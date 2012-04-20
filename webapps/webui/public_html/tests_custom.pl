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

my $profile_dir_manager = $FindBin::Bin . "/../../../profiles/test/";
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

my $testSuitesPath        = "none";
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

my @version_save_flag = ();
my @category_save_flag;
my @execution_type_save_flag = ();
my @priority_save_flag       = ();
my @status_save_flag         = ();
my @test_suite_save_flag     = ();
my @type_save_flag           = ();
my @test_set_save_flag       = ();
my @component_save_flag      = ();
my @package_name_flag        = ();

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

# press delete package button
if ( $_GET{"delete_package"} ) {
	my $flag_i;
	my @package_name_temp;
	my $checkbox_value  = $_GET{"checkbox"};
	my @select_packages = split /\*/, $checkbox_value;
	my $get_value       = $_GET{"advanced"};
	my @get_value       = split /\*/, $get_value;

	ScanPackages();
	foreach (@package_name) {
		my $temp = $_;
		if ( $_GET{ "delete_" . "$temp" } ) {
			system("rpm -e $_");
		}
		else {
			push( @package_name_temp, $_ );
		}
	}

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
	AnalysisVersion();
	CreateFilePath();
	AnalysisTestsXML();

	for (
		my $count_flag = 0 ;
		$count_flag < $package_name_number ;
		$count_flag++
	  )
	{
		push( @version_save_flag,        "a" );
		push( @category_save_flag,       "a" );
		push( @execution_type_save_flag, "a" );
		push( @priority_save_flag,       "a" );
		push( @status_save_flag,         "a" );
		push( @test_suite_save_flag,     "a" );
		push( @type_save_flag,           "a" );
		push( @test_set_save_flag,       "a" );
		push( @component_save_flag,      "a" );
		push( @package_name_flag,        "a" );
	}
	
	$count_package_number_post = $package_name_number;
	
	FilterItem();
	
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

	UpdateLoadPage();
}

# press save button
elsif ( $_GET{'save_profile_button'} ) {

	my $key;
	my $file;
	my $value;

	my $count             = 0;
	my $count_cn          = 0;
	my $count_ver         = 0;
	my $flag_i            = 0;
	my $get_value         = $_GET{"advanced"};
	my @get_value         = split /\*/, $get_value;
	my $checkbox_value    = $_GET{"checkbox"};
	my @select_packages   = split /\*/, $checkbox_value;
	my $save_profile_name = $_GET{'save_profile_button'};
	my $dir_profile_name  = $profile_dir_manager;

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
	CountPackages();
	AnalysisVersion();
	CreateFilePath();
	AnalysisTestsXML();

	for (
		my $count_flag = 0 ;
		$count_flag < $package_name_number ;
		$count_flag++
	  )
	{
		push( @version_save_flag,        "a" );
		push( @category_save_flag,       "a" );
		push( @execution_type_save_flag, "a" );
		push( @priority_save_flag,       "a" );
		push( @status_save_flag,         "a" );
		push( @test_suite_save_flag,     "a" );
		push( @type_save_flag,           "a" );
		push( @test_set_save_flag,       "a" );
		push( @component_save_flag,      "a" );
		push( @package_name_flag,        "a" );
	}

	$count_package_number_post = $package_name_number;

	open OUT, '>' . $dir_profile_name . $save_profile_name;

	FilterItem();

	print OUT "[Auto]\n";

	my @temp;
	while ( $flag_i < @package_name ) {
		if ( $package_name_flag[$flag_i] eq "a" ) {
			push( @temp, "[Display-packages]:" . $package_name[$flag_i] );
			push( @load_profile_result_pkg_name, $package_name[$flag_i] );
			foreach (@select_packages) {
				if ( $_ =~ /$package_name[$flag_i]/ ) {
					s/checkbox_//g;
					push( @checkbox_packages, $_ );
				}
			}
		}
		else {
			push( @temp, "[None-Display-packages]:" . $package_name[$flag_i] );
		}
		$flag_i++;
	}

	foreach (@checkbox_packages) {
		s/checkbox_//g;
		print OUT $_ . "\n";

	}

	print OUT "[/Auto]\n\n";

	foreach (@temp) {
		print OUT $_ . "\n";
	}

	print OUT "\n[Advanced-feature]\n";
	print OUT "select_arc=" . $advanced_value_architecture . "\n";
	print OUT "select_ver=" . $advanced_value_version . "\n";
	print OUT "select_category=" . $advanced_value_category . "\n";
	print OUT "select_pri=" . $advanced_value_priority . "\n";
	print OUT "select_status=" . $advanced_value_status . "\n";
	print OUT "select_exe=" . $advanced_value_execution_type . "\n";
	print OUT "select_testsuite=" . $advanced_value_test_suite . "\n";
	print OUT "select_type=" . $advanced_value_type . "\n";
	print OUT "select_testset=" . $advanced_value_test_set . "\n";
	print OUT "select_com=" . $advanced_value_component . "\n";

	print OUT "\n";
	foreach (
		my $count_cn = 0 ;
		$count_cn < $count_package_number_post ;
		$count_cn++
	  )
	{
		print OUT "\n[Package"
		  . $count_cn
		  . "-count]:"
		  . $case_number[ 3 * $count_cn ];
	}
	print OUT "\n";
	foreach (@version) {
		print OUT "\n[Package" . $count_ver . "-version]:" . $_;
		$count_ver++;
	}
	print OUT "\n\n";
	foreach (@checkbox_packages) {
		print OUT "[select-packages]: " . $_ . "\n";
	}

	UpdateLoadPage();
}

elsif ( $_POST{'execute_profile'} ) {
	my $key;
	my $value;
	my $flag_i    = 0;
	my %hash      = %_POST;
	my $count     = 0;
	my $count_cn  = 0;
	my $count_ver = 0;
	my @select_packages;
	my @select_packages_filter;

	$count_package_number_post   = $_POST{"package_name_number"};
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

	for (
		my $count_flag = 0 ;
		$count_flag < $count_package_number_post ;
		$count_flag++
	  )
	{
		push( @version_save_flag,        "a" );
		push( @category_save_flag,       "a" );
		push( @execution_type_save_flag, "a" );
		push( @priority_save_flag,       "a" );
		push( @status_save_flag,         "a" );
		push( @test_suite_save_flag,     "a" );
		push( @type_save_flag,           "a" );
		push( @test_set_save_flag,       "a" );
		push( @component_save_flag,      "a" );
		push( @package_name_flag,        "a" );
	}

	open OUT, '> ' . $profile_dir_manager . 'temp_profile';
	
	ScanPackages();

	CountPackages();

	AnalysisVersion();

	CreateFilePath();

	AnalysisTestsXML();

	FilterItem();

	print OUT "[Auto]\n";

	while ( ( $key, $value ) = each %hash ) {
		if ( $key =~ /checkbox/ ) {
			push( @select_packages, $key );
		}
	}

	my @temp;
	while ( $flag_i < @package_name ) {
		if ( $package_name_flag[$flag_i] eq "a" ) {
			push( @temp, "[Display-packages]:" . $package_name[$flag_i] );
			push( @load_profile_result_pkg_name, $package_name[$flag_i] );
			foreach (@select_packages) {
				if ( $_ eq "checkbox_" . $package_name[$flag_i] ) {
					push( @select_packages_filter, $_ );
				}
			}
		}
		else {
			push( @temp, "[None-Display-packages]:" . $package_name[$flag_i] );
		}
		$flag_i++;
	}

	foreach (@select_packages_filter) {
		s/checkbox_//g;
		print OUT $_ . "\n";
	}
	print OUT "[/Auto]\n";

	print OUT "\n[Advanced-feature]\n";
	while ( ( $key, $value ) = each %hash ) {
		if ( ( $key =~ /\_ver/ ) || ( $key =~ /\_arc/ ) ) {
			print OUT $key . "=" . $value . "\n";
		}
	}

	print OUT "select_category=" . $advanced_value_category . "\n";
	print OUT "select_pri=" . $advanced_value_priority . "\n";
	print OUT "select_status=" . $advanced_value_status . "\n";
	print OUT "select_exe=" . $advanced_value_execution_type . "\n";
	print OUT "select_testsuite=" . $advanced_value_test_suite . "\n";
	print OUT "select_type=" . $advanced_value_type . "\n";
	print OUT "select_testset=" . $advanced_value_test_set . "\n";
	print OUT "select_com=" . $advanced_value_component . "\n";

	print OUT "\n";
	foreach (
		my $count_cn = 0 ;
		$count_cn < $count_package_number_post ;
		$count_cn++
	  )
	{
		print OUT "\n[Package"
		  . $count_cn
		  . "-count]:"
		  . $case_number[ 3 * $count_cn ];
	}
	print OUT "\n";
	foreach (@version) {
		print OUT "\n[Package" . $count_ver . "-version]:" . $_;
		$count_ver++;
	}
	print <<DATA;
		<script>
		document.location="tests_execute.pl?profile=temp_profile"
		</script>
DATA
}

#press load button
elsif ( $_GET{'load_profile_button'} ) {
	my $file;
	my $flag_i;
	my $load_profile_name = $_GET{"load_profile_button"};

	my $dir_profile_name = $profile_dir_manager;
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

	CountPackages();

	AnalysisVersion();

	CreateFilePath();

	AnalysisTestsXML();

	$count_package_number_post = $package_name_number;

	for (
		my $count_flag = 0 ;
		$count_flag < $package_name_number ;
		$count_flag++
	  )
	{
		push( @version_save_flag,        "a" );
		push( @category_save_flag,       "a" );
		push( @execution_type_save_flag, "a" );
		push( @priority_save_flag,       "a" );
		push( @status_save_flag,         "a" );
		push( @test_suite_save_flag,     "a" );
		push( @type_save_flag,           "a" );
		push( @test_set_save_flag,       "a" );
		push( @component_save_flag,      "a" );
		push( @package_name_flag,        "a" );
	}

	FilterItem();

	UpdateLoadPage();

	closedir LOADPROFILE;
}

