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
use Data::Dumper;

if ( !( -e $profile_dir_manager ) ) {
	system( 'mkdir ' . $profile_dir_manager );
}

my @package_name         = ();
my @sort_package_name    = ();
my @reverse_package_name = ();
my @version              = ();
my @introduction         = ();
my @case_number          = ();
my @read_me              = ();
my @licence_copyright    = ();
my @installation_path    = ();
my @testsxml             = ();
my @category             = ();
my @category_num         = ();
my @test_suite           = ();
my @test_suite_num       = ();
my @test_set             = ();
my @test_set_num         = ();
my @status               = ();
my @status_num           = ();
my @type                 = ();
my @type_num             = ();
my @priority             = ();
my @priority_num         = ();
my @component            = ();
my @component_num        = ();
my @execution_type       = ();
my @execution_type_num   = ();
my @version_item         = ();
my @category_item        = ();
my @test_suite_item      = ();
my @test_set_item        = ();
my @status_item          = ();
my @type_item            = ();
my @priority_item        = ();
my @component_item       = ();
my @execution_type_item  = ();

my $package_name_number   = 0;
my $count_num             = 0;
my $number                = 0;
my $category_number       = 0;
my $test_suite_number     = 0;
my $test_set_number       = 0;
my $status_number         = 0;
my $priority_number       = 0;
my $type_number           = 0;
my $component_number      = 0;
my $execution_type_number = 0;
my $value                 = "";
my $image                 = "";

my $cnt_load_file = 0;
my $load_type_item;
my @package_name_load;
my @sort_package_name_load;
my @reverse_package_name_load;
my @load_keys;
my @load_values;
my @count_package_name_load;
my @ver_package_name_load;
my @count_package_keys;
my @count_package_values;
my @ver_package_keys;
my @ver_package_values;
my $advanced_value_version;
my $advanced_value_architecture;
my $count_checkbox = 0;

my @package_name_flag      = ();
my @view_package_name_flag = ();

my $advanced_value_category;
my $advanced_value_priority;
my $advanced_value_status;
my $advanced_value_execution_type;
my $advanced_value_test_suite;
my $advanced_value_type;
my $advanced_value_test_set;
my $advanced_value_component;
my $count_package_number_post;

my @load_profile_result_pkg_name;
my @select_packages_filter;
my @checkbox_packages;

my $case_value;
my @case_value;
my @case_id;
my @case_execution_type;
my @case_xml;
my $case_value_flag_count = 0;

my @filter_version_value         = ();
my @filter_suite_value           = ();
my @filter_set_value             = ();
my @filter_type_value            = ();
my @filter_status_value          = ();
my @filter_component_value       = ();
my @filter_execution_value       = ();
my @filter_priority_value        = ();
my @filter_category_value        = ();
my $case_count_total             = 0;
my @one_package_case_count_total = ();

my @filter_auto_count;
my @filter_manual_count;
my @package_version_installed   = ();
my @package_version_latest      = ();
my @update_package_flag         = ();
my @uninstall_package_name      = ();
my @uninstall_package_version   = ();
my $UNINSTALL_PACKAGE_COUNT_MAX = "100";
my $sort_flag                   = 0;
my $refresh_flag                = 1;
my $view_page_no_filter_flag    = 1;
my $tree_view_current           = 0;
my $list_view_current           = 0;

# press delete package icon
if ( $_GET{"delete_package"} ) {
	syncDefinition();
	my $flag_i = 0;
	my @package_name_temp;
	my $checkbox_value  = $_GET{"checkbox"};
	my @select_packages = split /\*/, $checkbox_value;
	my $get_value       = $_GET{"advanced"};
	my @get_value       = split /\*/, $get_value;
	$sort_flag = $_GET{'sort_flag'};

	ScanPackages();
	foreach (@package_name) {
		my $temp = $_;
		if ( $_GET{ "delete_" . "$temp" } ) {
			my $cmd          = "sdb shell 'rpm -qa | grep " . $temp . "'";
			my $have_package = `$cmd`;
			if ( $have_package =~ /$temp/ ) {
				system("sdb shell 'rpm -e $temp &>/dev/null' &>/dev/null");
				my $cmd = "sdb shell 'wrt-launcher -l | grep " . $temp . "'";
				my @package_items = `$cmd`;
				foreach (@package_items) {
					my $package_id = "none";
					if ( $_ =~ /^\s+(\d+)\s+(\d+)/ ) {
						$package_id = $2;
					}
					if ( $package_id ne "none" ) {
						system(
"sdb shell 'wrt-installer -u $package_id &>/dev/null' &>/dev/null"
						);
					}
				}
			}
		}
		else {
			push( @package_name_temp, $_ );
		}
	}
	syncDefinition();

	@package_name = @package_name_temp;

	$advanced_value_architecture   = $get_value[0];
	$advanced_value_version        = $get_value[1];
	$advanced_value_category       = $get_value[2];
	$advanced_value_priority       = $get_value[3];
	$advanced_value_status         = $get_value[4];
	$advanced_value_execution_type = $get_value[5];
	$advanced_value_test_suite     = $get_value[6];
	$advanced_value_type           = $get_value[7];
	$advanced_value_test_set       = $get_value[8];
	$advanced_value_component      = $get_value[9];

	CountPackages();
	@sort_package_name    = sort @package_name;
	@reverse_package_name = reverse @sort_package_name;
	if ( !$sort_flag ) {
		@package_name = @sort_package_name;
	}
	else {
		@package_name = @reverse_package_name;
	}

	AnalysisVersion();
	CreateFilePath();
	AnalysisTestsXML();

	$count_package_number_post = $package_name_number;

	FilterCaseValue();
	FilterCase();

	while ( $flag_i < @package_name ) {
		if ( $package_name_flag[$flag_i] eq "a" ) {
			foreach (@select_packages) {
				if ( $_ =~ /$package_name[$flag_i]/ ) {
					s/checkbox_//g;
					push( @checkbox_packages, $_ );
				}
			}
		}
		$flag_i++;
	}
	if ( @package_name > 0 ) {
		UpdatePage();
	}
	else {
		UpdateNullPage();
	}
}

elsif ( $_GET{'view_single_package'} ) {
	my $list_file = $test_definition_dir . "list_view_case.xml";
	$tree_view_current        = 0;
	$list_view_current        = 1;
	$refresh_flag             = 0;
	$view_page_no_filter_flag = 0;
	syncDefinition();
	my $get_value  = $_GET{"advanced"};
	my @get_value  = split /\*/, $get_value;
	my $view_count = 0;
	my @view_flag;

	$advanced_value_architecture   = $get_value[0];
	$advanced_value_version        = $get_value[1];
	$advanced_value_category       = $get_value[2];
	$advanced_value_priority       = $get_value[3];
	$advanced_value_status         = $get_value[4];
	$advanced_value_execution_type = $get_value[5];
	$advanced_value_test_suite     = $get_value[6];
	$advanced_value_type           = $get_value[7];
	$advanced_value_test_set       = $get_value[8];
	$advanced_value_component      = $get_value[9];

	ScanPackages();
	foreach (@package_name) {
		my $temp = $_;
		$view_flag[$view_count] = "b";
		if ( $_GET{ "view_" . "$temp" } ) {
			$view_flag[$view_count] = "a";
		}
		$view_count++;
	}

	CountPackages();
	AnalysisVersion();
	CreateFilePath();
	AnalysisTestsXML();
	GetSelectItem();
	FilterCaseValue();
	FilterCase();

	for ( my $count = 0 ; $count < $package_name_number ; $count++ ) {
		$view_package_name_flag[$count] = $package_name_flag[$count];
	}

	my $i = 0;
	while ( $i < @package_name ) {
		if ( $package_name_flag[$i] eq "a" ) {
			$package_name_flag[$i] = "b";
			if ( $view_flag[$i] eq "a" ) {
				$package_name_flag[$i] = "a";
				$advanced_value_test_suite = $package_name[$i];
			}
		}
		$i++;
	}
	UpdateViewPageSelectItem();
	ListViewDetailedInfo($list_file);

	print <<DATA;
<table width="768" border="0" cellspacing="0" cellpadding="0" class="report_list" style="table-layout:fixed">	
  <tr>
    <td>
DATA
	print xml2xsl_case($list_file);
	print <<DATA;
    </td>
  </tr>
  </table>
DATA
}

# press view button
elsif ( $_POST{'view_package_info'} ) {
	my $list_file = $test_definition_dir . "list_view_case.xml";
	$tree_view_current        = 0;
	$list_view_current        = 1;
	$refresh_flag             = 0;
	$view_page_no_filter_flag = 0;
	syncDefinition();
	my %hash = %_POST;
	my $key;
	my $value;
	my @select_package_temp;
	$advanced_value_version      = $_POST{"select_ver"};
	$advanced_value_architecture = $_POST{"select_arc"};

	$advanced_value_category       = $_POST{"select_category"};
	$advanced_value_priority       = $_POST{"select_pri"};
	$advanced_value_status         = $_POST{"select_status"};
	$advanced_value_execution_type = $_POST{"select_exe"};
	$advanced_value_test_suite     = $_POST{"select_testsuite"};
	$advanced_value_type           = $_POST{"select_type"};
	$advanced_value_test_set       = $_POST{"select_testset"};
	$advanced_value_component      = $_POST{"select_com"};

	ScanPackages();
	CountPackages();
	AnalysisVersion();
	CreateFilePath();
	AnalysisTestsXML();
	GetSelectItem();
	FilterCaseValue();
	FilterCase();
	UpdateViewPageSelectItem();

	for ( my $count = 0 ; $count < $package_name_number ; $count++ ) {
		$view_package_name_flag[$count] = $package_name_flag[$count];
	}

	while ( ( $key, $value ) = each %hash ) {
		if ( $key =~ /checkbox/ ) {
			push( @select_package_temp, $key );
		}
	}

	my $i = 0;
	while ( $i < @package_name ) {
		if ( $package_name_flag[$i] eq "a" ) {
			$package_name_flag[$i] = "b";
			foreach (@select_package_temp) {
				if ( $_ eq "checkbox_" . $package_name[$i] ) {
					$package_name_flag[$i] = "a";
				}
			}
		}
		$i++;
	}
	ListViewDetailedInfo($list_file);

	print <<DATA;
<table width="768" border="0" cellspacing="0" cellpadding="0" class="report_list" style="table-layout:fixed">	
  <tr>
    <td>
DATA
	print xml2xsl_case($list_file);
	print <<DATA;
    </td>
  </tr>
  </table>
DATA
}

elsif ( $_POST{'tree_view_filter_pkg_info'} ) {
	$tree_view_current        = 1;
	$list_view_current        = 0;
	$refresh_flag             = 0;
	$view_page_no_filter_flag = 0;
	syncDefinition();
	$advanced_value_version      = $_POST{"select_ver"};
	$advanced_value_architecture = $_POST{"select_arc"};

	$advanced_value_category       = $_POST{"select_category"};
	$advanced_value_priority       = $_POST{"select_pri"};
	$advanced_value_status         = $_POST{"select_status"};
	$advanced_value_execution_type = $_POST{"select_exe"};
	$advanced_value_test_suite     = $_POST{"select_testsuite"};
	$advanced_value_type           = $_POST{"select_type"};
	$advanced_value_test_set       = $_POST{"select_testset"};
	$advanced_value_component      = $_POST{"select_com"};

	ScanPackages();
	CountPackages();
	AnalysisVersion();
	CreateFilePath();
	AnalysisTestsXML();
	FilterCaseValue();
	FilterCase();
	UpdateViewPageSelectItem();

	for ( my $count = 0 ; $count < $package_name_number ; $count++ ) {
		$view_package_name_flag[$count] = $package_name_flag[$count];
	}
	ViewDetailedInfo();
}

elsif ( $_POST{'list_view_filter_pkg_info'} ) {
	$list_view_current = 1;
	$tree_view_current = 0;
	my $list_file = $test_definition_dir . "list_view_case.xml";
	$refresh_flag             = 0;
	$view_page_no_filter_flag = 0;
	syncDefinition();
	$advanced_value_version      = $_POST{"select_ver"};
	$advanced_value_architecture = $_POST{"select_arc"};

	$advanced_value_category       = $_POST{"select_category"};
	$advanced_value_priority       = $_POST{"select_pri"};
	$advanced_value_status         = $_POST{"select_status"};
	$advanced_value_execution_type = $_POST{"select_exe"};
	$advanced_value_test_suite     = $_POST{"select_testsuite"};
	$advanced_value_type           = $_POST{"select_type"};
	$advanced_value_test_set       = $_POST{"select_testset"};
	$advanced_value_component      = $_POST{"select_com"};

	ScanPackages();
	CountPackages();
	AnalysisVersion();
	CreateFilePath();
	AnalysisTestsXML();
	FilterCaseValue();
	FilterCase();
	UpdateViewPageSelectItem();

	for ( my $count = 0 ; $count < $package_name_number ; $count++ ) {
		$view_package_name_flag[$count] = $package_name_flag[$count];
	}
	ListViewDetailedInfo($list_file);

	print <<DATA;
<table width="768" border="0" cellspacing="0" cellpadding="0" class="report_list" style="table-layout:fixed">	
  <tr>
    <td>
DATA
	print xml2xsl_case($list_file);
	print <<DATA;
    </td>
  </tr>
  </table>
DATA
}

#press load button
elsif ( $_GET{'load_profile_button'} ) {
	$refresh_flag = 0;
	syncDefinition();
	my $file;
	my $flag_i            = 0;
	my $load_profile_name = $_GET{"load_profile_button"};
	my $dir_profile_name  = $profile_dir_manager;

	opendir LOADPROFILE, $dir_profile_name
	  or die "can not open $dir_profile_name";
	open IN, $profile_dir_manager . $load_profile_name or die $!;

	foreach $file ( readdir LOADPROFILE ) {
		if ( $file =~ /$load_profile_name/ ) {
			my $temp;
			my %temp;
			my @temp;
			while (<IN>) {
				if ( $_ =~ /select_ver/ ) {
					$temp                   = $_;
					@temp                   = split /=/, $temp;
					$advanced_value_version = $temp[1];
				}
				elsif ( $_ =~ /select_arc/ ) {
					$temp                        = $_;
					@temp                        = split /=/, $temp;
					$advanced_value_architecture = $temp[1];
				}
				elsif ( $_ =~ /select_category/ ) {
					$temp                    = $_;
					@temp                    = split /=/, $temp;
					$advanced_value_category = $temp[1];
				}
				elsif ( $_ =~ /select_pri/ ) {
					$temp                    = $_;
					@temp                    = split /=/, $temp;
					$advanced_value_priority = $temp[1];
				}
				elsif ( $_ =~ /select_status/ ) {
					$temp                  = $_;
					@temp                  = split /=/, $temp;
					$advanced_value_status = $temp[1];
				}
				elsif ( $_ =~ /select_exe/ ) {
					$temp                          = $_;
					@temp                          = split /=/, $temp;
					$advanced_value_execution_type = $temp[1];
				}
				elsif ( $_ =~ /select_testsuite/ ) {
					$temp                      = $_;
					@temp                      = split /=/, $temp;
					$advanced_value_test_suite = $temp[1];
				}
				elsif ( $_ =~ /select_type/ ) {
					$temp                = $_;
					@temp                = split /=/, $temp;
					$advanced_value_type = $temp[1];
				}
				elsif ( $_ =~ /select_testset/ ) {
					$temp                    = $_;
					@temp                    = split /=/, $temp;
					$advanced_value_test_set = $temp[1];
				}
				elsif ( $_ =~ /select_com/ ) {
					$temp                     = $_;
					@temp                     = split /=/, $temp;
					$advanced_value_component = $temp[1];
				}
				elsif ( $_ =~ /select-packages/ ) {
					$temp = $_;
					@temp = split /:/, $temp;
					push( @checkbox_packages, $temp[1] );
				}
			}
		}
	}

	ScanPackages();
	@sort_package_name = sort @package_name;
	@package_name      = @sort_package_name;

	CountPackages();

	AnalysisVersion();

	CreateFilePath();

	AnalysisTestsXML();

	$count_package_number_post = $package_name_number;

	FilterCaseValue();
	FilterCase();
	UpdateLoadPage($load_profile_name);

	closedir LOADPROFILE;
}
else {
	syncDefinition();
	ScanPackages();
	CountPackages();
	@sort_package_name = sort @package_name;
	@package_name      = @sort_package_name;
	AnalysisVersion();
	my $i = @package_name;
	if ( $i eq "0" ) {
		FilterCaseValue();
		UpdateNullPage();

	}
	else {
		FilterCaseValue();
		UpdatePage();
	}
}

