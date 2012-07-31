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

use FindBin;
use strict;
use Templates;
use File::Find;
use Data::Dumper;
use Digest::SHA qw(sha1_hex);

# data which is going to be displayed
my $result_dir_manager = $FindBin::Bin . "/../../../results/";
my $result_dir_lite    = $FindBin::Bin . "/../../../../lite/";
my @report_display     = ();
my @select_dir         = ();
my @package_list       = ();
my @test_type        = ();         #which test type are stored in the xml
my $hasTestTypeError = "FALSE";    #have error when list all cases by test type
my %caseInfo;                      #parse all info items from xml
my %manual_case_result;            #parse manual case result from txt file
my %component_list
  ;               #extract component and give it format like 1->a::root__b::root
my %spec_list;    #extract spec and give it format like 1->a::root__b::root
my %steps;        #parse steps part of the case info
my @result_list_xml =
  ();    #put all xml and txt result into format --form report.1=@sim.xml
my @result_list_txt =
  ();    #put all xml and txt result into format --form attachment.1=sim.txt
my %result_list_tree;    #(total pass fail not run) for tree view
my @same_package_list = ();    #extract same packages from selected reports
my $max_package_number =
  0;    #extract the maximum package number from selected reports
my %all_package_list;    #store package distribution

# clear text pipe
autoflush_on();

# press compare button
if ( $_POST{'compare'} ) {
	updateSelectDir(%_POST);
	getSamePackage();

	print "HTTP/1.0 200 OK" . CRLF;
	print "Content-type: text/html" . CRLF . CRLF;
	print_header( "$MTK_BRANCH Manager Test Report", "report" );

	if ( @same_package_list > 0 ) {
		print <<DATA;
<div id="message"></div>
<table width="1280" border="0" cellspacing="0" cellpadding="0" class="report_list" style="table-layout:fixed">
  <tr>
    <td height="50"><table width="100%" height="50" border="0" cellpadding="0" cellspacing="0">
        <tr style="font-size:24px">
DATA
		for ( my $i = 0 ; $i < @select_dir ; $i++ ) {
			my $time       = $select_dir[$i];
			my $class_time = "report_list_outside_left_compare_empty";
			print <<DATA;
          <td class="$class_time" align="center">$time</td>
DATA
		}
		print <<DATA;
        </tr>
      </table></td>
  </tr>
DATA
		for ( keys(%all_package_list) ) {
			my $package      = $_;
			my @which_report = split( ':', $all_package_list{$_} );
			my $package_temp = $package;
			$package_temp =~ s/_tests.xml//;
			print <<DATA;
  <tr style="font-size:24px">
    <td height="50" class="report_list_outside_left_compare" align="left" style="background-color:#89D6F2">&nbsp;Package Name: $package_temp</td>
  </tr>
  <tr>
    <td><table width="100%" border="0" cellspacing="0" cellpadding="0">
        <tr>
DATA
			my %case_result;
			my @color_change = ();
			for ( my $i = 0 ; $i < @select_dir ; $i++ ) {
				my $time            = $select_dir[$i];
				my $class_td_border = "report_list_outside_left_compare";
				my $class_name      = "report_list_outside_left";
				my $class_result    = "report_list_one_row";

				my $should_print = "FALSE";
				foreach (@which_report) {
					if ( $_ eq $i ) {
						$should_print = "TRUE";
					}
				}
				if ( $should_print eq "TRUE" ) {
					print <<DATA;
          <td valign="top" class="$class_td_border"><table width="100%" border="0" cellspacing="0" cellpadding="0" style="table-layout:fixed">
              <tr style="font-size:24px">
                <td width="80%" height="50" class="$class_name" align="left">&nbsp;Name</td>
                <td width="20%" height="50" class="$class_result" align="center" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="Result">Result</td>
              </tr>
DATA

					# print Auto case
					my $startCase = "FALSE";
					my $xml       = "none";
					my $name      = "none";
					my $result    = "none";
					my $isAuto    = "FALSE";
					my $xml_url =
					  $result_dir_manager . $select_dir[$i] . '/' . $package;
					open FILE, $xml_url or die $!;

					while (<FILE>) {
						if ( $startCase eq "TRUE" ) {
							chomp( $xml .= $_ );
						}
						if ( $_ =~ /.*<testcase.*execution_type="auto".*/ ) {
							$isAuto    = "TRUE";
							$startCase = "TRUE";
							chomp( $xml = $_ );

							if ( $_ =~ /result="(.*?)"/ ) {
								$result = $1;
							}
							if ( $_ =~ /testcase.*id="(.*?)".*/ ) {
								$name = $1;
							}
						}
						if (   ( $_ =~ /.*<\/testcase>.*/ )
							&& ( $isAuto eq "TRUE" ) )
						{
							$startCase = "FALSE";
							%caseInfo  = updateCaseInfo($xml);

							my $id = 'ID_' . sha1_hex( $package_temp . $name );
							if ( defined( $case_result{$id} ) ) {
								if ( $case_result{$id} ne $result ) {
									push( @color_change, $id );
								}
							}
							else {
								$case_result{$id} = $result;
							}
							$id .= '_' . $i;
							print <<DATA;
              <tr id = "$id">
                <td width="80%" height="50" class="$class_name" align="left" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$name"><a class="view_case_detail" onclick="javascript:show_case_detail('detailed_$id');">&nbsp;$name</a></td>
                <td width="20%" height="50" class="$class_result" align="center" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$result">$result</td>
              </tr>
DATA
							print <<DATA;
              <tr id="detailed_$id" style="display:none">
                <td height="50" colspan="2">
DATA
							printDetailedCaseInfo( $name, 'auto', %caseInfo );
							print <<DATA;
                </td>
              </tr>
DATA
						}
					}

					# print Manual case
					my $isManual = "FALSE";
					%manual_case_result =
					  updateManualCaseResult( $select_dir[$i], $package_temp );
					my $def_tests_xml_dir =
					    $result_dir_manager 
					  . $time . "/"
					  . $package_temp
					  . "_definition.xml";
					open FILE, $def_tests_xml_dir or die $!;
					while (<FILE>) {
						if ( $startCase eq "TRUE" ) {
							chomp( $xml .= $_ );
						}
						if ( $_ =~ /testcase.*execution_type="manual".*/ ) {
							$startCase = "TRUE";
							$isManual  = "TRUE";
							chomp( $xml = $_ );

							if ( $_ =~ /testcase.*id="(.*?)".*/ ) {
								$name = $1;
							}
						}
						if ( $_ =~ /testcase.*execution_type="auto".*/ ) {
							$isManual = "FALSE";
						}
						if (   ( $_ =~ /.*<\/testcase>.*/ )
							&& ( $isManual eq "TRUE" ) )
						{
							if ( defined $manual_case_result{$name} ) {
								$startCase = "FALSE";
								%caseInfo  = updateCaseInfo($xml);
								my $id_textarea =
								    "textarea__P:"
								  . $package_temp . '__N:'
								  . $name;
								my $id_bugnumber =
								    "bugnumber__P:"
								  . $package_temp . '__N:'
								  . $name;
								$result = $manual_case_result{$name};
								my $id =
								  'ID_' . sha1_hex( $package_temp . $name );
								if ( defined( $case_result{$id} ) ) {
									if ( $case_result{$id} ne $result ) {
										push( @color_change, $id );
									}
								}
								else {
									$case_result{$id} = $result;
								}
								$id .= '_' . $i;
								print <<DATA;
              <tr id = "$id">
                <td width="80%" height="50" class="$class_name" align="left" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$name"><a class="view_case_detail" onclick="javascript:show_case_detail('detailed_$id');">&nbsp;$name</a></td>
                <td width="20%" height="50" class="$class_result" align="center" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$result">$result</td>
              </tr>
DATA
								print <<DATA;
              <tr id="detailed_$id" style="display:none">
                <td height="50" colspan="2">
DATA
								printDetailedCaseInfoWithComment( $name,
									'manual', $time, $id_textarea,
									$id_bugnumber, %caseInfo );
								print <<DATA;
                </td>
              </tr>
DATA
							}
						}
					}
				}
				else {
					$class_td_border = "report_list_outside_left_compare_empty";
					print <<DATA;
          <td valign="top" class="$class_td_border"><table width="100%" border="0" cellspacing="0" cellpadding="0" style="table-layout:fixed">
              <tr style="font-size:24px">
                <td width="80%" height="50" class="$class_name" align="left">&nbsp;Name</td>
                <td width="20%" height="50" class="$class_result" align="center" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="Result">Result</td>
              </tr>
              <tr>
                <td width="80%" height="50" class="$class_name" align="left">&nbsp;None</td>
                <td width="20%" height="50" class="$class_result" align="center" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="Result">None</td>
              </tr>
DATA
				}
				print <<DATA;
            </table></td>
DATA
				foreach (@color_change) {
					my $total_number = @select_dir;
					print <<DATA;
<script language="javascript" type="text/javascript">
// <![CDATA[
for ( var i = 0; i < $total_number; i++) {
	var error_tr = document.getElementById("$_" + "_" + i);
	if (error_tr) {
		error_tr.style.backgroundColor = "#D5B584";
	}
}
// ]]>
</script>
DATA
				}
			}
			print <<DATA;
        </tr>
      </table></td>
  </tr>
DATA
		}
		print <<DATA;
</table>
<script language="javascript" type="text/javascript">
// <![CDATA[
function show_case_detail(id) {
	var display = document.getElementById(id).style.display;
	if (display == "none") {
		document.getElementById(id).style.display = "";
	} else {
		document.getElementById(id).style.display = "none";
	}
}
// ]]>
</script>
DATA
	}
	else {
		print show_error_dlg(
			"No same package is found from the selected reports");
		showReport();
	}
}

# press delete button
elsif ( $_POST{'delete'} ) {
	updateSelectDir(%_POST);
	foreach (@select_dir) {
		system("rm -rf $result_dir_manager$_");
		system("rm -rf $result_dir_lite$_");
	}

	my $report_ori      = $result_dir_manager . '*s';
	my $histtory_ori    = $result_dir_manager . 'HISTORY';
	my $latest_ori      = $result_dir_manager . 'latest';
	my $latest_ori_lite = $result_dir_lite . 'latest';
	system("rm -rf $report_ori");
	system("rm -rf $histtory_ori");
	system("rm -rf $latest_ori");
	system("rm -rf $latest_ori_lite");

	print "HTTP/1.0 200 OK" . CRLF;
	print "Content-type: text/html" . CRLF . CRLF;
	print_header( "$MTK_BRANCH Manager Test Report", "report" );

	showReport();
}

# press mail button
elsif ( $_POST{'mail'} ) {

	updateSelectDir(%_POST);

	print "HTTP/1.0 200 OK" . CRLF;
	print "Content-type: text/html" . CRLF . CRLF;
	print_header( "$MTK_BRANCH Manager Test Report", "report" );

	foreach (@select_dir) {
		updateResultList($_);
	}

	my $hasEvolution = `which evolution 2>&1`;
	if ( $hasEvolution =~ /which: no/ ) {
		my $attach = "";
		for ( my $i = 1 ; $i <= @result_list_xml ; $i++ ) {
			$attach .= '<p>' . $result_list_xml[ $i - 1 ] . '</p>';
		}
		my $form_txt = "";
		for ( my $i = 1 ; $i <= @result_list_txt ; $i++ ) {
			$attach .= '<p>' . $result_list_txt[ $i - 1 ] . '</p>';
		}
		print show_error_dlg(
"<p>Can't find Evolution in your system</p><p>Please send the following attachments manually:</p>"
			  . $attach );
	}
	else {
		my $form_xml = "";
		for ( my $i = 1 ; $i <= @result_list_xml ; $i++ ) {
			$form_xml .= '\&attach="' . $result_list_xml[ $i - 1 ] . '"';
		}
		my $form_txt = "";
		for ( my $i = 1 ; $i <= @result_list_txt ; $i++ ) {
			$form_txt .= '\&attach="' . $result_list_txt[ $i - 1 ] . '"';
		}
		my $command =
'subject=Test%20report%20from%20testkit-manager\&body=Please%20check%20detailed%20report%20from%20the%20attachment'
		  . $form_xml
		  . $form_txt;
		$command =~ s/:/%3A/g;
		$command = "export DISPLAY=:0.0;su tizen -c 'evolution mailto:?" 
		  . $command . "'";

		use threads;
		my $thr = threads->new( \&callSystem, $command );
		print show_message_dlg("Please specify a receiver in the Evolution");
	}

	showReport();
}