# press delete button
elsif ( $_GET{'delete_profile_button'} ) {

	my $key;
	my $file;
	my $value;
	my $flag_i              = 0;
	my %hash                = %_POST;
	my $get_value           = $_GET{"advanced"};
	my @get_value           = split /\*/, $get_value;
	my $checkbox_value      = $_GET{"checkbox"};
	my @select_packages     = split /\*/, $checkbox_value;
	my $delete_profile_name = $_GET{'delete_profile_button'};
	my $dir_profile_name    = $profile_dir_manager;
	my $delete_profile;

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

	opendir DELPROFILE, $dir_profile_name
	  or die "can not open $dir_profile_name";

	foreach $file ( readdir DELPROFILE ) {
		if ( $file =~ /\b$delete_profile_name\b/ ) {
			$delete_profile = $file;
			unlink $dir_profile_name . $delete_profile;
			$delete_profile = 1;
			last;
		}
		else {
			$delete_profile = 0;
		}
	}
	closedir DELPROFILE;

	ScanPackages();
	CountPackages();
	AnalysisVersion();
	CreateFilePath();
	AnalysisTestsXML();

	for (
		my $count_flag = 0 ;
		$count_flag < $package_name_number ;
		$count_flag++
	  )
	{
		push( @version_save_flag,        "a" );
		push( @category_save_flag,       "a" );
		push( @execution_type_save_flag, "a" );
		push( @priority_save_flag,       "a" );
		push( @status_save_flag,         "a" );
		push( @test_suite_save_flag,     "a" );
		push( @type_save_flag,           "a" );
		push( @test_set_save_flag,       "a" );
		push( @component_save_flag,      "a" );
		push( @package_name_flag,        "a" );
	}

	$count_package_number_post = $package_name_number;

	FilterItem();

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
	
	UpdateLoadPage();
}
else {
	ScanPackages();
	my $i = @package_name;
	if ( $i eq "0" ) {
		UpdateNullPage();
	}
	else {
		UpdatePage();
	}
}

#update page
sub UpdatePage {
	CountPackages();

	@sort_package_name    = sort @package_name;
	@reverse_package_name = reverse @sort_package_name;
	if ( $_GET{'order'} ) {
		if ( $_GET{'order'} eq "down" ) {
			@package_name = @reverse_package_name;
			$image        = "images/up_and_down_2.png";
			$value        = "up";
		}
		elsif ( $_GET{'order'} eq "up" ) {
			@package_name = @sort_package_name;
			$image        = "images/up_and_down_1.png";
			$value        = "down";
		}
	}

	if ( $value eq "" ) {
		$value = "up";
	}
	if ( $image eq "" ) {
		$image = "images/up_and_down_2.png";
	}

	print "HTTP/1.0 200 OK" . CRLF;
	print "Content-type: text/html" . CRLF . CRLF;

	print_header( "$MTK_BRANCH Manager Main Page", "custom" );

	AnalysisVersion();

	CreateFilePath();

	AnalysisTestsXML();

	AnalysisReadMe();

	GetSelectItem();

	print <<DATA;
	<table width="1280" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
	  <tr>
	    <td><form id="tests_custom" name="tests_custom" method="post" action="">
	      <table width="100%" height="50" border="0" cellspacing="0" cellpadding="0">
	        <tr>
	          <td><table width="100%" height="50" border="0" cellspacing="0" cellpadding="0" background="images/report_top_button_background.png">
	            <tr>
	              <td width="2.5%" height="50" nowrap="nowrap">&nbsp;</td>
	              <td width="17%" height="50" nowrap="nowrap"><table width="100%" border="0" cellspacing="0" cellpadding="0">
	                <tr>
	                  <td width="47%" height="50" align="right" class="custom_title">Architecture:&nbsp</td>
	                  <td width="53%" height="50"><select id="select_arc" name="select_arc" class="custom_select">
	                    <option>X86</option>
	                  </select>                  </td>
	                </tr>
	              </table></td>
	              <td width="13%" height="50" nowrap="nowrap"><table width="100%" border="0" cellspacing="0" cellpadding="0">
	                <tr>
	                <td width="13%" height="50" nowrap="nowrap">&nbsp;</td>
	                  <td width="37%" height="50" align="right" class="custom_title">Version:&nbsp</td>
	                  <td width="50%" height="50" ><select id="select_ver" name="select_ver" class="custom_select" onchange="javascript:filter_item();">
DATA
	DrawVersionSelect();
	print <<DATA;
                  </select></td>
                </tr>
              </table></td>
              <td width="2%" height="50" nowrap="nowrap">&nbsp;</td>
              <td width="4%" height="50" id="name" nowrap="nowrap" class="custom_title">Name:&nbsp</td>
              <td width="4.5%" height="50" nowrap="nowrap"><a href="tests_custom.pl?order=$value"><img src="$image" width="38" height="38"/></a></td>
              <td width="54%" height="50" nowrap="nowrap"><input id="button_adv" name="button_adv" class="medium_button" type="button" value="Advanced" onclick="javascript:hidden_Advanced_List();"/></td>
              <td width="3%" height="50" nowrap="nowrap">&nbsp;</td>
            </tr>
          </table></td>
        </tr>
        <tr>
          <td id="list_advanced" style="display:none"><table width="1280" border="0" cellspacing="0" cellpadding="0" frame="below" rules="none">
            <tr>
              <td width="50%" height="50" nowrap="nowrap" class="custom_list_type_bottomright"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="50" align="left" class="custom_title">&nbsp&nbsp&nbsp&nbspcategory:</td><td>
                    <select name="select_category" align="20px" id="select_category" class="custom_select" style="width:70%" onchange="javascript:filter_item();">
DATA
	DrawCategorySelect();
	print <<DATA;
                    </select>                    </td>
                </tr>
              </table></td>
              <td width="50%" height="50" nowrap="nowrap" class="custom_list_type_bottom"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="50" align="left" class="custom_title">&nbsp&nbsp&nbsp&nbsppriority:<td>
                    <select name="select_pri" id="select_pri" class="custom_select" style="width:70%" onchange="javascript:filter_item();">
DATA
	DrawPrioritySelect();
	print <<DATA;
                    </select>                    </td>
                </tr>
              </table></td>
            </tr>
            <tr>
              <td width="30%" height="50" nowrap="nowrap" class="custom_list_type_bottomright"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="50" align="left" class="custom_title">&nbsp&nbsp&nbsp&nbspstatus:<td>
                    <select name="select_status" id="select_status" class="custom_select" style="width:70%" onchange="javascript:filter_item();">
DATA
	DrawStatusSelect();
	print <<DATA;
                    </select>                    </td>
                </tr>
              </table></td>
              <td width="50%" height="50" nowrap="nowrap" class="custom_list_type_bottom"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="50" align="left" class="custom_title">&nbsp&nbsp&nbsp&nbspexecution_type:<td>
                    <select name="select_exe" id="select_exe" class="custom_select" style="width:70%" onchange="javascript:filter_item();">
DATA
	DrawExecutiontypeSelect();
	print <<DATA;
                    </select>                    </td>
                </tr>
              </table></td>
            </tr>
            <tr>
              <td width="50%" height="50" nowrap="nowrap" class="custom_list_type_bottomright"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="50" align="left" class="custom_title">&nbsp&nbsp&nbsp&nbsptestsuite:<td>
                    <select name="select_testsuite" id="select_testsuite" class="custom_select" style="width:70%" onchange="javascript:filter_item();">
DATA
	DrawTestsuiteSelect();
	print <<DATA;
                    </select>                    </td>
                </tr>
              </table></td>
              <td width="50%" height="50" nowrap="nowrap" class="custom_list_type_bottom"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="50" align="left" class="custom_title">&nbsp&nbsp&nbsp&nbsptype:<td>
                    <select name="select_type" id="select_type" class="custom_select" style="width:70%" onchange="javascript:filter_item();">
DATA
	DrawTypeSelect();
	print <<DATA;
                    </select>                    </td>
                </tr>
              </table></td>
            </tr>
            <tr>
              <td width="50%" height="50" nowrap="nowrap" class="custom_list_type_bottomright"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                  <tr>
                    <td width="30%" height="50" align="left" class="custom_title">&nbsp&nbsp&nbsp&nbsptestset:<td>
                      <select name="select_testset" id="select_testset" class="custom_select" style="width:70%" onchange="javascript:filter_item();">
DATA
	DrawTestsetSelect();
	print <<DATA;
                    </select>                    </td>
                  </tr>
              </table></td>
              <td width="50%" height="50" nowrap="nowrap" class="custom_list_type_bottom"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                 <tr>
                  <td width="30%" height="50" align="left" class="custom_title">&nbsp&nbsp&nbsp&nbspcomponent:<td>
                    <select name="select_com" id="select_com" class="custom_select" style="width:70%" onchange="javascript:filter_item();">
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
          <td><table width="100%" height="50" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
            <tr>
              <td><table width="100%" height="50" border="1" cellspacing="0" cellpadding="0" frame="below" rules="none">
                <tr>
              <td width="4%" height="36" align="center" valign="middle" class="custom_list_type_bottomright_title"><input type="checkbox" id="checkbox_all"  name="checkbox_all" value="checkbox_all" onclick="javascript:check_uncheck_all();" /></td>
              <td width="24%" height="50" class="custom_list_type_bottomright_title">&nbsp&nbsp&nbsp&nbspPackage Name </td>
              <td width="24%" height="50" class="custom_list_type_bottomright_title">&nbsp&nbsp&nbsp&nbspCase Number </td>
              <td width="24%" height="50" class="custom_list_type_bottomright_title">&nbsp&nbsp&nbsp&nbspVersion</td>
              <td width="24%" height="50" class="custom_list_type_bottom_title">&nbsp&nbsp&nbsp&nbspOperation</td>
              <input type="hidden" id="package_name_number" name="package_name_number" value="$package_name_number">
                </tr>
              </table></td>
            </tr>
DATA
	DrawPackageList();
	print <<DATA;
            </tr>
          </table></td>
        </tr>
        <tr>
        <td height="4" width="100%" class="backbackground_button"></td>
        </tr>
        <tr>
          <td><table width="100%"  height="48" border="0" align="center" class="backbackground_button" cellpadding="0" cellspacing="0">
            <tr>
              <td width="3.5%" align="center" valign="middle"><img src="images/environment-spacer.gif" width="1" height="1" /></td>
              <td width="10%" valign="top"><div align="center">
                <input type="submit" id="execute_profile" name="execute_profile" class="large_button" value="Execute"/>
              </div></td>
              <td width="1%"><img src="images/environment-spacer.gif" width="1" height="1" /></td>
              <td width="9%" valign="top" class="backbackground_button"><div align="center">
                <input name="Submit3" type="submit" class="large_button" value="Veiw" />
              </div></td>
              <td width="4%"><img src="images/environment-spacer.gif" width="1" height="1" /></td>
              <td width="6%" class="backbackground_button">&nbsp;</td>
              <td width="11%" valign="top"><table>
		        <tr>
		        	<td height="1" class="backbackground_button"></td>
		        </tr>
              	<tr>
              		<td nowrap="nowrap" class="custom_font">Profile name:</td>
              	</tr>
              </table>
              </td>
DATA
}

