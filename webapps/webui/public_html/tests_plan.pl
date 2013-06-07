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

use strict;
use Templates;
use Data::Dumper;

my %name_number_version
  ;    # save package name, package case number, package version
my $testkit_lite_error_message =
  check_testkit_sdb();    # check if the device is ready

# check test plan dir
if ( !( -e $profile_dir_manager ) ) {
	system( 'mkdir ' . $profile_dir_manager );
}

# check name number version information
my $repo     = get_repo();
my @repo_all = split( "::", $repo );
my $repo_url = $repo_all[1];
if ( !( -e $repo_url . "package_list" ) ) {
	syncDefinition_from_local_repo();
}

# load name number version information
if ( open FILE, $repo_url . "package_list" ) {
	while (<FILE>) {
		my @name_info = split( "!::!", $_ );
		$name_number_version{ $name_info[0] } = $name_info[1];
	}
}

# load filter information
my $execution_type_filter = "        <option>Any Execution Type</option>";
$execution_type_filter .= "        <option>Automated</option>";
$execution_type_filter .= "        <option>Manual</option>";

# load existing test plans
my $test_plan_list = "        <option>Choose A Test Plan</option>";
if ( opendir( DIR, $SERVER_PARAM{'APP_DATA'} . '/plans' ) ) {
	my @files = sort grep !/^[\.~]/, readdir(DIR);
	foreach (@files) {
		my $test_plan_name = $_;
		if (    ( $test_plan_name !~ /pre_template/ )
			and ( $test_plan_name !~ /^rerun_/ ) )
		{
			$test_plan_list .=
"        <option value=\"$test_plan_name\">$test_plan_name</option>\n";
		}
	}
}

# return html and java script to the user
print "HTTP/1.0 200 OK" . CRLF;
print "Content-type: text/html" . CRLF . CRLF;
print_header( "$MTK_BRANCH Manager Plan Page", "plan" );
print show_error_dlg($testkit_lite_error_message);

# print hardware capability table
my %hardware_type              = read_hardware_capability_config();
my $hardware_dynamic_checklist = "";
my @keys_hardware_type         = qw/usbHost usbAccessory inputKeyboard/;
foreach ( sort keys %hardware_type ) {
	if ( $_ ne "usbHost" && $_ ne "usbAccessory" && $_ ne "inputKeyboard" ) {
		push( @keys_hardware_type, $_ );
	}

}

