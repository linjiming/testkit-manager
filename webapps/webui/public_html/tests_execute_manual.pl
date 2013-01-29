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
use Templates qw{$result_dir_manager $test_definition_dir};
use Data::Dumper;

my @package_list = ();
my %caseInfo;              #parse all info items from xml
my %manual_case_result;    #parse manual case result from txt file
my %progress_bar_result
  ;    #pares auto and manual case result to generate progress bar
my @case_id_list = ();    #store all case id

if ( $_GET{'time'} ) {
	print "HTTP/1.0 200 OK" . CRLF;
	print "Content-type: text/html" . CRLF . CRLF;

	print_header( "$MTK_BRANCH Manager Main Page", "execute" );

	my $time = $_GET{'time'};
	updateProgressBarResult($time);
	my $total_auto   = $progress_bar_result{"total_auto"};
	my $total_manual = $progress_bar_result{"total_manual"};

	print <<DATA;
<div id="ajax_loading" style="display:none"></div>
<div id="message"></div>
<div id="time" style="display:none">$time</div>
<table width="768" border="0" cellspacing="0" cellpadding="0" class="report_list">
  <tr>
    <td class="top_button_bg"><table width="100%" height="100%" border="0" cellpadding="0" cellspacing="0">
        <tbody>
          <tr>
            <td width="2%">&nbsp;</td>
            <td width="98%" align="left">Edit test results</td>
          </tr>
        </tbody>
      </table></td>
  </tr>
  <tr>
    <td><table width="100%" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td width="35%" valign="top" class="report_list_outside_left_bold navigation_bar_bg"><table width="100%" border="1" cellspacing="0" cellpadding="0" frame="below" rules="all">
              <tr id="background_summary_case_">
                <td width="4%" class="report_list_one_row">&nbsp;</td>
                <td align="left" class="report_list_one_row"><a onclick="javascript:filter('summary_case_');" class="navigation_normal_text">Total</a></td>
                <td class="report_list_one_row"></td>
              </tr>
              <tr id="background_T:auto">
                <td width="4%" class="report_list_one_row">&nbsp;</td>
                <td align="left" class="report_list_one_row"><a onclick="javascript:filter('T:auto');" title="(Total Pass Fail Block N/A)">&nbsp;&nbsp;$total_auto</a></td>
                <td class="report_list_one_row"></td>
              </tr>
              <tr id="background_T:manual" class="navigation_focus">
                <td width="4%" class="report_list_one_row">&nbsp;</td>
                <td align="left" class="report_list_one_row"><a onclick="javascript:filter('T:manual');" title="(Total Pass Fail Block N/A)">&nbsp;&nbsp;$total_manual</a></td>
                <td class="report_list_one_row"></td>
              </tr>
DATA
	@package_list = updatePackageList($time);
	foreach (@package_list) {
		my $package       = $_;
		my $auto_result   = $progress_bar_result{ $package . "_auto" };
		my $manual_result = $progress_bar_result{ $package . "_manual" };
		print <<DATA;
              <tr id="background_P:$package">
                <td width="4%" class="report_list_one_row">&nbsp;</td>
                <td align="left" class="report_list_one_row"><a onclick="javascript:filter('P:$package');" class="navigation_normal_text">$package</a></td>
                <td class="report_list_one_row"></td>
              </tr>
              <tr id="background_T:auto_P:$package">
                <td width="4%" class="report_list_one_row">&nbsp;</td>
                <td align="left" class="report_list_one_row"><a onclick="javascript:filter('T:auto_P:$package');" title="(Total Pass Fail Block N/A)">&nbsp;&nbsp;$auto_result</a></td>
                <td class="report_list_one_row"><div id="progress_bar_auto_$package"></div></td>
              </tr>
              <tr id="background_T:manual_P:$package">
                <td width="4%" class="report_list_one_row">&nbsp;</td>
                <td align="left" class="report_list_one_row"><a onclick="javascript:filter('T:manual_P:$package');" title="(Total Pass Fail Block N/A)">&nbsp;&nbsp;$manual_result</a></td>
                <td class="report_list_one_row"><div id="progress_bar_$package"></div></td>
              </tr>
DATA
	}
	print <<DATA;
            </table></td>
          <td width="65%" valign="top" class="report_list_outside_right_bold"><table width="100%" border="0" cellspacing="0" cellpadding="0">
              <tr>
                <td width="100%"><div class="cmd_log_border">
                    <table width="100%" border="0" cellspacing="0" cellpadding="0">
                      <tr>
                        <td><table width="100%" border="1" cellpadding="0" cellspacing="0" class="table_normal" frame="below" rules="all">
                            <tr>
                              <td align="left" class="report_list_one_row">&nbsp;Manual execution for&nbsp;&nbsp;$time</td>
                            </tr>
                          </table></td>
                      </tr>
                      <tr>
                        <td><table width="100%" border="1" cellpadding="0" cellspacing="0" class="table_normal" frame="below" rules="all">
                            <tr>
                              <td rowspan="2" align="left" width="30%" class="report_list_outside_left_two">&nbsp;Name</td>
                              <td rowspan="2" align="left" width="30%" class="report_list_one_row">&nbsp;Description</td>
                              <td colspan="4" align="center" width="40%" class="report_list_outside_right">Result</td>
                            </tr>
                            <tr class="change_all_result" title="Attention! unsaved results will be lost, if you change them all">
                              <td class="report_list_outside_right">&nbsp;
                                <input id="pass_all_button" type="radio" name="radiobutton" onclick="javascript:passAll();" title="Set all cases' result to PASS">
                                P</td>
                              <td class="report_list_one_row">&nbsp;
                                <input id="fail_all_button" type="radio" name="radiobutton" onclick="javascript:failAll();" title="Set all cases' result to FAIL">
                                F</td>
                              <td class="report_list_one_row">&nbsp;
                                <input id="block_all_button" type="radio" name="radiobutton" onclick="javascript:blockAll();" title="Set all cases' result to BLOCK">
                                B</td>
                              <td class="report_list_one_row">&nbsp;
                                <input id="not_run_all_button" type="radio" name="radiobutton" onclick="javascript:notrunAll();" title="Set all cases' result to N/A">
                                N</td>
                            </tr>
                          </table></td>
                      </tr>
DATA

	# print auto case
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
				$suite =~ s/ /-/g;
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

				$id = "T:auto_P:" . $package . '_N:' . $name;
				my $id_radio = "T:auto__P:" . $package . '__N:' . $name;
				push( @case_id_list, $id );
				if ( $result eq "N/A" ) {
					print '<tr id="summary_case_' . $id . '">';
					print "\n";
				}
				else {
					print '<tr id="summary_case_' . $id
					  . '" style="display:none">';
					print "\n";
				}
				print <<DATA;
                        <td><table width="100%" border="1" cellpadding="0" cellspacing="0" frame="below" rules="all" class="table_normal">
                            <tr>
                              <td align="left" width="30%" class="report_list_outside_left cut_long_string_one_line" title="$name"><a onclick="javascript:show_case_detail('detailed_case_$name');">&nbsp;$name</a></td>
                              <td align="left" width="30%" class="report_list_one_row cut_long_string_one_line" title="$description">&nbsp;$description</td>
                              <td align="center" width="40%" class="report_list_outside_right"><table width="100%" border="0" cellpadding="0" cellspacing="0">
DATA
				if ( $result eq "PASS" ) {
					print <<DATA;
                                  <form>
                                  <tr>
                                    <td>&nbsp;
                                      <input id="pass__radio__$id_radio" type="radio" name="radiobutton" onclick="javascript:clearRadioAll();" value="PASS" checked>
                                      P</td>
                                    <td>&nbsp;
                                      <input id="fail__radio__$id_radio" type="radio" name="radiobutton" onclick="javascript:clearRadioAll();" value="FAIL">
                                      F</td>
                                    <td>&nbsp;
                                      <input id="block__radio__$id_radio" type="radio" name="radiobutton" onclick="javascript:clearRadioAll();" value="BLOCK">
                                      B</td>
                                    <td>&nbsp;
                                      <input id="not_run__radio__$id_radio" type="radio" name="radiobutton" onclick="javascript:clearRadioAll();" value="N/A">
                                      N</td>
                                  </tr>
                                  </form>
DATA
				}
				if ( $result eq "FAIL" ) {
					print <<DATA;
                                  <form>
                                  <tr>
                                    <td>&nbsp;
                                      <input id="pass__radio__$id_radio" type="radio" name="radiobutton" onclick="javascript:clearRadioAll();" value="PASS">
                                      P</td>
                                    <td>&nbsp;
                                      <input id="fail__radio__$id_radio" type="radio" name="radiobutton" onclick="javascript:clearRadioAll();" value="FAIL" checked>
                                      F</td>
                                    <td>&nbsp;
                                      <input id="block__radio__$id_radio" type="radio" name="radiobutton" onclick="javascript:clearRadioAll();" value="BLOCK">
                                      B</td>
                                    <td>&nbsp;
                                      <input id="not_run__radio__$id_radio" type="radio" name="radiobutton" onclick="javascript:clearRadioAll();" value="N/A">
                                      N</td>
                                  </tr>
                                  </form>
DATA
				}
				if ( $result eq "BLOCK" ) {
					print <<DATA;
                                  <form>
                                  <tr>
                                    <td>&nbsp;
                                      <input id="pass__radio__$id_radio" type="radio" name="radiobutton" onclick="javascript:clearRadioAll();" value="PASS">
                                      P</td>
                                    <td>&nbsp;
                                      <input id="fail__radio__$id_radio" type="radio" name="radiobutton" onclick="javascript:clearRadioAll();" value="FAIL">
                                      F</td>
                                    <td>&nbsp;
                                      <input id="block__radio__$id_radio" type="radio" name="radiobutton" onclick="javascript:clearRadioAll();" value="BLOCK" checked>
                                      B</td>
                                    <td>&nbsp;
                                      <input id="not_run__radio__$id_radio" type="radio" name="radiobutton" onclick="javascript:clearRadioAll();" value="N/A">
                                      N</td>
                                  </tr>
                                  </form>
DATA
				}
				if ( $result eq "N/A" ) {
					print <<DATA;
                                  <form>
                                  <tr>
                                    <td>&nbsp;
                                      <input id="pass__radio__$id_radio" type="radio" name="radiobutton" onclick="javascript:clearRadioAll();" value="PASS">
                                      P</td>
                                    <td>&nbsp;
                                      <input id="fail__radio__$id_radio" type="radio" name="radiobutton" onclick="javascript:clearRadioAll();" value="FAIL">
                                      F</td>
                                    <td>&nbsp;
                                      <input id="block__radio__$id_radio" type="radio" name="radiobutton" onclick="javascript:clearRadioAll();" value="BLOCK">
                                      B</td>
                                    <td>&nbsp;
                                      <input id="not_run__radio__$id_radio" type="radio" name="radiobutton" onclick="javascript:clearRadioAll();" value="N/A" checked>
                                      N</td>
                                  </tr>
                                  </form>
DATA
				}
				print <<DATA;
                                </table></td>
                            </tr>
                          </table></td>
                      </tr>
                      <tr id="detailed_case_$name" style="display:none">
                            <td height="30" colspan="3">
DATA
				printDetailedCaseInfo( $name, $execution_type, %caseInfo );
				print <<DATA;
                            </td>
                      </tr>
DATA
			}
		}

		# print manual case
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
				$suite =~ s/ /-/g;
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
			if (   ( $_ =~ /.*<\/testcase>.*/ )
				&& ( $isManual eq "TRUE" )
				&& ( defined( $manual_case_result{$name} ) ) )
			{
				$startCase = "FALSE";
				$isManual  = "FALSE";
				%caseInfo  = updateCaseInfo($xml);
				chomp( $result = $manual_case_result{$name} );
				$description = $caseInfo{"description"};

				$id = "T:manual_P:" . $package . '_N:' . $name;
				my $id_radio = "T:manual__P:" . $package . '__N:' . $name;
				push( @case_id_list, $id );
				my $id_textarea  = "textarea__P:" . $package . '__N:' . $name;
				my $id_bugnumber = "bugnumber__P:" . $package . '__N:' . $name;

				if ( $result eq "N/A" ) {
					print '<tr id="summary_case_' . $id . '">';
					print "\n";
				}
				else {
					print '<tr id="summary_case_' . $id
					  . '" style="display:none">';
					print "\n";
				}
				print <<DATA;
                        <td><table width="100%" border="1" cellpadding="0" cellspacing="0" frame="below" rules="all" class="table_normal">
                            <tr>
                              <td align="left" width="30%" class="report_list_outside_left cut_long_string_one_line" title="$name"><a onclick="javascript:show_case_detail('detailed_case_$name');">&nbsp;$name</a></td>
                              <td align="left" width="30%" class="report_list_one_row cut_long_string_one_line" title="$description">&nbsp;$description</td>
                              <td align="center" width="40%" class="report_list_outside_right"><table width="100%" border="0" cellpadding="0" cellspacing="0">
DATA
				if ( $result eq "PASS" ) {
					print <<DATA;
                                  <form>
                                  <tr>
                                    <td>&nbsp;
                                      <input id="pass__radio__$id_radio" type="radio" name="radiobutton" onclick="javascript:clearRadioAll();" value="PASS" checked>
                                      P</td>
                                    <td>&nbsp;
                                      <input id="fail__radio__$id_radio" type="radio" name="radiobutton" onclick="javascript:clearRadioAll();" value="FAIL">
                                      F</td>
                                    <td>&nbsp;
                                      <input id="block__radio__$id_radio" type="radio" name="radiobutton" onclick="javascript:clearRadioAll();" value="BLOCK">
                                      B</td>
                                    <td>&nbsp;
                                      <input id="not_run__radio__$id_radio" type="radio" name="radiobutton" onclick="javascript:clearRadioAll();" value="N/A">
                                      N</td>
                                  </tr>
                                  </form>
DATA
				}
				if ( $result eq "FAIL" ) {
					print <<DATA;
                                  <form>
                                  <tr>
                                    <td>&nbsp;
                                      <input id="pass__radio__$id_radio" type="radio" name="radiobutton" onclick="javascript:clearRadioAll();" value="PASS">
                                      P</td>
                                    <td>&nbsp;
                                      <input id="fail__radio__$id_radio" type="radio" name="radiobutton" onclick="javascript:clearRadioAll();" value="FAIL" checked>
                                      F</td>
                                    <td>&nbsp;
                                      <input id="block__radio__$id_radio" type="radio" name="radiobutton" onclick="javascript:clearRadioAll();" value="BLOCK">
                                      B</td>
                                    <td>&nbsp;
                                      <input id="not_run__radio__$id_radio" type="radio" name="radiobutton" onclick="javascript:clearRadioAll();" value="N/A">
                                      N</td>
                                  </tr>
                                  </form>
DATA
				}
				if ( $result eq "BLOCK" ) {
					print <<DATA;
                                  <form>
                                  <tr>
                                    <td>&nbsp;
                                      <input id="pass__radio__$id_radio" type="radio" name="radiobutton" onclick="javascript:clearRadioAll();" value="PASS">
                                      P</td>
                                    <td>&nbsp;
                                      <input id="fail__radio__$id_radio" type="radio" name="radiobutton" onclick="javascript:clearRadioAll();" value="FAIL">
                                      F</td>
                                    <td>&nbsp;
                                      <input id="block__radio__$id_radio" type="radio" name="radiobutton" onclick="javascript:clearRadioAll();" value="BLOCK" checked>
                                      B</td>
                                    <td>&nbsp;
                                      <input id="not_run__radio__$id_radio" type="radio" name="radiobutton" onclick="javascript:clearRadioAll();" value="N/A">
                                      N</td>
                                  </tr>
                                  </form>
DATA
				}
				if ( $result eq "N/A" ) {
					print <<DATA;
                                  <form>
                                  <tr>
                                    <td>&nbsp;
                                      <input id="pass__radio__$id_radio" type="radio" name="radiobutton" onclick="javascript:clearRadioAll();" value="PASS">
                                      P</td>
                                    <td>&nbsp;
                                      <input id="fail__radio__$id_radio" type="radio" name="radiobutton" onclick="javascript:clearRadioAll();" value="FAIL">
                                      F</td>
                                    <td>&nbsp;
                                      <input id="block__radio__$id_radio" type="radio" name="radiobutton" onclick="javascript:clearRadioAll();" value="BLOCK">
                                      B</td>
                                    <td>&nbsp;
                                      <input id="not_run__radio__$id_radio" type="radio" name="radiobutton" onclick="javascript:clearRadioAll();" value="N/A" checked>
                                      N</td>
                                  </tr>
                                  </form>
DATA
				}
				print <<DATA;
                                </table></td>
                            </tr>
                          </table></td>
                      </tr>
                      <tr id="detailed_case_$name" style="display:none">
                            <td height="30" colspan="3">
DATA
				printManualCaseInfo( $time, $id_textarea, $id_bugnumber,
					%caseInfo );
				print <<DATA;
                            </td>
                      </tr>
DATA
			}
		}
	}
	my $block_list_join = join( '::', @case_id_list );
	print <<DATA;
                        <div id="result" style="display:none">$block_list_join</div>
