#!/usr/bin/perl -w

# Distribution Checker
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
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
#
#   Changlog:
#			07/16/2010, 
#			Move the JavaScript codes to a JS-format file 'run_test.js' by Tang, Shao-Feng  <shaofeng.tang@intel.com>.
#			Remove the user-profile related codes.
#

use Templates;
use TestStatus;

my $js_init = '';
if ($_GET{'profile'}) {
        # Start tests via AJAX
        $js_init = "startTests('$_GET{'profile'}');\n";
}
else {
        my $status = read_status();
        if ($status->{'IS_RUNNING'}) {
                $js_init = "startRefresh();\n";
        }
}

print "HTTP/1.0 200 OK" . CRLF;
print "Content-type: text/html" . CRLF . CRLF;

print_header('Test Execution Console Page', 'exec');

print <<DATA;
      <div id="ajax_loading" style="display: none;"></div>
      <table cellpadding="0" cellspacing="0" width="1020" height="26" id="table94" > <!-- MSTableType="layout" --> 
		<tr>
			<td height="1">
				<img alt="" width="1" height="1" src="images/MsSpacer.gif">
			</td>
		</tr>
		<tr>
			<td width="1">
				<img alt="" width="1" height="1" src="images/MsSpacer.gif">
			</td>
			<td valign="middle" width="516" height="26"> 
				<table cellpadding="0" cellspacing="0" border="0" width="100%" height="100%"> 
				<!-- MSCellFormattingTableID="2" --> 
				<tr>
					<td valign="middle" bgcolor="#333333" height="100%"> 
						<!-- MSCellFormattingType="content" --> 
						<font size="1" face="Arial" color="#FFFFFF">&nbsp; PLEASE SELECT TEST PROFILE </font>
						<font color="#FFFFFF"> 
DATA

my $found = 0;
my $profiles_list = '';
my $app = $SERVER_PARAM{'APP_DATA'};
if (opendir(DIR, $SERVER_PARAM{'APP_DATA'}.'/profiles/test')) {
        
        my @files = sort grep !/^[\.~]/, readdir(DIR);
        $found = scalar(@files);
        foreach (@files) {
                if ($_GET{'profile'} and ($_GET{'profile'} eq $_)) {
                        $profiles_list .= "    <option value=\"$_\" selected=\"selected\">$_</option>\n";
                }
                else {
                        $profiles_list .= "    <option value=\"$_\">$_</option>\n";
                }
        }
        my $app_data = $SERVER_PARAM{'APP_DATA'};
        closedir(DIR);
}

if ($found) {
        print <<DATA;
  <select name="test_profile" id="test_profile" style="width: 12em;">$profiles_list</select>
  <input type="button" name="START" id="start_button" value="Start" style="width: 6em;" onclick="javascript:startTests('');" />
  <input type="button" name="STOP" id="stop_button" value="Stop" style="width: 6em;" onclick="javascript:stopTests();" disabled="disabled" />
DATA
}
else {
        print <<DATA;
  <select name="test_profile_no" id="test_profile_no" style="width: 12em;" size="1" disabled="disabled"><option>&lt;No profiles present&gt;</option></select>
  <input type="button" name="START" id="start_button_no" value="Start" style="width: 6em;" disabled="disabled" />
  <input type="button" name="STOP" id="stop_button" value="Stop" style="width: 6em;" onclick="javascript:stopTests();" disabled="disabled" />
DATA
}
      