#update custom page
sub UpdatePage {
	CountPackages();

	print "HTTP/1.0 200 OK" . CRLF;
	print "Content-type: text/html" . CRLF . CRLF;

	print_header( "$MTK_BRANCH Manager Main Page", "custom" );

	CreateFilePath();

	AnalysisTestsXML();

	AnalysisReadMe();

	GetSelectItem();
	print show_error_dlg("");
	print <<DATA;
	<div id="ajax_loading" style="display:none"></div>
	<iframe id='popIframe' class='popIframe' frameborder='0' ></iframe>
	<div id="popDiv" class="mydiv" style="overflow-y:auto;overflow-x:auto;height:460px;display:none";></div>
	<table width="768" border="0" cellspacing="0" cellpadding="0" frame="void" rules="all" style="table-layout:fixed">
	  <tr>
	    <td><form id="tests_custom" name="tests_custom" method="post" action="">
	      <table width="100%" height="30" border="0" cellspacing="0" cellpadding="0">
	        <tr>
	          <td><table width="100%" height="30" border="0" cellspacing="0" cellpadding="0" class="top_button_bg">
	            <tr>
	              <td width="2.5%" height="30" nowrap="nowrap">&nbsp;</td>
	              <td width="17%" height="30" nowrap="nowrap"><table width="100%" border="0" cellspacing="0" cellpadding="0">
	                <tr>
	                  <td width="47%" height="30" align="right" class="custom_title">Architecture &nbsp</td>
	                  <td width="53%" height="30"><select id="select_arc" name="select_arc" class="custom_select">
	                    <option>X86</option>
	                  </select>                  </td>
	                </tr>
	              </table></td>
	              <td width="13%" height="30" nowrap="nowrap"><table width="100%" border="0" cellspacing="0" cellpadding="0">
	                <tr>
	                <td width="13%" height="30" nowrap="nowrap">&nbsp;</td>
	                  <td width="37%" height="30" align="right" class="custom_title">Version &nbsp</td>
	                  <td width="50%" height="30" ><select id="select_ver" name="select_ver" class="custom_select" onchange="javascript:filter_case_item();">
DATA
	DrawVersionSelect();
	print <<DATA;
                  </select></td>
                </tr>
              </table></td>
              <td width="2%" height="30" nowrap="nowrap">&nbsp;</td>
              <td width="4%" height="30" id="name" nowrap="nowrap" class="custom_title">Name &nbsp</td>
              <td width="4.5%" height="30" nowrap="nowrap"><img id="sort_packages" title="Sort packages" src="images/up_and_down_1.png" width="23" height="23" onclick="javascript:sortPackages()"/></a></td>
              <td width="12%" height="30" nowrap="nowrap"><input id="button_adv" name="button_adv" title="Show advanced list" class="medium_button" type="button" value="Advanced" onclick="javascript:hidden_Advanced_List();"/></td>
              <td width="12%" height="30" align="left" nowrap="nowrap">
				<input id="update_package_list" name="update_package_list" class="medium_button" type="button" value="Update" title="Scan repos, and list uninstalled or later-version packages." onclick="javascript:onUpdatePackages();"/>
			  </td>
			  <td width="4.5%" height="30" nowrap="nowrap"><img id="progress_waiting" src="images/ajax_progress.gif" width="14" height="14"/></a></td>
              <td width="33%" height="30" nowrap="nowrap">&nbsp;</td>
            </tr>
          </table></td>
        </tr>
        <tr>
          <td id="list_advanced" style="display:none"><table width="768" border="0" cellspacing="0" cellpadding="0" frame="below" rules="none">
            <tr>
              <td width="50%" height="30" nowrap="nowrap" class="custom_list_type_bottomright"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="30" align="left" class="custom_title">&nbsp;Category</td><td>
                    <select name="select_category" align="20px" id="select_category" class="custom_select" style="width:70%" onchange="javascript:filter_case_item();">
DATA
	DrawCategorySelect();
	print <<DATA;
                    </select>                    </td>
                </tr>
              </table></td>
              <td width="50%" height="30" nowrap="nowrap" class="custom_list_type_bottom"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="30" align="left" class="custom_title">&nbsp;Priority<td>
                    <select name="select_pri" id="select_pri" class="custom_select" style="width:70%" onchange="javascript:filter_case_item();">
DATA
	DrawPrioritySelect();
	print <<DATA;
                    </select>                    </td>
                </tr>
              </table></td>
            </tr>
            <tr>
              <td width="30%" height="30" nowrap="nowrap" class="custom_list_type_bottomright"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="30" align="left" class="custom_title">&nbsp;Status<td>
                    <select name="select_status" id="select_status" class="custom_select" style="width:70%" onchange="javascript:filter_case_item();">
DATA
	DrawStatusSelect();
	print <<DATA;
                    </select>                    </td>
                </tr>
              </table></td>
              <td width="50%" height="30" nowrap="nowrap" class="custom_list_type_bottom"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="30" align="left" class="custom_title">&nbsp;Execution Type<td>
                    <select name="select_exe" id="select_exe" class="custom_select" style="width:70%" onchange="javascript:filter_case_item();">
DATA
	DrawExecutiontypeSelect();
	print <<DATA;
                    </select>                    </td>
                </tr>
              </table></td>
            </tr>
            <tr>
              <td width="50%" height="30" nowrap="nowrap" class="custom_list_type_bottomright"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="30" align="left" class="custom_title">&nbsp;Test Suite<td>
                    <select name="select_testsuite" id="select_testsuite" class="custom_select" style="width:70%" onchange="javascript:filter_case_item();">
DATA
	DrawTestsuiteSelect();
	print <<DATA;
                    </select>                    </td>
                </tr>
              </table></td>
              <td width="50%" height="30" nowrap="nowrap" class="custom_list_type_bottom"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="30" align="left" class="custom_title">&nbsp;Type<td>
                    <select name="select_type" id="select_type" class="custom_select" style="width:70%" onchange="javascript:filter_case_item();">
DATA
	DrawTypeSelect();
	print <<DATA;
                    </select>                    </td>
                </tr>
              </table></td>
            </tr>
            <tr>
              <td width="50%" height="30" nowrap="nowrap" class="custom_list_type_bottomright"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                  <tr>
                    <td width="30%" height="30" align="left" class="custom_title">&nbsp;Test Set<td>
                      <select name="select_testset" id="select_testset" class="custom_select" style="width:70%" onchange="javascript:filter_case_item();">
DATA
	DrawTestsetSelect();
	print <<DATA;
                    </select>                    </td>
                  </tr>
              </table></td>
              <td width="50%" height="30" nowrap="nowrap" class="custom_list_type_bottom"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                 <tr>
                  <td width="30%" height="30" align="left" class="custom_title">&nbsp;Component<td>
                    <select name="select_com" id="select_com" class="custom_select" style="width:70%" onchange="javascript:filter_case_item();">
DATA
	DrawComponentSelect();
	print <<DATA;
                    </select>                    </td>
                </tr>
              </table></td>
            </tr>
          </table></td>
        </tr>
        <tr>
          <td></td>
        </tr>
        <tr>
          <td><table width="100%" height="30" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
            <tr>
              <td><table width="100%" height="30" border="1" cellspacing="0" cellpadding="0" style="table-layout:fixed" frame="below" rules="all">
                <tr>
              <td width="4%" height="30" align="center" valign="middle" class="custom_list_type_bottomright_title"><input type="checkbox" id="checkbox_all"  name="checkbox_all" value="checkbox_all" onclick="javascript:check_uncheck_all();" /></td>
              <td width="0.5%" height="30" align="left" class="custom_list_type_bottom"></td>
              <td width="23.5%" height="30" align="left" class="custom_list_type_bottomright_title">Package Name</td>
              <td width="24%" height="30" align="left" class="custom_list_type_bottomright_title">&nbsp;Case Number</td>
              <td width="24%" height="30" align="left" class="custom_list_type_bottomright_title">&nbsp;Version</td>
              <td width="24%" height="30" align="left" class="custom_list_type_bottom_title">&nbsp;Operation</td>
              <input type="hidden" id="package_name_number" name="package_name_number" value="$package_name_number">
                </tr>
              </table></td>
            </tr>
DATA
	DrawPackageList();
	DrawUninstallPackageList();

	my $profiles_list = "";
	if ( opendir( DIR, $SERVER_PARAM{'APP_DATA'} . '/profiles/test' ) ) {
		my @files = sort grep !/^[\.~]/, readdir(DIR);
		foreach (@files) {
			my $profile_name = $_;
			$profiles_list .=
			  "    <option value=\"$profile_name\">$profile_name</option>\n";
		}
	}
	print <<DATA;
            </tr>
          </table></td>
        </tr>
        <tr>
        <td height="4" width="100%" class="backbackground_button"></td>
        </tr>
        <tr>
          <td><table width="100%" height="30" border="0" class="backbackground_button custom_font" cellpadding="0" cellspacing="0">
            <tr>
              <td width="10%" align="center"><input type="button" id="execute_profile" name="execute_profile" title="Execute selected packages" class="large_button" disabled="true" value="Execute" onclick="javascript:onExecute();" /></td>
              <td width="10%" align="center"><input type="submit" id="view_package_info" name="view_package_info" class="large_button" disabled="true" value="View" title="View detailed information of selected packages" /></td>
              <td width="40%">&nbsp;</td>
              <td width="10%" align="center">Test Plan</td>
              <td width="10%" align="center"><input name="save_profile_panel_button" id="save_profile_panel_button" title="Open save test plan panel" type="button" class="medium_button" value="Save" disabled="true" onclick="javascript:show_save_panel();" /></td>
              <td width="10%" align="center"><input name="load_profile_panel_button" id="load_profile_panel_button" title="Open load test plan panel" type="button" class="medium_button" value="Load" onclick="javascript:show_load_panel();" /></td>
              <td width="10%" align="center"><input name="manage_profile_panel_button" id="manage_profile_panel_button" title="Open manage test plan panel" type="button" class="medium_button" value="Manage" onclick="javascript:show_manage_panel();" /></td>
            </tr>
            <tr id="save_profile_panel" style="display:none">
              <td height="60" colspan="7"><table width="100%" height="60">
                <tr>
                  <td width="5%">&nbsp;</td>
                  <td width="30%" align="left">Save as a new test plan</td>
                  <td width="20%" align="left"><input name="save_test_plan_text" type="text" class="test_plan_name" id="save_test_plan_text" /></td>
                  <td width="20%">&nbsp;</td>
                  <td width="10%" align="center"><input name="save_profile_button_text" id="save_profile_button_text" title="Save test plan" type="button" class="medium_button" value="Save" onclick="javascript:save_profile('text');" /></td>
                  <td width="10%">&nbsp;</td>
                  <td width="5%">&nbsp;</td>
                </tr>
                <tr>
DATA
	if ( $profiles_list ne "" ) {
		print <<DATA;
                  <td width="5%">&nbsp;</td>
                  <td width="30%" align="left">Overwrite an existing test plan</td>
                  <td width="20%" align="left"><select name="save_test_plan_select" id="save_test_plan_select" style="width: 11em;">$profiles_list</select></td>
                  <td width="20%">&nbsp;</td>
                  <td width="10%" align="center"><input name="save_profile_button_select" id="save_profile_button_select" title="Save test plan" type="button" class="medium_button" value="Save" onclick="javascript:save_profile('select');" /></td>
                  <td width="10%" align="center"><input name="view_profile_button_save" id="view_profile_button_save" title="View test plan" type="button" class="medium_button" value="View" onclick="javascript:view_profile('save');" /></td>
                  <td width="5%">&nbsp;</td>
DATA
	}
	else {
		print <<DATA;
                  <td width="5%">&nbsp;</td>
                  <td width="30%" align="left">Overwrite an existing test plan</td>
                  <td width="20%" align="left"><select name="save_test_plan_select" id="save_test_plan_select" style="width: 11em;" disabled="disabled"><option>&lt;no plans present&gt;</option></select></td>
                  <td width="20%">&nbsp;</td>
                  <td width="10%" align="center"><input name="save_profile_button_select" id="save_profile_button_select" title="Save test plan" type="button" class="medium_button" value="Save" disabled="disabled" onclick="javascript:save_profile('select');" /></td>
                  <td width="10%" align="center"><input name="view_profile_button_save" id="view_profile_button_save" title="View test plan" type="button" class="medium_button" value="View" disabled="disabled" onclick="javascript:view_profile('save');" /></td>
                  <td width="5%">&nbsp;</td>
DATA
	}
	print <<DATA;
                </tr>
              </table></td>
            </tr>
            <tr id="load_profile_panel" style="display:none">
              <td height="30" colspan="7"><table width="100%" height="30">
                <tr>
DATA
	if ( $profiles_list ne "" ) {
		print <<DATA;
                  <td width="5%">&nbsp;</td>
                  <td width="30%" align="left">Choose from existing test plans</td>
                  <td width="20%" align="left"><select name="load_test_plan_select" id="load_test_plan_select" style="width: 11em;">$profiles_list</select></td>
                  <td width="20%">&nbsp;</td>
                  <td width="10%" align="center"><input name="load_profile_button" id="load_profile_button" title="Load test plan" type="button" class="medium_button" value="Load" onclick="javascript:load_profile();" /></td>
                  <td width="10%" align="center"><input name="view_profile_button_load" id="view_profile_button_load" title="View test plan" type="button" class="medium_button" value="View" onclick="javascript:view_profile('load');" /></td>
                  <td width="5%">&nbsp;</td>
DATA
	}
	else {
		print <<DATA;
                  <td width="5%">&nbsp;</td>
                  <td width="30%" align="left">Choose from existing test plans</td>
                  <td width="20%" align="left"><select name="load_test_plan_select" id="load_test_plan_select" style="width: 11em;" disabled="disabled"><option>&lt;no plans present&gt;</option></select></td>
                  <td width="20%">&nbsp;</td>
                  <td width="10%" align="center"><input name="load_profile_button" id="load_profile_button" title="Load test plan" type="button" class="medium_button" value="Load" disabled="disabled" onclick="javascript:load_profile();" /></td>
                  <td width="10%" align="center"><input name="view_profile_button_load" id="view_profile_button_load" title="View test plan" type="button" class="medium_button" value="View" disabled="disabled" onclick="javascript:view_profile('load');" /></td>
                  <td width="5%">&nbsp;</td>
DATA
	}
	print <<DATA;
                </tr>
              </table></td>
            </tr>
            <tr id="manage_profile_panel" style="display:none">
              <td height="30" colspan="7"><table width="100%" height="30">
                <tr>
DATA
	if ( $profiles_list ne "" ) {
		print <<DATA;
                  <td width="5%">&nbsp;</td>
                  <td width="30%" align="left">Existing test plans</td>
                  <td width="20%" align="left"><select name="manage_test_plan_select" id="manage_test_plan_select" style="width: 11em;">$profiles_list</select></td>
                  <td width="20%">&nbsp;</td>
                  <td width="10%" align="center"><input name="view_profile_button_manage" id="view_profile_button_manage" title="View test plan" type="button" class="medium_button" value="View" onclick="javascript:view_profile('manage');" /></td>
                  <td width="10%" align="center"><input name="delete_profile_button" id="delete_profile_button" title="Delete test plan" type="button" class="medium_button" value="Delete" onclick="javascript:delete_profile();" /></td>
                  <td width="5%">&nbsp;</td>
DATA
	}
	else {
		print <<DATA;
                  <td width="5%">&nbsp;</td>
                  <td width="30%" align="left">Existing test plans</td>
                  <td width="20%" align="left"><select name="manage_test_plan_select" id="manage_test_plan_select" style="width: 11em;" disabled="disabled"><option>&lt;no plans present&gt;</option></select></td>
                  <td width="20%">&nbsp;</td>
                  <td width="10%" align="center"><input name="view_profile_button_manage" id="view_profile_button_manage" title="View test plan" type="button" class="medium_button" value="View" disabled="disabled" onclick="javascript:view_profile('manage');" /></td>
                  <td width="10%" align="center"><input name="delete_profile_button" id="delete_profile_button" title="Delete test plan" type="button" class="medium_button" value="Delete" disabled="disabled" onclick="javascript:delete_profile();" /></td>
                  <td width="5%">&nbsp;</td>
DATA
	}
	print <<DATA;
                </tr>
              </table></td>
            </tr>
          </table></td>
        </tr>
      </table>
DATA
}

#When no packages in device, update the page.
sub UpdateNullPage {
	@sort_package_name = sort @package_name;
	@package_name      = @sort_package_name;
	$image             = "images/up_and_down_1.png";

	print "HTTP/1.0 200 OK" . CRLF;
	print "Content-type: text/html" . CRLF . CRLF;

	print_header( "$MTK_BRANCH Manager Main Page", "custom" );
	print show_error_dlg("");
	print <<DATA;
	<div id="ajax_loading" style="display:none"></div>
	<iframe id='popIframe' class='popIframe' frameborder='0' ></iframe>
	<div id="popDiv" class="mydiv" style="overflow-y:auto;overflow-x:auto;height:460px;display:none";></div>
	<table width="768" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
	  <tr>
	    <td><form id="tests_custom" name="tests_custom" method="post" action="">
	      <table width="100%" height="30" border="0" cellspacing="0" cellpadding="0">
	        <tr>
	          <td><table width="100%" height="30" border="0" cellspacing="0" cellpadding="0" class="top_button_bg">
	            <tr>
	              <td width="2.5%" height="30" nowrap="nowrap">&nbsp;</td>
	              <td width="17%" height="30" nowrap="nowrap"><table width="100%" border="0" cellspacing="0" cellpadding="0">
	                <tr>
	                  <td width="47%" height="30" align="right" class="custom_title">Architecture&nbsp</td>
	                  <td width="53%" height="30"><select id="select_arc" name="select_arc" class="custom_select">
	                    <option>X86</option>
	                  </select>                  </td>
	                </tr>
	              </table></td>
	              <td width="13%" height="30" nowrap="nowrap"><table width="100%" border="0" cellspacing="0" cellpadding="0">
	                <tr>
	                <td width="13%" height="30" nowrap="nowrap">&nbsp;</td>
	                  <td width="37%" height="30" align="right" class="custom_title">Version&nbsp</td>
	                  <td width="50%" height="30" ><select id="select_ver" name="select_ver" value="Any Version" class="custom_select" onchange="javascript:filter_case_item();">
                  <option>Any Version</option>
                  </select></td>
                </tr>
              </table></td>
              <td width="2%" height="30" nowrap="nowrap">&nbsp;</td>
              <td width="4%" height="30" id="name" nowrap="nowrap" class="custom_title">Name&nbsp</td>
              <td width="4.5%" height="30" nowrap="nowrap"><a id="sort_packages" title="Sort packages" href="tests_custom.pl?order=$value"><img src="$image" width="23" height="23"/></a></td>
              <td width="12%" height="30" nowrap="nowrap"><input id="button_adv" name="button_adv" title="Show advanced list" class="medium_button" type="button" value="Advanced" disabled="true" onclick="javascript:hidden_Advanced_List();"/></td>
              <td width="12%" align="left" height="30" nowrap="nowrap">
				<input id="update_package_list" name="update_package_list" class="medium_button" type="button" value="Update" title="Scan repos, and list uninstalled or later-version packages." onclick="javascript:onUpdatePackages();"/>
			  </td>
			  <td width="4.5%" height="30" nowrap="nowrap"><img id="progress_waiting" src="images/ajax_progress.gif" width="14" height="14"/></a></td>
              <td width="33%" height="30" nowrap="nowrap">&nbsp;</td>
            </tr>
          </table></td>
        </tr>
        <tr>
          <td id="list_advanced" style="display:none"><table width="768" border="0" cellspacing="0" cellpadding="0" frame="below" rules="none">
            <tr>
              <td width="50%" height="30" nowrap="nowrap" class="custom_list_type_bottomright"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="30" align="left" class="custom_title">&nbsp;Category</td><td>
                    <select name="select_category" align="20px" id="select_category" class="custom_select" value="Any Category" style="width:70%" onchange="javascript:filter_case_item();">
                    <option>Any Category</option>
                    </select>                    </td>
                </tr>
              </table></td>
              <td width="50%" height="30" nowrap="nowrap" class="custom_list_type_bottom"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="30" align="left" class="custom_title">&nbsp;Priority<td>
                    <select name="select_pri" id="select_pri" class="custom_select" value="And Priority" style="width:70%" onchange="javascript:filter_case_item();">
                    <option>Any Priority</option>
                    </select>                    </td>
                </tr>
              </table></td>
            </tr>
            <tr>
              <td width="30%" height="30" nowrap="nowrap" class="custom_list_type_bottomright"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="30" align="left" class="custom_title">&nbsp;Status<td>
                    <select name="select_status" id="select_status" class="custom_select" value="Any Status" style="width:70%" onchange="javascript:filter_case_item();">
                    <option>Any Status</option>
                    </select>                    </td>
                </tr>
              </table></td>
              <td width="50%" height="30" nowrap="nowrap" class="custom_list_type_bottom"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="30" align="left" class="custom_title">&nbsp;Execution Type<td>
                    <select name="select_exe" id="select_exe" class="custom_select" value="Any Execution Type" style="width:70%" onchange="javascript:filter_case_item();">
                    <option>Any Execution Type</option>
                    </select>                    </td>
                </tr>
              </table></td>
            </tr>
            <tr>
              <td width="50%" height="30" nowrap="nowrap" class="custom_list_type_bottomright"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="30" align="left" class="custom_title">&nbsp;Test Suite<td>
                    <select name="select_testsuite" id="select_testsuite" class="custom_select" value="Any Test Suite" style="width:70%" onchange="javascript:filter_case_item();">
                    <option>Any Test Suite</option>
                    </select>                    </td>
                </tr>
              </table></td>
              <td width="50%" height="30" nowrap="nowrap" class="custom_list_type_bottom"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="30" align="left" class="custom_title">&nbsp;Type<td>
                    <select name="select_type" id="select_type" class="custom_select" value="Any Type" style="width:70%" onchange="javascript:filter_case_item();">
                    <option>Any Type</option>
                    </select>                    </td>
                </tr>
              </table></td>
            </tr>
            <tr>
              <td width="50%" height="30" nowrap="nowrap" class="custom_list_type_bottomright"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                  <tr>
                    <td width="30%" height="30" align="left" class="custom_title">&nbsp;Test Set<td>
                      <select name="select_testset" id="select_testset" class="custom_select" value="Any Test Set" style="width:70%" onchange="javascript:filter_case_item();">
                    <option>Any Test Set</option>
                    </select>                    </td>
                  </tr>
              </table></td>
              <td width="50%" height="30" nowrap="nowrap" class="custom_list_type_bottom"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                 <tr>
                  <td width="30%" height="30" align="left" class="custom_title">&nbsp;Component<td>
                    <select name="select_com" id="select_com" class="custom_select" value="Any Component" style="width:70%" onchange="javascript:filter_case_item();">
                    <option>Any Component</option>
                    </select>                    </td>
                </tr>
              </table></td>
            </tr>
          </table></td>
        </tr>
        <tr>
          <td></td>
        </tr>
        <tr>
          <td><table width="100%" height="30" border="0" cellspacing="0" cellpadding="0" frame="void" rules="all">
            <tr>
              <td><table width="100%" height="30" border="1" cellspacing="0" cellpadding="0" frame="below" rules="all">
                <tr>
              <td width="4%" height="22" align="center" valign="middle" class="custom_list_type_bottomright_title"><input type="checkbox" id="checkbox_all"  name="checkbox_all" value="checkbox_all" onclick="javascript:check_uncheck_all();" /></td>
              <td width="24%" height="30" align="left" class="custom_list_type_bottomright_title">&nbsp;Package Name</td>
              <td width="24%" height="30" align="left" class="custom_list_type_bottomright_title">&nbsp;Case Number</td>
              <td width="24%" height="30" align="left" class="custom_list_type_bottomright_title">&nbsp;Version</td>
              <td width="24%" height="30" align="left" class="custom_list_type_bottom_title">&nbsp;Opreation</td>
                </tr>
              </table></td>
            </tr>
            </tr>
          </table></td>
        </tr>
        <input type="hidden" id="package_name_number" name="package_name_number" value="$package_name_number">
        <tr><table width="100%" height="300" border="0" id="update_null_page_div" align="center" class="backbackground_button" cellpadding="0" cellspacing="0" style="display:">
        	<tr>
        		<td width="100%" align="center" class="custom_list_type_bottomright_packagename" id="update_null_page" name="update_null_page">No packages, please click Update button , install packages, then click reload button to refresh page!</td>
        	</tr>
        </table>
        </tr>
DATA
	DrawUninstallPackageList();

	my $profiles_list = "";
	if ( opendir( DIR, $SERVER_PARAM{'APP_DATA'} . '/profiles/test' ) ) {
		my @files = sort grep !/^[\.~]/, readdir(DIR);
		foreach (@files) {
			my $profile_name = $_;
			$profiles_list .=
			  "    <option value=\"$profile_name\">$profile_name</option>\n";
		}
	}
	print <<DATA;
            </tr>
          </table></td>
        </tr>
        <tr>
        <td height="4" width="100%" class="backbackground_button"></td>
        </tr>
        <tr>
          <td><table width="768" height="30" border="0" class="backbackground_button custom_font" cellpadding="0" cellspacing="0">
            <tr>
              <td width="10%" align="center"><input type="button" id="execute_profile" name="execute_profile" title="Execute selected packages" class="large_button" disabled="true" value="Execute" onclick="javascript:onExecute();" /></td>
              <td width="10%" align="center"><input type="submit" id="view_package_info" name="view_package_info" class="large_button" disabled="true" value="View" title="View detailed information of selected packages" /></td>
              <td width="40%">&nbsp;</td>
              <td width="10%" align="center">Test Plan</td>
              <td width="10%" align="center"><input name="save_profile_panel_button" id="save_profile_panel_button" title="Open save test plan panel" type="button" class="medium_button" value="Save" disabled="true" onclick="javascript:show_save_panel();" /></td>
              <td width="10%" align="center"><input name="load_profile_panel_button" id="load_profile_panel_button" title="Open load test plan panel" type="button" class="medium_button" value="Load" onclick="javascript:show_load_panel();" /></td>
              <td width="10%" align="center"><input name="manage_profile_panel_button" id="manage_profile_panel_button" title="Open manage test plan panel" type="button" class="medium_button" value="Manage" onclick="javascript:show_manage_panel();" /></td>
            </tr>
            <tr id="save_profile_panel" style="display:none">
              <td height="60" colspan="7"><table width="100%" height="60">
                <tr>
                  <td width="5%">&nbsp;</td>
                  <td width="30%" align="left">Save as a new test plan</td>
                  <td width="20%" align="left"><input name="save_test_plan_text" type="text" class="test_plan_name" id="save_test_plan_text" /></td>
                  <td width="20%">&nbsp;</td>
                  <td width="10%" align="center"><input name="save_profile_button_text" id="save_profile_button_text" title="Save test plan" type="button" class="medium_button" value="Save" onclick="javascript:save_profile('text');" /></td>
                  <td width="10%">&nbsp;</td>
                  <td width="5%">&nbsp;</td>
                </tr>
                <tr>
DATA
	if ( $profiles_list ne "" ) {
		print <<DATA;
                  <td width="5%">&nbsp;</td>
                  <td width="30%" align="left">Overwrite an existing test plan</td>
                  <td width="20%" align="left"><select name="save_test_plan_select" id="save_test_plan_select" style="width: 11em;">$profiles_list</select></td>
                  <td width="20%">&nbsp;</td>
                  <td width="10%" align="center"><input name="save_profile_button_select" id="save_profile_button_select" title="Save test plan" type="button" class="medium_button" value="Save" onclick="javascript:save_profile('select');" /></td>
                  <td width="10%" align="center"><input name="view_profile_button_save" id="view_profile_button_save" title="View test plan" type="button" class="medium_button" value="View" onclick="javascript:view_profile('save');" /></td>
                  <td width="5%">&nbsp;</td>
DATA
	}
	else {
		print <<DATA;
                  <td width="5%">&nbsp;</td>
                  <td width="30%" align="left">Overwrite an existing test plan</td>
                  <td width="20%" align="left"><select name="save_test_plan_select" id="save_test_plan_select" style="width: 11em;" disabled="disabled"><option>&lt;no plans present&gt;</option></select></td>
                  <td width="20%">&nbsp;</td>
                  <td width="10%" align="center"><input name="save_profile_button_select" id="save_profile_button_select" title="Save test plan" type="button" class="medium_button" value="Save" disabled="disabled" onclick="javascript:save_profile('select');" /></td>
                  <td width="10%" align="center"><input name="view_profile_button_save" id="view_profile_button_save" title="View test plan" type="button" class="medium_button" value="View" disabled="disabled" onclick="javascript:view_profile('save');" /></td>
                  <td width="5%">&nbsp;</td>
DATA
	}
	print <<DATA;
                </tr>
              </table></td>
            </tr>
            <tr id="load_profile_panel" style="display:none">
              <td height="30" colspan="7"><table width="100%" height="30">
                <tr>
DATA
	if ( $profiles_list ne "" ) {
		print <<DATA;
                  <td width="5%">&nbsp;</td>
                  <td width="30%" align="left">Choose from existing test plans</td>
                  <td width="20%" align="left"><select name="load_test_plan_select" id="load_test_plan_select" style="width: 11em;">$profiles_list</select></td>
                  <td width="20%">&nbsp;</td>
                  <td width="10%" align="center"><input name="load_profile_button" id="load_profile_button" title="Load test plan" type="button" class="medium_button" value="Load" onclick="javascript:load_profile();" /></td>
                  <td width="10%" align="center"><input name="view_profile_button_load" id="view_profile_button_load" title="View test plan" type="button" class="medium_button" value="View" onclick="javascript:view_profile('load');" /></td>
                  <td width="5%">&nbsp;</td>
DATA
	}
	else {
		print <<DATA;
                  <td width="5%">&nbsp;</td>
                  <td width="30%" align="left">Choose from existing test plans</td>
                  <td width="20%" align="left"><select name="load_test_plan_select" id="load_test_plan_select" style="width: 11em;" disabled="disabled"><option>&lt;no plans present&gt;</option></select></td>
                  <td width="20%">&nbsp;</td>
                  <td width="10%" align="center"><input name="load_profile_button" id="load_profile_button" title="Load test plan" type="button" class="medium_button" value="Load" disabled="disabled" onclick="javascript:load_profile();" /></td>
                  <td width="10%" align="center"><input name="view_profile_button_load" id="view_profile_button_load" title="View test plan" type="button" class="medium_button" value="View" disabled="disabled" onclick="javascript:view_profile('load');" /></td>
                  <td width="5%">&nbsp;</td>
DATA
	}
	print <<DATA;
                </tr>
              </table></td>
            </tr>
            <tr id="manage_profile_panel" style="display:none">
              <td height="30" colspan="7"><table width="100%" height="30">
                <tr>
DATA
	if ( $profiles_list ne "" ) {
		print <<DATA;
                  <td width="5%">&nbsp;</td>
                  <td width="30%" align="left">Existing test plans</td>
                  <td width="20%" align="left"><select name="manage_test_plan_select" id="manage_test_plan_select" style="width: 11em;">$profiles_list</select></td>
                  <td width="20%">&nbsp;</td>
                  <td width="10%" align="center"><input name="view_profile_button_manage" id="view_profile_button_manage" title="View test plan" type="button" class="medium_button" value="View" onclick="javascript:view_profile('manage');" /></td>
                  <td width="10%" align="center"><input name="delete_profile_button" id="delete_profile_button" title="Delete test plan" type="button" class="medium_button" value="Delete" onclick="javascript:delete_profile();" /></td>
                  <td width="5%">&nbsp;</td>
DATA
	}
	else {
		print <<DATA;
                  <td width="5%">&nbsp;</td>
                  <td width="30%" align="left">Existing test plans</td>
                  <td width="20%" align="left"><select name="manage_test_plan_select" id="manage_test_plan_select" style="width: 11em;" disabled="disabled"><option>&lt;no plans present&gt;</option></select></td>
                  <td width="20%">&nbsp;</td>
                  <td width="10%" align="center"><input name="view_profile_button_manage" id="view_profile_button_manage" title="View test plan" type="button" class="medium_button" value="View" disabled="disabled" onclick="javascript:view_profile('manage');" /></td>
                  <td width="10%" align="center"><input name="delete_profile_button" id="delete_profile_button" title="Delete test plan" type="button" class="medium_button" value="Delete" disabled="disabled" onclick="javascript:delete_profile();" /></td>
                  <td width="5%">&nbsp;</td>
DATA
	}
	print <<DATA;
                </tr>
              </table></td>
            </tr>
          </table></td>
        </tr>
      </table>
DATA
}