# press submit button from submit server page
elsif ( $_POST{'submit_server'} ) {
	updateSelectDir(%_POST);
	my $server_name = $_POST{"server_name"};
	my $token       = $_POST{"token"};
	my $image_date  = $_POST{"image_date"};
	my $target      = $_POST{"target"};
	my $testtype    = $_POST{"testtype"};
	my $hwproduct   = $_POST{"hwproduct"};

	print "HTTP/1.0 200 OK" . CRLF;
	print "Content-type: text/html" . CRLF . CRLF;
	print_header( "$MTK_BRANCH Manager Test Report", "report" );

	if (   ( $server_name ne "" )
		&& ( $token      ne "" )
		&& ( $image_date ne "" )
		&& ( $target     ne "target" )
		&& ( $testtype   ne "testtype" )
		&& ( $hwproduct  ne "hwproduct" ) )
	{
		foreach (@select_dir) {
			updateResultList($_);
		}
		my $form_xml = "";
		for ( my $i = 1 ; $i <= @result_list_xml ; $i++ ) {
			$form_xml .=
			  " --form report." . $i . "=@" . $result_list_xml[ $i - 1 ];
		}
		my $form_txt = "";
		for ( my $i = 1 ; $i <= @result_list_txt ; $i++ ) {
			$form_txt .=
			  " --form attachment." . $i . "=@" . $result_list_txt[ $i - 1 ];
		}
		my $command = "curl"
		  . $form_xml
		  . $form_txt
		  . " http://"
		  . $server_name
		  . "/api/import?auth_token="
		  . $token
		  . "\\&release_version=V1"
		  . "\\&target="
		  . $target
		  . "\\&testtype="
		  . $testtype
		  . "\\&hwproduct="
		  . $hwproduct
		  . "\\&build_id="
		  . $image_date;
		$command =~ s/:/\\:/g;
		$command =~ s/http\\:/http\:/g;
		my $submit_result = `$command`;
		if ( $submit_result =~ /"ok":"1"/ ) {
			print show_message_dlg("Reports have been submitted");
		}
		else {
			print show_error_dlg($submit_result);
		}
	}
	else {
		print show_error_dlg("Missing submit parameter");
	}
	showReport();
}

# press submit button
elsif ( $_POST{'submit'} ) {
	print "HTTP/1.0 200 OK" . CRLF;
	print "Content-type: text/html" . CRLF . CRLF;
	print_header( "$MTK_BRANCH Manager Test Report", "report" );

	updateSelectDir(%_POST);

	print <<DATA;
<div id="message"></div>
<table width="1280" border="0" cellspacing="0" cellpadding="0">
  <tr>
    <td><form id="submit_server" name="submit_server" method="post" action="tests_report.pl">
      <table width="100%" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td height="50"  background="images/report_top_button_background.png">
<table width="100%" height="50" border="0" cellpadding="0" cellspacing="0">
  <tr>
    <td width="25">&nbsp;</td>
    <td width="200" align="left" valign="middle"><input name="server_name" type="text" class="submit_server" id="server_name" onfocus="javascript:submit_perpare('server_name');" value="Input Server Name" /></td>
    <td width="200" align="left" valign="middle"><input name="token" type="text" class="submit_server" id="token" onfocus="javascript:submit_perpare('token');" value="Input Token" /></td>
    <td width="200" align="left" valign="middle"><input name="image_date" type="text" class="submit_server" id="image_date" onfocus="javascript:submit_perpare('image_date');" value="Input Image Date" /></td>
    <td width="90" align="left" valign="middle"><select name="target" id="target">
        <option>Common</option>
        <option>Netbook</option>
        <option>IVI</option>
        <option>SDK</option>
        <option>TV</option>
        <option selected="selected">target</option>
      </select>
    </td>
    <td width="170" align="left" valign="middle"><select name="testtype" id="testtype">
        <option>CRX-WebAPI-Auto</option>
        <option>Full Feature</option>
        <option>Middleware</option>
        <option>Middleware-Auto</option>
        <option>WebAPI</option>
        <option>WebAPI-Auto</option>
        <option>WebApp</option>
        <option>Sanity Test</option>
        <option>Stability Test</option>
        <option>UX Key Feature Test</option>
        <option>Exploration Testing</option>
        <option>API Testing</option>
        <option>Emulator</option>
        <option>GUI Builder</option>
        <option>Web Simualtor</option>
        <option>Sanity Test</option>
        <option selected="selected">testtype</option>
      </select>
    </td>
    <td width="120" align="left" valign="middle"><select name="hwproduct" id="hwproduct">
        <option>Cedartrail</option>
        <option>Pinetrail</option>
        <option>TunnelCreek</option>
        <option selected="selected">hwproduct</option>
      </select>
    </td>
    <td width="125" align="center" valign="middle"><input type="submit" name="submit_server" id="submit_button" value="Submit" disabled="disabled" class="bottom_button" /></td>
    <td>&nbsp;</td>
  </tr>
</table>
          </td>
        </tr>
        <tr>
          <td><table width="100%" border="1" cellpadding="0" cellspacing="0" class="report_list" frame="below" rules="all">
            <tr style="font-size:24px">
              <td width="4%" height="50" class="report_list_one_row">&nbsp;</td>
              <td align="left" height="50" class="report_list_one_row">The following report(s) will be submitted to the QA report server:</td>
            </tr>
DATA
	my $number = 1;
	foreach (@select_dir) {
		print <<DATA;
            <tr>
              <td align="left" width="4%" height="50" class="report_list_outside_left">&nbsp;&nbsp;&nbsp;$number.</td>
              <td align="left" height="50" class="report_list_outside_right">&nbsp;$_<input type="text" name="$_" value="" style="display:none" /></td>
            </tr>
DATA
		$number++;
	}
	print <<DATA;
          </table></td>
        </tr>
      </table>
        </form>
    </td>
  </tr>
</table>
<script language="javascript" type="text/javascript">
// <![CDATA[
function submit_perpare(id) {
	document.getElementById(id).value = "";
	button = document.getElementById('submit_button');
	if (button) {
		button.disabled = 0;
	}
}
// ]]>
</script>
DATA
}

# press export button
elsif ( $_POST{'export'} ) {

	# TODO: finish code here
	print "HTTP/1.0 200 OK" . CRLF;
	print "Content-type: text/html" . CRLF . CRLF;
	print_header( "$MTK_BRANCH Manager Test Report", "report" );

	print show_not_implemented("Export");
}

# click summary icon
elsif ( $_GET{'time'} ) {
	if ( $_GET{'summary'} ) {
		print "HTTP/1.0 200 OK" . CRLF;
		print "Content-type: text/html" . CRLF . CRLF;
		print_header( "$MTK_BRANCH Manager Test Report", "report" );

		showSummaryReport( $_GET{'time'} );
	}
	if ( $_GET{'detailed'} ) {
		print "HTTP/1.0 200 OK" . CRLF;
		print "Content-type: text/html" . CRLF . CRLF;
		print_header( "$MTK_BRANCH Manager Test Report", "report" );

		showDetailedReport( $_GET{'time'} );
	}
}

# show normal report list
else {
	print "HTTP/1.0 200 OK" . CRLF;
	print "Content-type: text/html" . CRLF . CRLF;
	print_header( "$MTK_BRANCH Manager Test Report", "report" );

	# show report list according to the result folder
	showReport();
}

print_footer("");

sub showReport {
	getReportDisplayData();

	print <<DATA;
<table width="1280" border="0" cellspacing="0" cellpadding="0" class="report_list">
  <tr>
    <td><form id="report_list" name="report_list" method="post" action="tests_report.pl">
      <table width="1280" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td height="50" background="images/report_top_button_background.png"><table width="1280" height="50" border="0" cellpadding="0" cellspacing="0">
            <tr>
              <td width="2%">&nbsp;</td>
              <td><table width="100%" height="50" border="0" cellpadding="0" cellspacing="0">
                <tr>
                  <td width="119"><input type="submit" name="compare" id="compare_button" value="Compare" disabled="disabled" class="top_button" /></td>
                  <td width="10"><img src="images/environment-spacer.gif" alt="" width="10" height="1" /></td>
                  <td width="119"><input type="submit" name="delete" id="delete_button" value="Delete" disabled="disabled" onclick="javascript:return confirm_remove();" class="top_button" /></td>
                  <td>&nbsp;</td>
                </tr>
              </table></td>
            </tr>
          </table></td>
        </tr>
        <tr>
          <td><table width="1280" border="1" cellspacing="0" cellpadding="0" frame="below" rules="all">
            <tr style="font-size:24px">
              <td width="4%" height="50" align="center" valign="middle" class="report_list_outside_left"><label>
                <input type="checkbox" name="check_all" id="check_all" onclick="javascript:check_uncheck_all();" />
              </label></td>
              <td align="left" width="24%" class="report_list_inside">&nbsp;Time</td>
              <td align="left" width="12%" class="report_list_inside">&nbsp;User Name</td>
              <td align="left" width="12%" class="report_list_inside">&nbsp;Platform</td>
              <td width="24%" class="report_list_inside"><table width="100%" height="50" border="0" cellpadding="0" cellspacing="0">
                <tr>
                  <td width="20%" align="center">Total</td>
                  <td width="3%" align="center" valign="middle"><img src="images/splitter_result.png" width="2" height="20" /></td>
                  <td width="20%" align="center">Pass</td>
                  <td width="3%" align="center" valign="middle"><img src="images/splitter_result.png" width="2" height="20" /></td>
                  <td width="20%" align="center">Fail</td>
                  <td width="3%" align="center" valign="middle"><img src="images/splitter_result.png" width="2" height="20" /></td>
                  <td width="28%" align="center">Not run</td>
                  <td width="3%" align="center">&nbsp;</td>
                </tr>
              </table></td>
              <td align="left" width="24%" class="report_list_outside_right">&nbsp;Operation</td>
            </tr>
DATA

	# print data from runconfig and info file
	my $count = 0;
	while ( $count < @report_display ) {
		my $time      = $report_display[ $count++ ];
		my $user_name = $report_display[ $count++ ];
		my $platform  = $report_display[ $count++ ];
		my $total     = $report_display[ $count++ ];
		my $pass      = $report_display[ $count++ ];
		my $fail      = $report_display[ $count++ ];
		my $not_run   = $report_display[ $count++ ];
		print <<DATA;
            <tr>
              <td width="4%" height="50" align="center" valign="middle" class="report_list_outside_left"><label>
                <input type="checkbox" id="$time" name="$time" onclick="javascript:update_state();" />
              </label></td>
              <td align="left" width="24%" class="report_list_inside">&nbsp;$time</td>
              <td align="left" width="12%" class="report_list_inside">&nbsp;$user_name</td>
              <td align="left" width="12%" class="report_list_inside">&nbsp;$platform</td>
              <td width="24%" class="report_list_inside"><table width="100%" height="50" border="0" cellpadding="0" cellspacing="0">
                <tr>
                  <td width="20%" align="left">&nbsp;&nbsp;&nbsp;$total</td>
                  <td width="3%" align="center">&nbsp;</td>
                  <td width="20%" align="left" class="result_pass">&nbsp;&nbsp;&nbsp;&nbsp;$pass</td>
                  <td width="3%" align="center">&nbsp;</td>
                  <td width="20%" align="left" class="result_fail">&nbsp;&nbsp;&nbsp;&nbsp;$fail</td>
                  <td width="3%" align="center">&nbsp;</td>
                  <td width="25%" align="left" class="result_not_run">&nbsp;&nbsp;$not_run</td>
                  <td width="6%" align="center">&nbsp;</td>
                </tr>
              </table></td>
              <td align="left" width="24%" class="report_list_outside_right"><table width="100%" height="50" border="0" cellpadding="0" cellspacing="0">
                <tr>
                  <td><a href="tests_report.pl?time=$time&summary=1"><img title="View Summary Report" src="images/operation_view_summary_report.png" alt="operation_view_summary_report" width="38" height="38" /></a></td>
                  <td><a href="tests_report.pl?time=$time&detailed=1"><img title="View Detailed Report" src="images/operation_view_detailed_report.png" alt="operation_view_detailed_report" width="38" height="38" border="0" /></a></td>
DATA

		if ( $not_run ne "0" ) {
			print <<DATA;
                  <td><a href="tests_execute_manual.pl?time=$time"><img title="Continue Execution" src="images/operation_continue_execution_enable.png" alt="operation_continue_execution_enable" width="38" height="38" /></a></td>
DATA
		}
		else {
			print <<DATA;
                  <td><img title="Execution Complete" src="images/operation_continue_execution_disable.png" alt="operation_continue_execution_disable" width="38" height="38" /></td>
DATA
		}
		print <<DATA;
                </tr>
              </table></td>
            </tr>
DATA
	}
	print <<DATA;
          </table></td>
        </tr>
        <tr>
          <td height="50"><table width="1280" height="50" border="0" cellpadding="0" cellspacing="0">
            <tr>
              <td width="4%">&nbsp;</td>
              <td><label></label>
                <table width="100%" height="50" border="0" cellpadding="0" cellspacing="0">
                  <tr>
                    <td width="95"><input type="submit" name="mail" id="mail_button" value="Mail" disabled="disabled" onclick="javascript:mail_report();" class="bottom_button" /></td>
                    <td width="10"><img src="images/environment-spacer.gif" alt="" width="10" height="1" /></td>
                    <td width="95"><input type="submit" name="submit" id="submit_button" value="Submit" disabled="disabled" onclick="javascript:submit_report();" class="bottom_button" /></td>
                    <td width="10"><img src="images/environment-spacer.gif" alt="" width="10" height="1" /></td>
                    <td width="95"><input type="submit" name="export" id="export_button" value="Export" disabled="disabled" onclick="javascript:export_report();" class="bottom_button" /></td>
                    <td>&nbsp;</td>
                  </tr>
                </table></td>
            </tr>
          </table></td>
        </tr>
      </table>
        </form>
    </td>
  </tr>
</table>
<script language="javascript" type="text/javascript">
// <![CDATA[
function count_checked() {
	var num = 0;
	var form = document.report_list;
	for (var i=0; i<form.length; ++i) {
		if ((form[i].type.toLowerCase() == 'checkbox') && (form[i].name != 'check_all') && form[i].checked) {
			++num;
		}
	}
	return num;
}

function count_checkbox() {
	var num = 0;
	var form = document.report_list;
	for (var i=0; i<form.length; ++i) {
		if ((form[i].type.toLowerCase() == 'checkbox') && (form[i].name != 'check_all')) {
			++num;
		}
	}
	return num;
}

function update_state() {
	var button;
	var num_checked = count_checked();
	var num_checkbox = count_checkbox();
	button = document.getElementById('delete_button');
	if (button) {
		button.disabled = (num_checked == 0);
	}
	button = document.getElementById('compare_button');
	if (button) {
		button.disabled = (num_checked < 2);
	}
	button = document.getElementById('mail_button');
	if (button) {
		button.disabled = (num_checked == 0);
	}
	button = document.getElementById('submit_button');
	if (button) {
		button.disabled = (num_checked == 0);
	}
	button = document.getElementById('export_button');
	if (button) {
		button.disabled = (num_checked == 0);
	}
	var elem = document.getElementById('check_all');
	if (num_checked == num_checkbox){
		elem.checked = 1
	} else {
		elem.checked = 0
	}
}

function check_uncheck(box, check) {
	temp = box.onchange;
	box.onchange = null;
	box.checked = check;
	box.onchange = temp;
}

function check_uncheck_all() {
	var elem = document.getElementById('check_all');
	if (elem) {
		var checked = elem.checked;
		var form = document.report_list;
		for (var i=0; i<form.length; ++i) {
			if ((form[i].type.toLowerCase() == 'checkbox') && (form[i].name != 'check_all'))
				check_uncheck(form[i], checked);
		}
		update_state();
	}
}

function confirm_remove() {
	var num = count_checked();
	if (num == 0) {
		alert('Nothing selected!');
		return false;
	}
	else
		return confirm('Do you wish to delete ' + num + ' selected report(s)?');
}
// ]]>
</script>
DATA
}