DATA
	print <<DATA;
                    </table>
                  </div></td>
              </tr>
              <tr>
                <td height="30"><table width="100%" height="100%" border="0" cellpadding="0" cellspacing="0">
                    <tr>
                      <td width="69%">&nbsp;</td>
                      <td width="5%" align="center" id="manual_exec_icon"></td>
                      <td width="26%"><table width="100%" height="100%" border="0" cellpadding="0" cellspacing="0">
                          <tr>
                            <td align="center"><input type="submit" id="button_save" name="button_save" title="Save modification of case results" value="Save" class="small_button" onclick="javascript:saveManual();"></td>
                            <td align="center"><input type="submit" id="button_finish" name="button_finish" value="Finish" title="Finish editing result, and go to report page" class="small_button" onclick="javascript:finishManual();"></td>
                          </tr>
                        </table></td>
                    </tr>
                  </table></td>
              </tr>
            </table></td>
        </tr>
      </table></td>
  </tr>
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
function filter(reg) {
	var page = document.getElementsByTagName("*");
	for ( var i = 0; i < page.length; i++) {
		var temp_id = page[i].id;
		if (temp_id.indexOf("case_") >= 0) {
			page[i].style.display = "none";
			document.getElementById("background_summary_case_").style.display = "";
			if ((temp_id.indexOf(reg) >= 0)) {
				page[i].style.display = "";
			}
		}
		if (temp_id.indexOf("background_") >= 0) {
			page[i].style.backgroundColor = "";
			page[i].className = "";
			var bg_reg = "background_" + reg;
			if (temp_id == bg_reg) {
				page[i].style.backgroundColor = "#B9BAB5";
			}
		}
		if (temp_id.indexOf("_all_button") >= 0) {
			page[i].checked = false;
		}
	}
}
// ]]>
</script>
DATA

	# print progress bar
	@package_list = updatePackageList($time);
	foreach (@package_list) {
		my $package = $_;
		if ( $progress_bar_result{ $package . "_manual_maxValue" } != 0 ) {
			my $max_value =
			  $progress_bar_result{ $package . "_manual_maxValue" };
			my $value = $progress_bar_result{ $package . "_manual_value" };
			print <<DATA;
<script language="javascript" type="text/javascript">
// <![CDATA[
var pb = new YAHOO.widget.ProgressBar().render('progress_bar_$package');
pb.set('minValue',0);
pb.set('maxValue',$max_value);
pb.set('width',40);
pb.set('height',6);
pb.set('value',0);

pb.set('anim',true);
var anim = pb.get('anim');
anim.duration = 1;
anim.method = YAHOO.util.Easing.easeBothStrong;

pb.set('value',$value);
// ]]>
</script>
DATA
		}
		if ( $progress_bar_result{ $package . "_auto_maxValue" } != 0 ) {
			my $max_value = $progress_bar_result{ $package . "_auto_maxValue" };
			my $value     = $progress_bar_result{ $package . "_auto_value" };
			print <<DATA;
<script language="javascript" type="text/javascript">
// <![CDATA[
var pb = new YAHOO.widget.ProgressBar().render('progress_bar_auto_$package');
pb.set('minValue',0);
pb.set('maxValue',$max_value);
pb.set('width',40);
pb.set('height',6);
pb.set('value',0);

pb.set('anim',true);
var anim = pb.get('anim');
anim.duration = 1;
anim.method = YAHOO.util.Easing.easeBothStrong;

pb.set('value',$value);
// ]]>
</script>
DATA
		}
	}
}
else {
	print "HTTP/1.0 200 OK" . CRLF;
	print "Content-type: text/html" . CRLF . CRLF;

	print_header( "$MTK_BRANCH Manager Main Page", "execute" );
	print show_error_dlg("Can't get attribute time");
}