foreach (@keys_hardware_type) {
	my $hardware_name = $_;
	my $hardware_type = $hardware_type{$hardware_name};
	if ( $hardware_type eq "boolean" ) {
		$hardware_dynamic_checklist .= '<tr>'
		  . '<td width="4%" align="left" class="report_list_no_border">&nbsp;</td>'
		  . '<td width="4%" align="center" class="report_list_outside_left_no_height"><input type="checkbox" name="'
		  . $hardware_name
		  . "_checkbox"
		  . '" id="'
		  . $hardware_name
		  . "_checkbox"
		  . "\" onclick=\"javascript:check_hardware_checklist('"
		  . $hardware_name . "_"
		  . $hardware_type . "', '"
		  . $hardware_name
		  . "_checkbox"
		  . "');\" /></td>"
		  . '<td width="44%" align="left" class="report_list_outside_left_no_height">&nbsp;'
		  . $hardware_name . '</td>'
		  . '<td width="44%" align="center" class="custom_bottom" id="'
		  . $hardware_name . "_"
		  . $hardware_type
		  . '">No</td>'
		  . '<td width="0%" class="report_list_no_border"><input type="hidden" id="'
		  . $hardware_name
		  . "_message"
		  . '" name="'
		  . $hardware_name
		  . "_message"
		  . '" value="'
		  . $hardware_name . "_"
		  . $hardware_type
		  . '"></td>'
		  . '<td width="4%" align="left" class="report_list_no_border">&nbsp;</td>'
		  . '</tr>';
	}
	else {
		$hardware_dynamic_checklist .= '<tr>'
		  . '<td width="4%" align="left" class="report_list_no_border">&nbsp;</td>'
		  . '<td width="4%" align="center" class="report_list_outside_left_no_height"><input type="checkbox" name="'
		  . $hardware_name
		  . "_checkbox"
		  . '" id="'
		  . $hardware_name
		  . "_checkbox"
		  . "\" onclick=\"javascript:check_hardware_checklist('"
		  . $hardware_name . "_"
		  . $hardware_type . "', '"
		  . $hardware_name
		  . "_checkbox"
		  . "');\" /></td>"
		  . '<td width="44%" align="left" class="report_list_outside_left_no_height">&nbsp;'
		  . $hardware_name . '</td>'
		  . '<td width="44%" align="center" class="custom_bottom"><input type="text" name="'
		  . $hardware_name . "_"
		  . $hardware_type
		  . '" id="'
		  . $hardware_name . "_"
		  . $hardware_type
		  . '" class="test_plan_name" disabled="disabled" value="" /></td>'
		  . '<td width="0%" class="report_list_no_border"><input type="hidden" id="'
		  . $hardware_name
		  . "_message"
		  . '" name="'
		  . $hardware_name
		  . "_message"
		  . '" value="'
		  . $hardware_name . "_"
		  . $hardware_type
		  . '"></td>'
		  . '<td width="4%" align="left" class="report_list_no_border">&nbsp;</td>'
		  . '</tr>';
	}
}
my $hardware_capability_content = <<DATA;
<table width="660" border="1" cellspacing="0" cellpadding="0" class="report_list table_normal_small" rules="all" frame="void">
  <tr>
    <td width="4%" align="left" class="report_list_no_border">&nbsp;</td>
    <td width="4%" align="left" class="report_list_no_border">&nbsp;</td>
    <td width="44%" align="left" class="report_list_no_border">&nbsp;</td>
    <td width="44%" align="left" class="report_list_no_border">&nbsp;</td>
    <td width="0%" class="report_list_no_border"></td>
    <td width="4%" align="left" class="report_list_no_border">&nbsp;</td>
  </tr>
  <tr>
    <td width="4%" align="left" class="report_list_no_border">&nbsp;</td>
    <td colspan="4" align="left" class="custom_bottom"><input type="checkbox" id="change_all" onclick="javascript:change_all_status()">&nbsp;Hardware Capability Checklist</td>
    <td width="4%" align="left" class="report_list_no_border">&nbsp;</td>
  </tr>

  </tr>
  $hardware_dynamic_checklist
  <tr>
    <td width="4%" align="left" class="report_list_no_border">&nbsp;</td>
    <td width="4%" align="left" class="report_list_no_border">&nbsp;</td>
    <td width="44%" align="left" class="report_list_no_border">&nbsp;</td>
    <td width="44%" align="left" class="report_list_no_border">&nbsp;</td>
    <td width="0%" class="report_list_no_border"></td>
    <td width="4%" align="left" class="report_list_no_border">&nbsp;</td>
  </tr>
  <tr style="display:none">
    <td width="4%" align="left" class="report_list_no_border">&nbsp;</td>
    <td colspan="4" align="right" class="report_list_no_border">New test plan name:
      <input type="text" name="hardware_capability_plan" id="hardware_capability_plan" class="test_plan_name" /></td>
    <td width="4%" align="left" class="report_list_no_border">&nbsp;</td>
  </tr>
  <tr>
    <td width="4%" align="left" class="report_list_no_border">&nbsp;</td>
    <td colspan="4" align="right" class="report_list_no_border"><input type="submit" name="save_hardware_capability_checklist" id="save_hardware_capability_checklist" value="Confirm" class="small_button" onclick="javascript:onSaveHardwareCapability();" />
      &nbsp;
      <input type="submit" style="display:none" name="close_config_div" id="close_config_div"  value="Skip" class="small_button" onclick="javascript:onSkipHardwareCapability();" /></td>
    <td width="4%" align="left" class="report_list_no_border">&nbsp;</td>
  </tr>
</table>
DATA
$hardware_capability_content =~ s/\n//g;

# print test_plan and filter table
print <<DATA;
<div id="ajax_loading" style="display:none"></div>
<div id="preConfigDiv" class="report_list common_div pre_config_div"></div>
<div id="loadProgressBarDiv" class="report_list common_div load_progress_bar_Div"></div>
<div id="hardwareCapabilityDiv" class="report_list common_div hardware_capability_div" style="display:none">$hardware_capability_content</div>
<table width="768" border="0" cellspacing="0" cellpadding="0" class="plan_info_bar_bg table_normal">
  <tr>
    <td width="4%">&nbsp;</td>
    <td width="20%" align="left">&nbsp;Test Plan</td>
    <td width="38%" align="left"><select name="test_profile" id="test_profile" class="test_plan_name" onchange="javascript:load_test_plan();">
