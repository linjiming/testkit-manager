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

use FindBin;
use strict;
use Templates;
use File::Find;
use Data::Dumper;
use Digest::SHA qw(sha1_hex);

# data which is going to be displayed
my @report_display   = ();
my @select_dir       = ();
my @package_list     = ();
my @test_type        = ();         #which test type are stored in the xml
my $hasTestTypeError = "FALSE";    #have error when list all cases by test type
my %caseInfo;                      #parse all info items from xml
my %manual_case_result;            #parse manual case result from txt file
my %component_list
  ;               #extract component and give it format like 1->a::root__b::root
my %spec_list;    #extract spec and give it format like 1->a::root__b::root
my %steps;        #parse steps part of the case info
my @result_list_xml =
  ();             #put all xml result into format --form report.1=@sim.xml
my %result_list_tree;    #(total pass fail not run) for tree view
my @same_package_list = ();    #extract same packages from selected reports
my $max_package_number =
  0;    #extract the maximum package number from selected reports
my %all_package_list;    #store package distribution
my @reverse_time = ();   #store reversed order time list
my @ordered_time = ();   #store normal order time list

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
<table width="768" border="0" cellspacing="0" cellpadding="0" class="report_list">
  <tr>
    <td height="30"><table width="100%" height="30" border="0" cellpadding="0" cellspacing="0" class="table_normal">
        <tr>
DATA
		for ( my $i = 0 ; $i < @select_dir ; $i++ ) {
			my $time       = $select_dir[$i];
			my $class_time = "report_list_outside_left_compare_empty";
			print <<DATA;
          <td class="$class_time" align="center" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$time">$time</td>
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
  <tr>
    <td height="30" class="report_list_outside_left_compare" align="left" style="background-color:#89D6F2">&nbsp;Package Name: $package_temp</td>
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
          <td valign="top" class="$class_td_border"><table width="100%" border="0" cellspacing="0" cellpadding="0" class="table_normal">
              <tr>
                <td width="80%" height="30" class="$class_name" align="left">&nbsp;Name</td>
                <td width="20%" height="30" class="$class_result" align="center" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="Result">Result</td>
              </tr>
DATA

					# print Auto case
					my $startCase = "FALSE";
					my $xml       = "none";
					my $name      = "none";
					my $result    = "None";
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
							$isAuto    = "FALSE";
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
                <td width="80%" height="30" class="$class_name" align="left" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$name"><a onclick="javascript:show_case_detail('detailed_$id');">&nbsp;$name</a></td>
                <td width="20%" height="30" class="$class_result" align="center" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$result">$result</td>
              </tr>
DATA
							print <<DATA;
              <tr id="detailed_$id" style="display:none">
                <td height="30" colspan="2">
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
							&& ( $isManual eq "TRUE" )
							&& ( defined( $manual_case_result{$name} ) ) )

						{
							if ( defined $manual_case_result{$name} ) {
								$startCase = "FALSE";
								$isManual  = "FALSE";
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
                <td width="80%" height="30" class="$class_name" align="left" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$name"><a onclick="javascript:show_case_detail('detailed_$id');">&nbsp;$name</a></td>
                <td width="20%" height="30" class="$class_result" align="center" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$result">$result</td>
              </tr>
DATA
								print <<DATA;
              <tr id="detailed_$id" style="display:none">
                <td height="30" colspan="2">
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
          <td valign="top" class="$class_td_border"><table width="100%" border="0" cellspacing="0" cellpadding="0" class="table_normal">
              <tr>
                <td width="80%" height="30" class="$class_name" align="left">&nbsp;Name</td>
                <td width="20%" height="30" class="$class_result" align="center" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="Result">Result</td>
              </tr>
              <tr>
                <td width="80%" height="30" class="$class_name" align="left">&nbsp;None</td>
                <td width="20%" height="30" class="$class_result" align="center" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="Result">None</td>
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
			"No same package is found from the selected reports.");
		showReport();
	}
}

# press delete button
elsif ( $_POST{'delete'} ) {
	updateSelectDir(%_POST);
	foreach (@select_dir) {
		system("rm -rf $result_dir_manager$_");
	}

	my $report_ori   = $result_dir_manager . '*s';
	my $histtory_ori = $result_dir_manager . 'HISTORY';
	my $latest_ori   = $result_dir_manager . 'latest';
	system("rm -rf $report_ori");
	system("rm -rf $histtory_ori");
	system("rm -rf $latest_ori");

	print "HTTP/1.0 200 OK" . CRLF;
	print "Content-type: text/html" . CRLF . CRLF;
	print_header( "$MTK_BRANCH Manager Test Report", "report" );

	showReport();
}