#When no packages in device, update the page.
sub UpdateNullPage {

	@sort_package_name    = sort @package_name;
	@reverse_package_name = reverse @sort_package_name;
	if ( $_GET{'order'} ) {
		if ( $_GET{'order'} eq "down" ) {
			@package_name = @reverse_package_name;
			$image        = "images/up_and_down_2.png";
			$value        = "up";
		}
		elsif ( $_GET{'order'} eq "up" ) {
			@package_name = @sort_package_name;
			$image        = "images/up_and_down_1.png";
			$value        = "down";
		}
	}

	if ( $value eq "" ) {
		$value = "up";
	}
	if ( $image eq "" ) {
		$image = "images/up_and_down_2.png";
	}

	print "HTTP/1.0 200 OK" . CRLF;
	print "Content-type: text/html" . CRLF . CRLF;

	print_header( "$MTK_BRANCH Manager Main Page", "custom" );

	print <<DATA;
	<table width="1280" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
	  <tr>
	    <td><form id="tests_custom" name="tests_custom" method="post" action="">
	      <table width="100%" height="50" border="0" cellspacing="0" cellpadding="0">
	        <tr>
	          <td><table width="100%" height="50" border="0" cellspacing="0" cellpadding="0" background="images/report_top_button_background.png">
	            <tr>
	              <td width="2.5%" height="50" nowrap="nowrap">&nbsp;</td>
	              <td width="17%" height="50" nowrap="nowrap"><table width="100%" border="0" cellspacing="0" cellpadding="0">
	                <tr>
	                  <td width="47%" height="50" align="right" class="custom_title">Architecture:&nbsp</td>
	                  <td width="53%" height="50"><select id="select_arc" name="select_arc" class="custom_select">
	                    <option>X86</option>
	                  </select>                  </td>
	                </tr>
	              </table></td>
	              <td width="13%" height="50" nowrap="nowrap"><table width="100%" border="0" cellspacing="0" cellpadding="0">
	                <tr>
	                <td width="13%" height="50" nowrap="nowrap">&nbsp;</td>
	                  <td width="37%" height="50" align="right" class="custom_title">Version:&nbsp</td>
	                  <td width="50%" height="50" ><select id="select_ver" name="select_ver" value="Any Version" class="custom_select" onchange="javascript:filter_item();">
                  </select></td>
                </tr>
              </table></td>
              <td width="2%" height="50" nowrap="nowrap">&nbsp;</td>
              <td width="4%" height="50" id="name" nowrap="nowrap" class="custom_title">Name:&nbsp</td>
              <td width="4.5%" height="50" nowrap="nowrap"><a href="tests_custom.pl?order=$value"><img src="$image" width="38" height="38"/></a></td>
              <td width="54%" height="50" nowrap="nowrap"><input id="button_adv" name="button_adv" class="medium_button" type="button" value="Advanced" onclick="javascript:hidden_Advanced_List();"/></td>
              <td width="3%" height="50" nowrap="nowrap">&nbsp;</td>
            </tr>
          </table></td>
        </tr>
        <tr>
          <td id="list_advanced" style="display:none"><table width="1280" border="0" cellspacing="0" cellpadding="0" frame="below" rules="none">
            <tr>
              <td width="50%" height="50" nowrap="nowrap" class="custom_list_type_bottomright"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="50" align="left" class="custom_title">&nbsp&nbsp&nbsp&nbspcategory:</td><td>
                    <select name="select_category" align="20px" id="select_category" class="custom_select" value="Any Category" style="width:70%" onchange="javascript:filter_item();">
                    </select>                    </td>
                </tr>
              </table></td>
              <td width="50%" height="50" nowrap="nowrap" class="custom_list_type_bottom"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="50" align="left" class="custom_title">&nbsp&nbsp&nbsp&nbsppriority:<td>
                    <select name="select_pri" id="select_pri" class="custom_select" value="And Priority" style="width:70%" onchange="javascript:filter_item();">
                    </select>                    </td>
                </tr>
              </table></td>
            </tr>
            <tr>
              <td width="30%" height="50" nowrap="nowrap" class="custom_list_type_bottomright"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="50" align="left" class="custom_title">&nbsp&nbsp&nbsp&nbspstatus:<td>
                    <select name="select_status" id="select_status" class="custom_select" value="Any Status" style="width:70%" onchange="javascript:filter_item();">
                    </select>                    </td>
                </tr>
              </table></td>
              <td width="50%" height="50" nowrap="nowrap" class="custom_list_type_bottom"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="50" align="left" class="custom_title">&nbsp&nbsp&nbsp&nbspexecution_type:<td>
                    <select name="select_exe" id="select_exe" class="custom_select" value="Any Execution Type" style="width:70%" onchange="javascript:filter_item();">
                    </select>                    </td>
                </tr>
              </table></td>
            </tr>
            <tr>
              <td width="50%" height="50" nowrap="nowrap" class="custom_list_type_bottomright"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="50" align="left" class="custom_title">&nbsp&nbsp&nbsp&nbsptestsuite:<td>
                    <select name="select_testsuite" id="select_testsuite" class="custom_select" value="Any Test Suite" style="width:70%" onchange="javascript:filter_item();">
                    </select>                    </td>
                </tr>
              </table></td>
              <td width="50%" height="50" nowrap="nowrap" class="custom_list_type_bottom"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="50" align="left" class="custom_title">&nbsp&nbsp&nbsp&nbsptype:<td>
                    <select name="select_type" id="select_type" class="custom_select" value="Any Type" style="width:70%" onchange="javascript:filter_item();">
                    </select>                    </td>
                </tr>
              </table></td>
            </tr>
            <tr>
              <td width="50%" height="50" nowrap="nowrap" class="custom_list_type_bottomright"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                  <tr>
                    <td width="30%" height="50" align="left" class="custom_title">&nbsp&nbsp&nbsp&nbsptestset:<td>
                      <select name="select_testset" id="select_testset" class="custom_select" value="Any Test Set" style="width:70%" onchange="javascript:filter_item();">
                    </select>                    </td>
                  </tr>
              </table></td>
              <td width="50%" height="50" nowrap="nowrap" class="custom_list_type_bottom"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                 <tr>
                  <td width="30%" height="50" align="left" class="custom_title">&nbsp&nbsp&nbsp&nbspcomponent:<td>
                    <select name="select_com" id="select_com" class="custom_select" value="Any Component" style="width:70%" onchange="javascript:filter_item();">
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
          <td><table width="100%" height="50" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
            <tr>
              <td><table width="100%" height="50" border="1" cellspacing="0" cellpadding="0" frame="below" rules="none">
                <tr>
              <td width="4%" height="36" align="center" valign="middle" class="custom_list_type_bottomright_title"><input type="checkbox" id="checkbox_all"  name="checkbox_all" value="checkbox_all" onclick="javascript:check_uncheck_all();" /></td>
              <td width="24%" height="50" class="custom_list_type_bottomright_title">&nbsp&nbsp&nbsp&nbspPackage Name </td>
              <td width="24%" height="50" class="custom_list_type_bottomright_title">&nbsp&nbsp&nbsp&nbspCase Number </td>
              <td width="24%" height="50" class="custom_list_type_bottomright_title">&nbsp&nbsp&nbsp&nbspVersion</td>
              <td width="24%" height="50" class="custom_list_type_bottom_title">&nbsp&nbsp&nbsp&nbspOpreation</td>
                </tr>
              </table></td>
            </tr>
            </tr>
          </table></td>
        </tr>
        <tr><table width="100%" height="300" border="0" align="center" class="backbackground_button" cellpadding="0" cellspacing="0">
        	<tr>
        		<td width="20%" class="backbackground_button">&nbsp;</td>
        		<td width="80%"><input type="button" class="custom_list_type_bottomright_packagename" id="update_null_page" name="update_null_page" value="No packages, please install packages and then click here to refresh page!" onclick="javascript:refreshPage();" /></td>
        	</tr>
        </table>
        </tr>
        <tr>
          <td><table width="100%" height="50" border="0" align="center" class="backbackground_button" cellpadding="0" cellspacing="0">
            <tr>
              <td width="3.5%" align="center" valign="middle"><img src="images/environment-spacer.gif" width="1" height="1" /></td>
              <td width="10%"><div align="center">
                <input type="submit" id="execute_profile" name="execute_profile" class="large_button" value="Execute"/>
              </div></td>
              <td width="1%"><img src="images/environment-spacer.gif" width="1" height="1" /></td>
              <td width="9%" class="backbackground_button"><div align="center">
                <input name="Submit3" type="submit" class="large_button" value="Veiw" />
              </div></td>
              <td width="4%"><img src="images/environment-spacer.gif" width="1" height="1" /></td>
              <td width="6%" class="backbackground_button">&nbsp;</td>
              <td width="11%" nowrap="nowrap" class="custom_font">Profile name:</td>
DATA
}

#After press "Save", "Load", "Delete" button, refresh the page.
sub UpdateLoadPage {

	@sort_package_name    = sort @package_name;
	@reverse_package_name = reverse @sort_package_name;
	if ( $_GET{'order'} ) {
		if ( $_GET{'order'} eq "down" ) {
			@package_name = @reverse_package_name;
			$image        = "images/up_and_down_2.png";
			$value        = "up";
		}
		elsif ( $_GET{'order'} eq "up" ) {
			@package_name = @sort_package_name;
			$image        = "images/up_and_down_1.png";
			$value        = "down";
		}
	}

	if ( $value eq "" ) {
		$value = "up";
	}
	if ( $image eq "" ) {
		$image = "images/up_and_down_2.png";
	}

	print "HTTP/1.0 200 OK" . CRLF;
	print "Content-type: text/html" . CRLF . CRLF;

	print_header( "$MTK_BRANCH Manager Main Page", "custom" );

	AnalysisReadMe();

	GetSelectItem();

	print <<DATA;
	<table width="1280" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
	  <tr>
	    <td><form id="tests_custom" name="tests_custom" method="post" action="tests_custom.pl">
	      <table width="100%" height="50" border="0" cellspacing="0" cellpadding="0">
	        <tr>
	          <td><table width="100%" height="50" border="0" cellspacing="0" cellpadding="0" background="images/report_top_button_background.png">
	            <tr>
	              <td width="2.5%" height="50" nowrap="nowrap">&nbsp;</td>
	              <td width="17%" height="50" nowrap="nowrap"><table width="100%" border="0" cellspacing="0" cellpadding="0">
	                <tr>
	                  <td width="47%" height="50" align="left" class="custom_title">Architecture:&nbsp</td>
	                  <td width="53%" height="50"><select id="select_arc" name="select_arc" class="custom_select">
	                    <option>X86</option>
	                  </select>                  </td>
	                </tr>
	              </table></td>
	              <td width="13%" height="50" nowrap="nowrap"><table width="100%" border="0" cellspacing="0" cellpadding="0">
	                <tr>
	                <td width="13%" height="50" nowrap="nowrap">&nbsp;</td>
	                  <td width="37%" height="50" align="right" class="custom_title">Version:&nbsp</td>
	                  <td width="50%" height="50" ><select id="select_ver" name="select_ver" class="custom_select" onchange="javascript:filter_item();">
DATA
	LoadDrawVersionSelect();
	print <<DATA;
                  </select></td>
                </tr>
              </table></td>
              <td width="2%" height="50" nowrap="nowrap">&nbsp;</td>
              <td width="4%" height="50" id="name" nowrap="nowrap" class="custom_title">Name:&nbsp</td>
              <td width="4.5%" height="50" nowrap="nowrap"><a href="tests_custom.pl?order=$value"><img src="$image" width="38" height="38"/></a></td>
              <td width="54%" height="50" nowrap="nowrap"><input id="button_adv" name="button_adv" class="medium_button" type="button" value="Advanced" onclick="javascript:hidden_Advanced_List();"/></td>
              <td width="3%" height="50" nowrap="nowrap">&nbsp;</td>
            </tr>
          </table></td>
        </tr>
        <tr>
        
DATA
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
		print <<DATA;
          <td id="list_advanced" style="display:none"><table width="1280" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
DATA
	}
	else {
		print <<DATA;
		<td id="list_advanced" style="display:"><table width="1280" border="1" cellspacing="0" cellpadding="0" frame="void" rules="none">
DATA
	}

	print <<DATA;
            <tr>
              <td width="50%" height="50" nowrap="nowrap" class="custom_list_type_bottomright"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="50" align="left" class="custom_title">&nbsp&nbsp&nbsp&nbspcategory:</td><td>
                    <select name="select_category" align="20px" id="select_category" class="custom_select" style="width:70%" onchange="javascript:filter_item();">
