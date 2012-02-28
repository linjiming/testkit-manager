# Distribution Checker
# Module for Work with User Profiles (UserProfile.pm)
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

package UserProfile;
use strict;
use Exporter;

our @ISA = 'Exporter';
our @EXPORT = qw(
	&read_profile &write_profile $profile_error @profile_warnings
);

use Common;

# Variable to store the text information about last error. Empty, if no error occured.
our $profile_error = '';
# List of warning text messages.
our @profile_warnings = ();

# Function reads and parses the profile passed to it as input argument.
# Returns the following hash:
# ->{GENERAL}->{<option>} == <value>
# ->{FILES}->{<file>}->{DOWNLOAD} == <dl-option>
#                    ->{INSTALL} == <inst-option>
# ->{TEST_SUITES_SORT}->[<name1>, <name2>, ...]
# ->{TEST_SUITES}->{<name>}->{RUN} == [1|0]
#                          ->{STATUS} == <selected-status>
#                          ->{VERSION} == <selected-version>
#                          ->{OPTIONS} == {<opt0-id> => <opt0-value>, ...}
#                          ->{AUTO_REPLIES}->{<status>}->{<version>} == {<autoreply0-id> => <autoreply0-value>, ...}
#
# Each hash value may be undefined, if there is no appropriate information in the profile.
# 
# <option> is the name of option from [GENERAL] section; <value> is its value.
# <file> is path to file relative to the cache directory.
# <inst-option> is one of the following:
#   0 - install, if necessary
#   1 - force reinstall
#   2 - do not deinstall
# <dl-option> is one of the following:
#   0 - download, if necessary
#   1 - force download
#   2 - do not download
# <status> is one of (cert, certold, noncert, beta, snapshot, local).
# <version> is the version number (e.g. "3.2.0-1").
# <optI-id>, <optI-value> are string values, actual values being dependent on the test suite (currently used
#   only for specifying profile in cmdchk, libchk, etc.).
# <autoreplyI-id>, <autoreplyI-value> are string values, actual values being dependent on the test suite version;
#   (currently used only for expect autoreplies; undef means default value).
#
# In case of error returns undef and puts explanation into $profile_error. 
sub read_profile($) {
	my ($profile) = @_;
	$profile_error = '';
	@profile_warnings = ();
	if (!-f $profile) {
		$profile_error = "Cannot open file '$profile'. No such file or directory";
		return undef;
	}
	if (!-s $profile) {
		return {};
	}
	if (!open(PROFILE, $profile)) {
		$profile_error = "Cannot open file '$profile'. $!";
		return undef;
	}
	my $res = {'TEST_SUITES_SORT' => []};
	my $current_section = '';   # Current section we are reading
	my $name = '';              # Name of the test suite described by the current section
	my $status = '';            # Status of the test suite described by the current section
	my $version = '';           # Version of the test suite described by the current section
	my $line = 0;               # Current line number while reading profile
	while (<PROFILE>) {
		s/[\r\n]//g;
		++$line;
		# This line starts a section
		if (m/^\[(.*)\]$/) {
			# Either global section, or general test suite options
			if (m/^\[([^|]+)\]$/) {
				$current_section = $_;
				$name = $1;
				if (!defined($res->{'TEST_SUITES'}->{$name})) {
					$res->{'TEST_SUITES'}->{$name} = {};
					push @{$res->{'TEST_SUITES_SORT'}}, $name;
				}
				$status = '';
				$version = '';
			}
			# Section with options specific for a test suite version
			elsif (m/^\[([^|]+)\|([^|]+)\|([^|]+)\]$/) {
				$current_section = $_;
				$name = $1;
				if (!defined($res->{'TEST_SUITES'}->{$name})) {
					$res->{'TEST_SUITES'}->{$name} = {};
					push @{$res->{'TEST_SUITES_SORT'}}, $name;
				}
				$status = $2;
				$version = $3;
			}
			else {
				push @profile_warnings, "Line $line: Wrong section name format: '$_'";
				$current_section = '';
				$name = '';
				$status = '';
				$version = '';
			}
		}
		elsif (($current_section ne '') and ($_ ne '') and !m/^#/) {
			# [GENERAL] section
			if ($current_section eq '[GENERAL]') {
				if (m/^COMMENTS: (.*)$/) {
					if ($res->{'GENERAL'}->{'COMMENTS'}) {
						$res->{'GENERAL'}->{'COMMENTS'} .= "\n".$1;
					}
					else {
						$res->{'GENERAL'}->{'COMMENTS'} = $1;
					}
				}
				elsif (m/^([^:]+):\s*(.*)$/) {
					$res->{'GENERAL'}->{$1} = $2;
				}
				else {
					push @profile_warnings, "Line $line: Wrong line format in section $current_section: '$_'";
				}
			}
			# [FILES] section
			elsif ($current_section eq '[FILES]') {
				if (m/^FILEDL:\s*([^:]+):\s*(.*)$/) {
					$res->{'FILES'}->{$1}->{'DOWNLOAD'} = $2;
				}
				elsif (m/^FILEINST:\s*([^:]+):\s*(.*)$/) {
					$res->{'FILES'}->{$1}->{'INSTALL'} = $2;
				}
				else {
					push @profile_warnings, "Line $line: Wrong line format in section $current_section: '$_'";
				}
			}
			# [<test-suite>] section
			elsif ($status eq '') {
				if (m/^RUN:\s*([10])$/) {
					$res->{'TEST_SUITES'}->{$name}->{'RUN'} = $1;
				}
				elsif (m/^VERSION:\s*([^|]+)\|([^|]+)$/) {
					$res->{'TEST_SUITES'}->{$name}->{'STATUS'} = $1;
					$res->{'TEST_SUITES'}->{$name}->{'VERSION'} = $2;
				}
				elsif (m/^OPTION_(.+): (.*)$/) {
					$res->{'TEST_SUITES'}->{$name}->{'OPTIONS'}->{$1} = $2;
				}
				else {
					push @profile_warnings, "Line $line: Wrong line format in section $current_section: '$_'";
				}
			}
			# [<test-suite>|<status>|<version>] section
			else {
				if (m/^AUTOREPLY_(.+): (.*)$/) {
					$res->{'TEST_SUITES'}->{$name}->{'AUTO_REPLIES'}->{$status}->{$version}->{$1} = (($2 eq '[default]') ? undef : $2);
				}
				else {
					push @profile_warnings, "Line $line: Wrong line format in section $current_section: '$_'";
				}
			}
		}
	}
	close(PROFILE);
	if (scalar(keys %{$res->{'GENERAL'}}) == 0) {
		$profile_error = 'Incompatible profile format.';
		return undef;
	}
	return $res;
}