print <<DATA;
</font></td> </tr> <tr> <td bgcolor="#FFFFFF" height="1" width="100%"> <img alt="" width="1" height="1" src="MsSpacer.gif"></td> </tr> </table> </td> <td valign="middle" width="421" height="26"> <table cellpadding="0" cellspacing="0" border="0" width="100%" height="100%"> <!-- MSCellFormattingTableID="7" --> <tr> <td valign="middle" bgcolor="#333333" height="100%"> <!-- MSCellFormattingType="content" --></td> </tr> <tr> <td bgcolor="#FFFFFF" height="1" width="100%"> <img alt="" width="1" height="1" src="MsSpacer.gif"></td> </tr> </table> </td> <td valign="middle" height="26" width="83"> <table cellpadding="0" cellspacing="0" border="0" width="100%" height="100%"> <!-- MSCellFormattingTableID="6" --> <tr> <td valign="middle" bgcolor="#333333" height="100%"> <!-- MSCellFormattingType="content" --></td> </tr> <tr> <td bgcolor="#FFFFFF" height="1" width="100%"> <img alt="" width="1" height="1" src="MsSpacer.gif"></td> </tr> </table> </td> </tr> </table> <table cellpadding="0" cellspacing="0" id="table95" width="1020" height="494"> <!-- MSTableType="layout" -->
				<tr>
					<td valign="top" height="494" width="1020">
					<table cellpadding="0" cellspacing="0" border="0" width="100%" height="100%" id="table96">
						<!-- MSCellFormattingTableID="36" -->
						<tr>
							<td valign="top" width="100%" height="100%">
							<!-- MSCellFormattingType="content" -->
							<table cellpadding="0" cellspacing="0" width="1019" height="494">
								<!-- MSTableType="layout" -->
								<!-- tr>
									<td height="72" valign="top">
									<table cellpadding="0" cellspacing="0" border="0" width="100%" height="100%">
										
										<tr>
											<td bgcolor="#808080" colspan="3" height="1">
											<img alt="" width="1" height="1" src="MsSpacer.gif"></td>
										</tr>
										<tr>
											<td bgcolor="#808080" width="1">
											<img alt="" width="1" height="1" src="MsSpacer.gif"></td>
											<td valign="top" width="100%" bgcolor="#E8E8E8">
	
											<table border="0" width="100%" id="table472" height="43">
												<tr>
													<td width="116"></td>
													<td>
													<table cellpadding="0" cellspacing="0" width="1000" height="20">
														
														<tr>
															<td valign="middle" align="center" width="20%">
															<font size="1" face="Arial" color="#333333">
															AUTO CASE EXECUTION 
															PROGRESS</font>
                                                                                                                        </td>
															<td valign="middle" width="5%" height="20">
															<div id="percent" style="text-align: center;color: #C5291A;">0%</div>
                                                                                                                        </td>

															<td valign="top" height="20" width="75%">
                                                                                                                        <div style="width:65%;height: 100%"> 
															<div id="progress_bar" align="left" style="background-color: #C5291A;width:0%;height: 100%"></div></div>
															</td>
														</tr>
													</table>
													</td>
													<td width="114"></td>
												</tr>
											</table>
											</td>
											<td bgcolor="#808080" height="100%" width="1">
											<img alt="" width="1" height="1" src="MsSpacer.gif"></td>
										</tr>
									</table>
									</td>
								</tr   -->
								<tr>
									<td height="422" valign="top" width="1019">
									<table cellpadding="0" cellspacing="0" border="0" width="100%" height="100%">
										<!-- MSCellFormattingTableID="10" -->
										<tr>
											<td bgcolor="#808080" colspan="3" height="1">
											<img alt="" width="1" height="1" src="MsSpacer.gif"></td>
										</tr>
										<tr>
											<td bgcolor="#808080" width="1">
											<img alt="" width="1" height="1" src="MsSpacer.gif"></td>
											<td valign="top" width="100%">
											<!-- MSCellFormattingType="content" -->
											<font size="1" face="Arial">
DATA

print <<DATA;
<br /><br />
<table border="0" cellpadding="0" cellspacing="0" style="width: 60em;"><tr><td align="left">
<b><font color="blue"><span id="exec_info">Nothing started</span></font>&nbsp;<span id="exec_status"></span></b> </td><td align="right">
</td></tr></table>


<pre id="cmdlog" style="height: 400px; width: 60em; overflow: auto; text-wrap: none; border: 1px solid black; background-color: black; color: lightgreen;">Execute output will go here&hellip;</pre>
<script type="text/javascript" src="run_tests.js"></script>
<script language="javascript" type="text/javascript">
// <![CDATA[
// Preload images for shadow, various icons, buttons, etc.

var cmdlog = document.getElementById('cmdlog');
var exec_status = document.getElementById('exec_status');
var exec_info = document.getElementById('exec_info');

if (!cmdlog || !exec_status || !exec_info )
        alert('Internal error: Cannot find essential form fields! JavaScript will not work correctly.\\nPlease, contact the authors.');

var start_button = document.getElementById('start_button');
var stop_button = document.getElementById('stop_button');
var test_profile = document.getElementById('test_profile');

var cmdlog_height;
if (navigator.appName.indexOf('Opera') != -1)
        cmdlog_height = cmdlog.style.pixelHeight;
else
        cmdlog_height = cmdlog.clientHeight;


var log_contents = '';
var last_line = '';

// AJAX
var refresh_delay = 1000;
timeout_show_progress = -1;
var timeout_var;
var test_timer_var;

var progress_table_present = false;
var re_x0d = new RegExp();
re_x0d.compile('^[^\\x0d]*\\x0d', 'g');

$js_init
</script>

DATA

print <<DATA;

											</font></td>
											<td bgcolor="#808080" height="100%" width="1">
											<img alt="" width="1" height="1" src="MsSpacer.gif"></td>
										</tr>
										<tr>
											<td bgcolor="#808080" colspan="3" height="1">
											<img alt="" width="1" height="1" src="MsSpacer.gif"></td>
										</tr>
									</table>
									</td>
								</tr>
							</table>
	</td>
							</tr>
					</table>
					</td>
				</tr>
			</table>
DATA


print_footer();