sub showSummaryReport {
	my ($time)         = @_;
	my $result_dir     = $result_dir_manager . $time;
	my $result_dir_tgz = $result_dir_manager . $time . "/" . $time . ".tgz";
	my $runconfig_path = $result_dir . "/runconfig";
	my $info_path      = $result_dir . "/info";

	my $platform         = "none";
	my $package_manager  = "none";
	my $username         = "none";
	my $hostname         = "none";
	my $kernel           = "none";
	my $operation_system = "none";

	# get data from runconfig
	open FILE, $runconfig_path or die $!;
	while (<FILE>) {
		if ( $_ =~ /Hardware Platform:(.*)/ ) {
			$platform = $1;
		}
		if ( $_ =~ /Package Manager:(.*)/ ) {
			$package_manager = $1;
		}
		if ( $_ =~ /Username:(.*)/ ) {
			$username = $1;
		}
		if ( $_ =~ /Hostname:(.*)/ ) {
			$hostname = $1;
		}
		if ( $_ =~ /Kernel:(.*)/ ) {
			$kernel = $1;
		}
		if ( $_ =~ /Operation System:(.*)/ ) {
			$operation_system = $1;
		}
	}

	my $whole_total_a   = "none";
	my $whole_pass_a    = "none";
	my $whole_fail_a    = "none";
	my $whole_not_run_a = "none";
	my $whole_total_m   = "none";
	my $whole_pass_m    = "none";
	my $whole_fail_m    = "none";
	my $whole_not_run_m = "none";
	my $whole_status    = "complete";

	print <<DATA;
<table width="1280" border="0" cellspacing="0" cellpadding="0" class="report_list">
  <tr style="font-size:24px">
    <td align="left" height="50" background="images/report_top_button_background.png">&nbsp;Test Environment</td>
  </tr>
  <tr>
    <td><table width="100%" border="1" cellspacing="0" cellpadding="0" frame="below" rules="all">
      <tr>
        <td align="left" width="50%" height="50" class="report_list_outside_left" style="font-size:24px">&nbsp;Platform</td>
        <td align="left" width="50%" height="50" class="report_list_outside_right">&nbsp;$platform</td>
      </tr>
      <tr>
        <td align="left" width="50%" height="50" class="report_list_outside_left" style="font-size:24px">&nbsp;Package Manager </td>
        <td align="left" width="50%" height="50"class="report_list_outside_right">&nbsp;$package_manager</td>
      </tr>
      <tr>
        <td align="left" width="50%" height="50" class="report_list_outside_left" style="font-size:24px">&nbsp;Username</td>
        <td align="left" width="50%" height="50"class="report_list_outside_right">&nbsp;$username</td>
      </tr>
      <tr>
        <td align="left" width="50%" height="50" class="report_list_outside_left" style="font-size:24px">&nbsp;Hostname</td>
        <td align="left" width="50%" height="50"class="report_list_outside_right">&nbsp;$hostname</td>
      </tr>
      <tr>
        <td align="left" width="50%" height="50" class="report_list_outside_left" style="font-size:24px">&nbsp;Kernel</td>
        <td align="left" width="50%" height="50"class="report_list_outside_right">&nbsp;$kernel</td>
      </tr>
      <tr>
        <td align="left" width="50%" height="50" class="report_list_outside_left" style="font-size:24px">&nbsp;Operation System </td>
        <td align="left" width="50%" height="50"class="report_list_outside_right">&nbsp;$operation_system</td>
      </tr>
    </table></td>
  </tr>
  <tr style="font-size:24px">
    <td align="left" height="50" style="background-color:#88D6F2">&nbsp;Test Result for&nbsp;&nbsp;$time&nbsp;&nbsp;<a href="tests_report.pl?time=$time&detailed=1"><img title="View Detailed Report" src="images/operation_view_detailed_report.png" alt="operation_view_detailed_report" width="38" height="38" /></a></td>
  </tr>
  <tr>
    <td><table width="100%" border="1" cellspacing="0" cellpadding="0" frame="below" rules="all">
      <tr style="font-size:24px">
        <td align="left" width="25%" height="50" class="report_list_outside_left">&nbsp;Package Name</td>
        <td align="left" width="12%" height="50" class="report_list_inside">&nbsp;Type</td>
        <td align="left" width="13%" height="50" class="report_list_inside">&nbsp;Status</td>
        <td align="left" width="12%" height="50" class="report_list_outside_right">&nbsp;Total</td>
        <td align="left" width="12%" height="50" class="report_list_one_row">&nbsp;Pass</td>
        <td align="left" width="12%" height="50" class="report_list_one_row">&nbsp;Fail</td>
        <td align="left" width="14%" height="50" class="report_list_one_row">&nbsp;Not run</td>
      </tr>
DATA

	# get data from info
	open FILE, $info_path or die $!;
	my @data = ();
	while (<FILE>) {
		if ( $_ =~ /Package:(.*)/ ) {
			push( @data, $1 );
		}
		if ( $_ =~ /Total\(M\):(.*)/ ) {
			push( @data, $1 );
			$whole_total_m = $1;
		}
		if ( $_ =~ /Pass\(M\):(.*)/ ) {
			push( @data, $1 );
			$whole_pass_m = $1;
		}
		if ( $_ =~ /Fail\(M\):(.*)/ ) {
			push( @data, $1 );
			$whole_fail_m = $1;
		}
		if ( $_ =~ /Total\(A\):(.*)/ ) {
			push( @data, $1 );
			$whole_total_a = $1;
		}
		if ( $_ =~ /Pass\(A\):(.*)/ ) {
			push( @data, $1 );
			$whole_pass_a = $1;
		}
		if ( $_ =~ /Fail\(A\):(.*)/ ) {
			push( @data, $1 );
			$whole_fail_a = $1;

			my $package_name = shift(@data);
			my $total_m      = shift(@data);
			my $pass_m       = shift(@data);
			my $fail_m       = shift(@data);
			my $total_a      = shift(@data);
			my $pass_a       = shift(@data);
			my $fail_a       = shift(@data);
			my $status       = "complete";

			my $temp1     = int($total_a) - int($pass_a) - int($fail_a);
			my $not_run_a = "$temp1";
			my $temp2     = int($total_m) - int($pass_m) - int($fail_m);
			my $not_run_m = "$temp2";
			if ( $not_run_m ne "0" ) {
				$status = "incomplete";
			}

			print <<DATA;
      <tr>
        <td align="left" width="25%" height="50" rowspan="2" class="report_list_outside_left">&nbsp;$package_name</td>
        <td align="left" width="12%" height="25" class="report_list_inside">&nbsp;auto</td>
DATA
			if ( $not_run_a eq "0" ) {
				print <<DATA;
        <td align="left" width="13%" height="25" class="report_list_inside">&nbsp;complete</td>
DATA
			}
			else {
				print <<DATA;
        <td align="left" width="13%" height="25" class="report_list_inside">&nbsp;incomplete</td>
DATA
			}
			print <<DATA;
        <td align="left" width="12%" height="25" class="report_list_outside_right">&nbsp;$total_a</td>
        <td align="left" width="12%" height="25" class="report_list_one_row" style="color: #137717">&nbsp;$pass_a</td>
        <td align="left" width="12%" height="25" class="report_list_one_row" style="color: #830300">&nbsp;$fail_a</td>
        <td align="left" width="14%" height="25" class="report_list_one_row" style="color: #A65604">&nbsp;$not_run_a</td>
      </tr>
      <tr>
        <td align="left" width="12%" height="25" class="report_list_inside">&nbsp;manual</td>
DATA
			if ( $not_run_m eq "0" ) {
				print <<DATA;
        <td align="left" width="13%" height="25" class="report_list_inside">&nbsp;complete</td>
DATA
			}
			else {
				print <<DATA;
        <td align="left" width="13%" height="25" class="report_list_inside">&nbsp;incomplete</td>
DATA
			}
			print <<DATA;
        <td align="left" width="12%" height="25" class="report_list_outside_right">&nbsp;$total_m</td>
        <td align="left" width="12%" height="25" class="report_list_one_row" style="color: #137717">&nbsp;$pass_m</td>
        <td align="left" width="12%" height="25" class="report_list_one_row" style="color: #830300">&nbsp;$fail_m</td>
        <td align="left" width="14%" height="25" class="report_list_one_row" style="color: #A65604">&nbsp;$not_run_m</td>
      </tr>
DATA
			@data = ();
		}
	}
	my $temp1 = int($whole_total_a) - int($whole_pass_a) - int($whole_fail_a);
	$whole_not_run_a = "$temp1";
	my $temp2 = int($whole_total_m) - int($whole_pass_m) - int($whole_fail_m);
	$whole_not_run_m = "$temp2";
	if ( $whole_not_run_m ne "0" ) {
		$whole_status = "incomplete";
	}
	print <<DATA;
      <tr>
        <td align="left" width="25%" height="50" rowspan="2" class="report_list_outside_left">&nbsp;Total</td>
        <td align="left" width="12%" height="25" class="report_list_inside">&nbsp;auto</td>
DATA
	if ( $whole_not_run_a eq "0" ) {
		print <<DATA;
        <td align="left" width="13%" height="25" class="report_list_inside">&nbsp;complete</td>
DATA
	}
	else {
		print <<DATA;
        <td align="left" width="13%" height="25" class="report_list_inside">&nbsp;incomplete</td>
DATA
	}
	print <<DATA;
        <td align="left" width="12%" height="25" class="report_list_outside_right">&nbsp;$whole_total_a</td>
        <td align="left" width="12%" height="25" class="report_list_one_row" style="color: #137717">&nbsp;$whole_pass_a</td>
        <td align="left" width="12%" height="25" class="report_list_one_row" style="color: #830300">&nbsp;$whole_fail_a</td>
        <td align="left" width="14%" height="25" class="report_list_one_row" style="color: #A65604">&nbsp;$whole_not_run_a</td>
      </tr>
      <tr>
        <td align="left" width="12%" height="25" class="report_list_inside">&nbsp;manual</td>
DATA
	if ( $whole_not_run_m eq "0" ) {
		print <<DATA;
        <td align="left" width="13%" height="25" class="report_list_inside">&nbsp;complete</td>
DATA
	}
	else {
		print <<DATA;
        <td align="left" width="13%" height="25" class="report_list_inside">&nbsp;incomplete</td>
DATA
	}
	print <<DATA;
        <td align="left" width="12%" height="25" class="report_list_outside_right">&nbsp;$whole_total_m</td>
        <td align="left" width="12%" height="25" class="report_list_one_row" style="color: #137717">&nbsp;$whole_pass_m</td>
        <td align="left" width="12%" height="25" class="report_list_one_row" style="color: #830300">&nbsp;$whole_fail_m</td>
        <td align="left" width="14%" height="25" class="report_list_one_row" style="color: #A65604">&nbsp;$whole_not_run_m</td>
      </tr>
    </table></td>
  </tr>
  <tr style="font-size:24px">
    <td align="left" height="50" style="background-color:#88D6F2">&nbsp;Test Log</td>
  </tr>
  <tr>
    <td align="left" height="50">
    <label>
    <input name="log_path" id="log_path" type="text" style="display:none" value="$result_dir" />
    </label>
    &nbsp;$result_dir
    &nbsp;&nbsp;<a href="get.pl$result_dir_tgz"><img title="Download consolidated log" src="images/operation_download.png" alt="operation_download_consolidated_log" width="38" height="38" /></a>
    &nbsp;&nbsp;<img title="Copy URL" src="images/operation_copy_url.png" alt="operation_copy_url" width="38" height="38" onclick="javascript:copyUrl();" style="cursor:pointer" /></td>
  </tr>
</table>
<script language="javascript" type="text/javascript">
// <![CDATA[
function copyUrl() {
	var s=document.getElementById('log_path').value;
	if (window.clipboardData) {
		window.clipboardData.setData("Text",s);
		alert("Copy complete!");
	} else {
		alert("Copy failed, your browser doesn't support window.clipboardData");
	}
}
// ]]>
</script>
DATA
}