$test_plan_list
      </select></td>
    <td width="4%">&nbsp;</td>
    <td width="15%" align="left"><input type="button" name="execute_profile" id="execute_profile" class="medium_button" title="Execute selected packages" value="Run" onclick="javascript:run_test_plan();" /></td>
    <td width="15%" align="left"><input type="button" name="pre_config" id="pre_config" style="display:none" class="medium_button" title="Pre config some basic parameters for the device" value="Config" onclick="javascript:onPreConfig();" /></td>
    <td width="4%">&nbsp;</td>
  </tr>
  <tr>
    <td width="4%">&nbsp;</td>
    <td width="20%" align="left">&nbsp;Execution Type</td>
    <td width="38%" align="left"><select name="select_execution_type" id="select_execution_type" class="test_plan_name" onchange="javascript:filter_package('execution_type');">
$execution_type_filter
      </select></td>
    <td width="4%">&nbsp;</td>
    <td width="15%">&nbsp;</td>
    <td width="15%">&nbsp;</td>
    <td width="4%">&nbsp;</td>
  </tr>
  <tr style="display:none">
    <td width="4%">&nbsp;</td>
    <td width="20%" align="left">&nbsp;New Plan</td>
    <td width="38%" align="left"><input type="text" name="save_test_plan_text" id="save_test_plan_text" class="test_plan_name" /></td>
    <td width="4%">&nbsp;</td>
    <td width="15%" align="left"><input type="button" name="save_profile_button_text" id="save_profile_button_text" class="medium_button" title="Save test plan" value="Save" onclick="javascript:save_profile('text');" /></td>
    <td width="15%">&nbsp;</td>
    <td width="4%">&nbsp;</td>
  </tr>
</table>
DATA

# print package information table
print <<DATA;
<table width="768" border="0" cellspacing="0" cellpadding="0" frame="void" rules="all" class="report_list table_normal">
  <tr class="table_first_row">
    <td width="4%" align="center" class="custom_line_height report_list_outside_left_no_height"><input type="checkbox" name="checkbox_all" id="checkbox_all" value="checkbox_all" onclick="javascript:check_uncheck_all();" /></td>
    <td width="56%" class="custom_line_height report_list_outside_left_no_height">&nbsp;Package Name</td>
    <td width="11%" class="custom_line_height report_list_outside_left_no_height">&nbsp;Automated</td>
    <td width="8%" class="custom_line_height report_list_outside_left_no_height">&nbsp;Manual</td>
    <td width="8%" class="custom_line_height report_list_outside_left_no_height">&nbsp;Total</td>
    <td width="13%" class="custom_line_height report_list_outside_left_no_height">&nbsp;Version</td>
  </tr>
DATA
foreach ( sort keys %name_number_version ) {
	my $packageName    = $_;
	my @package_info   = split( "!:!", $name_number_version{$packageName} );
	my $autoNumber     = $package_info[0];
	my $manualNumber   = $package_info[1];
	my $totalNumber    = int($autoNumber) + int($manualNumber);
	my $packageVersion = $package_info[2];
	my $hasAuto        = "autonumber_0";
	if ( int($autoNumber) > 0 ) {
		$hasAuto = "autonumber_$autoNumber";
	}
	my $hasManual = "manualnumber_0";
	if ( int($manualNumber) > 0 ) {
		$hasManual = "manualnumber_$manualNumber";
	}
	print <<DATA;
  <tr id="package_item_$packageName\_$hasAuto\_$hasManual">
    <td width="4%" align="center" class="custom_line_height report_list_outside_left_no_height"><input type="checkbox" name="checkbox_$packageName\_$hasAuto\_$hasManual" id="checkbox_$packageName\_$hasAuto\_$hasManual" onclick="javascript:update_package_select();" /></td>
    <td width="56%" class="custom_line_height report_list_outside_left_no_height">&nbsp;$packageName</td>
    <td width="11%" class="custom_line_height report_list_outside_left_no_height">&nbsp;$autoNumber</td>
    <td width="8%" class="custom_line_height report_list_outside_left_no_height">&nbsp;$manualNumber</td>
    <td width="8%" class="custom_line_height report_list_outside_left_no_height">&nbsp;$totalNumber</td>
    <td width="13%" class="custom_line_height report_list_outside_left_no_height">&nbsp;$packageVersion</td>
  </tr>
DATA
}
print <<DATA;
</table>
DATA

