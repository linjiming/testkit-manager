# Testkit
# General Templates and Functions Module (Templates.pm)
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
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

use FindBin;

sub BEGIN {
	unshift @INC, $FindBin::Bin . '/../../utils';
}

package Templates;
use strict;
use Exporter;
use Common;
use Data::Dumper;

$Common::debug_inform_sub = sub { };

@Templates::ISA    = 'Exporter';
@Templates::EXPORT = (
	qw(
	  CRLF
	  %SERVER_PARAM %_GET %_POST %_COOKIE %CONFIG
	  $result_dir_manager $test_definition_dir
	  $cert_sys_host $cert_sys_base
	  &print_header &print_footer
	  &autoflush_on &escape &unescape &show_error_dlg &show_not_implemented &show_message_dlg
	  &updatePackageList &updateCaseInfo &printDetailedCaseInfo &updateManualCaseResult &printManualCaseInfo &printDetailedCaseInfoWithComment
	  ),
	@Common::EXPORT,
	@Manifest::EXPORT
);

my ( $global_header, $global_footer );

use constant CRLF => "\x0d\x0a";

our %SERVER_PARAM = ();
$SERVER_PARAM{'HOST'}            = ( $ENV{'DTKM_HOST'}            or '' );
$SERVER_PARAM{'PEER_IP'}         = ( $ENV{'DTKM_PEER_IP'}         or '' );
$SERVER_PARAM{'PORT'}            = ( $ENV{'DTKM_PORT'}            or '' );
$SERVER_PARAM{'SERVER_PID'}      = ( $ENV{'DTKM_SERVER_PID'}      or '' );
$SERVER_PARAM{'DOCUMENT_ROOT'}   = ( $ENV{'DTKM_DOCUMENT_ROOT'}   or '' );
$SERVER_PARAM{'APP_DATA'}        = ( $ENV{'DTKM_APP_DATA'}        or '' );
$SERVER_PARAM{'PROXY'}           = ( $ENV{'DTKM_PROXY'}           or '' );
$SERVER_PARAM{'PROXY_AUTH'}      = ( $ENV{'DTKM_PROXY_AUTH'}      or 'basic' );
$SERVER_PARAM{'HTTP_PROXY'}      = ( $ENV{'DTKM_HTTP_PROXY'}      or '' );
$SERVER_PARAM{'HTTP_PROXY_AUTH'} = ( $ENV{'DTKM_HTTP_PROXY_AUTH'} or 'basic' );
$SERVER_PARAM{'FTP_PROXY'}       = ( $ENV{'DTKM_FTP_PROXY'}       or '' );
$SERVER_PARAM{'FTP_PROXY_AUTH'}  = ( $ENV{'DTKM_FTP_PROXY_AUTH'}  or 'basic' );
$SERVER_PARAM{'CONF_FILE'}       = ( $ENV{'DTKM_CONF_FILE'}       or '' );

if ( open( FILE, $SERVER_PARAM{'DOCUMENT_ROOT'} . '/header.tpl' ) ) {
	$global_header = '';
	while (<FILE>) {
		$global_header .= $_;
	}
	close(FILE);
}
if ( open( FILE, $SERVER_PARAM{'DOCUMENT_ROOT'} . '/footer.tpl' ) ) {
	$global_footer = '';
	while (<FILE>) {
		$global_footer .= $_;
	}
	close(FILE);
}
if ( !$global_header or !$global_footer ) {
	$global_header = "<html><body>\n";
	$global_footer = '</body></html>';
}

sub escape($) {
	my ($str) = @_;
	$str =~ s/([^0-9a-zA-Z_\- ])/sprintf('%%%02X', ord($1))/eg;
	$str =~ s/ /\+/g;
	return $str;
}

sub unescape($) {
	my ($str) = @_;
	$str =~ s/\+/ /g;
	$str =~ s/%([0-9a-fA-F]{2})/chr(hex($1))/eg;
	return $str;
}

my @args;

our %_GET = ();
@args = split( /&/, $ENV{'DTKM_GET_ARGS'} );
foreach (@args) {
	my ( $name, $val ) = split( /=/, $_, 2 );
	if ($name) {
		$name = unescape($name);
		if ( defined($val) ) {
			$val = unescape($val);
		}
		else {
			$val = '1';
		}
		$_GET{$name} = $val;
	}
}

our %_POST = ();
@args = split( /&/, $ENV{'DTKM_POST_ARGS'} );
foreach (@args) {
	my ( $name, $val ) = split( /=/, $_, 2 );
	if ($name) {
		$name = unescape($name);
		if ( defined($val) ) {
			$val = unescape($val);
		}
		else {
			$val = '1';
		}
		$_POST{$name} = $val;
	}
}

our %_COOKIE = ();
my @cookies_list = split( /;\s*/, $ENV{'DTKM_COOKIES'} );
foreach (@cookies_list) {
	my ( $name, $val ) = split( /=/, $_, 2 );
	if ( $name and defined($val) ) {
		$name           = unescape($name);
		$val            = unescape($val);
		$_COOKIE{$name} = $val;
	}
}

