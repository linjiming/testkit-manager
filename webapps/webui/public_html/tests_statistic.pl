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
use File::Find;
use FindBin;
use Data::Dumper;
use Digest::SHA qw(sha1_hex);

my $profile_dir_manager = $FindBin::Bin . "/../../../profiles/test/";
if ( !( -e $profile_dir_manager ) ) {
	system( 'mkdir ' . $profile_dir_manager );
}

my @package_name           = ();
my @package_name_webapi    = ();
my @package_webapi_item    = ();
my @package_webapi_item_id = ();
my @testsxml               = ();
my @category               = ();
my @category_num           = ();
my @test_suite             = ();
my @test_suite_num         = ();
my @status                 = ();
my @status_num             = ();
my @type                   = ();
my @type_num               = ();
my @priority               = ();
my @priority_num           = ();
my @component              = ();
my @component_num          = ();
my @category_item          = ();
my @test_suite_item        = ();
my @status_item            = ();
my @type_item              = ();
my @priority_item          = ();
my @component_item         = ();

my $testSuitesPath                = "none";
my $package_name_number           = 0;
my $package_webapi_number         = 0;
my $package_webapi_item_num_total = 0;
my $count_num                     = 0;
my $category_number               = 0;
my $test_suite_number             = 0;
my $status_number                 = 0;
my $priority_number               = 0;
my $type_number                   = 0;
my $component_number              = 0;

my $result_dir_manager = $FindBin::Bin . "/../../../results/";
my %spec_list;

my @filter_suite_value            = ();
my @filter_type_value             = ();
my @filter_status_value           = ();
my @filter_component_value        = ();
my @filter_priority_value         = ();
my @filter_spec_value             = ();
my @filter_category_value         = ();
my $case_count_total              = 0;
my @one_package_case_count_total  = ();
my @one_webapi_package_item_count = ();
my $defination_dir                = $FindBin::Bin . "/../../../defination/";
my $test_definition_dir           = $defination_dir;

syncDefination();

ScanPackages();
CountPackages();
CreateFilePath();
AnalysisTestsXML();

if ( $package_name_number > 0 ) {
	GetSelectItem();
	FilterCaseValue();
}

for ( my $count = 0 ; $count < $package_name_number ; $count++ ) {
	if ( $package_name[$count] =~ /webapi/ ) {
		push( @package_name_webapi, $package_name[$count] );
		$package_webapi_number++;
	}
}

print "HTTP/1.0 200 OK" . CRLF;
print "Content-type: text/html" . CRLF . CRLF;

print_header( "$MTK_BRANCH Manager Main Page", "statistic" );

print <<DATA;
<div id="ajax_loading" style="display:none"></div>
<style type="text/css">
      .ygtvlabel, .ygtvlabel:link, .ygtvlabel:visited, .ygtvlabel:hover { 
          background-color: #FAFAFA;
      }
      .ygtvrow {
          height: 30px;
          background-color: #FAFAFA;
      }
    </style>
<div id="message"></div>
<table width="768" border="0" cellspacing="0" cellpadding="0" frame="void" rules="all" style="table-layout:fixed">
  <tr>
    <td><form id="tests_custom" name="tests_custom" method="post" action="">
      <table width="100%" border="0" cellspacing="0" cellpadding="0">
     
		 <tr>
          <td><table width="100%" border="0" cellspacing="0" cellpadding="0" class="top_button_bg">
            <tr>
               <td width="3%" align="left" height="30"  nowrap="nowrap"><img id="package_bar_chart" src="images/package_bar_chart_selected.png" title="Package Chart" style="cursor:default" width="73" height="30"  onclick=""/></td>
               <td width="3%" align="left" height="30"  nowrap="nowrap"><img id="package_tree_diagram" src="images/package_tree_diagram.png" title="Tree Diagram (This diaram is generated only for WebAPI packages. The branches are extracted from [Spec] filed inside the tests.xml file.)" style="cursor:pointer" width="73" height="30"  onclick="javascript:onDrawTree();"/></td>
               <td width="94%" align="left" height="30"  nowrap="nowrap"><img id="component_bar_chart" src="images/component_bar_chart.png" title="Component Chart" style="cursor:pointer" width="73" height="30"  onclick="javascript:onDrawComponent();"/></td>                      
            </tr>
          </table></td>
        </tr>
               
        <tr>
          <td id="list_advanced"><table width="768" border="1" cellspacing="0" cellpadding="0" frame="below" rules="all">
            <tr>
              <td width="50%" nowrap="nowrap" class="custom_list_type_bottomright"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
					<td width="30%" height="30" ="50" align="left" class="custom_title">&nbsp;Category</td><td>
                    <select name="select_category" align="20px" id="select_category" class="custom_select" style="width:70%" onchange="javascript:filter_case_item();">
DATA
DrawCategorySelect();
print <<DATA;
                    </select>
                    </td>
                  <td width="20%">&nbsp;</td>
                </tr>
              </table></td>
              <td width="50%" nowrap="nowrap" class="custom_list_type_bottom"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
					<td width="30%" height="30"  align="left" class="custom_title">&nbsp;Type</td><td>
                    <select name="select_type" align="20px" id="select_type" class="custom_select" style="width:70%" onchange="javascript:filter_case_item();">
DATA
DrawTypeSelect();
print <<DATA;
                    </select>
                    </td>
                  <td width="20%">&nbsp;</td>
                </tr>
              </table></td>
            </tr>
            
            <tr>
              <td width="50%" nowrap="nowrap" class="custom_list_type_bottomright"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                   	<td width="30%" height="30"  align="left" class="custom_title">&nbsp;Status</td><td>
                    <select name="select_status" align="20px" id="select_status" class="custom_select" style="width:70%" onchange="javascript:filter_case_item();">
DATA
DrawStatusSelect();
print <<DATA;
                    </select>
                    </td>
                  <td width="20%">&nbsp;</td>
                </tr>
              </table></td>
              <td width="50%" nowrap="nowrap" class="custom_list_type_bottom"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                   	<td width="30%" height="30"  align="left" class="custom_title">&nbsp;Priority</td><td>
                    <select name="select_priority" align="20px" id="select_priority" class="custom_select" style="width:70%" onchange="javascript:filter_case_item();">
DATA
DrawPrioritySelect();
print <<DATA;
                    </select>
                    </td>
                  <td width="20%">&nbsp;</td>
                </tr>
              </table></td>
            </tr>
            
            <tr>
              <td width="50%" nowrap="nowrap" class="custom_list_type_bottomright"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                   	<td width="30%" height="30"  align="left" class="custom_title">&nbsp;Test suite</td><td>
                    <select name="select_testsuite" align="20px" id="select_testsuite" class="custom_select" style="width:70%" onchange="javascript:filter_case_item();">
DATA
DrawTestsuiteSelect();
print <<DATA;
                    </select>
                    </td>
                  <td width="20%">&nbsp;</td>
                </tr>
              </table></td>
              
              <td id="select_package_disabled_td" width="50%" nowrap="nowrap" class="custom_list_type_bottom"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="all">
                <tr>
                  <td width="100%">&nbsp;</td>
                </tr>
              </table></td>
              
              <td id="select_package_td" width="50%" nowrap="nowrap" class="custom_list_type_bottom" style="display:none"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                   	<td width="30%" height="30"  align="left" class="custom_title">&nbsp;Package</td><td>
                    <select name="select_package" align="20px" id="select_package" class="custom_select" style="width:70%" onchange="javascript:draw_package_tree();">
