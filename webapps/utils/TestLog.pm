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
#   Authors:
#
#          Wendong,Sui  <weidongx.sun@intel.com>
#          Tao,Lin  <taox.lin@intel.com>
#
#

package TestLog;
use strict;
use Packages;
use Common;
use File::Find;
use FindBin;
use Data::Dumper;

# Export symbols
require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(
  &writeResultInfo
);

# where is the result home folder
my $result_dir_manager  = $FindBin::Bin . "/../../results/";
my $result_dir_lite     = $FindBin::Bin . "/../../../lite";
my $test_definition_dir = "/usr/share/";

# save time -> package_name -> package_dir
my @time_package_dir = ();
my $time             = "none";
my $total            = 0;        # total case number from txt file

sub writeResultInfo {
	my ($time_only) = @_;
	if ( $time_only ne "" ) {
		find( \&writeResultInfo_wanted, $result_dir_lite . "/" . $time_only );
	}
	else {
		find( \&writeResultInfo_wanted, $result_dir_lite );
	}

	# add WRITE at the bottom, remove WRITE from beginning
	push( @time_package_dir, "WRITE" );
	shift(@time_package_dir);

	my $package_verdict = "none";

	# write info to file
	my $count = 0;
	while ( $count < @time_package_dir ) {
		my $temp = $time_package_dir[$count];
		if ( $temp eq "WRITE" ) {
			my $info = <<DATA;
Time:$time
$package_verdict
DATA

			# write info
			write_string_as_file( $result_dir_manager . $time . "/info",
				$info );

			# write runconfig
			writeRunconfig($time);

			# create tar file
			my $tar_cmd_delete =
			  "rm -f " . $result_dir_manager . $time . "/*.tgz";
			my $tar_cmd_create =
			    "tar -czvf "
			  . $result_dir_manager
			  . $time . "/"
			  . $time . ".tgz "
			  . $result_dir_manager
			  . $time . "/*";
			system("$tar_cmd_delete");
			system("$tar_cmd_create &>/dev/null");

			$time            = "none";
			$package_verdict = "none";
		}
		elsif ( $temp =~ /^[0-9:\.\-]+$/ ) {
			$time = $temp;
		}
		elsif ( $temp =~ /^[\w\d\-]+$/ ) {
			if ( $package_verdict eq "none" ) {
				$package_verdict = "Package:" . $temp . "\n";
			}
			else {
				$package_verdict .= "\nPackage:" . $temp . "\n";
			}
			for ( my $i = 1 ; $i <= 8 ; $i++ ) {
				$package_verdict .= $time_package_dir[ ++$count ] . "\n";
			}
			$package_verdict .= $time_package_dir[ ++$count ];
		}
		$count++;
	}
}

sub writeResultInfo_wanted {
	my $dir = $File::Find::name;
	my @verdict;
	if ( $dir =~ /.*\/([0-9:\.\-]+)$/ ) {
		my $isEmpty = `find $dir -name tests.*`;
		if ( $isEmpty ne "" ) {
			push( @time_package_dir, "WRITE" );
			push( @time_package_dir, $1 );
			$time = $1;
			my $mkdir_path = $result_dir_manager . $1;
			system("mkdir -p $mkdir_path");
		}
	}
	if (   ( $dir =~ /.*\/[0-9:\.\-]+\/usr\/share\/([\w\d\-]+)$/ )
		or ( $dir =~ /.*\/[0-9:\.\-]+\/usr\/local\/share\/([\w\d\-]+)$/ ) )
	{
		my $package_name = $1;
		if ( -e $dir . "/tests.result.txt" ) {
			system( 'mv ' . $dir . "/tests.result.txt " . $dir . "/tests.txt" );
		}
		if ( -e $dir . "/tests.result.xml" ) {
			system( 'mv ' . $dir . "/tests.result.xml " . $dir . "/tests.xml" );
		}
		my $txt_result = $dir . "/tests.txt";
		my $xml_result = $dir . "/tests.xml";

		my $startCase = "FALSE";
		my @xml       = ();

		# if dir is not empty, create manual case list
		if (
			   ( -e $txt_result )
			&& ( -e $xml_result )
			&& !(
				  -e $result_dir_manager 
				. $time . "/"
				. $package_name
				. "_manual_case_tests.txt"
			)
		  )
		{

			# get all manual cases
			my $content = "";
			open FILE, $test_definition_dir . $package_name . "/tests.xml"
			  or die "can't open "
			  . $test_definition_dir
			  . $package_name
			  . "/tests.xml";
			while (<FILE>) {
				if ( $_ =~ /suite.*name="(.*?)".*/ ) {
					push( @xml, $_ );
				}
				if ( $_ =~ /<\/suite>/ ) {
					push( @xml, $_ );
				}
				if ( $_ =~ /set.*name="(.*?)".*/ ) {
					push( @xml, $_ );
				}
				if ( $_ =~ /<\/set>/ ) {
					push( @xml, $_ );
				}
				if ( $startCase eq "TRUE" ) {
					push( @xml, $_ );
				}
				if ( $_ =~ /.*<testcase.*execution_type="manual".*/ ) {
					$startCase = "TRUE";
					push( @xml, $_ );
					if ( $_ =~ /.*<testcase.*id="(.*?)".*/ ) {
						my $temp_id = $1;
						$content .= $temp_id . ":N/A\n";
					}
				}
				if ( $_ =~ /.*<\/testcase>.*/ ) {
					$startCase = "FALSE";
				}
			}
			my $file_list;
			open $file_list,
			    ">"
			  . $result_dir_manager
			  . $time . "/"
			  . $package_name
			  . "_manual_case_tests.txt"
			  or die $!;
			print {$file_list} $content;
			close $file_list;
		}

		#don't write if no manual case
		if ( @xml > 1 ) {

			# write manual cases' xml to a xml
			my $file_xml;
			open $file_xml,
			    ">"
			  . $result_dir_manager
			  . $time . "/"
			  . $package_name
			  . "_manual_case_tests.xml"
			  or die $!;
			foreach (@xml) {
				print {$file_xml} $_;
			}
			close $file_xml;
		}

		# get result info
		my @totalVerdict = getTotalVerdict( $dir, $time, $package_name );
		my @verdict = getVerdict( $dir, $time, $package_name );
		if ( ( @totalVerdict == 3 ) && ( @totalVerdict == 3 ) ) {
			push( @time_package_dir, $package_name );
			for ( my $i = 1 ; $i <= 3 ; $i++ ) {
				push( @time_package_dir, shift(@totalVerdict) );
			}
			for ( my $i = 1 ; $i <= 6 ; $i++ ) {
				push( @time_package_dir, shift(@verdict) );
			}
		}
	}
}