# Get "<DOCUMENT_ROOT>/../.." path
my $tmp = $SERVER_PARAM{'DOCUMENT_ROOT'};
$tmp =~ s!/[^/]+/[^/]+$!!;
our %CONFIG = (
	'TESTS_DIR'   => "$tmp/utils",
	'RESULTS_DIR' => $SERVER_PARAM{'APP_DATA'} . '/results'
);

my %styles = (
	'custom'    => '$$$CUSTOM_STYLE$$$',
	'execute'   => '$$$EXECUTE_STYLE$$$',
	'report'    => '$$$REPORT_STYLE$$$',
	'statistic' => '$$$STATISTIC_STYLE$$$',
	'help'      => '$$$HELP_STYLE$$$',
	'about'     => '$$$ABOUT_STYLE$$$'
);

sub print_header($$) {
	my ( $title, $id ) = @_;
	my $header = $global_header;

	# Replace static patterns
	$header =~ s/\$\$\$PAGE_TITLE\$\$\$/$title/g;
	$header =~ s/\$\$\$MTK_BRANCH\$\$\$/$MTK_BRANCH/g;
	$header =~ s/\$\$\$MTK_BRANCH_LC\$\$\$/lc($MTK_BRANCH)/eg;

	# Find and highlight the active menu link
	foreach my $name ( keys %styles ) {
		if ( $id eq $name ) {
			$header =~ s/\Q$styles{$name}\E/-active/;
			last;
		}
	}

	# Set all other menu links to non-highlighted style
	foreach ( values %styles ) {
		$header =~ s/\Q$_\E//;
	}

	# Show navigation bar if it's not in the home page
	my $navigation_bar_show = ( ( $id eq '' ) ? 'display: none;' : '' );
	$header =~ s/\$\$\$NAVIGATION_BAR_SHOW\$\$\$/$navigation_bar_show/g;

	# Get user name
	my $username = `w | sed -n '3,3p' | cut -d ' ' -f 1`;
	$header =~ s/\$\$\$USER_NAME\$\$\$/$username/g;

	print $header;
}

sub print_footer {
	my ($title) = @_;
	if ( $_[0] ) {
		$global_footer =~ s/<\/body>//;
		$global_footer =~ s/<\/html>//;
	}

	# Set backgroud for homepage, leave empty for other pages
	if ( $title eq "footer_home" ) {
		$global_footer =~ s/\$\$\$LEGAl_STYLE\$\$\$/-home/;
	}
	else {
		$global_footer =~ s/\$\$\$LEGAl_STYLE\$\$\$/-other/;
	}
	print $global_footer;
}

# Remove old session profiles
my $tm = time();
if ( opendir( DIR, $SERVER_PARAM{'APP_DATA'} . '/profiles' ) ) {
	my @files = grep /^~session\./, readdir(DIR);
	foreach (@files) {
		my $name = $SERVER_PARAM{'APP_DATA'} . "/profiles/$_";

		# Session expiration time is 7 days
		if ( $tm - ( stat($name) )[8] > 7 * 86400 ) {
			unlink($name);
		}
	}
	closedir(DIR);
}

sub autoflush_on() {
	my $old_handle = select(STDOUT);
	$| = 1;
	select(STDERR);
	$| = 1;
	select($old_handle);
}

sub show_error_dlg($) {
	my ($error_text) = @_;
	my $error_show = ( ( $error_text eq '' ) ? ' display: none;' : '' );
	return <<DATA;
<noscript><h1 align="center"><font color="red" size="+1">WARNING! Your browser does not support JavaScript.</font></h1></noscript>
<input type="hidden" name="js-browser-test-name" id="js-browser-test-id" />
<script language="javascript" type="text/javascript">
// <![CDATA[
var elem = document.getElementById('js-browser-test-id');
if (!elem) {
	if (document.getElementById('js-browser-test-name')) {
		alert('Sorry, your browser seems to work incorrectly!\\nIt uses NAME attribute instead of ID.');
	}
}
// ]]>
</script>
<div id="error_msg_area" style="border: none;$error_show">
<table border="0" cellpadding="1" cellspacing="1" width="80%" align="center">
  <tr>
    <th style="border: dashed 1px darkred; background: red; color: white; font-family: Calibri; font-size: 22px;">
      <table border="0" cellpadding="0" cellspacing="0" align="center">
        <tr>
          <td width="100%">Attention</td>
          <td><img src="images/close.png" alt="Close" width="20" height="20" style="cursor: pointer;" title="Close" onclick="javascript:document.getElementById('error_msg_area').style.display='none';" /></td>
        </tr>
      </table>
    </th>
  </tr>
  <tr><td align="center" style="border: dashed 1px darkred; border-top: none;">
    <table border="0" cellpadding="0" cellspacing="0">
      <tr><td height="10" colspan="3"></td></tr>
      <tr><td width="10%"></td><td align="left" id="error_msg_text" font-family: Calibri; style="font-size: 20px;">$error_text</td><td width="10%"></td></tr>
      <tr><td height="10" colspan="3"></td></tr>
    </table>
  </td></tr>
</table>
<br />
</div>
DATA
}