# Function saves the profile passed via HTML POST request.
# First argument is the path to profile to be saved.
# Second argument is a reference to the %_POST hash.
# Returns 1 if success or 0 otherwise.
sub write_profile($$) {
	my ($file_name, $POST) = @_;
	if (open(FILE, ">$file_name")) {
		my $architecture = ($POST->{'architecture'} or detect_architecture() or 'x86');
		my $std_version  = ($POST->{'std_version'} or $DEFAULT_STANDARD_VER);
		my $std_version_id = $std_version;
		$std_version_id =~ s/ /:/g;
		my $std_profile  = ($POST->{'std_profile'} or 'no');
		print FILE "[GENERAL]\n";
		print FILE "CERTIFY:         ".$POST->{'certify'}."\n"      if ($POST->{'certify'});
		print FILE "NAME:            ".$POST->{'tester_name'}."\n"  if ($POST->{'tester_name'});
		print FILE "ORGANIZATION:    ".$POST->{'organization'}."\n" if ($POST->{'organization'});
		if ($POST->{'tester_email'}) {
			print FILE "EMAIL:           ".$POST->{'tester_email'}."\n";
			print FILE "SEND_EMAIL:      ".(defined($POST->{'send_email_report'}) ? '1' : '0')."\n";
		}

		print FILE "VERBOSE_LEVEL:   ".($POST->{'verbose_level'} ? $POST->{'verbose_level'} : '1')."\n";
		print FILE "ARCHITECTURE:    $architecture\n";
		print FILE "USE_INTERNET:    ".(defined($POST->{'use_internet'}) ? '1' : '0')."\n";
		print FILE "STD_VERSION:     $std_version\n";
		print FILE "STD_PROFILE:     $std_profile\n";

		if ($POST->{'comments'}) {
			$POST->{'comments'} =~ s/\r\n/\n/g;
			my @comments_lines = split(/\n/, $POST->{'comments'});
			foreach (@comments_lines) {
				print FILE "COMMENTS: $_\n";
			}
		}

		my $file_inst_dl = '';
		if ($POST->{'file_dl'} or $POST->{'file_inst'}) {
			$file_inst_dl = "\n[FILES]\n";
			if ($POST->{'file_dl'}) {
				my %files = split(/:/, $POST->{'file_dl'});
				$file_inst_dl .= "FILEDL: $_:$files{$_}\n" foreach (sort keys %files);
			}
			if ($POST->{'file_inst'}) {
				my %files = split(/:/, $POST->{'file_inst'});
				$file_inst_dl .= "FILEINST: $_:$files{$_}\n" foreach (sort keys %files);
			}
			$file_inst_dl .= "\n";
		}
		my $test_suites = '';
		my %ts_glob_options = ();
		if ($POST->{'ts_glob_options'}) {
			my @test_suites = split(/;/, $POST->{'ts_glob_options'});
			foreach my $rec (@test_suites) {
				my ($ts, %options) = split(/:/, $rec);
				foreach (keys %options) {
					my $val = $options{$_};
					s/%([0-9a-fA-F]{2})/chr(hex($1))/eg;
					$val =~ s/%([0-9a-fA-F]{2})/chr(hex($1))/eg;
					$ts_glob_options{$ts}->{$_} = $val;
				}
			}
		}
		my %auto_replies = ();
		if ($POST->{'auto_replies'}) {
			my @test_suites = split(/;/, $POST->{'auto_replies'});
			foreach my $rec (@test_suites) {
				my ($ts, $status, $ver, %replies) = split(/:/, $rec);
				foreach (keys %replies) {
					my $val = $replies{$_};
					s/%([0-9a-fA-F]{2})/chr(hex($1))/eg;
					$val =~ s/%([0-9a-fA-F]{2})/chr(hex($1))/eg;
					$auto_replies{$ts}->{"$status|$ver"}->{$_} = $val;
				}
			}
		}
		my @ts_list;
		if ($POST->{"ts-sort-$architecture-$std_version_id"}) {
			@ts_list = split(/;/, $POST->{"ts-sort-$architecture-$std_version_id"});
		}
		else {
			@ts_list = sort(grep(/ver-$architecture-$std_version_id-/, keys %$POST));
		}
		foreach my $name (@ts_list) {
			$name =~ s/^ver-$architecture-$std_version_id-//;
			my $ver = "ver-$architecture-$std_version_id-$name";
			my $mod = "mod-$architecture-$std_version_id-$name";
			next if (!defined($POST->{$ver}));
			$test_suites .= "[$name]\n";
			if (defined($POST->{$mod})) {
				$test_suites .= "RUN: 1\n";
			}
			else {
				$test_suites .= "RUN: 0\n";
			}
			$test_suites .= "VERSION: ".$POST->{$ver}."\n";

			foreach my $opt_name (keys %{$ts_glob_options{$name}}) {
				$test_suites .= "OPTION_$opt_name: ".$ts_glob_options{$name}->{$opt_name}."\n";
			}

			$test_suites .= "\n";
			foreach my $status_ver (keys %{$auto_replies{$name}}) {
				$test_suites .= "[$name|$status_ver]\n";
				foreach (keys %{$auto_replies{$name}->{$status_ver}}) {
					$test_suites .= "AUTOREPLY_$_: ".$auto_replies{$name}->{$status_ver}->{$_}."\n";
				}
				$test_suites .= "\n";
			}
		}
		print FILE $file_inst_dl;
		print FILE $test_suites;
		close(FILE);
		return 1;
	}
	else {
		$profile_error = "Cannot open file '$file_name' for writing:<br />$!";
		return 0;
	}
}

1;
