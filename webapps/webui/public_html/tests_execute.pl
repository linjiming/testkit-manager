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

my $js_init           = '';
my $selected_profile  = "none";
my $have_progress_bar = "TRUE";
my %profile_list;    #parse and save all information from profile files
my @progress_bar_max_value = ();    #save all auto progress bar's max value
my @package_list           = ();    #save all the packages

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
	my $have_selected = "FALSE";
	foreach (@files) {
		my $profile_name = $_;
		if ( $_GET{'profile'} and ( $_GET{'profile'} eq $profile_name ) ) {
			$selected_profile = $profile_name;
			$profiles_list .=
"    <option value=\"$profile_name\" selected=\"selected\">$profile_name</option>\n";
		}
		else {
			if ( ( $have_selected eq "FALSE" ) and !$_GET{'profile'} ) {
				$profiles_list .=
"    <option value=\"$profile_name\" selected=\"selected\">$profile_name</option>\n";
				$selected_profile = $profile_name;
				$have_selected    = "TRUE";
			}
			else {
				$profiles_list .=
"    <option value=\"$profile_name\">$profile_name</option>\n";
			}
		}
		open FILE, $SERVER_PARAM{'APP_DATA'} . '/profiles/test/' . $profile_name
		  or die "can't open " . $profile_name;
		my $theEnd = "False";
		my $package_name;
		my $auto_number;
		my $manual_number;
		while (<FILE>) {
			my $line = $_;
			$line =~ s/\n//g;
			if ( $line =~ /\[\/Auto\]/ ) {
				$theEnd = "True";
			}
			if ( $theEnd eq "False" ) {
				if ( $line !~ /Auto/ ) {
					if ( $line =~ /(.*)\((\d*) (\d*)\)/ ) {
						$package_name  = $1;
						$auto_number   = $2;
						$manual_number = $3;

						# push package into list
						my $have_one          = "FALSE";
						my @package_list_temp = @package_list;
						foreach (@package_list_temp) {
							if ( $_ eq $package_name ) {
								$have_one = "TRUE";
							}
						}
						if ( $have_one eq "FALSE" ) {
							push( @package_list, $package_name );
						}

						# push profile_name and case number into hash
						if ( defined $profile_list{$profile_name} ) {
							$profile_list{$profile_name} .= '__'
							  . $package_name . ':'
							  . $auto_number . ':'
							  . $manual_number;
						}
						else {
							$profile_list{$profile_name} =
							    $package_name . ':'
							  . $auto_number . ':'
							  . $manual_number;
						}
					}
				}
			}
			if ( $theEnd eq "True" ) {
				if ( $line =~ /select_exe=(.*)/ ) {
					if ( $1 eq "manual" ) {
						$have_progress_bar = "FALSE";
					}
				}
			}
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
            <select name="test_profile" id="test_profile" style="width: 12em;" onchange="javascript:filter_progress_bar();">$profiles_list</select></td>
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
          <td width="480" valign="top" class="report_list_outside_left_bold">
DATA
foreach ( keys %profile_list ) {
	my $profile_name = $_;
	if ( $selected_profile ne "none" ) {
		if ( $_ eq $selected_profile ) {
			print <<DATA;
	        <div id="progress_bar_$profile_name">
DATA
		}
		else {
			print <<DATA;
	        <div id="progress_bar_$profile_name" style="display:none">
DATA
		}
	}
	else {
		print <<DATA;
	        <div id="progress_bar_$profile_name" style="display:none">
DATA
	}
	my @package_number = split( "__", $profile_list{$profile_name} );
	my $auto_all       = 0;
	my $manual_all     = 0;
	foreach (@package_number) {
		my @temp         = split( ":", $_ );
		my $package_name = $temp[0];
		my $auto         = $temp[1];
		my $manual       = $temp[2];
		$auto_all   = int($auto_all) + int($auto);
		$manual_all = int($manual_all) + int($manual);
	}
	print <<DATA;
            <table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="all">
              <tr>
                <td width="4%" height="50" class="report_list_one_row">&nbsp;</td>
                <td align="left" class="report_list_one_row">Total</td>
                <td class="report_list_one_row"></td>
              </tr>
              <tr>
                <td width="4%" height="50" class="report_list_one_row">&nbsp;</td>
                <td align="left" class="report_list_one_row">&nbsp;&nbsp;Auto Test($auto_all)</td>
                <td class="report_list_one_row"></td>
              </tr>
              <tr>
                <td width="4%" height="50" class="report_list_one_row">&nbsp;</td>
                <td align="left" class="report_list_one_row">&nbsp;&nbsp;Manual Test($manual_all)</td>
                <td class="report_list_one_row"></td>
              </tr>
DATA

	foreach (@package_number) {
		my @temp         = split( ":", $_ );
		my $package_name = $temp[0];
		my $auto         = $temp[1];
		my $manual       = $temp[2];
		push( @progress_bar_max_value,
			'bar_' . $profile_name . '_' . $package_name . '::' . $auto );
		my $auto_text_id = 'text_' . $profile_name . '_' . $package_name;
		my $bar_id       = 'bar_' . $profile_name . '_' . $package_name;
		my $progress_id =
		  'text_progress_' . $profile_name . '_' . $package_name;
		print <<DATA;
              <tr>
                <td width="4%" height="50" class="report_list_one_row">&nbsp;</td>
                <td align="left" class="report_list_one_row">$package_name</td>
                <td class="report_list_one_row"></td>
              </tr>
              <tr>
                <td width="4%" height="50" class="report_list_one_row">&nbsp;</td>
                <td align="left" class="report_list_one_row">&nbsp;&nbsp;<span id="$auto_text_id">Auto Test</span><span id="$progress_id">($auto)</span></td>
                <td align="left" class="report_list_one_row"><div id="$bar_id"></div></td>
              </tr>
              <tr>
                <td width="4%" height="50" class="report_list_one_row">&nbsp;</td>
                <td align="left" class="report_list_one_row">&nbsp;&nbsp;Manual Test($manual)</td>
                <td class="report_list_one_row"></td>
              </tr>
DATA
	}
	print <<DATA;
            </table></div>
DATA
}
print <<DATA;
          </td>
          <td width="800" valign="top" class="report_list_outside_right_bold"><table width="100%" border="0" cellspacing="0" cellpadding="0">
              <tr>
                <td align="left" height="50">&nbsp;<span id="exec_info">Nothing started</span>&nbsp;<span id="exec_status"></span></td>
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
<script language="javascript" type="text/javascript">
// <![CDATA[
function filter_progress_bar() {
	var view = document.getElementById('test_profile').value;
	var page = document.all;
	for ( var i = 0; i < page.length; i++) {
		var temp_id = page[i].id;
		if (temp_id.indexOf("progress_bar_") >= 0) {
			page[i].style.display = "none";
			if (temp_id == "progress_bar_" + view) {
				page[i].style.display = "";
			}
		}
	}
}
// ]]>
</script>
DATA

my $package_list_array = join( '","', @package_list );
$package_list_array = '("' . $package_list_array . '")';
my $progress_bar_max_value_list_array = join( '","', @progress_bar_max_value );
$progress_bar_max_value_list_array =
  '("' . $progress_bar_max_value_list_array . '")';
print <<DATA;
<script language="javascript" type="text/javascript">
// <![CDATA[
var global_profile_name;
var global_package_name = "none";
var global_case_number = 0;
var package_list = new Array$package_list_array;
var progress_bar_max_value_list = new Array$progress_bar_max_value_list_array;
// ]]>
</script>
DATA

print_footer("");