#After press View button, Update the page.
sub ViewDetailedInfo {
	my $xml = "none";
	my %caseInfo;
	my $case_count_flag = 0;
	print <<DATA;
	<tr>
		<td><table width="100%" height="600px" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none" style="table-layout:fixed">
        	<tr>
	            <td width="1%" class="report_list_one_row" style="background-color:#E9F6FC">&nbsp;</td>
	            <td width="29%" height="600px" valign="top" class="view_package_list_info" style="text-wrap:none;background-color:#E9F6FC">
					<div id="tree_area_package" style="overflow-y:auto;overflow-x:auto;height:600px;width:100%" >
						<div class='view_no_match_testcase_message' id="no_match_testcase_message" style="display:none">No match testcase!</div>
						<div class='view_no_match_testcase_message' id="no_select_testcase_message" style="display:none">Please select testcase!</div>
					</div>
				</td>			
DATA

	print <<DATA;
<script type="text/javascript" src="run_tests.js"></script>
<script language="javascript" type="text/javascript">
// <![CDATA[
// package tree
//global variable to allow console inspection of tree:

drawCaseTree();
// anonymous function wraps the remainder of the logic:
function drawCaseTree() {
	var tree;

	// function to initialize the tree:
	function treeInit() {
		buildTree();
	}

	// Function creates the tree
	function buildTree() {

		// instantiate the tree:
		tree = new YAHOO.widget.TreeView("tree_area_package");
DATA

	my $package_number                    = 1;
	my $count                             = 0;
	my $advanced_value_category_tmp       = $advanced_value_category;
	my $advanced_value_test_suite_tmp     = $advanced_value_test_suite;
	my $advanced_value_test_set_tmp       = $advanced_value_test_set;
	my $advanced_value_type_tmp           = $advanced_value_type;
	my $advanced_value_status_tmp         = $advanced_value_status;
	my $advanced_value_component_tmp      = $advanced_value_component;
	my $advanced_value_execution_type_tmp = $advanced_value_execution_type;
	my $advanced_value_priority_tmp       = $advanced_value_priority;
	my $testcase_id;
	my $testcase_execution_type;
	my @package_name_tmp = @package_name;

	foreach (@package_name_tmp) {
		if ( $view_package_name_flag[$count] eq "a" ) {
			$case_count_flag++;
		}
		if ( $package_name_flag[$count] eq "a" ) {
			my $suite_number    = 0;
			my $set_number      = 0;
			my $testcase_number = 1;
			my $xml_temp;
			my $suite_value;
			my $set_value;
			my $category_value;
			my $flag_suite        = "n";
			my $flag_set          = "n";
			my $flag_case         = "n";
			my $flag_category     = "n";
			my $draw_package_flag = 0;
			my $draw_suite_flag   = 0;
			my $draw_set_flag     = 0;
			my $package           = $_;
			my $tests_xml_dir = $test_definition_dir . $package . "/tests.xml";

			my $tmp2 = "none";
			my $tmp3 = "none";
			my $tmp4 = "none";
			my $tmp5 = "none";
			my $tmp6 = "none";
			my $tmp7 = "none";

			open FILE, $tests_xml_dir or die $!;
			while (<FILE>) {
				if ( $_ =~ /suite.*name="(.*?)"/ ) {
					$suite_value = $1;
					$flag_suite  = "s";
					if (
						(
							$advanced_value_test_suite_tmp =~
							/\bAny Test Suite\b/
						)
						|| ( $advanced_value_test_suite_tmp =~
							/\b$suite_value\b/ )
					  )
					{
						$flag_suite = "m";
						$suite_number++;
						$draw_suite_flag = 0;
					}
				}
				if ( $flag_suite eq "m" ) {
					if ( $_ =~ /set.*name="(.*?)"/ ) {
						$set_value = $1;
						$flag_set  = "s";
						if (
							(
								$advanced_value_test_set_tmp =~
								/\bAny Test Set\b/
							)
							|| ( $advanced_value_test_set_tmp =~
								/\b$set_value\b/ )
						  )
						{
							$flag_set = "m";
							$set_number++;
							$draw_set_flag = 0;
						}
					}
					if ( $flag_set eq "m" ) {
						if ( $_ =~ /<testcase/ ) {
							$xml_temp      = "none";
							$flag_case     = "s";
							$flag_category = "s";
						}
						if ( $flag_case eq "s" ) {
							if ( $_ =~ /id="(.*?)"/ ) {
								$case_value  = $1;
								$testcase_id = $1;
							}
							if (   ( $_ =~ / type="(.*?)"/ )
								&& ( $_ !~ /xml\-stylesheet type=/ ) )
							{
								$tmp2 = $1;
							}
							if (   ( $_ =~ /type="(.*?)"/ )
								&& ( $_ !~ /\_type=/ )
								&& ( $_ !~ /xml\-stylesheet type=/ ) )
							{
								$tmp2 = $1;
							}
							if ( $_ =~ /status="(.*?)"/ ) {
								$tmp3 = $1;
							}
							if ( $_ =~ /component="(.*?)"/ ) {
								$tmp4 = $1;
							}
							if ( $_ =~ /execution_type="(.*?)"/ ) {
								$tmp5 = $1;
							}

							if ( $_ =~ /priority="(.*?)"/ ) {
								$tmp6 = $1;
							}
							if ( $_ =~ /id="(.*?)"/ ) {
								$tmp7 = $1;
							}
							if ( $_ =~ /\>/ ) {
								$testcase_execution_type = $tmp5;
								if (
									(
										(
											$advanced_value_type_tmp =~
											/\bAny Type\b/
										)
										|| ( $advanced_value_type_tmp =~
											/\b$tmp2\b/ )
									)
									&& (
										(
											$advanced_value_status_tmp =~
											/\bAny Status\b/
										)
										|| ( $advanced_value_status_tmp =~
											/\b$tmp3\b/ )
									)
									&& (
										(
											$advanced_value_component_tmp =~
											/\bAny Component\b/
										)
										|| ( $advanced_value_component_tmp =~
											/\b$tmp4\b/ )
									)
									&& (
										(
											$advanced_value_execution_type_tmp
											=~ /\bAny Execution Type\b/
										)
										|| ( $advanced_value_execution_type_tmp
											=~ /\b$tmp5\b/ )
									)
									&& (
										(
											$advanced_value_priority_tmp =~
											/\bAny Priority\b/
										)
										|| ( $advanced_value_priority_tmp =~
											/\b$tmp6\b/ )
									)
								  )
								{
									$flag_case = "m";
								}
							}
						}
						if ( $flag_case eq "m" ) {
							chomp( $xml_temp .= $_ );
							if ( $_ =~ /\<category\>(.*?)\<\/category\>/ ) {
								$category_value = $1;
								if ( $flag_category eq "s" ) {
									if (
										(
											$advanced_value_category_tmp =~
											/\bAny Category\b/
										)
										|| ( $advanced_value_category_tmp =~
											/\b$category_value\b/ )
									  )
									{
										$flag_category = "m";
										push( @case_value, $case_value );
										push( @case_execution_type,
											$testcase_execution_type );
										push( @case_id, $testcase_id );

										if ( $draw_package_flag eq "0" ) {
											print 'var package_'
											  . $package_number
											  . ' = new YAHOO.widget.TextNode("'
											  . $package
											  . '", tree.getRoot(), false);';
											print "\n";
											print 'package_'
											  . $package_number
											  . '.title="Package: '
											  . $package . '";';
											print "\n";
											$draw_package_flag = 1;
										}

										if ( $draw_suite_flag eq "0" ) {
											print 'var suite_'
											  . $suite_number
											  . ' = new YAHOO.widget.TextNode("'
											  . $suite_value
											  . '", package_'
											  . $package_number
											  . ', false);';
											print "\n";
											print 'suite_'
											  . $suite_number
											  . '.title="Suite: '
											  . $value . '"';
											print "\n";
											$draw_suite_flag = 1;
										}

										if ( $draw_set_flag eq "0" ) {
											print 'var set_'
											  . $set_number
											  . ' = new YAHOO.widget.TextNode("'
											  . $set_value
											  . '", suite_'
											  . $suite_number
											  . ', false);';
											print "\n";
											print 'set_'
											  . $set_number
											  . '.title="Set: '
											  . $set_value . '";';
											print "\n";
											$draw_set_flag = 1;
										}

										print 'var testcase_'
										  . $testcase_number
										  . ' = new YAHOO.widget.TextNode("'
										  . ' <span class=\'view_case_name_list\'>'
										  . '<a onclick=\'javascript:onCaseClick('
										  . $case_value_flag_count . ');\'>'
										  . $case_value . '</a>'
										  . '", set_'
										  . $set_number
										  . ', false);';
										print "\n";
										print 'testcase_'
										  . $testcase_number
										  . '.title="Case: '
										  . $case_value . '";';
										print "\n";
										$case_value_flag_count++;
									}
								}
							}
							else {
								if ( $flag_category ne "m" ) {
									if ( $_ =~ /\<\/testcase\>/ ) {
										if ( $advanced_value_category_tmp =~
											/\bAny Category\b/ )
										{
											chomp( $xml = $xml_temp );
											push( @case_value, $case_value );
											push( @case_execution_type,
												$testcase_execution_type );
											push( @case_id,  $testcase_id );
											push( @case_xml, $xml );

											if ( $draw_package_flag eq "0" ) {
												print 'var package_'
												  . $package_number
												  . ' = new YAHOO.widget.TextNode("'
												  . $package
												  . '", tree.getRoot(), false);';
												print "\n";
												print 'package_'
												  . $package_number
												  . '.title="Package: '
												  . $package . '";';
												print "\n";
												$draw_package_flag = 1;
											}
											if ( $draw_suite_flag eq "0" ) {
												print 'var suite_'
												  . $suite_number
												  . ' = new YAHOO.widget.TextNode("'
												  . $suite_value
												  . '", package_'
												  . $package_number
												  . ', false);';
												print "\n";
												print 'suite_'
												  . $suite_number
												  . '.title="Suite: '
												  . $value . '"';
												print "\n";
												$draw_suite_flag = 1;
											}
											if ( $draw_set_flag eq "0" ) {
												print 'var set_'
												  . $set_number
												  . ' = new YAHOO.widget.TextNode("'
												  . $set_value
												  . '", suite_'
												  . $suite_number
												  . ', false);';
												print "\n";
												print 'set_'
												  . $set_number
												  . '.title="Set: '
												  . $set_value . '";';
												print "\n";
												$draw_set_flag = 1;
											}
											print 'var testcase_'
											  . $testcase_number
											  . ' = new YAHOO.widget.TextNode("'
											  . ' <span class=\'view_case_name_list\'>'
											  . '<a onclick=\'javascript:onCaseClick('
											  . $case_value_flag_count . ');\'>'
											  . $case_value . '</a>'
											  . '", set_'
											  . $set_number
											  . ', false);';
											print "\n";
											print 'testcase_'
											  . $testcase_number
											  . '.title="Case: '
											  . $case_value . '";';
											print "\n";
											$case_value_flag_count++;
										}
									}
								}
							}
							if ( $flag_category eq "m" ) {
								if ( $_ =~ /\<\/testcase\>/ ) {
									chomp( $xml = $xml_temp );
									push( @case_xml, $xml );
								}
							}
						}
					}
				}
			}
			$package_number++;
		}
		$count++;
	}
	if ( @case_value > 0 ) {
		print <<DATA;
	// The tree is not created in the DOM until this method is called:
		tree.draw();
DATA
	}
	else {
		if ( $case_count_flag eq "0" ) {
			print <<DATA;
   			 document.getElementById("no_match_testcase_message").style.display="";
DATA
		}
		else {
			print <<DATA;
   			 document.getElementById("no_select_testcase_message").style.display="";
DATA
		}
	}
	print <<DATA;
	}
	// Add a window onload handler to build the tree when the load
	// event fires.
	YAHOO.util.Event.addListener(window, "load", treeInit);
}
// ]]>
</script>
		<td width="70%" valign="top" class="view_case_detail_info" >
DATA
	my $count_temp = 0;
	if ( @case_value eq "0" ) {
		print <<DATA;
			
	          <div id="view_area_case_info_$count_temp" style="display:"> 
	                          		
DATA
		%caseInfo = updateCaseInfo("none");
		printDetailedCaseInfo( "none", "none", %caseInfo );
		print <<DATA;
</div>
DATA
	}
	foreach (@case_value) {
		my $temp = $_;
		%caseInfo = updateCaseInfo( $case_xml[$count_temp] );
		if ( $count_temp eq "0" ) {
			print <<DATA;
			
	          <div id="view_area_case_info_$count_temp" style="display:">                 		
DATA
			printDetailedCaseInfo( $case_id[$count_temp],
				$case_execution_type[$count_temp], %caseInfo );
			print <<DATA;
</div>
DATA
		}
		else {
			print <<DATA;
			
	          <div id="view_area_case_info_$count_temp" style="display:none">                 		
DATA
			printDetailedCaseInfo( $case_id[$count_temp],
				$case_execution_type[$count_temp], %caseInfo );
			print <<DATA;
</div>
DATA
		}
		$count_temp++;
	}

	print <<DATA;
		</td>
        	</tr>
     	</table>
     	</td>
	</tr>
DATA
}

