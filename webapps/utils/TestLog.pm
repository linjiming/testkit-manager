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

package TestLog;
use strict;
use Packages;
use Common;
use File::Find;
use FindBin;
use Data::Dumper;
use TestStatus;

# Export symbols
require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(
  &writeResultInfo
);

# where is the result home folder
my $result_dir_manager  = $FindBin::Bin . "/../../results/";
my $test_definition_dir = $FindBin::Bin . "/../../definition/";
my $opt_dir             = $FindBin::Bin . "/../../package/";
my $result_dir_lite     = $FindBin::Bin . "/../../lite";

# save time -> package_name -> package_dir
my @time_package_dir = ();
my $time             = "none";
my $isOnlyAuto       = "FALSE";
my $total            = 0;         # total case number from txt file
my @targetFilter;
my $dir_root     = "none";
my $combined_xml = "none";

sub writeResultInfo {
	my ( $time_only, $isOnlyAuto_temp, @targetFilter_temp ) = @_;
	$isOnlyAuto   = $isOnlyAuto_temp;
	@targetFilter = @targetFilter_temp;

	syncDefinition();

	if ( $time_only ne "" ) {
		find( \&changeDirStructure_wanted,
			$result_dir_lite . "/" . $time_only );
		find( \&writeResultInfo_wanted, $result_dir_lite . "/" . $time_only );
	}
	else {
		find( \&changeDirStructure_wanted, $result_dir_lite );
		find( \&writeResultInfo_wanted,    $result_dir_lite );
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
			my $tar_cmd_create = "cd "
			  . $result_dir_manager
			  . $time
			  . "/; tar -czPf ./"
			  . $time
			  . ".tgz application.js back_top.png jquery.min.js testresult.xsl tests.css tests.result.xml";
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
			for ( my $i = 1 ; $i <= 11 ; $i++ ) {
				$package_verdict .= $time_package_dir[ ++$count ] . "\n";
			}
			$package_verdict .= $time_package_dir[ ++$count ];
		}
		$count++;
	}
}

