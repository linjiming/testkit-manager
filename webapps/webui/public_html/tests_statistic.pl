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
use File::Find;
use FindBin;
use Data::Dumper;
use Digest::SHA qw(sha1_hex);

my $result_dir_manager  = $FindBin::Bin . "/../../../results/";
my $definition_dir      = $FindBin::Bin . "/../../../definition/";
my $test_definition_dir = $definition_dir;

my @package_name                    = ();
my @package_name_webapi             = ();
my @package_webapi_item             = ();
my @package_webapi_item_id          = ();
my @testsxml                        = ();
my @resultsxml                      = ();
my @category                        = ();
my @category_num                    = ();
my @test_suite                      = ();
my @test_suite_num                  = ();
my @status                          = ();
my @status_num                      = ();
my @type                            = ();
my @type_num                        = ();
my @priority                        = ();
my @priority_num                    = ();
my @component                       = ();
my @component_num                   = ();
my @category_item                   = ();
my @test_suite_item                 = ();
my @status_item                     = ();
my @type_item                       = ();
my @priority_item                   = ();
my @component_item                  = ();
my $testSuitesPath                  = "none";
my $package_name_number             = 0;
my $package_webapi_number           = 0;
my $package_webapi_item_num_total   = 0;
my $count_num                       = 0;
my $category_number                 = 0;
my $test_suite_number               = 0;
my $status_number                   = 0;
my $priority_number                 = 0;
my $type_number                     = 0;
my $component_number                = 0;
my $result_file_number              = 0;
my $result_no                       = 0;
my @result_file_name                = ();
my @filter_suite_item               = ();
my @filter_component_item           = ();
my @filter_suite_value              = ();
my @filter_type_value               = ();
my @filter_status_value             = ();
my @filter_component_value          = ();
my @filter_priority_value           = ();
my @filter_spec_value               = ();
my @filter_category_value           = ();
my @filter_result_value             = ();
my @filter_category_key_second      = ();
my @filter_category_key_third       = ();
my @filter_category_key_second_item = ();
my @filter_category_key_third_item  = ();
my $case_count_total                = 0;
my @one_package_case_count_total    = ();
my @one_webapi_package_item_count   = ();
my %spec_list;
my %caseInfo;
my @category_key = get_category_key;

syncDefinition();
if ( $_GET{'case_view'} ) {
	ScanPackages();
	CountPackages();
	CreateFilePath();
	AnalysisTestsXML( $package_name_number, @testsxml );

	if ( $package_name_number > 0 ) {
		GetSelectItem();
		FilterCaseValue( $definition_dir, @package_name );
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
<div id="message"></div>
<table width="768" border="0" cellspacing="0" cellpadding="0" frame="void" rules="all" class="report_list table_normal">
  <tr>
    <td><form id="tests_statistic" name="tests_custom" method="post" action="tests_statistic.pl">
      <table width="100%" border="0" cellspacing="0" cellpadding="0">
		 <tr>
          <td><table width="100%" border="0" cellspacing="0" cellpadding="0" class="top_button_bg">
            <tr>
               <td width="2%" class="custom_line_height" nowrap="nowrap">&nbsp;</td>
               <td width="12%" align="left" nowrap="nowrap" class="custom_line_height">View Statistic</td>
               <td width="6%" align="left" class="custom_line_height"  nowrap="nowrap"><img id="package_bar_chart" src="images/package_bar_chart_selected.png" title="Package Chart" class="statistic_chart_pic_selected"/></td>
               <td width="6%" align="left" class="custom_line_height"  nowrap="nowrap"><img id="package_tree_diagram" src="images/package_tree_diagram.png" title="Tree Diagram (This diaram is generated only for WebAPI packages. The branches are extracted from [Spec] filed inside the tests.xml file.)" class="statistic_tree_pic_unselected"  onclick="javascript:onDrawTree();"/></td>
               <td width="53%" align="left" class="custom_line_height"  nowrap="nowrap"><img id="component_bar_chart" src="images/component_bar_chart.png" title="Component Chart" class="statistic_chart_pic_unselected" onclick="javascript:onDrawComponent();"/></td>
               <td width="10%" align="left" class="custom_line_height"  nowrap="nowrap"><input id="view_test_result" name="view_test_result" type="button" class="medium_button" title="View statistic from result xml" value="Results" onclick=javascript:select_result_file("init")></td>
               <td width="10%" align="left" class="custom_line_height"  nowrap="nowrap"><input id="view_test_case" name="view_test_case" type="button" class="medium_button" title="View statistic from case xml" value="Cases" onclick="javascript:onCaseView()";></td>
               <td width="1%" align="left" class="custom_line_height" nowrap="nowrap">&nbsp;</td>
            </tr>
          </table></td>
        </tr>
               
        <tr>
          <td id="list_advanced" class="custom_panel_background_color"><table width="768" border="1" cellspacing="0" cellpadding="0" frame="void" rules="none">
            <tr>
              <td width="50%" nowrap="nowrap" ><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                    <td width="8%" align="left" class="custom_line_height report_list_no_border">&nbsp;<td>
					<td width="30%" class="custom_line_height"align="left" class="custom_font report_list_no_border">&nbsp;Category</td><td>
                    <select name="select_category" align="20px" id="select_category" class="custom_select" style="width:85%" onchange="javascript:filter_case_item();">
DATA
	DrawCategorySelect();
	print <<DATA;
                    </select>
                    </td>
                </tr>
              </table></td>
              <td width="50%" nowrap="nowrap"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                    <td width="2%" align="left" class="custom_line_height report_list_no_border">&nbsp;<td>
                    <td width="30%" align="left" class="custom_line_height custom_font report_list_no_border">&nbsp;Type</td><td>
                    <select name="select_type" align="20px" id="select_type" class="custom_select" style="width:85%" onchange="javascript:filter_case_item();">
DATA
	DrawTypeSelect();
	print <<DATA;
                    </select>
                    </td>
                </tr>
              </table></td>
            </tr>
            
            <tr>
              <td width="50%" nowrap="nowrap"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                    <td width="8%" align="left" class="custom_line_height report_list_no_border">&nbsp;<td>
                   	<td width="30%" align="left" class="custom_line_height custom_font report_list_no_border">&nbsp;Status</td><td>
                    <select name="select_status" align="20px" id="select_status" class="custom_select" style="width:85%" onchange="javascript:filter_case_item();">
DATA
	DrawStatusSelect();
	print <<DATA;
                    </select>
                    </td>
                </tr>
              </table></td>
              <td width="50%" nowrap="nowrap"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                    <td width="2%" align="left" class="custom_line_height report_list_no_border">&nbsp;<td>
                   	<td width="30%" align="left" class="custom_line_height custom_font report_list_no_border">&nbsp;Priority</td><td>
                    <select name="select_priority" align="20px" id="select_priority" class="custom_select" style="width:85%" onchange="javascript:filter_case_item();">
DATA
	DrawPrioritySelect();
	print <<DATA;
                    </select>
                    </td>
                </tr>
              </table></td>
            </tr>
            
            <tr>
              <td width="50%" nowrap="nowrap"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                    <td width="8%" align="left" class="custom_line_height report_list_no_border">&nbsp;<td>
                   	<td width="30%" align="left" class="custom_line_height custom_font report_list_no_border">&nbsp;Test Suite</td><td>
                    <select name="select_testsuite" align="20px" id="select_testsuite" class="custom_select" style="width:85%" onchange="javascript:filter_case_item();">
DATA
	DrawTestsuiteSelect();
	print <<DATA;
                    </select>
                    </td>
                </tr>
              </table></td>
              
              <td id="select_package_disabled_td" width="50%" nowrap="nowrap" class="custom_bottom"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="all">
                <tr>
                  <td width="100%">&nbsp;</td>
                </tr>
              </table></td>
              
              <td id="select_package_td" width="50%" nowrap="nowrap" style="display:none"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                    <td width="2%" align="left" class="custom_line_height report_list_no_border">&nbsp;<td>
                   	<td width="30%" align="left" class="custom_line_height custom_font report_list_no_border">&nbsp;Package</td><td>
                    <select name="select_package" align="20px" id="select_package" class="custom_select" style="width:85%" onchange="javascript:draw_package_tree();">
DATA
	DrawPackageSelect();
	print <<DATA;
                    </select>
                    </td>
                </tr>
              </table></td>
              
            </tr>
           </table></td>
         </tr>
         
DATA

	print <<DATA;
        <tr id="background_top" style="display:">
	       <td><table width="100%" height="15" border="0" cellspacing="0" cellpadding="0" frame="bellow" rules="all">	
		        <td width="100%" align="right" valign="middle" class="static_list_packagename"></td> 
	       </table></td>
	     </tr>     
DATA

	print <<DATA;
        <tr id="no_webapi_attention_div" class="view_edge_color" style="display:none">
	       <td><table width="100%" height="120" border="0" cellspacing="0" cellpadding="0" frame="void" rules="all">	
		        <td width="100%" align="middle" valign="middle" class="report_list_outside_left_no_height static_chart_select">
		        No webapi packages !</td> 
	       </table></td>
	     </tr>     
DATA

	print <<DATA;
        <tr id="no_pkg_attention_div" class="view_edge_color" style="display:none">
	       <td><table width="100%" height="120" border="0" cellspacing="0" cellpadding="0" frame="void" rules="all">	
		        <td width="100%" align="middle" valign="middle" class="report_list_outside_left_no_height static_chart_select">
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
	       <td><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="$frame" rules="all" class="custom_line_height table_normal">	
		        <td width="25%" align="right" class="static_list_packagename cut_long_string_one_line" title="$package_name[$count]">$package_name[$count]</td>
		        <td width="3%" class="static_list_packagename">&nbsp;</td> 
		        <td id="static_list_bar_td_$package_name[$count]" align="left" class="static_list_count_bar " ><span id="static_list_bar_$package_name[$count]"></span></td>
		        <td width="1%" class="static_list_num">&nbsp;</td>  
		        <td id="static_list_num_$package_name[$count]" align="left" class="static_list_num" ><span id="static_list_num_$package_name[$count]"></span></td> 
		        <td width="12%" class="static_list_packagename">&nbsp;</td>      
	       </table></td>
	      </tr>
DATA
	}

	print <<DATA;
        <tr id="background_top1" style="display:">
	       <td><table width="100%" height="8" border="0" cellspacing="0" cellpadding="0" frame="below" rules="all">	
		        <td width="100%" align="right" valign="middle" class="static_list_packagename"></td> 
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
	       		<td width="28%" align="left" class="report_list_no_border "></td>
		        <td width="8%" id="static_scale_number0" align="left" valign="middle" class="report_list_no_border "></td> 
		        <td width="9%" id="static_scale_number1" align="left" valign="middle" class="report_list_no_border "></td> 
		        <td width="9%" id="static_scale_number2" align="left" valign="middle" class="report_list_no_border "></td> 
		        <td width="9%" id="static_scale_number3" align="left" valign="middle" class="report_list_no_border "></td> 
		        <td width="9%" id="static_scale_number4" align="left" valign="middle" class="report_list_no_border "></td> 
		        <td width="9%" id="static_scale_number5" align="left" valign="middle" class="report_list_no_border "></td> 
		        <td width="19%" id="static_scale_number6"class="report_list_no_border "></td>
	       </table></td>
	     </tr>  
DATA

	my $one_webapi_package_item_count = 0;
	for ( my $count = 0 ; $count < $package_webapi_number ; $count++ ) {
		print <<DATA;
             <tr id="tree_area_$package_name_webapi[$count]" style="display:none">
              	<td><table width="100%" class="custom_line_height"  border="0" cellspacing="0" cellpadding="0" rules="all">
              	<tr>
              		<td width="21%" class="static_bg_pic static_list_packagename"></td>
                	<td width="31%" align="left" valign="top" class="static_list_packagename static_tree_bg_color">
                  	<div id="tree_area_test_type_$package_name_webapi[$count]" style="background:transparent;display:"></div></td>
                  	<td width="21%" align="right" class="static_bg_pic static_list_packagename" ></td>
                 </tr>
                 </table></td>
               </tr>
<script language="javascript" type="text/javascript">
// <![CDATA[
// test type tree
\$(function() {
	\$("#tree_area_test_type_$package_name_webapi[$count]").bind("click.jstree", function(event) {
		// filter leaves
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
					print "+ \"<item id='SP_" . sha1_hex($parent) . "'>\"\n";
					print "+ \"<content><name>" 
					  . $item
					  . '<span id=\'SP_'
					  . $count
					  . sha1_hex($parent)
					  . '\' class=\'static_tree_count\'></span>'
					  . "</name></content>\"\n";
					print "+ \"</item>\"\n";
					push( @package_webapi_item, $item );
					push( @package_webapi_item_id,
						'SP_' . $count . sha1_hex($parent) );
					$one_webapi_package_item_count++;
					$package_webapi_item_num_total++;
				}
				else {
					print "+ \"<item id='SP_"
					  . sha1_hex( $parent . ':' . $item )
					  . "' parent_id='SP_"
					  . sha1_hex($parent)
					  . "'>\"\n";
					print "+ \"<content><name>" 
					  . $item
					  . '<span id=\'SP_'
					  . $count
					  . sha1_hex( $parent . ':' . $item )
					  . '\' class=\'static_tree_count\'></span>'
					  . "</name></content>\"\n";
					print "+ \"</item>\"\n";
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
	+ "</root>"
				},
				"plugins" : [ "themes", "xml_data", "ui" ]
			});
	});
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
	       <td><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="$frame" rules="all" class="custom_line_height table_normal">	
		        <td width="35%" align="right" class="static_list_packagename" class="cut_long_string_one_line" title="$component[$count]">$component[$count]</td>
		        <td width="3%" class="static_list_packagename">&nbsp;</td> 
		        <td id="static_list_component_bar_td_$component[$count]" align="left" class="static_list_count_bar" ><span id="static_list_component_bar_$component[$count]"></span></td>
		        <td width="1%" class="static_list_num">&nbsp;</td>  
		        <td id="static_list_component_num_$component[$count]" align="left" class="static_list_num" ><span id="static_list_component_num_$component[$count]"></span></td> 
		        <td width="12%" class="static_list_packagename">&nbsp;</td>      
	       </table></td>
	      </tr>
DATA
	}

	print <<DATA;
        <tr id="background_top2" style="display:none">
	       <td><table width="100%" height="8" border="0" cellspacing="0" cellpadding="0" frame="below" rules="all">	
		        <td width="100%" align="right" valign="middle" class="static_list_packagename"></td> 
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
	       		<td width="38%" align="left" class="report_list_no_border "></td>
		        <td width="6.5%" id="static_scale_number_component0" align="left" valign="middle" class="report_list_no_border "></td> 
		        <td width="7.5%" id="static_scale_number_component1" align="left" valign="middle" class="report_list_no_border "></td> 
		        <td width="7.5%" id="static_scale_number_component2" align="left" valign="middle" class="report_list_no_border "></td> 
		        <td width="7.5%" id="static_scale_number_component3" align="left" valign="middle" class="report_list_no_border "></td> 
		        <td width="7.5%" id="static_scale_number_component4" align="left" valign="middle" class="report_list_no_border "></td> 
		        <td width="7.5%" id="static_scale_number_component5" align="left" valign="middle" class="report_list_no_border "></td> 
		        <td width="20%" id="static_scale_number_component6" class="report_list_no_border "></td>
	       </table></td>
	     </tr>  