DATA
	LoadDrawCategorySelect();
	print <<DATA;
                    </select>                    </td>
                </tr>
              </table></td>
              <td width="50%" height="50" nowrap="nowrap" class="custom_list_type_bottom"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="50" align="left" class="custom_title">&nbsp&nbsp&nbsp&nbsppriority:<td>
                    <select name="select_pri" id="select_pri" class="custom_select" style="width:70%" onchange="javascript:filter_item();">
DATA
	LoadDrawPrioritySelect();
	print <<DATA;
                    </select>                    </td>
                </tr>
              </table></td>
            </tr>
            <tr>
              <td width="30%" height="50" nowrap="nowrap" class="custom_list_type_bottomright"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="50" align="left" class="custom_title">&nbsp&nbsp&nbsp&nbspstatus:<td>
                    <select name="select_status" id="select_status" class="custom_select" style="width:70%" onchange="javascript:filter_item();">
DATA
	LoadDrawStatusSelect();
	print <<DATA;
                    </select>                    </td>
                </tr>
              </table></td>
              <td width="50%" height="50" nowrap="nowrap" class="custom_list_type_bottom"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="50" align="left" class="custom_title">&nbsp&nbsp&nbsp&nbspexecution_type:<td>
                    <select name="select_exe" id="select_exe" class="custom_select" style="width:70%" onchange="javascript:filter_item();">
DATA
	LoadDrawExecutiontypeSelect();
	print <<DATA;
                    </select>                    </td>
                </tr>
              </table></td>
            </tr>
            <tr>
              <td width="50%" height="50" nowrap="nowrap" class="custom_list_type_bottomright"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="50" align="left" class="custom_title">&nbsp&nbsp&nbsp&nbsptestsuite:<td>
                    <select name="select_testsuite" id="select_testsuite" class="custom_select" style="width:70%" onchange="javascript:filter_item();">
DATA
	LoadDrawTestsuiteSelect();
	print <<DATA;
                    </select>                    </td>
                </tr>
              </table></td>
              <td width="50%" height="50" nowrap="nowrap" class="custom_list_type_bottom"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                <tr>
                  <td width="30%" height="50" align="left" class="custom_title">&nbsp&nbsp&nbsp&nbsptype:<td>
                    <select name="select_type" id="select_type" class="custom_select" style="width:70%" onchange="javascript:filter_item();">
DATA
	LoadDrawTypeSelect();
	print <<DATA;
                    </select>                    </td>
                </tr>
              </table></td>
            </tr>
            <tr>
              <td width="50%" height="50" nowrap="nowrap" class="custom_list_type_bottomright"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                  <tr>
                    <td width="30%" height="50" align="left" class="custom_title">&nbsp&nbsp&nbsp&nbsptestset:<td>
                      <select name="select_testset" id="select_testset" class="custom_select" style="width:70%" onchange="javascript:filter_item();">
DATA
	LoadDrawTestsetSelect();
	print <<DATA;
                    </select>                    </td>
                  </tr>
              </table></td>
              <td width="50%" height="50" nowrap="nowrap" class="custom_list_type_bottom"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
                 <tr>
                  <td width="30%" height="50" align="left" class="custom_title">&nbsp&nbsp&nbsp&nbspcomponent:<td>
                    <select name="select_com" id="select_com" class="custom_select" style="width:70%" onchange="javascript:filter_item();">
DATA
	LoadDrawComponentSelect();
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
          <td><table width="100%" height="50" border="0" cellspacing="0" cellpadding="0" frame="void" rules="none">
            <tr>
              <td><table width="100%" height="50" border="1" cellspacing="0" cellpadding="0" frame="below" rules="none">
                <tr>
              <td width="4%" height="36" align="center" valign="middle" class="custom_list_type_bottomright_title"><input type="checkbox" id="checkbox_all"  name="checkbox_all" value="checkbox_all" onclick="javascript:check_uncheck_all();" /></td>
              <td width="24%" height="50" class="custom_list_type_bottomright_title">&nbsp&nbsp&nbsp&nbspPackage Name </td>
              <td width="24%" height="50" class="custom_list_type_bottomright_title">&nbsp&nbsp&nbsp&nbspCase Number </td>
              <td width="24%" height="50" class="custom_list_type_bottomright_title">&nbsp&nbsp&nbsp&nbspVersion</td>
              <td width="24%" height="50" class="custom_list_type_bottom_title">&nbsp&nbsp&nbsp&nbspOperation</td>
              <input type="hidden" id="package_name_number" name="package_name_number" value="$package_name_number">
                </tr>
              </table></td>
            </tr>
DATA
	LoadDrawPackageList();
	print <<DATA;
            </tr>
          </table></td>
        </tr>
        <tr>
        <td height="4" width="100%" class="backbackground_button"></td>
        </tr>
        <tr>
          <td><table width="100%" height="48" border="0" class="backbackground_button" cellpadding="0" cellspacing="0">
            <tr>
              <td width="3.5%" align="center" valign="middle"><img src="images/environment-spacer.gif" width="1" height="1" /></td>
              <td width="10%" valign="top"><div align="center">
                <input type="submit" id="execute_profile" name="execute_profile" class="large_button" value="Execute"/>
              </div></td>
              <td width="1%"><img src="images/environment-spacer.gif" width="1" height="1" /></td>
              <td width="9%" valign="top" class="backbackground_button"><div align="center">
                <input name="Submit3" type="submit" class="large_button" value="Veiw" />
              </div></td>
              <td width="4%"><img src="images/environment-spacer.gif" width="1" height="1" /></td>
              <td width="6%" class="backbackground_button">&nbsp;</td>
              <td width="11%" valign="top"><table>
		        <tr>
		        	<td height="1" class="backbackground_button"></td>
		        </tr>
              	<tr>
              		<td nowrap="nowrap" class="custom_font">Profile name:</td>
              	</tr>
              </table>
              </td>
DATA
}

print <<DATA;
              <td width="21%" valign="top"><table width="100%" border="0" cellspacing="0" cellpadding="0">
                <tr>
		        	<td height="7" class="backbackground_button"></td>
		        </tr>
                <tr>
                  <td>
                  <label><input name="edit_profile_name" type="text" class="custom_font" id="edit_profile_name" value="" style="width: 14em;" onkeyup="showtips();if(event.keyCode==27)c();" onkeydown="enterTips()" autocomplete=off /></label></td>
                </tr>
                <tr>
                  <td><label><select id="sel" size="4" style="display:none;height:auto;width:11.6em;" onclick=returnValue() onkeydown="if(event.keyCode==13){returnValue()}">
                   </select>
                  </label>
                  </td>
                </tr>
              </table></td>
              
              <td width="1%"><img src="images/environment-spacer.gif" width="1" height="1" /></td>
              <td width="9%" align="top" valign="top" class="backbackground_button"><input name="save_profile_button" id="save_profile_button"  type="button" class="medium_button" value="Save" onclick="javascript:onSave();"/></td>
              <td width="1%"><img src="images/environment-spacer.gif" width="1" height="1" /></td>
              <td width="9%" align="center" valign="top" class="backbackground_button"><input name="load_profile_button" id="load_profile_button" type="button" class="medium_button" value="Load" onclick="javascript:onLoad();"/></td>
              <td width="1%"><img src="images/environment-spacer.gif" width="1" height="1" /></td>
              <td width="9%" align="center" valign="top" class="backbackground_button"><input name="delete_profile_button" id="delete_profile_button" type="button" class="medium_button" value="Delete" onclick="javascript:onDelete();"/></td>
              <td width="1%"><img src="images/environment-spacer.gif" width="16" height="1" /></td>
            </tr>
          </table></td>
        </tr>
      </table>
        </form>
    </td>
  </tr>
</table>
<script language="javascript" type="text/javascript">
// <![CDATA[
var profiles_list;      // List of user profiles.
DATA

