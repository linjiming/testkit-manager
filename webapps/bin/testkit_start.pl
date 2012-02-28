#!/usr/bin/perl -w

# Distribution Checker
# Web-Server Start Module (testkit_start.pl)
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
#
#   Changlog:
#			07/16/2010, 
#			Update the branch name to 'MeeGo' by Tang, Shao-Feng <shaofeng.tang@intel.com>
#			Create the folders <HOME>/tests, <HOME>/profiles and <HOME>/results when the server is going to start.
#

use Fcntl ':flock';
use File::Temp qw/tmpnam/;
use Cwd qw(abs_path);
use FindBin;

my $machine = `uname -n`;
$machine =~ s/[\r\n]//g;

my $port = shift;
my $sudo_cmd = shift;

my $ask_pwd = ($< != 0);
my $testkit = abs_path($0);
$testkit =~ s!/[^/]+/[^/]+$!!;
my ($MTK_VERSION, $MTK_BRANCH);

# Read the MeeGo Testkit branch name and version
if (open(INFO, $testkit.'/utils/VERSION')) {
	if (defined(my $info = <INFO>)) {   # Read first line
		$info =~ s/[\r\n]//g;
		($MTK_VERSION, $MTK_BRANCH) = split(/:/, $info);
	}
	close(INFO);
}

$MTK_BRANCH = 'MeeGo' if (!$MTK_BRANCH);
$MTK_VERSION = '' if ($MTK_VERSION !~ m/^\d/);    # Version should start with digit
my $app_data = '../../';

# Check if port was specified and set it if it was not
if ($port) {
	if (($port !~ m/^\d+$/) or ($port > 65535)) {
		die "    Error: Invalid port '$port' specified!\n";
	}
}
else {
	$port = (($MTK_BRANCH eq 'MeeGo') ? 8890 : 8889);
}

# The same with sudo command
if (!$sudo_cmd) {
	#if (`lsb_release -ds 2>/dev/null` =~ m/ubuntu/i) {
        if (`cat /etc/issue` =~ m/ubuntu/i) {
		$sudo_cmd = 'sudo su -c';
	}
	else {
		$sudo_cmd = 'su -c';
	}
}

print "    The port '$port' will be used by the MeeGo Testkit's web-UI server.\n";
if ($ask_pwd) {
	print "    The command '$sudo_cmd' will be used to gain root access.\n";
	print "    If you want to change this, run $0 <port> <sudo-command>\n\n";
}
else {
	print "    If you want to change this, run $0 <port>\n\n";
}

my $LOCK_FILE = "/tmp/dc-server.lock.$port";
if (-f $LOCK_FILE) {
	if (open(LOCKFILE, $LOCK_FILE)) {
		if (!flock(LOCKFILE, LOCK_EX | LOCK_NB)) {
			my $pid = <LOCKFILE>;
			$pid =~ s/^G:(\d+)$/$1/;
			die "    Error: An instance of MeeGo Testkit is running on the port '$port' already! (PID: $pid.)\n\n    If you wish to use it, please open the URL http://$machine:$port/ in your browser.\n";
		}
		else {
			flock(LOCKFILE, LOCK_UN);
		}
		close(LOCKFILE);
	}
}

my $web_server = "$testkit/webui/dc-server.pl";
$web_server =~ s/\'/\'\\\'\'/g;
#my $cmd = "mkdir -p '$app_data/results' >/dev/null 2>&1; mkdir -p '$app_data/log/server_log' >/dev/null 2>&1; '$web_server' $port &";
#my $cmd = "'$web_server' $port &";
my $cmd = "mkdir -p '$testkit/../tests' >/dev/null 2>&1; mkdir -p '$testkit/../profiles' >/dev/null 2>&1; mkdir -p '$testkit/../results' >/dev/null 2>&1; mkdir -p '$testkit/../log/server_log' >/dev/null 2>&1; '$web_server' $port &";
if ($ask_pwd) {
        my $root = $FindBin::Bin."../../";
	$cmd = "$sudo_cmd 'export TESTKIT_ROOT=$root;$cmd'";
}
my $res = system($cmd);
sleep(1);
if ($res != 0) {
	die "    Failed to start server.\n";
}
print "    Server started. Log file location:\n    $app_data/log/server_log/dc-server.log.$port\n";

# If no X session available, exit immediately
if (!$ENV{'DISPLAY'}) {
	print "\n    The start page could be opened in a browser at http://$machine:$port/\n";
	exit;
}

# ...else try to open start page in a browser.
print "\n    The start page should be opened in a browser shortly.\n    If it doesn't open, you can load it at http://$machine:$port/\n";

my $browser_not_found = 5;

# First, try the Portland's xdg-open util.
if (system('which xdg-open >/dev/null 2>&1') == 0) {
	my $err_file = tmpnam();
	system("xdg-open \"http://127.0.0.1:$port/\" >$err_file 2>&1");
	# An exit code of 0 indicates success.
	# 1 Error in command line syntax. 
	# 2 One of the files passed on the command line did not exist. 
	# 3 A required tool could not be found. 
	# 4 The action failed.
	$browser_not_found = $?;
	if ($browser_not_found) {
		system("cat $err_file");
	}
	unlink($err_file);
}
else {
	# Try to find a browser by it's name.
	foreach my $br_name qw(opera google-chrome chromium /usr/bin/mozilla-firefox firefox konqueror epiphany galeon mozilla) {
		if (system("which $br_name >/dev/null 2>&1") == 0) {
			system("$br_name \"http://127.0.0.1:$port/\" >/dev/null 2>&1 &");
			$browser_not_found = 0;
			last;
		}
	}
}

if ($browser_not_found) {
	print "\n    Could not find a web-browser.\n    Go to 'http://$machine:$port/' to configure and launch tests.\n";
}
