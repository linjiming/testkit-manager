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
#			Remove the original way to get the manual cases info from a static HTML file by Tang, Shao-Feng  <shaofeng.tang@intel.com>. 
#			Dynamic scan the folder to extract the manual test-cases info according to the test profile by Tang, Shao-Feng  <shaofeng.tang@intel.com>.
#

use Templates;
use BuildList;
use UserProfile;

my @error_msgs = ();
my @warn_msgs = ();
our $test_id = "";

if (!$_GET{'test_run'}) {
        $error = 'Test run is not specified!';
}
$test_id = $_GET{'test_run'};

# Create session

# Print header.
 print 'HTTP/1.0 200 OK' . CRLF;
 print 'Content-type: text/html' . CRLF . CRLF;
#my $default_user = $SERVER_PARAM{'APP_DATA'}.'/profiles/user/user.profile';
#my $user = 'Guest';
#if (!open (MYFILE, $default_user)) {
#        $error_text = "Could not obtain user!<br />($!) \n";
#}
#else {
#        while (<MYFILE>) {
#                if ($_ =~ /^Name:\s+(.*)/)
#                {
#                        $user = $1;
#                        last;
#                }
#        }
#     }

 print_header('Manual Application Battery Tests', 'manappbat');

print <<DATA;
<table cellpadding="0" cellspacing="0" width="1020" height="26" id="table145">
                                <!-- MSTableType="layout" -->
                                <tr>
                                        <td height="1"> <img alt="" width="1" height="1" src="images/MsSpacer.gif"> </td>
                                </tr>
                                <tr>
					<td height="1"> <img alt="" width="1" height="1" src="images/MsSpacer.gif"> </td>
                                        <td valign="middle" bgcolor="#333333" width="500">
                                        </td>
                                        <td valign="middle" bgcolor="#333333" width="464">
                                        </td>
                                        <td valign="middle" bgcolor="#333333" width="107">
					<!-- font size="1" face="Arial" color="#FFFFFF">>> HELLO $user </font><</td -->
                                        <td width="2" height="26"></td>
                                        </tr>
                        </table>
DATA

print <<DATA;
	<table cellpadding="0" cellspacing="0" id="table166" width="1018" height="609">
	<!-- MSTableType="layout" -->
	<tr>
		<td valign="top" width="100%" height="100%">
DATA
print "<div class=\"yui-skin-sam\">\n";
print "  <div id=\"treeDiv1\"></div>\n";
print "<div id=\"PanelDetalle\"></div> ";
print"</div>\n";

print <<DATA;
		</td>
	<tr>
	</table>

DATA

# Function for writing Perl->HTML->JS templates.
# Input argument is a text variable containing HTML template code.
# The function converts it into a JS single-quotes string representing the
# appropriate HTML layout which can be passed into elem.innerHTML or so.
# <<<smth>>> patterns contain plain JS code snippets and are put into the resultant
# JS code unchanged (surrounded with '+' string operator).
# Also, compactification is performed (excessive spaces and newlines are removed).
# Starting and trailing quotes are not added.
#
# Example: html_compact("<b>Item No. '<<<x['1']>>>'</b>") eq "<b>Item No.\'' + x['1'] + '\'</b>";
# Known issue: additional "+ ''" is added to the end of the line.
sub html_compact($) {
	my ($html) = @_;
	$html =~ s/\n\s*//g;
	my @parts = split(/<<<|>>>/, $html);
	my $raw_js = 0;
	foreach my $part (@parts) {
		if ($raw_js) {
			$part .= ' + \'';
		}
		else {
			$part =~ s/\'/\\\'/g;
			$part .= '\' + ';
		}
		$raw_js = !$raw_js;
	}
	return join('', @parts).'\'';
}

my $tmp_table_code;

my $test_tree_code = '';

my $test_tree_div = '<div id="treediv" >';

use Scanfolder;
$test_tree_div .= &dynamicScanManualcaseFolders($CONFIG{'RESULTS_DIR'}.'/'.$test_id.'/profile.auto');
no Scanfolder;

#if (open(FILE, $SERVER_PARAM{"APP_DATA"}.'/profiles/manual_testsuites.htm')) {
#        while (<FILE>) {
#                $test_tree_div .= $_;
#        }
#        close(FILE);
#}
$test_tree_div .= '</div>';

$test_tree_code = html_compact($test_tree_div);

print <<DATA;
<div id="ajax_loading" style="display: none;"></div>
<script type="text/javascript" src="css/dtk.js"></script>
<script type="text/javascript" src="view_test.js"></script>
<script type="text/javascript">
var treediv_html = '$test_tree_code';
show_manual_test_view(treediv_html);
</script>
<input type="hidden" id="test_id" value="$test_id" />
DATA


print_footer();
