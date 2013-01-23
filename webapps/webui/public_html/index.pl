#!/usr/bin/perl -w
#
# Copyright (C) 2012 Intel Corporation
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# Authors:
#              Zhang, Huihui <huihuix.zhang@intel.com>
#              Wendong,Sui  <weidongx.sun@intel.com>

use strict;
use Templates;

print "HTTP/1.0 200 OK" . CRLF;
print "Content-type: text/html" . CRLF . CRLF;

print_header( "$MTK_BRANCH Manager Main Page", "" );

my $testkit_lite_error_message = check_testkit_sdb();
if ( $testkit_lite_error_message eq "" ) {
	my $check_network = check_network();
	if ( $check_network =~ /OK/ ) {
		my $pre_plan = "$SERVER_PARAM{'APP_DATA'}/plans/pre_Tizen_CTS";
		if ( -e $pre_plan ) {
			my @rpm       = ();
			my $repo      = get_repo();
			my @repo_all  = split( "::", $repo );
			my $repo_type = $repo_all[0];
			my $repo_url  = $repo_all[1];
			my $GREP_PATH = $repo_url;
			$GREP_PATH =~ s/\:/\\:/g;
			$GREP_PATH =~ s/\//\\\//g;
			$GREP_PATH =~ s/\./\\\./g;
			$GREP_PATH =~ s/\-/\\\-/g;

			# get package list from the repo
			if ( $repo_type =~ /remote/ ) {
				@rpm =
				  `$DOWNLOAD_CMD $repo_url 2>&1 | grep $GREP_PATH.*tests.*rpm`;
			}
			if ( $repo_type =~ /local/ ) {
				@rpm = `find $repo_url | grep $GREP_PATH.*tests.*rpm`;
			}

			# get package list from the test plan
			my $theEnd       = "False";
			my @planPackages = ();
			open( FILE, $pre_plan );
			while (<FILE>) {
				my $line = $_;
				$line =~ s/\n//g;
				if ( $line =~ /\[\/Auto\]/ ) {
					$theEnd = "True";
				}
				if ( $theEnd eq "False" ) {
					if ( $line !~ /Auto/ ) {
						$line =~ s/\(\d+ \d+\)//;
						push( @planPackages, $line );
					}
				}
			}

			# check if the pacakge from the plan is in the repo
			my @missingPackages = ();
			foreach (@planPackages) {
				my $plan_package = $_;
				$plan_package =~ s/^\s//;
				$plan_package =~ s/\s*$//;
				my $is_missing = 1;
				foreach (@rpm) {
					my $repo_package = $_;
					$repo_package =~ s/^\s//;
					$repo_package =~ s/\s*$//;
					if ( $repo_package =~ /$plan_package/ ) {
						$is_missing = 0;
					}
				}
				if ($is_missing) {
					push( @missingPackages, $plan_package );
				}
			}
			if ( @missingPackages > 0 ) {
				my $missing_package_list = join( ",", @missingPackages );
				$testkit_lite_error_message =
"Package(s): $missing_package_list in the test plan $pre_plan, can't be found in the $repo_type repo $repo_url";
			}
		}
	}
	else {
		$testkit_lite_error_message = $check_network;
	}
}

print show_error_dlg($testkit_lite_error_message);

print <<DATA;
<map name="home_menu" id="home_menu">
  <area href="tests_report.pl" alt="Report" title="Vie Test Report" shape="rect" coords="201,209,330,372" />
  <area href="tests_custom.pl" alt="Plan" title="Create Test Plan" shape="rect" coords="195,32,331,197" />
  <area href="tests_execute.pl" alt="Execute" title="Execute Test Plan" shape="rect" coords="397,43,535,196" />
  <area href="tests_statistic.pl" alt="Statistic" title="View Test Statistics" shape="rect" coords="391,214,541,370" />
</map>
<img src="images/home_menu.png" width="768" height="444" alt="home_menu" usemap="#home_menu" />
DATA

print_footer("footer_home");

