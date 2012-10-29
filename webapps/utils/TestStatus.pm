# Distribution Checker
# Module for Work with Test Status Files (TestStatus.pm)
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

package TestStatus;
use strict;
use Common;
use Fcntl ':flock';

# Export symbols
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
	$status_error @status_warnings
	&lock_status &unlock_status &read_status
);

# Variable to store the text information about last error. Empty, if no error occured.
our $status_error = '';
# List of warning text messages.
our @status_warnings = ();

my $STATUS_HANDLE = undef;

# Opens and locks the status file.
# This function together with unlock_status() can be used for synchronising with
# running testkit_lite_start.pl. If you call lock_status(), then you should also call
# unlock_status() when block is no more needed. The read_status() function can
# be called without prior blocking as it sets block itself, when necessary.
sub lock_status() {
	my $status_file_path = $RESULTS_DIR.'/'.$STATUS_FILE;
	if (!-f $status_file_path) {
		$status_error = "Status file not found at $status_file_path.";
		return 0;
	}
	if (!open($STATUS_HANDLE, $status_file_path)) {
		$status_error = "Failed to open status file $status_file_path: $!";
		return 0;
	}
	flock($STATUS_HANDLE, LOCK_EX);
	return 1;
}

# Unlocks and closes the status file.
sub unlock_status() {
	flock($STATUS_HANDLE, LOCK_UN);
	close($STATUS_HANDLE);
	$STATUS_HANDLE = undef;
	return 1;
}

# Reads the status file. Returns the following hash:
# ->{PID} == <value>
# ->{IS_RUNNING} == [1|0]
# ->{CERTIFICATION} == [1|0]
# ->{RESULT_DIR} == <value>
# ->{START_TIME} == <value>
# ->{ESTIMATE_DURATION} == <value>
# ->{CURRENT_PERCENT} == <value>
# ->{STATUS} == [Running|Finished|Terminated]
# ->{TEST_SUITES}->[idx]->{ID} == <value>
#                       ->{NAME} == <user-friendly name>
#                       ->{STATUS} == [Not started|Preparing|Running|Making report|Failed|Warnings|Passed|No verdict|Incomplete|Crashed]
#                       ->{START_TIME} == <value>
#                       ->{STOP_TIME} == <value>
#                       ->{ESTIMATE_DURATION} == <value>
#                       ->{PREPARE_PERCENT} == <value>
#                       ->{CURRENT_PERCENT} == <value>
# The test suite's status meanings:
# Not started   - test suite was not started yet
# Preparing     - test suite is being prepared to run (downloading, installing, etc.)
# Running       - test suite is now running
# Making report - report for the just finished test suite is being generated
# Failed        - test suite has finished with failure
# Warnings      - test suite has finished with warnings
# Passed        - test suite has finished with successful verdict
# No verdict    - test suite has finished, but the verdict is unknown
# Incomplete    - manual test suite has been installed successfully
# Crashed       - test suite has crashed
sub read_status() {
	my $res = {'IS_RUNNING' => 0};
	my $needs_opening = !defined($STATUS_HANDLE);
	if ($needs_opening) {
		if (!lock_status()) {
			return $res;
		}
	}
	my $ts_idx;
	my $line_num = 0;
	seek($STATUS_HANDLE, 0, 1); # rewind
	while (my $line = <$STATUS_HANDLE>) {
		$line =~ s/^\s*(.*?)\s*$/$1/;
		++$line_num;
		next if (($line eq '') or ($line =~ m/^#/));
		if ($line =~ m/^\[(.*)\]$/) {
			if (defined($ts_idx)) {
				++$ts_idx;
			}
			else {
				$ts_idx = 0;
			}
			$res->{'TEST_SUITES'}->[$ts_idx] = {'ID' => $1};
		}
		elsif ($line =~ m/^PID\s*=\s*(\d+)$/) {
			if (defined($ts_idx)) {
				push @status_warnings, "PID should be present in global parameters only (line: $line_num).";
			}
			else {
				$res->{'PID'} = $1;
				$res->{'IS_RUNNING'} = is_process_running($1, 'testkit_lite_st');
			}
		}
		elsif ($line =~ m/^CERTIFICATION\s*=\s*(.+)$/) {
			if (defined($ts_idx)) {
				push @status_warnings, "CERTIFICATION should be present in global parameters only (line: $line_num).";
			}
			else {
				$res->{'CERTIFICATION'} = $1;
			}
		}
		elsif ($line =~ m/^RESULT_DIR\s*=\s*(.+)$/) {
			if (defined($ts_idx)) {
				push @status_warnings, "RESULT_DIR should be present in global parameters only (line: $line_num).";
			}
			else {
				$res->{'RESULT_DIR'} = $1;
			}
		}
		elsif ($line =~ m/^START_TIME\s*=\s*(\d+)$/) {
			if (defined($ts_idx)) {
				$res->{'TEST_SUITES'}->[$ts_idx]->{'START_TIME'} = $1;
			}
			else {
				$res->{'START_TIME'} = $1;
			}
		}
		elsif ($line =~ m/^STOP_TIME\s*=\s*(\d+)$/) {
			if (defined($ts_idx)) {
				$res->{'TEST_SUITES'}->[$ts_idx]->{'STOP_TIME'} = $1;
			}
			else {
				push @status_warnings, "STOP_TIME should be present in section parameters only (line: $line_num).";
			}
		}
		elsif ($line =~ m/^TEST_PLAN\s*=\s*(.+)$/) {
			$res->{'TEST_PLAN'} = $1;
		}
		elsif ($line =~ m/^CURRENT_PACKAGE\s*=\s*(.+)$/) {
			$res->{'CURRENT_PACKAGE'} = $1;
		}
		elsif ($line =~ m/^CURRENT_RUN_NUMBER\s*=\s*(\d+)$/) {
			$res->{'CURRENT_RUN_NUMBER'} = $1;
		}
		elsif ($line =~ m/^COMPLETE_PACKAGE\s*=\s*(.+)$/) {
			$res->{'COMPLETE_PACKAGE'} = $1;
		}
		elsif ($line =~ m/^STATUS\s*=\s*(.+)$/) {
			if (defined($ts_idx)) {
				$res->{'TEST_SUITES'}->[$ts_idx]->{'STATUS'} = $1;
			}
			else {
				$res->{'STATUS'} = $1;
			}
		}
		elsif ($line =~ m/^NAME\s*=\s*(.+)$/) {
			if (defined($ts_idx)) {
				$res->{'TEST_SUITES'}->[$ts_idx]->{'NAME'} = $1;
			}
			else {
				push @status_warnings, "NAME should be present in section parameters only (line: $line_num).";
			}
		}
		else {
			push @status_warnings, "Unrecognized format (line: $line_num).";
		}
	}
	if ($needs_opening) {
		unlock_status();
	}
	return $res;
}

1;