sub show_message_dlg($) {
	my ($message_text) = @_;
	my $message_show = ( ( $message_text eq '' ) ? ' display: none;' : '' );
	return <<DATA;
<noscript><h1 align="center"><font color="red" size="+1">WARNING! Your browser does not support JavaScript.</font></h1></noscript>
<input type="hidden" name="js-browser-test-name" id="js-browser-test-id" />
<script language="javascript" type="text/javascript">
// <![CDATA[
var elem = document.getElementById('js-browser-test-id');
if (!elem) {
	if (document.getElementById('js-browser-test-name')) {
		alert('Sorry, your browser seems to work incorrectly!\\nIt uses NAME attribute instead of ID.');
	}
}
// ]]>
</script>
<div id="error_msg_area" style="border: none;$message_show">
<table border="0" cellpadding="1" cellspacing="1" width="80%" align="center">
  <tr>
    <th style="border: dashed 1px darkred; background: green; color: white; font-family: Calibri; font-size: 22px;">
      <table border="0" cellpadding="0" cellspacing="0" align="center">
        <tr>
          <td width="100%">Message</td>
          <td><img src="images/close.png" alt="Close" width="20" height="20" style="cursor: pointer;" title="Close" onclick="javascript:document.getElementById('error_msg_area').style.display='none';" /></td>
        </tr>
      </table>
    </th>
  </tr>
  <tr><td align="center" style="border: dashed 1px darkred; border-top: none;">
    <table border="0" cellpadding="0" cellspacing="0">
      <tr><td height="10" colspan="3"></td></tr>
      <tr><td width="10%"></td><td align="left" id="error_msg_text" font-family: Calibri; style="font-size: 20px;">$message_text</td><td width="10%"></td></tr>
      <tr><td height="10" colspan="3"></td></tr>
    </table>
  </td></tr>
</table>
<br />
</div>
DATA
}

sub show_not_implemented {
	my ($function) = @_;
	return <<DATA;
<table width="1280" height="200" border="0" cellpadding="0" cellspacing="0" class="not_implemented">
    <tr>
      <td align="center" valign="middle">Sorry, function "$function" has not been implemented.</td>
    </tr>
</table>
DATA
}

our $result_dir_manager  = $FindBin::Bin . "/../../../results/";
our $test_definition_dir = "/usr/share/";

sub updatePackageList {
	my @package_list = ();
	my ($time)       = @_;
	my $package      = "";
	open FILE, $result_dir_manager . $time . "/info" or die $!;

	while (<FILE>) {
		if ( $_ =~ /Package:(.*)/ ) {
			$package = $1;
			push( @package_list, $1 );
		}
	}
	return @package_list;
}