# start java script
print <<DATA;
<script language="javascript" type="text/javascript">
// define how run test plan work
var need_hardware_capability_option = false;
var change_after_load = false;
var current_run_test_plan = "temp";
var str_hardware_info="";

function old_save_plan_name()
{  
  
    var new_name = prompt("Please input the new plan name");
    document.getElementById('save_test_plan_text').value = new_name;
   
    if( new_name == null || !check_new_plan_name(new_name) )
    {  
	       return ;
    }
    else
       {

	       save_profile('text');
	       return;
       }
}

function save_and_run()
{
   need_hardware_capability_option = true;
		document.location = "tests_execute.pl?profile=" + current_run_test_plan
				+ "&need_check_hardware=" + need_hardware_capability_option
				+ "&content=" + str_hardware_info;


}

function change_all_status()
{
    var elem=document.getElementById('hardwareCapabilityDiv');
    var arr = elem.getElementsByTagName("*");
    var all_value = document.getElementById('change_all').checked;
    
    for(var i=0;i<arr.length;i++)
    {
         if(arr[i].type=="checkbox" && arr[i].id != "change_all" && arr[i].checked != all_value){
                      arr[i].click();
          }
    
    }
}

function open_the_hardwarecapabilityDiv()
{
 document.getElementById('hardwareCapabilityDiv').style.display = 'block';
 document.getElementById('popIframe').style.display = 'block';

 document.getElementById('usbHost_checkbox').click();
 document.getElementById('usbHost_checkbox').disabled="true";
 document.getElementById('inputKeyboard_checkbox').click();
 document.getElementById('inputKeyboard_checkbox').disabled="true";
 document.getElementById('usbAccessory_checkbox').click();
 document.getElementById('usbAccessory_checkbox').disabled="true";
}
function run_test_plan() {
	var test_plan_name = document.getElementById('test_profile').value;
	if (change_after_load) {
		if (confirm("The package selection or filter has changed,click 'Ok' to use 'temp' as a plan name to run test ,or click 'Cancel' to create a new plan.")) {
			current_run_test_plan = "temp";
			ajax_call_get('action=check_profile_isExist&profile_name=temp&option=save');
		} else {
                        old_save_plan_name();
			return;
		}
	} else {
		current_run_test_plan = test_plan_name;
	}
	ajax_call_get('action=pull_devcie_capability_xml&test_plan_name='
			+ current_run_test_plan);
}

// define how load test plan work
function load_test_plan() {
	var select_test_plan = document.getElementById('test_profile');
	if (select_test_plan.selectedIndex != 0) {
		var test_plan_name = select_test_plan.value;
		ajax_call_get('action=analyse_test_plan&load_test_plan_name='
				+ test_plan_name);
	} else {
		var page = document.getElementsByTagName("*");
		for ( var k = 0; k < page.length; k++) {
			var temp_id = page[k].id;
			if (temp_id.indexOf("checkbox_") >= 0) {
				document.getElementById(temp_id).checked = false;
			}
			if (temp_id.indexOf("package_item_") >= 0) {
				document.getElementById(temp_id).style.display = "";
			}
		}
		var select_execution_type = document
			.getElementById('select_execution_type');
		select_execution_type.options[0].selected = true;
		update_page_status();
	}
}

