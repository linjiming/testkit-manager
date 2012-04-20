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
use Templates qw{$result_dir_manager $test_definition_dir};
use Data::Dumper;

my @package_list = ();
my %caseInfo;              #parse all info items from xml
my %manual_case_result;    #parse manual case result from txt file
my %progress_bar_result
  ;    #pares auto and manual case result to generate progress bar
my @block_list = ();    #store all manual case and give it a unique id

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
<table width="1280" border="0" cellspacing="0" cellpadding="0" class="report_list">
  <tr>
    <td height="50" background="images/report_top_button_background.png"><table width="100%" height="50" border="0" cellpadding="0" cellspacing="0">
        <tbody>
          <tr>
            <td width="25">&nbsp;</td>
            <td style="font-size:24px">Manual execution for&nbsp;&nbsp;$time</td>
            <td>&nbsp;</td>
          </tr>
        </tbody>
      </table></td>
  </tr>
  <tr>
    <td><table width="100%" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td width="480" valign="top" class="report_list_outside_left_bold"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="all">
              <tr>
                <td width="4%" height="50" class="report_list_one_row">&nbsp;</td>
                <td class="report_list_one_row"><a class="view_case_detail" onclick="javascript:filter('summary_case_');" style="color:#000000">Total</a></td>
                <td class="report_list_one_row"></td>
              </tr>
              <tr>
                <td width="4%" height="50" class="report_list_one_row">&nbsp;</td>
                <td class="report_list_one_row"><a class="view_case_detail" onclick="javascript:filter('T:auto');">&nbsp;&nbsp;$total_auto</a></td>
                <td class="report_list_one_row"></td>
              </tr>
              <tr>
                <td width="4%" height="50" class="report_list_one_row">&nbsp;</td>
                <td class="report_list_one_row"><a class="view_case_detail" onclick="javascript:filter('T:manual');">&nbsp;&nbsp;$total_manual</a></td>
                <td class="report_list_one_row"></td>
              </tr>
DATA
	@package_list = updatePackageList($time);
	foreach (@package_list) {
		my $package       = $_;
		my $auto_result   = $progress_bar_result{ $package . "_auto" };
		my $manual_result = $progress_bar_result{ $package . "_manual" };
		print <<DATA;
              <tr>
                <td width="4%" height="50" class="report_list_one_row">&nbsp;</td>
                <td class="report_list_one_row"><a class="view_case_detail" onclick="javascript:filter('P:$package');" style="color:#000000">$package</a></td>
                <td class="report_list_one_row"></td>
              </tr>
              <tr>
                <td width="4%" height="50" class="report_list_one_row">&nbsp;</td>
                <td class="report_list_one_row"><a class="view_case_detail" onclick="javascript:filter('T:auto_P:$package');">&nbsp;&nbsp;$auto_result</a></td>
                <td class="report_list_one_row"></td>
              </tr>
              <tr>
                <td width="4%" height="50" class="report_list_one_row">&nbsp;</td>
                <td class="report_list_one_row"><a class="view_case_detail" onclick="javascript:filter('T:manual_P:$package');">&nbsp;&nbsp;$manual_result</a></td>
                <td class="report_list_one_row"><div id="progress_bar_$package"></div></td>
              </tr>
DATA
	}
	print <<DATA;
            </table></td>
          <td width="800" valign="top" class="report_list_outside_right_bold"><table width="100%" border="0" cellspacing="0" cellpadding="0">
              <tr>
                <td width="100%"><div style="height:600px;overflow:auto;text-wrap:none;padding-top:1px;">
                    <table width="100%" border="0" cellspacing="0" cellpadding="0">
                      <tr>
                        <td height="50"><table width="100%" height="50" border="0" cellpadding="0" cellspacing="0" frame="bottom" rules="all">
                            <tr>
                              <td width="32%" class="report_list_outside_left">&nbsp;Name</td>
                              <td width="32%" class="report_list_one_row">&nbsp;Description</td>
                              <td width="36%" class="report_list_outside_right">&nbsp;Result</td>
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

				$id = "T:auto_P:" . $package . '_R:' . $result;
				print '<tr id="summary_case_' . $id . '" style="display:none">';
				print "\n";
				print <<DATA;
                        <td height="50"><table width="100%" height="50" border="0" cellpadding="0" cellspacing="0" frame="bottom" rules="all" style="table-layout:fixed">
                            <tr>
                              <td width="32%" class="report_list_outside_left" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$name"><a class="view_case_detail" onclick="javascript:show_case_detail('detailed_case_$name');">&nbsp;$name</a></td>
                              <td width="32%" class="report_list_one_row" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$description">&nbsp;$description</td>
                              <td width="36%" class="report_list_outside_right"><table width="100%" height="50" border="0" cellpadding="0" cellspacing="0">