sub updateCaseInfo {
	my ($xml) = @_;
	my %caseInfo;
	my $description                 = "none";
	my $result                      = "none";
	my $priority                    = "none";
	my $component                   = "none";
	my $requirement                 = "none";
	my $status                      = "none";
	my $test_type                   = "none";
	my $pre_conditions              = "none";
	my $post_conditions             = "none";
	my $note                        = "none";
	my $test_script_entry           = "none";
	my $test_script_expected_result = "none";
	my $spec                        = "none";
	my $spec_url                    = "none";
	my $spec_statement              = "none";
	my $actual_result               = "none";
	my $start                       = "none";
	my $end                         = "none";
	my $stdout                      = "none";
	my $stderr                      = "none";
	my $measurement_name            = "none";
	my $measurement_value           = "none";
	my $measurement_unit            = "none";
	my $measurement_target          = "none";
	my $measurement_failure         = "none";
	my $categories                  = "";

	if ( $xml =~ /purpose="(.*?)"/ ) {
		$description = $1;
	}
	if ( $xml =~ /result="(.*?)"/ ) {
		$result = $1;
	}
	if ( $xml =~ /priority="(.*?)"/ ) {
		$priority = $1;
	}
	if ( $xml =~ /component="(.*?)"/ ) {
		$component = $1;
	}
	if ( $xml =~ /requirement_ref="(.*?)"/ ) {
		$requirement = $1;
	}
	if ( $xml =~ /status="(.*?)"/ ) {
		$status = $1;
	}
	if ( $xml =~ / type="(.*?)"/ ) {
		$test_type = $1;
	}
	if ( $xml =~ /<pre_condition>(.*?)<\/pre_condition>/ ) {
		$pre_conditions = $1;
	}
	if ( $xml =~ /<post_condition>(.*?)<\/post_condition>/ ) {
		$post_conditions = $1;
	}
	if ( $xml =~ /<notes>(.*?)<\/notes>/ ) {
		$note = $1;
	}
	if ( $xml =~ /<test_script_entry.*>(.*?)<\/test_script_entry>/ ) {
		$test_script_entry = $1;
	}
	if ( $xml =~ /test_script_expected_result="(.*?)"/ ) {
		$test_script_expected_result = $1;
	}
	if ( $xml =~ /<actual_result>(.*?)<\/actual_result>/ ) {
		$actual_result = $1;
	}
	if ( $xml =~ /<start>(.*?)<\/start>/ ) {
		$start = $1;
	}
	if ( $xml =~ /<end>(.*?)<\/end>/ ) {
		$end = $1;
	}
	if ( $xml =~ /<stdout>(.*?)<\/stdout>/ ) {
		$stdout = $1;
	}
	if ( $xml =~ /<stderr>(.*?)<\/stderr>/ ) {
		$stderr = $1;
	}
	if ( $xml =~ /measurement.*name="(.*?)"/ ) {
		$measurement_name = $1;
	}
	if ( $xml =~ /measurement.*value="(.*?)"/ ) {
		$measurement_value = $1;
	}
	if ( $xml =~ /measurement.*unit="(.*?)"/ ) {
		$measurement_unit = $1;
	}
	if ( $xml =~ /measurement.*target="(.*?)"/ ) {
		$measurement_target = $1;
	}
	if ( $xml =~ /measurement.*failure="(.*?)"/ ) {
		$measurement_failure = $1;
	}
	if ( $xml =~ /<category>(.*?)<\/category>/ ) {
		my @temp = $xml =~ /<category>(.*?)<\/category>/g;
		foreach (@temp) {
			$categories .= "[" . $_ . "] ";
		}
	}
	if ( $xml =~ /<spec>\[Spec\] *(.*) *\[Spec URL\]/ ) {
		$spec = $1;
		$spec =~ s/^[\s]+//;
		$spec =~ s/[\s]+$//;
		$spec =~ s/[\s]+/ /g;
		$spec =~ s/&lt;/[/g;
		$spec =~ s/&gt;/]/g;
		$spec =~ s/</[/g;
		$spec =~ s/>/]/g;
	}
	if ( $xml =~ /\[Spec URL\] *(.*) *\[Spec Statement\]/ ) {
		$spec_url = $1;
	}
	if ( $xml =~ /\[Spec Statement\] *(.*) *<\/spec>/ ) {
		$spec_statement = $1;
	}

	# change $categories to none if not found
	if ( $categories eq "" ) {
		$categories = "none";
	}
	$caseInfo{"description"}                 = $description;
	$caseInfo{"result"}                      = $result;
	$caseInfo{"priority"}                    = $priority;
	$caseInfo{"component"}                   = $component;
	$caseInfo{"requirement"}                 = $requirement;
	$caseInfo{"status"}                      = $status;
	$caseInfo{"test_type"}                   = $test_type;
	$caseInfo{"pre_conditions"}              = $pre_conditions;
	$caseInfo{"post_conditions"}             = $post_conditions;
	$caseInfo{"note"}                        = $note;
	$caseInfo{"test_script_entry"}           = $test_script_entry;
	$caseInfo{"test_script_expected_result"} = $test_script_expected_result;
	$caseInfo{"spec"}                        = $spec;
	$caseInfo{"spec_url"}                    = $spec_url;
	$caseInfo{"spec_statement"}              = $spec_statement;
	$caseInfo{"actual_result"}               = $actual_result;
	$caseInfo{"start"}                       = $start;
	$caseInfo{"end"}                         = $end;
	$caseInfo{"stdout"}                      = $stdout;
	$caseInfo{"stderr"}                      = $stderr;
	$caseInfo{"measurement_name"}            = $measurement_name;
	$caseInfo{"measurement_value"}           = $measurement_value;
	$caseInfo{"measurement_unit"}            = $measurement_unit;
	$caseInfo{"measurement_target"}          = $measurement_target;
	$caseInfo{"measurement_failure"}         = $measurement_failure;
	$caseInfo{"categories"}                  = $categories;

	my $steps = "none";

	my @step_desc = ();
	my @expected  = ();

	# handle steps
	if ( $xml =~ /<step_desc>(.*?)<\/step_desc>/ ) {
		@step_desc = $xml =~ /<step_desc>(.*?)<\/step_desc>/g;
	}
	if ( $xml =~ /<expected>(.*?)<\/expected>/ ) {
		@expected = $xml =~ /<expected>(.*?)<\/expected>/g;
	}
	my @temp_steps = ();
	for ( my $i = 0 ; $i < @step_desc ; $i++ ) {
		push( @temp_steps, $step_desc[$i] . ":" . $expected[$i] );
	}
	if ( @temp_steps >= 1 ) {
		$steps = join( "__", @temp_steps );
	}
	else {
		$steps = "none:none";
	}

	$caseInfo{"steps"} = $steps;
	return %caseInfo;
}