sub showDetailedReport {
	my ($time) = @_;
	print <<DATA;
  <div id="message"></div>
  <table width="1280" border="0" cellspacing="0" cellpadding="0" class="report_list">
    <tr>
      <td><form id="detailed_report" name="detailed_report" method="post" action="tests_report.pl">
        <table width="100%" border="0" cellspacing="0" cellpadding="0">
          <tr>
            <td align="left" height="50" background="images/report_top_button_background.png"><table width="100%" height="50" border="0" cellpadding="0" cellspacing="0">
              <tr>
                <td width="2%">&nbsp;</td>
                <td style="font-size:24px">View by:
                  <select name="select_view" id="select_view" onchange="javascript:filter_view();">
                    <option selected="selected">Package</option>
                    <option>Component</option>
                    <option>Test type</option>
                  </select>
                  &nbsp;&nbsp;Result:
                  <select name="select_result" id="select_result" onchange="javascript:filter();">
                    <option selected="selected">FAIL</option>
                    <option>PASS</option>
                    <option>N/A</option>
                    <option>All</option>
                  </select>
                  &nbsp;&nbsp;Type:
                  <select name="select_type" id="select_type" onchange="javascript:filter();">
                    <option selected="selected">All</option>
                    <option>auto</option>
                    <option>manual</option>
                  </select>
                  </td>
              </tr>
            </table></td>
          </tr>
          <tr>
            <td><table width="100%" border="1" cellspacing="0" cellpadding="0" frame="void" rules="all">
              <tr>
                <td width="1%" class="report_list_one_row" style="background-color:#E9F6FC">&nbsp;</td>
                <td width="29%" valign="top" class="report_list_outside_left_bold" style="background-color:#E9F6FC">
                  <div id="tree_area_package"></div>
                  <div id="tree_area_component" style="display:none"></div>
                  <div id="tree_area_test_type" style="display:none"></div></td>
                <td width="70%" valign="top" class="report_list_outside_right_bold"><div id="view_area_package">
                  <div id="view_area_package_reg" style="display:none"></div>
                  <table width="100%" border="0" cellspacing="0" cellpadding="0">
                    <tr style="font-size:24px">
                      <td align="left" height="50" class="report_list_one_row">&nbsp;Test Result for&nbsp;&nbsp;$time&nbsp;&nbsp;<a href="tests_report.pl?time=$time&summary=1"><img title="View Summary Report" src="images/operation_view_summary_report.png" alt="operation_view_summary_report" width="38" height="38" /></td>
                    </tr>
                    <tr>
                      <td><table width="100%" border="0" cellspacing="0" cellpadding="0" style="table-layout:fixed">
                          <tr style="font-size:24px">
                            <td align="left" width="33%" height="50" class="report_list_outside_left">&nbsp;Name</td>
                            <td align="left" width="34%" height="50" class="report_list_one_row">&nbsp;Description</td>
                            <td width="33%" height="50" class="report_list_outside_right" align="center">Result</td>
                          </tr>
DATA

	# print auto case for package view
	@package_list = updatePackageList($time);
	foreach (@package_list) {
		my $package        = $_;
		my $id             = "none";
		my $name           = "none";
		my $description    = "none";
		my $result         = "none";
		my $execution_type = "auto";

		my $tests_xml_dir =
		  $result_dir_manager . $time . "/" . $package . "_tests.xml";
		open FILE, $tests_xml_dir or die $!;
		my $suite     = "none";
		my $set       = "none";
		my $startCase = "FALSE";
		my $isAuto    = "FALSE";
		my $xml       = "none";
		while (<FILE>) {

			if ( $startCase eq "TRUE" ) {
				chomp( $xml .= $_ );
			}
			if ( $_ =~ /suite.*name="(.*?)".*/ ) {
				$suite = $1;
			}
			if ( $_ =~ /set.*name="(.*?)".*/ ) {
				$set = $1;
			}
			if ( $_ =~ /execution_type="auto"/ ) {
				$isAuto = "TRUE";
				if ( $_ =~ /testcase.*id="(.*?)".*/ ) {
					$name      = $1;
					$startCase = "TRUE";
					chomp( $xml = $_ );
				}
			}
			if ( ( $_ =~ /.*<\/testcase>.*/ ) && ( $isAuto eq "TRUE" ) ) {
				$startCase   = "FALSE";
				%caseInfo    = updateCaseInfo($xml);
				$result      = $caseInfo{"result"};
				$description = $caseInfo{"description"};

				$id =
				    "P:" 
				  . $package . '_SU:' 
				  . $suite . '_SE:' 
				  . $set
				  . '_T:auto_R:'
				  . $result;

				#update result number for package tree view
				my @package_suite_set =
				  ( 'P_' . $package, 'SU_' . $suite, 'SE_' . $set );
				updateTreeResult( $result, @package_suite_set );

				if ( $result eq "FAIL" ) {
					print '<tr id="case_package_' . $id . '">';
					print "\n";
				}
				else {
					print '<tr id="case_package_' . $id
					  . '" style="display:none">';
					print "\n";
				}
				print <<DATA;
                            <td align="left" width="33%" height="50" class="report_list_outside_left" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$name"><a class="view_case_detail" onclick="javascript:show_case_detail('detailed_case_package_$name');">&nbsp;$name</a></td>
                            <td align="left" width="34%" height="50" class="report_list_one_row" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$description">&nbsp;$description</td>
                            <td width="33%" height="50" class="report_list_outside_right" align="center">$result</td>
                          </tr>
                          <tr id="detailed_case_package_$name" style="display:none">
                            <td height="50" colspan="3">
DATA
				printDetailedCaseInfo( $name, $execution_type, %caseInfo );
				print <<DATA;
                            </td>
                          </tr>
DATA
			}
		}

		# print manual case for package view
		%manual_case_result = updateManualCaseResult( $time, $package );
		$execution_type = "manual";
		my $isManual = "FALSE";
		my $def_tests_xml_dir =
		  $result_dir_manager . $time . "/" . $package . "_definition.xml";
		open FILE, $def_tests_xml_dir or die $!;
		while (<FILE>) {
			if ( $startCase eq "TRUE" ) {
				chomp( $xml .= $_ );
			}
			if ( $_ =~ /suite.*name="(.*?)".*/ ) {
				$suite = $1;
			}
			if ( $_ =~ /set.*name="(.*?)".*/ ) {
				$set = $1;
			}
			if ( $_ =~ /testcase.*id="(.*?)".*/ ) {
				$name = $1;
				if ( $_ =~ /testcase.*execution_type="manual".*/ ) {
					$startCase = "TRUE";
					$isManual  = "TRUE";
					chomp( $xml = $_ );
				}
			}
			if ( $_ =~ /testcase.*execution_type="auto".*/ ) {
				$isManual = "FALSE";
			}
			if ( ( $_ =~ /.*<\/testcase>.*/ ) && ( $isManual eq "TRUE" ) ) {
				$startCase = "FALSE";
				%caseInfo  = updateCaseInfo($xml);
				if ( defined $manual_case_result{$name} ) {
					$result      = $manual_case_result{$name};
					$description = $caseInfo{"description"};

					my $id_textarea =
					  "textarea__P:" . $package . '__N:' . $name;
					my $id_bugnumber =
					  "bugnumber__P:" . $package . '__N:' . $name;

					$id =
					    "P:" 
					  . $package . '_SU:' 
					  . $suite . '_SE:' 
					  . $set
					  . '_T:manual_R:'
					  . $result;

					#update result number for package tree view
					my @package_suite_set =
					  ( 'P_' . $package, 'SU_' . $suite, 'SE_' . $set );
					updateTreeResult( $result, @package_suite_set );

					if ( $result eq "FAIL" ) {
						print '<tr id="case_package_' . $id . '">';
						print "\n";
					}
					else {
						print '<tr id="case_package_' . $id
						  . '" style="display:none">';
						print "\n";
					}

					print <<DATA;
                            <td align="left" width="33%" height="50" class="report_list_outside_left" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$name"><a class="view_case_detail" onclick="javascript:show_case_detail('detailed_case_package_$name');">&nbsp;$name</a></td>
                            <td align="left" width="34%" height="50" class="report_list_one_row" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$description">&nbsp;$description</td>
                            <td width="33%" height="50" class="report_list_outside_right" align="center">$result</td>
                          </tr>
                          <tr id="detailed_case_package_$name" style="display:none">
                            <td height="50" colspan="3">
DATA
					printDetailedCaseInfoWithComment( $name, $execution_type,
						$time, $id_textarea, $id_bugnumber, %caseInfo );
					print <<DATA;
                            </td>
                          </tr>
DATA
				}
			}
		}
	}
	print <<DATA;
                      </table></td>
                    </tr>
                  </table>
                </div><div id="view_area_component" style="display:none">
                  <div id="view_area_component_reg" style="display:none"></div>
                  <table width="100%" border="0" cellspacing="0" cellpadding="0">
                    <tr style="font-size:24px">
                      <td align="left" height="50" class="report_list_one_row">&nbsp;Test Result for&nbsp;&nbsp;$time&nbsp;&nbsp;<a href="tests_report.pl?time=$time&summary=1"><img title="View Summary Report" src="images/operation_view_summary_report.png" alt="operation_view_summary_report" width="38" height="38" /></td>
                    </tr>
                    <tr>
                      <td><table width="100%" border="0" cellspacing="0" cellpadding="0" style="table-layout:fixed">
                          <tr style="font-size:24px">
                            <td align="left" width="33%" height="50" class="report_list_outside_left">&nbsp;Name</td>
                            <td align="left" width="34%" height="50" class="report_list_one_row">&nbsp;Description</td>
                            <td width="33%" height="50" class="report_list_outside_right" align="center">Result</td>
                          </tr>
DATA

	# print auto case for component view
	@package_list = updatePackageList($time);
	foreach (@package_list) {
		my $package        = $_;
		my $id             = "none";
		my $name           = "none";
		my $description    = "none";
		my $result         = "none";
		my $execution_type = "auto";

		my $tests_xml_dir =
		  $result_dir_manager . $time . "/" . $package . "_tests.xml";
		open FILE, $tests_xml_dir or die $!;
		my $component = "none";
		my $startCase = "FALSE";
		my $isAuto    = "FALSE";
		my $xml       = "none";
		while (<FILE>) {

			if ( $startCase eq "TRUE" ) {
				chomp( $xml .= $_ );
			}
			if ( $_ =~ /execution_type="auto"/ ) {
				$isAuto = "TRUE";
				if ( $_ =~ /testcase.*id="(.*?)".*/ ) {
					$name      = $1;
					$startCase = "TRUE";
					chomp( $xml = $_ );
				}
			}
			if ( ( $_ =~ /.*<\/testcase>.*/ ) && ( $isAuto eq "TRUE" ) ) {
				$startCase   = "FALSE";
				%caseInfo    = updateCaseInfo($xml);
				$result      = $caseInfo{"result"};
				$description = $caseInfo{"description"};
				$component   = $caseInfo{"component"};

				# calculate id by component
				my @component_item = split( "\/", $component );
				my @component_item_temp = ();
				for ( my $i = 0 ; $i < @component_item ; $i++ ) {
					push( @component_item_temp,
						"level-" . ( $i + 1 ) . ":" . $component_item[$i] );
				}

				$id =
				  join( "_", @component_item_temp ) . '_T:auto_R:' . $result;

				#update result number for component tree view
				updateTreeResult( $result, @component_item_temp );

				if ( $result eq "FAIL" ) {
					print '<tr id="case_component_' . $id . '">';
					print "\n";
				}
				else {
					print '<tr id="case_component_' . $id
					  . '" style="display:none">';
					print "\n";
				}
				print <<DATA;
                            <td align="left" width="33%" height="50" class="report_list_outside_left" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$name"><a class="view_case_detail" onclick="javascript:show_case_detail('detailed_case_component_$name');">&nbsp;$name</a></td>
                            <td align="left" width="34%" height="50" class="report_list_one_row" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$description">&nbsp;$description</td>
                            <td width="33%" height="50" class="report_list_outside_right" align="center">$result</td>
                          </tr>
                          <tr id="detailed_case_component_$name" style="display:none">
                            <td height="50" colspan="3">
DATA
				printDetailedCaseInfo( $name, $execution_type, %caseInfo );
				print <<DATA;
                            </td>
                          </tr>
DATA
			}
		}

		# print manual case for component view
		%manual_case_result = updateManualCaseResult( $time, $package );
		$execution_type = "manual";
		my $isManual = "FALSE";
		my $def_tests_xml_dir =
		  $result_dir_manager . $time . "/" . $package . "_definition.xml";
		open FILE, $def_tests_xml_dir or die $!;
		while (<FILE>) {
			if ( $startCase eq "TRUE" ) {
				chomp( $xml .= $_ );
			}
			if ( $_ =~ /testcase.*id="(.*?)".*/ ) {
				$name = $1;
				if ( $_ =~ /testcase.*execution_type="manual".*/ ) {
					$startCase = "TRUE";
					$isManual  = "TRUE";
					chomp( $xml = $_ );
				}
			}
			if ( $_ =~ /testcase.*execution_type="auto".*/ ) {
				$isManual = "FALSE";
			}
			if ( ( $_ =~ /.*<\/testcase>.*/ ) && ( $isManual eq "TRUE" ) ) {
				$startCase   = "FALSE";
				%caseInfo    = updateCaseInfo($xml);
				$description = $caseInfo{"description"};
				if ( defined $manual_case_result{$name} ) {
					$result    = $manual_case_result{$name};
					$component = $caseInfo{"component"};

					my @component_item = split( "\/", $component );
					my @component_item_temp = ();
					for ( my $i = 0 ; $i < @component_item ; $i++ ) {
						push( @component_item_temp,
							"level-" . ( $i + 1 ) . ":" . $component_item[$i] );
					}

					my $id_textarea =
					  "textarea__P:" . $package . '__N:' . $name;
					my $id_bugnumber =
					  "bugnumber__P:" . $package . '__N:' . $name;

					$id =
					    join( "_", @component_item_temp )
					  . '_T:manual_R:'
					  . $result;

					#update result number for component tree view
					updateTreeResult( $result, @component_item_temp );

					if ( $result eq "FAIL" ) {
						print '<tr id="case_component_' . $id . '">';
						print "\n";
					}
					else {
						print '<tr id="case_component_' . $id
						  . '" style="display:none">';
						print "\n";
					}
					print <<DATA;
                            <td align="left" width="33%" height="50" class="report_list_outside_left" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$name"><a class="view_case_detail" onclick="javascript:show_case_detail('detailed_case_component_$name');">&nbsp;$name</a></td>
                            <td align="left" width="34%" height="50" class="report_list_one_row" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$description">&nbsp;$description</td>
                            <td width="33%" height="50" class="report_list_outside_right" align="center">$result</td>
                          </tr>
                          <tr id="detailed_case_component_$name" style="display:none">
                            <td height="50" colspan="3">
DATA
					printDetailedCaseInfoWithComment( $name, $execution_type,
						$time, $id_textarea, $id_bugnumber, %caseInfo );
					print <<DATA;
                            </td>
                          </tr>
DATA
				}
			}
		}
	}
	print <<DATA;
                      </table></td>
                    </tr>
                  </table>
                </div><div id="view_area_test_type" style="display:none">
                  <div id="view_area_test_type_reg" style="display:none"></div>
                  <table width="100%" border="0" cellspacing="0" cellpadding="0">
                    <tr style="font-size:24px">
                      <td align="left" height="50" class="report_list_one_row">&nbsp;Test Result for&nbsp;&nbsp;$time&nbsp;&nbsp;<a href="tests_report.pl?time=$time&summary=1"><img title="View Summary Report" src="images/operation_view_summary_report.png" alt="operation_view_summary_report" width="38" height="38" /></td>
                    </tr>
                    <tr>
                      <td><table width="100%" border="0" cellspacing="0" cellpadding="0" style="table-layout:fixed">
                          <tr style="font-size:24px">
                            <td align="left" width="33%" height="50" class="report_list_outside_left">&nbsp;Name</td>
                            <td align="left" width="34%" height="50" class="report_list_one_row">&nbsp;Description</td>
                            <td width="33%" height="50" class="report_list_outside_right" align="center">Result</td>
                          </tr>
DATA

	# print auto case for test type view
	@package_list = updatePackageList($time);
	foreach (@package_list) {
		my $package        = $_;
		my $id             = "none";
		my $name           = "none";
		my $description    = "none";
		my $result         = "none";
		my $spec           = "none";
		my $test_type      = "none";
		my $execution_type = "auto";

		my $tests_xml_dir =
		  $result_dir_manager . $time . "/" . $package . "_tests.xml";
		open FILE, $tests_xml_dir or die $!;
		my $suite     = "none";
		my $set       = "none";
		my $startCase = "FALSE";
		my $isAuto    = "FALSE";
		my $xml       = "none";
		while (<FILE>) {

			if ( $startCase eq "TRUE" ) {
				chomp( $xml .= $_ );
			}
			if ( $_ =~ /suite.*name="(.*?)".*/ ) {
				$suite = $1;
			}
			if ( $_ =~ /set.*name="(.*?)".*/ ) {
				$set = $1;
			}
			if ( $_ =~ /execution_type="auto"/ ) {
				$isAuto = "TRUE";
				if ( $_ =~ /testcase.*id="(.*?)".*/ ) {
					$name      = $1;
					$startCase = "TRUE";
					chomp( $xml = $_ );
				}
			}
			if ( ( $_ =~ /.*<\/testcase>.*/ ) && ( $isAuto eq "TRUE" ) ) {
				$startCase   = "FALSE";
				%caseInfo    = updateCaseInfo($xml);
				$result      = $caseInfo{"result"};
				$description = $caseInfo{"description"};
				$spec        = $caseInfo{"spec"};
				$test_type   = $caseInfo{"test_type"};

				my @spec_hex = ();
				if ( $spec ne "none" ) {
					my @temp_spec = split( ":", $spec );

					# remove "::" error
					for ( my $i = 0 ; $i < @temp_spec ; $i++ ) {
						$temp_spec[$i] =~ s/^\s*//;
						$temp_spec[$i] =~ s/\s*$//;
						if ( $temp_spec[$i] eq "" ) {
							$temp_spec[$i] = "none";
							print
'<p style="font-size:18px">&nbsp;<span style="color:red">'
							  . $name
							  . '</span> got "::" in [SPEC]</p>';
						}
					}

					my @temp_spec_back = @temp_spec;
					for ( my $i = 0 ; $i < @temp_spec ; $i++ ) {
						push( @spec_hex,
							sha1_hex( join( ":", @temp_spec_back ) ) );
						pop(@temp_spec_back);
					}
				}
				elsif ( $test_type eq "compliance" ) {
					print
					  '<p style="font-size:18px">&nbsp;<span style="color:red">'
					  . $name
					  . '</span> got no [SPEC] in xml</p>';
				}

				$id =
				    "P:" 
				  . $package . '_SU:' 
				  . $suite . '_SE:' 
				  . $set . '_SP_'
				  . join( "_SP_", @spec_hex ) . '_TT:'
				  . $test_type
				  . '_T:auto_R:'
				  . $result;

				#update result number for test type tree view
				my @spec_hex_temp = @spec_hex;
				for ( my $i = 0 ; $i < @spec_hex ; $i++ ) {
					$spec_hex_temp[$i] = 'SP_' . $spec_hex_temp[$i];
				}
				push( @spec_hex_temp, 'TT_' . $test_type );
				push( @spec_hex_temp, 'TT_' . $test_type . 'P_' . $package );
				push( @spec_hex_temp, 'TT_' . $test_type . 'SU_' . $suite );
				push( @spec_hex_temp, 'TT_' . $test_type . 'SE_' . $set );
				updateTreeResult( $result, @spec_hex_temp );

				if ( $result eq "FAIL" ) {
					print '<tr id="case_test_type_' . $id . '">';
					print "\n";
				}
				else {
					print '<tr id="case_test_type_' . $id
					  . '" style="display:none">';
					print "\n";
				}
				print <<DATA;
                            <td align="left" width="33%" height="50" class="report_list_outside_left" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$name"><a class="view_case_detail" onclick="javascript:show_case_detail('detailed_case_test_type_$name');">&nbsp;$name</a></td>
                            <td align="left" width="34%" height="50" class="report_list_one_row" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$description">&nbsp;$description</td>
                            <td width="33%" height="50" class="report_list_outside_right" align="center">$result</td>
                          </tr>
                          <tr id="detailed_case_test_type_$name" style="display:none">
                            <td height="50" colspan="3">
DATA
				printDetailedCaseInfo( $name, $execution_type, %caseInfo );
				print <<DATA;
                            </td>
                          </tr>
DATA
			}
		}

		# print manual case for test type view
		%manual_case_result = updateManualCaseResult( $time, $package );
		$execution_type = "manual";
		my $isManual = "FALSE";
		my $def_tests_xml_dir =
		  $result_dir_manager . $time . "/" . $package . "_definition.xml";
		open FILE, $def_tests_xml_dir or die $!;
		while (<FILE>) {
			if ( $startCase eq "TRUE" ) {
				chomp( $xml .= $_ );
			}
			if ( $_ =~ /suite.*name="(.*?)".*/ ) {
				$suite = $1;
			}
			if ( $_ =~ /set.*name="(.*?)".*/ ) {
				$set = $1;
			}
			if ( $_ =~ /testcase.*id="(.*?)".*/ ) {
				$name = $1;
				if ( $_ =~ /testcase.*execution_type="manual".*/ ) {
					$startCase = "TRUE";
					$isManual  = "TRUE";
					chomp( $xml = $_ );
				}
			}
			if ( $_ =~ /testcase.*execution_type="auto".*/ ) {
				$isManual = "FALSE";
			}
			if ( ( $_ =~ /.*<\/testcase>.*/ ) && ( $isManual eq "TRUE" ) ) {
				$startCase = "FALSE";
				%caseInfo  = updateCaseInfo($xml);
				if ( defined $manual_case_result{$name} ) {
					$result      = $manual_case_result{$name};
					$description = $caseInfo{"description"};
					$spec        = $caseInfo{"spec"};
					$test_type   = $caseInfo{"test_type"};

					my @spec_hex = ();
					if ( $spec ne "none" ) {
						my @temp_spec = split( ":", $spec );

						# remove "::" error
						for ( my $i = 0 ; $i < @temp_spec ; $i++ ) {
							$temp_spec[$i] =~ s/^\s*//;
							$temp_spec[$i] =~ s/\s*$//;
							if ( $temp_spec[$i] eq "" ) {
								$temp_spec[$i] = "none";
								print
'<p style="font-size:18px">&nbsp;<span style="color:red">'
								  . $name
								  . '</span> got "::" in [SPEC]</p>';
							}
						}

						my @temp_spec_back = @temp_spec;
						for ( my $i = 0 ; $i < @temp_spec ; $i++ ) {
							push( @spec_hex,
								sha1_hex( join( ":", @temp_spec_back ) ) );
							pop(@temp_spec_back);
						}
					}
					elsif ( $test_type eq "compliance" ) {
						print
'<p style="font-size:18px">&nbsp;<span style="color:red">'
						  . $name
						  . '</span> got no [SPEC] in xml</p>';
					}

					my $id_textarea =
					  "textarea__P:" . $package . '__N:' . $name;
					my $id_bugnumber =
					  "bugnumber__P:" . $package . '__N:' . $name;

					$id =
					    "P:" 
					  . $package . '_SU:' 
					  . $suite . '_SE:' 
					  . $set . '_SP_'
					  . join( "_SP_", @spec_hex ) . '_TT:'
					  . $test_type
					  . '_T:manual_R:'
					  . $result;

					#update result number for test type tree view
					my @spec_hex_temp = @spec_hex;
					for ( my $i = 0 ; $i < @spec_hex ; $i++ ) {
						$spec_hex_temp[$i] = 'SP_' . $spec_hex_temp[$i];
					}
					push( @spec_hex_temp, 'TT_' . $test_type );
					push( @spec_hex_temp,
						'TT_' . $test_type . 'P_' . $package );
					push( @spec_hex_temp, 'TT_' . $test_type . 'SU_' . $suite );
					push( @spec_hex_temp, 'TT_' . $test_type . 'SE_' . $set );
					updateTreeResult( $result, @spec_hex_temp );

					if ( $result eq "FAIL" ) {
						print '<tr id="case_test_type_' . $id . '">';
						print "\n";
					}
					else {
						print '<tr id="case_test_type_' . $id
						  . '" style="display:none">';
						print "\n";
					}
					print <<DATA;
                            <td align="left" width="33%" height="50" class="report_list_outside_left" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$name"><a class="view_case_detail" onclick="javascript:show_case_detail('detailed_case_test_type_$name');">&nbsp;$name</a></td>
                            <td align="left" width="34%" height="50" class="report_list_one_row" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$description">&nbsp;$description</td>
                            <td width="33%" height="50" class="report_list_outside_right" align="center">$result</td>
                          </tr>
                          <tr id="detailed_case_test_type_$name" style="display:none">
                            <td height="50" colspan="3">
DATA
					printDetailedCaseInfoWithComment( $name, $execution_type,
						$time, $id_textarea, $id_bugnumber, %caseInfo );
					print <<DATA;
                            </td>
                          </tr>
DATA
				}
			}
		}
	}
	print <<DATA;
                      </table></td>
                    </tr>
                  </table>
                </div></td>
              </tr>
            </table></td>
          </tr>
        </table>
            </form>
      </td>
    </tr>
  </table>
<script language="javascript" type="text/javascript">
// <![CDATA[
// package tree
//global variable to allow console inspection of tree:
var tree;

// anonymous function wraps the remainder of the logic:
(function() {

	// function to initialize the tree:
	function treeInit() {
		buildTree();
	}

	// Function creates the tree
	function buildTree() {

		// instantiate the tree:
		tree = new YAHOO.widget.TreeView("tree_area_package");
DATA

	@package_list = updatePackageList($time);
	my $package_number = 1;
	foreach (@package_list) {
		my $package = $_;
		my $tests_xml_dir =
		  $result_dir_manager . $time . "/" . $package . "_definition.xml";
		print 'var package_'
		  . $package_number
		  . ' = new YAHOO.widget.TextNode("'
		  . $package
		  . getHTMLResult( 'P_' . $package )
		  . '", tree.getRoot(), false);';
		print "\n";
		print 'package_' . $package_number . '.title="P:' . $package . '";';
		print "\n";
		open FILE, $tests_xml_dir or die $!;
		my $suite_number = 0;
		my $set_number   = 1;

		while (<FILE>) {
			if ( $_ =~ /suite.*name="(.*?)"/ ) {
				$suite_number++;
				print 'var suite_'
				  . $suite_number
				  . ' = new YAHOO.widget.TextNode("'
				  . $1
				  . getHTMLResult( 'SU_' . $1 )
				  . '", package_'
				  . $package_number
				  . ', false);';
				print "\n";
				print 'suite_' . $suite_number . '.title="SU:' . $1 . '";';
				print "\n";
			}
			if ( $_ =~ /set.*name="(.*?)"/ ) {
				print 'var set_'
				  . $set_number
				  . ' = new YAHOO.widget.TextNode("'
				  . $1
				  . getHTMLResult( 'SE_' . $1 )
				  . '", suite_'
				  . $suite_number
				  . ', false);';
				print "\n";
				print 'set_' . $set_number . '.title="SE:' . $1 . '";';
				print "\n";
			}
		}
		$package_number++;
	}

	print <<DATA;
		tree.subscribe("labelClick",
			function(node) {
				// set result to 'Fail', type to 'All'
				var select_result = document.getElementById('select_result');
				var select_type = document.getElementById('select_type');
				select_result.selectedIndex = 0;
				select_type.selectedIndex = 0;
				// filter leaves
				var title = node.title;
				var reg = title;
				document.getElementById("view_area_package_reg").innerHTML = reg;
				var page = document.all;
				for ( var i = 0; i < page.length; i++) {
					var temp_id = page[i].id;
					if (temp_id.indexOf("case_package_") >= 0) {
						page[i].style.display = "none";
						if ((temp_id.indexOf(reg) >= 0)
								&& (temp_id.indexOf("R:FAIL") >= 0)) {
							page[i].style.display = "";
						}
					}
				}
				for ( var i = 0; i < page.length; i++) {
					var temp_id = page[i].id;
					if (temp_id.indexOf("detailed_case_package_") >= 0) {
						page[i].style.display = "none";
					}
				}
			});
		// The tree is not created in the DOM until this method is called:
		tree.draw();
	}

	// Add a window onload handler to build the tree when the load
	// event fires.
	YAHOO.util.Event.addListener(window, "load", treeInit);

})();
// ]]>
</script>

<script language="javascript" type="text/javascript">
// <![CDATA[
// component tree
//global variable to allow console inspection of tree:
var tree;

// anonymous function wraps the remainder of the logic:
(function() {

	// function to initialize the tree:
	function treeInit() {
		buildTree();
	}

	// Function creates the tree
	function buildTree() {

		// instantiate the tree:
		tree = new YAHOO.widget.TreeView("tree_area_component");
DATA

	updateComponentList($time);
	my $component_depth = keys %component_list;
	for ( my $i = 1 ; $i <= $component_depth ; $i++ ) {

		# get component list of a specific level
		my @temp = split( "__", $component_list{$i} );
		foreach (@temp) {

			# get component and its parent
			my @temp      = split( "::", $_ );
			my $parent    = pop(@temp);
			my $component = pop(@temp);
			if ( $parent eq "root" ) {
				print 'var level_' 
				  . $i . '_'
				  . $component
				  . ' = new YAHOO.widget.TextNode("'
				  . $component
				  . getHTMLResult( 'level-' . $i . ':' . $component )
				  . '", tree.getRoot(), false);';
			}
			else {
				print 'var level_' 
				  . $i . '_'
				  . $component
				  . ' = new YAHOO.widget.TextNode("'
				  . $component
				  . getHTMLResult( 'level-' . $i . ':' . $component )
				  . '", level_'
				  . ( $i - 1 ) . '_'
				  . $parent
				  . ', false);';
			}
			print "\n";
			print 'level_' 
			  . $i . '_'
			  . $component
			  . '.title="level-'
			  . $i . ':'
			  . $component . '";';
			print "\n";
		}
	}

	print <<DATA;
		tree.subscribe("labelClick",
			function(node) {
				// set result to 'Fail', type to 'All'
				var select_result = document.getElementById('select_result');
				var select_type = document.getElementById('select_type');
				select_result.selectedIndex = 0;
				select_type.selectedIndex = 0;
				// filter leaves
				var title = node.title;
				var reg = title;
				
				document.getElementById("view_area_component_reg").innerHTML = reg;
				var page = document.all;
				for ( var i = 0; i < page.length; i++) {
					var temp_id = page[i].id;
					if (temp_id.indexOf("case_component_") >= 0) {
						page[i].style.display = "none";
						if ((temp_id.indexOf(reg) >= 0)
								&& (temp_id.indexOf("R:FAIL") >= 0)) {
							page[i].style.display = "";
						}
					}
				}
				for ( var i = 0; i < page.length; i++) {
					var temp_id = page[i].id;
					if (temp_id.indexOf("detailed_case_component_") >= 0) {
						page[i].style.display = "none";
					}
				}
			});
		// The tree is not created in the DOM until this method is called:
		tree.draw();
	}

	// Add a window onload handler to build the tree when the load
	// event fires.
	YAHOO.util.Event.addListener(window, "load", treeInit);

})();
// ]]>
</script>

<script language="javascript" type="text/javascript">
// <![CDATA[
// test type tree
//global variable to allow console inspection of tree:
var tree;

// anonymous function wraps the remainder of the logic:
(function() {

	// function to initialize the tree:
	function treeInit() {
		buildTree();
	}

	// Function creates the tree
	function buildTree() {

		// instantiate the tree:
		tree = new YAHOO.widget.TreeView("tree_area_test_type");
DATA

	my $haveCompliance = "FALSE";
	updateTestTypeList($time);
	foreach (@test_type) {
		my $test_type = $_;
		if ( $test_type ne "compliance" ) {
			print 'var test_type_'
			  . $test_type
			  . ' = new YAHOO.widget.TextNode("'
			  . $test_type
			  . getHTMLResult( 'TT_' . $test_type )
			  . '", tree.getRoot(), false);';
			print "\n";
			print 'test_type_' . $test_type . '.title="TT:' . $test_type . '"';
			print "\n";
			@package_list = updatePackageList($time);
			my $package_number = 1;
			foreach (@package_list) {
				my $package = $_;
				my $tests_xml_dir =
				    $result_dir_manager 
				  . $time . "/" 
				  . $package
				  . "_definition.xml";
				print 'var package_'
				  . $package_number
				  . ' = new YAHOO.widget.TextNode("'
				  . $package
				  . getHTMLResult( 'TT_' . $test_type . "P_" . $package )
				  . '", test_type_'
				  . $test_type
				  . ', false);';
				print "\n";
				print 'package_'
				  . $package_number
				  . '.title="TT:'
				  . $test_type . '__P:'
				  . $package . '";';
				print "\n";
				open FILE, $tests_xml_dir or die $!;
				my $suite_number = 0;
				my $set_number   = 1;

				while (<FILE>) {
					if ( $_ =~ /suite.*name="(.*?)"/ ) {
						$suite_number++;
						print 'var suite_'
						  . $suite_number
						  . ' = new YAHOO.widget.TextNode("'
						  . $1
						  . getHTMLResult( 'TT_' . $test_type . "SU_" . $1 )
						  . '", package_'
						  . $package_number
						  . ', false);';
						print "\n";
						print 'suite_'
						  . $suite_number
						  . '.title="TT:'
						  . $test_type . '__SU:'
						  . $1 . '";';
						print "\n";
					}
					if ( $_ =~ /set.*name="(.*?)"/ ) {
						print 'var set_'
						  . $set_number
						  . ' = new YAHOO.widget.TextNode("'
						  . $1
						  . getHTMLResult( 'TT_' . $test_type . "SE_" . $1 )
						  . '", suite_'
						  . $suite_number
						  . ', false);';
						print "\n";
						print 'set_'
						  . $set_number
						  . '.title="TT:'
						  . $test_type . '__SE:'
						  . $1 . '";';
						print "\n";
					}
				}
				$package_number++;
			}
		}
		else {
			$haveCompliance = "TRUE";
		}
	}
	if ( ( $haveCompliance eq "TRUE" ) && ( $hasTestTypeError eq "FALSE" ) ) {

		# create compliance node
		print 'var test_type_compliance = new YAHOO.widget.TextNode("compliance'
		  . getHTMLResult('TT_compliance')
		  . '", tree.getRoot(), false);';
		print "\n";
		print 'test_type_compliance.title="TT:compliance";';
		print "\n";
		updateSpecList($time);
		my $spec_depth = keys %spec_list;
		for ( my $i = 1 ; $i <= $spec_depth ; $i++ ) {

			# get spec list of a specific level
			my @temp = split( "__", $spec_list{$i} );
			foreach (@temp) {

				# get item and its parent
				my @temp_inside = split( "::", $_ );
				my $item        = shift(@temp_inside);
				my $parent      = shift(@temp_inside);

				if ( $i == 1 ) {
					print 'var SP_'
					  . sha1_hex($parent)
					  . ' = new YAHOO.widget.TextNode("'
					  . $item
					  . getHTMLResult( 'SP_' . sha1_hex($parent) )
					  . '", test_type_compliance, false);';
					print "\n";
					print 'SP_'
					  . sha1_hex($parent)
					  . '.title="SP_'
					  . sha1_hex($parent) . '";';
					print "\n";
				}
				else {
					print 'var SP_'
					  . sha1_hex( $parent . ':' . $item )
					  . ' = new YAHOO.widget.TextNode("'
					  . $item
					  . getHTMLResult(
						'SP_' . sha1_hex( $parent . ':' . $item ) )
					  . '", SP_'
					  . sha1_hex($parent)
					  . ', false);';
					print "\n";
					print 'SP_'
					  . sha1_hex( $parent . ':' . $item )
					  . '.title="SP_'
					  . sha1_hex( $parent . ':' . $item ) . '";';
					print "\n";
				}
			}
		}
	}

	print <<DATA;
		tree.subscribe("labelClick",
			function(node) {
				// set result to 'Fail', type to 'All'
				var select_result = document.getElementById('select_result');
				var select_type = document.getElementById('select_type');
				select_result.selectedIndex = 0;
				select_type.selectedIndex = 0;
				// filter leaves
				var title = node.title;
				var reg = "";
				var reg_test_type = "";
				var have_test_type = "";
				if ((title.indexOf("P:") >= 0) || (title.indexOf("SU:") >= 0)
						|| (title.indexOf("SE:") >= 0)) {
					have_test_type = "TRUE";
					var reg_both = node.title.split("__");
					reg_test_type = reg_both[0];
					reg = reg_both[1];
				} else {
					have_test_type = "FALSE";
					reg = title;
				}
				document.getElementById("view_area_test_type_reg").innerHTML = title;
				var page = document.all;
				for ( var i = 0; i < page.length; i++) {
					var temp_id = page[i].id;
					if (temp_id.indexOf("case_test_type_") >= 0) {
						page[i].style.display = "none";
						if (have_test_type == "TRUE") {
							if ((temp_id.indexOf(reg) >= 0)
									&& (temp_id.indexOf(reg_test_type) >= 0)
									&& (temp_id.indexOf("R:FAIL") >= 0)) {
								page[i].style.display = "";
							}
						} else {
							if ((temp_id.indexOf(reg) >= 0)
									&& (temp_id.indexOf("R:FAIL") >= 0)) {
								page[i].style.display = "";
							}
						}
					}
				}
				for ( var i = 0; i < page.length; i++) {
					var temp_id = page[i].id;
					if (temp_id.indexOf("detailed_case_test_type_") >= 0) {
						page[i].style.display = "none";
					}
				}
			});
		// The tree is not created in the DOM until this method is called:
		tree.draw();
	}

	// Add a window onload handler to build the tree when the load
	// event fires.
	YAHOO.util.Event.addListener(window, "load", treeInit);

})();
// ]]>
</script>
<script language="javascript" type="text/javascript">
// <![CDATA[
function filter() {
	var view = document.getElementById('select_view').value;
	var result = document.getElementById('select_result').value;
	var type = document.getElementById('select_type').value;
	var reg_result = "R:" + result;
	var reg_type = "T:" + type;

	if (view == "Package") {
		// get which tree element was clicked
		var reg_view = document.getElementById('view_area_package_reg').innerHTML;
		var page = document.all;
		for ( var i = 0; i < page.length; i++) {
			var temp_id = page[i].id;
			if (temp_id.indexOf("case_package_") >= 0) {
				page[i].style.display = "none";
				// if one tree element was clicked
				if (reg_view == "") {
					if ((reg_result == "R:All") && (reg_type == "T:All")) {
						if (temp_id.indexOf('detailed_case_') < 0) {
							page[i].style.display = "";
						}
					}
					if ((reg_result == "R:All") && (reg_type != "T:All")) {
						if (temp_id.indexOf(reg_type) >= 0) {
							page[i].style.display = "";
						}
					}
					if ((reg_result != "R:All") && (reg_type == "T:All")) {
						if (temp_id.indexOf(reg_result) >= 0) {
							page[i].style.display = "";
						}
					}
					if ((reg_result != "R:All") && (reg_type != "T:All")) {
						if ((temp_id.indexOf(reg_result) >= 0)
								&& (temp_id.indexOf(reg_type) >= 0)) {
							page[i].style.display = "";
						}
					}
				} else {
					if ((reg_result == "R:All") && (reg_type == "T:All")) {
						if (temp_id.indexOf(reg_view) >= 0) {
							page[i].style.display = "";
						}
					}
					if ((reg_result == "R:All") && (reg_type != "T:All")) {
						if ((temp_id.indexOf(reg_view) >= 0)
								&& (temp_id.indexOf(reg_type) >= 0)) {
							page[i].style.display = "";
						}
					}
					if ((reg_result != "R:All") && (reg_type == "T:All")) {
						if ((temp_id.indexOf(reg_view) >= 0)
								&& (temp_id.indexOf(reg_result) >= 0)) {
							page[i].style.display = "";
						}
					}
					if ((reg_result != "R:All") && (reg_type != "T:All")) {
						if ((temp_id.indexOf(reg_view) >= 0)
								&& (temp_id.indexOf(reg_result) >= 0)
								&& (temp_id.indexOf(reg_type) >= 0)) {
							page[i].style.display = "";
						}
					}
				}
			}
		}
	}
	if (view == "Component") {
		// get which tree element was clicked
		var reg_view = document.getElementById('view_area_component_reg').innerHTML;
		var page = document.all;
		for ( var i = 0; i < page.length; i++) {
			var temp_id = page[i].id;
			if (temp_id.indexOf("case_component_") >= 0) {
				page[i].style.display = "none";
				// if on tree element was clicked
				if (reg_view == "") {
					if ((reg_result == "R:All") && (reg_type == "T:All")) {
						if (temp_id.indexOf('detailed_case_') < 0) {
							page[i].style.display = "";
						}
					}
					if ((reg_result == "R:All") && (reg_type != "T:All")) {
						if (temp_id.indexOf(reg_type) >= 0) {
							page[i].style.display = "";
						}
					}
					if ((reg_result != "R:All") && (reg_type == "T:All")) {
						if (temp_id.indexOf(reg_result) >= 0) {
							page[i].style.display = "";
						}
					}
					if ((reg_result != "R:All") && (reg_type != "T:All")) {
						if ((temp_id.indexOf(reg_result) >= 0)
								&& (temp_id.indexOf(reg_type) >= 0)) {
							page[i].style.display = "";
						}
					}
				} else {
					if ((reg_result == "R:All") && (reg_type == "T:All")) {
						if (temp_id.indexOf(reg_view) >= 0) {
							page[i].style.display = "";
						}
					}
					if ((reg_result == "R:All") && (reg_type != "T:All")) {
						if ((temp_id.indexOf(reg_view) >= 0)
								&& (temp_id.indexOf(reg_type) >= 0)) {
							page[i].style.display = "";
						}
					}
					if ((reg_result != "R:All") && (reg_type == "T:All")) {
						if ((temp_id.indexOf(reg_view) >= 0)
								&& (temp_id.indexOf(reg_result) >= 0)) {
							page[i].style.display = "";
						}
					}
					if ((reg_result != "R:All") && (reg_type != "T:All")) {
						if ((temp_id.indexOf(reg_view) >= 0)
								&& (temp_id.indexOf(reg_result) >= 0)
								&& (temp_id.indexOf(reg_type) >= 0)) {
							page[i].style.display = "";
						}
					}
				}
			}
		}
	}
	if (view == "Test type") {
		// get which tree element was clicked
		var reg_view = document.getElementById('view_area_test_type_reg').innerHTML;
		var page = document.all;
		for ( var i = 0; i < page.length; i++) {
			var temp_id = page[i].id;
			if (temp_id.indexOf("case_test_type_") >= 0) {
				page[i].style.display = "none";
				// if on tree element was clicked
				if (reg_view == "") {
					if ((reg_result == "R:All") && (reg_type == "T:All")) {
						if (temp_id.indexOf('detailed_case_') < 0) {
							page[i].style.display = "";
						}
					}
					if ((reg_result == "R:All") && (reg_type != "T:All")) {
						if (temp_id.indexOf(reg_type) >= 0) {
							page[i].style.display = "";
						}
					}
					if ((reg_result != "R:All") && (reg_type == "T:All")) {
						if (temp_id.indexOf(reg_result) >= 0) {
							page[i].style.display = "";
						}
					}
					if ((reg_result != "R:All") && (reg_type != "T:All")) {
						if ((temp_id.indexOf(reg_result) >= 0)
								&& (temp_id.indexOf(reg_type) >= 0)) {
							page[i].style.display = "";
						}
					}
				} else {
					if ((reg_result == "R:All") && (reg_type == "T:All")) {
						if ((reg_view.indexOf("P:") >= 0) || (reg_view.indexOf("SU:") >= 0)
								|| (reg_view.indexOf("SE:") >= 0)) {
							var reg_both = reg_view.split("__");
							reg_test_type = reg_both[0];
							reg = reg_both[1];
					
							if ((temp_id.indexOf(reg_test_type) >= 0)
									&& (temp_id.indexOf(reg) >= 0)) {
								page[i].style.display = "";
							}
						} else {
							if (temp_id.indexOf(reg_view) >= 0) {
								page[i].style.display = "";
							}
						}
					}
					if ((reg_result == "R:All") && (reg_type != "T:All")) {
						if ((reg_view.indexOf("P:") >= 0) || (reg_view.indexOf("SU:") >= 0)
								|| (reg_view.indexOf("SE:") >= 0)) {
							var reg_both = reg_view.split("__");
							reg_test_type = reg_both[0];
							reg = reg_both[1];
					
							if ((temp_id.indexOf(reg_test_type) >= 0)
									&& (temp_id.indexOf(reg) >= 0)
									&& (temp_id.indexOf(reg_type) >= 0)) {
								page[i].style.display = "";
							}
						} else {
							if ((temp_id.indexOf(reg_view) >= 0)
									&& (temp_id.indexOf(reg_type) >= 0)) {
								page[i].style.display = "";
							}
						}
					}
					if ((reg_result != "R:All") && (reg_type == "T:All")) {
						if ((reg_view.indexOf("P:") >= 0) || (reg_view.indexOf("SU:") >= 0)
								|| (reg_view.indexOf("SE:") >= 0)) {
							var reg_both = reg_view.split("__");
							reg_test_type = reg_both[0];
							reg = reg_both[1];
					
							if ((temp_id.indexOf(reg_test_type) >= 0)
									&& (temp_id.indexOf(reg) >= 0)
									&& (temp_id.indexOf(reg_result) >= 0)) {
								page[i].style.display = "";
							}
						} else {
							if ((temp_id.indexOf(reg_view) >= 0)
									&& (temp_id.indexOf(reg_result) >= 0)) {
								page[i].style.display = "";
							}
						}
					}
					if ((reg_result != "R:All") && (reg_type != "T:All")) {
						if ((reg_view.indexOf("P:") >= 0) || (reg_view.indexOf("SU:") >= 0)
								|| (reg_view.indexOf("SE:") >= 0)) {
							var reg_both = reg_view.split("__");
							reg_test_type = reg_both[0];
							reg = reg_both[1];
					
							if ((temp_id.indexOf(reg_test_type) >= 0)
									&& (temp_id.indexOf(reg) >= 0)
									&& (temp_id.indexOf(reg_result) >= 0)
									&& (temp_id.indexOf(reg_type) >= 0)) {
								page[i].style.display = "";
							}
						} else {
							if ((temp_id.indexOf(reg_view) >= 0)
									&& (temp_id.indexOf(reg_result) >= 0)
									&& (temp_id.indexOf(reg_type) >= 0)) {
								page[i].style.display = "";
							}
						}
					}
				}
			}
		}
	}
}

// change div by view type
function filter_view() {
	var view = document.getElementById('select_view').value;

	if (view == "Package") {
		document.getElementById('tree_area_package').style.display = "";
		document.getElementById('tree_area_component').style.display = "none";
		document.getElementById('tree_area_test_type').style.display = "none";
		document.getElementById('view_area_package').style.display = "";
		document.getElementById('view_area_component').style.display = "none";
		document.getElementById('view_area_test_type').style.display = "none";
	}
	if (view == "Component") {
		document.getElementById('tree_area_package').style.display = "none";
		document.getElementById('tree_area_component').style.display = "";
		document.getElementById('tree_area_test_type').style.display = "none";
		document.getElementById('view_area_package').style.display = "none";
		document.getElementById('view_area_component').style.display = "";
		document.getElementById('view_area_test_type').style.display = "none";
	}
	if (view == "Test type") {
		document.getElementById('tree_area_package').style.display = "none";
		document.getElementById('tree_area_component').style.display = "none";
		document.getElementById('tree_area_test_type').style.display = "";
		document.getElementById('view_area_package').style.display = "none";
		document.getElementById('view_area_component').style.display = "none";
		document.getElementById('view_area_test_type').style.display = "";
	}

	var select_result = document.getElementById('select_result');
	var select_type = document.getElementById('select_type');
	select_result.selectedIndex = 0;
	select_type.selectedIndex = 0;
	update_case_display(view);
}

// set all failed cases to display
function update_case_display(view) {
	var page = document.all;
	for ( var i = 0; i < page.length; i++) {
		var temp_id = page[i].id;
		if (temp_id.indexOf("case_") >= 0) {
			page[i].style.display = "none";
			if (view == "Package") {
				// check if it was clicked before
				var reg_view = document.getElementById('view_area_package_reg').innerHTML;
				// just consider result 'Fail'
				if (reg_view == "") {
					if (temp_id.indexOf("R:FAIL") >= 0) {
						page[i].style.display = "";
					}
				} else {
					if ((temp_id.indexOf("R:FAIL") >= 0)
							&& (temp_id.indexOf(reg_view) >= 0)) {
						page[i].style.display = "";
					}
				}
			}
			if (view == "Component") {
				var reg_view = document
						.getElementById('view_area_component_reg').innerHTML;
				if (reg_view == "") {
					if (temp_id.indexOf("R:FAIL") >= 0) {
						page[i].style.display = "";
					}
				} else {
					if ((temp_id.indexOf("R:FAIL") >= 0)
							&& (temp_id.indexOf(reg_view) >= 0)) {
						page[i].style.display = "";
					}
				}
			}
			if (view == "Test type") {
				var reg_view = document
						.getElementById('view_area_test_type_reg').innerHTML;
				if (reg_view == "") {
					if (temp_id.indexOf("R:FAIL") >= 0) {
						page[i].style.display = "";
					}
				} else {
					if ((reg_view.indexOf("P:") >= 0) || (reg_view.indexOf("SU:") >= 0)
							|| (reg_view.indexOf("SE:") >= 0)) {
						var reg_both = reg_view.split("__");
						reg_test_type = reg_both[0];
						reg = reg_both[1];
				
						if ((temp_id.indexOf(reg_test_type) >= 0)
								&& (temp_id.indexOf(reg) >= 0)
								&& (temp_id.indexOf("R:FAIL") >= 0)) {
							page[i].style.display = "";
						}
					} else {
						if ((temp_id.indexOf(reg_view) >= 0)
								&& (temp_id.indexOf("R:FAIL") >= 0)) {
							page[i].style.display = "";
						}
					}
				}
			}
		}
	}
}

function show_case_detail(id) {
	var display = document.getElementById(id).style.display;
	if (display == "none") {
		document.getElementById(id).style.display = "";
	} else {
		document.getElementById(id).style.display = "none";
	}
}
// ]]>
</script>
DATA
}

