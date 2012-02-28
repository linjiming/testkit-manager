#!/usr/bin/perl -w

# Distribution Checker
# Custom Tests Page Module (tests_conf.pl)
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

use Templates;
use BuildList;
use UserProfile;

my @error_msgs = ();
my @warn_msgs = ();

if ($_COOKIE{"last_error_text"}) {
	push @error_msgs, $_COOKIE{"last_error_text"};
}

# Create session
if (!-d $SERVER_PARAM{"APP_DATA"}."/profiles/test") {
	system("mkdir -p ".$SERVER_PARAM{"APP_DATA"}."/profiles/test");
	if (!-d $SERVER_PARAM{"APP_DATA"}."/profiles/test") {
		push @error_msgs, "Cannot not create the profiles directory!<br />$!";
	}
}

my $profile_name = "";
my $create_session_error = 0;

if (!$_COOKIE{"session_id"} or !-f $SERVER_PARAM{"APP_DATA"}."/profiles/test/~session.".$SERVER_PARAM{"PEER_IP"}.".".$_COOKIE{"session_id"}) {
	my $i = time();
	while (-f $SERVER_PARAM{"APP_DATA"}."/profiles/test/~session.".$SERVER_PARAM{"PEER_IP"}.".$i") {
		$i++;
	}
	$_COOKIE{"session_id"} = $i;
	$profile_name = "~session.".$SERVER_PARAM{"PEER_IP"}.".$i";
	if (open(FILE, ">".$SERVER_PARAM{"APP_DATA"}."/profiles/test/$profile_name")) {
		close(FILE);
	}
	else {
		push @error_msgs, "Cannot create the session profile '$profile_name'!<br />$!";
		$create_session_error = 1;
	}
}
else {
	$profile_name = "~session.".$SERVER_PARAM{"PEER_IP"}.".".$_COOKIE{"session_id"};
}

my @checkbox_state = ('', ' checked="checked"');
my $profile = read_profile($SERVER_PARAM{"APP_DATA"}."/profiles/test/$profile_name");
my $standard_ver = $DEFAULT_STANDARD_VER;
if (detect_OS() =~ m/\bMeeGo\b/i) {
	$standard_ver = 'MeeGo 1.0';
}
my %default_profile_general = (
	"NAME" => "",
	"ORGANIZATION" => "",
	"EMAIL" => "",
	"SEND_EMAIL" => "0",
	"VERBOSE_LEVEL" => "1",
	"ARCHITECTURE" => (detect_architecture() or "x86"),
	"USE_INTERNET" => "1",
	"STD_VERSION" => $standard_ver,
	"STD_PROFILE" => "no",
	"COMMENTS" => ""
);

# Fill values not specified in profile
foreach (keys %default_profile_general) {
	if (!defined($profile->{'GENERAL'}->{$_})) {
		$profile->{'GENERAL'}->{$_} = $default_profile_general{$_};
	}
}

# Set cookie expiration to 7 days since now
my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = gmtime(time() + 7*86400);
my @wday_names = qw/Sunday Monday Tuesday Wednesday Thursday Friday Saturday/;
my @mon_names = qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;
# Format date like follows: Tuesday, 31-Dec-19 21:00:00 GMT
my $fmt_date = sprintf("%s, %d-%s-%d %02d:%02d:%02d GMT", $wday_names[$wday], $mday, $mon_names[$mon], 1900 + $year, $hour, $min, $sec);
print "HTTP/1.0 200 OK" . CRLF;
print "Content-type: text/html" . CRLF;
print "Set-Cookie: session_id=".$_COOKIE{"session_id"}."; expires=$fmt_date; path=/;" . CRLF;
print "Set-Cookie: last_error_text=; path=/;" . CRLF . CRLF;

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
print_header("View Tests", "view");

my $table_spacer = "<td><img src=\"images/environment-spacer.gif\" width=\"5\" height=\"1\" border=\"0\" alt=\"\" /></td>";

# Show errors/warnings
#push @error_msgs, $profile_error if ($profile_error);      # Ignore incompatible profile format
#@warn_msgs = (@profile_warnings);
my $error_text = "";
if ((scalar(@error_msgs) != 0) or (scalar(@warn_msgs) != 0)) {
	$error_text = "<ul>";
	foreach (@error_msgs) {
		$error_text .= "<li><font color=\"red\"><u><b>Error:</b></u></font> <font color=\"darkblue\">$_</font></li>";
	}
	foreach (@warn_msgs) {
		$error_text .= "<li><font color=\"darkred\"><u><b>Warning:</b></u></font> <font color=\"darkblue\">$_</font></li>";
	}
	$error_text .= "</ul>";
}

print show_error_dlg($error_text);

my %field_contents = ();
$field_contents{'NAME'} = $default_profile_general{'NAME'};
$field_contents{'ORGANIZATION'} = $default_profile_general{'ORGANIZATION'};
$field_contents{'COMMENTS'} = $default_profile_general{'COMMENTS'};
$field_contents{'EMAIL'} = $default_profile_general{'EMAIL'};
for my $key (keys %field_contents) {
	$field_contents{$key} =~ s/&/&amp;/g;
	$field_contents{$key} =~ s/\"/&quot;/g;
}

#print the 'black' bar
print <<DATA;
			<table cellpadding="0" cellspacing="0" width="1020" height="26" id="table155">
				<!-- MSTableType="layout" -->
				  <tr>
  					<td height="1"> <img alt="" width="1" height="1" src="images/MsSpacer.gif"> </td>
  				</tr>
				<tr>
					<td height="1"> <img alt="" width="1" height="1" src="images/MsSpacer.gif"> </td>
					<td valign="middle" bgcolor="#333333" width="400"></td>
					<td valign="middle" bgcolor="#333333" width="471"></td>
					<td valign="middle" bgcolor="#333333" width="147"></td>
					<td width="2" height="26"></td>
					</tr>
			</table>

DATA

print <<DATA;
			<table cellpadding="0" cellspacing="0" id="table156" width="1018" height="678">
				<!-- MSTableType="layout" -->
				<tr>
					<td valign="top" height="678" width="1018">
					<table cellpadding="0" cellspacing="0" border="0" width="100%" height="100%" id="table157">
						<!-- MSCellFormattingTableID="36" -->
						<tr>
							<td valign="top" width="100%" height="100%">
							<!-- MSCellFormattingType="content" -->
DATA
print "<div class=\"yui-skin-sam\">\n";
print "  <div id=\"treeDiv1\">\n";
print "  </div>\n";
print"</div>\n  ";

print <<DATA;
					</td>
				</tr>
			</table>
			</td>
		</tr>
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

# Function for dynamically scanning the folder structure of testsuits
# 
# Author: Joey.



my $tmp_table_code;
my $test_tree_code = '';
my $test_tree_div = '<div id="treediv" >';

use Scanfolder;
$test_tree_div .= &dynamicScanFolders(0);
no Scanfolder;

$test_tree_div .= '</div>';

$test_tree_code = html_compact($test_tree_div);

print <<DATA;
<script type="text/javascript" src="view_test.js"></script>
<script type="text/javascript">
var treediv_html = '$test_tree_code';
showtest_view(treediv_html);
</script>

DATA


print_footer();