DATA
DrawPackageSelect();
print <<DATA;
                    </select>
                    </td>
                  <td width="20%">&nbsp;</td>
                </tr>
              </table></td>
              
            </tr>
           </table></td>
         </tr>
         
DATA

print <<DATA;
        <tr id="background_top" style="display:">
	       <td><table width="100%" height="15" border="0" cellspacing="0" cellpadding="0" frame="void" rules="all">	
		        <td width="100%" align="right" valign="middle" class="backbackground_button"></td> 
	       </table></td>
	     </tr>     
DATA

print <<DATA;
        <tr id="no_webapi_attention_div" style="background-color:#E9F6FC;display:none">
	       <td><table width="100%" height="120" border="0" cellspacing="0" cellpadding="0" frame="void" rules="all">	
		        <td width="100%" align="middle" valign="middle" class="static_chart_select">
		        No webapi packages !</td> 
	       </table></td>
	     </tr>     
DATA

print <<DATA;
        <tr id="no_pkg_attention_div" style="background-color:#E9F6FC;display:none">
	       <td><table width="100%" height="120" border="0" cellspacing="0" cellpadding="0" frame="void" rules="all">	
		        <td width="100%" align="middle" valign="middle" class="static_chart_select">
		        No packages !</td> 
	       </table></td>
	     </tr>     
DATA

for ( my $count = 0 ; $count < $package_name_number ; $count++ ) {
	my $frame;
	if ( $count eq "0" ) {
		$frame = "hsides";
	}
	else {
		$frame = "below";
	}
	print <<DATA;
	     <tr id="static_list_$package_name[$count]" style="display:">
	       <td><table width="100%" height="30"  border="0" cellspacing="0" cellpadding="0" frame="$frame" rules="all" style="table-layout:fixed">	
		        <td width="25%" height="30"  align="right" class="static_list_packagename" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$package_name[$count]">$package_name[$count]</td>
		        <td width="3%" height="30"  class="static_list_packagename">&nbsp;</td> 
		        <td id="static_list_bar_td_$package_name[$count]" align="left" height="30"  class="static_list_count_bar" ><span id="static_list_bar_$package_name[$count]"></span></td>
		        <td width="1%" height="30"  class="static_list_num">&nbsp;</td>  
		        <td id="static_list_num_$package_name[$count]" align="left" height="30"  class="static_list_num" ><span id="static_list_num_$package_name[$count]"></span></td> 
		        <td width="12%" height="30"  class="static_list_packagename">&nbsp;</td>      
	       </table></td>
	      </tr>
DATA
}

print <<DATA;
        <tr id="background_top1" style="display:">
	       <td><table width="100%" height="8" border="0" cellspacing="0" cellpadding="0" frame="void" rules="all">	
		        <td width="100%" align="right" valign="middle" class="backbackground_button"></td> 
	       </table></td>
	     </tr>  
DATA

print <<DATA;
        <tr id="static_scale" style="display:">
	       <td><table width="100%" height="8" border="0" cellspacing="0" cellpadding="0" frame="below" rules="all">
	       		<td width="29%" align="right" class="static_list_scale_head"></td>
		        <td width="9%" align="right" valign="middle" class="static_list_scale"></td> 
		        <td width="9%" align="right" valign="middle" class="static_list_scale"></td> 
		        <td width="9%" align="right" valign="middle" class="static_list_scale"></td> 
		        <td width="9%" align="right" valign="middle" class="static_list_scale"></td> 
		        <td width="9%" align="right" valign="middle" class="static_list_scale"></td> 
		        <td width="9%" align="right" valign="middle" class="static_list_scale"></td> 
		        <td width="19%" class="static_list_scale_head"></td>
	       </table></td>
	     </tr>  
DATA

print <<DATA;
        <tr id="static_scale_number" style="display:">
	       <td><table width="100%" height="8" border="0" cellspacing="0" cellpadding="0" frame="void" rules="all">
	       		<td width="28%" align="left" class="static_list_scale_num"></td>
		        <td width="8%" id="static_scale_number0" align="left" valign="middle" class="static_list_scale_num"></td> 
		        <td width="9%" id="static_scale_number1" align="left" valign="middle" class="static_list_scale_num"></td> 
		        <td width="9%" id="static_scale_number2" align="left" valign="middle" class="static_list_scale_num"></td> 
		        <td width="9%" id="static_scale_number3" align="left" valign="middle" class="static_list_scale_num"></td> 
		        <td width="9%" id="static_scale_number4" align="left" valign="middle" class="static_list_scale_num"></td> 
		        <td width="9%" id="static_scale_number5" align="left" valign="middle" class="static_list_scale_num"></td> 
		        <td width="19%" id="static_scale_number6"class="static_list_scale_num"></td>
	       </table></td>
	     </tr>  
DATA

my $one_webapi_package_item_count = 0;
for ( my $count = 0 ; $count < $package_webapi_number ; $count++ ) {
	print <<DATA;
             <tr id="tree_area_$package_name_webapi[$count]" style="display:none">
              	<td><table width="100%" height="30"  border="0" cellspacing="0" cellpadding="0" rules="all">
              	<tr>
              		<td width="21%" class="static_list_packagename" ><img src="images/statistic_background_left.png"></td>
                	<td width="40%" align="left" valign="top" class="static_list_packagename" >
                  	<div id="tree_area_test_type_$package_name_webapi[$count]" style="display:"></div></td>
                  	<td width="12%" align="right" valign="bottom" class="static_list_packagename" ><img src="images/statistic_background_right.png"></td>
                 </tr>
                 </table></td>
               </tr>
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
		tree = new YAHOO.widget.TreeView("tree_area_test_type_$package_name_webapi[$count]");
DATA
	updateStaticSpecList( $package_name_webapi[$count] );
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
				  . '<span id=\'SP_'
				  . $count
				  . sha1_hex($parent)
				  . '\' class=\'static_tree_count\'>'
				  . '</span>'
				  . '", tree.getRoot(), false);';
				print "\n";
				print 'SP_'
				  . sha1_hex($parent)
				  . '.title="SP_'
				  . sha1_hex($parent) . '";';
				print "\n";
				push( @package_webapi_item, $item );
				push( @package_webapi_item_id,
					'SP_' . $count . sha1_hex($parent) );
				$one_webapi_package_item_count++;
				$package_webapi_item_num_total++;
			}
			else {
				print 'var SP_'
				  . sha1_hex( $parent . ':' . $item )
				  . ' = new YAHOO.widget.TextNode("'
				  . $item
				  . '<span id=\'SP_'
				  . $count
				  . sha1_hex( $parent . ':' . $item )
				  . '\' class=\'static_tree_count\'>'
				  . '</span>'
				  . '", SP_'
				  . sha1_hex($parent)
				  . ', false);';
				print "\n";
				print 'SP_'
				  . sha1_hex( $parent . ':' . $item )
				  . '.title="SP_'
				  . sha1_hex( $parent . ':' . $item ) . '";';
				print "\n";
				push( @package_webapi_item, $parent . ":" . $item );
				push( @package_webapi_item_id,
					'SP_' . $count . sha1_hex( $parent . ':' . $item ) );
				$one_webapi_package_item_count++;
				$package_webapi_item_num_total++;
			}
		}
		if ( $i == $spec_depth ) {
			push( @one_webapi_package_item_count,
				$one_webapi_package_item_count );
		}
	}
	print <<DATA;
		tree.draw();
		tree.expandAll();
		tree.collapseAll();
	}

	// Add a window onload handler to build the tree when the load
	// event fires.
	YAHOO.util.Event.addListener(window, "load", treeInit);

})();
// ]]>
</script>
DATA
}