sub ListViewDetailedInfo {
	my $xml = "none";
	my %caseInfo;
	my @list_file_xml   = @_;
	my $case_count_flag = 0;

	my $package_number                    = 1;
	my $count                             = 0;
	my $advanced_value_category_tmp       = $advanced_value_category;
	my $advanced_value_test_suite_tmp     = $advanced_value_test_suite;
	my $advanced_value_test_set_tmp       = $advanced_value_test_set;
	my $advanced_value_type_tmp           = $advanced_value_type;
	my $advanced_value_status_tmp         = $advanced_value_status;
	my $advanced_value_component_tmp      = $advanced_value_component;
	my $advanced_value_execution_type_tmp = $advanced_value_execution_type;
	my $advanced_value_priority_tmp       = $advanced_value_priority;
	my $testcase_id;
	my $testcase_purpose;
	my $testcase_type;
	my $testcase_component;
	my $testcase_exe_type;
	my $testcase_execution_type;
	my @package_name_tmp = @package_name;
	my $suite_terminator = 0;
	my $set_terminator   = 0;

	open OUT, '>' . $list_file_xml[0];
	print OUT '<test_definition>' . "\n";
	foreach (@package_name_tmp) {
		if ( $view_package_name_flag[$count] eq "a" ) {
			$case_count_flag++;
		}
		if ( $package_name_flag[$count] eq "a" ) {
			my $suite_number    = 0;
			my $set_number      = 0;
			my $testcase_number = 1;
			my $xml_temp;
			my $suite_value;
			my $set_value;
			my $category_value;
			my $flag_suite      = "n";
			my $flag_set        = "n";
			my $flag_case       = "n";
			my $flag_category   = "n";
			my $draw_suite_flag = 0;
			my $draw_set_flag   = 0;
			my $package         = $_;
			my $tests_xml_dir = $test_definition_dir . $package . "/tests.xml";
			my $tmp2          = "none";
			my $tmp3          = "none";
			my $tmp4          = "none";
			my $tmp5          = "none";
			my $tmp6          = "none";
			my $tmp7          = "none";

			open FILE, $tests_xml_dir or die $!;
			while (<FILE>) {
				if ( $_ =~ /suite.*name="(.*?)"/ ) {
					if ($suite_terminator) {
						print OUT '</suite>' . "\n";
						$suite_terminator = 0;
					}
					$suite_value = $1;
					$flag_suite  = "s";
					if (
						(
							$advanced_value_test_suite_tmp =~
							/\bAny Test Suite\b/
						)
						|| ( $advanced_value_test_suite_tmp =~
							/\b$suite_value\b/ )
					  )
					{
						$flag_suite = "m";
						$suite_number++;
						$draw_suite_flag = 0;
					}
				}
				if ( $flag_suite eq "m" ) {
					if ( $_ =~ /set.*name="(.*?)"/ ) {
						if ($set_terminator) {
							print OUT '</set>' . "\n";
							$set_terminator = 0;
						}
						$set_value = $1;
						$flag_set  = "s";
						if (
							(
								$advanced_value_test_set_tmp =~
								/\bAny Test Set\b/
							)
							|| ( $advanced_value_test_set_tmp =~
								/\b$set_value\b/ )
						  )
						{
							$flag_set = "m";
							$set_number++;
							$draw_set_flag = 0;
						}
					}
					if ( $flag_set eq "m" ) {
						if ( $_ =~ /<testcase/ ) {
							$xml_temp      = "none";
							$flag_case     = "s";
							$flag_category = "s";
						}
						if ( $flag_case eq "s" ) {
							if ( $_ =~ /purpose="(.*?)"/ ) {
								$testcase_purpose = $1;
							}
							if ( $_ =~ /component="(.*?)"/ ) {
								$testcase_component = $1;
							}
							if ( $_ =~ /execution_type="(.*?)"/ ) {
								$testcase_exe_type = $1;
							}
							if (   ( $_ =~ / type="(.*?)"/ )
								&& ( $_ !~ /xml\-stylesheet type=/ ) )
							{
								$testcase_type = $1;
							}
							if (   ( $_ =~ /type="(.*?)"/ )
								&& ( $_ !~ /\_type=/ )
								&& ( $_ !~ /xml\-stylesheet type=/ ) )
							{
								$testcase_type = $1;
							}
							if ( $_ =~ /id="(.*?)"/ ) {
								$case_value  = $1;
								$testcase_id = $1;
							}

							if ( $_ =~ /status="(.*?)"/ ) {
								$tmp3 = $1;
							}
							if ( $_ =~ /component="(.*?)"/ ) {
								$tmp4 = $1;
							}
							if ( $_ =~ /execution_type="(.*?)"/ ) {
								$tmp5 = $1;
							}
							if (   ( $_ =~ / type="(.*?)"/ )
								&& ( $_ !~ /xml\-stylesheet type=/ ) )
							{
								$tmp2 = $1;
							}
							if (   ( $_ =~ /type="(.*?)"/ )
								&& ( $_ !~ /\_type=/ )
								&& ( $_ !~ /xml\-stylesheet type=/ ) )
							{
								$tmp2 = $1;
							}
							if ( $_ =~ /priority="(.*?)"/ ) {
								$tmp6 = $1;
							}
							if ( $_ =~ /id="(.*?)"/ ) {
								$tmp7 = $1;
							}
							if ( $_ =~ /\>/ ) {
								$testcase_execution_type = $tmp5;
								if (
									(
										(
											$advanced_value_type_tmp =~
											/\bAny Type\b/
										)
										|| ( $advanced_value_type_tmp =~
											/\b$tmp2\b/ )
									)
									&& (
										(
											$advanced_value_status_tmp =~
											/\bAny Status\b/
										)
										|| ( $advanced_value_status_tmp =~
											/\b$tmp3\b/ )
									)
									&& (
										(
											$advanced_value_component_tmp =~
											/\bAny Component\b/
										)
										|| ( $advanced_value_component_tmp =~
											/\b$tmp4\b/ )
									)
									&& (
										(
											$advanced_value_execution_type_tmp
											=~ /\bAny Execution Type\b/
										)
										|| ( $advanced_value_execution_type_tmp
											=~ /\b$tmp5\b/ )
									)
									&& (
										(
											$advanced_value_priority_tmp =~
											/\bAny Priority\b/
										)
										|| ( $advanced_value_priority_tmp =~
											/\b$tmp6\b/ )
									)
								  )
								{
									$flag_case = "m";
								}
							}
						}
						if ( $flag_case eq "m" ) {
							chomp( $xml_temp .= $_ );
							if ( $_ =~ /\<category\>(.*?)\<\/category\>/ ) {
								$category_value = $1;
								if ( $flag_category eq "s" ) {
									if (
										(
											$advanced_value_category_tmp =~
											/\bAny Category\b/
										)
										|| ( $advanced_value_category_tmp =~
											/\b$category_value\b/ )
									  )
									{
										$flag_category = "m";
										%caseInfo = updateCaseInfo($xml_temp);
										my $pre_conditions =
										  $caseInfo{"pre_conditions"};
										my $post_conditions =
										  $caseInfo{"post_conditions"};
										my $test_script_entry =
										  $caseInfo{"test_script_entry"};
										my $test_script_expected_result =
										  $caseInfo{
											"test_script_expected_result"};
										my $actual_result =
										  $caseInfo{"actual_result"};
										my $spec     = $caseInfo{"spec"};
										my $spec_url = $caseInfo{"spec_url"};
										my $spec_statement =
										  $caseInfo{"spec_statement"};
										my $steps = $caseInfo{"steps"};

										if ( $draw_suite_flag eq "0" ) {
											$suite_terminator = 1;
											print OUT '<suite name="'
											  . $suite_value . '">' . "\n";
											$draw_suite_flag = 1;
										}

										if ( $draw_set_flag eq "0" ) {
											$set_terminator = 1;
											print OUT '<set name="'
											  . $set_value . '">' . "\n";
											$draw_set_flag = 1;
										}
										print OUT '<testcase id="'
										  . $case_value
										  . '" purpose="'
										  . $testcase_purpose
										  . '" type="'
										  . $testcase_type
										  . '" component="'
										  . $testcase_component
										  . '" execution_type="'
										  . $testcase_exe_type . '">' . "\n";
										print OUT '<description>' . "\n";
										print OUT '<pre_condition>'
										  . $pre_conditions
										  . '</pre_condition>' . "\n";
										print OUT '<post_condition>'
										  . $post_conditions
										  . '</post_condition>' . "\n";
										print OUT '<steps>' . "\n";
										print OUT '<step order="1">' . "\n";
										my @temp_steps = split( "__", $steps );

										foreach (@temp_steps) {
											my @temp = split( ":", $_ );
											my $step_description = shift @temp;
											my $expected_result  = shift @temp;
											print OUT '<step_desc>'
											  . $step_description
											  . '</step_desc>' . "\n";
											print OUT '<expected>'
											  . $expected_result
											  . '</expected>' . "\n";
										}
										print OUT '</step>' . "\n";
										print OUT '</steps>' . "\n";
										print OUT
'<test_script_entry test_script_expected_result="'
										  . $test_script_expected_result . '">'
										  . $test_script_entry
										  . '</test_script_entry>' . "\n";
										print OUT '</description>' . "\n";
										print OUT '<categories>' . "\n";
										print OUT '</categories>' . "\n";
										print OUT '</testcase>' . "\n";
										$case_value_flag_count++;
									}
								}
							}
							else {
								if ( $flag_category ne "m" ) {
									if ( $_ =~ /\<\/testcase\>/ ) {
										if ( $advanced_value_category_tmp =~
											/\bAny Category\b/ )
										{
											chomp( $xml = $xml_temp );
											%caseInfo = updateCaseInfo($xml);
											my $pre_conditions =
											  $caseInfo{"pre_conditions"};
											my $post_conditions =
											  $caseInfo{"post_conditions"};
											my $test_script_entry =
											  $caseInfo{"test_script_entry"};
											my $test_script_expected_result =
											  $caseInfo{
												"test_script_expected_result"};
											my $actual_result =
											  $caseInfo{"actual_result"};
											my $specs = $caseInfo{"specs"};
											my $steps = $caseInfo{"steps"};

											if ( $draw_suite_flag eq "0" ) {
												$suite_terminator = 1;
												print OUT '<suite name="'
												  . $suite_value . '">' . "\n";
												$draw_suite_flag = 1;
											}
											if ( $draw_set_flag eq "0" ) {
												$set_terminator = 1;
												print OUT '<set name="'
												  . $set_value . '">' . "\n";
												$draw_set_flag = 1;
											}

											print OUT '<testcase id="'
											  . $case_value
											  . '" purpose="'
											  . $testcase_purpose
											  . '" type="'
											  . $testcase_type
											  . '" component="'
											  . $testcase_component
											  . '" execution_type="'
											  . $testcase_exe_type . '">'
											  . "\n";
											print OUT '<description>' . "\n";
											print OUT '<pre_condition>'
											  . $pre_conditions
											  . '</pre_condition>' . "\n";
											print OUT '<post_condition>'
											  . $post_conditions
											  . '</post_condition>' . "\n";
											print OUT '<steps>' . "\n";
											print OUT '<step order="1">' . "\n";
											my @temp_steps =
											  split( "!__!", $steps );

											foreach (@temp_steps) {
												my @temp = split( "!::!", $_ );
												my $step_description =
												  shift @temp;
												my $expected_result =
												  shift @temp;
												print OUT '<step_desc>'
												  . $step_description
												  . '</step_desc>' . "\n";
												print OUT '<expected>'
												  . $expected_result
												  . '</expected>' . "\n";
											}
											print OUT '</step>' . "\n";
											print OUT '</steps>' . "\n";
											print OUT
'<test_script_entry test_script_expected_result="'
											  . $test_script_expected_result
											  . '">'
											  . $test_script_entry
											  . '</test_script_entry>' . "\n";
											print OUT '</description>' . "\n";
											print OUT '<specs>' . "\n";
											my @temp_specs =
											  split( "!__!", $specs );
											for (
												my $i = 0 ;
												$i < @temp_specs ;
												$i++
											  )
											{
												my @temp =
												  split( "!::!",
													$temp_specs[$i] );
												my $spec_category = shift @temp;
												my $spec_section  = shift @temp;
												my $spec_specification =
												  shift @temp;
												my $spec_interface =
												  shift @temp;
												my $spec_element_name =
												  shift @temp;
												my $spec_usage = shift @temp;
												my $spec_element_type =
												  shift @temp;
												my $spec_url = shift @temp;
												my $spec_statement =
												  shift @temp;

												print OUT '<spec>' . "\n";

												if ( $spec_element_name ne
													"none" )
												{
													print OUT
'<spec_assertion category="'
													  . $spec_category
													  . '" section="'
													  . $spec_section
													  . '" specification="'
													  . $spec_specification
													  . '" interface="'
													  . $spec_interface
													  . '" usage="'
													  . $spec_usage
													  . '" element_name="'
													  . $spec_element_name
													  . '" element_type="'
													  . $spec_element_type
													  . "\"\/\>\n";
												}
												else {
													print OUT
'<spec_assertion category="'
													  . $spec_category
													  . '" section="'
													  . $spec_section
													  . '" specification="'
													  . $spec_specification
													  . '" interface="'
													  . $spec_interface
													  . '" usage="'
													  . $spec_usage
													  . "\"\/\>\n";
												}
												print OUT '<spec_url>'
												  . $spec_url
												  . '</spec_url>' . "\n";
												print OUT '<spec_statement>'
												  . $spec_statement
												  . '</spec_statement>' . "\n";
												print OUT '</spec>' . "\n";
											}
											print OUT '</specs>' . "\n";
											print OUT '</testcase>' . "\n";
											$case_value_flag_count++;
										}
									}
								}
							}
						}
					}
				}
			}
			$package_number++;
		}
		$count++;
		if ($set_terminator) {
			print OUT '</set>' . "\n";
			$set_terminator = 0;
		}
		if ($suite_terminator) {
			print OUT '</suite>' . "\n";
			$suite_terminator = 0;
		}
	}
	print OUT '</test_definition>' . "\n";
	close OUT;
}

#After press View button, refresh the page.
sub UpdateViewPageSelectItem {
	@sort_package_name    = sort @package_name;
	@reverse_package_name = reverse @sort_package_name;
	if ( $_GET{'order'} ) {
		if ( $_GET{'order'} eq "down" ) {
			@package_name = @reverse_package_name;
			$image        = "images/up_and_down_1.png";
			$value        = "up";
		}
		elsif ( $_GET{'order'} eq "up" ) {
			@package_name = @sort_package_name;
			$image        = "images/up_and_down_2.png";
			$value        = "down";
		}
	}

	if ( $value eq "" ) {
		$value = "up";
	}
	if ( $image eq "" ) {
		$image = "images/up_and_down_1.png";
	}

	print "HTTP/1.0 200 OK" . CRLF;
	print "Content-type: text/html" . CRLF . CRLF;

	print_header( "$MTK_BRANCH Manager Main Page", "custom" );

	AnalysisReadMe();

	GetSelectItem();
	print <<DATA;
    <div id="ajax_loading" style="display:none"></div>
    <table width="768" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
      <tr>
        <td><form id="tests_custom" name="tests_custom" method="post" action="tests_custom.pl">
          <table width="100%" height="30" border="0" cellspacing="0" cellpadding="0">
            <tr>
              <td><table width="100%" height="30" border="0" cellspacing="0" cellpadding="0" class="top_button_bg">
                <tr>
                  <td width="2%" height="30" nowrap="nowrap">&nbsp;</td> 
DATA
	if ($tree_view_current) {
		print <<DATA;
                  <td width="78%" height="30" nowrap="nowrap" class="custom_title">View test cases in tree view</td>
DATA
	}
	elsif ($list_view_current) {
		print <<DATA;
                  <td width="78%" height="30" nowrap="nowrap" class="custom_title">View test cases in list view</td>
DATA
	}
	print <<DATA;
                  
                  <td width="10%" height="30" align="center" nowrap="nowrap">
                    <input id="list_view_filter_pkg_info" name="list_view_filter_pkg_info" title="View detailed information of filtered packages in list view" class="medium_button" type="submit" value="List View"/>
                  </td>
                  <td width="10%" height="30" align="center" nowrap="nowrap">
                    <input id="tree_view_filter_pkg_info" name="tree_view_filter_pkg_info" title="View detailed information of filtered packages in tree view" class="medium_button" type="submit" value="Tree View"/>
                  </td>
                  
                </tr>
          </table></td>
        </tr>
        <tr>
        <td id="list_advanced" style="display:"><table width="768" border="1" cellspacing="0" cellpadding="0" frame="void" rules="none">
            
            <tr>
              <td width="50%" height="30" nowrap="nowrap" class="custom_list_type_bottomright"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="30" align="left" class="custom_title">&nbsp;Architecture</td><td>
                    <select name="select_arc" align="20px" id="select_arc" class="custom_select" style="width:70%">
                    <option>X86</option>
                    </select></td>
                </tr>
              </table></td>
              <td width="50%" height="30" nowrap="nowrap" class="custom_list_type_bottom"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="30" align="left" class="custom_title">&nbsp;Version<td>
                    <select name="select_ver" id="select_ver" class="custom_select" style="width:70%">
DATA
	LoadDrawVersionSelect();
	print <<DATA;
                    </select>                    </td>
                </tr>
              </table></td>
            </tr>
            
            <tr>
              <td width="50%" height="30" nowrap="nowrap" class="custom_list_type_bottomright"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="30" align="left" class="custom_title">&nbsp;Category</td><td>
                    <select name="select_category" align="20px" id="select_category" class="custom_select" style="width:70%">
DATA
	LoadDrawCategorySelect();
	print <<DATA;
                    </select>                    </td>
                </tr>
              </table></td>
              <td width="50%" height="30" nowrap="nowrap" class="custom_list_type_bottom"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="30" align="left" class="custom_title">&nbsp;Priority<td>
                    <select name="select_pri" id="select_pri" class="custom_select" style="width:70%">
DATA
	LoadDrawPrioritySelect();
	print <<DATA;
                    </select>                    </td>
                </tr>
              </table></td>
            </tr>
            <tr>
              <td width="30%" height="30" nowrap="nowrap" class="custom_list_type_bottomright"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="30" align="left" class="custom_title">&nbsp;Status<td>
                    <select name="select_status" id="select_status" class="custom_select" style="width:70%">
DATA
	LoadDrawStatusSelect();
	print <<DATA;
                    </select>                    </td>
                </tr>
              </table></td>
              <td width="50%" height="30" nowrap="nowrap" class="custom_list_type_bottom"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="30" align="left" class="custom_title">&nbsp;Execution Type<td>
                    <select name="select_exe" id="select_exe" class="custom_select" style="width:70%">
DATA
	LoadDrawExecutiontypeSelect();
	print <<DATA;
                    </select>                    </td>
                </tr>
              </table></td>
            </tr>
            <tr>
              <td width="50%" height="30" nowrap="nowrap" class="custom_list_type_bottomright"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="30" align="left" class="custom_title">&nbsp;Test Suite<td>
                    <select name="select_testsuite" id="select_testsuite" class="custom_select" style="width:70%">
DATA
	LoadDrawTestsuiteSelect();
	print <<DATA;
                    </select>                    </td>
                </tr>
              </table></td>
              <td width="50%" height="30" nowrap="nowrap" class="custom_list_type_bottom"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="30" align="left" class="custom_title">&nbsp;Type<td>
                    <select name="select_type" id="select_type" class="custom_select" style="width:70%">
DATA
	LoadDrawTypeSelect();
	print <<DATA;
                    </select>                    </td>
                </tr>
              </table></td>
            </tr>
            <tr>
              <td width="50%" height="30" nowrap="nowrap" class="custom_list_type_bottomright"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                  <tr>
                    <td width="30%" height="30" align="left" class="custom_title">&nbsp;Test Set<td>
                      <select name="select_testset" id="select_testset" class="custom_select" style="width:70%">
DATA
	LoadDrawTestsetSelect();
	print <<DATA;
                    </select>                    </td>
                  </tr>
              </table></td>
              <td width="50%" height="30" nowrap="nowrap" class="custom_list_type_bottom"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                 <tr>
                  <td width="30%" height="30" align="left" class="custom_title">&nbsp;Component<td>
                    <select name="select_com" id="select_com" class="custom_select" style="width:70%">
DATA
	LoadDrawComponentSelect();
	print <<DATA;
                    </select>                    </td>
                </tr>
              </table></td>
            </tr>
          </table></td>
        </tr>
DATA
}

#After press "Save", "Load", "Delete" button, refresh the page.
sub UpdateLoadPageSelectItem {
	$image = "images/up_and_down_1.png";
	print "HTTP/1.0 200 OK" . CRLF;
	print "Content-type: text/html" . CRLF . CRLF;

	print_header( "$MTK_BRANCH Manager Main Page", "custom" );

	AnalysisReadMe();

	GetSelectItem();
	print show_error_dlg("");
	print <<DATA;
	<div id="ajax_loading" style="display:none"></div>
	<iframe id='popIframe' class='popIframe' frameborder='0' ></iframe>
	<div id="popDiv" class="mydiv" style="overflow-y:auto;overflow-x:auto;height:460px;display:none";></div>
	<table width="768" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
	  <tr>
	    <td><form id="tests_custom" name="tests_custom" method="post" action="tests_custom.pl">
	      <table width="100%" height="30" border="0" cellspacing="0" cellpadding="0">  
	        <tr>
	          <td><table width="100%" height="30" border="0" cellspacing="0" cellpadding="0" class="top_button_bg">
	            <tr>
	              <td width="2.5%" height="30" nowrap="nowrap">&nbsp;</td>
	              <td width="17%" height="30" nowrap="nowrap"><table width="100%" border="0" cellspacing="0" cellpadding="0">
	                <tr>
	                  <td width="47%" height="30" align="left" class="custom_title">Architecture&nbsp</td>
	                  <td width="53%" height="30"><select id="select_arc" name="select_arc" class="custom_select">
	                    <option>X86</option>
	                  </select>                  </td>
	                </tr>
	              </table></td>
	              <td width="13%" height="30" nowrap="nowrap"><table width="100%" border="0" cellspacing="0" cellpadding="0">
	                <tr>
	                <td width="13%" height="30" nowrap="nowrap">&nbsp;</td>
	                  <td width="37%" height="30" align="right" class="custom_title">Version&nbsp</td>
	                  <td width="50%" height="30" ><select id="select_ver" name="select_ver" class="custom_select" onchange="javascript:filter_case_item();">
DATA
	LoadDrawVersionSelect();
	print <<DATA;
                  </select></td>
                </tr>
              </table></td>
              <td width="2%" height="30" nowrap="nowrap">&nbsp;</td>
              <td width="4%" height="30" id="name" nowrap="nowrap" class="custom_title">Name&nbsp</td>
DATA
	if ( !$sort_flag ) {
		print <<DATA;
     <td width="4.5%" height="30" nowrap="nowrap"><img id="sort_packages" title="Sort packages" src="images/up_and_down_1.png" width="23" height="23" onclick="javascript:sortPackages()"/></a></td>
DATA
	}
	else {
		print <<DATA;
     <td width="4.5%" height="30" nowrap="nowrap"><img id="sort_packages" title="Sort packages" src="images/up_and_down_2.png" width="23" height="23" onclick="javascript:sortPackages()"/></a></td>
DATA
	}
	my $hidden_advanced_flag = 0;
	if (   ( $advanced_value_category =~ /\bAny Category\b/ )
		&& ( $advanced_value_priority       =~ /\bAny Priority\b/ )
		&& ( $advanced_value_status         =~ /\bAny Status\b/ )
		&& ( $advanced_value_execution_type =~ /\bAny Execution Type\b/ )
		&& ( $advanced_value_test_suite     =~ /\bAny Test Suite\b/ )
		&& ( $advanced_value_type           =~ /\bAny Type\b/ )
		&& ( $advanced_value_test_set       =~ /\bAny Test Set\b/ )
		&& ( $advanced_value_component      =~ /\bAny Component\b/ ) )
	{

		if ( @package_name == 0 ) {
			print <<DATA;
			<td width="12%" height="30" nowrap="nowrap"><input id="button_adv" name="button_adv" title="Show advanced list" class="medium_button" type="button" value="Advanced" disabled="true" onclick="javascript:hidden_Advanced_List();"/></td>
DATA
		}
		else {
			print <<DATA;
			<td width="12%" height="30" nowrap="nowrap"><input id="button_adv" name="button_adv" title="Show advanced list" class="medium_button" type="button" value="Advanced" onclick="javascript:hidden_Advanced_List();"/></td>
DATA
		}
		print <<DATA;
	        <td width="42%" align="left" height="30" nowrap="nowrap">
				<input id="update_package_list" name="update_package_list" class="medium_button" type="button" value="Update" title="Scan repos, and list uninstalled or later-version packages." onclick="javascript:onUpdatePackages();"/>
			</td>
			<td width="4.5%" height="30" nowrap="nowrap"><img id="progress_waiting" src="" width="14" height="14"/></a></td>
			<td width="3%" height="30" nowrap="nowrap">&nbsp;</td>
            </tr>
          </table></td>
        </tr>
        <tr>
         <td id="list_advanced" style="display:none"><table width="768" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
DATA
	}
	else {
		print <<DATA;
		<td width="12%" height="30" nowrap="nowrap"><input id="button_adv" name="button_adv" title="Hide advanced list" class="medium_button" type="button" value="Normal" onclick="javascript:hidden_Advanced_List();"/></td>
        <td width="42%" align="left" height="30" nowrap="nowrap">
			<input id="update_package_list" name="update_package_list" class="medium_button" type="button" value="Update" title="Scan repos, and list uninstalled or later-version packages." onclick="javascript:onUpdatePackages();"/>
		</td>
		<td width="4.5%" height="30" nowrap="nowrap"><img id="progress_waiting" src="" width="14" height="14"/></a></td>
		<td width="3%" height="30" nowrap="nowrap">&nbsp;</td>
            </tr>
          </table></td>
        </tr>
        <tr>
		<td id="list_advanced" style="display:"><table width="768" border="1" cellspacing="0" cellpadding="0" frame="void" rules="none">
DATA
	}

	print <<DATA;
            <tr>
              <td width="50%" height="30" nowrap="nowrap" class="custom_list_type_bottomright"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="30" align="left" class="custom_title">&nbsp;Category</td><td>
                    <select name="select_category" align="20px" id="select_category" class="custom_select" style="width:70%" onchange="javascript:filter_case_item();">
DATA
	LoadDrawCategorySelect();
	print <<DATA;
                    </select>                    </td>
                </tr>
              </table></td>
              <td width="50%" height="30" nowrap="nowrap" class="custom_list_type_bottom"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="30" align="left" class="custom_title">&nbsp;Priority<td>
                    <select name="select_pri" id="select_pri" class="custom_select" style="width:70%" onchange="javascript:filter_case_item();">
DATA
	LoadDrawPrioritySelect();
	print <<DATA;
                    </select>                    </td>
                </tr>
              </table></td>
            </tr>
            <tr>
              <td width="30%" height="30" nowrap="nowrap" class="custom_list_type_bottomright"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="30" align="left" class="custom_title">&nbsp;Status<td>
                    <select name="select_status" id="select_status" class="custom_select" style="width:70%" onchange="javascript:filter_case_item();">
DATA
	LoadDrawStatusSelect();
	print <<DATA;
                    </select>                    </td>
                </tr>
              </table></td>
              <td width="50%" height="30" nowrap="nowrap" class="custom_list_type_bottom"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="30" align="left" class="custom_title">&nbsp;Execution Type<td>
                    <select name="select_exe" id="select_exe" class="custom_select" style="width:70%" onchange="javascript:filter_case_item();">
DATA
	LoadDrawExecutiontypeSelect();
	print <<DATA;
                    </select>                    </td>
                </tr>
              </table></td>
            </tr>
            <tr>
              <td width="50%" height="30" nowrap="nowrap" class="custom_list_type_bottomright"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="30" align="left" class="custom_title">&nbsp;Test Suite<td>
                    <select name="select_testsuite" id="select_testsuite" class="custom_select" style="width:70%" onchange="javascript:filter_case_item();">
DATA
	LoadDrawTestsuiteSelect();
	print <<DATA;
                    </select>                    </td>
                </tr>
              </table></td>
              <td width="50%" height="30" nowrap="nowrap" class="custom_list_type_bottom"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="30" align="left" class="custom_title">&nbsp;Type<td>
                    <select name="select_type" id="select_type" class="custom_select" style="width:70%" onchange="javascript:filter_case_item();">
DATA
	LoadDrawTypeSelect();
	print <<DATA;
                    </select>                    </td>
                </tr>
              </table></td>
            </tr>
            <tr>
              <td width="50%" height="30" nowrap="nowrap" class="custom_list_type_bottomright"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                  <tr>
                    <td width="30%" height="30" align="left" class="custom_title">&nbsp;Test Set<td>
                      <select name="select_testset" id="select_testset" class="custom_select" style="width:70%" onchange="javascript:filter_case_item();">
DATA
	LoadDrawTestsetSelect();
	print <<DATA;
                    </select>                    </td>
                  </tr>
              </table></td>
              <td width="50%" height="30" nowrap="nowrap" class="custom_list_type_bottom"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                 <tr>
                  <td width="30%" height="30" align="left" class="custom_title">&nbsp;Component<td>
                    <select name="select_com" id="select_com" class="custom_select" style="width:70%" onchange="javascript:filter_case_item();">
DATA
	LoadDrawComponentSelect();
	print <<DATA;
                    </select>                    </td>
                </tr>
              </table></td>
            </tr>
          </table></td>
        </tr>
DATA
}

