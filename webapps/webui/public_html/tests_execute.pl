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
use Data::Dumper;

my $js_init                  = "";
my $global_profile_init      = "var global_profile_name = 'temp_plan';";
my $global_package_name_init = "var global_package_name = 'none';";
my $global_case_number_init  = "var global_case_number = 0;";
my $need_update_progress_bar = "var need_update_progress_bar = true;";
my $selected_profile         = "none";
my $have_progress_bar        = "TRUE";
my %profile_list;    #parse and save all information from profile files
my @progress_bar_max_value     = ();     #save all auto progress bar's max value
my @package_list               = ();     #save all the packages
my $have_testkit_lite          = "FALSE";
my $have_correct_testkit_lite  = "FALSE";
my $testkit_lite_status        = "FALSE";
my $testkit_lite_error_message = "none";

check_testkit_lite();

if ( $_GET{'profile'} ) {
	if ( ( $have_testkit_lite eq "TRUE" ) and ( $have_testkit_lite eq "TRUE" ) )
	{
		$js_init = "startTests('$_GET{'profile'}');\n";
	}
}
else {
	if ( ( $have_testkit_lite eq "TRUE" ) and ( $have_testkit_lite eq "TRUE" ) )
	{
		my $status = read_status();
		if ( $status->{'IS_RUNNING'} ) {
			my $TEST_PLAN       = ( $status->{'TEST_PLAN'}       or "" );
			my $CURRENT_PACKAGE = ( $status->{'CURRENT_PACKAGE'} or "none" );
			my $CURRENT_RUN_NUMBER = ( $status->{'CURRENT_RUN_NUMBER'} or 0 );
			$global_profile_init =
			  'var global_profile_name = "' . $TEST_PLAN . '";';
			$global_package_name_init =
			  'var global_package_name = "' . $CURRENT_PACKAGE . '";';
			$global_case_number_init =
			  'var global_case_number = ' . $CURRENT_RUN_NUMBER . ';';
			$need_update_progress_bar = "var need_update_progress_bar = false;";
			$js_init                  = "startRefresh('$TEST_PLAN');\n";
		}
	}
}

print "HTTP/1.0 200 OK" . CRLF;
print "Content-type: text/html" . CRLF . CRLF;

print_header( "$MTK_BRANCH Manager Main Page", "execute" );

if (   ( $have_testkit_lite eq "FALSE" )
	or ( $have_correct_testkit_lite eq "FALSE" ) )
{
	print show_error_dlg($testkit_lite_error_message);
}

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
<table width="768" border="0" cellspacing="0" cellpadding="0" class="report_list">
  <tr>
    <td height="30" class="top_button_bg"><table width="100%" height="30" border="0" cellpadding="0" cellspacing="0">
        <tbody>
          <tr>
            <td width="15">&nbsp;</td>
            <td width="252" style="font-size:14px">Test Plan
DATA
if ($found) {
	print <<DATA;
            <select name="test_profile" id="test_profile" style="width: 11em;" onchange="javascript:filter_progress_bar();">$profiles_list</select></td>
DATA
}
else {
	print <<DATA;
            <select name="test_profile_no" id="test_profile_no" style="width: 12em;" size="1" disabled="disabled"><option>&lt;no plans present&gt;</option></select></td>
DATA
}