sub printManualCaseInfo {
	my ( $time, $id_textarea, $id_bugnumber, %caseInfo ) = @_;
	my $steps             = $caseInfo{"steps"};
	my @name_all          = split( "__", $id_textarea );
	my @package_name_temp = split( ":", $name_all[1] );
	my @case_name_temp    = split( ":", $name_all[2] );
	my $package_name      = $package_name_temp[1];
	my $case_name         = $case_name_temp[1];

	my $comment   = "none";
	my $bugnumber = "none";
	if (  -e $result_dir_manager 
		. $time . "/"
		. $package_name
		. "_manual_case_tests_comment_bug_number.txt" )
	{
		open FILE,
		    $result_dir_manager 
		  . $time . "/"
		  . $package_name
		  . "_manual_case_tests_comment_bug_number.txt"
		  or die $!;
		while (<FILE>) {
			if ( index( $_, "__" . $case_name . "__" ) > 0 ) {
				my @comment_bug_temp = split( "__", $_ );
				$bugnumber = pop(@comment_bug_temp);
				$comment   = pop(@comment_bug_temp);
			}
		}
	}

	print <<DATA;
<table width="100%" border="0" cellspacing="0" cellpadding="0" style="font-size:18px;table-layout:fixed" frame="hsides" rules="all">
DATA
	my @temp_steps = split( "__", $steps );
	foreach (@temp_steps) {
		my @temp             = split( ":", $_ );
		my $step_description = shift @temp;
		my $expected_result  = shift @temp;
		print <<DATA;
  <tr>
    <td width="19%" class="report_list_inside">&nbsp;Step Description:</td>
    <td width="81%" class="report_list_inside">&nbsp;$step_description</td>
  </tr>
  <tr>
    <td width="19%" class="report_list_inside">&nbsp;Expected Result:</td>
    <td width="81%" class="report_list_inside">&nbsp;$expected_result</td>
  </tr>
DATA
	}
	print <<DATA;
  <tr>
    <td width="19%" class="report_list_inside">&nbsp;Comment:</td>
    <td width="81%" class="report_list_inside"><textarea id="$id_textarea" name="textarea" cols="67" rows="4">$comment</textarea></td>
  </tr>
  <tr>
    <td width="19%" class="report_list_inside">&nbsp;Bug Number:</td>
    <td width="81%" class="report_list_inside"><input type="text" id="$id_bugnumber" name="textfield" value="$bugnumber"></td>
  </tr>
</table>
DATA
}

