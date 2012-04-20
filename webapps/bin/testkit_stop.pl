#!/usr/bin/perl -w

# Testkit
# Web-Server Stop Module (dist-checker-stop.pl)
#
# Copyright (C) 2007-2009 The Linux Foundation. All rights reserved.
#
# This program has been developed by ISP RAS for LF.
# The ptyshell tool is originally written by Jiri Dluhos <jdluhos@suse.cz>
# Copyright (C) 2005-2007 SuSE Linux Products GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 2 as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

use Fcntl ':flock';
use Cwd qw(cwd abs_path);

sub confirm($) {
	print $_[0];
	$reply = <STDIN>;
	if (($reply !~ m/^y$/i) and ($reply !~ m/^yes$/i)) {
		exit(2);
	}
}

sub exec_sudo_cmd($$) {
	my ($cmd, $sudo_cmd) = @_;
	if ($sudo_cmd) {
		$cmd =~ s/\'/\'\\\'\'/g;
		return system("$sudo_cmd '$cmd'");
	}
	else {
		return system("$cmd");
	}
}

my $port = shift;
my $sudo_cmd = shift;
my $pwd_prompt = "    Please enter the root password when prompted.\n";

my $ask_pwd = ($< != 0);
my $dc_dir = abs_path($0);
$dc_dir =~ s!/[^/]+/[^/]+$!!;
my ($MTK_VERSION, $MTK_BRANCH);

# Read the Testkit branch name and version
if (open(INFO, $dc_dir.'/utils/VERSION')) {
	if (defined(my $info = <INFO>)) {   # Read first line
		$info =~ s/[\r\n]//g;
		($MTK_VERSION, $MTK_BRANCH) = split(/:/, $info);
	}
	close(INFO);
}

$MTK_BRANCH = 'Testkit' if (!$MTK_BRANCH);
$MTK_VERSION = '' if ($MTK_VERSION !~ m/^\d/);    # Version should start with digit

# Check if port was specified and set it if it was not
if ($port) {
	if (($port !~ m/^\d+$/) or ($port > 65535)) {
		die "    Error: Invalid port '$port' specified!\n";
	}
}
else {
	$port = (($MTK_BRANCH eq 'Testkit') ? 8899 : 8898);
}

# The same with sudo command
if ($ask_pwd and !$sudo_cmd) {
	if (`lsb_release -ds 2>/dev/null` =~ m/ubuntu/i) {
		$sudo_cmd = 'sudo su -c';
		$pwd_prompt = ''
	}
	else {
		$sudo_cmd = 'su -c';
	}
}

print "    Stopping the Testkit's web-UI server on port '$port'.\n";
if ($ask_pwd) {
	print "    The command '$sudo_cmd' will be used to gain root access.\n";
	print "    If you want to change this, run $0 <port> <sudo-command>\n\n";
	if ($pwd_prompt) {
		print $pwd_prompt;
	}
}
else {
	print "    If you want to change this, run $0 <port>\n\n";
}

my $LOCK_FILE = "/tmp/dc-server.lock.$port";
my $pid;
if (open(LOCKFILE, $LOCK_FILE)) {
	if (!flock(LOCKFILE, LOCK_EX | LOCK_NB)) {
		$pid = <LOCKFILE>;
		$pid =~ s/^G:(\d+)$/$1/;
	}
	else {
		flock(LOCKFILE, LOCK_UN);
	}
	close(LOCKFILE);
}

if ($pid) {
	confirm('    Are you sure you want to stop the server? ');
	my $res = exec_sudo_cmd("cd $dc_dir/utils; ./stop_server.pl $pid", $sudo_cmd);
	exit $res >> 8;
}
elsif (`ps -A 2>/dev/null` =~ m/(dc|dtk)-server\.pl/) {
	confirm("    It seems that another Testkit or DTK Manager is running.\n    killall will be used to stop it.\n    Continue? ");
	my $res = exec_sudo_cmd('killall dc-server.pl dtk-server.pl', $sudo_cmd);
	exit $res >> 8;
}
else {
	die "    No running Testkit was found.\n";
}