sub UpdateLoadPage {
	UpdateLoadPageSelectItem();
	my ($load_profile_name) = @_;
	print <<DATA;
	<tr>
          <td></td>
        </tr>
        <tr>
          <td><table width="100%" height="30" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
            <tr>
              <td><table width="100%" height="30" border="1" cellspacing="0" cellpadding="0" style="table-layout:fixed" frame="below" rules="all">
                <tr>
              <td width="4%" height="22" align="center" valign="middle" class="custom_list_type_bottomright_title"><input type="checkbox" id="checkbox_all"  name="checkbox_all" value="checkbox_all" onclick="javascript:check_uncheck_all();" /></td>
              <td width="0.5%" height="30" align="left" class="custom_list_type_bottom"></td>
              <td width="23.5%" height="30" align="left" class="custom_list_type_bottomright_title">Package Name</td>
              <td width="24%" height="30" align="left" class="custom_list_type_bottomright_title">&nbsp;Case Number</td>
              <td width="24%" height="30" align="left" class="custom_list_type_bottomright_title">&nbsp;Version</td>
              <td width="24%" height="30" align="left" class="custom_list_type_bottom_title">&nbsp;Operation</td>
              <input type="hidden" id="package_name_number" name="package_name_number" value="$package_name_number">
                </tr>
              </table></td>
            </tr>
DATA
	if ( @package_name == 0 ) {
		print <<DATA;
            <tr><table width="100%" height="300" border="0" id="update_null_page_div" align="center" class="backbackground_button" cellpadding="0" cellspacing="0" style="display:">
        	<tr>
        		<td width="100%" align="center" class="custom_list_type_bottomright_packagename" id="update_null_page" name="update_null_page">No packages, please click Update button , install packages, then click reload button to refresh page!</td>
        	</tr>
        </table>
        </tr>
DATA
	}
	LoadDrawPackageList();
	DrawUninstallPackageList();
	my $profiles_list = "";
	if ( opendir( DIR, $SERVER_PARAM{'APP_DATA'} . '/profiles/test' ) ) {
		my @files = sort grep !/^[\.~]/, readdir(DIR);
		foreach (@files) {
			my $profile_name = $_;
			$profiles_list .=
			  "    <option value=\"$profile_name\">$profile_name</option>\n";
		}
	}
	print <<DATA;
            </tr>
          </table></td>
        </tr>
        <tr>
        <td height="4" width="100%" class="backbackground_button"></td>
        </tr>
        <tr>
          <td><table width="100%" height="30" border="0" class="backbackground_button custom_font" cellpadding="0" cellspacing="0">
            <tr>
DATA
	if ( @checkbox_packages > 0 ) {
		print <<DATA;
              <td width="10%" align="center"><input type="button" id="execute_profile" name="execute_profile" title="Execute selected packages" class="large_button" value="Execute" onclick="javascript:onExecute();" /></td>
              <td width="10%" align="center"><input type="submit" id="view_package_info" name="view_package_info" class="large_button" value="View" title="View detailed information of selected packages" /></td>
DATA
	}
	else {
		print <<DATA;
              <td width="10%" align="center"><input type="button" id="execute_profile" name="execute_profile" title="Execute selected packages" class="large_button" disabled="true" value="Execute" onclick="javascript:onExecute();" /></td>
              <td width="10%" align="center"><input type="submit" id="view_package_info" name="view_package_info" class="large_button" disabled="true" value="View" title="View detailed information of selected packages" /></td>
DATA
	}
	print <<DATA;
              <td width="40%">&nbsp;</td>
              <td width="10%" align="center">Test Plan</td>
              <td width="10%" align="center"><input name="save_profile_panel_button" id="save_profile_panel_button" title="Open save test plan panel" type="button" class="medium_button" value="Save" onclick="javascript:show_save_panel();" /></td>
              <td width="10%" align="center"><input name="load_profile_panel_button" id="load_profile_panel_button" title="Open load test plan panel" type="button" class="medium_button" value="Load" onclick="javascript:show_load_panel();" /></td>
              <td width="10%" align="center"><input name="manage_profile_panel_button" id="manage_profile_panel_button" title="Open manage test plan panel" type="button" class="medium_button" value="Manage" onclick="javascript:show_manage_panel();" /></td>
            </tr>
            <tr id="save_profile_panel" style="display:none">
              <td height="60" colspan="7"><table width="100%" height="60">
                <tr>
                  <td width="5%">&nbsp;</td>
                  <td width="30%" align="left">Save as a new test plan</td>
                  <td width="20%" align="left"><input name="save_test_plan_text" type="text" class="test_plan_name" id="save_test_plan_text" /></td>
                  <td width="20%">&nbsp;</td>
                  <td width="10%" align="center"><input name="save_profile_button_text" id="save_profile_button_text" title="Save test plan" type="button" class="medium_button" value="Save" onclick="javascript:save_profile('text');" /></td>
                  <td width="10%">&nbsp;</td>
                  <td width="5%">&nbsp;</td>
                </tr>
                <tr>
DATA
	if ( $profiles_list ne "" ) {
		print <<DATA;
                  <td width="5%">&nbsp;</td>
                  <td width="30%" align="left">Overwrite an existing test plan</td>
                  <td width="20%" align="left"><select name="save_test_plan_select" id="save_test_plan_select" style="width: 11em;">$profiles_list</select></td>
                  <td width="20%">&nbsp;</td>
                  <td width="10%" align="center"><input name="save_profile_button_select" id="save_profile_button_select" title="Save test plan" type="button" class="medium_button" value="Save" onclick="javascript:save_profile('select');" /></td>
                  <td width="10%" align="center"><input name="view_profile_button_save" id="view_profile_button_save" title="View test plan" type="button" class="medium_button" value="View" onclick="javascript:view_profile('save');" /></td>
                  <td width="5%">&nbsp;</td>
DATA
	}
	else {
		print <<DATA;
                  <td width="5%">&nbsp;</td>
                  <td width="30%" align="left">Overwrite an existing test plan</td>
                  <td width="20%" align="left"><select name="save_test_plan_select" id="save_test_plan_select" style="width: 11em;" disabled="disabled"><option>&lt;no plans present&gt;</option></select></td>
                  <td width="20%">&nbsp;</td>
                  <td width="10%" align="center"><input name="save_profile_button_select" id="save_profile_button_select" title="Save test plan" type="button" class="medium_button" value="Save" disabled="disabled" onclick="javascript:save_profile('select');" /></td>
                  <td width="10%" align="center"><input name="view_profile_button_save" id="view_profile_button_save" title="View test plan" type="button" class="medium_button" value="View" disabled="disabled" onclick="javascript:view_profile('save');" /></td>
                  <td width="5%">&nbsp;</td>
DATA
	}
	print <<DATA;
                </tr>
              </table></td>
            </tr>
            <tr id="load_profile_panel" style="display:none">
              <td height="30" colspan="7"><table width="100%" height="30">
                <tr>
DATA
	if ( $profiles_list ne "" ) {
		print <<DATA;
                  <td width="5%">&nbsp;</td>
                  <td width="30%" align="left">Choose from existing test plans</td>
                  <td width="20%" align="left"><select name="load_test_plan_select" id="load_test_plan_select" style="width: 11em;">$profiles_list</select></td>
                  <td width="20%">&nbsp;</td>
                  <td width="10%" align="center"><input name="load_profile_button" id="load_profile_button" title="Load test plan" type="button" class="medium_button" value="Load" onclick="javascript:load_profile();" /></td>
                  <td width="10%" align="center"><input name="view_profile_button_load" id="view_profile_button_load" title="View test plan" type="button" class="medium_button" value="View" onclick="javascript:view_profile('load');" /></td>
                  <td width="5%">&nbsp;</td>
DATA
	}
	else {
		print <<DATA;
                  <td width="5%">&nbsp;</td>
                  <td width="30%" align="left">Choose from existing test plans</td>
                  <td width="20%" align="left"><select name="load_test_plan_select" id="load_test_plan_select" style="width: 11em;" disabled="disabled"><option>&lt;no plans present&gt;</option></select></td>
                  <td width="20%">&nbsp;</td>
                  <td width="10%" align="center"><input name="load_profile_button" id="load_profile_button" title="Load test plan" type="button" class="medium_button" value="Load" disabled="disabled" onclick="javascript:load_profile();" /></td>
                  <td width="10%" align="center"><input name="view_profile_button_load" id="view_profile_button_load" title="View test plan" type="button" class="medium_button" value="View" disabled="disabled" onclick="javascript:view_profile('load');" /></td>
                  <td width="5%">&nbsp;</td>
DATA
	}
	print <<DATA;
                </tr>
              </table></td>
            </tr>
            <tr id="manage_profile_panel" style="display:none">
              <td height="30" colspan="7"><table width="100%" height="30">
                <tr>
DATA
	if ( $profiles_list ne "" ) {
		print <<DATA;
                  <td width="5%">&nbsp;</td>
                  <td width="30%" align="left">Existing test plans</td>
                  <td width="20%" align="left"><select name="manage_test_plan_select" id="manage_test_plan_select" style="width: 11em;">$profiles_list</select></td>
                  <td width="20%">&nbsp;</td>
                  <td width="10%" align="center"><input name="view_profile_button_manage" id="view_profile_button_manage" title="View test plan" type="button" class="medium_button" value="View" onclick="javascript:view_profile('manage');" /></td>
                  <td width="10%" align="center"><input name="delete_profile_button" id="delete_profile_button" title="Delete test plan" type="button" class="medium_button" value="Delete" onclick="javascript:delete_profile();" /></td>
                  <td width="5%">&nbsp;</td>
DATA
	}
	else {
		print <<DATA;
                  <td width="5%">&nbsp;</td>
                  <td width="30%" align="left">Existing test plans</td>
                  <td width="20%" align="left"><select name="manage_test_plan_select" id="manage_test_plan_select" style="width: 11em;" disabled="disabled"><option>&lt;no plans present&gt;</option></select></td>
                  <td width="20%">&nbsp;</td>
                  <td width="10%" align="center"><input name="view_profile_button_manage" id="view_profile_button_manage" title="View test plan" type="button" class="medium_button" value="View" disabled="disabled" onclick="javascript:view_profile('manage');" /></td>
                  <td width="10%" align="center"><input name="delete_profile_button" id="delete_profile_button" title="Delete test plan" type="button" class="medium_button" value="Delete" disabled="disabled" onclick="javascript:delete_profile();" /></td>
                  <td width="5%">&nbsp;</td>
DATA
	}
	print <<DATA;
                </tr>
              </table></td>
            </tr>
          </table></td>
        </tr>
      </table>
DATA
}
print <<DATA;
        </form>
    </td>
  </tr>
</table>

<script type="text/javascript" src="run_tests.js"></script>
<script language="javascript" type="text/javascript">
// <![CDATA[
var check_all_box = document.getElementById('checkbox_all');
if (check_all_box) {
	update_state(); // Remember state of the buttons
}
var profiles_list;      // List of user profiles.
DATA

print <<DATA;
var package_name_number = 
DATA
print $package_name_number. ";";

print <<DATA;
var uninstall_package_count_max = 
DATA
print $UNINSTALL_PACKAGE_COUNT_MAX. ";";

print <<DATA;
var case_number = new Array(
DATA
for ( $count_num = 0 ; $count_num < $package_name_number ; $count_num++ ) {
	if ( $count_num == $package_name_number - 1 ) {
		print '"' . $case_number[ 3 * $count_num ] . '"';
	}
	else {
		print '"' . $case_number[ 3 * $count_num ] . '"' . ",";
	}
}
print <<DATA;
)
DATA

print <<DATA;
var case_number_auto = new Array(
DATA
for ( $count_num = 0 ; $count_num < $package_name_number ; $count_num++ ) {
	if ( $count_num == $package_name_number - 1 ) {
		print '"' . $case_number[ 3 * $count_num + 1 ] . '"';
	}
	else {
		print '"' . $case_number[ 3 * $count_num + 1 ] . '"' . ",";
	}
}
print <<DATA;
)
DATA

print <<DATA;
var case_number_manual = new Array(
DATA
for ( $count_num = 0 ; $count_num < $package_name_number ; $count_num++ ) {
	if ( $count_num == $package_name_number - 1 ) {
		print '"' . $case_number[ 3 * $count_num + 2 ] . '"';
	}
	else {
		print '"' . $case_number[ 3 * $count_num + 2 ] . '"' . ",";
	}
}
print <<DATA;
)
DATA

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
var package_name_flag = new Array(
DATA
for ( $count_num = 0 ; $count_num < $package_name_number ; $count_num++ ) {
	if ( $count_num == $package_name_number - 1 ) {
		print '"' . "a" . '"';
	}
	else {
		print '"' . "a" . '"' . ",";
	}
}
print <<DATA;
);
DATA