sub printDetailedCaseInfo {
	my ( $name, $execution_type, %caseInfo ) = @_;
	my $description                 = $caseInfo{"description"};
	my $priority                    = $caseInfo{"priority"};
	my $component                   = $caseInfo{"component"};
	my $requirement                 = $caseInfo{"requirement"};
	my $status                      = $caseInfo{"status"};
	my $test_type                   = $caseInfo{"test_type"};
	my $pre_conditions              = $caseInfo{"pre_conditions"};
	my $post_conditions             = $caseInfo{"post_conditions"};
	my $note                        = $caseInfo{"note"};
	my $test_script_entry           = $caseInfo{"test_script_entry"};
	my $test_script_expected_result = $caseInfo{"test_script_expected_result"};
	my $actual_result               = $caseInfo{"actual_result"};
	my $start                       = $caseInfo{"start"};
	my $end                         = $caseInfo{"end"};
	my $stdout                      = $caseInfo{"stdout"};
	my $stderr                      = $caseInfo{"stderr"};
	my $measurement_name            = $caseInfo{"measurement_name"};
	my $measurement_value           = $caseInfo{"measurement_value"};
	my $measurement_unit            = $caseInfo{"measurement_unit"};
	my $measurement_target          = $caseInfo{"measurement_target"};
	my $measurement_failure         = $caseInfo{"measurement_failure"};
	my $categories                  = $caseInfo{"categories"};
	my $spec                        = $caseInfo{"spec"};
	my $spec_url                    = $caseInfo{"spec_url"};
	my $spec_statement              = $caseInfo{"spec_statement"};
	my $steps                       = $caseInfo{"steps"};
	print <<DATA;
                            <table width="100%" border="0" cellspacing="0" cellpadding="0" style="font-size:18px;table-layout:fixed" frame="hsides" rules="all">
                              <tr>
                                <td width="15%" class="report_list_outside_left">&nbsp;TC ID:</td>
                                <td colspan="3" class="report_list_outside_right">&nbsp;$name</td>
                              </tr>
                              <tr>
                                <td width="15%" class="report_list_outside_left">&nbsp;TC Purpose:</td>
                                <td colspan="3" class="report_list_outside_right">&nbsp;$description</td>
                              </tr>
                              <tr>
                                <td width="15%" class="report_list_outside_left">&nbsp;Priority:</td>
                                <td width="35%" class="report_list_inside">&nbsp;$priority</td>
                                <td width="15%" class="report_list_inside">&nbsp;Execution Type:</td>
                                <td width="35%" class="report_list_outside_right">&nbsp;$execution_type</td>
                              </tr>
                              <tr>
                                <td width="15%" class="report_list_outside_left">&nbsp;Component:</td>
                                <td width="35%" class="report_list_inside">&nbsp;$component</td>
                                <td width="15%" class="report_list_inside">&nbsp;Requirement:</td>
                                <td width="35%" class="report_list_outside_right">&nbsp;$requirement</td>
                              </tr>
                              <tr>
                                <td width="15%" class="report_list_outside_left">&nbsp;Case State:</td>
                                <td colspan="3" class="report_list_outside_right">&nbsp;$status</td>
                              </tr>
                              <tr>
                                <td width="15%" class="report_list_outside_left">&nbsp;Type:</td>
                                <td colspan="3" class="report_list_outside_right">&nbsp;$test_type</td>
                              </tr>
                              <tr>
                                <td width="15%" class="report_list_outside_left">&nbsp;Categories:</td>
                                <td colspan="3" class="report_list_outside_right">&nbsp;$categories</td>
                              </tr>
                              <tr>
                                <td width="15%" rowspan="6" class="report_list_outside_left">&nbsp;Description</td>
                                <td width="35%" class="report_list_inside">&nbsp;Pre-conditions:</td>
                                <td colspan="2" class="report_list_outside_right">&nbsp;$pre_conditions</td>
                              </tr>
                              <tr>
                                <td width="35%" class="report_list_inside">&nbsp;Post-conditions:</td>
                                <td colspan="2" class="report_list_outside_right">&nbsp;$post_conditions</td>
                              </tr>
                              <tr>
                                <td width="35%" class="report_list_inside">&nbsp;Steps</td>
                                <td colspan="2" class="report_list_outside_right"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="all">
DATA

	my @temp_steps = split( "__", $steps );
	foreach (@temp_steps) {
		my @temp             = split( ":", $_ );
		my $step_description = shift @temp;
		my $expected_result  = shift @temp;
		print <<DATA;
                                  <tr>
                                    <td width="30%" class="report_list_inside">&nbsp;Step Description:</td>
                                    <td width="70%" class="report_list_outside_right">&nbsp;$step_description</td>
                                  </tr>
                                  <tr>
                                    <td width="30%" class="report_list_inside">&nbsp;Expected Result:</td>
                                    <td width="70%" class="report_list_outside_right">&nbsp;$expected_result</td>
                                  </tr>
DATA
	}
	print <<DATA;
                                </table></td>
                              </tr>
                              <tr>
                                <td width="35%" class="report_list_inside">&nbsp;Notes:</td>
                                <td colspan="2" class="report_list_outside_right">&nbsp;$note</td>
                              </tr>
                              <tr>
                                <td width="35%" class="report_list_inside">&nbsp;Test Script Entry:</td>
                                <td colspan="2" class="report_list_outside_right">&nbsp;$test_script_entry</td>
                              </tr>
                              <tr>
                                <td width="35%" class="report_list_inside">&nbsp;Test Script Expected Result:</td>
                                <td colspan="2" class="report_list_outside_right">&nbsp;$test_script_expected_result</td>
                              </tr>
                              <tr>
                                <td width="15%" rowspan="5" class="report_list_outside_left">&nbsp;Result Info</td>
                                <td width="35%" class="report_list_inside">&nbsp;Actual result:</td>
                                <td colspan="2" class="report_list_outside_right">&nbsp;$actual_result</td>
                              </tr>
                              <tr>
                                <td width="35%" class="report_list_inside">&nbsp;Start:</td>
                                <td colspan="2" class="report_list_outside_right">&nbsp;$start</td>
                              </tr>
                              <tr>
                                <td width="35%" class="report_list_inside">&nbsp;End:</td>
                                <td colspan="2" class="report_list_outside_right">&nbsp;$end</td>
                              </tr>
                              <tr>
                                <td width="35%" class="report_list_inside">&nbsp;Stdout:</td>
                                <td colspan="2" class="report_list_outside_right">&nbsp;$stdout</td>
                              </tr>
                              <tr>
                                <td width="35%" class="report_list_inside">&nbsp;Stderr:</td>
                                <td colspan="2" class="report_list_outside_right">&nbsp;$stderr</td>
                              </tr>
                              <tr>
                                <td width="15%" rowspan="5" class="report_list_outside_left">&nbsp;Measurement</td>
                                <td width="35%" class="report_list_inside">&nbsp;Name:</td>
                                <td colspan="2" class="report_list_outside_right">&nbsp;$measurement_name</td>
                              </tr>
                              <tr>
                                <td width="35%" class="report_list_inside">&nbsp;Value:</td>
                                <td colspan="2" class="report_list_outside_right">&nbsp;$measurement_value</td>
                              </tr>
                              <tr>
                                <td width="35%" class="report_list_inside">&nbsp;Unit:</td>
                                <td colspan="2" class="report_list_outside_right">&nbsp;$measurement_unit</td>
                              </tr>
                              <tr>
                                <td width="35%" class="report_list_inside">&nbsp;Target:</td>
                                <td colspan="2" class="report_list_outside_right">&nbsp;$measurement_target</td>
                              </tr>
                              <tr>
                                <td width="35%" class="report_list_inside">&nbsp;Failure:</td>
                                <td colspan="2" class="report_list_outside_right">&nbsp;$measurement_failure</td>
                              </tr>
                              <tr>
                                <td width="15%" rowspan="3" class="report_list_outside_left">&nbsp;Spec</td>
                                <td width="35%" class="report_list_inside">&nbsp;Name:</td>
                                <td colspan="2" class="report_list_outside_right">&nbsp;$spec</td>
                              </tr>
                              <tr>
                                <td width="35%" class="report_list_inside">&nbsp;URL:</td>
                                <td colspan="2" class="report_list_outside_right">&nbsp;$spec_url</td>
                              </tr>
                              <tr>
                                <td width="35%" class="report_list_inside">&nbsp;Statement:</td>
                                <td colspan="2" class="report_list_outside_right">&nbsp;$spec_statement</td>
                              </tr>
                            </table>
DATA
}