DATA
				if ( $result eq "PASS" ) {
					print <<DATA;
                                  <form>
                                  <tr>
                                    <td>&nbsp;
                                      <input type="radio" name="radiobutton" value="radiobutton" checked>
                                      PASS</td>
                                    <td>&nbsp;
                                      <input type="radio" name="radiobutton" value="radiobutton" disabled="disabled">
                                      FAIL</td>
                                    <td>&nbsp;
                                      <input type="radio" name="radiobutton" value="radiobutton" disabled="disabled">
                                      N/A</td>
                                  </tr>
                                  </form>
DATA
				}
				if ( $result eq "FAIL" ) {
					print <<DATA;
                                  <form>
                                  <tr>
                                    <td>&nbsp;
                                      <input type="radio" name="radiobutton" value="radiobutton" disabled="disabled">
                                      PASS</td>
                                    <td>&nbsp;
                                      <input type="radio" name="radiobutton" value="radiobutton" checked>
                                      FAIL</td>
                                    <td>&nbsp;
                                      <input type="radio" name="radiobutton" value="radiobutton" disabled="disabled">
                                      N/A</td>
                                  </tr>
                                  </form>
DATA
				}
				if ( $result eq "N/A" ) {
					print <<DATA;
                                  <form>
                                  <tr>
                                    <td>&nbsp;
                                      <input type="radio" name="radiobutton" value="radiobutton" disabled="disabled">
                                      PASS</td>
                                    <td>&nbsp;
                                      <input type="radio" name="radiobutton" value="radiobutton" disabled="disabled">
                                      FAIL</td>
                                    <td>&nbsp;
                                      <input type="radio" name="radiobutton" value="radiobutton" checked>
                                      N/A</td>
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
                            <td height="50" colspan="3">
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
		my $isManual          = "FALSE";
		my $def_tests_xml_dir = $test_definition_dir . $package . "/tests.xml";
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
				chomp( $result = $manual_case_result{$name} );
				$description = $caseInfo{"description"};

				$id = "T:manual_P:" . $package . '_R:' . $result;
				my $id_radio     = "P:" . $package . '__N:' . $name;
				my $id_textarea  = "textarea__P:" . $package . '__N:' . $name;
				my $id_bugnumber = "bugnumber__P:" . $package . '__N:' . $name;

				if ( $result eq "N/A" ) {
					push( @block_list, $id_radio );
					print '<tr id="summary_case_' . $id . '">';
					print "\n";
				}
				else {
					print '<tr id="summary_case_' . $id
					  . '" style="display:none">';
					print "\n";
				}
				print <<DATA;
                        <td height="50"><table width="100%" height="50" border="0" cellpadding="0" cellspacing="0" frame="bottom" rules="all" style="table-layout:fixed">
                            <tr>
                              <td width="32%" class="report_list_outside_left" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$name"><a class="view_case_detail" onclick="javascript:show_case_detail('detailed_case_$name');">&nbsp;$name</a></td>
                              <td width="32%" class="report_list_one_row" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$description">&nbsp;$description</td>
                              <td width="36%" class="report_list_outside_right"><table width="100%" height="50" border="0" cellpadding="0" cellspacing="0">
DATA
				if ( $result eq "PASS" ) {
					print <<DATA;
                                  <form>
                                  <tr>
                                    <td>&nbsp;
                                      <input id="pass__radio__$id_radio" type="radio" name="radiobutton" value="PASS" checked>
                                      PASS</td>
                                    <td>&nbsp;
                                      <input id="fail__radio__$id_radio" type="radio" name="radiobutton" value="FAIL" disabled="disabled">
                                      FAIL</td>
                                    <td>&nbsp;
                                      <input id="block__radio__$id_radio" type="radio" name="radiobutton" value="N/A" disabled="disabled">
                                      N/A</td>
                                  </tr>
                                  </form>
DATA
				}
				if ( $result eq "FAIL" ) {
					print <<DATA;
                                  <form>
                                  <tr>
                                    <td>&nbsp;
                                      <input id="pass__radio__$id_radio" type="radio" name="radiobutton" value="PASS" disabled="disabled">
                                      PASS</td>
                                    <td>&nbsp;
                                      <input id="fail__radio__$id_radio" type="radio" name="radiobutton" value="FAIL" checked>
                                      FAIL</td>
                                    <td>&nbsp;
                                      <input id="block__radio__$id_radio" type="radio" name="radiobutton" value="N/A" disabled="disabled">
                                      N/A</td>
                                  </tr>
                                  </form>
DATA
				}
				if ( $result eq "N/A" ) {
					print <<DATA;
                                  <form>
                                  <tr>
                                    <td>&nbsp;
                                      <input id="pass__radio__$id_radio" type="radio" name="radiobutton" value="PASS">
                                      PASS</td>
                                    <td>&nbsp;
                                      <input id="fail__radio__$id_radio" type="radio" name="radiobutton" value="FAIL">
                                      FAIL</td>
                                    <td>&nbsp;
                                      <input id="block__radio__$id_radio" type="radio" name="radiobutton" value="N/A" checked>
                                      N/A</td>
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
                            <td height="50" colspan="3">
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
	my $block_list_join = join( '::', @block_list );
	print <<DATA;
                        <div id="result" style="display:none">$block_list_join</div>
DATA
	print <<DATA;
                    </table>
                  </div></td>
              </tr>
              <tr>
                <td height="50"><table width="100%" height="50" border="0" cellpadding="0" cellspacing="0">
                    <tr>
                      <td width="32%"><table width="100%" height="50" border="0" cellpadding="0" cellspacing="0">
                          <tr>
                            <td align="center"><input type="submit" name="button_save" value="SAVE" class="bottom_button" onclick="javascript:saveManual();"></td>
                            <td align="center"><input type="submit" name="button_finish" value="FINISH" class="bottom_button" onclick="javascript:finishManual();"></td>
                          </tr>
                        </table></td>
                      <td width="32%">&nbsp;</td>
                      <td width="36%"><table width="100%" height="50" border="0" cellpadding="0" cellspacing="0">
                          <tr>
                            <td align="center"><input type="submit" name="button_pass" value="PASS" class="bottom_button" onclick="javascript:passAll();"></td>
                            <td align="center"><input type="submit" name="button_fail" value="FAIL" class="bottom_button" onclick="javascript:failAll();"></td>
                            <td align="center"><input type="submit" name="button_block" value="N/A" class="bottom_button" onclick="javascript:blockAll();"></td>
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
<script type="text/javascript" src="run_tests.js"></script>
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
	var page = document.all;
	for ( var i = 0; i < page.length; i++) {
		var temp_id = page[i].id;
		if (temp_id.indexOf("case_") >= 0) {
			page[i].style.display = "none";
			if ((temp_id.indexOf(reg) >= 0)) {
				page[i].style.display = "";
			}
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
		if ( $progress_bar_result{ $package . "_have_progress_bar" } eq "TRUE" )
		{
			my $max_value = $progress_bar_result{ $package . "_maxValue" };
			my $value     = $progress_bar_result{ $package . "_value" };
			print <<DATA;
<script language="javascript" type="text/javascript">
// <![CDATA[
var pb = new YAHOO.widget.ProgressBar().render('progress_bar_$package');
pb.set('minValue',0);
pb.set('maxValue',$max_value);
pb.set('width',180);
pb.set('height',10);
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
	my ($time)  = @_;
	my $total_a = 0;
	my $pass_a  = 0;
	my $fail_a  = 0;
	my $block_a = 0;
	my $total_m = 0;
	my $pass_m  = 0;
	my $fail_m  = 0;
	my $block_m = 0;
	@package_list = updatePackageList($time);

	foreach (@package_list) {
		my $package = $_;

		my $result;
		my $total_auto   = 0;
		my $pass_auto    = 0;
		my $fail_auto    = 0;
		my $block_auto   = 0;
		my $total_manual = 0;
		my $pass_manual  = 0;
		my $fail_manual  = 0;
		my $block_manual = 0;

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
					if ( $result eq "N/A" ) {
						$block_auto++;
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
			if ( $result eq "N/A" ) {
				$block_manual++;
			}
		}
		$total_a += $total_auto;
		$total_m += $total_manual;
		$pass_a  += $pass_auto;
		$pass_m  += $pass_manual;
		$fail_a  += $fail_auto;
		$fail_m  += $fail_manual;
		$block_a += $block_auto;
		$block_m += $block_manual;

		my $auto_result_text;
		if ( $fail_auto > 0 ) {
			$auto_result_text = '<span class=\'result_fail\'>Auto Test</span>';
		}
		elsif ( $block_auto > 0 ) {
			$auto_result_text =
			  '<span class=\'result_not_run\'>Auto Test</span>';
		}
		else {
			$auto_result_text = '<span class=\'result_pass\'>Auto Test</span>';
		}
		my $manual_result_text;
		if ( $fail_manual > 0 ) {
			$manual_result_text =
			  '<span class=\'result_fail\'>Manual Test</span>';
		}
		elsif ( $block_manual > 0 ) {
			$manual_result_text =
			  '<span class=\'result_not_run\'>Manual Test</span>';
		}
		else {
			$manual_result_text =
			  '<span class=\'result_pass\'>Manual Test</span>';
		}
		my $auto_result =
		    $auto_result_text
		  . '<span style="color:#000000">('
		  . $total_auto
		  . '</span> <span class=\'result_pass\'>'
		  . $pass_auto
		  . '</span> <span class=\'result_fail\'>'
		  . $fail_auto
		  . '</span> <span class=\'result_not_run\'>'
		  . $block_auto
		  . '</span><span style="color:#000000">)</span>';
		my $manual_result =
		    $manual_result_text
		  . '<span style="color:#000000">('
		  . $total_manual
		  . '</span> <span class=\'result_pass\'>'
		  . $pass_manual
		  . '</span> <span class=\'result_fail\'>'
		  . $fail_manual
		  . '</span> <span class=\'result_not_run\'>'
		  . $block_manual
		  . '</span><span style="color:#000000">)</span>';
		$progress_bar_result{ $package . "_auto" }   = $auto_result;
		$progress_bar_result{ $package . "_manual" } = $manual_result;

		$progress_bar_result{ $package . "_maxValue" } = $total_manual;
		$progress_bar_result{ $package . "_value" } =
		  ( $pass_manual + $fail_manual );
		if ( $total_manual > 0 ) {
			$progress_bar_result{ $package . "_have_progress_bar" } = "TRUE";
		}
		else {
			$progress_bar_result{ $package . "_have_progress_bar" } = "FALSE";
		}
	}
	my $total_auto_result_text;
	if ( $fail_a > 0 ) {
		$total_auto_result_text =
		  '<span class=\'result_fail\'>Auto Test</span>';
	}
	elsif ( $block_a > 0 ) {
		$total_auto_result_text =
		  '<span class=\'result_not_run\'>Auto Test</span>';
	}
	else {
		$total_auto_result_text =
		  '<span class=\'result_pass\'>Auto Test</span>';
	}
	my $total_manual_result_text;
	if ( $fail_m > 0 ) {
		$total_manual_result_text =
		  '<span class=\'result_fail\'>Manual Test</span>';
	}
	elsif ( $block_m > 0 ) {
		$total_manual_result_text =
		  '<span class=\'result_not_run\'>Manual Test</span>';
	}
	else {
		$total_manual_result_text =
		  '<span class=\'result_pass\'>Manual Test</span>';
	}
	my $total_auto =
	    $total_auto_result_text
	  . '<span style="color:#000000">('
	  . $total_a
	  . '</span> <span class=\'result_pass\'>'
	  . $pass_a
	  . '</span> <span class=\'result_fail\'>'
	  . $fail_a
	  . '</span> <span class=\'result_not_run\'>'
	  . $block_a
	  . '</span><span style="color:#000000">)</span>';
	my $total_manual =
	    $total_manual_result_text
	  . '<span style="color:#000000">('
	  . $total_m
	  . '</span> <span class=\'result_pass\'>'
	  . $pass_m
	  . '</span> <span class=\'result_fail\'>'
	  . $fail_m
	  . '</span> <span class=\'result_not_run\'>'
	  . $block_m
	  . '</span><span style="color:#000000">)</span>';
	$progress_bar_result{"total_auto"}   = $total_auto;
	$progress_bar_result{"total_manual"} = $total_manual;
}