for ( my $count = 0 ; $count < @component ; $count++ ) {
	my $frame;
	if ( $count eq "0" ) {
		$frame = "hsides";
	}
	else {
		$frame = "below";
	}
	print <<DATA;
	     <tr id="static_list_component_$component[$count]" style="display:none">
	       <td><table width="100%" height="30"  border="0" cellspacing="0" cellpadding="0" frame="$frame" rules="all" style="table-layout:fixed">	
		        <td width="35%" height="30"  align="right" class="static_list_packagename" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;" title="$component[$count]">$component[$count]</td>
		        <td width="3%" height="30"  class="static_list_packagename">&nbsp;</td> 
		        <td id="static_list_component_bar_td_$component[$count]" align="left" height="30"  class="static_list_count_bar" ><span id="static_list_component_bar_$component[$count]"></span></td>
		        <td width="1%" height="30"  class="static_list_num">&nbsp;</td>  
		        <td id="static_list_component_num_$component[$count]" align="left" height="30"  class="static_list_num" ><span id="static_list_component_num_$component[$count]"></span></td> 
		        <td width="12%" height="30"  class="static_list_packagename">&nbsp;</td>      
	       </table></td>
	      </tr>
DATA
}

print <<DATA;
        <tr id="background_top2" style="display:none">
	       <td><table width="100%" height="8" border="0" cellspacing="0" cellpadding="0" frame="void" rules="all">	
		        <td width="100%" align="right" valign="middle" class="backbackground_button"></td> 
	       </table></td>
	     </tr>  
DATA

print <<DATA;
        <tr id="static_scale_component" style="display:none">
	       <td><table width="100%" height="8" border="0" cellspacing="0" cellpadding="0" frame="below" rules="all">
	       		<td width="38%" align="right" class="static_list_scale_head"></td>
		        <td width="7.5%" align="right" valign="middle" class="static_list_scale"></td> 
		        <td width="7.5%" align="right" valign="middle" class="static_list_scale"></td> 
		        <td width="7.5%" align="right" valign="middle" class="static_list_scale"></td> 
		        <td width="7.5%" align="right" valign="middle" class="static_list_scale"></td> 
		        <td width="7.5%" align="right" valign="middle" class="static_list_scale"></td> 
		        <td width="7.5%" align="right" valign="middle" class="static_list_scale"></td> 
		        <td width="19%" class="static_list_scale_head"></td>
	       </table></td>
	     </tr>  
DATA

print <<DATA;
        <tr id="static_scale_number_component" style="display:none">
	       <td><table width="100%" height="8" border="0" cellspacing="0" cellpadding="0" frame="void" rules="all">
	       		<td width="38%" align="left" class="static_list_scale_num"></td>
		        <td width="6.5%" id="static_scale_number_component0" align="left" valign="middle" class="static_list_scale_num"></td> 
		        <td width="7.5%" id="static_scale_number_component1" align="left" valign="middle" class="static_list_scale_num"></td> 
		        <td width="7.5%" id="static_scale_number_component2" align="left" valign="middle" class="static_list_scale_num"></td> 
		        <td width="7.5%" id="static_scale_number_component3" align="left" valign="middle" class="static_list_scale_num"></td> 
		        <td width="7.5%" id="static_scale_number_component4" align="left" valign="middle" class="static_list_scale_num"></td> 
		        <td width="7.5%" id="static_scale_number_component5" align="left" valign="middle" class="static_list_scale_num"></td> 
		        <td width="20%" id="static_scale_number_component6"class="static_list_scale_num"></td>
	       </table></td>
	     </tr>  
DATA

print <<DATA;
        <tr id="background_bottom" style="display:">
	       <td><table width="100%" height="25" border="0" cellspacing="0" cellpadding="0" frame="void" rules="all">	
		        <td width="100%" align="right" valign="middle" class="backbackground_button"></td> 
	       </table></td>
	     </tr>  
DATA

if ( $package_name_number ne "0" ) {
	print <<DATA;
	<script>
	document.getElementById("no_pkg_attention_div").style.display = "none";
	</script>   
DATA
}
else {
	print <<DATA;
	<script>
	document.getElementById("no_pkg_attention_div").style.display = "";
	document.getElementById("static_scale").style.display = "none";
	document.getElementById("background_top").style.display = "none";
	document.getElementById("background_bottom").style.display = "none";
	</script>   
DATA
}
print <<DATA;
        </table>
       </form>
      </td>
     </tr>
    </table> 
		
DATA

print <<DATA;
<script type="text/javascript" src="run_tests.js"></script>
<script language="javascript" type="text/javascript">

var package_name_number = 
DATA
print $package_name_number. ";";

print <<DATA;
var component_number = 
DATA
print @component . ";";

print <<DATA;
var package_name = new Array(
DATA
for ( $count_num = 0 ; $count_num < $package_name_number ; $count_num++ ) {
	if ( $count_num == $package_name_number - 1 ) {
		print '"' . $package_name[$count_num] . '"';
	}
	else {
		print '"' . $package_name[$count_num] . '"' . ",";
	}
}
print <<DATA;
);
DATA

print <<DATA;
var package_name_webapi = new Array(
DATA
for ( $count_num = 0 ; $count_num < $package_webapi_number ; $count_num++ ) {
	if ( $count_num == $package_webapi_number - 1 ) {
		print '"' . $package_name_webapi[$count_num] . '"';
	}
	else {
		print '"' . $package_name_webapi[$count_num] . '"' . ",";
	}
}
print <<DATA;
);
DATA

print <<DATA;
var package_name_webapi_number = 
DATA
print $package_webapi_number. ";";

print <<DATA;
var package_webapi_item = new Array(
DATA
for (
	$count_num = 0 ;
	$count_num < $package_webapi_item_num_total ;
	$count_num++
  )
{
	if ( $count_num == $package_webapi_item_num_total - 1 ) {
		print '"' . $package_webapi_item[$count_num] . '"';
	}
	else {
		print '"' . $package_webapi_item[$count_num] . '"' . ",";
	}
}
print <<DATA;
);
DATA

print <<DATA;
var package_webapi_item_id = new Array(
DATA
for (
	$count_num = 0 ;
	$count_num < $package_webapi_item_num_total ;
	$count_num++
  )
{
	if ( $count_num == $package_webapi_item_num_total - 1 ) {
		print '"' . $package_webapi_item_id[$count_num] . '"';
	}
	else {
		print '"' . $package_webapi_item_id[$count_num] . '"' . ",";
	}
}
print <<DATA;
);
DATA

print <<DATA;
var one_webapi_package_item_count = new Array(
DATA
for ( $count_num = 0 ; $count_num < $package_webapi_number ; $count_num++ ) {
	if ( $count_num == $package_webapi_number - 1 ) {
		print '"' . $one_webapi_package_item_count[$count_num] . '"';
	}
	else {
		print '"' . $one_webapi_package_item_count[$count_num] . '"' . ",";
	}
}
print <<DATA;
);
DATA

print <<DATA;
var package_webapi_item_number_total = 
DATA
print $package_webapi_item_num_total. ";";

