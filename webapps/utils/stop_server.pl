#!/usr/bin/perl -w

# Distribution Checker
# Stop Process Tree Module (stop_server.pl)
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

use FindBin;

sub BEGIN { unshift @INC, $FindBin::Bin; }

use Common;

my $server_pid = shift;
if (!$server_pid) {
	die "Usage: $0 <SERVER_PID>\n";
}

# Build the list of processes to be killed.
# Sub-tree of this particular process is excluded so that it could finish its work.
my @tef_list = ();
my %children = ();
my %parent = ();
my %cmd_line = ();

# Read list of all currently running processes
if (!opendir(PROC_DIR, '/proc')) {
	print STDERR "Failed to open /proc directory for reading:\n$!";
	return 0;
}
my @all_pids = grep(/^\d+$/, readdir(PROC_DIR));
closedir(PROC_DIR);

# Build the parent-child tree and get command lines
foreach my $pid (@all_pids) {
	if (open(PID_FILE, "/proc/$pid/stat")) {
		my $info = <PID_FILE>;
		close(PID_FILE);
		if ($info =~ m/^\d+\s+\((.*)\)\s+\S\s+(\d+)\s+[^\(\)]+$/) {
			my ($cmdline, $ppid) = ($1, $2);
			if (open(CMDLINE_FILE, "/proc/$pid/cmdline")) {
				my $line = <CMDLINE_FILE>;
				close(CMDLINE_FILE);
				if ($line) {
					$cmdline = $line;
				}
			}
			$cmd_line{$pid} = $cmdline;
			# Add testkit_lite_start.pl, if it was started from Web-UI.
			if (($cmdline =~ m/\btestkit_lite_start\.pl\x00/) and ($cmdline =~ m/\x00--webui\x00/)) {
				push @tef_list, $pid;
			}
			$parent{$pid} = $ppid;
			if (!defined($children{$ppid})) {
				$children{$ppid} = [];
			}
			push @{$children{$ppid}}, $pid;
		}
	}
}

# Find grand-parent of current process which is 'dc-server.pl':
# we need to exclude it from killing, so that we could send response
# back to browser.
my $this_parent_pid = $$;
while ($cmd_line{$this_parent_pid} !~ m/\bdc-server\.pl\x00/) {
	if (!$parent{$this_parent_pid}) {
		# Did not find dc-server.pl - started not from Web-UI
		$this_parent_pid = 0;
		last;
	}
	else {
		$this_parent_pid = $parent{$this_parent_pid};
	}
}

# Get the plain list of processes to kill (breadth-first tree-walk)
my @server_list = ($server_pid);
for (my $i = 0; $i < scalar(@server_list); ++$i) {
	my $pid = $server_list[$i];
	if ($children{$pid}) {
		foreach (@{$children{$pid}}) {
			# Skip all testkit_lite_start.pl instances. Those started from command line should
			# continue running, those started from Web-UI are in @tef_list already.
			next if ($cmd_line{$_} =~ m/\btestkit_lite_start\.pl\x00/);
			# Also exclude Web-UI subtree of this process.
			next if ($_ == $this_parent_pid);
			push @server_list, $_;
		}
	}
}

# Send TERM signal to all processes
foreach (@tef_list, @server_list) {
	kill('SIGTERM', $_);
}

# Try 20 times, waiting 0.3 seconds each time, for all the processes to be really dead.
# Check only server processes, because testkit_lite_start.pl is stopping too slowly.
my %death_check = map { $_ => 1 } @server_list;
for (my $i = 0; $i < 20; ++$i) {
	foreach (keys %death_check) {
		if (!is_process_running($_)) {
			delete $death_check{$_};
		}
	}
	if (scalar(keys %death_check) == 0) {
		last;
	}
	else {
		select(undef, undef, undef, 0.3);
	}
}

# Finalization: report about processes that were not killed (if any), and exit
if (scalar(keys %death_check) == 0) {
	exit 0;
}
else {
	print STDERR "Could not terminate processes: ".join(", ", sort keys %death_check)."\n";
	exit 1;
}