if (    ( $have_testkit_lite eq "TRUE" )
	and ( $have_correct_testkit_lite eq "TRUE" ) )
{
	print <<DATA;
            <td width="6"><img src="images/environment-spacer.gif" alt="" width="6" height="1"></td>
            <td width="71"><input type="submit" name="START" id="start_button" title="Start testing" value="Start" class="bottom_button" onclick="javascript:startTests('');"></td>
            <td width="6"><img src="images/environment-spacer.gif" alt="" width="6" height="1"></td>
            <td width="71"><input type="submit" name="STOP" id="stop_button" title="Stop testing" value="Stop" disabled="disabled" class="bottom_button" onclick="javascript:stopTests();"></td>
DATA
}
else {
	print <<DATA;
            <td width="6"><img src="images/environment-spacer.gif" alt="" width="6" height="1"></td>
            <td width="71"><input type="submit" name="START" id="start_button" title="Start to test" value="Start" disabled="disabled" class="bottom_button" onclick="javascript:startTests('');"></td>
            <td width="6"><img src="images/environment-spacer.gif" alt="" width="6" height="1"></td>
            <td width="71"><input type="submit" name="STOP" id="stop_button" title="Stop testing" value="Stop" disabled="disabled" class="bottom_button" onclick="javascript:stopTests();"></td>
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
          <td width="288" valign="top" class="report_list_outside_left_bold">
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
	my $auto_text_id   = 'text_' . $profile_name . '_all';
	my $bar_id         = 'bar_' . $profile_name . '_all';
	my $progress_id    = 'text_progress_' . $profile_name . '_all';
	foreach (@package_number) {
		my @temp         = split( ":", $_ );
		my $package_name = $temp[0];
		my $auto         = $temp[1];
		my $manual       = $temp[2];
		$auto_all   = int($auto_all) + int($auto);
		$manual_all = int($manual_all) + int($manual);
	}
	push( @progress_bar_max_value,
		'bar_' . $profile_name . '_all' . '::' . $auto_all );
	print <<DATA;
            <table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="all">
              <tr>
                <td width="4%" height="30" class="report_list_one_row">&nbsp;</td>
                <td align="left" class="report_list_one_row">Total</td>
                <td class="report_list_one_row"></td>
              </tr>
              <tr>
                <td width="4%" height="30" class="report_list_one_row">&nbsp;</td>
                <td align="left" class="report_list_one_row">&nbsp;&nbsp;<span id="$auto_text_id">Auto Test&nbsp;</span><span id="$progress_id">($auto_all)</span></td>
                <td class="report_list_one_row"><div id="$bar_id"></div></td>
              </tr>
              <tr>
                <td width="4%" height="30" class="report_list_one_row">&nbsp;</td>
                <td align="left" class="report_list_one_row">&nbsp;&nbsp;Manual Test&nbsp;($manual_all)</td>
                <td class="report_list_one_row"></td>
              </tr>
DATA
	my @package_number_order = reverse(@package_number);
	foreach (@package_number_order) {
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
                <td width="4%" height="30" class="report_list_one_row">&nbsp;</td>
                <td align="left" class="report_list_one_row">$package_name</td>
                <td class="report_list_one_row"></td>
              </tr>
              <tr>
                <td width="4%" height="30" class="report_list_one_row">&nbsp;</td>
                <td align="left" class="report_list_one_row">&nbsp;&nbsp;<span id="$auto_text_id">Auto Test&nbsp;</span><span id="$progress_id">($auto)</span></td>
                <td align="left" class="report_list_one_row"><div id="$bar_id"></div></td>
              </tr>
              <tr>
                <td width="4%" height="30" class="report_list_one_row">&nbsp;</td>
                <td align="left" class="report_list_one_row">&nbsp;&nbsp;Manual Test&nbsp;($manual)</td>
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
          <td width="480" valign="top" class="report_list_outside_right_bold"><table width="100%" border="0" cellspacing="0" cellpadding="0">
              <tr>
                <td align="left" height="30">&nbsp;<span id="exec_info">Nothing started</span>&nbsp;<span id="exec_status"></span></td>
              </tr>
              <tr>
                <td align="left"><pre id="cmdlog" style="margin-top:0px;margin-bottom:4px; margin-left:4px; height:310px;width:450px;overflow:auto;text-wrap:none;border:1px solid #BCBCBC;background-color:white;color:black;font-family:Arial;font-size:10px;">Execute output will go here...</pre></td>
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
	var page = document.getElementsByTagName("*");
	for ( var i = 0; i < page.length; i++) {
		var temp_id = page[i].id;
		if (temp_id.indexOf("progress_bar_") >= 0) {
			page[i].style.display = "none";
			if (temp_id == "progress_bar_" + view) {
				page[i].style.display = "";
				global_profile_name = view;
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
$global_profile_init
$global_package_name_init
$global_case_number_init
$need_update_progress_bar
var package_list = new Array$package_list_array;
var progress_bar_max_value_list = new Array$progress_bar_max_value_list_array;
// ]]>
</script>
DATA

print_footer("");

sub check_testkit_lite {
	my @device = `sdb devices`;
	if ( $device[1] =~ /device/ ) {
		my $cmd          = "sdb shell 'rpm -qa | grep testkit-lite'";
		my $testkit_lite = `$cmd`;
		if ( $testkit_lite =~ /testkit-lite-(.*)-\d\.noarch/ ) {
			$have_testkit_lite = "TRUE";
			my $version = $1;
			if ( $version eq $MTK_VERSION ) {

				# everthing is fine here
				$have_correct_testkit_lite = "TRUE";
			}
			else {

				# have testkit-lite but version is not correct
				$have_correct_testkit_lite = "FALSE";
				install_testkit_lite();
			}
		}
		else {

			# don't have testkit-lite
			install_testkit_lite();
		}
	}
	else {
		$testkit_lite_error_message = "Can't find a connected device";
	}
}

sub install_testkit_lite {
	my $check_network = check_network();
	if ( $check_network =~ /OK/ ) {
		my $repo      = get_repo();
		my @repo_all  = split( "::", $repo );
		my $repo_type = $repo_all[0];
		my $repo_url  = $repo_all[1];
		my $GREP_PATH = $repo_url;
		$GREP_PATH =~ s/\:/\\:/g;
		$GREP_PATH =~ s/\//\\\//g;
		$GREP_PATH =~ s/\./\\\./g;
		$GREP_PATH =~ s/\-/\\\-/g;

		my $cmd = "";
		if ( $repo_type =~ /remote/ ) {
			$cmd =
			    "wget -r -l 1 -nd -A rpm --spider "
			  . $repo_url
			  . " 2>&1 | grep $GREP_PATH"
			  . "testkit-lite.*.noarch.rpm";
		}
		if ( $repo_type =~ /local/ ) {
			$cmd = "find "
			  . $repo_url
			  . " | grep $GREP_PATH"
			  . "testkit-lite.*.noarch.rpm";
		}
		my $network_result = `$cmd`;
		if (
			$network_result =~ /$GREP_PATH.*testkit-lite-(.*)-(\d).noarch.rpm/ )
		{
			my $main_version = $1;
			my $sub_version  = $2;
			if ( $main_version eq $MTK_VERSION ) {
				if ( $have_testkit_lite eq "TRUE" ) {
					system("sdb shell rpm -e testkit-lite &>/dev/null");
				}
				if ( $repo_type =~ /remote/ ) {
					system( "wget -c $repo_url"
						  . "testkit-lite-$main_version-$sub_version.noarch.rpm -P /tmp -q -N"
					);
					system(
"sdb push /tmp/testkit-lite-$main_version-$sub_version.noarch.rpm /tmp &>/dev/null"
					);
				}
				if ( $repo_type =~ /local/ ) {
					system( "sdb push $repo_url"
						  . "testkit-lite-$main_version-$sub_version.noarch.rpm /tmp &>/dev/null"
					);
				}
				system( "sdb shell 'rpm -ivh /tmp/"
					  . "testkit-lite-$main_version-$sub_version.noarch.rpm --nodeps"
					  . "' 2>&1 >/dev/null" );
				my $cmd          = "sdb shell 'rpm -qa | grep testkit-lite'";
				my $testkit_lite = `$cmd`;
				if ( $testkit_lite =~ /testkit-lite-(.*)-\d\.noarch/ ) {
					$have_testkit_lite = "TRUE";
					my $version = $1;
					if ( $version eq $MTK_VERSION ) {
						$have_correct_testkit_lite = "TRUE";
					}
				}
				if (   ( $have_testkit_lite eq "FALSE" )
					or ( $have_correct_testkit_lite eq "FALSE" ) )
				{
					$testkit_lite_error_message =
"testkit-lite-$1-$2.noarch.rpm is find in the repo, however we failed to install it, please try manually";
				}
			}
			else {
				$testkit_lite_error_message =
"Only find testkit-lite-$1-$2.noarch.rpm in the repo, please install testkit-lite-$MTK_VERSION-x.noarch.rpm manually";
			}
		}
		else {
			$testkit_lite_error_message =
"Can't find testkit-lite in the repo, please install testkit-lite-$MTK_VERSION-x.noarch.rpm manually";
		}
	}
	else {
		$testkit_lite_error_message =
"Can't connect to the repo, please install testkit-lite-$MTK_VERSION-x.noarch.rpm manually";
	}
}