DATA

	print <<DATA;
        <tr id="background_bottom" style="display:">
	       <td><table width="100%" height="25" border="0" cellspacing="0" cellpadding="0" frame="void" rules="all">	
		        <td width="100%" align="right" valign="middle" class=""></td> 
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

}
else {
	if ( $_GET{'result_file'} ) {
		$result_no = $_GET{'result_file'} - 1;
	}
	else {
		$result_no = 0;
	}
	ScanResultFile();
	CountResultFiles();
	CreateResultFilePath();

	if ( $result_file_number > 0 ) {
		AnalysisTestsXML( 1, $resultsxml[$result_no] );
		GetSelectItem();
		FilterCaseValue( $result_dir_manager, $result_file_name[$result_no] );
	}

	print "HTTP/1.0 200 OK" . CRLF;
	print "Content-type: text/html" . CRLF . CRLF;

	print_header( "$MTK_BRANCH Manager Main Page", "statistic" );
	print <<DATA;
<div id="ajax_loading" style="display:none"></div>
<div id="message"></div>
<table width="768" border="0" cellspacing="0" cellpadding="0" frame="void" rules="all" class="report_list table_normal">
  <tr>
    <td><form id="tests_statistic" name="tests_custom" method="post" action="tests_statistic.pl">
      <table width="100%" border="0" cellspacing="0" cellpadding="0">
     	
		 <tr>
          <td><table width="100%" border="0" cellspacing="0" cellpadding="0" class="top_button_bg">
            <tr>
               <td width="2%" class="custom_line_height" nowrap="nowrap">&nbsp;</td>
               <td width="83%" align="left" class="custom_line_height" nowrap="nowrap">View Statistic</td>
               <td width="5%" align="left" class="custom_line_height" nowrap="nowrap"><img id="package_bar_chart" src="images/package_bar_chart_selected.png" title="Package Chart" class="statistic_chart_pic_selected" onclick=""/></td>
               <td width="5%" align="left" class="custom_line_height" nowrap="nowrap"><img id="component_bar_chart" src="images/component_bar_chart.png" title="Component Chart" class="statistic_chart_pic_unselected" onclick="javascript:onDrawResultComponent();"/></td>
               <td width="5%" align="left" class="custom_line_height" nowrap="nowrap"><img id="spec_bar_chart" src="images/package_tree_diagram.png" title="Spec Chart" class="statistic_tree_pic_unselected" onclick="javascript:onDrawResultSpec();"/></td>
               <td width="0%" align="left" class="custom_line_height" nowrap="nowrap" style="display:none"><input id="view_test_result" name="view_test_result" type="button" class="medium_button" title="View statistic from result xml" value="Results" onclick=javascript:select_result_file("init");></td>
               <td width="0%" align="left" class="custom_line_height" nowrap="nowrap" style="display:none"><input id="view_test_case" name="view_test_case" type="button" class="medium_button" title="View statistic from case xml" value="Cases" onclick="javascript:onCaseView();"></td>
               <td width="0%" align="left" class="custom_line_height" nowrap="nowrap" style="display:none">&nbsp;</td>
            </tr>
          </table></td>
        </tr>
               
        <tr>
          <td id="list_advanced" class="custom_panel_background_color"><table width="768" border="1" cellspacing="0" cellpadding="0" frame="void" rules="none">
            <tr>
              <td width="100%" nowrap="nowrap" colspan="2"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                    <td width="4%" align="left" class="custom_line_height report_list_no_border">&nbsp;<td>
                    <td width="15%" align="left" class="custom_line_height custom_font report_list_no_border">&nbsp;Test Time</td><td>
                    <select name="select_result" align="20px" id="select_result" class="custom_select" style="width:96%" onchange="javascript:select_result_file();">
DATA
	DrawResultSelect();
	print <<DATA;
                    </select>
                    </td>
                  <td width="2%">&nbsp;</td>
                </tr>
              </table></td>
            </tr>
            
            <tr>
              <td width="50%" nowrap="nowrap"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                    <td width="8%" align="left" class="custom_line_height report_list_no_border">&nbsp;<td>
                    <td width="30%" align="left" class="custom_line_height custom_font report_list_no_border">&nbsp;Category</td><td>
                    <select name="select_category" align="20px" id="select_category" class="custom_select" style="width:85%" onchange="javascript:filter_result_item();">
DATA
	DrawCategorySelect();
	print <<DATA;
                    </select>
                    </td>
                </tr>
              </table></td>
              <td width="50%" nowrap="nowrap"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                    <td width="2%" align="left" class="custom_line_height report_list_no_border">&nbsp;<td>
                    <td width="30%" align="left" class="custom_line_height custom_font report_list_no_border">&nbsp;Type</td><td>
                    <select name="select_type" align="20px" id="select_type" class="custom_select" style="width:85%" onchange="javascript:filter_result_item();">
DATA
	DrawTypeSelect();
	print <<DATA;
                    </select>
                    </td>
                </tr>
              </table></td>
            </tr>
            
            <tr>
              <td width="50%" nowrap="nowrap"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                    <td width="8%" align="left" class="custom_line_height report_list_no_border">&nbsp;<td>
                   	<td width="30%" align="left" class="custom_line_height custom_font report_list_no_border">&nbsp;Status</td><td>
                    <select name="select_status" align="20px" id="select_status" class="custom_select" style="width:85%" onchange="javascript:filter_result_item();">
DATA
	DrawStatusSelect();
	print <<DATA;
                    </select>
                    </td>
                </tr>
              </table></td>
              <td width="50%" nowrap="nowrap"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                    <td width="2%" align="left" class="custom_line_height report_list_no_border">&nbsp;<td>
                   	<td width="30%" align="left" class="custom_line_height custom_font report_list_no_border">&nbsp;Priority</td><td>
                    <select name="select_priority" align="20px" id="select_priority" class="custom_select" style="width:85%" onchange="javascript:filter_result_item();">
DATA
	DrawPrioritySelect();
	print <<DATA;
                    </select>
                    </td>
                </tr>
              </table></td>
            </tr>
            
            <tr>
              <td width="50%" nowrap="nowrap"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                    <td width="8%" align="left" class="custom_line_height report_list_no_border">&nbsp;<td>
                   	<td width="30%" align="left" class="custom_line_height custom_font report_list_no_border">&nbsp;Test Suite</td><td>
                    <select name="select_testsuite" align="20px" id="select_testsuite" class="custom_select" style="width:85%" onchange="javascript:filter_result_item();">
DATA
	DrawResultsuiteSelect();
	print <<DATA;
                    </select>
                    </td>
                </tr>
              </table></td>
              
              <td id="td_category_key_null" width="50%" nowrap="nowrap" class="custom_bottom" style="display:"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="100%">&nbsp;</td>
                </tr>
              </table></td>
              
              <td id="td_category_key" width="50%" nowrap="nowrap" style="display:none"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="2%" align="left" class="custom_line_height report_list_no_border">&nbsp;<td>
                  <td width="30%" align="left" class="custom_line_height custom_font report_list_no_border">&nbsp;Spec</td><td>
                    <select name="select_category_key" align="20px" id="select_category_key" class="custom_select" style="width:85%" onchange="javascript:filter_result_item();">
DATA
	DrawCategoryKeySelect();
	print <<DATA;
                    </select>
                    </td>
                </tr>
              </table></td>
             </tr>
           </table></td>
         </tr>
         
DATA

	print <<DATA;
        <tr id="background_top" style="display:">
	       <td><table width="100%" height="15" border="0" cellspacing="0" cellpadding="0" frame="bellow" rules="all">	
		        <td width="100%" align="right" valign="middle" class="static_list_packagename"></td> 
	       </table></td>
	     </tr>     
DATA

	print <<DATA;
        <tr id="no_pkg_attention_div" class="view_edge_color" style="display:none">
	       <td><table width="100%" height="120" border="0" cellspacing="0" cellpadding="0" frame="void" rules="all">	
		        <td width="100%" align="middle" valign="middle" class="report_list_outside_left_no_height static_chart_select">
		        No result files !</td> 
	       </table></td>
	     </tr>     
DATA

	for ( my $count = 0 ; $count < @filter_suite_item ; $count++ ) {
		my $frame;
		if ( $count eq "0" ) {
			$frame = "hsides";
		}
		else {
			$frame = "below";
		}
		print <<DATA;
	     <tr id="static_list_$filter_suite_item[$count]" style="display:">
	       <td><table width="100%" class="custom_line_height"  border="0" cellspacing="0" cellpadding="0" frame="$frame" rules="all" class="table_normal">	
		        <td width="25%" align="right" class="custom_line_height static_list_packagename" class="cut_long_string_one_line" title="$filter_suite_item[$count]">$filter_suite_item[$count]</td>
		        <td width="3%" class="custom_line_height static_list_packagename">&nbsp;</td> 
		        <td id="static_list_bar_td_$filter_suite_item[$count]" align="left" class="custom_line_height static_list_count_bar" ><span id="static_list_bar_$filter_suite_item[$count]"></span></td>
		        <td width="1%" class="custom_line_height static_list_num">&nbsp;</td>  
		        <td id="static_list_num_$filter_suite_item[$count]" align="left" class="custom_line_height static_list_num" ><span id="static_list_num_$filter_suite_item[$count]"></span></td> 
		        <td width="12%" class="custom_line_height  static_list_packagename ">&nbsp;</td>      
	       </table></td>
	      </tr>
DATA
	}

	print <<DATA;
        <tr id="background_top1" style="display:">
	       <td><table width="100%" height="8" border="0" cellspacing="0" cellpadding="0" frame="bellow" rules="all">	
		        <td width="100%" align="right" valign="middle" class="static_list_packagename"></td> 
	       </table></td>
	     </tr>  
DATA

	print <<DATA;
        <tr id="static_scale" style="display:">
	       <td><table width="100%" height="8" border="1" cellspacing="0" cellpadding="0" frame="below" rules="all">
	       		<td width="27.5%" align="right" class="static_list_scale_head"></td>
		        <td width="5.4%" align="right" valign="middle" class="static_list_scale"></td> 
		        <td width="5.4%" align="right" valign="middle" class="static_list_scale"></td>
		        <td width="5.4%" align="right" valign="middle" class="static_list_scale"></td>
		        <td width="5.4%" align="right" valign="middle" class="static_list_scale"></td>
		        <td width="5.4%" align="right" valign="middle" class="static_list_scale"></td>
		        <td width="5.4%" align="right" valign="middle" class="static_list_scale"></td>
		        <td width="5.4%" align="right" valign="middle" class="static_list_scale"></td>
		        <td width="5.4%" align="right" valign="middle" class="static_list_scale"></td>
		        <td width="5.4%" align="right" valign="middle" class="static_list_scale"></td>
		        <td width="5.4%" align="right" valign="middle" class="static_list_scale"></td>
		        <td width="18%" class="static_list_scale_head"></td>
	       </table></td>
	     </tr>  
DATA

	print <<DATA;
        <tr id="static_scale_number" style="display:">
	       <td><table width="100%" height="8" border="1" cellspacing="0" cellpadding="0" frame="void" rules="all">
	       		<td width="28%" align="left" class="report_list_no_border "></td>
		        <td width="4.4%" id="static_scale_number0" align="left" valign="middle" class="report_list_no_border ">0</td> 
		        <td width="5.4%" id="static_scale_number1" align="left" valign="middle" class="report_list_no_border ">10</td> 
		        <td width="5.4%" id="static_scale_number2" align="left" valign="middle" class="report_list_no_border ">20</td> 
		        <td width="5.4%" id="static_scale_number3" align="left" valign="middle" class="report_list_no_border ">30</td> 
		        <td width="5.4%" id="static_scale_number4" align="left" valign="middle" class="report_list_no_border ">40</td> 
		        <td width="5.4%" id="static_scale_number5" align="left" valign="middle" class="report_list_no_border ">50</td>
		        <td width="5.4%" id="static_scale_number6" align="left" valign="middle" class="report_list_no_border ">60</td> 
		        <td width="5.4%" id="static_scale_number7" align="left" valign="middle" class="report_list_no_border ">70</td> 
		        <td width="5.4%" id="static_scale_number8" align="left" valign="middle" class="report_list_no_border ">80</td> 
		        <td width="5.4%" id="static_scale_number9" align="left" valign="middle" class="report_list_no_border ">90</td>  
		        <td width="19%" id="static_scale_number10"class=" report_list_no_border ">100&nbsp;(%)</td>
	       </table></td>
	     </tr>  
DATA

	for ( my $count = 0 ; $count < @filter_component_item ; $count++ ) {
		my $frame;
		if ( $count eq "0" ) {
			$frame = "hsides";
		}
		else {
			$frame = "below";
		}
		print <<DATA;
	     <tr id="static_list_component_$filter_component_item[$count]" style="display:none">
	       <td><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="$frame" rules="all" class="custom_line_height table_normal">	
		        <td width="35%" align="right" class="custom_line_height  static_list_packagename " class="cut_long_string_one_line" title="$filter_component_item[$count]">$filter_component_item[$count]</td>
		        <td width="3%" class="custom_line_height  static_list_packagename ">&nbsp;</td> 
		        <td id="static_list_component_bar_td_$filter_component_item[$count]" align="left" class="custom_line_height  static_list_count_bar " ><span id="static_list_component_bar_$filter_component_item[$count]"></span></td>
		        <td width="1%" class="custom_line_height  static_list_num ">&nbsp;</td>  
		        <td id="static_list_component_num_$filter_component_item[$count]" align="left" class="custom_line_height  static_list_num " ><span id="static_list_component_num_$filter_component_item[$count]"></span></td> 
		        <td width="12%" class="custom_line_height  static_list_packagename ">&nbsp;</td>      
	       </table></td>
	      </tr>
DATA
	}

	print <<DATA;
        <tr id="background_top2" style="display:none">
	       <td><table width="100%" height="8" border="0" cellspacing="0" cellpadding="0" frame="bellow" rules="all">	
		        <td width="100%" align="right" valign="middle" class="static_list_packagename"></td> 
	       </table></td>
	     </tr>  
DATA

	print <<DATA;
        <tr id="static_scale_component" style="display:none">
	       <td><table width="100%" height="8" border="0" cellspacing="0" cellpadding="0" frame="below" rules="all">
	       		<td width="38%" align="right" class="static_list_scale_head"></td>
		        <td width="4.5%" align="right" valign="middle" class="static_list_scale"></td> 
		        <td width="4.5%" align="right" valign="middle" class="static_list_scale"></td>
		        <td width="4.5%" align="right" valign="middle" class="static_list_scale"></td>
		        <td width="4.5%" align="right" valign="middle" class="static_list_scale"></td>
		        <td width="4.5%" align="right" valign="middle" class="static_list_scale"></td>
		        <td width="4.5%" align="right" valign="middle" class="static_list_scale"></td>
		        <td width="4.5%" align="right" valign="middle" class="static_list_scale"></td>
		        <td width="4.5%" align="right" valign="middle" class="static_list_scale"></td>
		        <td width="4.5%" align="right" valign="middle" class="static_list_scale"></td>
		        <td width="4.5%" align="right" valign="middle" class="static_list_scale"></td>
		        <td width="19%" class="static_list_scale_head"></td>
	       </table></td>
	     </tr>  
DATA

	print <<DATA;
        <tr id="static_scale_number_component" style="display:none">
	       <td><table width="100%" height="8" border="0" cellspacing="0" cellpadding="0" frame="void" rules="all">
	       		<td width="38%" align="left" class="report_list_no_border "></td>
		        <td width="4.4%" align="left" valign="middle" class="report_list_no_border">0</td> 
		        <td width="4.4%" align="left" valign="middle" class="report_list_no_border ">10</td> 
		        <td width="4.4%" align="left" valign="middle" class="report_list_no_border ">20</td> 
		        <td width="4.4%" align="left" valign="middle" class="report_list_no_border ">30</td> 
		        <td width="4.4%" align="left" valign="middle" class="report_list_no_border ">40</td> 
		        <td width="4.4%" align="left" valign="middle" class="report_list_no_border ">50</td> 
		        <td width="4.4%" align="left" valign="middle" class="report_list_no_border ">60</td>
		        <td width="4.4%" align="left" valign="middle" class="report_list_no_border ">70</td>
		        <td width="4.4%" align="left" valign="middle" class="report_list_no_border ">80</td>
		        <td width="4.4%" align="left" valign="middle" class="report_list_no_border ">90</td>
		        <td width="20%" class="report_list_no_border ">100 &nbsp;(%)</td>
	       </table></td>
	     </tr>  
DATA

	if ( @filter_suite_item > 0 ) {
		my $count = 0;
		for ( $count = 0 ; $count < @category_key ; $count++ ) {
			my $frame;
			if ( $count eq "0" ) {
				$frame = "hsides";
			}
			else {
				$frame = "below";
			}
			print <<DATA;
	     <tr id="static_list_category_key_$count" style="display:none">
	       <td><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="$frame" rules="all" class="custom_line_height table_normal">	
		        <td width="35%" align="right" class="custom_line_height static_list_packagename" class="cut_long_string_one_line" title="$category_key[$count]">$category_key[$count]</td>
		        <td width="3%" class="custom_line_height  static_list_packagename ">&nbsp;</td> 
		        <td id="static_list_category_key_bar_td_$count" align="left" class="custom_line_height  static_list_count_bar " ><span id="static_list_category_key_bar_$count"></span></td>
		        <td width="1%" class="custom_line_height  static_list_num ">&nbsp;</td>  
		        <td id="static_list_category_key_num_$count" align="left" class="custom_line_height  static_list_num " ><span id="static_list_category_key_num_$count"></span></td> 
		        <td width="12%" class="custom_line_height  static_list_packagename ">&nbsp;</td>      
	       </table></td>
	      </tr>
DATA
			for ( my $j = 0 ; $j < @filter_category_key_second_item ; $j++ ) {
				if ( $filter_category_key_second_item[$j] =~
					/$category_key[$count]/ )
				{
					my @second_key =
					  split( ":", $filter_category_key_second_item[$j] );
					print <<DATA;
	     <tr id="static_list_category_key_second_$filter_category_key_second_item[$j]" style="display:none">
	       <td><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="$frame" rules="all" class="custom_line_height table_normal">	
		        <td width="35%" align="right" class="custom_line_height  static_list_packagename_second " class="cut_long_string_one_line" title="$second_key[1]">$second_key[1]</td>
		        <td width="3%" class="custom_line_height  static_list_packagename ">&nbsp;</td> 
		        <td id="static_list_bar_td_category_key_second_$filter_category_key_second_item[$j]" align="left" class="custom_line_height  static_list_count_bar " ><span id="static_list_bar_category_key_second_$filter_category_key_second_item[$j]"></span></td>
		        <td width="1%" class="custom_line_height  static_list_num ">&nbsp;</td>  
		        <td id="static_list_num_category_key_second_$filter_category_key_second_item[$j]" align="left" class="custom_line_height  static_list_num " ><span id="static_list_num_category_key_second_$filter_category_key_second_item[$j]"></span></td> 
		        <td width="12%" class="custom_line_height  static_list_packagename ">&nbsp;</td>      
	       </table></td>
	      </tr>
DATA
					for (
						my $k = 0 ;
						$k < @filter_category_key_third_item ;
						$k++
					  )
					{
						my $second_temp = $filter_category_key_second_item[$j];
						my $third_temp  = $filter_category_key_third_item[$k];
						$second_temp =~ s/\(/XXX/g;
						$second_temp =~ s/\)/XXX/g;
						$second_temp =~ s/\,/OOO/g;
						$second_temp =~ s/\//MMM/g;
						$third_temp  =~ s/\(/XXX/g;
						$third_temp  =~ s/\)/XXX/g;
						$third_temp  =~ s/\,/OOO/g;
						$third_temp  =~ s/\//MMM/g;

						if ( $third_temp =~ /$second_temp/ ) {
							my @third_key =
							  split( ":", $filter_category_key_third_item[$k] );
							print <<DATA;
			     <tr id="static_list_category_key_third_$filter_category_key_third_item[$k]" style="display:none">
			       <td><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="$frame" rules="all" class="custom_line_height table_normal">	
				        <td width="35%" align="right" class="custom_line_height  static_list_packagename_third" class="cut_long_string_one_line" title="$third_key[2]">$third_key[2]</td>
				        <td width="3%" class="custom_line_height  static_list_packagename ">&nbsp;</td> 
				        <td id="static_list_bar_td_category_key_third_$filter_category_key_third_item[$k]" align="left" class="custom_line_height  static_list_count_bar " ><span id="static_list_bar_category_key_third_$filter_category_key_third_item[$k]"></span></td>
				        <td width="1%" class="custom_line_height  static_list_num ">&nbsp;</td>  
				        <td id="static_list_num_category_key_third_$filter_category_key_third_item[$k]" align="left" class="custom_line_height  static_list_num " ><span id="static_list_num_category_key_third_$filter_category_key_third_item[$k]"></span></td> 
				        <td width="12%" class="custom_line_height  static_list_packagename ">&nbsp;</td>      
			       </table></td>
			      </tr>
DATA
						}
					}
				}
			}
		}

		print <<DATA;
        <tr id="background_top2" style="display:">
	       <td><table width="100%" height="8" border="0" cellspacing="0" cellpadding="0" frame="bellow" rules="all">	
		        <td width="100%" align="right" valign="middle" class="static_list_packagename"></td> 
	       </table></td>
	     </tr>  
DATA

		print <<DATA;
        <tr id="static_scale_category_key" style="display:none">
	       <td><table width="100%" height="8" border="0" cellspacing="0" cellpadding="0" frame="below" rules="all">
	       		<td width="38%" align="right" class="static_list_scale_head"></td>
		        <td width="4.5%" align="right" valign="middle" class="static_list_scale"></td> 
		        <td width="4.5%" align="right" valign="middle" class="static_list_scale"></td>
		        <td width="4.5%" align="right" valign="middle" class="static_list_scale"></td>
		        <td width="4.5%" align="right" valign="middle" class="static_list_scale"></td>
		        <td width="4.5%" align="right" valign="middle" class="static_list_scale"></td>
		        <td width="4.5%" align="right" valign="middle" class="static_list_scale"></td>
		        <td width="4.5%" align="right" valign="middle" class="static_list_scale"></td>
		        <td width="4.5%" align="right" valign="middle" class="static_list_scale"></td>
		        <td width="4.5%" align="right" valign="middle" class="static_list_scale"></td>
		        <td width="4.5%" align="right" valign="middle" class="static_list_scale"></td>
		        <td width="19%" class="static_list_scale_head"></td>
	       </table></td>
	     </tr>  
DATA

		print <<DATA;
        <tr id="static_scale_number_category_key" style="display:none">
	       <td><table width="100%" height="8" border="0" cellspacing="0" cellpadding="0" frame="void" rules="all">
	       		<td width="38%" align="left" class="report_list_no_border "></td>
		        <td width="4.4%" align="left" valign="middle" class="report_list_no_border ">0</td> 
		        <td width="4.4%" align="left" valign="middle" class="report_list_no_border ">10</td> 
		        <td width="4.4%" align="left" valign="middle" class="report_list_no_border ">20</td> 
		        <td width="4.4%" align="left" valign="middle" class="report_list_no_border ">30</td> 
		        <td width="4.4%" align="left" valign="middle" class="report_list_no_border ">40</td> 
		        <td width="4.4%" align="left" valign="middle" class="report_list_no_border ">50</td> 
		        <td width="4.4%" align="left" valign="middle" class="report_list_no_border ">60</td>
		        <td width="4.4%" align="left" valign="middle" class="report_list_no_border ">70</td>
		        <td width="4.4%" align="left" valign="middle" class="report_list_no_border ">80</td>
		        <td width="4.4%" align="left" valign="middle" class="report_list_no_border ">90</td>
		        <td width="20%" class="report_list_no_border ">100 &nbsp;(%)</td>
	       </table></td>
	     </tr>  
DATA
	}

	print <<DATA;
        <tr id="background_bottom" style="display:">
	       <td><table width="100%" height="25" border="0" cellspacing="0" cellpadding="0" frame="void" rules="all">	
		        <td width="100%" align="right" valign="middle" class=""></td> 
	       </table></td>
	     </tr>  
DATA

	if ( @filter_suite_item ne "0" ) {
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
	document.getElementById("background_top").style.display = "none";
	document.getElementById("background_bottom").style.display = "none";
	document.getElementById("static_scale").style.display = "none";
	document.getElementById("static_scale_number").style.display = "none";
	
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
}

print <<DATA;
<script language="javascript" type="text/javascript">

var package_name_number = 
DATA
print $package_name_number. ";";

print <<DATA;
var case_count_total = 
DATA
print $case_count_total. ";";

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
var static_list_bar_result = new Array(
DATA
for ( $count_num = 0 ; $count_num < @filter_suite_item ; $count_num++ ) {
	if ( $count_num == @filter_suite_item - 1 ) {
		print '"' . "static_list_bar_" . $filter_suite_item[$count_num] . '"';
	}
	else {
		print '"'
		  . "static_list_bar_"
		  . $filter_suite_item[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);
DATA

print <<DATA;
var static_list_bar_component_result = new Array(
DATA
for ( $count_num = 0 ; $count_num < @filter_component_item ; $count_num++ ) {
	if ( $count_num == @filter_component_item - 1 ) {
		print '"'
		  . "static_list_component_bar_"
		  . $filter_component_item[$count_num] . '"';
	}
	else {
		print '"'
		  . "static_list_component_bar_"
		  . $filter_component_item[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);
DATA

print <<DATA;
var static_list_bar_category_key_result = new Array(
DATA
for ( $count_num = 0 ; $count_num < @category_key ; $count_num++ ) {
	if ( $count_num == @category_key - 1 ) {
		print '"' . "static_list_category_key_bar_" . $count_num . '"';
	}
	else {
		print '"' . "static_list_category_key_bar_" . $count_num . '"' . ",";
	}
}
print <<DATA;
	);
DATA

print <<DATA;
var static_list_bar_category_key_second_result = new Array(
DATA
for (
	$count_num = 0 ;
	$count_num < @filter_category_key_second_item ;
	$count_num++
  )
{
	if ( $count_num == @filter_category_key_second_item - 1 ) {
		print '"'
		  . "static_list_bar_category_key_second_"
		  . $filter_category_key_second_item[$count_num] . '"';
	}
	else {
		print '"'
		  . "static_list_bar_category_key_second_"
		  . $filter_category_key_second_item[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);
DATA

print <<DATA;
var static_list_bar_category_key_third_result = new Array(
DATA
for (
	$count_num = 0 ;
	$count_num < @filter_category_key_third_item ;
	$count_num++
  )
{
	if ( $count_num == @filter_category_key_third_item - 1 ) {
		print '"'
		  . "static_list_bar_category_key_third_"
		  . $filter_category_key_third_item[$count_num] . '"';
	}
	else {
		print '"'
		  . "static_list_bar_category_key_third_"
		  . $filter_category_key_third_item[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);
DATA

print <<DATA;
var static_list_bar_td_category_key_second_result = new Array(
DATA
for (
	$count_num = 0 ;
	$count_num < @filter_category_key_second_item ;
	$count_num++
  )
{
	if ( $count_num == @filter_category_key_second_item - 1 ) {
		print '"'
		  . "static_list_bar_td_category_key_second_"
		  . $filter_category_key_second_item[$count_num] . '"';
	}
	else {
		print '"'
		  . "static_list_bar_td_category_key_second_"
		  . $filter_category_key_second_item[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);
DATA

print <<DATA;
var static_list_bar_td_category_key_third_result = new Array(
DATA
for (
	$count_num = 0 ;
	$count_num < @filter_category_key_third_item ;
	$count_num++
  )
{
	if ( $count_num == @filter_category_key_third_item - 1 ) {
		print '"'
		  . "static_list_bar_td_category_key_third_"
		  . $filter_category_key_third_item[$count_num] . '"';
	}
	else {
		print '"'
		  . "static_list_bar_td_category_key_third_"
		  . $filter_category_key_third_item[$count_num] . '"' . ",";
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
var static_list_num_result = new Array(
DATA
for ( $count_num = 0 ; $count_num < @filter_suite_item ; $count_num++ ) {
	if ( $count_num == @filter_suite_item - 1 ) {
		print '"' . "static_list_num_" . $filter_suite_item[$count_num] . '"';
	}
	else {
		print '"'
		  . "static_list_num_"
		  . $filter_suite_item[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);
DATA

print <<DATA;
var static_list_num_component_result = new Array(
DATA
for ( $count_num = 0 ; $count_num < @filter_component_item ; $count_num++ ) {
	if ( $count_num == @filter_component_item - 1 ) {
		print '"'
		  . "static_list_component_num_"
		  . $filter_component_item[$count_num] . '"';
	}
	else {
		print '"'
		  . "static_list_component_num_"
		  . $filter_component_item[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);
DATA

print <<DATA;
var static_list_num_category_key_result = new Array(
DATA
for ( $count_num = 0 ; $count_num < @category_key ; $count_num++ ) {
	if ( $count_num == @category_key - 1 ) {
		print '"' . "static_list_category_key_num_" . $count_num . '"';
	}
	else {
		print '"' . "static_list_category_key_num_" . $count_num . '"' . ",";
	}
}
print <<DATA;
	);
DATA

print <<DATA;
var static_list_num_category_key_second_result = new Array(
DATA
for (
	$count_num = 0 ;
	$count_num < @filter_category_key_second_item ;
	$count_num++
  )
{
	if ( $count_num == @filter_category_key_second_item - 1 ) {
		print '"'
		  . "static_list_num_category_key_second_"
		  . $filter_category_key_second_item[$count_num] . '"';
	}
	else {
		print '"'
		  . "static_list_num_category_key_second_"
		  . $filter_category_key_second_item[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);
DATA

print <<DATA;
var static_list_num_category_key_third_result = new Array(
DATA
for (
	$count_num = 0 ;
	$count_num < @filter_category_key_third_item ;
	$count_num++
  )
{
	if ( $count_num == @filter_category_key_third_item - 1 ) {
		print '"'
		  . "static_list_num_category_key_third_"
		  . $filter_category_key_third_item[$count_num] . '"';
	}
	else {
		print '"'
		  . "static_list_num_category_key_third_"
		  . $filter_category_key_third_item[$count_num] . '"' . ",";
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
var static_list_bar_td_result = new Array(
DATA
for ( $count_num = 0 ; $count_num < @filter_suite_item ; $count_num++ ) {
	if ( $count_num == @filter_suite_item - 1 ) {
		print '"'
		  . "static_list_bar_td_"
		  . $filter_suite_item[$count_num] . '"';
	}
	else {
		print '"'
		  . "static_list_bar_td_"
		  . $filter_suite_item[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);
DATA

print <<DATA;
var static_list_bar_td_component_result = new Array(
DATA
for ( $count_num = 0 ; $count_num < @filter_component_item ; $count_num++ ) {
	if ( $count_num == @filter_component_item - 1 ) {
		print '"'
		  . "static_list_component_bar_td_"
		  . $filter_component_item[$count_num] . '"';
	}
	else {
		print '"'
		  . "static_list_component_bar_td_"
		  . $filter_component_item[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);
DATA

print <<DATA;
var static_list_bar_td_category_key_result = new Array(
DATA
for ( $count_num = 0 ; $count_num < @category_key ; $count_num++ ) {
	if ( $count_num == @category_key - 1 ) {
		print '"' . "static_list_category_key_bar_td_" . $count_num . '"';
	}
	else {
		print '"' . "static_list_category_key_bar_td_" . $count_num . '"' . ",";
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
var result_value = new Array(
DATA
for ( $count_num = 0 ; $count_num < $case_count_total ; $count_num++ ) {
	if ( $count_num == $case_count_total - 1 ) {
		print '"' . $filter_result_value[$count_num] . '"';
	}
	else {
		print '"' . $filter_result_value[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);				
DATA

print <<DATA;
var suite_item = new Array(
DATA
for ( $count_num = 0 ; $count_num < @filter_suite_item ; $count_num++ ) {
	if ( $count_num == @filter_suite_item - 1 ) {
		print '"' . $filter_suite_item[$count_num] . '"';
	}
	else {
		print '"' . $filter_suite_item[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);				
DATA

print <<DATA;
var category_key = new Array(
DATA
for ( $count_num = 0 ; $count_num < @category_key ; $count_num++ ) {
	if ( $count_num == @category_key - 1 ) {
		print '"' . $category_key[$count_num] . '"';
	}
	else {
		print '"' . $category_key[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);				
DATA

print <<DATA;
var category_key_second = new Array(
DATA
for (
	$count_num = 0 ;
	$count_num < @filter_category_key_second_item ;
	$count_num++
  )
{
	if ( $count_num == @filter_category_key_second_item - 1 ) {
		print '"' . $filter_category_key_second_item[$count_num] . '"';
	}
	else {
		print '"' . $filter_category_key_second_item[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);				
DATA

print <<DATA;
var category_key_third = new Array(
DATA
for (
	$count_num = 0 ;
	$count_num < @filter_category_key_third_item ;
	$count_num++
  )
{
	if ( $count_num == @filter_category_key_third_item - 1 ) {
		print '"' . $filter_category_key_third_item[$count_num] . '"';
	}
	else {
		print '"' . $filter_category_key_third_item[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);				
DATA

print <<DATA;
var component_item = new Array(
DATA
for ( $count_num = 0 ; $count_num < @filter_component_item ; $count_num++ ) {
	if ( $count_num == @filter_component_item - 1 ) {
		print '"' . $filter_component_item[$count_num] . '"';
	}
	else {
		print '"' . $filter_component_item[$count_num] . '"' . ",";
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

if ( @one_package_case_count_total > 0 ) {
	print <<DATA;
var one_package_case_count_total_result = 
DATA
	print '"' . $one_package_case_count_total[0] . '"';
	print <<DATA;
;				
DATA
}

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
var spec_id				= document.getElementById('spec_bar_chart');
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

function static_pkg_list_display(count_num,style,file){
	for ( var count = 0 ; count < count_num ; count++ ) {
		if(file == "case"){
			var id = "static_list_"+package_name[count];
		}
		else if(file == "result"){
			var id = "static_list_"+suite_item[count];
		}
		document.getElementById(id).style.display = style;
	}
}

function static_spec_list_display(count_first,style_first,count_second,style_second,count_third,style_third){
	for ( var count = 0 ; count < count_first ; count++ ) {
		var id_first = "static_list_category_key_" + count;
		document.getElementById(id_first).style.display = style_first;
	}
	for ( var count = 0 ; count < count_second ; count++ ) {
		var id_second = "static_list_category_key_second_" + category_key_second[count];
		var reg = new RegExp("&amp;");
		id_second = id_second.replace(reg,"&");
		var flag = check_conf_category_key(id_second);
		if(flag){
			document.getElementById(id_second).style.display = style_second;
		}
	}
	for ( var count = 0 ; count < count_third ; count++ ) {
		var id_third = "static_list_category_key_third_" + category_key_third[count];
		var reg = new RegExp("&amp;");
		id_third = id_third.replace(reg,"&");
		var flag = check_conf_category_key(id_third);
		if(flag){
			document.getElementById(id_third).style.display = style_third;
		}
	}
}

function static_tree_display(style){
	for ( var count = 0 ; count < package_name_webapi_number ; count++ ) {
		var id = "tree_area_"+package_name_webapi[count];
		document.getElementById(id).style.display = style;
	}
}

function static_component_display(count_num,style,file){
	for ( var count = 0 ; count < count_num ; count++ ) {
		if (file == "case"){
			var id = "static_list_component_"+component[count];
		}
		else if(file == "result"){
			var id = "static_list_component_"+component_item[count];
		}
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

function onCaseView(){
	document.location="tests_statistic.pl?case_view=1"
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
	static_pkg_list_display(package_name_number,"","case");
	filter_case_item();	
	static_tree_display("none");	
	static_component_display(component_number,"none","case");
}

function onDrawTree(){
	top_id.style.display		 = "none";
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
	
	static_pkg_list_display(package_name_number,"none","case");	
	static_component_display(component_number,"none","case");	

	
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
	static_component_display(component_number,"","case");
	filter_case_item();
	static_pkg_list_display(package_name_number,"none","case");	
	static_tree_display("none");
}

function onDrawResultCylindrical(){
	top_id.style.display		 = "";
	bottom_id.style.display		 = "";
	no_pkg_id.style.display		 = "none";
	component_id.src			 = "images/component_bar_chart.png";
	chart_id.src				 = "images/package_bar_chart_selected.png";
	spec_id.src					 = "images/package_tree_diagram.png";
	component_id.style.cursor	 = "pointer";
	chart_id.style.cursor 		 = "default";
	spec_id.style.cursor 		 = "pointer";
	
	chart_id.onclick		 = "";
	
	component_id.onclick = function(){
		return onDrawResultComponent();
	};	
	spec_id.onclick = function(){
		return onDrawResultSpec();
	};
	
	if(component_item.length == 0){
		no_pkg_id.style.display	= "";
		top_id.style.display	= "none";
		bottom_id.style.display	= "none";
		static_scale_display("none","none");
	}
	else{
		static_component_display(component_item.length,"none","result");
		static_scale_display("","none");
		document.getElementById("static_scale_category_key").style.display = "none";
		document.getElementById("static_scale_number_category_key").style.display = "none";
		static_pkg_list_display(suite_item.length,"","result");	
		static_spec_list_display(category_key.length,"none",category_key_second.length,"none",category_key_third.length,"none");
		document.getElementById("td_category_key_null").style.display = "";
		document.getElementById("td_category_key").style.display = "none";
		filter_result_item();
	}
}

function onDrawResultComponent(){
	top_id.style.display		 = "";
	bottom_id.style.display		 = "";
	no_pkg_id.style.display		 = "none";
	component_id.src			 = "images/component_bar_chart_selected.png";
	chart_id.src				 = "images/package_bar_chart.png";
	spec_id.src					 = "images/package_tree_diagram.png";
	component_id.style.cursor	 = "default";
	chart_id.style.cursor 		 = "pointer";
	spec_id.style.cursor 		 = "pointer";
	
	component_id.onclick		 = "";
	
	chart_id.onclick = function(){
		return onDrawResultCylindrical();
	};	
	spec_id.onclick = function(){
		return onDrawResultSpec();
	};
	
	if(suite_item.length == 0){
		no_pkg_id.style.display	= "";
		top_id.style.display	= "none";
		bottom_id.style.display	= "none";
		static_scale_display("none","none");
	}
	else{
		static_component_display(component_item.length,"","result");
		static_scale_display("none","");
		document.getElementById("static_scale_category_key").style.display = "none";
		document.getElementById("static_scale_number_category_key").style.display = "none";
		static_pkg_list_display(suite_item.length,"none","result");	
		static_spec_list_display(category_key.length,"none",category_key_second.length,"none",category_key_third.length,"none");
		document.getElementById("td_category_key_null").style.display = "";
		document.getElementById("td_category_key").style.display = "none";
		filter_result_item();
	}
}

function onDrawResultSpec(){
	top_id.style.display		 = "";
	bottom_id.style.display		 = "";
	no_pkg_id.style.display		 = "none";
	component_id.src			 = "images/component_bar_chart.png";
	chart_id.src				 = "images/package_bar_chart.png";
	spec_id.src					 = "images/package_tree_diagram_selected.png";
	component_id.style.cursor	 = "pointer";
	chart_id.style.cursor 		 = "pointer";
	spec_id.style.cursor		 = "default";
	
	component_id.onclick = function(){
		return onDrawResultComponent();
	};	
	
	chart_id.onclick = function(){
		return onDrawResultCylindrical();
	};	
	
	spec_id.onclick = "";
	
	if(suite_item.length == 0){
		no_pkg_id.style.display	= "";
		top_id.style.display	= "none";
		bottom_id.style.display	= "none";
		static_scale_display("none","none");
	}
	else{
		static_component_display(component_item.length,"none","result");
		static_scale_display("none","none");
		document.getElementById("static_scale_category_key").style.display = "";
		document.getElementById("static_scale_number_category_key").style.display = "";
		static_pkg_list_display(suite_item.length,"none","result");	
		static_spec_list_display(category_key.length,"",category_key_second.length,"",category_key_third.length,"");
		document.getElementById("td_category_key_null").style.display = "none";
		document.getElementById("td_category_key").style.display = "";
		filter_result_item();
	}
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
						if (spec_value[j].indexOf(item+":")== 0){
							pkg_webapi_item_count[k]++; 
						}
						if((spec_value[j].indexOf(item+":") > 0) && (spec_value[j].indexOf(":"+item) > 0)){
							pkg_webapi_item_count[k]++; 							
						}
						if (spec_value[j] == item) {
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
	var color_list = new Array("#5CCBF6", "#Cc3300", "#EED484", "#596874", "#59315F");
	var page = document.getElementsByClassName("yui-pb-bar");
	for ( var i = 0; i < page.length; i++) {
		page[i].style.backgroundColor = color_list[i%5];
	}
	var page = document.getElementsByClassName("yui-pb");
	for ( var i = 0; i < page.length; i++) {
		page[i].style.borderStyle = "none";
	}
}
DATA
print <<DATA;
function select_result_file(type){
	if(type == "init"){
		document.location = "tests_statistic.pl?result_file=1";
	}
	else{
		var id = document.getElementById('select_result');
		var count = id.selectedIndex+1;
		document.location = "tests_statistic.pl?result_file="+count;
	}
}

function filter_result_item(){
	var suite_count_total = new Array;
	var suite_count_pass = new Array;
	var component_count_total = new Array;
	var component_count_pass = new Array;
	var category_key_count_total = new Array;
	var category_key_count_pass = new Array;
	var category_key_second_count_total = new Array;
	var category_key_second_count_pass = new Array;
	var category_key_third_count_total = new Array;
	var category_key_third_count_pass = new Array;
	var select_category_key_id = document.getElementById("select_category_key");
	
	if(suite_item.length == 0){
		var item = new Option("No result file","No result file");
		document.getElementById("select_result").options.add(item);
	}
	
	for(var i=0; i< suite_item.length; i++){
		suite_count_total[i] = 0;
		suite_count_pass[i] = 0;
	}
	
	for(var i=0; i< component_item.length; i++){
		component_count_total[i] = 0;
		component_count_pass[i] = 0;
	}
	
	for(var i=0; i< category_key.length; i++){
		category_key_count_total[i] = 0;
		category_key_count_pass[i] = 0;
	}
	
	for(var i=0; i< category_key_second.length; i++){
		category_key_second_count_total[i] = 0;
		category_key_second_count_pass[i] = 0;
	}
	
	for(var i=0; i< category_key_third.length; i++){
		category_key_third_count_total[i] = 0;
		category_key_third_count_pass[i] = 0;
	}
	
	for (var j=0;j<suite_item.length; j++){
		for(var i=0;i<one_package_case_count_total_result; i++){
			if (suite_value[i] == suite_item[j]){	
				if (((sel_testsuite_id.value == "Any Test Suite")
				||(sel_testsuite_id.value == suite_value[i]))
				&& ((sel_type_id.value == "Any Type")
				||(sel_type_id.value == type_value[i]))
				&& ((sel_status_id.value == "Any Status")
				||(sel_status_id.value == status_value[i]))
				&& ((sel_priority_id.value == "Any Priority")
				||(sel_priority_id.value == priority_value[i]))
				&& ((sel_category_id.value == "Any Category")
				||(category_value[i].indexOf(sel_category_id.value))>0)
				){
					suite_count_total[j] ++;
					if(result_value[i] == "PASS"){
						suite_count_pass[j] ++;
					}
				}
			}
		}
	}
	
	for(var k=0; k<component_item.length; k++){
		for(var i=0;i<one_package_case_count_total_result; i++){	
			if (component_value[i] == component_item[k]){	
				if (((sel_testsuite_id.value == "Any Test Suite")
				||(sel_testsuite_id.value == suite_value[i]))
				&& ((sel_type_id.value == "Any Type")
				||(sel_type_id.value == type_value[i]))
				&& ((sel_status_id.value == "Any Status")
				||(sel_status_id.value == status_value[i]))
				&& ((sel_priority_id.value == "Any Priority")
				||(sel_priority_id.value == priority_value[i]))
				&& ((sel_category_id.value == "Any Category")
				||(category_value[i].indexOf(sel_category_id.value))>0)
				){
					component_count_total[k] ++;
					if(result_value[i] == "PASS"){
						component_count_pass[k] ++;
					}
				}
			}	
		}
	}
	
	if(suite_item.length > 0){
		for(var k=0; k<category_key.length; k++){
			for(var i=0;i<one_package_case_count_total_result; i++){	
				if (spec_value[i].indexOf(category_key[k]+":") == 0){	
					if (((sel_testsuite_id.value == "Any Test Suite")
					||(sel_testsuite_id.value == suite_value[i]))
					&& ((sel_type_id.value == "Any Type")
					||(sel_type_id.value == type_value[i]))
					&& ((sel_status_id.value == "Any Status")
					||(sel_status_id.value == status_value[i]))
					&& ((sel_priority_id.value == "Any Priority")
					||(sel_priority_id.value == priority_value[i]))
					&& ((sel_category_id.value == "Any Category")
					||(category_value[i].indexOf(sel_category_id.value))>0)
					){
						category_key_count_total[k] ++;
						if(result_value[i] == "PASS"){
							category_key_count_pass[k] ++;
						}
					}
				}	
			}
		}
		
		for(var k=0; k<category_key_second.length; k++){
			for(var i=0;i<one_package_case_count_total_result; i++){	
				if (spec_value[i].indexOf(category_key_second[k]+":") == 0){	
					if (((sel_testsuite_id.value == "Any Test Suite")
					||(sel_testsuite_id.value == suite_value[i]))
					&& ((sel_type_id.value == "Any Type")
					||(sel_type_id.value == type_value[i]))
					&& ((sel_status_id.value == "Any Status")
					||(sel_status_id.value == status_value[i]))
					&& ((sel_priority_id.value == "Any Priority")
					||(sel_priority_id.value == priority_value[i]))
					&& ((sel_category_id.value == "Any Category")
					||(category_value[i].indexOf(sel_category_id.value))>0)
					){
						category_key_second_count_total[k] ++;
						if(result_value[i] == "PASS"){
							category_key_second_count_pass[k] ++;
						}
					}
				}	
			}
		}
		
		for(var k=0; k<category_key_third.length; k++){
			for(var i=0;i<one_package_case_count_total_result; i++){	
				if (spec_value[i].indexOf(category_key_third[k]+":") == 0){	
					if (((sel_testsuite_id.value == "Any Test Suite")
					||(sel_testsuite_id.value == suite_value[i]))
					&& ((sel_type_id.value == "Any Type")
					||(sel_type_id.value == type_value[i]))
					&& ((sel_status_id.value == "Any Status")
					||(sel_status_id.value == status_value[i]))
					&& ((sel_priority_id.value == "Any Priority")
					||(sel_priority_id.value == priority_value[i]))
					&& ((sel_category_id.value == "Any Category")
					||(category_value[i].indexOf(sel_category_id.value))>0)
					){
						category_key_third_count_total[k] ++;
						if(result_value[i] == "PASS"){
							category_key_third_count_pass[k] ++;
						}
					}
				}	
			}
		}
	}
	for (var i=0; i<suite_item.length; i++) {
		var list_bar = document.getElementById(static_list_bar_td_result[i]);
		var list_num = document.getElementById(static_list_num_result[i]);
		
		var id 	 = static_list_bar_result[i];
		document.getElementById(id).innerHTML = "";
		var pb = new YAHOO.widget.ProgressBar().render(static_list_bar_result[i]);
		if(	suite_count_total[i] == 0){
			var rate = 0;
			list_bar.width = 1;
			list_num.innerHTML = suite_count_total[i]+"%";
		}
		else{
			var rate = parseFloat((suite_count_pass[i]/case_count_total*100).toFixed(2));
			pb.set('minValue', 0);
			pb.set('maxValue', rate);
		}	
		
		if(rate <1 ){
			pb.set('width', 1);
			list_bar.width = 1;
		}
		else{
			pb.set('width', rate*3.98);
			list_bar.width = rate*3.98;
		}
		
		pb.set('height', 15);
		//case_number_before
		pb.set('value', 0);
	
		pb.set('anim', true);
		var anim = pb.get('anim');
		anim.duration = 1;
		anim.method = YAHOO.util.Easing.easeBothStrong;
	
		//global_case_number
		pb.set('value', rate);
		
		list_num.innerHTML =rate+"%";
	}
	
	for (var i=0; i<component_item.length; i++) {
		var list_bar = document.getElementById(static_list_bar_td_component_result[i]);
		var list_num = document.getElementById(static_list_num_component_result[i]);
		
		var id 	 = static_list_bar_component_result[i];
		document.getElementById(id).innerHTML = "";
		var pb = new YAHOO.widget.ProgressBar().render(static_list_bar_component_result[i]);
		if(	component_count_total[i] == 0){
			var rate = 0;
			list_bar.width = 1;
			list_num.innerHTML = component_count_total[i]+"%";
		}
		else{
			var rate = parseFloat((component_count_pass[i]/case_count_total*100).toFixed(2));
			pb.set('minValue', 0);
			pb.set('maxValue', rate);
		}	
		if(rate <1 ){
			pb.set('width', 1);
			list_bar.width = 1;
		}
		else{
			pb.set('width', rate*3.13);
			list_bar.width = rate*3.13;
		}
		pb.set('height', 15);
		//case_number_before
		pb.set('value', 0);
	
		pb.set('anim', true);
		var anim = pb.get('anim');
		anim.duration = 1;
		anim.method = YAHOO.util.Easing.easeBothStrong;
	
		//global_case_number
		pb.set('value', rate);
		list_num.innerHTML =rate+"%";
	}
	
	if( suite_item.length >0 ){
		for (var i=0; i<category_key.length; i++) {
			var list_bar = document.getElementById(static_list_bar_td_category_key_result[i]);
			var list_num = document.getElementById(static_list_num_category_key_result[i]);
			
			var id 	 = static_list_bar_category_key_result[i];
			document.getElementById(id).innerHTML = "";
			var pb = new YAHOO.widget.ProgressBar().render(static_list_bar_category_key_result[i]);
			if(	category_key_count_total[i] == 0){
				var rate = 0;
				list_bar.width = 1;
				list_num.innerHTML = category_key_count_total[i]+"%";
			}
			else{
				var rate = parseFloat((category_key_count_pass[i]/case_count_total*100).toFixed(2));
				pb.set('minValue', 0);
				pb.set('maxValue', rate);
			}	
			if(rate <1 ){
				pb.set('width', 1);
				list_bar.width = 1;
			}
			else{
				pb.set('width', rate*3.13);
				list_bar.width = rate*3.13;
			}
			pb.set('height', 15);
			//case_number_before
			pb.set('value', 0);
		
			pb.set('anim', true);
			var anim = pb.get('anim');
			anim.duration = 1;
			anim.method = YAHOO.util.Easing.easeBothStrong;
		
			//global_case_number
			pb.set('value', rate);
			list_num.innerHTML =rate+"%";
		}
	
		for (var i=0; i<category_key_second.length; i++) {
			var id 	 = static_list_bar_category_key_second_result[i];
			var td_id = static_list_bar_td_category_key_second_result[i];
			var num_id = static_list_num_category_key_second_result[i];
			var reg = new RegExp("&amp;");
			id = id.replace(reg,"&");
			num_id = num_id.replace(reg,"&");
			td_id = td_id.replace(reg,"&");
			var flag = check_conf_category_key(id);
			if(flag){
				var list_bar = document.getElementById(td_id);
				var list_num = document.getElementById(num_id);
				document.getElementById(id).innerHTML = "";
				var pb = new YAHOO.widget.ProgressBar().render(id);
				if(	category_key_second_count_total[i] == 0){
					var rate = 0;
					list_bar.width = 1;
					list_num.innerHTML = category_key_second_count_total[i]+"%";
				}
				else{
					var rate = parseFloat((category_key_second_count_pass[i]/case_count_total*100).toFixed(2));
					pb.set('minValue', 0);
					pb.set('maxValue', rate);
				}	
				if(rate <1 ){
					pb.set('width', 1);
					list_bar.width = 1;
				}
				else{
					pb.set('width', rate*3.13);
					list_bar.width = rate*3.13;
				}
				pb.set('height', 15);
				//case_number_before
				pb.set('value', 0);
			
				pb.set('anim', true);
				var anim = pb.get('anim');
				anim.duration = 1;
				anim.method = YAHOO.util.Easing.easeBothStrong;
			
				//global_case_number
				pb.set('value', rate);
				list_num.innerHTML =rate+"%";
			}
		}
		
		for (var i=0; i<category_key_third.length; i++) {
			var id 	 = static_list_bar_category_key_third_result[i];
			var num_id = static_list_num_category_key_third_result[i];
			var td_id = static_list_bar_td_category_key_third_result[i];
			var reg = new RegExp("&amp;");
			id = id.replace(reg,"&");
			num_id = num_id.replace(reg,"&");
			td_id = td_id.replace(reg,"&");
			var flag = check_conf_category_key(id);
			if(flag){
				var list_bar = document.getElementById(td_id);
				var list_num = document.getElementById(num_id);
				document.getElementById(id).innerHTML = "";
				var pb = new YAHOO.widget.ProgressBar().render(id);
				if(	category_key_third_count_total[i] == 0){
					var rate = 0;
					list_bar.width = 1;
					list_num.innerHTML = category_key_third_count_total[i]+"%";
				}
				else{
					var rate = parseFloat((category_key_third_count_pass[i]/case_count_total*100).toFixed(2));
					pb.set('minValue', 0);
					pb.set('maxValue', rate);
				}	
				if(rate <1 ){
					pb.set('width', 1);
					list_bar.width = 1;
				}
				else{
					pb.set('width', rate*3.13);
					list_bar.width = rate*3.13;
				}
				pb.set('height', 15);
				//case_number_before
				pb.set('value', 0);
			
				pb.set('anim', true);
				var anim = pb.get('anim');
				anim.duration = 1;
				anim.method = YAHOO.util.Easing.easeBothStrong;
			
				//global_case_number
				pb.set('value', rate);
				list_num.innerHTML =rate+"%";
			}
		}
	}
	//change color
	var color_list = new Array("#5CCBF6", "#Cc3300", "#EED484", "#596874", "#59315F");
	var page = document.getElementsByClassName("yui-pb-bar");
	for ( var i = 0; i < page.length; i++) {
		page[i].style.backgroundColor = color_list[i%5];
	}
	var page = document.getElementsByClassName("yui-pb");
	for ( var i = 0; i < page.length; i++) {
		page[i].style.borderStyle = "none";
	}
	if(document.getElementById("td_category_key").style.display == ""){
		if(select_category_key_id.selectedIndex == 0){
			static_spec_list_display(category_key.length,"",category_key_second.length,"none",category_key_third.length,"none");
		}
		else if(select_category_key_id.selectedIndex == 1){
			static_spec_list_display(category_key.length,"",category_key_second.length,"",category_key_third.length,"none");
		}
		else if(select_category_key_id.selectedIndex == 2){
			static_spec_list_display(category_key.length,"",category_key_second.length,"",category_key_third.length,"");
		}
	}
}

function check_conf_category_key(id){
	var flag = 0;
	for (var j = 0; j<category_key.length; j++){
		if(id.indexOf("_"+category_key[j]+":") > 0){
			flag = 1;
		}
	}
	return flag;
}

DATA
if ( $_GET{'case_view'} ) {
	print <<DATA;
	filter_case_item();
	document.getElementById('view_test_case').disabled = "true";
	document.getElementById('view_test_case').style.cursor = "default";
	document.getElementById('view_test_case').className = "medium_button_disable";

DATA
}
else {
	print <<DATA;
	filter_result_item();
	document.getElementById("select_result").selectedIndex = $result_no;
	document.getElementById('view_test_result').disabled = "true";
	document.getElementById('view_test_result').style.cursor = "default";
	document.getElementById('view_test_result').className = "medium_button_disable";
DATA
}
print <<DATA;
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

sub GetResultFileName {
	if ( $_ =~ /^tests\.result\.xml$/ ) {
		my $relative = $File::Find::dir;
		$relative =~ s/$testSuitesPath//g;
		my @temp_result_file_name = split( "\/", $relative );
		push( @result_file_name, @temp_result_file_name );
	}
}

sub ScanPackages {
	$testSuitesPath = $definition_dir;
	find( \&GetPackageName, $testSuitesPath );
}

sub ScanResultFile {
	$testSuitesPath = $result_dir_manager;
	find( \&GetResultFileName, $testSuitesPath );
}

sub CountPackages {
	while ( $package_name_number < @package_name ) {
		$package_name_number++;
	}
}

sub CountResultFiles {
	while ( $result_file_number < @result_file_name ) {
		$result_file_number++;
	}
}

sub CreateFilePath {
	my $count = 0;
	while ( $count < $package_name_number ) {
		$testsxml[$count] =
		  $definition_dir . $package_name[$count] . "/tests.xml";
		$count++;
	}
}

sub CreateResultFilePath {
	my $count = 0;
	while ( $count < $result_file_number ) {
		$resultsxml[$count] =
		  $result_dir_manager . $result_file_name[$count] . "/tests.result.xml";
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
	my ( $number_temp, @xml_temp ) = @_;

	while ( $count < $number_temp ) {
		open FILE, $xml_temp[$count] or die $!;
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
			if ( $_ =~ /<suite.*name="(.*?)"/ ) {
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
			if (   ( $_ =~ / type="(.*?)"/ )
				&& ( $_ !~ /xml\-stylesheet type=/ ) )
			{
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
	my ( $xml_dir, @xml_file_tmp ) = @_;

	foreach (@xml_file_tmp) {
		my $package = $_;
		my $tests_xml_dir;
		if ( $xml_dir eq $definition_dir ) {
			$tests_xml_dir = $xml_dir . $package . "/tests.xml";
		}
		else {
			$tests_xml_dir = $xml_dir . $package . "/tests.result.xml";
		}
		my $suite_value;
		my $type_value;
		my $case_value;
		my $status_value;
		my $component_value;
		my $priority_value;
		my $category_value;
		my $result_value;
		my $spec        = "none";
		my $spec_number = 0;
		my $startCase   = "FALSE";
		my $xml         = "none";

		open FILE, $tests_xml_dir or die $!;

		while (<FILE>) {
			if ( $startCase eq "TRUE" ) {
				chomp( $xml .= $_ );
			}
			if ( $_ =~ /suite.*name="(.*?)".*/ ) {
				$suite_value = $1;
			}
			if ( $_ =~ /.*<testcase.*/ ) {
				$startCase = "TRUE";
				chomp( $xml = $_ );
			}
			if ( $_ =~ /.*<\/testcase>.*/ ) {
				$startCase       = "FALSE";
				%caseInfo        = updateCaseInfo($xml);
				$type_value      = $caseInfo{"test_type"};
				$status_value    = $caseInfo{"status"};
				$component_value = $caseInfo{"component"};
				$priority_value  = $caseInfo{"priority"};
				$category_value  = $caseInfo{"categories"};
				$spec            = $caseInfo{"specs"};
				$result_value    = $caseInfo{"result"};

				push( @filter_suite_value,     $suite_value );
				push( @filter_type_value,      $type_value );
				push( @filter_status_value,    $status_value );
				push( @filter_component_value, $component_value );
				push( @filter_priority_value,  $priority_value );
				push( @filter_category_value,  $category_value );
				push( @filter_result_value,    $result_value );

				my @temp = ();

				push( @temp, $filter_suite_value[0] );
				for ( my $j = 1 ; $j < @filter_suite_value ; $j++ ) {
					for ( my $i = 0 ; $i < @temp ; $i++ ) {
						if ( $filter_suite_value[$j] eq $temp[$i] ) {
							last;
						}
						if ( $i == @temp - 1 ) {
							push( @temp, $filter_suite_value[$j] );
						}
					}
				}
				@filter_suite_item = sort @temp;
				@temp              = ();

				push( @temp, $filter_component_value[0] );
				for ( my $j = 1 ; $j < @filter_component_value ; $j++ ) {
					for ( my $i = 0 ; $i < @temp ; $i++ ) {
						if ( $filter_component_value[$j] eq $temp[$i] ) {
							last;
						}
						if ( $i == @temp - 1 ) {
							push( @temp, $filter_component_value[$j] );
						}
					}
				}
				@filter_component_item = sort @temp;

				if (
					(
						$spec ne
"none!::!none!::!none!::!none!::!none!::!none!::!none!::!none!::!none"
					)
					or ( $spec ne "none" )
				  )
				{
					my @spec_list = split( "!__!", $spec );
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
						push( @filter_spec_value,
							join( ":", @spec_content_top_5 ) );

					}
				}

				$one_package_case_count_total++;
			}
		}
		push( @one_package_case_count_total, $one_package_case_count_total );
		$count_tmp++;
	}
	foreach (@filter_suite_value) {
		$case_count_total++;
	}
	foreach (@filter_spec_value) {
		if ( $_ =~ /(.*?)\:(.*?)\:(.*)/ ) {
			my $category_key_temp = $1 . ":" . $2;
			push( @filter_category_key_second, $category_key_temp );
		}
		if ( $_ =~ /(.*?)\:(.*?)\:(.*?):(.*)/ ) {
			my $category_key_temp = $1 . ":" . $2 . ":" . $3;
			push( @filter_category_key_third, $category_key_temp );
		}
	}

	my @temp = ();
	my $k    = 0;
	for ( ; $k < @filter_category_key_second ; $k++ ) {
		if ( $filter_category_key_second[$k] !~ /unknown/ ) {
			push( @temp, $filter_category_key_second[$k] );
			last;
		}
	}

	for ( my $j = 1 ; $j < @filter_category_key_second ; $j++ ) {
		for ( my $i = 0 ; $i < @temp ; $i++ ) {
			if ( $filter_category_key_second[$j] eq $temp[$i] ) {
				last;
			}
			if ( $i == @temp - 1 ) {
				if ( $filter_category_key_second[$j] !~ /unknown/ ) {
					push( @temp, $filter_category_key_second[$j] );
				}
			}
		}
	}
	@filter_category_key_second_item = sort @temp;
	@temp                            = ();

	$k = 0;
	for ( ; $k < @filter_category_key_third ; $k++ ) {
		if ( $filter_category_key_third[$k] !~ /unknown/ ) {
			push( @temp, $filter_category_key_third[$k] );
			last;
		}
	}
	for ( my $j = 1 ; $j < @filter_category_key_third ; $j++ ) {
		for ( my $i = 0 ; $i < @temp ; $i++ ) {
			if ( $filter_category_key_third[$j] eq $temp[$i] ) {
				last;
			}
			if ( $i == @temp - 1 ) {
				if ( $filter_category_key_third[$j] !~ /unknown/ ) {
					push( @temp, $filter_category_key_third[$j] );
				}
			}
		}
	}
	@filter_category_key_third_item = sort @temp;
}

sub DrawResultSelect {
	foreach ( reverse sort @result_file_name ) {
		my $result_file = $_;
		print <<DATA;
		<option>$result_file</option>
DATA
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

sub DrawResultsuiteSelect {
	my $count = 0;
	print <<DATA;
		<option selected="selected">Any Test Suite</option>
DATA
	for ( ; $count < @filter_suite_item ; $count++ ) {
		print <<DATA;
		<option>$filter_suite_item[$count]</option>
DATA
	}
}

sub DrawCategoryKeySelect {
	my $count = 0;
	print <<DATA;
		<option selected="selected">category</option>
		<option>section</option>
		<option>specification</option>
DATA
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

print_footer("");