function update_page_by_load(test_plan_info) {
	var execution_type_package_list = test_plan_info.split("!::!");
	var execution_type = execution_type_package_list[0];
	var package_list = execution_type_package_list[1].split("!:!");
	var page = document.getElementsByTagName("*");
	for ( var k = 0; k < page.length; k++) {
		var temp_id = page[k].id;
		if (temp_id.indexOf("checkbox_") >= 0) {
			document.getElementById(temp_id).checked = false;
		}
	}
	for ( var j = 0; j < package_list.length; j++) {
		for ( var i = 0; i < page.length; i++) {
			var temp_id = page[i].id;
			if (temp_id.indexOf("checkbox_" + package_list[j]) >= 0) {
				document.getElementById(temp_id).checked = true;
			}
			if (temp_id.indexOf("package_item_" + package_list[j]) >= 0) {
				document.getElementById(temp_id).style.display = "";
			}
		}
	}
	var select_execution_type = document
			.getElementById('select_execution_type');

	if (execution_type == "auto") {
		select_execution_type.options[1].selected = true;
	} else if (execution_type == "manual") {
		select_execution_type.options[2].selected = true;
	} else {
		select_execution_type.options[0].selected = true;
	}
	update_page_status();
	// update global variables
	change_after_load = false;
}

// define how execution type select work
function filter_package() {
	var execution_type = document.getElementById('select_execution_type');
      
	var page = document.getElementsByTagName("*");
	for ( var i = 0; i < page.length; i++) {
		var temp_id = page[i].id;
		if (temp_id.indexOf("package_item_") >= 0) {
			var package_item = document.getElementById(temp_id);
			package_item.style.display = "";
			if (execution_type.value == "Automated") {
				var r_auto, re_auto;
				re_auto = new RegExp("autonumber_0", "g");
				r_auto = temp_id.match(re_auto);
				if (r_auto) {
					package_item.style.display = "none";
					var r_checkbox = new RegExp("package_item_", "g");
					var checkbox_id = temp_id.replace(r_checkbox, "checkbox_");
					document.getElementById(checkbox_id).checked = false;
				}
			}
			if (execution_type.value == "Manual") {
				var r_manual, re_manual;
				re_manual = new RegExp("manualnumber_0", "g");
				r_manual = temp_id.match(re_manual);
				if (r_manual) {
					package_item.style.display = "none";
					var r_checkbox = new RegExp("package_item_", "g");
					var checkbox_id = temp_id.replace(r_checkbox, "checkbox_");
					document.getElementById(checkbox_id).checked = false;
				}
			}
		}
	}
	// update global variables
	change_after_load = true;
}

// update package select when change checkbox
function update_package_select() {
	update_page_status();
	change_after_load = true;
}

// update button status when load page
restore_plan_page_init_state();
function restore_plan_page_init_state() {
	load_pre_test_plan();
	load_test_plan();
}

function load_pre_test_plan() {
	var select_test_plan = document.getElementById('test_profile');
	for ( var i = 0; i < select_test_plan.options.length; i++) {
		if (select_test_plan.options[i].value == "Full_test") {
			select_test_plan.options[i].selected = true;
		}
	}
}

function count_checked_checkbox_number() {
	var num = 0;
	var page = document.getElementsByTagName("*");
	for ( var i = 0; i < page.length; i++) {
		var temp_id = page[i].id;
		if ((temp_id.indexOf("checkbox_") >= 0)
				&& !((temp_id.indexOf("checkbox_all") >= 0))
				&& (document.getElementById(temp_id).checked)) {
			++num;
		}
	}
	return num;
}

function count_checkbox_number() {
	var num = 0;
	var page = document.getElementsByTagName("*");
	for ( var i = 0; i < page.length; i++) {
		var temp_id = page[i].id;
		if ((temp_id.indexOf("checkbox_") >= 0)
				&& !((temp_id.indexOf("checkbox_all") >= 0))) {
			++num;
		}
	}
	return num;
}