sub updateTestTypeList {
	@test_type = ();
	my ($time) = @_;
	find( \&updateTestTypeList_wanted, $result_dir_manager . $time );
}

sub updateTestTypeList_wanted {
	my $dir = $File::Find::name;
	if ( $dir =~ /.*\/(.*_tests.xml)$/ ) {
		open FILE, $dir or die $!;
		while (<FILE>) {
			if ( $_ =~ /testcase.* type="(.*?)".*/ ) {
				my $hasOne = "FALSE";
				foreach (@test_type) {
					if ( $_ eq $1 ) { $hasOne = "TRUE"; }
				}
				if ( $hasOne eq "FALSE" ) {
					push( @test_type, $1 );
				}
			}
		}
	}
}

sub updateComponentList {
	undef %component_list;
	my ($time) = @_;
	find( \&updateComponentList_wanted, $result_dir_manager . $time );
}

sub updateComponentList_wanted {
	my $dir = $File::Find::name;
	if ( $dir =~ /.*\/(.*_tests.xml)$/ ) {
		open FILE, $dir or die $!;
		while (<FILE>) {
			if ( $_ =~ /testcase.*component="(.*?)".*/ ) {
				my @component_item = split( "\/", $1 );
				for ( my $i = 0 ; $i < @component_item ; $i++ ) {

					# already got some components at this level
					if ( defined( $component_list{ $i + 1 } ) ) {
						my $component_temp = $component_list{ $i + 1 };
						if ( $i == 0 ) {
							my $hasOne = "FALSE";
							my @temp_component_list =
							  split( "__", $component_temp );
							foreach (@temp_component_list) {
								if ( $component_item[$i] . "::root" eq $_ ) {
									$hasOne = "TURE";
								}
							}
							if ( $hasOne eq "FALSE" ) {
								$component_list{ $i + 1 } =
								    $component_temp . "__"
								  . $component_item[$i]
								  . "::root";
							}
						}
						else {
							my $hasOne = "FALSE";
							my @temp_component_list =
							  split( "__", $component_temp );
							foreach (@temp_component_list) {
								if (  $component_item[$i] . "::"
									. $component_item[ $i - 1 ] eq $_ )
								{
									$hasOne = "TURE";
								}
							}
							if ( $hasOne eq "FALSE" ) {
								$component_list{ $i + 1 } =
								    $component_temp . "__"
								  . $component_item[$i] . "::"
								  . $component_item[ $i - 1 ];
							}
						}

						# this is the first component at this level
					}
					else {
						if ( $i == 0 ) {
							$component_list{ $i + 1 } =
							  $component_item[$i] . "::root";
						}
						else {
							$component_list{ $i + 1 } =
							    $component_item[$i] . "::"
							  . $component_item[ $i - 1 ];
						}
					}
				}
			}
		}
	}
}