sub printDetailedCaseInfoWithComment {
	my ( $name, $execution_type, $time, $id_textarea, $id_bugnumber, %caseInfo )
	  = @_;
	my $description                 = $caseInfo{"description"};
	my $priority                    = $caseInfo{"priority"};
	my $component                   = $caseInfo{"component"};
	my $requirement                 = $caseInfo{"requirement"};
	my $status                      = $caseInfo{"status"};
	my $test_type                   = $caseInfo{"test_type"};
	my $pre_conditions              = $caseInfo{"pre_conditions"};
	my $post_conditions             = $caseInfo{"post_conditions"};
	my $note                        = $caseInfo{"note"};
	my $test_script_entry           = $caseInfo{"test_script_entry"};
	my $test_script_expected_result = $caseInfo{"test_script_expected_result"};
	my $actual_result               = $caseInfo{"actual_result"};
	my $start                       = $caseInfo{"start"};
	my $end                         = $caseInfo{"end"};
	my $stdout                      = $caseInfo{"stdout"};
	my $stderr                      = $caseInfo{"stderr"};
	my $measurement_name            = $caseInfo{"measurement_name"};
	my $measurement_value           = $caseInfo{"measurement_value"};
	my $measurement_unit            = $caseInfo{"measurement_unit"};
	my $measurement_target          = $caseInfo{"measurement_target"};
	my $measurement_failure         = $caseInfo{"measurement_failure"};
	my $categories                  = $caseInfo{"categories"};
	my $spec                        = $caseInfo{"spec"};
	my $spec_url                    = $caseInfo{"spec_url"};
	my $spec_statement              = $caseInfo{"spec_statement"};
	my $steps                       = $caseInfo{"steps"};

	# handle comment and bug number
	my @name_all          = split( "__", $id_textarea );
	my @package_name_temp = split( ":",  $name_all[1] );
	my @case_name_temp    = split( ":",  $name_all[2] );
	my $package_name      = $package_name_temp[1];
	my $case_name         = $case_name_temp[1];

	my $comment   = "none";
	my $bugnumber = "none";
	if (  -e $result_dir_manager 
		. $time . "/"
		. $package_name
		. "_manual_case_tests_comment_bug_number.txt" )
	{
		open FILE,
		    $result_dir_manager 
		  . $time . "/"
		  . $package_name
		  . "_manual_case_tests_comment_bug_number.txt"
		  or die $!;
		while (<FILE>) {
			if ( index( $_, $case_name ) > 0 ) {
				my @comment_bug_temp = split( "__", $_ );
				$bugnumber = pop(@comment_bug_temp);
				$comment   = pop(@comment_bug_temp);
			}
		}
	}
	print <<DATA;
                            <table width="100%" border="0" cellspacing="0" cellpadding="0" style="font-size:18px;table-layout:fixed" frame="hsides" rules="all">
                              <tr>
                                <td width="15%" class="report_list_outside_left">&nbsp;TC ID:</td>
                                <td colspan="3" class="report_list_outside_right">&nbsp;$name</td>
                              </tr>
                              <tr>
                                <td width="15%" class="report_list_outside_left">&nbsp;TC Purpose:</td>
                                <td colspan="3" class="report_list_outside_right">&nbsp;$description</td>
                              </tr>
                              <tr>
                                <td width="15%" class="report_list_outside_left">&nbsp;Priority:</td>
                                <td width="35%" class="report_list_inside">&nbsp;$priority</td>
                                <td width="15%" class="report_list_inside">&nbsp;Execution Type:</td>
                                <td width="35%" class="report_list_outside_right">&nbsp;$execution_type</td>
                              </tr>
                              <tr>
                                <td width="15%" class="report_list_outside_left">&nbsp;Component:</td>
                                <td width="35%" class="report_list_inside">&nbsp;$component</td>
                                <td width="15%" class="report_list_inside">&nbsp;Requirement:</td>
                                <td width="35%" class="report_list_outside_right">&nbsp;$requirement</td>
                              </tr>
                              <tr>
                                <td width="15%" class="report_list_outside_left">&nbsp;Case State:</td>
                                <td colspan="3" class="report_list_outside_right">&nbsp;$status</td>
                              </tr>
                              <tr>
                                <td width="15%" class="report_list_outside_left">&nbsp;Type:</td>
                                <td colspan="3" class="report_list_outside_right">&nbsp;$test_type</td>
                              </tr>
                              <tr>
                                <td width="15%" class="report_list_outside_left">&nbsp;Categories:</td>
                                <td colspan="3" class="report_list_outside_right">&nbsp;$categories</td>
                              </tr>
                              <tr>
                                <td width="15%" class="report_list_outside_left">&nbsp;Comment:</td>
                                <td colspan="3" class="report_list_outside_right">&nbsp;$comment</td>
                              </tr>
                              <tr>
                                <td width="15%" class="report_list_outside_left">&nbsp;Bug Number:</td>
                                <td colspan="3" class="report_list_outside_right">&nbsp;$bugnumber</td>
                              </tr>
                              <tr>
                                <td width="15%" rowspan="6" class="report_list_outside_left">&nbsp;Description</td>
                                <td width="35%" class="report_list_inside">&nbsp;Pre-conditions:</td>
                                <td colspan="2" class="report_list_outside_right">&nbsp;$pre_conditions</td>
                              </tr>
                              <tr>
                                <td width="35%" class="report_list_inside">&nbsp;Post-conditions:</td>
                                <td colspan="2" class="report_list_outside_right">&nbsp;$post_conditions</td>
                              </tr>
                              <tr>
                                <td width="35%" class="report_list_inside">&nbsp;Steps</td>
                                <td colspan="2" class="report_list_outside_right"><table width="100%" border="0" cellspacing="0" cellpadding="0" frame="void" rules="all">
DATA

	my @temp_steps = split( "__", $steps );
	foreach (@temp_steps) {
		my @temp             = split( ":", $_ );
		my $step_description = shift @temp;
		my $expected_result  = shift @temp;
		print <<DATA;
                                  <tr>
                                    <td width="30%" class="report_list_inside">&nbsp;Step Description:</td>
                                    <td width="70%" class="report_list_outside_right">&nbsp;$step_description</td>
                                  </tr>
                                  <tr>
                                    <td width="30%" class="report_list_inside">&nbsp;Expected Result:</td>
                                    <td width="70%" class="report_list_outside_right">&nbsp;$expected_result</td>
                                  </tr>
DATA
	}
	print <<DATA;
                                </table></td>
                              </tr>
                              <tr>
                                <td width="35%" class="report_list_inside">&nbsp;Notes:</td>
                                <td colspan="2" class="report_list_outside_right">&nbsp;$note</td>
                              </tr>
                              <tr>
                                <td width="35%" class="report_list_inside">&nbsp;Test Script Entry:</td>
                                <td colspan="2" class="report_list_outside_right">&nbsp;$test_script_entry</td>
                              </tr>
                              <tr>
                                <td width="35%" class="report_list_inside">&nbsp;Test Script Expected Result:</td>
                                <td colspan="2" class="report_list_outside_right">&nbsp;$test_script_expected_result</td>
                              </tr>
                              <tr>
                                <td width="15%" rowspan="5" class="report_list_outside_left">&nbsp;Result Info</td>
                                <td width="35%" class="report_list_inside">&nbsp;Actual result:</td>
                                <td colspan="2" class="report_list_outside_right">&nbsp;$actual_result</td>
                              </tr>
                              <tr>
                                <td width="35%" class="report_list_inside">&nbsp;Start:</td>
                                <td colspan="2" class="report_list_outside_right">&nbsp;$start</td>
                              </tr>
                              <tr>
                                <td width="35%" class="report_list_inside">&nbsp;End:</td>
                                <td colspan="2" class="report_list_outside_right">&nbsp;$end</td>
                              </tr>
                              <tr>
                                <td width="35%" class="report_list_inside">&nbsp;Stdout:</td>
                                <td colspan="2" class="report_list_outside_right">&nbsp;$stdout</td>
                              </tr>
                              <tr>
                                <td width="35%" class="report_list_inside">&nbsp;Stderr:</td>
                                <td colspan="2" class="report_list_outside_right">&nbsp;$stderr</td>
                              </tr>
                              <tr>
                                <td width="15%" rowspan="5" class="report_list_outside_left">&nbsp;Measurement</td>
                                <td width="35%" class="report_list_inside">&nbsp;Name:</td>
                                <td colspan="2" class="report_list_outside_right">&nbsp;$measurement_name</td>
                              </tr>
                              <tr>
                                <td width="35%" class="report_list_inside">&nbsp;Value:</td>
                                <td colspan="2" class="report_list_outside_right">&nbsp;$measurement_value</td>
                              </tr>
                              <tr>
                                <td width="35%" class="report_list_inside">&nbsp;Unit:</td>
                                <td colspan="2" class="report_list_outside_right">&nbsp;$measurement_unit</td>
                              </tr>
                              <tr>
                                <td width="35%" class="report_list_inside">&nbsp;Target:</td>
                                <td colspan="2" class="report_list_outside_right">&nbsp;$measurement_target</td>
                              </tr>
                              <tr>
                                <td width="35%" class="report_list_inside">&nbsp;Failure:</td>
                                <td colspan="2" class="report_list_outside_right">&nbsp;$measurement_failure</td>
                              </tr>
                              <tr>
                                <td width="15%" rowspan="3" class="report_list_outside_left">&nbsp;Spec</td>
                                <td width="35%" class="report_list_inside">&nbsp;Name:</td>
                                <td colspan="2" class="report_list_outside_right">&nbsp;$spec</td>
                              </tr>
                              <tr>
                                <td width="35%" class="report_list_inside">&nbsp;URL:</td>
                                <td colspan="2" class="report_list_outside_right">&nbsp;$spec_url</td>
                              </tr>
                              <tr>
                                <td width="35%" class="report_list_inside">&nbsp;Statement:</td>
                                <td colspan="2" class="report_list_outside_right">&nbsp;$spec_statement</td>
                              </tr>
                            </table>
DATA
}

sub updateManualCaseResult {
	my %manual_case_result;
	my ( $time, $package ) = @_;
	open FILE,
	  $result_dir_manager . $time . "/" . $package . "_manual_case_tests.txt"
	  or die $!;
	while (<FILE>) {
		my @temp = split( ":", $_ );
		$manual_case_result{ pop(@temp) } = pop(@temp);
	}
	return %manual_case_result;
}

1;