function update_page_status() {
	var button;
	var checked_checkbox_number = count_checked_checkbox_number();
	var checkbox_number = count_checkbox_number();
	var select_test_plan = document.getElementById('test_profile');
	var elem = document.getElementById('checkbox_all');
	// update run button status
	button = document.getElementById('execute_profile');
	if (button) {
		button.disabled = (select_test_plan.selectedIndex == 0);
		if (button.disabled) {
			button.className = "medium_button_disable";
		} else {
			button.className = "medium_button";
		}
	}
	// update config button status
	button = document.getElementById('pre_config');
	if (button) {
		button.disabled = (select_test_plan.selectedIndex == 0);
		if (button.disabled) {
			button.className = "medium_button_disable";
		} else {
			button.className = "medium_button";
		}
	}
	// update new plan name text status
	button = document.getElementById('save_test_plan_text');
	if (button) {
		button.disabled = (checked_checkbox_number == 0);
		if (button.disabled == true) {
			button.value = "";
		}
	}
	// update save, run and config button status
	button = document.getElementById('save_profile_button_text');
	if (button) {
		button.disabled = (checked_checkbox_number == 0);
		if (button.disabled) {
			button.className = "medium_button_disable";
		} else {
			button.className = "medium_button";
		}
	}
	button = document.getElementById('execute_profile');
	if (button) {
		button.disabled = (checked_checkbox_number == 0);
		if (button.disabled) {
			button.className = "medium_button_disable";
		} else {
			button.className = "medium_button";
		}
	}
	button = document.getElementById('pre_config');
	if (button) {
		button.disabled = (checked_checkbox_number == 0);
		if (button.disabled) {
			button.className = "medium_button_disable";
		} else {
			button.className = "medium_button";
		}
	}
	// update checkbox_all status
	if (checked_checkbox_number == checkbox_number) {
		if (checkbox_number == 0) {
			elem.checked = 0;
		} else {
			elem.checked = 1;
		}
	} else {
		elem.checked = 0;
	}
}

// define how checkbox_all work
function check_uncheck_all() {
	var elem = document.getElementById('checkbox_all');
	if (elem) {
		var checked = elem.checked;
		var page = document.getElementsByTagName("*");
		for ( var i = 0; i < page.length; i++) {
			var temp_id = page[i].id;
			if ((temp_id.indexOf("checkbox_") >= 0)
					&& !((temp_id.indexOf("checkbox_all") >= 0))) {
				document.getElementById(temp_id).checked = checked;
			}
		}
	}
	update_page_status();
	change_after_load = true;
}
DATA

# define how pre_config work
my $pre_config_content = <<DATA;
<table width="660" border="1" cellspacing="0" cellpadding="0" class="table_normal_small" rules="all" frame="void">
  <tr>
    <td width="4%" align="left" class="report_list_no_border">&nbsp;</td>
    <td colspan="4" align="left" class="report_list_no_border">&nbsp;</td>
    <td width="4%" align="left" class="report_list_no_border">&nbsp;</td>
  </tr>
  <tr>
    <td width="4%" align="left" class="report_list_no_border">&nbsp;</td>
    <td colspan="4" align="left" class="top_button_bg report_list_inside">&nbsp;Pre-configuration steps for TCT testing:</td>
    <td width="4%" align="left" class="report_list_no_border">&nbsp;</td>
  </tr>
  <tr>
    <td width="4%" align="left" class="report_list_no_border">&nbsp;</td>
    <td colspan="4" align="left" class="report_list_inside" id="pre_config_desc_xml_text">&nbsp;</td>
    <td width="4%" align="left" class="report_list_no_border">&nbsp;</td>
  </tr>
  <tr>
    <td width="4%" align="left" class="report_list_no_border">&nbsp;</td>
    <td colspan="2" align="left" class="report_list_no_border">&nbsp;</td>
    <td colspan="2" align="left" class="report_list_no_border">&nbsp;</td>
    <td width="4%" align="left" class="report_list_no_border">&nbsp;</td>
  </tr>
  <tr>
    <td width="4%" align="left" class="report_list_no_border">&nbsp;</td>
    <td colspan="2" align="left" class="report_list_no_border">&nbsp;</td>
    <td colspan="2" align="right" class="report_list_no_border"><input type="submit" name="close_config_div"  id="close_config_div" value="Close" class="small_button" onclick="javascript:save_and_run();" /></td>
    <td width="4%" align="left" class="report_list_no_border">&nbsp;</td>
  </tr>
</table>
DATA