print <<DATA;
var static_package_list = new Array(
DATA
for ( $count_num = 0 ; $count_num < $package_name_number ; $count_num++ ) {
	if ( $count_num == $package_name_number - 1 ) {
		print '"' . "static_list_" . $package_name[$count_num] . '"';
	}
	else {
		print '"' . "static_list_" . $package_name[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);
DATA

print <<DATA;
var static_list_bar = new Array(
DATA
for ( $count_num = 0 ; $count_num < $package_name_number ; $count_num++ ) {
	if ( $count_num == $package_name_number - 1 ) {
		print '"' . "static_list_bar_" . $package_name[$count_num] . '"';
	}
	else {
		print '"' . "static_list_bar_" . $package_name[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);
DATA

print <<DATA;
var static_list_num = new Array(
DATA
for ( $count_num = 0 ; $count_num < $package_name_number ; $count_num++ ) {
	if ( $count_num == $package_name_number - 1 ) {
		print '"' . "static_list_num_" . $package_name[$count_num] . '"';
	}
	else {
		print '"' . "static_list_num_" . $package_name[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);
DATA

print <<DATA;
var static_list_bar_td = new Array(
DATA
for ( $count_num = 0 ; $count_num < $package_name_number ; $count_num++ ) {
	if ( $count_num == $package_name_number - 1 ) {
		print '"' . "static_list_bar_td_" . $package_name[$count_num] . '"';
	}
	else {
		print '"'
		  . "static_list_bar_td_"
		  . $package_name[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);
DATA

print <<DATA;
var static_list_component_bar = new Array(
DATA
for ( $count_num = 0 ; $count_num < @component ; $count_num++ ) {
	if ( $count_num == @component - 1 ) {
		print '"' . "static_list_component_bar_" . $component[$count_num] . '"';
	}
	else {
		print '"'
		  . "static_list_component_bar_"
		  . $component[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);
DATA

print <<DATA;
var static_list_component_num = new Array(
DATA
for ( $count_num = 0 ; $count_num < @component ; $count_num++ ) {
	if ( $count_num == @component - 1 ) {
		print '"' . "static_list_component_num_" . $component[$count_num] . '"';
	}
	else {
		print '"'
		  . "static_list_component_num_"
		  . $component[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);
DATA

print <<DATA;
var static_list_component_bar_td = new Array(
DATA
for ( $count_num = 0 ; $count_num < @component ; $count_num++ ) {
	if ( $count_num == @component - 1 ) {
		print '"'
		  . "static_list_component_bar_td_"
		  . $component[$count_num] . '"';
	}
	else {
		print '"'
		  . "static_list_component_bar_td_"
		  . $component[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);
DATA

print <<DATA;
var suite_value = new Array(
DATA
for ( $count_num = 0 ; $count_num < $case_count_total ; $count_num++ ) {
	if ( $count_num == $case_count_total - 1 ) {
		print '"' . $filter_suite_value[$count_num] . '"';
	}
	else {
		print '"' . $filter_suite_value[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);				
DATA

print <<DATA;
var type_value = new Array(
DATA
for ( $count_num = 0 ; $count_num < $case_count_total ; $count_num++ ) {
	if ( $count_num == $case_count_total - 1 ) {
		print '"' . $filter_type_value[$count_num] . '"';
	}
	else {
		print '"' . $filter_type_value[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);				
DATA

print <<DATA;
var status_value = new Array(
DATA
for ( $count_num = 0 ; $count_num < $case_count_total ; $count_num++ ) {
	if ( $count_num == $case_count_total - 1 ) {
		print '"' . $filter_status_value[$count_num] . '"';
	}
	else {
		print '"' . $filter_status_value[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);				
DATA

print <<DATA;
var priority_value = new Array(
DATA
for ( $count_num = 0 ; $count_num < $case_count_total ; $count_num++ ) {
	if ( $count_num == $case_count_total - 1 ) {
		print '"' . $filter_priority_value[$count_num] . '"';
	}
	else {
		print '"' . $filter_priority_value[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);				
DATA

print <<DATA;
var category_value = new Array(
DATA
for ( $count_num = 0 ; $count_num < $case_count_total ; $count_num++ ) {
	if ( $count_num == $case_count_total - 1 ) {
		print '"' . $filter_category_value[$count_num] . '"';
	}
	else {
		print '"' . $filter_category_value[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);				
DATA

print <<DATA;
var spec_value = new Array(
DATA
for ( $count_num = 0 ; $count_num < $case_count_total ; $count_num++ ) {
	if ( $count_num == $case_count_total - 1 ) {
		print '"' . $filter_spec_value[$count_num] . '"';
	}
	else {
		print '"' . $filter_spec_value[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);				
DATA

print <<DATA;
var one_package_case_count_total = new Array(
DATA
for ( $count_num = 0 ; $count_num < $package_name_number ; $count_num++ ) {
	if ( $count_num == $package_name_number - 1 ) {
		print '"' . $one_package_case_count_total[$count_num] . '"';
	}
	else {
		print '"' . $one_package_case_count_total[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);				
DATA

print <<DATA;
var component = new Array(
DATA
for ( $count_num = 0 ; $count_num < @component ; $count_num++ ) {
	if ( $count_num == @component - 1 ) {
		print '"' . $component[$count_num] . '"';
	}
	else {
		print '"' . $component[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);
DATA

print <<DATA;
var component_value = new Array(
DATA
for ( $count_num = 0 ; $count_num < $case_count_total ; $count_num++ ) {
	if ( $count_num == $case_count_total - 1 ) {
		print '"' . $filter_component_value[$count_num] . '"';
	}
	else {
		print '"' . $filter_component_value[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);				
DATA

print <<DATA;
var chart_id 			= document.getElementById('package_bar_chart');
var tree_id 			= document.getElementById('package_tree_diagram');
var component_id 		= document.getElementById('component_bar_chart');
var sel_category_id 	= document.getElementById('select_category');
var sel_type_id 		= document.getElementById('select_type');
var sel_testsuite_id 	= document.getElementById('select_testsuite');
var sel_priority_id  	= document.getElementById('select_priority');
var sel_status_id  		= document.getElementById('select_status');
var sel_pkg_id  		= document.getElementById('select_package_td');
var sel_pkg_dis_id 		= document.getElementById('select_package_disabled_td');
var top_id				= document.getElementById('background_top');
var bottom_id			= document.getElementById('background_bottom');
var no_webapi_id		= document.getElementById('no_webapi_attention_div');
var no_pkg_id		= document.getElementById('no_pkg_attention_div');
var adv_value_package	= document.getElementById('select_package');

var background_top1_id = document.getElementById('background_top1');
var static_scale_id = document.getElementById('static_scale');
var static_scale_number_id = document.getElementById('static_scale_number');
var background_top2_id = document.getElementById('background_top2');
var static_scale_component_id = document.getElementById('static_scale_component');
var static_scale_number_component_id = document.getElementById('static_scale_number_component');
	
function disabledSelectButton(){
	sel_category_id.disabled	= true;
	sel_type_id.disabled		= true;
	sel_testsuite_id.disabled	= true;
	sel_priority_id.disabled	= true;
	sel_status_id.disabled		= true;
	adv_value_package.disabled	= true;
}

function static_pkg_list_display(style){
	for ( var count = 0 ; count < package_name_number ; count++ ) {
	   var id = "static_list_"+package_name[count];
	   document.getElementById(id).style.display = style;
	}
}

function static_tree_display(style){
	for ( var count = 0 ; count < package_name_webapi_number ; count++ ) {
		var id = "tree_area_"+package_name_webapi[count];
		document.getElementById(id).style.display = style;
	}
}

function static_component_display(style){
	for ( var count = 0 ; count < component_number ; count++ ) {
	   var id = "static_list_component_"+component[count];
	   document.getElementById(id).style.display = style;
	}
}

function static_scale_display(style1,style2){
	background_top1_id.style.display = style1;
	static_scale_id.style.display = style1;
	static_scale_number_id.style.display = style1;
	background_top2_id.style.display = style2;
	static_scale_component_id.style.display = style2;
	static_scale_number_component_id.style.display = style2;
}

function onDrawCylindrical(){
	top_id.style.display		 = "";
	bottom_id.style.display		 = "";
	sel_pkg_dis_id.style.display = "";
	sel_pkg_id.style.display 	 = "none";
	no_webapi_id.style.display	 = "none";
	no_pkg_id.style.display		 = "none";
	chart_id.src				 = "images/package_bar_chart_selected.png";
	tree_id.src					 = "images/package_tree_diagram.png";
	component_id.src			 = "images/component_bar_chart.png";
	static_scale_display("","none");

	chart_id.style.cursor = "default";
	chart_id.onclick = "";
	
	tree_id.style.cursor = "pointer";
	tree_id.onclick = function(){
		return onDrawTree();
	};
	
	component_id.style.cursor = "pointer";
	component_id.onclick = function(){
		return onDrawComponent();
	};
	
	if(package_name_number == 0){
		no_pkg_id.style.display	= "";
		static_scale_id.style.display = "none";
		static_scale_component_id.style.display = "none";
		top_id.style.display	= "none";
		bottom_id.style.display	= "none";
		disabledSelectButton();
	}
	static_pkg_list_display("");
	filter_case_item();	
	static_tree_display("none");	
	static_component_display("none");
	

	
}

function onDrawTree(){
	top_id.style.display		 = "";
	bottom_id.style.display		 = "";
	sel_pkg_id.style.display 	 = "";
	sel_pkg_dis_id.style.display = "none";
	no_pkg_id.style.display		 = "none";
	tree_id.src					 = "images/package_tree_diagram_selected.png";
	chart_id.src				 = "images/package_bar_chart.png";
	component_id.src			 = "images/component_bar_chart.png";
	static_scale_display("none","none");

	tree_id.style.cursor = "default";
	tree_id.onclick = "";
	
	chart_id.style.cursor = "pointer";
	chart_id.onclick = function(){
		return onDrawCylindrical();
	};
	
	component_id.style.cursor = "pointer";
	component_id.onclick = function(){
		return onDrawComponent();
	};
	
	static_pkg_list_display("none");	
	static_component_display("none");	

	
	if(package_name_webapi_number == 0){
		no_webapi_id.style.display = "";
		top_id.style.display	   = "none";
		bottom_id.style.display	   = "none";
		disabledSelectButton();
	}
	else{
		var tree_area_id = "tree_area_"+package_name_webapi[0];
	    document.getElementById(tree_area_id).style.display = "";
	    filter_case_item();
	}
}

function onDrawComponent(){
	top_id.style.display		 = "";
	bottom_id.style.display		 = "";
	sel_pkg_id.style.display	 = "none";
	no_webapi_id.style.display	 = "none";
	no_pkg_id.style.display		 = "none";
	sel_pkg_dis_id.style.display = "";
	component_id.src			 = "images/component_bar_chart_selected.png";
	chart_id.src				 = "images/package_bar_chart.png";
	tree_id.src					 = "images/package_tree_diagram.png";	
	component_id.style.cursor	 = "default";
	chart_id.style.cursor 		 = "pointer";
	tree_id.style.cursor		 = "pointer";
	static_scale_display("none","");
	
	component_id.onclick		 = "";
	
	chart_id.onclick = function(){
		return onDrawCylindrical();
	};	
	tree_id.onclick = function(){
		return onDrawTree();
	};
	
	if(package_name_number == 0){
		no_pkg_id.style.display	= "";
		static_scale_id.style.display = "none";
		static_scale_component_id.style.display = "none";
		top_id.style.display	= "none";
		bottom_id.style.display	= "none";
		disabledSelectButton();
	}
	static_component_display("");
	filter_case_item();
	static_pkg_list_display("none");	
	static_tree_display("none");
}

function draw_package_tree(){
	static_tree_display("none");
	var tree_area_id = "tree_area_"+adv_value_package.value;
	document.getElementById(tree_area_id).style.display = "";
	filter_case_item();
}

function draw_static_scale(scale_id,count){
	for(var j=0; j<7; j++){
		var static_scale_id = scale_id+j;
		var id = document.getElementById(static_scale_id);
		id.innerHTML=j*count;
	}
}

function filter_case_item(){
	var webapi_no;
	var flag_case 			  = new Array();
	var component_count 	  = new Array();
	var package_case_count 	  = new Array();	
	var pkg_webapi_item_count = new Array();
	var count_webapi_start;
	var count_webapi_end;
	var max_case_count = 0;
	var max_component_count = 0;

	for (var i=0; i<component_number; i++){
		var id = static_list_component_bar[i];
		document.getElementById(id).innerHTML = "";
		component_count[i] = 0;
	}

	for (var i=0; i<package_name_number; i++) {
		var j;		
		var flag 		= 0;
		var count_start = one_package_case_count_total[i-1];
		var count_end 	= one_package_case_count_total[i];
		var id 	 		= static_list_bar[i];
		document.getElementById(id).innerHTML = "";
		package_case_count[i] =	0;
		
		for(var m=0; m<package_name_webapi_number; m++){
			var webapi_name = package_name_webapi[m];
			
			if(package_name[i].indexOf(webapi_name)>=0){
				flag 		= 1;
				webapi_no 	= m;
				count_webapi_start = one_webapi_package_item_count[webapi_no-1];
				count_webapi_end   = one_webapi_package_item_count[webapi_no];
				
				for(var k=0; k<package_webapi_item_number_total; k++){
					pkg_webapi_item_count[k] = 0;
				}	
			}
		}	
		
		if(i == "0"){
			j=0;
		}
		else{
			j = parseInt(count_start);
		}		

		for(j; j < parseInt(count_end); j++) {	
			if (((sel_testsuite_id.value == "Any Test Suite")
			||(sel_testsuite_id.value == suite_value[j]))
			&& ((sel_type_id.value == "Any Type")
			||(sel_type_id.value == type_value[j]))
			&& ((sel_status_id.value == "Any Status")
			||(sel_status_id.value == status_value[j]))
			&& ((sel_priority_id.value == "Any Priority")
			||(sel_priority_id.value == priority_value[j]))
			&& ((sel_category_id.value == "Any Category")
			||(category_value[j].indexOf(sel_category_id.value))>0)
			){	
				package_case_count[i]++;
				if(flag){	
					var k;		
					if(webapi_no == "0"){
						k=0;
					}
					else{
						k = parseInt(count_webapi_start);
					}	
					for(k; k < parseInt(count_webapi_end); k++){
						var item = package_webapi_item[k];
						if((spec_value[j].indexOf(item+":") >= 0)||(spec_value[j] == item)){
							pkg_webapi_item_count[k]++; 							
						}
					}
				}
				for (var n=0; n<component_number; n++){
					if(component_value[j] == component[n]){
						component_count[n]++;
					}	
				}
			}
		}
		
		if(flag){
			if( j == parseInt(count_end)){
				var k;		
				if(webapi_no == "0"){
					k=0;
				}
				else{
					k = parseInt(count_webapi_start);
				}	
				for(k; k< parseInt(count_webapi_end); k++){	
					var id 	 = package_webapi_item_id[k];
					var temp = document.getElementById(id);
					if(temp){
						temp.innerHTML = "("+pkg_webapi_item_count[k]+")";	
					}
				}
			}
		}
	}
		
	for(var m=0; m<package_name_number; m++){
		max_case_count = Math.max(max_case_count,package_case_count[m]);
	}
	
	for (var n=0; n<component_number; n++){
		max_component_count = Math.max(max_component_count,component_count[n]);
	}
			
	for (var i=0; i<package_name_number; i++) {
		var list_bar = document.getElementById(static_list_bar_td[i]);
		var list_num = document.getElementById(static_list_num[i]);
		
		if(	package_case_count[i] == 0){
			list_bar.width = 1;
			list_num.innerHTML = package_case_count[i];
		}
		else{
			var pb = new YAHOO.widget.ProgressBar().render(static_list_bar[i]);
			pb.set('minValue', 0);
			pb.set('maxValue', package_case_count[i]);
			
			if(max_case_count >=0 && max_case_count <= 30){
				pb.set('width', package_case_count[i]*13.5);
				list_bar.width = package_case_count[i]*13.5;
				draw_static_scale("static_scale_number",5);
			}
			else if(max_case_count > 30 && max_case_count <= 60){
				pb.set('width', package_case_count[i]*6.8);
				list_bar.width = package_case_count[i]*6.8;
				draw_static_scale("static_scale_number",10);
			}
			else if(max_case_count > 60 && max_case_count <= 120){
				pb.set('width', package_case_count[i]*3.4);
				list_bar.width = package_case_count[i]*3.4;
				draw_static_scale("static_scale_number",20);
			}
			else if(max_case_count > 120 && max_case_count <= 180){
				pb.set('width', package_case_count[i]*2.3);
				list_bar.width = package_case_count[i]*2.3;
				draw_static_scale("static_scale_number",30);
			}
			else if(max_case_count > 180 && max_case_count<= 300){
				pb.set('width', package_case_count[i]*1.4);
				list_bar.width = package_case_count[i]*1.4;
				draw_static_scale("static_scale_number",50);
			}
			else if(max_case_count >300 && max_case_count<= 600){
				if(package_case_count[i]*0.7 < 1){
					pb.set('width', 1);
					list_bar.width = 1;
				}
				else{
					pb.set('width', package_case_count[i]*0.7);
					list_bar.width = package_case_count[i]*0.7;
					draw_static_scale("static_scale_number",100);
				}
			}
			else if(max_case_count >600 && max_case_count<= 1200){	
				if(package_case_count[i]*0.24 < 1){
					pb.set('width', 1);
					list_bar.width = 1;
				}
				else{
					pb.set('width', package_case_count[i]*0.24);
					list_bar.width = package_case_count[i]*0.24;
					draw_static_scale("static_scale_number",200);
				}
			}
			else if(max_case_count >1200 && max_case_count<= 2400){		
				if(package_case_count[i]*0.18 < 1){
					pb.set('width', 1);
					list_bar.width = 1;
				}
				else{
					pb.set('width', package_case_count[i]*0.18);
					list_bar.width = package_case_count[i]*0.18;	
					draw_static_scale("static_scale_number",400);	
				}
			}
			else if(max_case_count >2400 && max_case_count<= 4800){
				if(package_case_count[i]*0.09 < 1){
					pb.set('width', 1);
					list_bar.width = 1;
				}
				else{
					pb.set('width', package_case_count[i]*0.09);
					list_bar.width = package_case_count[i]*0.09;
					draw_static_scale("static_scale_number",800);
				}
			}
			else if(max_case_count >4800 && max_case_count<= 9600){
				if(package_case_count[i]*0.042 < 1){
					pb.set('width', 1);
					list_bar.width = 1;
				}
				else{
					pb.set('width', package_case_count[i]*0.042);
				   	list_bar.width = package_case_count[i]*0.042;
				   	draw_static_scale("static_scale_number",1600);	
				}
			}
			else if(max_case_count >9600 && max_case_count<= 19200){
				if(package_case_count[i]*0.021 < 1){
					pb.set('width', 1);
					list_bar.width = 1;
				}
				else{		
					pb.set('width', package_case_count[i]*0.021);		
					list_bar.width = package_case_count[i]*0.021;
					draw_static_scale("static_scale_number",3200);
				}
			}
			else{
				if(package_case_count[i]*0.012 <1){
					pb.set('width', 1);
					list_bar.width = 1;
				}
				else{
					pb.set('width', package_case_count[i]*0.012);
					list_bar.width = package_case_count[i]*0.012;
				}
			}

			pb.set('height', 15);
			//case_number_before
			pb.set('value', 0);
		
			pb.set('anim', true);
			var anim = pb.get('anim');
			anim.duration = 1;
			anim.method = YAHOO.util.Easing.easeBothStrong;
		
			//global_case_number
			pb.set('value', package_case_count[i]);
			list_num.innerHTML = package_case_count[i];
		}
	}
		
	for (var i=0; i<component_number; i++) {
		var list_component_bar = document.getElementById(static_list_component_bar_td[i]);
		var list_component_num = document.getElementById(static_list_component_num[i]);

		if(	component_count[i] == 0){
			list_component_bar.width = 1;
			list_component_num.innerHTML = component_count[i];
		}
		else{
			var pb = new YAHOO.widget.ProgressBar().render(static_list_component_bar[i]);
			pb.set('minValue', 0);
			pb.set('maxValue', component_count[i]);

			if(max_component_count >=0 && max_component_count <= 30){
				pb.set('width', component_count[i]*11.4);
				list_component_bar.width = component_count[i]*11.4;
				draw_static_scale("static_scale_number_component",5);
			}
			else if(max_component_count > 30 && max_component_count<= 60){
				pb.set('width', component_count[i]*5.64);
				list_component_bar.width = component_count[i]*5.64;
				draw_static_scale("static_scale_number_component",10);
			}
			else if(max_component_count > 60 && max_component_count <=120){
				pb.set('width', component_count[i]*2.82);
				list_component_bar.width = component_count[i]*2.82;
				draw_static_scale("static_scale_number_component",20);
			}			
			else if(max_component_count > 120 && max_component_count <= 180){
				pb.set('width', component_count[i]*1.86);
				list_component_bar.width = component_count[i]*1.86;
				draw_static_scale("static_scale_number_component",30);
			}	
			else if(max_component_count > 180 && max_component_count <= 300){
				pb.set('width', component_count[i]*1.14);
				list_component_bar.width = component_count[i]*1.14;
				draw_static_scale("static_scale_number_component",50);
			}	
			else if(max_component_count > 300 && max_component_count <= 600){
				if(component_count[i]*0.51 <1){
					pb.set('width', 1);
					list_component_bar.width = 1;
				}
				else{
					pb.set('width', component_count[i]*0.51);
					list_component_bar.width = component_count[i]*0.51;
					draw_static_scale("static_scale_number_component",100);
				}				
			}	
			else if(max_component_count > 600 && max_component_count <= 1200){
				if(component_count[i]*0.27 <1){
					pb.set('width', 1);
					list_component_bar.width = 1;
				}
				else{
					pb.set('width', component_count[i]*0.27);
					list_component_bar.width = component_count[i]*0.27;
					draw_static_scale("static_scale_number_component",200);
				}
			}			
			else if(max_component_count > 1200 && max_component_count <= 2400){
				if(component_count[i]*0.138 < 1){
					pb.set('width', 1);
					list_component_bar.width = 1;
				}
				else{
					pb.set('width', component_count[i]*0.138);
					list_component_bar.width = component_count[i]*0.138;
					draw_static_scale("static_scale_number_component",400);
				}
			}
			else if(max_component_count > 2400 && max_component_count <= 4800){
				if(component_count[i]*0.072 < 1){
					pb.set('width', 1);
					list_component_bar.width = 1;
				}
				else{
					pb.set('width', component_count[i]*0.072);
					list_component_bar.width = component_count[i]*0.072;
					draw_static_scale("static_scale_number_component",800);
				}
			}
			
			else if(max_component_count > 4800 && max_component_count <= 9600){				
				if(component_count[i]*0.042 <1){
					pb.set('width', c1);
					list_component_bar.width = 1;
				}
				else{
					pb.set('width', component_count[i]*0.042);
					list_component_bar.width = component_count[i]*0.042;
					draw_static_scale("static_scale_number_component",1600);
				}
			}
			else if(max_component_count > 9600 && max_component_count <= 19200){
				if(component_count[i]*0.03 <1 ){
					pb.set('width', 1);
					list_component_bar.width = 1;
				}
				else{
					pb.set('width', component_count[i]*0.03);
					list_component_bar.width = component_count[i]*0.03;
					draw_static_scale("static_scale_number_component",3200);
				}
			}
			else{	
				if(component_count[i]*0.024 < 1){
					pb.set('width', 1);
					list_component_bar.width = 1;
				}
				else{
					pb.set('width', component_count[i]*0.024);
					list_component_bar.width = component_count[i]*0.024;
					draw_static_scale("static_scale_number_component",6400);
				}
			}
			pb.set('height', 15);
			//case_number_before
			pb.set('value', 0);
		
			pb.set('anim', true);
			var anim = pb.get('anim');
			anim.duration = 1;
			anim.method = YAHOO.util.Easing.easeBothStrong;
		
			//global_case_number
			pb.set('value', component_count[i]);
			list_component_num.innerHTML = component_count[i];
		}
	}
	
	//change color
	var color_list = new Array("#BDD484", "#D5B584", "#83D4CE", "#D48483");
	var page = document.getElementsByClassName("yui-pb-bar");
	for ( var i = 0; i < page.length; i++) {
		page[i].style.backgroundColor = color_list[i%4];
	}
	var page = document.getElementsByClassName("yui-pb");
	for ( var i = 0; i < page.length; i++) {
		page[i].style.borderStyle = "none";
	}
}

filter_case_item();

</script>
DATA

sub GetPackageName {
	if ( $_ =~ /^tests\.xml$/ ) {
		my $relative = $File::Find::dir;
		$relative =~ s/$testSuitesPath//g;
		my @temp_package_name = split( "\/", $relative );
		push( @package_name, @temp_package_name );
	}
}

sub ScanPackages {
	$testSuitesPath = $defination_dir;
	find( \&GetPackageName, $testSuitesPath );
}

sub CountPackages {
	while ( $package_name_number < @package_name ) {
		$package_name_number++;
	}
}

sub CreateFilePath {
	my $count = 0;
	while ( $count < $package_name_number ) {
		$testsxml[$count] =
		  $defination_dir . $package_name[$count] . "/tests.xml";
		$count++;
	}
}

sub AnalysisTestsXML {
	my $i                      = 0;
	my $count                  = 0;
	my $category_number_temp   = 0;
	my $test_suite_number_temp = 0;

	my $status_number_temp    = 0;
	my $priority_number_temp  = 0;
	my $type_number_temp      = 0;
	my $component_number_temp = 0;
	my $temp;

	while ( $count < $package_name_number ) {
		open FILE, $testsxml[$count] or die $!;
		while (<FILE>) {
			if ( $_ =~ /<category>(.*?)</ ) {

				$temp = $1;
				if ( $category_number_temp == 0 ) {
					push( @category, $temp );
					$category_number_temp++;
				}
				else {
					for (
						$i = $category_number ;
						$i < ( $category_number + $category_number_temp ) ;
						$i++
					  )
					{
						if ( $category[$i] eq $temp ) {
							last;
						}
						if (
							$i == (
								( $category_number + $category_number_temp ) - 1
							)
						  )
						{
							push( @category, $temp );
							$category_number_temp++;
						}
					}
				}
			}
			if ( $_ =~ /<suite name="(.*?)"/ ) {
				$temp = $1;
				if ( $test_suite_number_temp == 0 ) {
					push( @test_suite, $temp );
					$test_suite_number_temp++;
				}
				else {
					for (
						$i = $test_suite_number ;
						$i < ( $test_suite_number + $test_suite_number_temp ) ;
						$i++
					  )
					{
						if ( $test_suite[$i] eq $temp ) {
							last;
						}
						if (
							$i == (
								(
									$test_suite_number + $test_suite_number_temp
								) - 1
							)
						  )
						{
							push( @test_suite, $temp );
							$test_suite_number_temp++;
						}
					}
				}
			}

			if ( $_ =~ /status="(.*?)"/ ) {
				$temp = $1;
				if ( $status_number_temp == 0 ) {
					push( @status, $temp );
					$status_number_temp++;
				}
				else {
					for (
						$i = $status_number ;
						$i < ( $status_number + $status_number_temp ) ;
						$i++
					  )
					{
						if ( $status[$i] eq $temp ) {
							last;
						}
						if ( $i ==
							( ( $status_number + $status_number_temp ) - 1 ) )
						{
							push( @status, $temp );
							$status_number_temp++;
						}
					}
				}
			}
			if ( $_ =~ / type="(.*?)"/ ) {
				$temp = $1;
				if ( $type_number_temp == 0 ) {
					push( @type, $temp );
					$type_number_temp++;
				}
				else {
					for (
						$i = $type_number ;
						$i < ( $type_number + $type_number_temp ) ;
						$i++
					  )
					{
						if ( $type[$i] eq $temp ) {
							last;
						}
						if (
							$i == ( ( $type_number + $type_number_temp ) - 1 ) )
						{
							push( @type, $temp );
							$type_number_temp++;
						}
					}
				}
			}
			if ( $_ =~ /priority="(.*?)"/ ) {
				$temp = $1;
				if ( $priority_number_temp == 0 ) {
					push( @priority, $temp );
					$priority_number_temp++;
				}
				else {
					for (
						$i = $priority_number ;
						$i < ( $priority_number + $priority_number_temp ) ;
						$i++
					  )
					{
						if ( $priority[$i] eq $temp ) {
							last;
						}
						if (
							$i == (
								( $priority_number + $priority_number_temp ) - 1
							)
						  )
						{
							push( @priority, $temp );
							$priority_number_temp++;
						}
					}
				}
			}
			if ( $_ =~ /component="(.*?)"/ ) {
				$temp = $1;
				if ( $component_number_temp == 0 ) {
					push( @component, $temp );
					$component_number_temp++;
				}
				else {
					for (
						$i = $component_number ;
						$i < ( $component_number + $component_number_temp ) ;
						$i++
					  )
					{
						if ( $component[$i] eq $temp ) {
							last;
						}
						if (
							$i == (
								( $component_number + $component_number_temp ) -
								  1
							)
						  )
						{
							push( @component, $temp );
							$component_number_temp++;
						}
					}
				}
			}
		}
		if ( @category < 1 ) {
			push( @category, "Any Category" );
		}
		push( @category_num,   $category_number_temp );
		push( @test_suite_num, $test_suite_number_temp );

		push( @status_num,    $status_number_temp );
		push( @type_num,      $type_number_temp );
		push( @priority_num,  $priority_number_temp );
		push( @component_num, $component_number_temp );
		$category_number   += $category_number_temp;
		$test_suite_number += $test_suite_number_temp;

		$status_number    += $status_number_temp;
		$type_number      += $type_number_temp;
		$priority_number  += $priority_number_temp;
		$component_number += $component_number_temp;
		$category_number_temp   = 0;
		$test_suite_number_temp = 0;

		$status_number_temp    = 0;
		$type_number_temp      = 0;
		$priority_number_temp  = 0;
		$component_number_temp = 0;
		$count++;
	}
}

sub GetSelectItem {
	my $i     = 0;
	my $j     = 0;
	my $k     = 0;
	my $count = 0;
	my @temp  = ();

	push( @temp, $category[0] );
	for ( $j = 1 ; $j < @category ; $j++ ) {
		for ( $i = 0 ; $i < @temp ; $i++ ) {
			if ( $category[$j] eq $temp[$i] ) {
				last;
			}
			if ( $i == @temp - 1 ) {
				push( @temp, $category[$j] );
			}
		}
	}
	@category_item = sort @temp;
	@temp          = ();

	push( @temp, $test_suite[0] );
	for ( $j = 1 ; $j < @test_suite ; $j++ ) {
		for ( $i = 0 ; $i < @temp ; $i++ ) {
			if ( $test_suite[$j] eq $temp[$i] ) {
				last;
			}
			if ( $i == @temp - 1 ) {
				push( @temp, $test_suite[$j] );
			}
		}
	}
	@test_suite_item = sort @temp;
	@temp            = ();

	push( @temp, $status[0] );
	for ( $j = 1 ; $j < @status ; $j++ ) {
		for ( $i = 0 ; $i < @temp ; $i++ ) {
			if ( $status[$j] eq $temp[$i] ) {
				last;
			}
			if ( $i == @temp - 1 ) {
				push( @temp, $status[$j] );
			}
		}
	}
	@status_item = sort @temp;
	@temp        = ();

	push( @temp, $type[0] );
	for ( $j = 1 ; $j < @type ; $j++ ) {
		for ( $i = 0 ; $i < @temp ; $i++ ) {
			if ( $type[$j] eq $temp[$i] ) {
				last;
			}
			if ( $i == @temp - 1 ) {
				push( @temp, $type[$j] );
			}
		}
	}
	@type_item = sort @temp;
	@temp      = ();

	push( @temp, $priority[0] );
	for ( $j = 1 ; $j < @priority ; $j++ ) {
		for ( $i = 0 ; $i < @temp ; $i++ ) {
			if ( $priority[$j] eq $temp[$i] ) {
				last;
			}
			if ( $i == @temp - 1 ) {
				push( @temp, $priority[$j] );
			}
		}
	}
	@priority_item = sort @temp;
	@temp          = ();

}

sub FilterCaseValue {
	my $one_package_case_count_total = 0;
	my $count_tmp                    = 0;
	my @package_name_tmp             = @package_name;

	foreach (@package_name_tmp) {
		my $package       = $_;
		my $tests_xml_dir = $test_definition_dir . $package . "/tests.xml";
		my $suite_value;
		my $type_value;
		my $case_value;
		my $status_value;
		my $component_value;
		my $priority_value;
		my $category_value;
		my $spec = "none";

		open FILE, $tests_xml_dir or die $!;

		while (<FILE>) {
			if ( $_ =~ /suite.*name="(.*?)"/ ) {
				$suite_value = $1;
			}
			if ( $_ =~
/testcase.*purpose="(.*?)".*type="(.*?)".*status="(.*?)".*component="(.*?)".*priority="(.*?)"/
			  )
			{
				$type_value      = $2;
				$status_value    = $3;
				$component_value = $4;
				$priority_value  = $5;
				$category_value  = "null";
			}

			if ( $_ =~ /\<category\>(.*?)\<\/category\>/ ) {
				my $category_value_tmp;
				$category_value_tmp = $1;
				$category_value = $category_value . "&" . $category_value_tmp;
			}
			if ( $_ =~ /<spec>\[Spec\](.*)/ ) {
				$spec = $1;
				$spec =~ s/&amp;/&/g;
				$spec =~ s/^[\s]+//;
				$spec =~ s/[\s]+$//;
				$spec =~ s/[\s]+/ /g;
				$spec =~ s/&lt;/[/g;
				$spec =~ s/&gt;/]/g;
				$spec =~ s/</[/g;
				$spec =~ s/>/]/g;
				$spec =~ s/\:\s/\:/;
				$spec =~ s/\s\:/\:/;
			}

			if ( $_ =~ /\<\/testcase\>/ ) {
				push( @filter_suite_value,     $suite_value );
				push( @filter_type_value,      $type_value );
				push( @filter_status_value,    $status_value );
				push( @filter_component_value, $component_value );
				push( @filter_priority_value,  $priority_value );
				push( @filter_category_value,  $category_value );
				push( @filter_spec_value,      $spec );
				$one_package_case_count_total++;
			}
		}
		push( @one_package_case_count_total, $one_package_case_count_total );
		$count_tmp++;
	}
	foreach (@filter_suite_value) {
		$case_count_total++;
	}
}

sub DrawCategorySelect {
	my $count = 0;
	print <<DATA;
		<option selected="selected">Any Category</option>
DATA
	if ( $package_name_number != $package_webapi_number ) {
		for ( ; $count < @category_item ; $count++ ) {
			print <<DATA;
		<option>$category_item[$count]</option>
DATA
		}
	}
}

sub DrawTypeSelect {
	my $count = 0;
	print <<DATA;
		<option selected="selected">Any Type</option>
DATA
	for ( ; $count < @type_item ; $count++ ) {
		print <<DATA;
		<option>$type_item[$count]</option>
DATA
	}
}

sub DrawStatusSelect {
	my $count = 0;
	print <<DATA;
		<option selected="selected">Any Status</option>
DATA
	for ( ; $count < @status_item ; $count++ ) {
		print <<DATA;
		<option>$status_item[$count]</option>
DATA
	}
}

sub DrawPrioritySelect {
	my $count = 0;
	print <<DATA;
		<option selected="selected">Any Priority</option>
DATA
	for ( ; $count < @priority_item ; $count++ ) {
		print <<DATA;
		<option>$priority_item[$count]</option>
DATA
	}
}

sub DrawTestsuiteSelect {
	my $count = 0;
	print <<DATA;
		<option selected="selected">Any Test Suite</option>
DATA
	for ( ; $count < @test_suite_item ; $count++ ) {
		print <<DATA;
		<option>$test_suite_item[$count]</option>
DATA
	}
}

sub DrawPackageSelect {
	if (@package_name_webapi) {
		my $count = 0;
		for ( ; $count < @package_name_webapi ; $count++ ) {
			print <<DATA;
		<option>$package_name_webapi[$count]</option>
DATA
		}
	}
	else {
		print <<DATA;
		<option>No webapi package</option>
DATA
	}
}

sub updateStaticSpecList {
	undef %spec_list;
	my ($package) = @_;
	find( \&updateSpecList_wanted, $test_definition_dir . $package );
}

sub updateSpecList_wanted {
	my $dir = $File::Find::name;
	if ( $dir =~ /.*\/tests.xml$/ ) {
		open FILE, $dir or die $!;
		while (<FILE>) {
			if ( $_ =~ /<spec>\[Spec\](.*)/ ) {
				my $spec_name = $1;
				$spec_name =~ s/&amp;/&/g;
				$spec_name =~ s/^[\s]+//;
				$spec_name =~ s/[\s]+$//;
				$spec_name =~ s/[\s]+/ /g;
				$spec_name =~ s/&lt;/[/g;
				$spec_name =~ s/&gt;/]/g;
				$spec_name =~ s/</[/g;
				$spec_name =~ s/>/]/g;
				$spec_name =~ s/\:\s/\:/;
				$spec_name =~ s/\s\:/\:/;

				my @spec_item = split( ":", $spec_name );

				# remove additional space
				foreach (@spec_item) {
					$_ =~ s/^\s*//;
					$_ =~ s/\s*$//;
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

print_footer("");