sub writeResultInfo_wanted {
	my $dir = $File::Find::name;
	if ( $dir =~ /$result_dir_lite\/([0-9:\.\-]+)$/ ) {
		push( @time_package_dir, "WRITE" );
		push( @time_package_dir, $1 );
		$time = $1;
		my $mkdir_path = $result_dir_manager . $1;
		system("mkdir -p $mkdir_path");
	}
	if (   ( $dir =~ /.*\/[0-9:\.\-]+\/usr\/share\/([\w\d\-]+)$/ )
		or ( $dir =~ /.*\/[0-9:\.\-]+\/usr\/local\/share\/([\w\d\-]+)$/ ) )
	{
		system("cp $combined_xml $result_dir_manager$time/tests.result.xml");
		my $status = read_status();
		my $test_plan_name =
		  ( $status->{'TEST_PLAN'} or "Empty test_plan_name" );
		system(
"sed -i 's/Empty test_plan_name/$test_plan_name/' $result_dir_manager$time/tests.result.xml"
		);
		system(
"cp /opt/testkit/manager/webapps/webui/public_html/css/xsd/testcase.xsl $result_dir_manager$time"
		);
		system(
"cp /opt/testkit/manager/webapps/webui/public_html/css/xsd/testresult.xsl $result_dir_manager$time"
		);
		system(
"cp /opt/testkit/manager/webapps/webui/public_html/css/xsd/tests.css $result_dir_manager$time"
		);
		system(
"cp /opt/testkit/manager/webapps/webui/public_html/css/xsd/jquery.min.js $result_dir_manager$time"
		);
		system(
"cp /opt/testkit/manager/webapps/webui/public_html/css/xsd/back_top.png $result_dir_manager$time"
		);
		system(
"cp /opt/testkit/manager/webapps/webui/public_html/css/xsd/application.js $result_dir_manager$time"
		);
		my $package_name = $1;

		my $test_definition_xml =
		  $test_definition_dir . $package_name . "/tests.xml";
		if ( -e $test_definition_xml ) {
			system( 'cp '
				  . $test_definition_xml . ' '
				  . $result_dir_manager
				  . $time . '/'
				  . $package_name
				  . '_definition.xml' );
		}
		else {
			warning "definition xml: $test_definition_xml is missing";
			sleep 3;
		}
		if ( -e $dir . "/tests.result.xml" ) {
			system( 'mv ' . $dir . "/tests.result.xml " . $dir . "/tests.xml" );
			my $testkit_lite_result_xml = $dir . "/tests.xml";
			system( "cp $testkit_lite_result_xml $result_dir_manager$time"
				  . "/$package_name"
				  . "_tests.xml" );
		}
		my $xml_result = $dir . "/tests.xml";

		# if dir is not empty, create manual case list
		if (
			( -e $xml_result )
			&& !(
				  -e $result_dir_manager 
				. $time . "/"
				. $package_name
				. "_manual_case_tests.txt"
			)
		  )
		{

			# get all manual cases' result
			my $content = "";
			my $total_result_xml =
			  $result_dir_manager . $time . "/" . $package_name . "_tests.xml";
			open FILE, $total_result_xml
			  or die "can't open " . $total_result_xml;
			while (<FILE>) {
				if (   ( $_ =~ /.*<testcase.*execution_type="\s*manual\s*".*/ )
					&& ( $isOnlyAuto eq "FALSE" ) )
				{
					if ( $_ =~ /.*<testcase.*id="\s*(.*?)\s*".*/ ) {
						my $temp_id = $1;
						if ( $_ =~ /result="\s*(.*?)\s*"/ ) {
							my $result = $1;
							$content .= $temp_id . "!:!$result\n";
						}
						else {
							$content .= $temp_id . "!:!N/A\n";
						}
					}
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

		# get result info
		my @totalVerdict = getTotalVerdict( $dir, $time, $package_name );
		my @verdict = getVerdict( $dir, $time, $package_name );
		if ( ( @totalVerdict == 4 ) && ( @verdict == 8 ) ) {
			push( @time_package_dir, $package_name );
			for ( my $i = 1 ; $i <= 4 ; $i++ ) {
				push( @time_package_dir, shift(@totalVerdict) );
			}
			for ( my $i = 1 ; $i <= 8 ; $i++ ) {
				push( @time_package_dir, shift(@verdict) );
			}
		}
	}
}

# parse tests_result.txt and get total, pass, fail number
sub getTotalVerdict {
	my ( $testkit_lite_result, $time, $package ) = @_;
	my $testkit_lite_result_xml = $testkit_lite_result . "/tests.xml";

	# parse tests_result.xml
	my @totalVerdict = ();
	$total = 0;
	my $pass  = 0;
	my $fail  = 0;
	my $block = 0;
	if ( -e $testkit_lite_result_xml ) {
		open FILE, $testkit_lite_result_xml or die $!;
		while (<FILE>) {
			if ( $_ =~ /.*<testcase.*>.*/ ) {
				$total += 1;
				if ( $_ =~ /.*result="PASS".*/ ) {
					$pass += 1;
				}
				elsif ( $_ =~ /.*result="FAIL".*/ ) {
					$fail += 1;
				}
				elsif ( $_ =~ /.*result="BLOCK".*/ ) {
					$block += 1;
				}
			}
		}
	}
	push( @totalVerdict, "Total:" . $total );
	push( @totalVerdict, "Pass:" . $pass );
	push( @totalVerdict, "Fail:" . $fail );
	push( @totalVerdict, "Block:" . $block );
	return @totalVerdict;
}

# parse tests_result.xml and get total, pass, fail number for both manual and auto cases
sub getVerdict {
	my ( $testkit_lite_result, $time, $package ) = @_;
	my $testkit_lite_result_xml = $testkit_lite_result . "/tests.xml";
	my $manual_result_list =
	  $result_dir_manager . $time . "/" . $package . "_manual_case_tests.txt";

	# parse tests_result.xml
	my @verdict = ();
	if ( ( -e $testkit_lite_result_xml ) && ( -e $manual_result_list ) ) {
		my $totalM = 0;
		my $passM  = 0;
		my $failM  = 0;
		my $blockM = 0;
		my $totalA = 0;
		my $passA  = 0;
		my $failA  = 0;
		my $blockA = 0;

		open FILE, $manual_result_list or die $!;
		while (<FILE>) {
			if ( $_ =~ /PASS/ ) {
				$passM += 1;
			}
			if ( $_ =~ /FAIL/ ) {
				$failM += 1;
			}
			if ( $_ =~ /BLOCK/ ) {
				$blockM += 1;
			}
			$totalM += 1;
		}
		push( @verdict, "Total(M):" . $totalM );
		push( @verdict, "Pass(M):" . $passM );
		push( @verdict, "Fail(M):" . $failM );
		push( @verdict, "Block(M):" . $blockM );

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
				elsif ( $_ =~ /.*result="BLOCK".*/ ) {
					$blockA += 1;
				}
			}
		}
		if ( $totalA == 0 ) {
			$totalA = $total - $totalM;
		}
		push( @verdict, "Total(A):" . $totalA );
		push( @verdict, "Pass(A):" . $passA );
		push( @verdict, "Fail(A):" . $failA );
		push( @verdict, "Block(A):" . $blockA );
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

sub changeDirStructure_wanted {
	my $dir = $File::Find::name;
	if ( $dir =~ /.*\/([0-9:\.\-]+)$/ ) {
		if ( $dir !~ /[0-9:\.\-]+\/opt/ ) {
			my $time = $1;
			$combined_xml = "none";
			find( \&findXml_wanted, $result_dir_lite . "/" . $time );
			if ( $combined_xml ne "none" ) {
				$dir_root = $result_dir_lite . "/" . $time;
				rewriteXmlFile($combined_xml);
			}
		}
	}
}

sub findXml_wanted {
	my $dir = $File::Find::name;
	if (   ( $dir =~ /tests\..{6}\.result\.xml/ )
		or ( $dir =~ /tests\.result\.xml/ ) )
	{
		$combined_xml = $dir;
	}
}

sub rewriteXmlFile {
	my ($combined_xml) = @_;
	my $need_manual_carriage_return = "FALSE";
	open FILE, $combined_xml
	  or die "can't open " . $combined_xml;
	my $content      = "none";
	my $package_name = "none";
	while (<FILE>) {
		if ( $_ =~ /<suite.*name="(.*?)">/ ) {
			$package_name = $1;
			$package_name =~ s/ /-/g;
			$content = $_;
		}

		# write to file for every end of a suite
		elsif ( $_ =~ /<\/suite>/ ) {
			$content .= $_;
			mkdirWriteXmlResult( $package_name, $content,
				$need_manual_carriage_return );
		}
		else {
			$content .= $_;
		}
	}
}

sub mkdirWriteXmlResult {
	my ( $package_name, $content, $need_manual_carriage_return ) = @_;
	my @carriage_list = (
		'<suite.*?>',           '</suite>',
		'<set.*?>',             '</set>',
		'<testcase.*?>',        '</testcase>',
		'<description>',        '</description>',
		'<notes\s*/>',          '</notes>',
		'<pre_condition\s*/>',  '</pre_condition>',
		'<post_condition\s*/>', '</post_condition>',
		'<steps>',              '</steps>',
		'<step order.*?>',      '</step>',
		'</step_desc>',         '</expected>',
		'</test_script_entry>', '<result_info>',
		'</result_info>',       '<actual_result\s*/>',
		'</actual_result>',     '<start\s*/>',
		'</start>',             '<end\s*/>',
		'</end>',               '<stdout\s*/>',
		'</stdout>',            '<stderr\s*/>',
		'</stderr>',            '<categories\s*/>',
		'<categories>',         '</categories>',
		'</category>',          '<spec\s*/>',
		'</spec>'
	);
	foreach (@carriage_list) {

		# add carriage return manually, use it when it has -o option
		if ( $need_manual_carriage_return eq "TRUE" ) {
			$content =~ s/($_)/$1\n/g;
		}
	}

	# make dir to write result
	if ( !( -e $dir_root . "/usr/share/" . $package_name ) ) {
		system( "mkdir -p " . $dir_root . "/usr/share/" . $package_name );
	}
	else {
		system( "rm -rf " . $dir_root . "/usr/share/" . $package_name );
		system( "mkdir -p " . $dir_root . "/usr/share/" . $package_name );
	}

	# write to file
	my $file;
	open $file,
	  ">" . $dir_root . "/usr/share/" . $package_name . "/tests.result.xml"
	  or die "Failed to open file "
	  . $dir_root
	  . "/usr/share/"
	  . $package_name
	  . "/tests.result.xml for writing: $!";
	print {$file} $content;
	close $file;
}

# should alway copy from Templates.pm
sub sdbPullFile {
	my ( $copy_from, $copy_to ) = @_;
	system( sdb_cmd("pull $copy_from $copy_to") );
}

sub syncDefinition {
	use threads;
	my @pull_thread_list = ();

	# sync xml definition files
	system( "rm -rf $test_definition_dir" . "*" );
	system( "rm -rf $opt_dir" . "*" );
	my $cmd_definition = sdb_cmd("shell 'ls /usr/share/*/tests.xml'");
	my $definition     = `$cmd_definition`;
	my @definitions    = $definition =~ /(\/usr\/share\/.*?\/tests.xml)/g;
	if (   ( @definitions >= 1 )
		&& ( $definition !~ /No such file or directory/ ) )
	{
		foreach (@definitions) {
			my $definition = "";
			if ( $_ =~ /(\/usr\/share\/.*\/tests.xml)/ ) {
				$definition = $1;
			}
			$definition =~ s/^\s//;
			$definition =~ s/\s*$//;
			if ( $definition =~ /share\/(.*)\/tests.xml/ ) {
				my $package_name = $1;
				if ( $package_name =~ /-tests$/ ) {
					system("mkdir $test_definition_dir$package_name");
					system("mkdir $opt_dir$package_name");
					system(
						"echo 'No readme info' > $opt_dir$package_name/README");
					system(
						"echo 'No license info' > $opt_dir$package_name/LICENSE"
					);
					my $copy_to = $test_definition_dir . $package_name;
					my $pull_thread =
					  threads->create( \&sdbPullFile, $definition, $copy_to );
					push( @pull_thread_list, $pull_thread );
				}
			}
		}
	}

	# sync readme files and license files
	my $cmd_readme = sdb_cmd("shell 'ls /opt/*/README'");
	my $readme     = `$cmd_readme`;
	my @readmes    = $readme =~ /(\/opt\/.*?\/README)/g;
	if ( ( @readmes >= 1 ) && ( $readme !~ /No such file or directory/ ) ) {
		foreach (@readmes) {
			my $readme = "";
			if ( $_ =~ /(\/opt\/.*\/README)/ ) {
				$readme = $1;
			}
			$readme =~ s/^\s//;
			$readme =~ s/\s$//;
			if ( $readme =~ /opt\/(.*)\/README/ ) {
				my $package_name = $1;
				if ( $package_name =~ /-tests$/ ) {
					my $copy_to = $opt_dir . $package_name;
					my $pull_thread =
					  threads->create( \&sdbPullFile, $readme, $copy_to );
					push( @pull_thread_list, $pull_thread );
					my $license_cmd_tmp =
					  sdb_cmd("shell 'ls /opt/$package_name/LICENSE'");
					my $license_cmd = `$license_cmd_tmp`;
					if ( $license_cmd !~ /No such file or directory/ ) {
						my $license = $readme;
						$license =~ s/README/LICENSE/;
						my $copy_to = $opt_dir . $package_name;
						my $pull_thread =
						  threads->create( \&sdbPullFile, $license, $copy_to );
						push( @pull_thread_list, $pull_thread );
					}
				}
			}
		}
	}
	foreach (@pull_thread_list) {
		$_->join();
	}
}

1;
