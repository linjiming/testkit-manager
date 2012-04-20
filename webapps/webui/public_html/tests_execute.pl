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

use strict;
use Templates;
use TestStatus;

my $js_init = '';
if ( $_GET{'profile'} ) {

	# Start tests via AJAX
	$js_init = "startTests('$_GET{'profile'}');\n";
}
else {
	my $status = read_status();
	if ( $status->{'IS_RUNNING'} ) {
		$js_init = "startRefresh();\n";
	}
}

print "HTTP/1.0 200 OK" . CRLF;
print "Content-type: text/html" . CRLF . CRLF;

print_header( "$MTK_BRANCH Manager Main Page", "execute" );

my $found         = 0;
my $profiles_list = '';
my $app           = $SERVER_PARAM{'APP_DATA'};
if ( opendir( DIR, $SERVER_PARAM{'APP_DATA'} . '/profiles/test' ) ) {

	my @files = sort grep !/^[\.~]/, readdir(DIR);
	$found = scalar(@files);
	foreach (@files) {
		if ( $_GET{'profile'} and ( $_GET{'profile'} eq $_ ) ) {
			$profiles_list .=
			  "    <option value=\"$_\" selected=\"selected\">$_</option>\n";
		}
		else {
			$profiles_list .= "    <option value=\"$_\">$_</option>\n";
		}
	}
	my $app_data = $SERVER_PARAM{'APP_DATA'};
	closedir(DIR);
}

print <<DATA;
<div id="ajax_loading" style="display:none"></div>
<div id="message"></div>
<table width="1280" border="0" cellspacing="0" cellpadding="0" class="report_list">
  <tr>
    <td height="50" background="images/report_top_button_background.png"><table width="100%" height="50" border="0" cellpadding="0" cellspacing="0">
        <tbody>
          <tr>
            <td width="25">&nbsp;</td>
            <td width="420" style="font-size:24px">Profile name:
DATA
if ($found) {
	print <<DATA;
            <select name="test_profile" id="test_profile" style="width: 12em;">$profiles_list</select></td>
            <td width="10"><img src="images/environment-spacer.gif" alt="" width="10" height="1"></td>
            <td width="119"><input type="submit" name="START" id="start_button" value="Start Test" class="top_button" onclick="javascript:startTests('');"></td>
            <td width="10"><img src="images/environment-spacer.gif" alt="" width="10" height="1"></td>
            <td width="119"><input type="submit" name="STOP" id="stop_button" value="Stop Test" disabled="disabled" class="top_button" onclick="javascript:stopTests();"></td>
DATA
}
else {
	print <<DATA;
            <select name="test_profile_no" id="test_profile_no" style="width: 12em;" size="1" disabled="disabled"><option>&lt;No profiles present&gt;</option></select></td>
            <td width="10"><img src="images/environment-spacer.gif" alt="" width="10" height="1"></td>
            <td width="119"><input type="submit" name="START" id="start_button" value="Start Test" disabled="disabled" class="top_button" onclick="javascript:startTests('');"></td>
            <td width="10"><img src="images/environment-spacer.gif" alt="" width="10" height="1"></td>
            <td width="119"><input type="submit" name="STOP" id="stop_button" value="Stop Test" disabled="disabled" class="top_button" onclick="javascript:stopTests();"></td>
DATA
}
print <<DATA;
            <td>&nbsp;</td>
          </tr>
        </tbody>
      </table></td>
  </tr>
  <tr>
    <td><table width="100%" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td width="480" valign="top" class="report_list_outside_left_bold">&nbsp;&nbsp;Progress bar will go here...</td>
          <td width="800" valign="top" class="report_list_outside_right_bold"><table width="100%" border="0" cellspacing="0" cellpadding="0">
              <tr>
                <td height="50">&nbsp;<span id="exec_info">Nothing started</span>&nbsp;<span id="exec_status"></span></td>
              </tr>
              <tr>
                <td align="center"><pre align="left" id="cmdlog" style="margin-top:0px;margin-bottom:7px;height:500px;width:750px;overflow:auto;text-wrap:none;border:1px solid #BCBCBC;background-color:white;color:black;font-size:18px;">Execute output will go here...</pre></td>
              </tr>
            </table></td>
        </tr>
      </table></td>
  </tr>
</table>
<script type="text/javascript" src="run_tests.js"></script>
<script language="javascript" type="text/javascript">
// <![CDATA[
// Preload images for shadow, various icons, buttons, etc.
var cmdlog = document.getElementById('cmdlog');
var exec_status = document.getElementById('exec_status');
var exec_info = document.getElementById('exec_info');

if (!cmdlog || !exec_status || !exec_info) {
	alert('Internal error: Cannot find essential form fields! JavaScript will not work correctly.');
}

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
// ]]>
</script>
DATA

print_footer("");