sub updateSpecList {
	undef %spec_list;
	my ($time) = @_;
	find( \&updateSpecList_wanted, $result_dir_manager . $time );
}

sub updateSpecList_wanted {
	my $dir = $File::Find::name;
	if ( $dir =~ /.*\/(.*_tests.xml)$/ ) {
		open FILE, $dir or die $!;
		while (<FILE>) {
			if ( $_ =~ /<spec>\[Spec\] *(.*) */ ) {
				my $spec_name = $1;
				$spec_name =~ s/\[Spec URL\].*//;
				$spec_name =~ s/^[\s]+//;
				$spec_name =~ s/[\s]+$//;
				$spec_name =~ s/[\s]+/ /g;
				$spec_name =~ s/&lt;/[/g;
				$spec_name =~ s/&gt;/]/g;
				$spec_name =~ s/</[/g;
				$spec_name =~ s/>/]/g;
				my @spec_item = split( ":", $spec_name );

				# remove additional space
				for ( my $i = 0 ; $i < @spec_item ; $i++ ) {
					$spec_item[$i] =~ s/^\s*//;
					$spec_item[$i] =~ s/\s*$//;
					if ( $spec_item[$i] eq "" ) {
						$spec_item[$i] = "none";
					}
				}

				for ( my $i = 0 ; $i < @spec_item ; $i++ ) {

					# already got some specs at this level
					if ( defined( $spec_list{ $i + 1 } ) ) {
						my $spec_temp = $spec_list{ $i + 1 };
						if ( $i == 0 ) {
							my $hasOne = "FALSE";
							my @temp_spec_list =
							  split( "__", $spec_temp );
							foreach (@temp_spec_list) {
								if (  $spec_item[$i] . "::"
									. $spec_item[$i] eq $_ )
								{
									$hasOne = "TURE";
								}
							}
							if ( $hasOne eq "FALSE" ) {
								$spec_list{ $i + 1 } =
								    $spec_temp . "__"
								  . $spec_item[$i] . "::"
								  . $spec_item[$i];
							}
						}
						else {
							my $hasOne = "FALSE";
							my @temp_spec_list =
							  split( "__", $spec_temp );
							my $parent =
							  join( ":", @spec_item[ 0 .. ( $i - 1 ) ] );
							foreach (@temp_spec_list) {
								if ( $spec_item[$i] . "::" . $parent eq $_ ) {
									$hasOne = "TURE";
								}
							}
							if ( $hasOne eq "FALSE" ) {
								$spec_list{ $i + 1 } =
								    $spec_temp . "__"
								  . $spec_item[$i] . "::"
								  . $parent;
							}
						}
					}
					else {
						if ( $i == 0 ) {
							$spec_list{ $i + 1 } =
							  $spec_item[$i] . "::" . $spec_item[$i];
						}
						else {
							my $parent =
							  join( ":", @spec_item[ 0 .. ( $i - 1 ) ] );
							$spec_list{ $i + 1 } =
							  $spec_item[$i] . "::" . $parent;
						}
					}
				}
			}
		}
	}
}