print_footer("");

sub updateProgressBarResult {
	my ($time)    = @_;
	my $total_a   = 0;
	my $pass_a    = 0;
	my $fail_a    = 0;
	my $block_a   = 0;
	my $not_run_a = 0;
	my $total_m   = 0;
	my $pass_m    = 0;
	my $fail_m    = 0;
	my $block_m   = 0;
	my $not_run_m = 0;
	@package_list = updatePackageList($time);

	foreach (@package_list) {
		my $package = $_;

		my $result;
		my $total_auto     = 0;
		my $pass_auto      = 0;
		my $fail_auto      = 0;
		my $block_auto     = 0;
		my $not_run_auto   = 0;
		my $total_manual   = 0;
		my $pass_manual    = 0;
		my $fail_manual    = 0;
		my $block_manual   = 0;
		my $not_run_manual = 0;

		# parse auto result
		my $tests_xml_dir =
		  $result_dir_manager . $time . "/" . $package . "_tests.xml";
		open FILE, $tests_xml_dir or die $!;
		while (<FILE>) {
			if ( $_ =~ /execution_type="auto"/ ) {
				if ( $_ =~ /result="(.*?)"/ ) {
					$total_auto++;
					$result = $1;
					if ( $result eq "PASS" ) {
						$pass_auto++;
					}
					if ( $result eq "FAIL" ) {
						$fail_auto++;
					}
					if ( $result eq "BLOCK" ) {
						$block_auto++;
					}
					if ( $result eq "N/A" ) {
						$not_run_auto++;
					}
				}
			}
		}

		# parse manual result
		%manual_case_result = updateManualCaseResult( $time, $package );
		foreach ( keys %manual_case_result ) {
			chomp( $result = $manual_case_result{$_} );
			$total_manual++;
			if ( $result eq "PASS" ) {
				$pass_manual++;
			}
			if ( $result eq "FAIL" ) {
				$fail_manual++;
			}
			if ( $result eq "BLOCK" ) {
				$block_manual++;
			}
			if ( $result eq "N/A" ) {
				$not_run_manual++;
			}
		}
		$total_a   += $total_auto;
		$total_m   += $total_manual;
		$pass_a    += $pass_auto;
		$pass_m    += $pass_manual;
		$fail_a    += $fail_auto;
		$fail_m    += $fail_manual;
		$block_a   += $block_auto;
		$block_m   += $block_manual;
		$not_run_a += $not_run_auto;
		$not_run_m += $not_run_manual;

		my $auto_result_text;
		if ( $fail_auto > 0 ) {
			$auto_result_text =
			  '<span class=\'result_fail\'>Auto Test&nbsp;</span>';
		}
		elsif ( $block_auto > 0 ) {
			$auto_result_text =
			  '<span class=\'result_block\'>Auto Test&nbsp;</span>';
		}
		elsif ( $not_run_auto > 0 ) {
			$auto_result_text =
			  '<span class=\'result_not_run\'>Auto Test&nbsp;</span>';
		}
		else {
			$auto_result_text =
			  '<span class=\'result_pass\'>Auto Test&nbsp;</span>';
		}
		my $manual_result_text;
		if ( $fail_manual > 0 ) {
			$manual_result_text =
			  '<span class=\'result_fail\'>Manual Test&nbsp;</span>';
		}
		elsif ( $block_manual > 0 ) {
			$manual_result_text =
			  '<span class=\'result_block\'>Manual Test&nbsp;</span>';
		}
		elsif ( $not_run_manual > 0 ) {
			$manual_result_text =
			  '<span class=\'result_not_run\'>Manual Test&nbsp;</span>';
		}
		else {
			$manual_result_text =
			  '<span class=\'result_pass\'>Manual Test&nbsp;</span>';
		}
		my $auto_result =
		    $auto_result_text
		  . '<span class=\'navigation_normal_text\'>('
		  . $total_auto
		  . '</span> <span class=\'result_pass\'>'
		  . $pass_auto
		  . '</span> <span class=\'result_fail\'>'
		  . $fail_auto
		  . '</span> <span class=\'result_block\'>'
		  . $block_auto
		  . '</span> <span class=\'result_not_run\'>'
		  . $not_run_auto
		  . '</span><span class=\'navigation_normal_text\'>)</span>';
		my $manual_result =
		    $manual_result_text
		  . '<span class=\'navigation_normal_text\'>('
		  . $total_manual
		  . '</span> <span class=\'result_pass\'>'
		  . $pass_manual
		  . '</span> <span class=\'result_fail\'>'
		  . $fail_manual
		  . '</span> <span class=\'result_block\'>'
		  . $block_manual
		  . '</span> <span class=\'result_not_run\'>'
		  . $not_run_manual
		  . '</span><span class=\'navigation_normal_text\'>)</span>';
		$progress_bar_result{ $package . "_auto" }   = $auto_result;
		$progress_bar_result{ $package . "_manual" } = $manual_result;

		$progress_bar_result{ $package . "_manual_maxValue" } = $total_manual;
		$progress_bar_result{ $package . "_manual_value" } =
		  ( $pass_manual + $fail_manual + $block_manual );
		$progress_bar_result{ $package . "_auto_maxValue" } = $total_auto;
		$progress_bar_result{ $package . "_auto_value" } =
		  ( $pass_auto + $fail_auto + $block_auto );
	}
	my $total_auto_result_text;
	if ( $fail_a > 0 ) {
		$total_auto_result_text =
		  '<span class=\'result_fail\'>Auto Test&nbsp;</span>';
	}
	elsif ( $block_a > 0 ) {
		$total_auto_result_text =
		  '<span class=\'result_block\'>Auto Test&nbsp;</span>';
	}
	elsif ( $not_run_a > 0 ) {
		$total_auto_result_text =
		  '<span class=\'result_not_run\'>Auto Test&nbsp;</span>';
	}
	else {
		$total_auto_result_text =
		  '<span class=\'result_pass\'>Auto Test&nbsp;</span>';
	}
	my $total_manual_result_text;
	if ( $fail_m > 0 ) {
		$total_manual_result_text =
		  '<span class=\'result_fail\'>Manual Test&nbsp;</span>';
	}
	elsif ( $block_m > 0 ) {
		$total_manual_result_text =
		  '<span class=\'result_block\'>Manual Test&nbsp;</span>';
	}
	elsif ( $not_run_m > 0 ) {
		$total_manual_result_text =
		  '<span class=\'result_not_run\'>Manual Test&nbsp;</span>';
	}
	else {
		$total_manual_result_text =
		  '<span class=\'result_pass\'>Manual Test&nbsp;</span>';
	}
	my $total_auto =
	    $total_auto_result_text
	  . '<span class=\'navigation_normal_text\'>('
	  . $total_a
	  . '</span> <span class=\'result_pass\'>'
	  . $pass_a
	  . '</span> <span class=\'result_fail\'>'
	  . $fail_a
	  . '</span> <span class=\'result_block\'>'
	  . $block_a
	  . '</span> <span class=\'result_not_run\'>'
	  . $not_run_a
	  . '</span><span class=\'navigation_normal_text\'>)</span>';
	my $total_manual =
	    $total_manual_result_text
	  . '<span class=\'navigation_normal_text\'>('
	  . $total_m
	  . '</span> <span class=\'result_pass\'>'
	  . $pass_m
	  . '</span> <span class=\'result_fail\'>'
	  . $fail_m
	  . '</span> <span class=\'result_block\'>'
	  . $block_m
	  . '</span> <span class=\'result_not_run\'>'
	  . $not_run_m
	  . '</span><span class=\'navigation_normal_text\'>)</span>';
	$progress_bar_result{"total_auto"}   = $total_auto;
	$progress_bar_result{"total_manual"} = $total_manual;
}