# parse tests_result.txt and get total, pass, fail number
sub getTotalVerdict {
	my ( $testkit_lite_result, $time, $package ) = @_;
	my $testkit_lite_result_txt = $testkit_lite_result . "/tests.txt";
	system( "cp $testkit_lite_result_txt $result_dir_manager$time"
		  . "/$package"
		  . "_tests.txt" );

	# parse tests_result.txt
	my @totalVerdict = ();
	if ( -e $testkit_lite_result_txt ) {
		open FILE, $testkit_lite_result_txt or die $!;
		while (<FILE>) {
			if (   ( $_ =~ /.*tests.xml\s*XML\s*(\d+)\s*(\d+)\s*(\d+)\s*/ )
				or
				( $_ =~ /.*tests.result.xml\s*XML\s*(\d+)\s*(\d+)\s*(\d+)\s*/ )
			  )
			{
				$total = int($1) + int($2) + int($3);
				push( @totalVerdict, "Total:" . $total );
				push( @totalVerdict, "Pass:" . $1 );
				push( @totalVerdict, "Fail:" . $2 );
			}
		}
	}
	return @totalVerdict;
}

# parse tests_result.xml and get total, pass, fail number for both manual and auto cases
sub getVerdict {
	my ( $testkit_lite_result, $time, $package ) = @_;
	my $testkit_lite_result_xml = $testkit_lite_result . "/tests.xml";
	system( "cp $testkit_lite_result_xml $result_dir_manager$time"
		  . "/$package"
		  . "_tests.xml" );
	my $manual_result_list =
	  $result_dir_manager . $time . "/" . $package . "_manual_case_tests.txt";

	# parse tests_result.xml
	my @verdict = ();
	if ( ( -e $testkit_lite_result_xml ) && ( -e $manual_result_list ) ) {
		my $totalM = 0;
		my $passM  = 0;
		my $failM  = 0;
		my $totalA = 0;
		my $passA  = 0;
		my $failA  = 0;

		open FILE, $manual_result_list or die $!;
		while (<FILE>) {
			$totalM += 1;
		}
		push( @verdict, "Total(M):" . $totalM );
		push( @verdict, "Pass(M):" . $passM );
		push( @verdict, "Fail(M):" . $failM );

		open FILE, $testkit_lite_result_xml or die $!;
		while (<FILE>) {

			# just count auto case
			if ( $_ =~ /.*<testcase.*execution_type="auto".*/ ) {
				$totalA += 1;
				if ( $_ =~ /.*result="PASS".*/ ) {
					$passA += 1;
				}
				elsif ( $_ =~ /.*result="FAIL".*/ ) {
					$failA += 1;
				}
			}
		}
		if ( $totalA == 0 ) {
			$totalA = $total - $totalM;
		}
		push( @verdict, "Total(A):" . $totalA );
		push( @verdict, "Pass(A):" . $passA );
		push( @verdict, "Fail(A):" . $failA );
	}
	return @verdict;
}

sub writeRunconfig {
	my ($time) = @_;
	chomp( my $hardware_platform = `uname -i` );
	chomp( my $package_manager   = guess_package_manager( detect_OS() ) );
	chomp( my $username          = `w | sed -n '3,3p' | cut -d ' ' -f 1` );
	chomp( my $hostname          = `uname -n` );
	chomp( my $kernel            = `uname -r` );
	chomp( my $operation_system  = `uname -o` );

	my $runconfig = <<DATA;
Hardware Platform:$hardware_platform
Package Manager:$package_manager
Username:$username
Hostname:$hostname
Kernel:$kernel
Operation System:$operation_system
DATA
	write_string_as_file( $result_dir_manager . $time . "/runconfig",
		$runconfig );
}

1;