sub updateSelectDir {
	my %post_temp = @_;
	find( \&updateSelectDir_wanted, $result_dir_manager );
	my @select_dir_back = ();
	foreach (@select_dir) {
		if ( defined( $post_temp{$_} ) ) {
			push( @select_dir_back, $_ );
		}
	}
	@select_dir = @select_dir_back;
}

sub updateSelectDir_wanted {
	my %post_temp = @_;
	my $dir       = $File::Find::name;
	if ( $dir =~ /.*\/([0-9:\.\-]+)$/ ) {
		push( @select_dir, $1 );
	}
}

sub updateResultList {
	my ($time) = @_;
	find( \&updateResultList_wanted, $result_dir_manager . $time );
}

sub updateResultList_wanted {
	my $dir = $File::Find::name;
	if ( $dir =~ /.*\/([\w\d\-]+tests_tests.xml)$/ ) {
		push( @result_list_xml, $dir );
	}
	if ( $dir =~ /.*\/([\w\d\-]+tests_tests.txt)$/ ) {
		push( @result_list_txt, $dir );
	}
}

sub getReportDisplayData {
	find( \&getReportDisplayData_wanted, $result_dir_manager );
}

sub getReportDisplayData_wanted {
	my $time      = "none";
	my $user_name = "none";
	my $platform  = "none";
	my $total     = 0;
	my $pass      = 0;
	my $fail      = 0;
	my $not_run   = 0;
	my $dir       = $File::Find::name;
	if ( $dir =~ /.*\/([0-9:\.\-]+)$/ ) {
		open FILE, $dir . "/runconfig" or die $!;
		while (<FILE>) {
			if ( $_ =~ /Hardware Platform:(.*)/ ) {
				$platform = $1;
			}
			if ( $_ =~ /Username:(.*)/ ) {
				$user_name = $1;
			}
		}
		open FILE, $dir . "/info" or die $!;
		while (<FILE>) {
			if ( $_ =~ /Time:(.*)/ ) {
				$time = $1;
			}
			if ( $_ =~ /Total:(.*)/ ) {
				$total += int($1);
			}
			if ( $_ =~ /Pass:(.*)/ ) {
				$pass += int($1);
			}
			if ( $_ =~ /Fail:(.*)/ ) {
				$fail += int($1);
			}
		}
		push( @report_display, $time );
		push( @report_display, $user_name );
		push( @report_display, $platform );
		push( @report_display, $total );
		push( @report_display, $pass );
		push( @report_display, $fail );
		push( @report_display, ( int($total) - int($pass) - int($fail) ) );
	}
}