print <<DATA;
var package_name_number = 
DATA
print $package_name_number. ";";

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
 foreach(@files_temp){
  	if($_ =~ /^\./){
  		next;
  	}
  	else{
  		push(@files,$_);
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
var version_flag = new Array(
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
var category_flag = new Array(
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
var priority_flag = new Array(
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
var status_flag = new Array(
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
var execution_type_flag = new Array(
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
var test_suite_flag = new Array(
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
var type_flag = new Array(
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
var test_set_flag = new Array(
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
var component_flag = new Array(
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
var id = new Array(
DATA

print <<DATA;
	);
DATA

print <<DATA;
// Find and cache most of the necessary HTML document elements.
var edit_profile_name = document.getElementById('edit_profile_name');
var list_profile_name = document.getElementById('list_profile_name');

function rank()
{
	var image;
	var value;
	image = document.getElementById('image_up_down');
	value = document.getElementById('value_up_down');
	if(image.src == "images/up_and_down_1.png"){
		image.src = "images/up_and_down_2.png";
	}else{
		image.src = "images/up_and_down_1.png";
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
	advanced_list = document.getElementById('list_advanced');
	if(advanced_list.style.display == ""){
		advanced_list.style.display = "none";
	}else{
		advanced_list.style.display = "";
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
	}
}
DATA

print <<DATA;

function filter_item(){
	var view_version 		= document.getElementById('select_ver');
	var view_category 		= document.getElementById('select_category');
	var view_priority 		= document.getElementById('select_pri');
	var view_status		= document.getElementById('select_status');
	var view_execution_type 	= document.getElementById('select_exe');
	var view_test_suite 		= document.getElementById('select_testsuite');
	var view_type 			= document.getElementById('select_type');
	var view_test_set 		= document.getElementById('select_testset');
	var view_component 	= document.getElementById('select_com');
	var id;
	var j = 0; 
	var i = 0;
	var count_start = 0;
	var count_end = 0;
	if(view_version.value == "Any Version")
	{
		for(i  = 0;i < package_name_number ;i++)
		{
			version_flag[i] = "a";
		}
	}else
	{
		for(i  = 0;i < package_name_number ;i++)
		{
			if(view_version.value == version[i])
			{
				version_flag[i] = "a";
			}else
			{
				version_flag[i] = "b";
			}
		}
	}

	if(view_category.value == "Any Category")
	{
		for(i  = 0;i < package_name_number ;i++)
		{
			category_flag[i]="a";
		}
	}else
	{
		for(var i = 0;i < package_name_number ;i++)
		{
			if(category_num[i] == 0)
			{
				category_flag[i]="b";
				continue;
			}
			if(i == 0)
			{
				count_start = 0;
				count_end = category_num[i];
			}else
			{
				count_start += category_num[i-1];
				count_end += category_num[i];
			}
			
			if(count_start == count_end)
			{
				category_flag[i]="b";
			}else
			{
				for( j = count_start; j < count_end; j++)
				{
					if(view_category.value != category[j]){
						if(j == (count_end - 1))
						{
							category_flag[i]="b";
						}
					}
					if(view_category.value == category[j])
					{
						category_flag[i]="a";
						break;
					}
				}
			}
		}
	}

	if(view_priority.value == "Any Priority")
	{
		for(i  = 0;i < package_name_number ;i++)
		{
			priority_flag[i]="a";
		}
	}else
	{
		for(var i = 0;i < package_name_number ;i++)
		{
			if(priority_num[i] == 0)
			{
				priority_flag[i]="b";
				continue;
			}
			if(i == 0)
			{
				count_start = 0;
				count_end = priority_num[i];
			}else
			{
				count_start += priority_num[i-1];
				count_end += priority_num[i];
			}
			
			if(count_start == count_end)
			{
				priority_flag[i]="b";
			}else
			{
				for( j = count_start; j < count_end; j++)
				{
					if(view_priority.value != priority[j]){
						if(j == (count_end - 1))
						{
							priority_flag[i]="b";			
						}
					}
					if(view_priority.value == priority[j])
					{
						priority_flag[i]="a";
						break;
					}
				}
			}
		}
	}

	if(view_status.value == "Any Status")
	{
		for(i  = 0;i < package_name_number ;i++)
		{
			status_flag[i]="a";
		}
	}else
	{
		for(var i = 0;i < package_name_number ;i++)
		{
			if(status_num[i] == 0)
			{
				status_flag[i]="b";
				continue;
			}
			if(i == 0)
			{
				count_start = 0;
				count_end = status_num[i];
			}else
			{
				count_start += status_num[i-1];
				count_end += status_num[i];
			}
			
			if(count_start == count_end)
			{
				status_flag[i]="b";
			}else
			{
				for( j = count_start; j < count_end; j++)
				{   
					if(view_status.value != status_s[j]){
						if(j == (count_end - 1))
						{
							status_flag[i]="b";		
						}
					}
					if(view_status.value == status_s[j])
					{
						status_flag[i]="a";
						break;
					}
				}
			}
		}
	}

	if(view_execution_type.value == "Any Execution Type")
	{
		for(i  = 0;i < package_name_number ;i++)
		{
			execution_type_flag[i]="a";	
		}
	}else
	{
		for(var i = 0;i < package_name_number ;i++)
		{
			if(execution_type_num[i] == 0)
			{
				execution_type_flag[i]="b";	
				continue;
			}
			if(i == 0)
			{
				count_start = 0;
				count_end = execution_type_num[i];
			}else
			{
				count_start += execution_type_num[i-1];
				count_end += execution_type_num[i];
			}
			
			if(count_start == count_end)
			{
				execution_type_flag[i]="b";	
			}else
			{
				for( j = count_start; j < count_end; j++)
				{	
					if(view_execution_type.value != execution_type[j]){
						if(j == (count_end - 1))
						{
							execution_type_flag[i]="b";					
						}
					}
					if(view_execution_type.value == execution_type[j])
					{
						execution_type_flag[i]="a";	
						break;
					}
				}
			}
		}
	}

	if(view_test_suite.value == "Any Test Suite")
	{
		for(i  = 0;i < package_name_number ;i++)
		{
			test_suite_flag[i]="a";	
		}
	}else
	{
		for(var i = 0;i < package_name_number ;i++)
		{
			if(test_suite_num[i] == 0)
			{
				test_suite_flag[i]="b";	
				continue;
			}
			if(i == 0)
			{
				count_start = 0;
				count_end = test_suite_num[i];
			}else
			{
				count_start += test_suite_num[i-1];
				count_end += test_suite_num[i];
			}
			
			if(count_start == count_end)
			{
				test_suite_flag[i]="b";
			}else
			{
				for( j = count_start; j < count_end; j++)
				{
					if(view_test_suite.value != test_suite[j]){
						if(j == (count_end - 1))
						{
							test_suite_flag[i]="b";				
						}
					}
					if(view_test_suite.value == test_suite[j])
					{
						test_suite_flag[i]="a";
						break;
					}
				}
			}
		}
	}

	if(view_type.value == "Any Type")
	{
		for(i  = 0;i < package_name_number ;i++)
		{
			type_flag[i]="a";
		}
	}else
	{
		for(var i = 0;i < package_name_number ;i++)
		{
			if(type_num[i] == 0)
			{
				type_flag[i]="b";
				continue;
			}
			if(i == 0)
			{
				count_start = 0;
				count_end = type_num[i];
			}else
			{
				count_start += type_num[i-1];
				count_end += type_num[i];
			}
			
			if(count_start == count_end)
			{
				type_flag[i]="b";
			}else
			{
				for( j = count_start; j < count_end; j++)
				{ 
					if(view_type.value != type[j]){
						if(j == (count_end - 1))
						{
							type_flag[i]="b";			
						}
					}
					if(view_type.value == type[j])
					{
						type_flag[i]="a";
						break;
					}
				}
			}
		}
	}

	if(view_test_set.value == "Any Test Set")
	{
		for(i  = 0;i < package_name_number ;i++)
		{
			test_set_flag[i]="a";
		}
	}else
	{
		for(var i = 0;i < package_name_number ;i++)
		{
			if(test_set_num[i] == 0)
			{
				test_set_flag[i]="b";
				continue;
			}
			if(i == 0)
			{
				count_start = 0;
				count_end = test_set_num[i];
			}else
			{
				count_start += test_set_num[i-1];
				count_end += test_set_num[i];
			}
			
			if(count_start == count_end)
			{
				test_set_flag[i]="b";
			}else
			{
				for( j = count_start; j < count_end; j++)
				{
					if(view_test_set.value != test_set[j]){
						if(j == (count_end - 1))
						{
							test_set_flag[i]="b";				
						}
					}
					if(view_test_set.value == test_set[j])
					{
						test_set_flag[i]="a";
						break;
					}
				}
			}
		}
	}

	if(view_component.value == "Any Component")
	{
		for(i  = 0;i < package_name_number ;i++)
		{
			component_flag[i]="a";
		}
	}else
	{
		for(var i = 0;i < package_name_number ;i++)
		{
			if(component_num[i] == 0)
			{
				component_flag[i]="b";
				continue;
			}
			if(i == 0)
			{
				count_start = 0;
				count_end = component_num[i];
			}else
			{
				count_start += component_num[i-1];
				count_end += component_num[i];
			}
			
			if(count_start == count_end)
			{
				component_flag[i]="b";
			}else
			{
				for( j = count_start; j < count_end; j++)
				{
					if(view_component.value != component[j]){
						if(j == (count_end - 1))
						{
							component_flag[i]="b";				
						}
					}
					if(view_component.value == component[j])
					{
						component_flag[i]="a";
						break;
					}
				}
			}
		}
	}
	for(var i = 0;i < package_name_number ;i++)
	{   
		if((version_flag[i] == "a")
		&&(category_flag[i] == "a")
		&&(priority_flag[i] == "a")
		&&(status_flag[i] == "a")
		&&(execution_type_flag[i] == "a")
		&&(test_suite_flag[i] == "a")
		&&(type_flag[i] == "a")
		&&(test_set_flag[i] == "a")
		&&(component_flag[i] == "a")
		)
		{  
			id = document.getElementById(main_list_id[i]);
			id.style.display = "";
			
		}else
		{
			id = document.getElementById(main_list_id[i]);
			id.style.display = "none";

		}
		id = document.getElementById(second_list_id[i]);
		if(id.style.display == "")
		{
			id.style.display = "none";
		}
	}
}

DATA
print <<DATA;
function onSave() {
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
	var checkbox_value="null";
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
	var flag=0;
	
	for(var count=0; count<package_name_number; count++){
		var checkbox_package_name_tmp="checkbox_package_name"+count;
		var checkbox_pacakage_name=document.getElementById(checkbox_package_name_tmp);
		if(checkbox_pacakage_name.checked){
			checkbox_value=checkbox_value+"*"+checkbox_pacakage_name.name;
		}
	}
	
	if (edit_profile_name.value == '') {
		edit_profile_name.style.borderColor = 'white';
		alert('Please, specify the profile name!');
		return false;
	}
	else{
		var save_pro_file = new Array(
DATA
	my $file;
	my $dir_profile_name = $profile_dir_manager;
	my $save_profile;
	my @save_profile;
	my $profile_count = 0;
	
	opendir DELPROFILE, $dir_profile_name
	  or die "can not open $dir_profile_name";
	foreach $file ( readdir DELPROFILE ) {
		$save_profile = $file;
		push( @save_profile, $save_profile );
		$profile_count++;
	}
	for ( $count_num = 0 ; $count_num < $profile_count ; $count_num++ ) {
		if ( $count_num == $profile_count - 1 ) {
			print '"' . $save_profile[$count_num] . '"';
		}
		else {
			print '"' . $save_profile[$count_num] . '"' . ",";
		}
	}
print <<DATA;
	);			
		for (var pro_count=0; pro_count<$profile_count; pro_count++){
			if (save_pro_file[pro_count] == edit_profile_name.value){
				flag=1;
			}
		}
		if(flag){
			if(confirm("Profile: "+edit_profile_name.value+" exists, Would you like to overwirte it?")){
					document.location="tests_custom.pl?save_profile_button="+edit_profile_name.value+"&checkbox="+checkbox_value+"&advanced="+arc+"*"+ver+"*"+category+"*"+pri+"*"+status+"*"+exe+"*"+testsuite+"*"+type+"*"+testset+"*"+com;
			}
		}
		else{
			document.location="tests_custom.pl?save_profile_button="+edit_profile_name.value+"&checkbox="+checkbox_value+"&advanced="+arc+"*"+ver+"*"+category+"*"+pri+"*"+status+"*"+exe+"*"+testsuite+"*"+type+"*"+testset+"*"+com;
		}
	}
}

function onLoad() {
	var flag=1;
	if (edit_profile_name.value == '') {
		edit_profile_name.style.borderColor = 'white';
		alert('Please, specify the profile name!');
		return false;
	}
	else{
		var save_pro_file = new Array(
DATA
	my $file_load;
	my $dir_profile_name_load = $profile_dir_manager;
	my $load_profile;
	my @load_profile;
	my $profile_count_load = 0;
	
	opendir DELPROFILE, $dir_profile_name_load
	  or die "can not open $dir_profile_name_load";
	foreach $file_load ( readdir DELPROFILE ) {
		$load_profile = $file_load;
		push( @load_profile, $load_profile );
		$profile_count_load++;
	}
	for ( $count_num = 0 ; $count_num < $profile_count_load ; $count_num++ ) {
		if ( $count_num == $profile_count - 1 ) {
			print '"' . $load_profile[$count_num] . '"';
		}
		else {
			print '"' . $load_profile[$count_num] . '"' . ",";
		}
	}
print <<DATA;
	);			
		for (var pro_count=0; pro_count<$profile_count; pro_count++){
			if (save_pro_file[pro_count] == edit_profile_name.value){
				flag=0;
			}
		}
		if(flag){
			alert("Does not exist profile: "+edit_profile_name.value);
		}
		else {	
			document.location="tests_custom.pl?load_profile_button="+edit_profile_name.value;
			}
	}
}

DATA
print <<DATA;

function onDelete() {	
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
	var checkbox_value="null";
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
	var flag=1;
	
	for(var count=0; count<package_name_number; count++){
		var checkbox_package_name_tmp="checkbox_package_name"+count;
		var checkbox_pacakage_name=document.getElementById(checkbox_package_name_tmp);
		if(checkbox_pacakage_name.checked){
			checkbox_value=checkbox_value+"*"+checkbox_pacakage_name.name;
		}
	}
	
	if (edit_profile_name.value == '') {
		edit_profile_name.style.borderColor = 'white';
		alert('Please, specify the profile name!');
		return false;
	}
	else{
		var delete_pro_file = new Array(
DATA
	my $file_del;
	my $dir_profile_name_del = $profile_dir_manager;
	my $delete_profile;
	my @delete_profile;
	my $profile_count_del = 0;
	
	opendir DELPROFILE, $dir_profile_name_del
	  or die "can not open $dir_profile_name_del";
	foreach $file_del ( readdir DELPROFILE ) {
		$delete_profile = $file_del;
		push( @delete_profile, $delete_profile );
		$profile_count_del++;
	}
	for ( $count_num = 0 ; $count_num < $profile_count_del ; $count_num++ ) {
		if ( $count_num == $profile_count_del - 1 ) {
			print '"' . $delete_profile[$count_num] . '"';
		}
		else {
			print '"' . $delete_profile[$count_num] . '"' . ",";
		}
	}
print <<DATA;
	);	
		for (var pro_count=0; pro_count<$profile_count; pro_count++){
			if (delete_pro_file[pro_count] == edit_profile_name.value){
				flag=0;
			}
		}
		if(flag){
			alert("Does not exist profile: "+edit_profile_name.value);
		}
		else {
			if(confirm("Can you confirm to delete Profile: "+edit_profile_name.value)){		
				document.location="tests_custom.pl?delete_profile_button="+edit_profile_name.value+"&checkbox="+checkbox_value+"&advanced="+arc+"*"+ver+"*"+category+"*"+pri+"*"+status+"*"+exe+"*"+testsuite+"*"+type+"*"+testset+"*"+com;
			}
		}
	}
}

function refreshPage() {
	document.location="tests_custom.pl";
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
	
	
	if(confirm("Can you confirm to delete "+pkg+"?")){
		document.location="tests_custom.pl?delete_package=1&delete_"+pkg+"=1&checkbox="+checkbox_value+"&advanced="+arc+"*"+ver+"*"+category+"*"+pri+"*"+status+"*"+exe+"*"+testsuite+"*"+type+"*"+testset+"*"+com;
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

function showtips(){
	eo=event.srcElement;
	sel.length=0;
	var len=msg.length;
	var re=new RegExp("^"+eo.value,"i")
	var flag=0
	for(i=0;i<len;i++){
		if(re.test(msg[i])==true){
			sel.style.display=''
			sel.add(new Option(msg[i]))
			sel.selectedIndex=0
			flag=1	
		}
	}
	if(flag==0){
			sel.style.display=''
			sel.add(new Option("No match profile"))
			sel.selectedIndex=0
	}	
}

function enterTips(){
	e=event.keyCode;
	if(sel.style.display!='none'){
		if(e==13){
			event.srcElement.value=sel.value,sel.style.display='none'
		}
		if(e==40){
			sel.focus();
		}
	}
}
function returnValue(){
	var txt=document.getElementById('edit_profile_name');
	txt.value=sel.value;
	c();
}
function c(){
	var txt=document.getElementById('edit_profile_name');
	sel.style.display='none';
	txt.focus();
}
document.onclick=function(){c()}

</script>
DATA

sub ScanPackages {
	$testSuitesPath = "/usr/share/";
	find( \&GetPackageName, $testSuitesPath );
}

sub CountPackages {
	while ( $package_name_number < @package_name ) {
		$package_name_number++;
	}
}

sub AnalysisVersion {
	my $temp;
	my $temp_version;
	my $temp_count = 0;
	while ( $temp_count < $package_name_number ) {
		$temp = `su tizen -c 'rpm -qa|grep $package_name[$temp_count]'`;
		if ( $temp =~ /tests-(.*?)-/ ) {
			$temp_version = $1;
			push( @version, $temp_version );
		}
		$temp_count++;
	}
}

sub CreateFilePath {
	my $count = 0;
	while ( $count < $package_name_number ) {
		$read_me[$count] = "/opt/" . $package_name[$count] . "/README";
		$licence_copyright[$count] =
		  "/opt/" . $package_name[$count] . "/LICENSE";
		$installation_path[$count] = "/opt/" . $package_name[$count] . "/";
		$testsxml[$count] =
		  "/usr/share/" . $package_name[$count] . "/tests.xml";
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
			if ( $_ =~ /type="(.*?)"/ ) {
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
			$temp = "NO Introduction";
		}
		push( @introduction, $temp );
		$temp    = "";
		$content = "";
		$count++;
	}
}

sub LoadDrawPackageList {
	my $count = 0;
	my $display;
	my $i = @checkbox_packages;
	while ( $count < $package_name_number ) {
		my $count_chkbox = 0;
		if ( $package_name_flag[$count] eq "a" ) {
			$display = "";
		}
		else {
			$display = "none";
		}
		print <<DATA;
            <tr id="main_list_$package_name[$count]" style="display:$display">
              <td><table width="100%" height="50" border="1" cellspacing="0" cellpadding="0" frame="below" rules="none">
DATA
		my $flag = 0;
		while ( $count_chkbox < $i ) {
			if ( $checkbox_packages[$count_chkbox] =~ /$package_name[$count]/ )
			{
				$flag = 1;
				print <<DATA;
				<td width="4%" height="50" align="center" valign="middle" class="custom_list_type_bottomright"><input type="checkbox" id="checkbox_package_name$count" name="checkbox_$package_name[$count]" checked=true /></td>	
DATA
			}
			$count_chkbox++;
		}
		if ( $flag eq "0" ) {
			print <<DATA;
				<td width="4%" height="50" align="center" valign="middle" class="custom_list_type_bottomright"><input type="checkbox" id="checkbox_package_name$count" name="checkbox_$package_name[$count]" /></td>	
DATA
		}
		print <<DATA;
              <td width="24%" height="50" class="custom_list_type_bottomright_packagename" id="pn_$package_name[$count]"><a  onclick="javascript:show_CaseDetail('second_list_$package_name[$count]');">&nbsp&nbsp&nbsp&nbsp$package_name[$count]</a></td>
              <td width="24%" height="50" class="custom_list_type_bottomright" id="cn_$package_name[$count]" name="cn_$package_name[$count]">&nbsp&nbsp&nbsp&nbsp$case_number[3*$count]</td>
              <td width="24%" height="50" valign="middle" nowrap="nowrap" bordercolor="#ECE9D8" class="custom_list_type_bottomright"><table width="58%" border="0" cellspacing="0" cellpadding="0">
                <tr>
                  <td width="22%" height="50" align="center" valign="middle"><div align="right"><img src="images/package_version.png" width="38" height="38" /></div></td>
                  <td width="78%" height="50" align="center" valign="middle"><div align="left" class="custom_title" id="ver_$package_name[$count]">$version[$count]</div></td>
                </tr>
              </table></td>
              <td width="24%" height="50" class="custom_list_type_bottom"><table width="100%" border="0" cellspacing="0" cellpadding="0">
                <tr>
                  <td align="center" height="50" valign="middle"><div align="left"><img src="images/operation_install.png" width="38" height="38" /></div></td>
                  <td align="center" height="50" valign="middle"><div align="left"><img src="images/operation_update.png" width="38" height="38" /></div></td>
                  <td align="center" height="50" valign="middle"><div align="left"><img title="Delete package" src="images/operation_delete.png" id="delete_$package_name[$count]" name="delete_$package_name[$count]" style="cursor:pointer" width="38" height="38" onclick="javascript:onDeletePackage($count);"/></a></td>
                  <input type="hidden" id="pn_package_name_$count" name="pn_package_name_$count" value="$package_name[$count]">
                  <td align="center" height="50" valign="middle"><div align="left"><img src="images/operation_view_tests.png" width="38" height="38" /></div></td>
                </tr>
              </table></td>
              </table>
		</td>
            </tr>
            <tr id="second_list_$package_name[$count]" style="display:none">
              <td><table width="100%" height="50" border="0" cellspacing="0" cellpadding="0">
            <tr>
              <td width="40%" height="50" align="left" valign="middle" nowrap="nowrap" class="custom_list_type_bottomright">&nbsp&nbsp&nbsp&nbspIntroduction: </td>
              <td width="60%" height="50" align="left" valign="middle" class="custom_list_type_bottom" id="intro_$package_name[$count]">$introduction[$count]</td>
              </tr>
            <tr>
              <td align="left" height="50" valign="middle" nowrap="nowrap" class="custom_list_type_bottomright">&nbsp&nbsp&nbsp&nbspCase Number(auto manual): </td>
              <td class="custom_list_type_bottom" height="50" id="cnam_$package_name[$count]"><table width="100%" border="0" cellpadding="0" cellspacing="0" class="custom_font">
                <tr>
                  <td width="5%" height="50" align="left" valign="middle">$case_number[3*$count+1]</td>
                  <td width="95%" height="50" align="left" valign="middle">&nbsp&nbsp&nbsp&nbsp$case_number[3*$count+2]</td>
                </tr>
              </table></td>
              </tr>
            <tr>
              <td align="left" valign="middle" nowrap="nowrap" class="custom_list_type_bottomright">&nbsp&nbsp&nbsp&nbspReadme:</td>
              <td width="5%" height="50" align="left" valign="middle" class="custom_list_type_bottom">$read_me[$count]
                <a href="/get.pl?file=$read_me[$count]"><image name="imageField" src="images/operation_open_file.png" align="middle" width="38" height="38" /></td>
              </tr>
            <tr>
              <td align="left" height="50" valign="middle" nowrap="nowrap" class="custom_list_type_bottomright">&nbsp&nbsp&nbsp&nbspLicence&amp;Copyright:</td>
              <td width="5%" height="50" align="left" valign="middle" id=$licence_copyright[$count] class="custom_list_type_bottom">$licence_copyright[$count]
                <a href="/get.pl?file=$licence_copyright[$count]"><image name="imageField2" src="images/operation_open_file.png" align="middle" width="38" height="38" /></td>
              </tr>
            <tr>
              <td align="left" height="50" valign="middle" nowrap="nowrap" class="custom_list_type_bottomright">&nbsp&nbsp&nbsp&nbspInstallation Path:</td>
              <td width="5%" height="50" align="left" valign="middle" class="custom_list_type_bottom">$installation_path[$count]
                <image name="imageField3" id=$installation_path[$count] src="images/operation_copy_url.png" width="38" height="38" onclick="javascript:copyUrl(id);" style="cursor:pointer"/></td>
              </tr>
            <tr>
              </table>
		</td>
            </tr>
DATA
		$count++;
	}

}

sub DrawPackageList {
	my $count = 0;
	while ( $count < $package_name_number ) {
		print <<DATA;
            <tr id="main_list_$package_name[$count]">
              <td><table width="100%" height="50" border="1" cellspacing="0" cellpadding="0" frame="below" rules="none">
              <td width="4%" height="50" align="center" valign="middle" class="custom_list_type_bottomright"><input type="checkbox" id="checkbox_package_name$count" name="checkbox_$package_name[$count]" /></td>
              <td width="24%" height="50" class="custom_list_type_bottomright_packagename" id="pn_$package_name[$count]"><a  onclick="javascript:show_CaseDetail('second_list_$package_name[$count]');">&nbsp&nbsp&nbsp&nbsp$package_name[$count]</a></td>
              <td width="24%" height="50" class="custom_list_type_bottomright" id="cn_$package_name[$count]" name="cn_$package_name[$count]">&nbsp&nbsp&nbsp&nbsp$case_number[3*$count]</td>
              <td width="24%" height="50" valign="middle" nowrap="nowrap" bordercolor="#ECE9D8" class="custom_list_type_bottomright"><table width="58%" border="0" cellspacing="0" cellpadding="0">
                <tr>
                  <td width="22%" height="50" align="center" valign="middle"><div align="right"><img src="images/package_version.png" width="38" height="38" /></div></td>
                  <td width="78%" height="50" align="center" valign="middle"><div align="left" class="custom_title" id="ver_$package_name[$count]">$version[$count]</div></td>
                </tr>
              </table></td>
              <td width="24%" height="50" class="custom_list_type_bottom"><table width="100%" border="0" cellspacing="0" cellpadding="0">
                <tr>
                  <td align="center" height="50" valign="middle"><div align="left"><img src="images/operation_install.png" width="38" height="38" /></div></td>
                  <td align="center" height="50" valign="middle"><div align="left"><img src="images/operation_update.png" width="38" height="38" /></div></td>
                  <td align="center" height="50" valign="middle"><div align="left"><img title="Delete package" src="images/operation_delete.png" id="delete_$package_name[$count]" name="delete_$package_name[$count]" style="cursor:pointer" width="38" height="38" onclick="javascript:onDeletePackage($count);" /></a></td>
                  <input type="hidden" id="pn_package_name_$count" name="pn_package_name_$count" value="$package_name[$count]">
                  <td align="center" height="50" valign="middle"><div align="left"><img src="images/operation_view_tests.png" width="38" height="38" /></div></td>
                </tr>
              </table></td>
              </table>
		</td>
            </tr>
            <tr id="second_list_$package_name[$count]" style="display:none">
              <td><table width="100%" height="50" border="0" cellspacing="0" cellpadding="0">
            <tr>
              <td width="40%" height="50" align="left" valign="middle" nowrap="nowrap" class="custom_list_type_bottomright">&nbsp&nbsp&nbsp&nbspIntroduction:</td>
              <td width="60%" height="50" align="left" valign="middle" class="custom_list_type_bottom" id="intro_$package_name[$count]">$introduction[$count]</td>
              </tr>
            <tr>
              <td align="left" height="50" valign="middle" nowrap="nowrap" class="custom_list_type_bottomright">&nbsp&nbsp&nbsp&nbspCase Number(auto manual):</td>
              <td class="custom_list_type_bottom" height="50" id="cnam_$package_name[$count]"><table width="100%" border="0" cellpadding="0" cellspacing="0" class="custom_font">
                <tr>
                  <td width="5%" height="50" align="left" valign="middle">$case_number[3*$count+1]</td>
                  <td width="95%" height="50" align="left" valign="middle">&nbsp&nbsp&nbsp&nbsp$case_number[3*$count+2]</td>
                </tr>
              </table></td>
              </tr>
            <tr>
              <td align="left" valign="middle" nowrap="nowrap" class="custom_list_type_bottomright">&nbsp&nbsp&nbsp&nbspReadme:</td>
              <td width="5%" height="50" align="left" valign="middle" class="custom_list_type_bottom">$read_me[$count]
                <a href="/get.pl?file=$read_me[$count]"><image name="imageField" src="images/operation_open_file.png" align="middle" width="38" height="38" /></td>
              </tr>
            <tr>
              <td align="left" height="50" valign="middle" nowrap="nowrap" class="custom_list_type_bottomright">&nbsp&nbsp&nbsp&nbspLicence&amp;Copyright:</td>
              <td width="5%" height="50" align="left" valign="middle" id=$licence_copyright[$count] class="custom_list_type_bottom">$licence_copyright[$count]
                <a href="/get.pl?file=$licence_copyright[$count]"><image name="imageField2" src="images/operation_open_file.png" align="middle" width="38" height="38" /></td>
              </tr>
            <tr>
              <td align="left" height="50" valign="middle" nowrap="nowrap" class="custom_list_type_bottomright">&nbsp&nbsp&nbsp&nbspInstallation Path:</td>
              <td width="5%" height="50" align="left" valign="middle" class="custom_list_type_bottom">$installation_path[$count]
                <image name="imageField3" id=$installation_path[$count] src="images/operation_copy_url.png" width="38" height="38" onclick="javascript:copyUrl(id);" style="cursor:pointer"/></td>
              </tr>
            <tr>
              </table>
		</td>
            </tr>
DATA
		$count++;
	}

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
		print <<DATA;
		<option>Any Version</option>
DATA
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
			print <<DATA;
			<option>$category_item[$count]</option>
DATA
		}
	}
	else {
		for ( ; $count < @category_item ; $count++ ) {
			if ( $advanced_value_category =~ /\b$category_item[$count]\b/ ) {
				print <<DATA;
				<option selected="selected">$category_item[$count]</option>
DATA
			}
			else {
				print <<DATA;
				<option>$category_item[$count]</option>
DATA
			}
		}
		print <<DATA;
		<option>Any Category</option>
DATA
	}
}

sub DrawCategorySelect {
	my $count = 0;
	print <<DATA;
		<option selected="selected">Any Category</option>
DATA
	for ( ; $count < @category_item ; $count++ ) {
		print <<DATA;
		<option>$category_item[$count]</option>
DATA
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
		print <<DATA;
		<option>Any Test Suite</option>
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
		print <<DATA;
		<option>Any Test Set</option>
DATA
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
		print <<DATA;
		<option>Any Status</option>
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
		print <<DATA;
		<option>Any Type</option>
DATA
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
		print <<DATA;
		<option>Any Priority</option>
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
		print <<DATA;
		<option>Any Component</option>
DATA
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
		print <<DATA;
		<option>Any Execution Type</option>
DATA
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

sub GetPackageName {
	if ( $_ =~ /^tests\.xml$/ ) {
		my $relative = $File::Find::dir;
		$relative =~ s/$testSuitesPath//g;
		my @temp_package_name = split( "\/", $relative );
		push( @package_name, @temp_package_name );
	}
}

sub FilterItem {
	my $count_temp_package  = 0;
	my $count_temp_property = 0;
	my $count_start         = 0;
	my $count_end           = 0;

	if ( $advanced_value_version =~ /Any Version/ ) {
		for (
			$count_temp_property = 0 ;
			$count_temp_property < $count_package_number_post ;
			$count_temp_property++
		  )
		{
			$version_save_flag[$count_temp_property] = "a";
		}
	}
	else {
		for (
			$count_temp_property = 0 ;
			$count_temp_property < $count_package_number_post ;
			$count_temp_property++
		  )
		{
			if ( $advanced_value_version =~
				/\b$version[$count_temp_property]\b/ )
			{
				$version_save_flag[$count_temp_property] = "a";
			}
			else {
				$version_save_flag[$count_temp_property] = "b";
			}
		}
	}

	if ( $advanced_value_category =~ /Any Category/ ) {
		for (
			$count_temp_property = 0 ;
			$count_temp_property < $count_package_number_post ;
			$count_temp_property++
		  )
		{
			$category_save_flag[$count_temp_property] = "a";
		}
	}
	else {
		for (
			$count_temp_property = 0 ;
			$count_temp_property < $count_package_number_post ;
			$count_temp_property++
		  )
		{
			if ( $category_num[$count_temp_property] == 0 ) {
				$category_save_flag[$count_temp_property] = "b";
				next;
			}
			if ( $count_temp_property == 0 ) {
				$count_start = 0;
				$count_end   = $category_num[$count_temp_property];
			}
			else {
				$count_start += $category_num[ $count_temp_property - 1 ];
				$count_end   += $category_num[$count_temp_property];
			}

			if ( $count_start == $count_end ) {
				$category_save_flag[$count_temp_property] = "b";
			}
			else {
				for (
					$count_temp_package = $count_start ;
					$count_temp_package < $count_end ;
					$count_temp_package++
				  )
				{
					if ( $advanced_value_category ne
						$category[$count_temp_package] )
					{
						if ( $count_temp_package == ( $count_end - 1 ) ) {
							$category_save_flag[$count_temp_property] = "b";
						}
					}
					if ( $advanced_value_category =~
						/\b$category[$count_temp_package]\b/ )
					{
						$category_save_flag[$count_temp_property] = "a";
						last;
					}
				}
			}
		}
	}

	if ( $advanced_value_priority =~ /Any Priority/ ) {
		for (
			$count_temp_property = 0 ;
			$count_temp_property < $count_package_number_post ;
			$count_temp_property++
		  )
		{
			$priority_save_flag[$count_temp_property] = "a";
		}
	}
	else {
		for (
			$count_temp_property = 0 ;
			$count_temp_property < $count_package_number_post ;
			$count_temp_property++
		  )
		{
			if ( $priority_num[$count_temp_property] == 0 ) {
				$priority_save_flag[$count_temp_property] = "b";
				next;
			}
			if ( $count_temp_property == 0 ) {
				$count_start = 0;
				$count_end   = $priority_num[$count_temp_property];
			}
			else {
				$count_start += $priority_num[ $count_temp_property - 1 ];
				$count_end   += $priority_num[$count_temp_property];
			}

			if ( $count_start == $count_end ) {
				$priority_save_flag[$count_temp_property] = "b";
			}
			else {
				for (
					$count_temp_package = $count_start ;
					$count_temp_package < $count_end ;
					$count_temp_package++
				  )
				{
					if ( $advanced_value_priority ne
						$priority[$count_temp_package] )
					{
						if ( $count_temp_package == ( $count_end - 1 ) ) {
							$priority_save_flag[$count_temp_property] = "b";
						}
					}
					if ( $advanced_value_priority =~
						/\b$priority[$count_temp_package]\b/ )
					{
						$priority_save_flag[$count_temp_property] = "a";
						last;
					}
				}
			}
		}
	}

	if ( $advanced_value_status =~ /Any Status/ ) {
		for (
			$count_temp_property = 0 ;
			$count_temp_property < $count_package_number_post ;
			$count_temp_property++
		  )
		{
			$status_save_flag[$count_temp_property] = "a";
		}
	}
	else {
		for (
			$count_temp_property = 0 ;
			$count_temp_property < $count_package_number_post ;
			$count_temp_property++
		  )
		{
			if ( $status_num[$count_temp_property] == 0 ) {
				$status_save_flag[$count_temp_property] = "b";
				next;
			}
			if ( $count_temp_property == 0 ) {
				$count_start = 0;
				$count_end   = $status_num[$count_temp_property];
			}
			else {
				$count_start += $status_num[ $count_temp_property - 1 ];
				$count_end   += $status_num[$count_temp_property];
			}

			if ( $count_start == $count_end ) {
				$status_save_flag[$count_temp_property] = "b";
			}
			else {
				for (
					$count_temp_package = $count_start ;
					$count_temp_package < $count_end ;
					$count_temp_package++
				  )
				{
					if (
						$advanced_value_status ne $status[$count_temp_package] )
					{
						if ( $count_temp_package == ( $count_end - 1 ) ) {
							$status_save_flag[$count_temp_property] = "b";
						}
					}
					if ( $advanced_value_status =~
						/\b$status[$count_temp_package]\b/ )
					{
						$status_save_flag[$count_temp_property] = "a";
						last;
					}
				}
			}
		}
	}

	if ( $advanced_value_execution_type =~ /Any Execution Type/ ) {
		for (
			$count_temp_property = 0 ;
			$count_temp_property < $count_package_number_post ;
			$count_temp_property++
		  )
		{
			$execution_type_save_flag[$count_temp_property] = "a";
		}
	}
	else {
		for (
			$count_temp_property = 0 ;
			$count_temp_property < $count_package_number_post ;
			$count_temp_property++
		  )
		{
			if ( $execution_type_num[$count_temp_property] == 0 ) {
				$execution_type_save_flag[$count_temp_property] = "b";
				next;
			}
			if ( $count_temp_property == 0 ) {
				$count_start = 0;
				$count_end   = $execution_type_num[$count_temp_property];
			}
			else {
				$count_start += $execution_type_num[ $count_temp_property - 1 ];
				$count_end   += $execution_type_num[$count_temp_property];
			}

			if ( $count_start == $count_end ) {
				$execution_type_save_flag[$count_temp_property] = "b";
			}
			else {
				for (
					$count_temp_package = $count_start ;
					$count_temp_package < $count_end ;
					$count_temp_package++
				  )
				{
					if ( $advanced_value_execution_type ne
						$execution_type[$count_temp_package] )
					{
						if ( $count_temp_package == ( $count_end - 1 ) ) {
							$execution_type_save_flag[$count_temp_property] =
							  "b";
						}
					}
					if ( $advanced_value_execution_type =~
						/\b$execution_type[$count_temp_package]\b/ )
					{
						$execution_type_save_flag[$count_temp_property] = "a";
						last;
					}
				}
			}
		}
	}

	if ( $advanced_value_test_suite =~ /Any Test Suite/ ) {
		for (
			$count_temp_property = 0 ;
			$count_temp_property < $count_package_number_post ;
			$count_temp_property++
		  )
		{
			$test_suite_save_flag[$count_temp_property] = "a";
		}
	}
	else {
		for (
			$count_temp_property = 0 ;
			$count_temp_property < $count_package_number_post ;
			$count_temp_property++
		  )
		{
			if ( $test_suite_num[$count_temp_property] == 0 ) {
				$test_suite_save_flag[$count_temp_property] = "b";
				next;
			}
			if ( $count_temp_property == 0 ) {
				$count_start = 0;
				$count_end   = $test_suite_num[$count_temp_property];
			}
			else {
				$count_start += $test_suite_num[ $count_temp_property - 1 ];
				$count_end   += $test_suite_num[$count_temp_property];
			}

			if ( $count_start == $count_end ) {
				$test_suite_save_flag[$count_temp_property] = "b";
			}
			else {
				for (
					$count_temp_package = $count_start ;
					$count_temp_package < $count_end ;
					$count_temp_package++
				  )
				{
					if ( $advanced_value_test_suite ne
						$test_suite[$count_temp_package] )
					{
						if ( $count_temp_package == ( $count_end - 1 ) ) {
							$test_suite_save_flag[$count_temp_property] = "b";
						}
					}
					if ( $advanced_value_test_suite =~
						/\b$test_suite[$count_temp_package]\b/ )
					{
						$test_suite_save_flag[$count_temp_property] = "a";
						last;
					}
				}
			}
		}
	}

	if ( $advanced_value_type =~ /\bAny\sType\b/ ) {
		for (
			$count_temp_property = 0 ;
			$count_temp_property < $count_package_number_post ;
			$count_temp_property++
		  )
		{
			$type_save_flag[$count_temp_property] = "a";
		}
	}
	else {
		for (
			$count_temp_property = 0 ;
			$count_temp_property < $count_package_number_post ;
			$count_temp_property++
		  )
		{
			if ( $type_num[$count_temp_property] == 0 ) {
				$type_save_flag[$count_temp_property] = "b";
				next;
			}
			if ( $count_temp_property == 0 ) {
				$count_start = 0;
				$count_end   = $type_num[$count_temp_property];
			}
			else {
				$count_start += $type_num[ $count_temp_property - 1 ];
				$count_end   += $type_num[$count_temp_property];
			}

			if ( $count_start == $count_end ) {
				$type_save_flag[$count_temp_property] = "b";
			}
			else {
				for (
					$count_temp_package = $count_start ;
					$count_temp_package < $count_end ;
					$count_temp_package++
				  )
				{
					if ( $advanced_value_type ne $type[$count_temp_package] ) {
						if ( $count_temp_package == ( $count_end - 1 ) ) {
							$type_save_flag[$count_temp_property] = "b";
						}
					}
					if ( $advanced_value_type =~
						/\b$type[$count_temp_package]\b/ )
					{
						$type_save_flag[$count_temp_property] = "a";
						last;
					}
				}
			}
		}
	}

	if ( $advanced_value_test_set =~ /Any Test Set/ ) {
		for (
			$count_temp_property = 0 ;
			$count_temp_property < $count_package_number_post ;
			$count_temp_property++
		  )
		{
			$test_set_save_flag[$count_temp_property] = "a";
		}
	}
	else {
		for (
			$count_temp_property = 0 ;
			$count_temp_property < $count_package_number_post ;
			$count_temp_property++
		  )
		{
			if ( $test_set_num[$count_temp_property] == 0 ) {
				$test_set_save_flag[$count_temp_property] = "b";
				next;
			}
			if ( $count_temp_property == 0 ) {
				$count_start = 0;
				$count_end   = $test_set_num[$count_temp_property];
			}
			else {
				$count_start += $test_set_num[ $count_temp_property - 1 ];
				$count_end   += $test_set_num[$count_temp_property];
			}

			if ( $count_start == $count_end ) {
				$test_set_save_flag[$count_temp_property] = "b";
			}
			else {
				for (
					$count_temp_package = $count_start ;
					$count_temp_package < $count_end ;
					$count_temp_package++
				  )
				{
					if ( $advanced_value_test_set ne
						$test_set[$count_temp_package] )
					{
						if ( $count_temp_package == ( $count_end - 1 ) ) {
							$test_set_save_flag[$count_temp_property] = "b";
						}
					}
					if ( $advanced_value_test_set =~
						/\b$test_set[$count_temp_package]\b/ )
					{
						$test_set_save_flag[$count_temp_property] = "a";
						last;
					}
				}
			}
		}
	}

	if ( $advanced_value_component =~ /Any Component/ ) {
		for (
			$count_temp_property = 0 ;
			$count_temp_property < $count_package_number_post ;
			$count_temp_property++
		  )
		{
			$component_save_flag[$count_temp_property] = "a";
		}
	}
	else {
		for (
			$count_temp_property = 0 ;
			$count_temp_property < $count_package_number_post ;
			$count_temp_property++
		  )
		{
			if ( $component_num[$count_temp_property] == 0 ) {
				$component_save_flag[$count_temp_property] = "b";
				next;
			}
			if ( $count_temp_property == 0 ) {
				$count_start = 0;
				$count_end   = $component_num[$count_temp_property];
			}
			else {
				$count_start += $component_num[ $count_temp_property - 1 ];
				$count_end   += $component_num[$count_temp_property];
			}

			if ( $count_start == $count_end ) {
				$component_save_flag[$count_temp_property] = "b";
			}
			else {
				for (
					$count_temp_package = $count_start ;
					$count_temp_package < $count_end ;
					$count_temp_package++
				  )
				{
					if ( $advanced_value_component ne
						$component[$count_temp_package] )
					{
						if ( $count_temp_package == ( $count_end - 1 ) ) {
							$component_save_flag[$count_temp_property] = "b";
						}
					}
					if ( $advanced_value_component =~
						/\b$component[$count_temp_package]\b/ )
					{
						$component_save_flag[$count_temp_property] = "a";
						last;
					}
				}
			}
		}
	}

	for (
		$count_temp_property = 0 ;
		$count_temp_property < $count_package_number_post ;
		$count_temp_property++
	  )
	{
		if (   ( $version_save_flag[$count_temp_property] eq "a" )
			&& ( $category_save_flag[$count_temp_property]       eq "a" )
			&& ( $priority_save_flag[$count_temp_property]       eq "a" )
			&& ( $status_save_flag[$count_temp_property]         eq "a" )
			&& ( $execution_type_save_flag[$count_temp_property] eq "a" )
			&& ( $test_suite_save_flag[$count_temp_property]     eq "a" )
			&& ( $type_save_flag[$count_temp_property]           eq "a" )
			&& ( $test_set_save_flag[$count_temp_property]       eq "a" )
			&& ( $component_save_flag[$count_temp_property]      eq "a" ) )
		{
			$package_name_flag[$count_temp_property] = "a";
		}
		else {
			$package_name_flag[$count_temp_property] = "b";
		}
	}
}

print_footer("");