# press mail icon
elsif ( $_GET{'mail'} ) {
	print "HTTP/1.0 200 OK" . CRLF;
	print "Content-type: text/html" . CRLF . CRLF;
	print_header( "$MTK_BRANCH Manager Test Report", "report" );

	my $time = $_GET{'time'};
	updateResultList($time);

	my $hasEvolution = `which evolution 2>&1`;
	if ( $hasEvolution =~ /which: no/ ) {
		my $attach = "";
		for ( my $i = 1 ; $i <= @result_list_xml ; $i++ ) {
			$attach .= '<p>' . $result_list_xml[ $i - 1 ] . '</p>';
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
		my $command =
'subject=Test%20report%20from%20testkit-manager\&body=Please%20check%20detailed%20report%20from%20the%20attachment'
		  . $form_xml;
		$command =~ s/:/%3A/g;
		$command = "export DISPLAY=:0.0;su tizen -c 'evolution mailto:?" 
		  . $command . "'";

		use threads;
		my $thr = threads->new( \&callSystem, $command );
		print show_message_dlg("Please specify a receiver in the Evolution.");
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

	$target    =~ s/ /%20/g;
	$testtype  =~ s/ /%20/g;
	$hwproduct =~ s/ /%20/g;

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
		my $command =
		    "curl --connect-timeout 3"
		  . $form_xml
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
		$command .= " 2>&1";

		my $submit_result = `$command`;
		if ( $submit_result =~ /"ok":"1"/ ) {
			print show_message_dlg("Reports have been submitted");
		}
		elsif ( $submit_result =~ /timed out/ ) {
			print show_error_dlg( "Connection timeout to server '"
				  . $server_name
				  . "' please check your network!" );
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

# press submit icon
elsif ( $_GET{'submit'} ) {
	print "HTTP/1.0 200 OK" . CRLF;
	print "Content-type: text/html" . CRLF . CRLF;
	print_header( "$MTK_BRANCH Manager Test Report", "report" );

	my $time = $_GET{'time'};
	print <<DATA;
<div id="message"></div>
<table width="768" border="0" cellspacing="0" cellpadding="0">
  <tr>
    <td><form id="submit_server" name="submit_server" method="post" action="tests_report.pl">
      <table width="100%" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td height="30" class="top_button_bg">
<table width="100%" height="30" border="0" cellpadding="0" cellspacing="0">
  <tr>
    <td width="15">&nbsp;</td>
    <td width="110" align="left" valign="middle"><input name="server_name" type="text" class="submit_server" id="server_name" onfocus="javascript:submit_perpare('server_name');" onblur="javascript:update_submit_text_field();" value="Input Server Name" /></td>
    <td width="5">&nbsp;</td>
    <td width="110" align="left" valign="middle"><input name="token" type="text" class="submit_server" id="token" onfocus="javascript:submit_perpare('token');" onblur="javascript:update_submit_text_field();" value="Input Token" /></td>
    <td width="5">&nbsp;</td>
    <td width="110" align="left" valign="middle"><input name="image_date" type="text" class="submit_server" id="image_date" onfocus="javascript:submit_perpare('image_date');" onblur="javascript:update_submit_text_field();" value="Input Image Date" /></td>
    <td width="5">&nbsp;</td>
    <td width="54" align="left" valign="middle"><select name="target" id="target" onchange="javascript:update_submit_text_field();">
        <option>Common</option>
        <option>Netbook</option>
        <option>IVI</option>
        <option>SDK</option>
        <option>TV</option>
        <option selected="selected">target</option>
      </select>
    </td>
    <td width="5">&nbsp;</td>
    <td width="102" align="left" valign="middle"><select name="testtype" id="testtype" onchange="javascript:update_submit_text_field();">
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
    <td width="5">&nbsp;</td>
    <td width="102" align="left" valign="middle"><select name="hwproduct" id="hwproduct" onchange="javascript:update_submit_text_field();">
        <option>Cedartrail</option>
        <option>Pinetrail</option>
        <option>TunnelCreek</option>
        <option selected="selected">hwproduct</option>
      </select>
    </td>
    <td width="5">&nbsp;</td>
    <td width="75" align="center" valign="middle"><input type="submit" name="submit_server" id="submit_button" value="Submit" disabled="disabled" class="bottom_button" /></td>
    <td>&nbsp;</td>
  </tr>
</table>
          </td>
        </tr>
        <tr>
          <td><table width="100%" border="1" cellpadding="0" cellspacing="0" class="report_list" frame="below" rules="all">
            <tr>
              <td width="4%" height="30" class="report_list_one_row">&nbsp;</td>
              <td align="left" height="30" class="report_list_one_row">The following report will be submitted to the QA report server:</td>
            </tr>
DATA
	print <<DATA;
            <tr>
              <td align="left" width="4%" height="30" class="report_list_outside_left">&nbsp;&nbsp;&nbsp;1.</td>
              <td align="left" height="30" class="report_list_outside_right">&nbsp;$time<input type="text" name="$time" value="" style="display:none" /></td>
            </tr>
DATA
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
update_submit_text_field();

function update_submit_text_field() {
	var button = document.getElementById('submit_button');
	var server_name = document.getElementById('server_name');
	var token = document.getElementById('token');
	var image_date = document.getElementById('image_date');
	var target = document.getElementById('target');
	var testtype = document.getElementById('testtype');
	var hwproduct = document.getElementById('hwproduct');

	var server_name_status = 0;
	var token_status = 0;
	var image_date_status = 0;
	var target_status = 0;
	var testtype_status = 0;
	var hwproduct_status = 0;

	if ((server_name.value == "") || (server_name.value == "Input Server Name")) {
		server_name.style.borderColor = "#E2E3E3";
		server_name.value = "Input Server Name";
	} else {
		var reg1 = /^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\$/;
		var result1 = reg1.exec(server_name.value);
		var reg2 = /\.com\$/;
		var result2 = reg2.exec(server_name.value);
		if (result1 || result2) {
			server_name_status = 1;
			server_name.style.borderColor = "green";
		} else {
			server_name.style.borderColor = "red";
		}
	}
	if ((token.value == "") || (token.value == "Input Token")) {
		token.style.borderColor = "#E2E3E3";
		token.value = "Input Token";
	} else {
		var reg = /^.{15,}/;
		var result = reg.exec(token.value);
		if (result) {
			token_status = 1;
			token.style.borderColor = "green";
		} else {
			token.style.borderColor = "red";
		}
	}
	if ((image_date.value == "") || (image_date.value == "Input Image Date")) {
		image_date.style.borderColor = "#E2E3E3";
		image_date.value = "Input Image Date";
	} else {
		var reg = /^[0-9]{8}%2E[0-9]{1}\$/;
		var result = reg.exec(image_date.value);
		if (result) {
			image_date_status = 1;
			image_date.style.borderColor = "green";
		} else {
			image_date.style.borderColor = "red";
		}
	}

	if (target.value != "target") {
		target_status = 1;
	}
	if (testtype.value != "testtype") {
		testtype_status = 1;
	}
	if (hwproduct.value != "hwproduct") {
		hwproduct_status = 1;
	}

	if (button && server_name_status && token_status && image_date_status
			&& target_status && testtype_status && hwproduct_status) {
		button.disabled = 0;
	} else {
		button.disabled = 1;
	}
}

function submit_perpare(id) {
	var reg = /^Input /;
	var str = document.getElementById(id).value;
	var result = reg.exec(str);
	if (result) {
		document.getElementById(id).value = "";
	}
}
// ]]>
</script>
DATA
}

# click view report icon
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

# click view summary report button
elsif ( $_POST{'summary_report'} ) {
	print "HTTP/1.0 200 OK" . CRLF;
	print "Content-type: text/html" . CRLF . CRLF;
	print_header( "$MTK_BRANCH Manager Test Report", "report" );

	showSummaryReport( $_POST{'time_flag'} );
}

# click view detailed report button
elsif ( $_POST{'detailed_report'} ) {
	print "HTTP/1.0 200 OK" . CRLF;
	print "Content-type: text/html" . CRLF . CRLF;
	print_header( "$MTK_BRANCH Manager Test Report", "report" );

	showDetailedReport( $_POST{'time_flag'} );
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
<table width="768" border="0" cellspacing="0" cellpadding="0" class="report_list">
  <tr>
    <td><form id="report_list" name="report_list" method="post" action="tests_report.pl">
      <table width="768" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td height="30" class="top_button_bg"><table width="768" height="30" border="0" cellpadding="0" cellspacing="0">
            <tr>
              <td width="2%">&nbsp;</td>
              <td><table width="100%" height="30" border="0" cellpadding="0" cellspacing="0">
                <tr>
                  <td>Test report for all executions</td>
                </tr>
              </table></td>
            </tr>
          </table></td>
        </tr>
        <tr>
          <td><table width="768" border="1" cellspacing="0" cellpadding="0" frame="below" rules="all" class="table_normal">
            <tr>
              <td width="4%" height="30" align="center" valign="middle" class="report_list_outside_left"><label>
                <input type="checkbox" name="check_all" id="check_all" onclick="javascript:check_uncheck_all();" />
              </label></td>
              <td align="left" width="26%" class="report_list_inside">&nbsp;Test Time</td>
              <td align="left" width="12%" class="report_list_inside">&nbsp;Test Plan</td>
              <td align="left" width="12%" class="report_list_inside">&nbsp;Device Name</td>
              <td width="24%" class="report_list_inside"><table width="100%" height="30" border="0" cellpadding="0" cellspacing="0">
                <tr>
                  <td width="45%" align="left">&nbsp;Auto Status</td>
                  <td width="1%" align="center" valign="middle"><img src="images/splitter_result.png" width="2" height="12" /></td>
                  <td width="54%" align="left">&nbsp;Manual Status</td>
                </tr>
              </table></td>
              <td align="left" width="22%" class="report_list_outside_right">&nbsp;Operation</td>
            </tr>
DATA

	# print data from runconfig and info file
	my $count = 0;
	while ( $count < @report_display ) {
		my $time           = $report_display[ $count++ ];
		my $test_plan      = $report_display[ $count++ ];
		my $device_name    = $report_display[ $count++ ];
		my $not_run_auto   = $report_display[ $count++ ];
		my $not_run_manual = $report_display[ $count++ ];
		my $result_dir_tgz = $result_dir_manager . $time . "/" . $time . ".tgz";
		print <<DATA;
            <tr>
              <td width="4%" height="30" align="center" valign="middle" class="report_list_outside_left"><label>
                <input type="checkbox" id="$time" name="$time" onclick="javascript:update_state();" />
              </label></td>
              <td align="left" width="26%" class="report_list_inside"><a href="tests_report.pl?time=$time&detailed=1">&nbsp;$time</a></td>
              <td align="left" width="12%" class="report_list_inside" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$test_plan">&nbsp;$test_plan</td>
              <td align="left" width="12%" class="report_list_inside" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$device_name">&nbsp;$device_name</td>
              <td width="24%" class="report_list_inside"><table width="100%" height="30" border="0" cellpadding="0" cellspacing="0">
                <tr>
DATA
		if ( $not_run_auto == 0 ) {
			print <<DATA;
			      <td width="45%" align="left" class="result_pass">&nbsp;Complete</td>
                  <td width="1%" align="center" valign="middle"><img src="images/splitter_result.png" width="2" height="12" /></td>
DATA
		}
		else {
			print <<DATA;
			      <td width="45%" align="left" class="result_not_run">&nbsp;Incomplete</td>
                  <td width="1%" align="center" valign="middle"><img src="images/splitter_result.png" width="2" height="12" /></td>
DATA
		}
		if ( $not_run_manual == 0 ) {
			print <<DATA;
			      <td width="54%" align="left" class="result_pass">&nbsp;Complete</td>
DATA
		}
		else {
			print <<DATA;
			      <td width="54%" align="left" class="result_not_run">&nbsp;Incomplete</td>
DATA
		}
		print <<DATA;
                </tr>
              </table></td>
              <td align="left" width="22%" class="report_list_outside_right"><table width="100%" height="30" border="0" cellpadding="0" cellspacing="0">
                <tr>
                  <td><a href="tests_report.pl?time=$time&summary=1"><img title="View report in list view" src="images/operation_view_summary_report.png" alt="operation_view_summary_report" width="23" height="23" /></a></td>
                  <td><a href="tests_execute_manual.pl?time=$time"><img title="Continue execution" src="images/operation_continue_execution_enable.png" alt="operation_continue_execution_enable" width="23" height="23" /></a></td>
                  <td><a href="get.pl$result_dir_tgz"><img title="Download consolidated report" src="images/operation_download.png" alt="operation_download_consolidated_log" width="23" height="23" /></a></td>
                  <td><a href="tests_report.pl?time=$time&submit=1"><img title="Submit report to QA report server" src="images/operation_submit.png" alt="operation_submit_to_QA_report_server" width="23" height="23" /></a></td>
                  <td><a href="tests_report.pl?time=$time&mail=1"><img title="Send report through email" src="images/operation_mail.png" alt="operation_mail" width="23" height="23" /></a></td>
                </tr>
              </table></td>
            </tr>
DATA
	}
	print <<DATA;
          </table></td>
        </tr>
        <tr>
          <td height="30"><table width="768" height="30" border="0" cellpadding="0" cellspacing="0">
            <tr>
              <td>
                <table width="100%" height="30" border="0" cellpadding="0" cellspacing="0">
                  <tr>
                    <td width="80%">&nbsp;</td>
                    <td width="10%" align="center"><input type="submit" name="compare" id="compare_button" title="Compare two or more reports that include at least one same package" value="Compare" disabled="disabled" class="top_button" /></td>
                    <td width="10%" align="center"><input type="submit" name="delete" id="delete_button" title="Delete reports" value="Delete" disabled="disabled" onclick="javascript:return confirm_remove();" class="top_button" /></td>
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
var check_all_box = document.getElementById('check_all');
if (check_all_box) {
	update_state(); // Remember state of the buttons
}

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
	var elem = document.getElementById('check_all');
	if (num_checked == num_checkbox){
		if (num_checked == 0){
			elem.checked = 0
		} else {
			elem.checked = 1
		}
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
		return confirm('Are you sure to delete the ' + num + ' selected report(s)?');
}
// ]]>
</script>
DATA
}

sub showSummaryReport {
	my ($time) = @_;
	my $result_dir = $result_dir_manager . $time;

	print <<DATA;
<table width="768" border="0" cellspacing="0" cellpadding="0" class="report_list">
  <tr>
    <td align="left" height="30" class="top_button_bg"><form id="detailed_report" name="detailed_report" method="post" action="tests_report.pl"><table width="100%" height="30" border="0" cellpadding="0" cellspacing="0">
      <tr>
        <td width="2%">&nbsp;</td>
        <td width="78%">Test report for $time in list view<input type="text" name="time_flag" value="$time" style="display:none" /></td>
        <td width="10%" align="center"><input type="submit" name="summary_report" id="summary_report_button" title="View test report in list view" value="List View" disabled="disabled" class="top_button" /></td>
        <td width="10%" align="center"><input type="submit" name="detailed_report" id="detailed_report_button" title="View test report in tree view" value="Tree View" class="top_button" /></td>
      </tr>
    </table></form></td>
  </tr>
  <tr>
    <td>
DATA
	print xml2xsl( $result_dir . "/tests.result.xml" );
	print <<DATA;
    </td>
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
  <table width="768" border="0" cellspacing="0" cellpadding="0" class="report_list">
    <tr>
      <td><form id="detailed_report" name="detailed_report" method="post" action="tests_report.pl">
        <table width="100%" border="0" cellspacing="0" cellpadding="0">
          <tr>
            <td align="left" height="30" class="top_button_bg"><table width="100%" height="30" border="0" cellpadding="0" cellspacing="0">
              <tr>
                <td width="2%">&nbsp;</td>
                <td width="78%">Test report for $time in tree view<input type="text" name="time_flag" value="$time" style="display:none" /></td>
                <td width="10%" align="center"><input type="submit" name="summary_report" id="summary_report_button" title="View test report in list view" value="List View" class="top_button" /></td>
                <td width="10%" align="center"><input type="submit" name="detailed_report" id="detailed_report_button" title="View test report in tree view" value="Tree View" disabled="disabled" class="top_button" /></td>
              </tr>
            </table></td>
          </tr>
          <tr>
            <td align="center" height="30" class="report_list_one_row"><table width="100%" height="30" border="0" cellpadding="0" cellspacing="0" class="table_normal">
              <tr>
                <td width="5%">&nbsp;</td>
                <td width="30%" align="right">View by
                  <select name="select_view" id="select_view" onchange="javascript:filter_view();">
                    <option selected="selected">Package</option>
                    <option>Component</option>
                    <option>Test type</option>
                  </select>
                </td>
                <td width="30%" align="center">
                  Result
                  <select name="select_result" id="select_result" onchange="javascript:filter();">
                    <option selected="selected">FAIL</option>
                    <option>PASS</option>
                    <option>BLOCK</option>
                    <option>N/A</option>
                    <option>All</option>
                  </select>
                </td>
                <td width="30%" align="left">
                  Type
                  <select name="select_type" id="select_type" onchange="javascript:filter();">
                    <option selected="selected">All</option>
                    <option>auto</option>
                    <option>manual</option>
                  </select>
                </td>
                <td width="5%">&nbsp;</td>
              </tr>
            </table></td>
          </tr>
          <tr>
            <td><table width="100%" border="1" cellspacing="0" cellpadding="0" class="table_normal" frame="void" rules="all">
              <tr>
                <td width="1%" class="report_list_one_row" style="background-color:#E9F6FC">&nbsp;</td>
                <td width="39%" valign="top" class="report_list_outside_left_bold" style="background-color:#E9F6FC">
                  <div id="tree_area_package" style="background:transparent; overflow-x:auto; overflow-y:hidden;"></div>
                  <div id="tree_area_component" style="background:transparent; display:none; overflow-x:auto; overflow-y:hidden;"></div>
                  <div id="tree_area_test_type" style="background:transparent; display:none; overflow-x:auto; overflow-y:hidden;"></div></td>
                <td width="60%" valign="top" class="report_list_outside_right_bold"><div id="view_area_package">
                  <div id="view_area_package_reg" style="display:none"></div>
                  <table width="100%" border="0" cellspacing="0" cellpadding="0">
                    <tr>
                      <td><table width="100%" border="0" cellspacing="0" cellpadding="0" class="table_normal">
                          <tr>
                            <td align="left" width="40%" height="30" class="report_list_outside_left">&nbsp;Name</td>
                            <td align="left" width="40%" height="30" class="report_list_one_row">&nbsp;Description</td>
                            <td width="20%" height="30" class="report_list_outside_right" align="center">Result</td>
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
				$isAuto      = "FALSE";
				%caseInfo    = updateCaseInfo($xml);
				$result      = $caseInfo{"result"};
				$description = $caseInfo{"description"};
				$result =~ s/^\s//;
				$result =~ s/\s$//;

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
                            <td align="left" width="40%" height="30" class="report_list_outside_left" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$name"><a onclick="javascript:show_case_detail('detailed_case_package_$name');">&nbsp;$name</a></td>
                            <td align="left" width="40%" height="30" class="report_list_one_row" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$description">&nbsp;$description</td>
                            <td width="20%" height="30" class="report_list_outside_right" align="center">$result</td>
                          </tr>
                          <tr id="detailed_case_package_$name" style="display:none">
                            <td height="30" colspan="3">
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
		my $isManual         = "FALSE";
		my $total_result_xml = "$result_dir_manager$time/tests.result.xml";
		open FILE, $total_result_xml or die $!;
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
				$isManual  = "FALSE";
				%caseInfo  = updateCaseInfo($xml);
				if ( defined $manual_case_result{$name} ) {
					$result      = $manual_case_result{$name};
					$description = $caseInfo{"description"};
					$result =~ s/^\s//;
					$result =~ s/\s$//;

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
                            <td align="left" width="40%" height="30" class="report_list_outside_left" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$name"><a onclick="javascript:show_case_detail('detailed_case_package_$name');">&nbsp;$name</a></td>
                            <td align="left" width="40%" height="30" class="report_list_one_row" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$description">&nbsp;$description</td>
                            <td width="20%" height="30" class="report_list_outside_right" align="center">$result</td>
                          </tr>
                          <tr id="detailed_case_package_$name" style="display:none">
                            <td height="30" colspan="3">
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
                    <tr>
                      <td><table width="100%" border="0" cellspacing="0" cellpadding="0" class="table_normal">
                          <tr>
                            <td align="left" width="40%" height="30" class="report_list_outside_left">&nbsp;Name</td>
                            <td align="left" width="40%" height="30" class="report_list_one_row">&nbsp;Description</td>
                            <td width="20%" height="30" class="report_list_outside_right" align="center">Result</td>
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
				$isAuto      = "FALSE";
				%caseInfo    = updateCaseInfo($xml);
				$result      = $caseInfo{"result"};
				$description = $caseInfo{"description"};
				$component   = $caseInfo{"component"};
				$result =~ s/^\s//;
				$result =~ s/\s$//;

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
                            <td align="left" width="40%" height="30" class="report_list_outside_left" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$name"><a onclick="javascript:show_case_detail('detailed_case_component_$name');">&nbsp;$name</a></td>
                            <td align="left" width="40%" height="30" class="report_list_one_row" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$description">&nbsp;$description</td>
                            <td width="20%" height="30" class="report_list_outside_right" align="center">$result</td>
                          </tr>
                          <tr id="detailed_case_component_$name" style="display:none">
                            <td height="30" colspan="3">
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
		my $isManual         = "FALSE";
		my $total_result_xml = "$result_dir_manager$time/tests.result.xml";
		open FILE, $total_result_xml or die $!;
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
				$isManual    = "FALSE";
				%caseInfo    = updateCaseInfo($xml);
				$description = $caseInfo{"description"};
				if ( defined $manual_case_result{$name} ) {
					$result    = $manual_case_result{$name};
					$component = $caseInfo{"component"};
					$result =~ s/^\s//;
					$result =~ s/\s$//;

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
                            <td align="left" width="40%" height="30" class="report_list_outside_left" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$name"><a onclick="javascript:show_case_detail('detailed_case_component_$name');">&nbsp;$name</a></td>
                            <td align="left" width="40%" height="30" class="report_list_one_row" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$description">&nbsp;$description</td>
                            <td width="20%" height="30" class="report_list_outside_right" align="center">$result</td>
                          </tr>
                          <tr id="detailed_case_component_$name" style="display:none">
                            <td height="30" colspan="3">
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
                    <tr>
                      <td><table width="100%" border="0" cellspacing="0" cellpadding="0"class="table_normal">
                          <tr>
                            <td align="left" width="40%" height="30" class="report_list_outside_left">&nbsp;Name</td>
                            <td align="left" width="40%" height="30" class="report_list_one_row">&nbsp;Description</td>
                            <td width="20%" height="30" class="report_list_outside_right" align="center">Result</td>
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
		my $specs          = "none";
		my $spec_number    = 0;
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
				$isAuto      = "FALSE";
				%caseInfo    = updateCaseInfo($xml);
				$result      = $caseInfo{"result"};
				$description = $caseInfo{"description"};
				$specs       = $caseInfo{"specs"};
				$test_type   = $caseInfo{"test_type"};
				$result =~ s/^\s//;
				$result =~ s/\s$//;

				my @spec_hex = ();
				if (
					(
						$specs ne
"none!::!none!::!none!::!none!::!none!::!none!::!none!::!none!::!none"
					)
					or ( $specs ne "none" )
				  )
				{
					my @spec_list = split( "!__!", $specs );
					foreach (@spec_list) {
						$spec_number++;
						my @spec_content = split( "!::!", $_ );
						my @spec_content_top_5 = ();
						for ( my $i = 0 ; $i < 5 ; $i++ ) {
							if ( $spec_content[$i] eq "none" ) {
								push( @spec_content_top_5, "[unknown]" );
							}
							else {
								push( @spec_content_top_5, $spec_content[$i] );
							}
						}
						my @spec_content_back = @spec_content_top_5;
						for ( my $i = 0 ; $i < @spec_content ; $i++ ) {
							push( @spec_hex,
								sha1_hex( join( ":", @spec_content_back ) ) );
							pop(@spec_content_back);
						}
					}
				}
				elsif ( $test_type eq "compliance" ) {

					# print error message when there is no spec in case xml
					print
					  '<p style="font-size:10px">&nbsp;<span style="color:red">'
					  . $name
					  . '</span> got no &lt;spec&gt; tag</p>';
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
				for ( my $i = 1 ; $i < $spec_number ; $i++ ) {
					push( @spec_hex_temp, 'TT_' . $test_type );
				}
				$spec_number = 0;
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
                            <td align="left" width="40%" height="30" class="report_list_outside_left" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$name"><a onclick="javascript:show_case_detail('detailed_case_test_type_$name');">&nbsp;$name</a></td>
                            <td align="left" width="40%" height="30" class="report_list_one_row" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$description">&nbsp;$description</td>
                            <td width="20%" height="30" class="report_list_outside_right" align="center">$result</td>
                          </tr>
                          <tr id="detailed_case_test_type_$name" style="display:none">
                            <td height="30" colspan="3">
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
		my $isManual         = "FALSE";
		my $total_result_xml = "$result_dir_manager$time/tests.result.xml";
		open FILE, $total_result_xml or die $!;
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
				$isManual  = "FALSE";
				%caseInfo  = updateCaseInfo($xml);
				if ( defined $manual_case_result{$name} ) {
					$result      = $manual_case_result{$name};
					$description = $caseInfo{"description"};
					$specs       = $caseInfo{"specs"};
					$test_type   = $caseInfo{"test_type"};
					$result =~ s/^\s//;
					$result =~ s/\s$//;

					my @spec_hex = ();
					if (
						(
							$specs ne
"none!::!none!::!none!::!none!::!none!::!none!::!none!::!none!::!none"
						)
						or ( $specs ne "none" )
					  )
					{
						my @spec_list = split( "!__!", $specs );
						foreach (@spec_list) {
							$spec_number++;
							my @spec_content = split( "!::!", $_ );
							my @spec_content_top_5 = ();
							for ( my $i = 0 ; $i < 5 ; $i++ ) {
								if ( $spec_content[$i] eq "none" ) {
									push( @spec_content_top_5, "[unknown]" );
								}
								else {
									push( @spec_content_top_5,
										$spec_content[$i] );
								}
							}
							my @spec_content_back = @spec_content_top_5;
							for ( my $i = 0 ; $i < @spec_content ; $i++ ) {
								push( @spec_hex,
									sha1_hex( join( ":", @spec_content_back ) )
								);
								pop(@spec_content_back);
							}
						}
					}
					elsif ( $test_type eq "compliance" ) {

						# print error message when there is no spec in case xml
						print
'<p style="font-size:10px">&nbsp;<span style="color:red">'
						  . $name
						  . '</span> got no &lt;spec&gt; tag</p>';
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
					for ( my $i = 1 ; $i < $spec_number ; $i++ ) {
						push( @spec_hex_temp, 'TT_' . $test_type );
					}
					$spec_number = 0;
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
                            <td align="left" width="40%" height="30" class="report_list_outside_left" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$name"><a onclick="javascript:show_case_detail('detailed_case_test_type_$name');">&nbsp;$name</a></td>
                            <td align="left" width="40%" height="30" class="report_list_one_row" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$description">&nbsp;$description</td>
                            <td width="20%" height="30" class="report_list_outside_right" align="center">$result</td>
                          </tr>
                          <tr id="detailed_case_test_type_$name" style="display:none">
                            <td height="30" colspan="3">
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
// package tree
\$(function() {
	\$("#tree_area_package").bind("click.jstree", function(event) {
		var eventNodeName = event.target.nodeName;
		if (eventNodeName == 'A') {
			// set result to 'Fail', type to 'All'
			var select_result = document.getElementById('select_result');
			var select_type = document.getElementById('select_type');
			select_result.selectedIndex = 0;
			select_type.selectedIndex = 0;
			// filter leaves
			var title = \$(event.target).parents('li').attr('id');
			var reg = title;
			document.getElementById("view_area_package_reg").innerHTML = reg;
			var page = document.getElementsByTagName("*");
			for ( var i = 0; i < page.length; i++) {
				var temp_id = page[i].id;
				if (temp_id.indexOf("case_package_") >= 0) {
					page[i].style.display = "none";
					if ((temp_id.indexOf(reg) >= 0) && (temp_id.indexOf("R:FAIL") >= 0)) {
						page[i].style.display = "";
					}
				}
			}
			// close detailed case div
			for ( var i = 0; i < page.length; i++) {
				var temp_id = page[i].id;
				if (temp_id.indexOf("detailed_case_package_") >= 0) {
					page[i].style.display = "none";
				}
			}
		}
	}).jstree(
			{
				"themes" : {
					"icons" : false
				},
				"ui" : {
					"select_limit" : 1
				},
				"xml_data" : {
					"data" : "" + "<root>"
DATA
	@package_list = updatePackageList($time);
	my $package_number = 1;

	# add package to the tree
	foreach (@package_list) {
		my $package = $_;
		my $tests_xml_dir =
		  $result_dir_manager . $time . "/" . $package . "_definition.xml";
		print "+ \"<item id='P:" . $package . "'>\"\n";
		print "+ \"<content><name>" 
		  . $package
		  . getHTMLResult( 'P_' . $package )
		  . "</name></content>\"\n";
		print "+ \"</item>\"\n";
		eval {

			# read definition xml, add suite and set to the tree
			open FILE, $tests_xml_dir or die $!;
			my $suite_number = 0;
			my $set_number   = 1;
			my $suite_name   = "[unknown]";
			my $set_name     = "[unknown]";
			while (<FILE>) {
				if ( $_ =~ /suite.*name="(.*?)"/ ) {
					$suite_name = $1;
					$suite_number++;
					print "+ \"<item id='SU:"
					  . $suite_name
					  . "' parent_id='P:"
					  . $package
					  . "'>\"\n";
					print "+ \"<content><name>"
					  . $suite_name
					  . getHTMLResult( 'SU_' . $suite_name )
					  . "</name></content>\"\n";
					print "+ \"</item>\"\n";
				}
				if ( $_ =~ /set.*name="(.*?)"/ ) {
					$set_name = $1;
					print "+ \"<item id='SE:"
					  . $set_name
					  . "' parent_id='SU:"
					  . $suite_name
					  . "'>\"\n";
					print "+ \"<content><name>"
					  . $set_name
					  . getHTMLResult( 'SE_' . $set_name )
					  . "</name></content>\"\n";
					print "+ \"</item>\"\n";
				}
			}
		};
		if ($@) {
			print "+ \"<item parent_id='P:" . $package . "'>\"\n";
			print "+ \"<content><name>missing file: "
			  . $tests_xml_dir
			  . "</name></content>\"\n";
			print "+ \"</item>\"\n";
		}
		$package_number++;
	}
	print <<DATA;
							+ "</root>"
				},
				"plugins" : [ "themes", "xml_data", "ui" ]
			});
});
</script>
<script language="javascript" type="text/javascript">
// component tree
\$(function() {
	\$("#tree_area_component").bind("click.jstree", function(event) {
		var eventNodeName = event.target.nodeName;
		if (eventNodeName == 'A') {
			// set result to 'Fail', type to 'All'
			var select_result = document.getElementById('select_result');
			var select_type = document.getElementById('select_type');
			select_result.selectedIndex = 0;
			select_type.selectedIndex = 0;
			// filter leaves
			var title = \$(event.target).parents('li').attr('id');
			var reg = title;
			document.getElementById("view_area_component_reg").innerHTML = reg;
			var page = document.getElementsByTagName("*");
			for ( var i = 0; i < page.length; i++) {
				var temp_id = page[i].id;
				if (temp_id.indexOf("case_component_") >= 0) {
					page[i].style.display = "none";
					if ((temp_id.indexOf(reg) >= 0) && (temp_id.indexOf("R:FAIL") >= 0)) {
						page[i].style.display = "";
					}
				}
			}
			// close detailed case div
			for ( var i = 0; i < page.length; i++) {
				var temp_id = page[i].id;
				if (temp_id.indexOf("detailed_case_component_") >= 0) {
					page[i].style.display = "none";
				}
			}
		}
	}).jstree(
			{
				"themes" : {
					"icons" : false
				},
				"ui" : {
					"select_limit" : 1
				},
				"xml_data" : {
					"data" : "" + "<root>"
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
				print "+ \"<item id='level-" . $i . ":" . $component . "'>\"\n";
				print "+ \"<content><name>"
				  . $component
				  . getHTMLResult( 'level-' . $i . ':' . $component )
				  . "</name></content>\"\n";
				print "+ \"</item>\"\n";
			}
			else {
				print "+ \"<item id='level-" 
				  . $i . ":"
				  . $component
				  . "' parent_id='level-"
				  . ( $i - 1 ) . ":"
				  . $parent
				  . "'>\"\n";
				print "+ \"<content><name>"
				  . $component
				  . getHTMLResult( 'level-' . $i . ':' . $component )
				  . "</name></content>\"\n";
				print "+ \"</item>\"\n";
			}
		}
	}
	print <<DATA;
							+ "</root>"
				},
				"plugins" : [ "themes", "xml_data", "ui" ]
			});
});
</script>

<script language="javascript" type="text/javascript">
// test type tree
\$(function() {
	\$("#tree_area_test_type").bind("click.jstree", function(event) {
		var eventNodeName = event.target.nodeName;
		if (eventNodeName == 'A') {
			// set result to 'Fail', type to 'All'
			var select_result = document.getElementById('select_result');
			var select_type = document.getElementById('select_type');
			select_result.selectedIndex = 0;
			select_type.selectedIndex = 0;
			// filter leaves
			var title = \$(event.target).parents('li').attr('id');
			var reg = "";
			var reg_test_type = "";
			var have_test_type = "";
			if ((title.indexOf("P:") >= 0) || (title.indexOf("SU:") >= 0) || (title.indexOf("SE:") >= 0)) {
				have_test_type = "TRUE";
				var reg_both = title.split("__");
				reg_test_type = reg_both[0];
				reg = reg_both[1];
			} else {
				have_test_type = "FALSE";
				reg = title;
			}
			document.getElementById("view_area_test_type_reg").innerHTML = title;
			var page = document.getElementsByTagName("*");
			for ( var i = 0; i < page.length; i++) {
				var temp_id = page[i].id;
				if (temp_id.indexOf("case_test_type_") >= 0) {
					page[i].style.display = "none";
					if (have_test_type == "TRUE") {
						if ((temp_id.indexOf(reg) >= 0) && (temp_id.indexOf(reg_test_type) >= 0) && (temp_id.indexOf("R:FAIL") >= 0)) {
							page[i].style.display = "";
						}
					} else {
						if ((temp_id.indexOf(reg) >= 0) && (temp_id.indexOf("R:FAIL") >= 0)) {
							page[i].style.display = "";
						}
					}
				}
			}
			// close detailed case div
			for ( var i = 0; i < page.length; i++) {
				var temp_id = page[i].id;
				if (temp_id.indexOf("detailed_case_test_type_") >= 0) {
					page[i].style.display = "none";
				}
			}
		}
	}).jstree(
			{
				"themes" : {
					"icons" : false
				},
				"ui" : {
					"select_limit" : 1
				},
				"xml_data" : {
					"data" : "" + "<root>"
DATA

	my $haveCompliance = "FALSE";
	updateTestTypeList($time);
	foreach (@test_type) {
		my $test_type = $_;
		if ( $test_type ne "compliance" ) {
			print "+ \"<item id='TT:" . $test_type . "'>\"\n";
			print "+ \"<content><name>"
			  . $test_type
			  . getHTMLResult( 'TT_' . $test_type )
			  . "</name></content>\"\n";
			print "+ \"</item>\"\n";
			@package_list = updatePackageList($time);
			my $package_number = 1;

			# add package to the tree
			foreach (@package_list) {
				my $package = $_;
				my $tests_xml_dir =
				    $result_dir_manager 
				  . $time . "/" 
				  . $package
				  . "_definition.xml";
				print "+ \"<item id='TT:"
				  . $test_type . "__P:"
				  . $package
				  . "' parent_id='TT:"
				  . $test_type
				  . "'>\"\n";
				print "+ \"<content><name>" 
				  . $package
				  . getHTMLResult( 'TT_' . $test_type . "P_" . $package )
				  . "</name></content>\"\n";
				print "+ \"</item>\"\n";
				eval {

					# read definition xml, add suite and set to the tree
					open FILE, $tests_xml_dir or die $!;
					my $suite_number = 0;
					my $set_number   = 1;
					my $suite_name   = "[unknown]";
					my $set_name     = "[unknown]";
					while (<FILE>) {
						if ( $_ =~ /suite.*name="(.*?)"/ ) {
							$suite_name = $1;
							$suite_number++;
							print "+ \"<item id='TT:"
							  . $test_type . "__SU:"
							  . $suite_name
							  . "' parent_id='TT:"
							  . $test_type . "__P:"
							  . $package
							  . "'>\"\n";
							print "+ \"<content><name>"
							  . $suite_name
							  . getHTMLResult(
								'TT_' . $test_type . "SU_" . $suite_name )
							  . "</name></content>\"\n";
							print "+ \"</item>\"\n";
						}
						if ( $_ =~ /set.*name="(.*?)"/ ) {
							$set_name = $1;
							print "+ \"<item id='TT:"
							  . $test_type . "__SE:"
							  . $set_name
							  . "' parent_id='TT:"
							  . $test_type . "__SU:"
							  . $suite_name
							  . "'>\"\n";
							print "+ \"<content><name>"
							  . $set_name
							  . getHTMLResult(
								'TT_' . $test_type . "SE_" . $set_name )
							  . "</name></content>\"\n";
							print "+ \"</item>\"\n";
						}
					}
				};
				if ($@) {
					print "+ \"<item parent_id='TT:"
					  . $test_type . "__P:"
					  . $package
					  . "'>\"\n";
					print "+ \"<content><name>missing file: "
					  . $tests_xml_dir
					  . "</name></content>\"\n";
					print "+ \"</item>\"\n";
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
		print "+ \"<item id='TT:compliance'>\"\n";
		print "+ \"<content><name>compliance"
		  . getHTMLResult('TT_compliance')
		  . "</name></content>\"\n";
		print "+ \"</item>\"\n";
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
					print "+ \"<item id='SP_"
					  . sha1_hex($parent)
					  . "' parent_id='TT:compliance'>\"\n";
					print "+ \"<content><name>" 
					  . $item
					  . getHTMLResult( 'SP_' . sha1_hex($parent) )
					  . "</name></content>\"\n";
					print "+ \"</item>\"\n";
				}
				else {
					print "+ \"<item id='SP_"
					  . sha1_hex( $parent . ':' . $item )
					  . "' parent_id='SP_"
					  . sha1_hex($parent)
					  . "'>\"\n";
					print "+ \"<content><name>" 
					  . $item
					  . getHTMLResult(
						'SP_' . sha1_hex( $parent . ':' . $item ) )
					  . "</name></content>\"\n";
					print "+ \"</item>\"\n";
				}
			}
		}
	}
	print <<DATA;
							+ "</root>"
				},
				"plugins" : [ "themes", "xml_data", "ui" ]
			});
});
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
		var page = document.getElementsByTagName("*");
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
		var page = document.getElementsByTagName("*");
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
		var page = document.getElementsByTagName("*");
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
	var page = document.getElementsByTagName("*");
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
	if ( $dir =~ /tests.result.xml$/ ) {
		open FILE, $dir or die $!;
		my $start_spec = "FALSE";
		my $xml        = "none";
		while (<FILE>) {
			if ( $start_spec eq "TRUE" ) {
				chomp( $xml .= $_ );
			}
			if ( $_ =~ /<spec>/ ) {
				$start_spec = "TRUE";
				chomp( $xml = $_ );
			}
			if ( $_ =~ /<\/spec>/ ) {
				$start_spec = "FALSE";
				my $spec_category      = "[unknown]";
				my $spec_section       = "[unknown]";
				my $spec_specification = "[unknown]";
				my $spec_interface     = "[unknown]";
				my $spec_element_name  = "[unknown]";
				if ( $xml =~ /category="(.*?)"/ ) {
					$spec_category = $1;
				}
				if ( $xml =~ /section="(.*?)"/ ) {
					$spec_section = $1;
				}
				if ( $xml =~ /specification="(.*?)"/ ) {
					$spec_specification = $1;
				}
				if ( $xml =~ /interface="(.*?)"/ ) {
					$spec_interface = $1;
				}
				if ( $xml =~ /element_name="(.*?)"/ ) {
					$spec_element_name = $1;
				}
				my @spec_item = ();
				push( @spec_item, $spec_category );
				push( @spec_item, $spec_section );
				push( @spec_item, $spec_specification );
				push( @spec_item, $spec_interface );
				push( @spec_item, $spec_element_name );

				for ( my $i = 0 ; $i < @spec_item ; $i++ ) {
					$spec_item[$i] =~ s/^[\s]+//;
					$spec_item[$i] =~ s/[\s]+$//;
					$spec_item[$i] =~ s/[\s]+/ /g;
					$spec_item[$i] =~ s/&lt;/[/g;
					$spec_item[$i] =~ s/&gt;/]/g;
					$spec_item[$i] =~ s/</[/g;
					$spec_item[$i] =~ s/>/]/g;
					if ( $spec_item[$i] eq "" ) {
						$spec_item[$i] = "[unknown]";
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
}

sub getReportDisplayData {
	find( \&getReportDisplayData_wanted, $result_dir_manager );

	@ordered_time = reverse(@reverse_time);
	foreach (@ordered_time) {
		my $time           = $_;
		my $test_plan      = "none";
		my $device_name    = "none";
		my $not_run_auto   = 0;
		my $not_run_manual = 0;
		eval {
			open FILE, $time . "/tests.result.xml"
			  or die "Can't open " . $time . "/tests.result.xml";

			while (<FILE>) {
				if ( $_ =~ /<summary test_plan_name="(.*?)">/ ) {
					$test_plan = $1;
				}
				if ( $_ =~ /device_name="(.*?)"/ ) {
					$device_name = $1;
				}
				if (    ( $_ =~ /execution_type="auto"/ )
					and ( $_ =~ /result="N\/A"/ ) )
				{
					$not_run_auto++;
				}
				if (    ( $_ =~ /execution_type="manual"/ )
					and ( $_ =~ /result="N\/A"/ ) )
				{
					$not_run_manual++;
				}
			}
		};
		if ($@) {
			$not_run_auto   = 1;
			$not_run_manual = 1;
		}
		my $time_only = "none";
		if ( $time =~ /\/opt\/testkit\/manager\/results\/(.*)/ ) {
			$time_only = $1;
		}
		push( @report_display, $time_only );
		push( @report_display, $test_plan );
		push( @report_display, $device_name );
		push( @report_display, $not_run_auto );
		push( @report_display, $not_run_manual );
	}
}

sub getReportDisplayData_wanted {
	my $dir = $File::Find::name;
	if ( $dir =~ /.*\/([0-9:\.\-]+)$/ ) {
		push( @reverse_time, $dir );
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
			if ( $result =~ /BLOCK/ ) {
				$result[3] = int( $result[3] ) + 1;
			}
			if ( $result =~ /N\/A/ ) {
				$result[4] = int( $result[4] ) + 1;
			}
			$result_list_tree{$_} = join( ":", @result );
		}
		else {
			if ( $result =~ /PASS/ ) {
				$result_list_tree{$_} = "1:1:0:0:0";
			}
			if ( $result =~ /FAIL/ ) {
				$result_list_tree{$_} = "1:0:1:0:0";
			}
			if ( $result =~ /BLOCK/ ) {
				$result_list_tree{$_} = "1:0:0:1:0";
			}
			if ( $result =~ /N\/A/ ) {
				$result_list_tree{$_} = "1:0:0:0:1";
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
		  . '</span> <span class=\'result_block\'>'
		  . $result[3]
		  . '</span> <span class=\'result_not_run\'>'
		  . $result[4]
		  . '</span>)';
	}
	else {
		$resultHTML =
		    '(' . '0'
		  . ' <span class=\'result_pass\'>' . '0'
		  . '</span> <span class=\'result_fail\'>' . '0'
		  . '</span> <span class=\'result_block\'>' . '0'
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