print <<DATA;
var msg = new Array(
DATA
my @files;
my @files_temp;
my $files_count;
if ( opendir( DIR, $profile_dir_manager ) ) {
	@files_temp = readdir(DIR);
	closedir(DIR);
}
foreach (@files_temp) {
	if ( $_ =~ /^\./ ) {
		next;
	}
	else {
		push( @files, $_ );
	}
}
$files_count = @files;
for ( $count_num = 0 ; $count_num < $files_count ; $count_num++ ) {
	if ( $count_num == $files_count - 1 ) {
		print '"' . $files[$count_num] . '"';
	}
	else {
		print '"' . $files[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);
DATA

print <<DATA;
var main_list_id = new Array(
DATA
for ( $count_num = 0 ; $count_num < $package_name_number ; $count_num++ ) {
	if ( $count_num == $package_name_number - 1 ) {
		print '"' . "main_list_" . $package_name[$count_num] . '"';
	}
	else {
		print '"' . "main_list_" . $package_name[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);
DATA

print <<DATA;
var second_list_id = new Array(
DATA
for ( $count_num = 0 ; $count_num < $package_name_number ; $count_num++ ) {
	if ( $count_num == $package_name_number - 1 ) {
		print '"' . "second_list_" . $package_name[$count_num] . '"';
	}
	else {
		print '"' . "second_list_" . $package_name[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);
DATA

print <<DATA;
var version = new Array(
DATA
for ( $count_num = 0 ; $count_num < $package_name_number ; $count_num++ ) {
	if ( $count_num == $package_name_number - 1 ) {
		print '"' . $version[$count_num] . '"';
	}
	else {
		print '"' . $version[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);
DATA

print <<DATA;
var category_num = new Array(
DATA
for ( $count_num = 0 ; $count_num < $package_name_number ; $count_num++ ) {
	if ( $count_num == $package_name_number - 1 ) {
		print $category_num[$count_num];
	}
	else {
		print $category_num[$count_num] . ",";
	}
}
print <<DATA;
);
DATA

print <<DATA;
var category = new Array(
DATA
for ( $count_num = 0 ; $count_num < @category ; $count_num++ ) {
	if ( $count_num == @category - 1 ) {
		print '"' . $category[$count_num] . '"';
	}
	else {
		print '"' . $category[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);
DATA

print <<DATA;
var priority_num = new Array(
DATA
for ( $count_num = 0 ; $count_num < $package_name_number ; $count_num++ ) {
	if ( $count_num == $package_name_number - 1 ) {
		print $priority_num[$count_num];
	}
	else {
		print $priority_num[$count_num] . ",";
	}
}
print <<DATA;
);
DATA

print <<DATA;
var priority = new Array(
DATA
for ( $count_num = 0 ; $count_num < @priority ; $count_num++ ) {
	if ( $count_num == @priority - 1 ) {
		print '"' . $priority[$count_num] . '"';
	}
	else {
		print '"' . $priority[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);
DATA

print <<DATA;
var status_num = new Array(
DATA
for ( $count_num = 0 ; $count_num < $package_name_number ; $count_num++ ) {
	if ( $count_num == $package_name_number - 1 ) {
		print $status_num[$count_num];
	}
	else {
		print $status_num[$count_num] . ",";
	}
}
print <<DATA;
);
DATA

print <<DATA;
var status_s = new Array(
DATA
for ( $count_num = 0 ; $count_num < @status ; $count_num++ ) {
	if ( $count_num == @status - 1 ) {
		print '"' . $status[$count_num] . '"';
	}
	else {
		print '"' . $status[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);
DATA

print <<DATA;
var execution_type_num = new Array(
DATA
for ( $count_num = 0 ; $count_num < $package_name_number ; $count_num++ ) {
	if ( $count_num == $package_name_number - 1 ) {
		print $execution_type_num[$count_num];
	}
	else {
		print $execution_type_num[$count_num] . ",";
	}
}
print <<DATA;
);
DATA

print <<DATA;
var execution_type = new Array(
DATA
for ( $count_num = 0 ; $count_num < @execution_type ; $count_num++ ) {
	if ( $count_num == @execution_type - 1 ) {
		print '"' . $execution_type[$count_num] . '"';
	}
	else {
		print '"' . $execution_type[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);
DATA

print <<DATA;
var test_suite_num = new Array(
DATA
for ( $count_num = 0 ; $count_num < $package_name_number ; $count_num++ ) {
	if ( $count_num == $package_name_number - 1 ) {
		print $test_suite_num[$count_num];
	}
	else {
		print $test_suite_num[$count_num] . ",";
	}
}
print <<DATA;
);
DATA

print <<DATA;
var test_suite = new Array(
DATA
for ( $count_num = 0 ; $count_num < @test_suite ; $count_num++ ) {
	if ( $count_num == @test_suite - 1 ) {
		print '"' . $test_suite[$count_num] . '"';
	}
	else {
		print '"' . $test_suite[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);
DATA

print <<DATA;
var type_num = new Array(
DATA
for ( $count_num = 0 ; $count_num < $package_name_number ; $count_num++ ) {
	if ( $count_num == $package_name_number - 1 ) {
		print $type_num[$count_num];
	}
	else {
		print $type_num[$count_num] . ",";
	}
}
print <<DATA;
);
DATA

print <<DATA;
var type = new Array(
DATA
for ( $count_num = 0 ; $count_num < @type ; $count_num++ ) {
	if ( $count_num == @type - 1 ) {
		print '"' . $type[$count_num] . '"';
	}
	else {
		print '"' . $type[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);
DATA

print <<DATA;
var test_set_num = new Array(
DATA
for ( $count_num = 0 ; $count_num < $package_name_number ; $count_num++ ) {
	if ( $count_num == $package_name_number - 1 ) {
		print $test_set_num[$count_num];
	}
	else {
		print $test_set_num[$count_num] . ",";
	}
}
print <<DATA;
);
DATA

print <<DATA;
var test_set = new Array(
DATA
for ( $count_num = 0 ; $count_num < @test_set ; $count_num++ ) {
	if ( $count_num == @test_set - 1 ) {
		print '"' . $test_set[$count_num] . '"';
	}
	else {
		print '"' . $test_set[$count_num] . '"' . ",";
	}
}
print <<DATA;
	);
DATA

print <<DATA;
var component_num = new Array(
DATA
for ( $count_num = 0 ; $count_num < $package_name_number ; $count_num++ ) {
	if ( $count_num == $package_name_number - 1 ) {
		print $component_num[$count_num];
	}
	else {
		print $component_num[$count_num] . ",";
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
var version_value = new Array(
DATA
for ( $count_num = 0 ; $count_num < $case_count_total ; $count_num++ ) {
	if ( $count_num == $case_count_total - 1 ) {
		print '"' . $filter_version_value[$count_num] . '"';
	}
	else {
		print '"' . $filter_version_value[$count_num] . '"' . ",";
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
var set_value = new Array(
DATA
for ( $count_num = 0 ; $count_num < $case_count_total ; $count_num++ ) {
	if ( $count_num == $case_count_total - 1 ) {
		print '"' . $filter_set_value[$count_num] . '"';
	}
	else {
		print '"' . $filter_set_value[$count_num] . '"' . ",";
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
var execution_value = new Array(
DATA
for ( $count_num = 0 ; $count_num < $case_count_total ; $count_num++ ) {
	if ( $count_num == $case_count_total - 1 ) {
		print '"' . $filter_execution_value[$count_num] . '"';
	}
	else {
		print '"' . $filter_execution_value[$count_num] . '"' . ",";
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
var filter_auto_count = new Array(
DATA
for ( $count_num = 0 ; $count_num < $package_name_number ; $count_num++ ) {
	if ( $count_num == $package_name_number - 1 ) {
		print '"' . "0" . '"';
	}
	else {
		print '"' . "0" . '"' . ",";
	}
}
print <<DATA;
);

var filter_auto_count_reverse = new Array(
DATA
for ( $count_num = 0 ; $count_num < $package_name_number ; $count_num++ ) {
	if ( $count_num == $package_name_number - 1 ) {
		print '"' . "0" . '"';
	}
	else {
		print '"' . "0" . '"' . ",";
	}
}
print <<DATA;
);

var filter_manual_count = new Array(
DATA
for ( $count_num = 0 ; $count_num < $package_name_number ; $count_num++ ) {
	if ( $count_num == $package_name_number - 1 ) {
		print '"' . "0" . '"';
	}
	else {
		print '"' . "0" . '"' . ",";
	}
}
print <<DATA;
);

var filter_manual_count_reverse = new Array(
DATA
for ( $count_num = 0 ; $count_num < $package_name_number ; $count_num++ ) {
	if ( $count_num == $package_name_number - 1 ) {
		print '"' . "0" . '"';
	}
	else {
		print '"' . "0" . '"' . ",";
	}
}
print <<DATA;
);

var refresh_flag = 
DATA
print $refresh_flag. ";";

print <<DATA;
var view_page_no_filter_flag = 
DATA
print $view_page_no_filter_flag. ";";

print <<DATA;
var filter_auto_string;
var filter_manual_string;
var filter_auto_count_string;
var filter_manual_count_string;
var filter_auto_count_reverse_string;
var filter_manual_count_reverse_string;

if(view_page_no_filter_flag){
	filter_case_item();
}

if(refresh_flag){
	onUpdatePackages();
}

var id = new Array();
var sort_flag = 
DATA
print $sort_flag. ";";

print <<DATA;
var uninstall_pkg_name;
var uninstall_pkg_version;
var install_pkg_update_flag;
var uninstall_pkg_name_arr= new Array();
var uninstall_pkg_version_arr = new Array();
var install_pkg_update_flag_arr= new Array();

function rank()
{
	var image;
	var value;
	image = document.getElementById('image_up_down');
	value = document.getElementById('value_up_down');
	if(image.src == "images/up_and_down_2.png"){
		image.src = "images/up_and_down_1.png";
	}else{
		image.src = "images/up_and_down_2.png";
	}
	if(value.href == "tests_custom.pl?down = 1"){
		value.href="tests_custom.pl?down = 0";
	}else{
		value.href="tests_custom.pl?down = 1";
	}
}

function hidden_Advanced_List()
{
	var advanced_list;
	var button_advanced;
	advanced_list = document.getElementById('list_advanced');
	button_advanced = document.getElementById('button_adv');
	if(advanced_list.style.display == ""){
		advanced_list.style.display = "none";
		button_advanced.value = "Advanced";
		button_advanced.title = "Show advanced list";
	}else{
		advanced_list.style.display = "";
		button_advanced.value = "Normal";
		button_advanced.title = "Hide advanced list";
	}
}

function show_CaseDetail(id) {
	var display = document.getElementById(id).style.display;
	if (display == "none") {
		document.getElementById(id).style.display = "";
	} else {
		document.getElementById(id).style.display = "none";
	}
}

function count_checked() {
	var num = 0;
	var form = document.tests_custom;
	for (var i=0; i<form.length; ++i) {
		if ((form[i].type.toLowerCase() == 'checkbox') && (form[i].name != 'checkbox_all') && form[i].checked) {
			++num;
		}
	}
	return num;
}

function count_checkbox() {
	var num = 0;
	var form = document.tests_custom;
	for (var i=0; i<form.length; ++i) {
		if ((form[i].type.toLowerCase() == 'checkbox') && (form[i].name != 'checkbox_all')) {
			++num;
		}
	}
	return num;
}

function update_state() {
	var button;
	var num_checked = count_checked();
	var num_checkbox = count_checkbox();
	button = document.getElementById('execute_profile');
	if (button) {
		button.disabled = (num_checked == 0);
	}
	button = document.getElementById('view_package_info');
	if (button) {
		button.disabled = (num_checked ==0);
	}
	button = document.getElementById('save_profile_button_text');
	if (button) {
		button.disabled = (num_checked == 0);
	}
	button = document.getElementById('save_profile_button_select');
	if (button) {
		var save_test_plan_select_value = document.getElementById('save_test_plan_select').value;
		if (save_test_plan_select_value.indexOf("no plans present") >= 0) {
			button.disabled = true;
		} else {
			button.disabled = (num_checked == 0);
		}
	}
	var elem = document.getElementById('checkbox_all');
	if (num_checked == num_checkbox){
		elem.checked = 1
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
	var elem = document.getElementById('checkbox_all');
	if (elem) {
		var checked = elem.checked;
		var form = document.tests_custom;
		for (var i=0; i<form.length; ++i) {
			if ((form[i].type.toLowerCase() == 'checkbox') && (form[i].name != 'checkbox_all'))
				check_uncheck(form[i], checked);
		}
		update_state();
	}
}
DATA

print <<DATA;
function sortPackages(){
	var img_id = document.getElementById('sort_packages');
	if (sort_flag){
		img_id.src = "images/up_and_down_1.png";
		for(var count = 0; count < package_name_number; count++){
			var transfer;
			var sort_count = package_name_number-1-count;
			var checkbox_id = "checkbox_package_name"+count;
			var package_name_id = "pn_"+package_name[count];
			var id = document.getElementById(main_list_id[count]);
			var package_case_cn_id = "cn_"+package_name[count];
			var package_ver_id = "ver_"+package_name[count];
			var update_id = "update_package_name_"+count;
			var update_reverse_id = "update_package_name_"+sort_count; 
			var update_pkg_pic = "update_" + document.getElementById(update_id).value;
			var update_pkg_pic_reverse = "update_" + document.getElementById(update_reverse_id).value;
			var delete_id = "pn_package_name_"+count;
			var view_id = "view_package_name_"+count;
			var sec_list_intro_id = "second_list_intro"+count;
			var sec_list_intro_reverse_id = "second_list_intro_reverse"+count;
			var sec_list_case_number_id = "sec_list_case_number"+count;
			var sec_list_case_number_reverse_id = "sec_list_case_number_reverse"+count;
			var sec_list_read_me_id = "sec_list_read_me"+count;
			var sec_list_read_me_reverse_id = "sec_list_read_me_reverse"+count;
			var sec_list_copyright_id = "sec_list_copyright"+count;
			var sec_list_copyright_reverse_id = "sec_list_copyright_reverse"+count;
			var sec_list_install_path_id = "sec_list_install_path"+count;
			var sec_list_install_path_reverse_id = "sec_list_install_path_reverse"+count;
			
			document.getElementById(checkbox_id).name = "checkbox_"+package_name[count];
			document.getElementById(package_name_id).innerHTML = package_name[count];
			
			id.style.display = "none";
			if(package_name_flag[count] == "a"){
			 	id.style.display = "";
			}
			document.getElementById(package_case_cn_id).innerHTML = "&nbsp"+case_number[count];
			document.getElementById(package_ver_id).innerHTML = version[count];
			document.getElementById(update_id).value = package_name[count];	
			
			transfer = document.getElementById(update_pkg_pic).src;
			document.getElementById(update_pkg_pic).src = document.getElementById(update_pkg_pic_reverse).src;
			document.getElementById(update_pkg_pic_reverse).src = transfer;
			
			transfer = document.getElementById(update_pkg_pic).style.cursor;
			document.getElementById(update_pkg_pic).style.cursor = document.getElementById(update_pkg_pic_reverse).style.cursor;
			document.getElementById(update_pkg_pic_reverse).style.cursor = transfer;
			
			transfer = document.getElementById(update_pkg_pic).onclick;
			document.getElementById(update_pkg_pic).onclick = document.getElementById(update_pkg_pic_reverse).onclick;
			document.getElementById(update_pkg_pic_reverse).onclick = transfer;
			
			document.getElementById(delete_id).value = package_name[count];
			document.getElementById(view_id).value = package_name[count];
			document.getElementById(sec_list_intro_id).style.display="";
			document.getElementById(sec_list_intro_reverse_id).style.display="none";		
			document.getElementById(sec_list_case_number_id).style.display="";
			document.getElementById(sec_list_case_number_reverse_id).style.display="none";	
			document.getElementById(sec_list_read_me_id).style.display="";
			document.getElementById(sec_list_read_me_reverse_id).style.display="none";	
			document.getElementById(sec_list_copyright_id).style.display="";
			document.getElementById(sec_list_copyright_reverse_id).style.display="none";	
			document.getElementById(sec_list_install_path_id).style.display="";
			document.getElementById(sec_list_install_path_reverse_id).style.display="none";
		}
		filter_auto_count_string = filter_auto_string;
		filter_manual_count_string = filter_manual_string;
		check_uncheck_all();
		sort_flag = 0;
	}
	else{
		img_id.src = "images/up_and_down_2.png";
		for(var count = 0; count < package_name_number; count++){
			var transfer;
			var sort_count = package_name_number-1-count;
			var checkbox_id = "checkbox_package_name"+count;
			var package_name_id = "pn_"+package_name[count];
			var id = document.getElementById(main_list_id[sort_count]);
			var package_case_cn_id = "cn_"+package_name[count];
			var package_ver_id = "ver_"+package_name[count];
			var update_id = "update_package_name_"+count;
			var update_reverse_id = "update_package_name_"+sort_count; 
			var update_pkg_pic = "update_" + document.getElementById(update_id).value;
			var update_pkg_pic_reverse = "update_" + document.getElementById(update_reverse_id).value;
			var delete_id = "pn_package_name_"+count;
			var view_id = "view_package_name_"+count;
			var sec_list_intro_id = "second_list_intro"+count;
			var sec_list_intro_reverse_id = "second_list_intro_reverse"+count;
			var sec_list_case_number_id = "sec_list_case_number"+count;
			var sec_list_case_number_reverse_id = "sec_list_case_number_reverse"+count;
			var sec_list_read_me_id = "sec_list_read_me"+count;
			var sec_list_read_me_reverse_id = "sec_list_read_me_reverse"+count;
			var sec_list_copyright_id = "sec_list_copyright"+count;
			var sec_list_copyright_reverse_id = "sec_list_copyright_reverse"+count;
			var sec_list_install_path_id = "sec_list_install_path"+count;
			var sec_list_install_path_reverse_id = "sec_list_install_path_reverse"+count;
	
			id.style.display = "none";
			document.getElementById(checkbox_id).name = "checkbox_"+package_name[sort_count];
			document.getElementById(package_name_id).innerHTML = package_name[sort_count];
			
			if(package_name_flag[count] == "a"){	
			 	id.style.display = "";	
			}			
			document.getElementById(package_case_cn_id).innerHTML = "&nbsp"+case_number[sort_count];			
			document.getElementById(package_ver_id).innerHTML = version[sort_count];	
			document.getElementById(update_id).value = package_name[sort_count];
			
			transfer = document.getElementById(update_pkg_pic).src;
			document.getElementById(update_pkg_pic).src = document.getElementById(update_pkg_pic_reverse).src;
			document.getElementById(update_pkg_pic_reverse).src = transfer;
			
			transfer = document.getElementById(update_pkg_pic).style.cursor;
			document.getElementById(update_pkg_pic).style.cursor = document.getElementById(update_pkg_pic_reverse).style.cursor;
			document.getElementById(update_pkg_pic_reverse).style.cursor = transfer;
			
			transfer = document.getElementById(update_pkg_pic).onclick;
			document.getElementById(update_pkg_pic).onclick = document.getElementById(update_pkg_pic_reverse).onclick;
			document.getElementById(update_pkg_pic_reverse).onclick = transfer;
					
			document.getElementById(delete_id).value = package_name[sort_count];
			document.getElementById(view_id).value = package_name[sort_count];
			
			document.getElementById(sec_list_intro_id).style.display="none";
			document.getElementById(sec_list_intro_reverse_id).style.display="";		
			document.getElementById(sec_list_case_number_id).style.display="none";
			document.getElementById(sec_list_case_number_reverse_id).style.display="";	
			document.getElementById(sec_list_read_me_id).style.display="none";
			document.getElementById(sec_list_read_me_reverse_id).style.display="";	
			document.getElementById(sec_list_copyright_id).style.display="none";
			document.getElementById(sec_list_copyright_reverse_id).style.display="";	
			document.getElementById(sec_list_install_path_id).style.display="none";
			document.getElementById(sec_list_install_path_reverse_id).style.display="";				
		} 
		filter_auto_count_string = filter_auto_count_reverse_string;
		filter_manual_count_string = filter_manual_count_reverse_string;
		check_uncheck_all();
		sort_flag = 1;
	}
}
DATA

print <<DATA;
function filter_case_item(){
	document.getElementById('checkbox_all').checked=false;	
	//check_uncheck_all(); remove for remember initial state
	var advanced_value_version = document.getElementById('select_ver');
	var advanced_value_category	= document.getElementById('select_category');
	var advanced_value_priority = document.getElementById('select_pri');
	var advanced_value_status = document.getElementById('select_status');
	var advanced_value_execution_type = document.getElementById('select_exe');
	var advanced_value_test_suite = document.getElementById('select_testsuite');
	var advanced_value_type = document.getElementById('select_type');
	var advanced_value_test_set = document.getElementById('select_testset');
	var advanced_value_component = document.getElementById('select_com');
	var flag_case = new Array("a","a","a","a","a","a");
	
	for (var i=0; i<package_name_number; i++) {	
		var j;
		flag_case[i] = "b";
		filter_auto_count[i]=0;
		filter_manual_count[i]=0;
		if(i == "0"){
			j=0;
		}
		else{
			j = parseInt(one_package_case_count_total[i-1])
		}		
		for(j; j < parseInt(one_package_case_count_total[i]); j++) {		
			if (((advanced_value_version.value == "Any Version")||(advanced_value_version.value == version_value[j]))
			&& ((advanced_value_test_suite.value == "Any Test Suite")||(advanced_value_test_suite.value == suite_value[j]))
			&& ((advanced_value_test_set.value == "Any Test Set")||(advanced_value_test_set.value == set_value[j]))
			&& ((advanced_value_type.value == "Any Type")||(advanced_value_type.value == type_value[j]))
			&& ((advanced_value_status.value == "Any Status")||(advanced_value_status.value == status_value[j]))
			&& ((advanced_value_component.value == "Any Component")||(advanced_value_component.value == component_value[j]))
			&& ((advanced_value_execution_type.value == "Any Execution Type")||(advanced_value_execution_type.value == execution_value[j]))
			&& ((advanced_value_priority.value == "Any Priority")||(advanced_value_priority.value == priority_value[j]))
			&& ((advanced_value_category.value == "Any Category")||(category_value[j].indexOf(advanced_value_category.value))>0)
			){					
				flag_case[i]="a";
				if(execution_value[j] == "auto"){
					filter_auto_count[i]++;
				}
				else{
					filter_manual_count[i]++;
				}
			}
		}
	}
	for (var i=0; i<package_name_number; i++)
	{
		var sort_count = package_name_number-1-i;
		filter_auto_count_reverse[sort_count] = filter_auto_count[i];
		filter_manual_count_reverse[sort_count] = filter_manual_count[i];
	}
	
	filter_auto_string = filter_auto_count.join(":");
	filter_manual_string = filter_manual_count.join(":");
	filter_auto_count_string = filter_auto_string;
	filter_manual_count_string = filter_manual_string;
	filter_auto_count_reverse_string = filter_auto_count_reverse.join(":");
	filter_manual_count_reverse_string = filter_manual_count_reverse.join(":");
				
	for (var i=0; i<package_name_number; i++) {
		var sort_count = package_name_number-1-i;
		if(flag_case[i] == "a"){
			package_name_flag[i] = "a";
			if(sort_flag){
				id = document.getElementById(main_list_id[sort_count]);
				id.style.display = "";
			}
			else{
				id = document.getElementById(main_list_id[i]);
				id.style.display = "";
			}
		}
		else{
			package_name_flag[i] = "b";
			if(sort_flag){
				id = document.getElementById(main_list_id[sort_count]);
				id.style.display = "none";	
			}
			else{
				id = document.getElementById(main_list_id[i]);
				id.style.display = "none";	
			}
		}
	}
	for( var i=0; i<100; i++){
		var id = "uninstall_"+i;
		document.getElementById(id).style.display="none";
	}

}
DATA

print <<DATA;
function onCaseClick(count) {
	var view_select_testcase_info = "view_area_case_info_"+count;
	var select_testcase = document.getElementById(view_select_testcase_info);
	for(var i=0; i<$case_value_flag_count; i++){
		var view_no_select_testcase_info = "view_area_case_info_"+i;
		var no_select_testcase = document.getElementById(view_no_select_testcase_info);
		no_select_testcase.style.display="none";
	}
	select_testcase.style.display="";
}
DATA

print <<DATA;
function refreshPage() {
	document.location="tests_custom.pl";
}
DATA

print <<DATA;
function onViewPackage(count){
	var view_pkg_count="view_package_name_"+count;
	var pkg_name=document.getElementById(view_pkg_count);
	var sel_arc=document.getElementById("select_arc");
	var sel_ver=document.getElementById("select_ver");
	var sel_category=document.getElementById("select_category");
	var sel_pri=document.getElementById("select_pri");
	var sel_status=document.getElementById("select_status");
	var sel_exe=document.getElementById("select_exe");
	var sel_testsuite=document.getElementById("select_testsuite");
	var sel_type=document.getElementById("select_type");
	var sel_testset=document.getElementById("select_testset");
	var sel_com=document.getElementById("select_com");
	
	var pkg=pkg_name.value;
	var arc=sel_arc.value;
	var ver=sel_ver.value;
	var category=sel_category.value;
	var pri=sel_pri.value;
	var status=sel_status.value;
	var exe=sel_exe.value;
	var testsuite=sel_testsuite.value;
	var type=sel_type.value;
	var testset=sel_testset.value;
	var com=sel_com.value;
	
	for(var i=0; i<uninstall_package_count_max; i++){
		var install_pkg_id_tmp = "install_pkg_" + i;
		document.getElementById(install_pkg_id_tmp).onclick = "";
		document.getElementById(install_pkg_id_tmp).style.cursor = "default";
	}
		
	for(var i=0; i<package_name_number; i++){
		var update_pkg_count_tmp = "update_package_name_" + i;
		var pkg_name_tmp = document.getElementById(update_pkg_count_tmp);
		var update_pkg_pic_tmp = "update_" + pkg_name_tmp.value;
		var del_pkg_count_tmp = "pn_package_name_"+i;
		var del_pkg_name_tmp = document.getElementById(del_pkg_count_tmp);
		var del_pkg_pic_tmp = "delete_" + del_pkg_name_tmp.value;
		var view_pkg_count_tmp = "view_package_name_"+i;
		var view_pkg_name_tmp = document.getElementById(view_pkg_count_tmp);
		var view_pkg_pic_tmp = "view_" + view_pkg_name_tmp.value;
		
		document.getElementById(update_pkg_pic_tmp).onclick = "";
		document.getElementById(update_pkg_pic_tmp).style.cursor = "default";
		document.getElementById(del_pkg_pic_tmp).onclick = "";
		document.getElementById(del_pkg_pic_tmp).style.cursor = "default";
		document.getElementById(view_pkg_pic_tmp).onclick = "";
		document.getElementById(view_pkg_pic_tmp).style.cursor = "default";
	}
	
	document.location="tests_custom.pl?view_single_package=1&view_"+pkg+"=1&advanced="+arc+"*"+ver+"*"+category+"*"+pri+"*"+status+"*"+exe+"*"+testsuite+"*"+type+"*"+testset+"*"+com;
}
DATA

print <<DATA;
function onDeletePackage(count) {
	var pkg_count="pn_package_name_"+count;
	var pkg_name=document.getElementById(pkg_count);	
	var sel_arc=document.getElementById("select_arc");
	var sel_ver=document.getElementById("select_ver");
	var sel_category=document.getElementById("select_category");
	var sel_pri=document.getElementById("select_pri");
	var sel_status=document.getElementById("select_status");
	var sel_exe=document.getElementById("select_exe");
	var sel_testsuite=document.getElementById("select_testsuite");
	var sel_type=document.getElementById("select_type");
	var sel_testset=document.getElementById("select_testset");
	var sel_com=document.getElementById("select_com");
	
	var pkg=pkg_name.value;
	var arc=sel_arc.value;
	var ver=sel_ver.value;
	var category=sel_category.value;
	var pri=sel_pri.value;
	var status=sel_status.value;
	var exe=sel_exe.value;
	var testsuite=sel_testsuite.value;
	var type=sel_type.value;
	var testset=sel_testset.value;
	var com=sel_com.value;
	var checkbox_value="null";
	
	for(var count=0; count<package_name_number; count++){
		var checkbox_package_name_tmp="checkbox_package_name"+count;
		var checkbox_pacakage_name=document.getElementById(checkbox_package_name_tmp);
		if(checkbox_pacakage_name.checked){
			checkbox_value=checkbox_value+"*"+checkbox_pacakage_name.name;
		}
	}
	
	
	if(confirm("Are you sure to delete "+pkg+"?")){
		for(var i=0; i<uninstall_package_count_max; i++){
			var install_pkg_id_tmp = "install_pkg_" + i;
			document.getElementById(install_pkg_id_tmp).onclick = "";
			document.getElementById(install_pkg_id_tmp).style.cursor = "default";
		}
		
		for(var i=0; i<package_name_number; i++){
			var update_pkg_count_tmp = "update_package_name_" + i;
			var pkg_name_tmp = document.getElementById(update_pkg_count_tmp);
			var update_pkg_pic_tmp = "update_" + pkg_name_tmp.value;
			var del_pkg_count_tmp = "pn_package_name_"+i;
			var del_pkg_name_tmp = document.getElementById(del_pkg_count_tmp);
			var del_pkg_pic_tmp = "delete_" + del_pkg_name_tmp.value;
			var view_pkg_count_tmp = "view_package_name_"+i;
			var view_pkg_name_tmp = document.getElementById(view_pkg_count_tmp);
			var view_pkg_pic_tmp = "view_" + view_pkg_name_tmp.value;
			
			document.getElementById(update_pkg_pic_tmp).onclick = "";
			document.getElementById(update_pkg_pic_tmp).style.cursor = "default";
			document.getElementById(del_pkg_pic_tmp).onclick = "";
			document.getElementById(del_pkg_pic_tmp).style.cursor = "default";
			document.getElementById(view_pkg_pic_tmp).onclick = "";
			document.getElementById(view_pkg_pic_tmp).style.cursor = "default";
		}
		document.location="tests_custom.pl?delete_package=1&delete_"+pkg+"=1&sort_flag="+sort_flag+"&checkbox="+checkbox_value+"&advanced="+arc+"*"+ver+"*"+category+"*"+pri+"*"+status+"*"+exe+"*"+testsuite+"*"+type+"*"+testset+"*"+com;
	}
}

function copyUrl(id) {
	var s=document.getElementById('id');
	if (window.clipboardData) {
		window.clipboardData.setData("Text",id);
		alert("Copy complete!");
	} else 
	{alert("Copy failed, your browser doesn't support window.clipboardData");
	}
}

function openLC(id) {
	var s=document.getElementById('id');
	file=id/LICENSE;
}
</script>
DATA

sub ScanPackages {
	find( \&GetPackageName, $test_definition_dir );
}

sub CountPackages {
	while ( $package_name_number < @package_name ) {
		$package_name_number++;
	}
}

sub AnalysisVersion {
	my $temp_version;
	my $temp_count = 0;
	my @temp       = `sdb shell 'rpm -qa | grep tests'`;
	if ( @temp > 0 ) {
		while ( $temp_count < $package_name_number ) {
			for ( my $i = 0 ; $i < @temp ; $i++ ) {
				if (   ( $temp[$i] =~ /$package_name[$temp_count]/ )
					&& ( $temp[$i] =~ /-(\d\.\d\.\d-\d)/ ) )
				{
					$temp_version = $1;
					push( @version, $temp_version );
				}
			}
			$temp_count++;
		}
	}
	else {
		while ( $temp_count < $package_name_number ) {
			$temp_version = "none";
			push( @version, $temp_version );
			$temp_count++;
		}
	}
}

sub CreateFilePath {
	my $count = 0;
	while ( $count < $package_name_number ) {
		$read_me[$count] = $opt_dir . $package_name[$count] . "/README";
		$licence_copyright[$count] =
		  $opt_dir . $package_name[$count] . "/LICENSE";
		$installation_path[$count] =
		  $test_definition_dir . $package_name[$count] . "/";
		$testsxml[$count] =
		  $test_definition_dir . $package_name[$count] . "/tests.xml";
		$count++;
	}
}

sub AnalysisTestsXML {
	my $i                          = 0;
	my $count                      = 0;
	my $case_number_all_temp       = 0;
	my $case_number_auto_temp      = 0;
	my $category_number_temp       = 0;
	my $test_suite_number_temp     = 0;
	my $test_set_number_temp       = 0;
	my $status_number_temp         = 0;
	my $priority_number_temp       = 0;
	my $type_number_temp           = 0;
	my $component_number_temp      = 0;
	my $execution_type_number_temp = 0;
	my $temp;

	while ( $count < $package_name_number ) {
		open FILE, $testsxml[$count] or die $!;
		while (<FILE>) {
			if ( $_ =~ /<testcase(.*)/ ) {
				$case_number_all_temp++;
			}
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
			if ( $_ =~ /<set name="(.*?)"/ ) {
				$temp = $1;
				if ( $test_set_number_temp == 0 ) {
					push( @test_set, $temp );
					$test_set_number_temp++;
				}
				else {
					for (
						$i = $test_set_number ;
						$i < ( $test_set_number + $test_set_number_temp ) ;
						$i++
					  )
					{
						if ( $test_set[$i] eq $temp ) {
							last;
						}
						if (
							$i == (
								( $test_set_number + $test_set_number_temp ) - 1
							)
						  )
						{
							push( @test_set, $temp );
							$test_set_number_temp++;
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
			if ( $_ =~ /execution_type="(.*?)"/ ) {
				$temp = $1;
				if ( $temp eq "auto" ) {
					$case_number_auto_temp++;
				}
				if ( $execution_type_number_temp == 0 ) {
					push( @execution_type, $temp );
					$execution_type_number_temp++;
				}
				else {
					for (
						$i = $execution_type_number ;
						$i < (
							$execution_type_number + $execution_type_number_temp
						) ;
						$i++
					  )
					{
						if ( $execution_type[$i] eq $temp ) {
							last;
						}
						if (
							$i == (
								(
									$execution_type_number +
									  $execution_type_number_temp
								) - 1
							)
						  )
						{
							push( @execution_type, $temp );
							$execution_type_number_temp++;
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
			if (   ( $_ =~ /type="(.*?)"/ )
				&& ( $_ !~ /\_type=/ )
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
		}
		if ( @category < 1 ) {
			for ( my $i = 0 ; $i < $case_number_all_temp ; $i++ ) {
				push( @category, "Any Category" );
			}
		}
		push( @case_number, $case_number_all_temp );
		push( @case_number, $case_number_auto_temp );
		push( @case_number,
			( $case_number_all_temp - $case_number_auto_temp ) );
		push( @category_num,       $category_number_temp );
		push( @test_suite_num,     $test_suite_number_temp );
		push( @test_set_num,       $test_set_number_temp );
		push( @status_num,         $status_number_temp );
		push( @type_num,           $type_number_temp );
		push( @priority_num,       $priority_number_temp );
		push( @component_num,      $component_number_temp );
		push( @execution_type_num, $execution_type_number_temp );
		$category_number       += $category_number_temp;
		$test_suite_number     += $test_suite_number_temp;
		$test_set_number       += $test_set_number_temp;
		$status_number         += $status_number_temp;
		$type_number           += $type_number_temp;
		$priority_number       += $priority_number_temp;
		$component_number      += $component_number_temp;
		$execution_type_number += $execution_type_number_temp;
		$case_number_all_temp       = 0;
		$case_number_auto_temp      = 0;
		$category_number_temp       = 0;
		$test_suite_number_temp     = 0;
		$test_set_number_temp       = 0;
		$status_number_temp         = 0;
		$type_number_temp           = 0;
		$priority_number_temp       = 0;
		$component_number_temp      = 0;
		$execution_type_number_temp = 0;
		$count++;
	}
}

sub AnalysisReadMe {
	my $count   = 0;
	my $content = "";
	my $temp    = "";
	while ( $count < $package_name_number ) {
		open FILE, $read_me[$count] or die $!;
		while (<FILE>) {
			$content .= $_;
		}
		if ( $content =~ /Introduction.-{5,}(.*?)-{5,}/s ) {
			$temp = $1;
		}
		else {
			$temp = "None";
		}
		push( @introduction, $temp );
		$temp    = "";
		$content = "";
		$count++;
	}
}

#After press "Save", "Load", "Delete" button, draw package list.
sub LoadDrawPackageList {
	my $count = 0;
	my $display;
	my $i = @checkbox_packages;
	while ( $count < $package_name_number ) {
		my $sort_count   = $package_name_number - 1 - $count;
		my $count_chkbox = 0;
		if ( $package_name_flag[$count] eq "a" ) {
			$display = "";
		}
		else {
			$display = "none";
		}
		print <<DATA;
            <tr id="main_list_$package_name[$count]" style="display:$display">
              <td><table width="100%" height="30" border="1" cellspacing="0" cellpadding="0" frame="below" rules="all" style="table-layout:fixed">
DATA
		my $flag = 0;
		while ( $count_chkbox < $i ) {
			if ( $checkbox_packages[$count_chkbox] =~ /$package_name[$count]/ )
			{
				$flag = 1;
				print <<DATA;
				<td width="4%" height="30" align="center" valign="middle" class="custom_list_type_bottomright"><input type="checkbox" id="checkbox_package_name$count" name="checkbox_$package_name[$count]" checked=true onclick="javascript:update_state()"/></td>	
DATA
			}
			$count_chkbox++;
		}
		if ( $flag eq "0" ) {
			print <<DATA;
				<td width="4%" height="30" align="center" valign="middle" class="custom_list_type_bottomright"><input type="checkbox" id="checkbox_package_name$count" name="checkbox_$package_name[$count]" onclick="javascript:update_state()"/></td>	
DATA
		}
		print <<DATA;
              <td width="0.5%" height="30" align="left" class="custom_list_type_bottom"></td>
              <td width="23.5%" height="30" align="left" class="custom_list_type_bottomright_packagename" id="pn_$package_name[$count]" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;cursor:pointer;" title="$package_name[$count]" onclick="javascript:show_CaseDetail('second_list_$package_name[$count]');">$package_name[$count]</td>
              <td width="24%" height="30" align="left" class="custom_list_type_bottomright" id="cn_$package_name[$count]" name="cn_$package_name[$count]">&nbsp;$case_number[3*$count]</td>
              <td width="24%" height="30" valign="middle" nowrap="nowrap" bordercolor="#ECE9D8" class="custom_list_type_bottomright"><table width="58%" border="0" cellspacing="0" cellpadding="0">
                <tr>
                  <td width="22%" height="30" align="center" valign="middle"><div align="right"><img src="images/package_version.png" width="23" height="23" /></div></td>
                  <td width="78%" height="30" align="center" valign="middle"><div align="left" class="custom_title" id="ver_$package_name[$count]">$version[$count]</div></td>
                </tr>
              </table></td>
              <td width="24%" height="30" class="custom_list_type_bottom"><table width="100%" border="0" cellspacing="0" cellpadding="0">
                <tr>
                  <td align="center" height="30" valign="middle"><div align="left"><img src="images/operation_install_disable.png" title="Install package" width="23" height="23" /></div></td>
                  <td align="center" height="30" valign="middle"><div align="left"><img src="images/operation_update_disable.png" title="Update package" id="update_$package_name[$count]" name="update_$package_name[$count]" width="23" height="23" /></div></td>
					<input type="hidden" id="update_package_name_$count" name="update_package_name_$count" value="$package_name[$count]">
                  <td align="center" height="30" valign="middle"><div align="left"><img title="Delete package" src="images/operation_delete.png" id="delete_$package_name[$count]" name="delete_$package_name[$count]" style="cursor:pointer" width="23" height="23" onclick="javascript:onDeletePackage($count);"/></a></td>
                  <input type="hidden" id="pn_package_name_$count" name="pn_package_name_$count" value="$package_name[$count]">
                  <td align="center" height="30" valign="middle"><div align="left"><img title="View Package" src="images/operation_view_tests.png" id="view_$package_name[$count]" name="view_$package_name[$count]" style="cursor:pointer" width="23" height="23" onclick="javascript:onViewPackage($count);"/></div></td>
                	<input type="hidden" id="view_package_name_$count" name="view_package_name_$count" value="$package_name[$count]">
                </tr>
              </table></td>
              </table>
		</td>
            </tr>
            <tr id="second_list_$package_name[$count]" style="display:none">
              <td><table width="100%" height="30" border="0" cellspacing="0" cellpadding="0">
            <tr>
              <td width="25%" height="30" align="left" valign="middle" nowrap="nowrap" class="custom_list_type_bottomright">&nbsp;&nbsp;Introduction</td>
              <td width="75%" height="30" align="left" valign="middle" class="custom_list_type_bottom" id="intro_$package_name[$count]">
              <table>
              <tr>
               <td width="0.5%" class="backbackground_button"></td>
               <td id="second_list_intro$count" width="99.5%" class="backbackground_button">$introduction[$count]</td>
              <tr>
              <tr>
               <td width="0.5%" class="backbackground_button"></td>
               <td id="second_list_intro_reverse$count" width="99.5%" style="display:none" class="backbackground_button">$introduction[$package_name_number-1-$count]</td>
              <tr>
              </table>
              </td>
             </tr>
            <tr id="sec_list_case_number$count">
              <td align="left" height="30" valign="middle" nowrap="nowrap" class="custom_list_type_bottomright">&nbsp;&nbsp;Case Number(auto manual)</td>
              <td class="custom_list_type_bottom" height="30" id="cnam_$package_name[$count]"><table width="100%" border="0" cellpadding="0" cellspacing="0" class="custom_font">
                <tr>
                  <td width="5%" height="30" align="left" valign="middle">&nbsp;$case_number[3*$count+1]</td>
                  <td width="95%" height="30" align="left" valign="middle">&nbsp;$case_number[3*$count+2]</td>
                </tr>
              </table></td>
              </tr>
              
             <tr id="sec_list_case_number_reverse$count" style="display:none">
              <td align="left" height="30" valign="middle" nowrap="nowrap" class="custom_list_type_bottomright">&nbsp;&nbsp;Case Number(auto manual)</td>
              <td class="custom_list_type_bottom" height="30" id="cnam_$package_name[$sort_count]"><table width="100%" border="0" cellpadding="0" cellspacing="0" class="custom_font">
                <tr>
                  <td width="5%" height="30" align="left" valign="middle">&nbsp;$case_number[3*$sort_count+1]</td>
                  <td width="95%" height="30" align="left" valign="middle">&nbsp;$case_number[3*$sort_count+2]</td>
                </tr>
              </table></td>
              </tr> 
              
            <tr id="sec_list_read_me$count">
              <td align="left" valign="middle" nowrap="nowrap" class="custom_list_type_bottomright">&nbsp;&nbsp;Readme</td>
              <td width="5%" height="30" align="left" valign="middle" class="custom_list_type_bottom">&nbsp;$read_me[$count]
                <a href="/get.pl?file=$read_me[$count]"><image name="imageField" src="images/operation_open_file.png" align="middle" width="23" height="23" /></td>
              </tr>
            
            <tr id="sec_list_read_me_reverse$count" style="display:none">
              <td align="left" valign="middle" nowrap="nowrap" class="custom_list_type_bottomright">&nbsp;&nbsp;Readme</td>
              <td width="5%" height="30" align="left" valign="middle" class="custom_list_type_bottom">&nbsp;$read_me[$sort_count]
                <a href="/get.pl?file=$read_me[$sort_count]"><image name="imageField" src="images/operation_open_file.png" align="middle" width="23" height="23" /></td>
              </tr>
              
            <tr id="sec_list_copyright$count">
              <td align="left" height="30" valign="middle" nowrap="nowrap" class="custom_list_type_bottomright">&nbsp;&nbsp;Licence&amp;Copyright</td>
              <td width="5%" height="30" align="left" valign="middle" id=$licence_copyright[$count] class="custom_list_type_bottom">&nbsp;$licence_copyright[$count]
                <a href="/get.pl?file=$licence_copyright[$count]"><image name="imageField2" src="images/operation_open_file.png" align="middle" width="23" height="23" /></td>
              </tr>
             
             <tr id="sec_list_copyright_reverse$count" style="display:none">
              <td align="left" height="30" valign="middle" nowrap="nowrap" class="custom_list_type_bottomright">&nbsp;&nbsp;Licence&amp;Copyright</td>
              <td width="5%" height="30" align="left" valign="middle" id=$licence_copyright[$sort_count] class="custom_list_type_bottom">&nbsp;$licence_copyright[$sort_count]
                <a href="/get.pl?file=$licence_copyright[$sort_count]"><image name="imageField2" src="images/operation_open_file.png" align="middle" width="23" height="23" /></td>
              </tr>
              
            <tr id="sec_list_install_path$count">
              <td align="left" height="30" valign="middle" nowrap="nowrap" class="custom_list_type_bottomright">&nbsp;&nbsp;Installation Path</td>
              <td width="5%" height="30" align="left" valign="middle" class="custom_list_type_bottom">&nbsp;$installation_path[$count]
                <image name="imageField3" id=$installation_path[$count] src="images/operation_copy_url.png" width="23" height="23" onclick="javascript:copyUrl(id);" style="cursor:pointer"/></td>
              </tr>
            <tr>
            
            <tr id="sec_list_install_path_reverse$count" style="display:none">
              <td align="left" height="30" valign="middle" nowrap="nowrap" class="custom_list_type_bottomright">&nbsp;&nbsp;Installation Path</td>
              <td width="5%" height="30" align="left" valign="middle" class="custom_list_type_bottom">&nbsp;$installation_path[$sort_count]
                <image name="imageField3" id=$installation_path[$sort_count] src="images/operation_copy_url.png" width="23" height="23" onclick="javascript:copyUrl(id);" style="cursor:pointer"/></td>
              </tr>
            <tr>
              </table>
		</td>
            </tr>
DATA
		$count++;
	}

}

#Enter custom page, draw package list.
sub DrawPackageList {
	my $count = 0;
	while ( $count < $package_name_number ) {
		my $sort_count = $package_name_number - 1 - $count;
		print <<DATA;
            <tr id="main_list_$package_name[$count]">
              <td><table width="100%" height="30" border="1" cellspacing="0" cellpadding="0" frame="below" rules="all" style="table-layout:fixed">
              <td width="4%" height="30" align="center" valign="middle" class="custom_list_type_bottomright"><input type="checkbox" id="checkbox_package_name$count" name="checkbox_$package_name[$count]" onclick="javascript:update_state()"/></td>
              <td width="0.5%" height="30" align="left" class="custom_list_type_bottom"></td>
              <td width="23.5%" height="30" align="left" class="custom_list_type_bottomright_packagename" id="pn_$package_name[$count]" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;cursor:pointer;" title="$package_name[$count]" onclick="javascript:show_CaseDetail('second_list_$package_name[$count]');">$package_name[$count]</td>
              <td width="24%" height="30" align="left" class="custom_list_type_bottomright" id="cn_$package_name[$count]" name="cn_$package_name[$count]">&nbsp;$case_number[3*$count]</td>
              <td width="24%" height="30" valign="middle" nowrap="nowrap" bordercolor="#ECE9D8" class="custom_list_type_bottomright"><table width="58%" border="0" cellspacing="0" cellpadding="0">
                <tr>
                  <td width="22%" height="30" align="center" valign="middle"><div align="right"><img src="images/package_version.png" width="23" height="23" /></div></td>
                  <td width="78%" height="30" align="center" valign="middle"><div align="left" class="custom_title" id="ver_$package_name[$count]">$version[$count]</div></td>
                </tr>
              </table></td>
              <td width="24%" height="30" class="custom_list_type_bottom"><table width="100%" border="0" cellspacing="0" cellpadding="0">
                <tr>
                  <td align="center" height="30" valign="middle"><div align="left"><img src="images/operation_install_disable.png" title="Install package" width="23" height="23" /></div></td>	
                  <td align="center" height="30" valign="middle"><div align="left"><img src="images/operation_update_disable.png" title="Update package" id="update_$package_name[$count]" name="update_$package_name[$count]" width="23" height="23"/></div></td>
                  	<input type="hidden" id="update_package_name_$count" name="update_package_name_$count" value="$package_name[$count]">
                  <td align="center" height="30" valign="middle"><div align="left"><img title="Delete package" src="images/operation_delete.png" id="delete_$package_name[$count]" name="delete_$package_name[$count]" style="cursor:pointer" width="23" height="23" onclick="javascript:onDeletePackage($count);" /></a></td>
                  <input type="hidden" id="pn_package_name_$count" name="pn_package_name_$count" value="$package_name[$count]">
                  <td align="center" height="30" valign="middle"><div align="left"><img title="View Package" src="images/operation_view_tests.png" id="view_$package_name[$count]" name="view_$package_name[$count]" style="cursor:pointer" width="23" height="23" onclick="javascript:onViewPackage($count);"/></div></td>
                	<input type="hidden" id="view_package_name_$count" name="view_package_name_$count" value="$package_name[$count]">
                </tr>
              </table></td>
              </table>
		</td>
            </tr>
            <tr id="second_list_$package_name[$count]" style="display:none">
              <td><table width="100%" height="30" border="0" cellspacing="0" cellpadding="0">
            <tr>
              <td width="25%" height="30" align="left" valign="middle" nowrap="nowrap" class="custom_list_type_bottomright">&nbsp;&nbsp;Introduction</td>
              <td width="75%" height="30" align="left" valign="middle" class="custom_list_type_bottom" id="intro_$package_name[$count]">
              <table>
              <tr>
               <td width="0.5%" class="backbackground_button"></td>
               <td id="second_list_intro$count" width="99.5%" class="backbackground_button">$introduction[$count]</td>
              <tr>
              <tr>
               <td width="0.5%" class="backbackground_button"></td>
               <td id="second_list_intro_reverse$count" width="99.5%" style="display:none" class="backbackground_button">$introduction[$package_name_number-1-$count]</td>
              <tr>
              </table>
              </td>
             </tr>
            <tr id="sec_list_case_number$count">
              <td align="left" height="30" valign="middle" nowrap="nowrap" class="custom_list_type_bottomright">&nbsp;&nbsp;Case Number(auto manual)</td>
              <td class="custom_list_type_bottom" height="30" id="cnam_$package_name[$count]"><table width="100%" border="0" cellpadding="0" cellspacing="0" class="custom_font">
                <tr>
                  <td width="5%" height="30" align="left" valign="middle">&nbsp;$case_number[3*$count+1]</td>
                  <td width="95%" height="30" align="left" valign="middle">&nbsp;$case_number[3*$count+2]</td>
                </tr>
              </table></td>
              </tr>
              
             <tr id="sec_list_case_number_reverse$count" style="display:none">
              <td align="left" height="30" valign="middle" nowrap="nowrap" class="custom_list_type_bottomright">&nbsp;&nbsp;Case Number(auto manual)</td>
              <td class="custom_list_type_bottom" height="30" id="cnam_$package_name[$sort_count]"><table width="100%" border="0" cellpadding="0" cellspacing="0" class="custom_font">
                <tr>
                  <td width="5%" height="30" align="left" valign="middle">&nbsp;$case_number[3*$sort_count+1]</td>
                  <td width="95%" height="30" align="left" valign="middle">&nbsp;$case_number[3*$sort_count+2]</td>
                </tr>
              </table></td>
              </tr> 
              
            <tr id="sec_list_read_me$count">
              <td align="left" valign="middle" nowrap="nowrap" class="custom_list_type_bottomright">&nbsp;&nbsp;Readme</td>
              <td width="5%" height="30" align="left" valign="middle" class="custom_list_type_bottom">&nbsp;$read_me[$count]
                <a href="/get.pl?file=$read_me[$count]"><image name="imageField" src="images/operation_open_file.png" align="middle" width="23" height="23" /></td>
              </tr>
            
            <tr id="sec_list_read_me_reverse$count" style="display:none">
              <td align="left" valign="middle" nowrap="nowrap" class="custom_list_type_bottomright">&nbsp;&nbsp;Readme</td>
              <td width="5%" height="30" align="left" valign="middle" class="custom_list_type_bottom">&nbsp;$read_me[$sort_count]
                <a href="/get.pl?file=$read_me[$sort_count]"><image name="imageField" src="images/operation_open_file.png" align="middle" width="23" height="23" /></td>
              </tr>
              
            <tr id="sec_list_copyright$count">
              <td align="left" height="30" valign="middle" nowrap="nowrap" class="custom_list_type_bottomright">&nbsp;&nbsp;Licence&amp;Copyright</td>
              <td width="5%" height="30" align="left" valign="middle" id=$licence_copyright[$count] class="custom_list_type_bottom">&nbsp;$licence_copyright[$count]
                <a href="/get.pl?file=$licence_copyright[$count]"><image name="imageField2" src="images/operation_open_file.png" align="middle" width="23" height="23" /></td>
              </tr>
             
             <tr id="sec_list_copyright_reverse$count" style="display:none">
              <td align="left" height="30" valign="middle" nowrap="nowrap" class="custom_list_type_bottomright">&nbsp;&nbsp;Licence&amp;Copyright</td>
              <td width="5%" height="30" align="left" valign="middle" id=$licence_copyright[$sort_count] class="custom_list_type_bottom">&nbsp;$licence_copyright[$sort_count]
                <a href="/get.pl?file=$licence_copyright[$sort_count]"><image name="imageField2" src="images/operation_open_file.png" align="middle" width="23" height="23" /></td>
              </tr>
              
            <tr id="sec_list_install_path$count">
              <td align="left" height="30" valign="middle" nowrap="nowrap" class="custom_list_type_bottomright">&nbsp;&nbsp;Installation Path</td>
              <td width="5%" height="30" align="left" valign="middle" class="custom_list_type_bottom">&nbsp;$installation_path[$count]
                <image name="imageField3" id=$installation_path[$count] src="images/operation_copy_url.png" width="23" height="23" onclick="javascript:copyUrl(id);" style="cursor:pointer"/></td>
              </tr>
            <tr>
            
            <tr id="sec_list_install_path_reverse$count" style="display:none">
              <td align="left" height="30" valign="middle" nowrap="nowrap" class="custom_list_type_bottomright">&nbsp;&nbsp;Installation Path</td>
              <td width="5%" height="30" align="left" valign="middle" class="custom_list_type_bottom">&nbsp;$installation_path[$sort_count]
                <image name="imageField3" id=$installation_path[$sort_count] src="images/operation_copy_url.png" width="23" height="23" onclick="javascript:copyUrl(id);" style="cursor:pointer"/></td>
              </tr>
            <tr>
            
              </table>
		</td>
            </tr>
DATA
		$count++;
	}
}

sub DrawUninstallPackageList {
	for ( my $i = 0 ; $i < $UNINSTALL_PACKAGE_COUNT_MAX ; $i++ ) {
		print <<DATA;
		<tr id="uninstall_$i" style="display:none">
	        <td><table width="100%" height="30" border="1" cellspacing="0" cellpadding="0" frame="below" rules="all" style="table-layout:fixed">
	        <td width="4%" height="30" align="center" valign="middle" class="custom_list_type_bottomright"><input type="checkbox" id="checkbox_$i" name="checkbox_$i" disabled="true"/></td>
	        <td width="0.5%" height="30" align="left" class="custom_list_type_bottom"></td>
	        <td width="23.5%" height="30" align="left" class="custom_list_type_bottomright_uninstall_packagename" id="pn_$i" style="text-overflow:ellipsis; white-space:nowrap; overflow:hidden;cursor:default;" title="Uninstalled"></td>
	        <td width="24%" height="30" align="left" class="custom_list_type_bottomright" id="cn_$i" name="cn_$i">&nbsp;- -</td>
	        <td width="24%" height="30" valign="middle" nowrap="nowrap" bordercolor="#ECE9D8" class="custom_list_type_bottomright"><table width="58%" border="0" cellspacing="0" cellpadding="0">
	        <tr>
	         <td width="22%" height="30" align="center" valign="middle"><div align="right"><img src="images/package_version.png" width="23" height="23" /></div></td>
	          <td width="78%" height="30" align="center" valign="middle"><div align="left" class="custom_title" id="ver_$i"> </div></td>
	          </tr>
	        </table></td>
	         <td width="24%" height="30" class="custom_list_type_bottom"><table width="100%" border="0" cellspacing="0" cellpadding="0">
	         <tr>
	          <td align="center" height="30" valign="middle"><div align="left"><img title="Install package" src="images/operation_install.png" id="install_pkg_$i" name="install_pkg_$i" style="cursor:pointer" width="23" height="23" onclick="javascript:installPackage($i);"/></div></td>				
	            <td align="center" height="30" valign="middle"><div align="left"><img title="Update package" src="images/operation_update_disable.png" id="update_uninstall_pkg_name_$i" name="update_uninstall_pkg_name_$i" width="23" height="23" /></div></td>
	            <td align="center" height="30" valign="middle"><div align="left"><img title="Delete package" src="images/operation_delete.png" id="delete_uninstall_pkg_name_$i" name="delete_uninstall_pkg_name_$i" width="23" height="23"/></a></td>
	            <td align="center" height="30" valign="middle"><div align="left"><img title="View package" src="images/operation_view_tests.png" id="view_uninstall_pkg_name_$i" name="view_uninstall_pkg_name_$i" width="23" height="23"/></div></td>
	            </tr>
	           </table></td>
	           </table>
			</td>
	        </tr>
DATA
	}
	print <<DATA;
<input type="hidden" id="uninstall_package_count_max" value="$UNINSTALL_PACKAGE_COUNT_MAX">
DATA
}

sub LoadDrawVersionSelect {
	my $count = 0;
	if ( $advanced_value_version =~ /\bAny Version\b/ ) {
		print <<DATA;
		<option selected="selected">Any Version</option>
DATA
		for ( ; $count < @version_item ; $count++ ) {
			print <<DATA;
			<option>$version_item[$count]</option>
DATA
		}
	}
	else {
		print <<DATA;
		<option>Any Version</option>
DATA
		for ( ; $count < @version_item ; $count++ ) {
			if ( $advanced_value_version =~ /\b$version_item[$count]\b/ ) {
				print <<DATA;
				<option selected="selected">$version_item[$count]</option>
DATA
			}
			else {
				print <<DATA;
				<option>$version_item[$count]</option>
DATA
			}
		}
	}
}

sub DrawVersionSelect {
	my $count = 0;
	print <<DATA;
		<option selected="selected">Any Version</option>
DATA
	for ( ; $count < @version_item ; $count++ ) {
		print <<DATA;
		<option>$version_item[$count]</option>
DATA
	}
}

sub LoadDrawCategorySelect {
	my $count = 0;
	if ( $advanced_value_category =~ /\bAny Category\b/ ) {
		print <<DATA;
		<option selected="selected">Any Category</option>
DATA
		for ( ; $count < @category_item ; $count++ ) {
			if ( $category_item[$count] !~ /Any Category/ ) {
				print <<DATA;
			<option>$category_item[$count]</option>
DATA
			}
		}
	}
	else {
		print <<DATA;
		<option>Any Category</option>
DATA
		for ( ; $count < @category_item ; $count++ ) {
			if ( $advanced_value_category =~ /\b$category_item[$count]\b/ ) {
				print <<DATA;
				<option selected="selected">$category_item[$count]</option>
DATA
			}
			else {
				if ( $category_item[$count] !~ /Any Category/ ) {
					print <<DATA;
				<option>$category_item[$count]</option>
DATA
				}
			}
		}
	}
}

sub DrawCategorySelect {
	my $count = 0;
	print <<DATA;
		<option selected="selected">Any Category</option>
DATA
	for ( ; $count < @category_item ; $count++ ) {
		if ( $category_item[$count] !~ /Any Category/ ) {
			print <<DATA;
		<option>$category_item[$count]</option>
DATA
		}
	}
}

sub LoadDrawTestsuiteSelect {
	my $count = 0;
	if ( $advanced_value_test_suite =~ /\bAny Test Suite\b/ ) {
		print <<DATA;
		<option selected="selected">Any Test Suite</option>
DATA
		for ( ; $count < @test_suite_item ; $count++ ) {
			print <<DATA;
			<option>$test_suite_item[$count]</option>
DATA
		}
	}
	else {
		print <<DATA;
		<option>Any Test Suite</option>
DATA
		for ( ; $count < @test_suite_item ; $count++ ) {
			if ( $advanced_value_test_suite =~ /\b$test_suite_item[$count]\b/ )
			{
				print <<DATA;
				<option selected="selected">$test_suite_item[$count]</option>
DATA
			}
			else {
				print <<DATA;
				<option>$test_suite_item[$count]</option>
DATA
			}
		}
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

sub LoadDrawTestsetSelect {
	my $count = 0;
	if ( $advanced_value_test_set =~ /\bAny Test Set\b/ ) {
		print <<DATA;
		<option selected="selected">Any Test Set</option>
DATA
		for ( ; $count < @test_set_item ; $count++ ) {
			print <<DATA;
			<option>$test_set_item[$count]</option>
DATA
		}
	}
	else {
		print <<DATA;
		<option>Any Test Set</option>
DATA
		for ( ; $count < @test_set_item ; $count++ ) {
			if ( $advanced_value_test_set =~ /\b$test_set_item[$count]\b/ ) {
				print <<DATA;
				<option selected="selected">$test_set_item[$count]</option>
DATA
			}
			else {
				print <<DATA;
				<option>$test_set_item[$count]</option>
DATA
			}
		}
	}
}

sub DrawTestsetSelect {
	my $count = 0;
	print <<DATA;
		<option selected="selected">Any Test Set</option>
DATA
	for ( ; $count < @test_set_item ; $count++ ) {
		print <<DATA;
		<option>$test_set_item[$count]</option>
DATA
	}
}

sub LoadDrawStatusSelect {
	my $count = 0;
	if ( $advanced_value_status =~ /\bAny Status\b/ ) {
		print <<DATA;
		<option selected="selected">Any Status</option>
DATA
		for ( ; $count < @status_item ; $count++ ) {
			print <<DATA;
			<option>$status_item[$count]</option>
DATA
		}
	}
	else {
		print <<DATA;
		<option>Any Status</option>
DATA
		for ( ; $count < @status_item ; $count++ ) {
			if ( $advanced_value_status =~ /\b$status_item[$count]\b/ ) {
				print <<DATA;
				<option selected="selected">$status_item[$count]</option>
DATA
			}
			else {
				print <<DATA;
				<option>$status_item[$count]</option>
DATA
			}
		}
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

sub LoadDrawTypeSelect {
	my $count = 0;
	if ( $advanced_value_type =~ /\bAny Type\b/ ) {
		print <<DATA;
		<option selected="selected">Any Type</option>
DATA
		for ( ; $count < @type_item ; $count++ ) {
			print <<DATA;
			<option>$type_item[$count]</option>
DATA
		}
	}
	else {
		print <<DATA;
		<option>Any Type</option>
DATA
		for ( ; $count < @type_item ; $count++ ) {
			if ( $advanced_value_type =~ /\b$type_item[$count]\b/ ) {
				print <<DATA;
				<option selected="selected">$type_item[$count]</option>
DATA
			}
			else {
				print <<DATA;
				<option>$type_item[$count]</option>
DATA
			}
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

sub LoadDrawPrioritySelect {
	my $count = 0;
	if ( $advanced_value_priority =~ /\bAny Priority\b/ ) {
		print <<DATA;
		<option selected="selected">Any Priority</option>
DATA
		for ( ; $count < @priority_item ; $count++ ) {
			print <<DATA;
			<option>$priority_item[$count]</option>
DATA
		}
	}
	else {
		print <<DATA;
		<option>Any Priority</option>
DATA
		for ( ; $count < @priority_item ; $count++ ) {
			if ( $advanced_value_priority =~ /\b$priority_item[$count]\b/ ) {
				print <<DATA;
				<option selected="selected">$priority_item[$count]</option>
DATA
			}
			else {
				print <<DATA;
				<option>$priority_item[$count]</option>
DATA
			}
		}
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

sub LoadDrawComponentSelect {
	my $count = 0;
	if ( $advanced_value_component =~ /\bAny Component\b/ ) {
		print <<DATA;
		<option selected="selected">Any Component</option>
DATA
		for ( ; $count < @component_item ; $count++ ) {
			print <<DATA;
			<option>$component_item[$count]</option>
DATA
		}
	}
	else {
		print <<DATA;
		<option>Any Component</option>
DATA
		for ( ; $count < @component_item ; $count++ ) {
			if ( $advanced_value_component =~ /\b$component_item[$count]\b/ ) {
				print <<DATA;
				<option selected="selected">$component_item[$count]</option>
DATA
			}
			else {
				print <<DATA;
				<option>$component_item[$count]</option>
DATA
			}
		}
	}
}

sub DrawComponentSelect {
	my $count = 0;
	print <<DATA;
		<option selected="selected">Any Component</option>
DATA
	for ( ; $count < @component_item ; $count++ ) {
		print <<DATA;
		<option>$component_item[$count]</option>
DATA
	}
}

sub LoadDrawExecutiontypeSelect {
	my $count = 0;
	if ( $advanced_value_execution_type =~ /\bAny Execution Type\b/ ) {
		print <<DATA;
		<option selected="selected">Any Execution Type</option>
DATA
		for ( ; $count < @execution_type_item ; $count++ ) {
			print <<DATA;
			<option>$execution_type_item[$count]</option>
DATA
		}
	}
	else {
		print <<DATA;
		<option>Any Execution Type</option>
DATA
		for ( ; $count < @execution_type_item ; $count++ ) {
			if ( $advanced_value_execution_type =~
				/\b$execution_type_item[$count]\b/ )
			{
				print <<DATA;
				<option selected="selected">$execution_type_item[$count]</option>
DATA
			}
			else {
				print <<DATA;
				<option>$execution_type_item[$count]</option>
DATA
			}
		}
	}
}

sub DrawExecutiontypeSelect {
	my $count = 0;
	print <<DATA;
		<option selected="selected">Any Execution Type</option>
DATA
	for ( ; $count < @execution_type_item ; $count++ ) {
		print <<DATA;
		<option>$execution_type_item[$count]</option>
DATA
	}
}

sub GetSelectItem {
	my $i     = 0;
	my $j     = 0;
	my $k     = 0;
	my $count = 0;
	my @temp  = ();

	push( @temp, $version[0] );
	for ( $j = 1 ; $j < @version ; $j++ ) {
		for ( $i = 0 ; $i < @temp ; $i++ ) {
			if ( $version[$j] eq $temp[$i] ) {
				last;
			}
			if ( $i == @temp - 1 ) {
				push( @temp, $version[$j] );
			}
		}
	}
	@version_item = sort @temp;
	@temp         = ();

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

	push( @temp, $test_set[0] );
	for ( $j = 1 ; $j < @test_set ; $j++ ) {
		for ( $i = 0 ; $i < @temp ; $i++ ) {
			if ( $test_set[$j] eq $temp[$i] ) {
				last;
			}
			if ( $i == @temp - 1 ) {
				push( @temp, $test_set[$j] );
			}
		}
	}
	@test_set_item = sort @temp;
	@temp          = ();

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

	push( @temp, $component[0] );
	for ( $j = 1 ; $j < @component ; $j++ ) {
		for ( $i = 0 ; $i < @temp ; $i++ ) {
			if ( $component[$j] eq $temp[$i] ) {
				last;
			}
			if ( $i == @temp - 1 ) {
				push( @temp, $component[$j] );
			}
		}
	}
	@component_item = sort @temp;
	@temp           = ();

	push( @temp, $execution_type[0] );
	for ( $j = 1 ; $j < @execution_type ; $j++ ) {
		for ( $i = 0 ; $i < @temp ; $i++ ) {
			if ( $execution_type[$j] eq $temp[$i] ) {
				last;
			}
			if ( $i == @temp - 1 ) {
				push( @temp, $execution_type[$j] );
			}
		}
	}
	@execution_type_item = sort @temp;
	@temp                = ();
}

# Get all the packages' name installed in device.
sub GetPackageName {
	if ( $_ =~ /^tests\.xml$/ ) {
		my $relative = $File::Find::dir;
		$relative =~ s/$test_definition_dir//g;
		my @temp_package_name = split( "\/", $relative );
		push( @package_name, @temp_package_name );
	}
}

# This function is used to analyze xml, filter the property values for each case.
sub FilterCaseValue {
	my $one_package_case_count_total = 0;
	my $count_tmp                    = 0;
	my @package_name_tmp             = @package_name;

	foreach (@package_name_tmp) {
		my $package       = $_;
		my $tests_xml_dir = $test_definition_dir . $package . "/tests.xml";

		my $version_value = $version[$count_tmp];
		my $suite_value;
		my $set_value;
		my $type_value;
		my $case_value;
		my $status_value;
		my $component_value;
		my $execution_value;
		my $priority_value;
		my $category_value;

		open FILE, $tests_xml_dir or die $! . " " . $tests_xml_dir;

		while (<FILE>) {
			if ( $_ =~ /suite.*name="(.*?)"/ ) {
				$suite_value = $1;
			}
			if ( $_ =~ /set.*name="(.*?)"/ ) {
				$set_value = $1;
			}
			if ( $_ =~ /status="(.*?)"/ ) {
				$status_value = $1;
			}
			if ( $_ =~ /component="(.*?)"/ ) {
				$component_value = $1;
			}
			if ( $_ =~ /execution_type="(.*?)"/ ) {
				$execution_value = $1;
			}
			if (   ( $_ =~ / type="(.*?)"/ )
				&& ( $_ !~ /xml\-stylesheet type=/ ) )
			{
				$type_value = $1;
			}
			if (   ( $_ =~ /type="(.*?)"/ )
				&& ( $_ !~ /\_type=/ )
				&& ( $_ !~ /xml\-stylesheet type=/ ) )
			{
				$type_value = $1;
			}
			if ( $_ =~ /priority="(.*?)"/ ) {
				$priority_value = $1;
			}
			if ( $_ =~ /<testcase/ ) {
				$category_value = "null";
			}
			if ( $_ =~ /\<category\>(.*?)\<\/category\>/ ) {
				my $category_value_tmp = "null";
				$category_value_tmp = $1;
				$category_value = $category_value . "&" . $category_value_tmp;
			}
			if ( $_ =~ /\<\/testcase\>/ ) {
				push( @filter_version_value,   $version_value );
				push( @filter_suite_value,     $suite_value );
				push( @filter_set_value,       $set_value );
				push( @filter_type_value,      $type_value );
				push( @filter_status_value,    $status_value );
				push( @filter_component_value, $component_value );
				push( @filter_execution_value, $execution_value );
				push( @filter_priority_value,  $priority_value );
				push( @filter_category_value,  $category_value );
				$one_package_case_count_total++;
			}
		}
		push( @one_package_case_count_total, $one_package_case_count_total );
		$count_tmp++;
	}
	foreach (@filter_set_value) {
		$case_count_total++;
	}
}

# Get property values for each case with function FilterCaseValue();
# This function is used to filter the right cases according to the options' values.
sub FilterCase {
	my $i;
	my $filter_auto_count;
	my $filter_manual_count;

	for ( $i = 0 ; $i < $package_name_number ; $i++ ) {
		my $j;
		$package_name_flag[$i] = "b";
		$filter_auto_count     = 0;
		$filter_manual_count   = 0;

		if ( $i eq "0" ) {
			$j = 0;
		}
		else {
			$j = $one_package_case_count_total[ $i - 1 ];
		}
		for ( $j ; $j < $one_package_case_count_total[$i] ; $j++ ) {
			if (
				(
					( $advanced_value_version =~ /Any Version/ )
					|| (
						$advanced_value_version =~ /$filter_version_value[$j]/ )
				)
				&& ( ( $advanced_value_test_suite =~ /Any Test Suite/ )
					|| ( $advanced_value_test_suite =~
						/$filter_suite_value[$j]/ ) )
				&& (   ( $advanced_value_test_set =~ /Any Test Set/ )
					|| ( $advanced_value_test_set =~ /$filter_set_value[$j]/ ) )
				&& (   ( $advanced_value_type =~ /Any Type/ )
					|| ( $advanced_value_type =~ /$filter_type_value[$j]/ ) )
				&& (   ( $advanced_value_status =~ /Any Status/ )
					|| ( $advanced_value_status =~ /$filter_status_value[$j]/ )
				)
				&& (
					( $advanced_value_component =~ /Any Component/ )
					|| ( $advanced_value_component =~
						/$filter_component_value[$j]/ )
				)
				&& (
					( $advanced_value_execution_type =~ /Any Execution Type/ )
					|| ( $advanced_value_execution_type =~
						/$filter_execution_value[$j]/ )
				)
				&& (
					( $advanced_value_priority =~ /Any Priority/ )
					|| ( $advanced_value_priority =~
						/$filter_priority_value[$j]/ )
				)
				&& (
					( $advanced_value_category =~ /Any Category/ )
					|| ( $filter_category_value[$j] =~
						/$advanced_value_category/ )
				)
			  )
			{
				$package_name_flag[$i] = "a";
				if ( $filter_execution_value[$j] eq "auto" ) {
					$filter_auto_count++;
				}
				else {
					$filter_manual_count++;
				}
			}
		}
		push( @filter_auto_count,   $filter_auto_count );
		push( @filter_manual_count, $filter_manual_count );
	}
}

print_footer("");