$pre_config_content =~ s/\n//g;
print <<DATA;
function onPreConfig() {
	document.getElementById('preConfigDiv').innerHTML = '$pre_config_content';
	document.getElementById('preConfigDiv').style.display = 'block';
	document.getElementById('popIframe').style.display = 'block';
DATA
my $desc_xml_path = get_config_info("desc_xml");
my $desc_xml_cmd  = sdb_cmd("shell 'ls $desc_xml_path'");
my $desc_xml      = `$desc_xml_cmd`;
if ( $desc_xml !~ /No such file or directory/ ) {
	system( sdb_cmd("pull $desc_xml_path /tmp/desc_xml") );
	my $step_number  = 1;
	my $step_content = "";
	my $more_line    = "";
	if ( open( FILE, "/tmp/desc_xml" ) ) {
		my $line_start = 0;
		while (<FILE>) {
			my $line = $_;
			if ( $line =~ /<set(.+?)>/ ) {
				my $set_name = $1;
				$set_name =~ s/name="//g;
				$set_name =~ s/"//g;
				$step_number = 1;
				$step_content .=
				    "&nbsp;<span style=font-weight:bold;>"
				  . $set_name
				  . "</span>&nbsp;<\/br>";
			}
			if ( $line =~ /<step_desc>(.+?)<\/step_desc>/ ) {
				my $step = $1;
				$step =~ s/</&lt;/g;
				$step =~ s/>/&gt;/g;
				$step =~ s/'/&apos;/g;
				$step =~ s/"/&quot;/g;
				$step_content .= "<ol>.$step_number.$step<\/ol>";
				$step_number++;
				next;
			}
			else {
				if ( $line =~ /<step_desc>/ ) {
					$more_line = $line;
					while (<FILE>) {
						$more_line .= $_;
						if ( $_ =~ /<\/step_desc>/ ) {

							last;
						}
					}
				}
				$line = chomp($more_line);
				if ( $line =~ /<step_desc>(.+?)<\/step_desc>/ ) {
					my $step = $1;
					$step =~ s/</&lt;/g;
					$step =~ s/>/&gt;/g;
					$step =~ s/'/&apos;/g;
					$step =~ s/"/&quot;/g;
					$step_content .= "<ol>.$step_number.$step<\/ol>";
					$step_number++;
					next;
				}
			}
		}
		close(FILE);
	}
	system("rm -rf /tmp/desc_xml");
	print
"	document.getElementById('pre_config_desc_xml_text').innerHTML = '$step_content';\n";
}
else {
	print
"	document.getElementById('pre_config_desc_xml_text').innerHTML = '&nbsp;missing file: $desc_xml_path';\n";
}
print <<DATA;
}
DATA

# define how hardware capability work
print <<DATA;
function onSkipHardwareCapability() {
	onClosePopup();
	need_hardware_capability_option = false;
	document.location = "tests_execute.pl?profile=" + current_run_test_plan
			+ "&need_check_hardware=" + need_hardware_capability_option;
}


function onSaveHardwareCapability() {
DATA
print <<DATA;
	var hardware_list = new Array(
DATA
my @hardware_capability_array = ();
foreach ( keys %hardware_type ) {
	my $hardware_checkbox_id = $_;
	push( @hardware_capability_array,
		    '"'
		  . $hardware_checkbox_id . "!:!"
		  . $hardware_type{$hardware_checkbox_id}
		  . '"' );
}
print join( ", ", @hardware_capability_array );
print <<DATA;
	);
        
	var hardware_info = "";
	var has_blank = false;
	for ( var i = 0; i < hardware_list.length; i++) {
		var hardware_type = hardware_list[i].split("!:!");
		var hardware_name = hardware_type[0];
		var hardware_type = hardware_type[1];
		var hardware_id = document.getElementById(hardware_name + "_message").value;
		var hardware = document.getElementById(hardware_id);
		var hardware_content = "";
		var hardware_support = "false";
		if (document.getElementById(hardware_name + "_checkbox").checked) {
			hardware_support = "true";
		}
		if (hardware_id.indexOf("boolean") >= 0) {
			hardware_content = hardware.innerHTML;
		} else {
			hardware_content = hardware.value;
			if ((hardware_support == "true") && (hardware_content == "")) {
				has_blank = true;
				hardware.style.borderColor = "red";
			}
		}
		var this_hardware_info = hardware_name + "!:!" + hardware_type + "!:!" + hardware_content;
		if (hardware_info == "") {
			hardware_info = this_hardware_info;
		} else {
			hardware_info += "!::!" + this_hardware_info;
		}
	}
	if (has_blank) {  
                       

	} else {
		          str_hardware_info=hardware_info;
                          onClosePopup();
                          onPreConfig();
	}

}
DATA

# end of java script
print <<DATA;
</script>
DATA