sub updateTreeResult {
	my ( $result, @component_item ) = @_;
	foreach (@component_item) {
		if ( defined $result_list_tree{$_} ) {
			my @result = split( ":", $result_list_tree{$_} );
			$result[0] = int( $result[0] ) + 1;
			if ( $result =~ /PASS/ ) {
				$result[1] = int( $result[1] ) + 1;
			}
			if ( $result =~ /FAIL/ ) {
				$result[2] = int( $result[2] ) + 1;
			}
			if ( $result =~ /N\/A/ ) {
				$result[3] = int( $result[3] ) + 1;
			}
			$result_list_tree{$_} = join( ":", @result );
		}
		else {
			if ( $result =~ /PASS/ ) {
				$result_list_tree{$_} = "1:1:0:0";
			}
			if ( $result =~ /FAIL/ ) {
				$result_list_tree{$_} = "1:0:1:0";
			}
			if ( $result =~ /N\/A/ ) {
				$result_list_tree{$_} = "1:0:0:1";
			}
		}
	}
}

sub getHTMLResult {
	my ($name) = @_;
	my $resultHTML;
	if ( defined $result_list_tree{$name} ) {
		my @result = split( ":", $result_list_tree{$name} );
		$resultHTML = '('
		  . $result[0]
		  . ' <span class=\'result_pass\'>'
		  . $result[1]
		  . '</span> <span class=\'result_fail\'>'
		  . $result[2]
		  . '</span> <span class=\'result_not_run\'>'
		  . $result[3]
		  . '</span>)';
	}
	else {
		$resultHTML =
		    '(' . '0'
		  . ' <span class=\'result_pass\'>' . '0'
		  . '</span> <span class=\'result_fail\'>' . '0'
		  . '</span> <span class=\'result_not_run\'>' . '0'
		  . '</span>)';
	}
	return $resultHTML;
}

sub getSamePackage {
	my %allPackage;
	my $number = 0;
	foreach (@select_dir) {
		updateResultList($_);
		if ( $max_package_number < @result_list_xml ) {
			$max_package_number = @result_list_xml;
		}
		foreach (@result_list_xml) {
			my $package = $_;
			$package =~ s/\/.*\///;
			if ( defined( $allPackage{$package} ) ) {
				$allPackage{$package}++;
				$all_package_list{$package} .= ':' . $number;
			}
			else {
				$allPackage{$package}       = 1;
				$all_package_list{$package} = $number;
			}
		}
		@result_list_xml = ();
		$number++;
	}
	foreach ( keys(%allPackage) ) {
		if ( $allPackage{$_} == @select_dir ) {
			push( @same_package_list, $_ );
		}
	}
}
