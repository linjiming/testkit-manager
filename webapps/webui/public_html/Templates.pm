# Distribution Checker
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
	unshift @INC, $FindBin::Bin.'/../../utils';
}

package Templates;
use strict;
use Exporter;
use Common;

$Common::debug_inform_sub = sub {};

@Templates::ISA = 'Exporter';
@Templates::EXPORT = (
	qw(
		CRLF
		%SERVER_PARAM %_GET %_POST %_COOKIE %CONFIG
		&print_header &print_footer
		&autoflush_on &escape &unescape &show_error_dlg
	),
	@Common::EXPORT,
	);

my ($global_header, $global_footer);

use constant CRLF => "\x0d\x0a";

our %SERVER_PARAM = ();
$SERVER_PARAM{'HOST'} =            ($ENV{'DTKM_HOST'} or '');
$SERVER_PARAM{'PEER_IP'} =         ($ENV{'DTKM_PEER_IP'} or '');
$SERVER_PARAM{'PORT'} =            ($ENV{'DTKM_PORT'} or '');
$SERVER_PARAM{'SERVER_PID'} =      ($ENV{'DTKM_SERVER_PID'} or '');
$SERVER_PARAM{'DOCUMENT_ROOT'} =   ($ENV{'DTKM_DOCUMENT_ROOT'} or '');
$SERVER_PARAM{'APP_DATA'} =        ($ENV{'DTKM_APP_DATA'} or '');
$SERVER_PARAM{'PROXY'} =           ($ENV{'DTKM_PROXY'} or '');
$SERVER_PARAM{'PROXY_AUTH'} =      ($ENV{'DTKM_PROXY_AUTH'} or 'basic');
$SERVER_PARAM{'HTTP_PROXY'} =      ($ENV{'DTKM_HTTP_PROXY'} or '');
$SERVER_PARAM{'HTTP_PROXY_AUTH'} = ($ENV{'DTKM_HTTP_PROXY_AUTH'} or 'basic');
$SERVER_PARAM{'FTP_PROXY'} =       ($ENV{'DTKM_FTP_PROXY'} or '');
$SERVER_PARAM{'FTP_PROXY_AUTH'} =  ($ENV{'DTKM_FTP_PROXY_AUTH'} or 'basic');
$SERVER_PARAM{'CONF_FILE'} =       ($ENV{'DTKM_CONF_FILE'} or '');


if (open(FILE, $SERVER_PARAM{'DOCUMENT_ROOT'}.'/header.tpl')) {
	$global_header = '';
	while (<FILE>) {
		$global_header .= $_;
	}
	close(FILE);
}
if (open(FILE, $SERVER_PARAM{'DOCUMENT_ROOT'}.'/footer.tpl')) {
	$global_footer = '';
	while (<FILE>) {
		$global_footer .= $_;
	}
	close(FILE);
}
if (!$global_header or !$global_footer) {
	$global_header = "<html><body>\n";
	$global_footer = '</body></html>';
}

sub escape($) {
	my ($str) = @_;
	$str =~ s/([^0-9a-zA-Z_\-])/sprintf('%%%02X', ord($1))/eg;
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
@args = split(/&/, $ENV{'DTKM_GET_ARGS'});
foreach (@args) {
	my ($name, $val) = split(/=/, $_, 2);
	if ($name) {
		$name = unescape($name);
		if (defined($val)) {
			$val = unescape($val);
		}
		else {
			$val = '1';
		}
		$_GET{$name} = $val;
	}
}

our %_POST = ();
@args = split(/&/, $ENV{'DTKM_POST_ARGS'});
foreach (@args) {
	my ($name, $val) = split(/=/, $_, 2);
	if ($name) {
		$name = unescape($name);
		if (defined($val)) {
			$val = unescape($val);
		}
		else {
			$val = '1';
		}
		$_POST{$name} = $val;
	}
}

our %_COOKIE = ();
my @cookies_list = split(/;\s*/, $ENV{'DTKM_COOKIES'});
foreach (@cookies_list) {
	my ($name, $val) = split(/=/, $_, 2);
	if ($name and defined($val)) {
		$name = unescape($name);
		$val = unescape($val);
		$_COOKIE{$name} = $val;
	}
}

# Get "<DOCUMENT_ROOT>/../.." path
my $tmp = $SERVER_PARAM{'DOCUMENT_ROOT'};
$tmp =~ s!/[^/]+/[^/]+$!!;
our %CONFIG = (
	'TESTS_DIR' => "$tmp/utils",
	'RESULTS_DIR' => $SERVER_PARAM{'APP_DATA'}.'/results'
);

my %styles = (
	'view' => '$$$CERT_STYLE$$$',
	'conf' => '$$$CONFIGURE_STYLE$$$',
	'exec' => '$$$PROGRESS_STYLE$$$',
	'manappbat' => '$$$PROGRESS_STYLE$$$',
	'results' => '$$$RESULTS_STYLE$$$',
	'sumreport' => '$$$RESULTS_STYLE$$$',
	'detreport' => '$$$RESULTS_STYLE$$$',
	'help' => '$$$HELP_STYLE$$$',
	'about' => '$$$ABOUT_STYLE$$$',
	'admin' => '$$$ADMIN_STYLE$$$'
);

sub print_header($$) {
	my ($title, $id) = @_;
	my $header = $global_header;
	# Replace static patterns
	$header =~ s/\$\$\$PAGE_TITLE\$\$\$/$title/g;
	$header =~ s/\$\$\$MTK_BRANCH\$\$\$/$MTK_BRANCH/g;
	$header =~ s/\$\$\$MTK_BRANCH_LC\$\$\$/lc($MTK_BRANCH)/eg;

	# Find and highlight the active menu link
	foreach my $name (keys %styles) {
		if ($id eq $name) {
			$header =~ s/\Q$styles{$name}\E/-active/;
			last;
		}
	}
	# Set all other menu links to non-highlighted style
	foreach (values %styles) {
		$header =~ s/\Q$_\E//;
	}
	if ($id) {
		$header =~ s/\$\$\$HELP_REF\$\$\$/#$id/;
	}
	else {
		$header =~ s/\$\$\$HELP_REF\$\$\$//;
	}
	print $header;
}

sub print_footer {
	if ($_[0]) {
		$global_footer =~ s/<\/body>//;
		$global_footer =~ s/<\/html>//;
	}
	print $global_footer;
}

# Remove old session profiles
my $tm = time();
if (opendir(DIR, $SERVER_PARAM{'APP_DATA'}.'/profiles')) {
	my @files = grep /^~session\./, readdir(DIR);
	foreach (@files) {
		my $name = $SERVER_PARAM{'APP_DATA'}."/profiles/$_";
		# Session expiration time is 7 days
		if ($tm - (stat($name))[8] > 7*86400) {
			unlink($name);
		}
	}
	closedir(DIR);
}

sub autoflush_on() {
	my $old_handle = select (STDOUT);
	$| = 1;
	select (STDERR);
	$| = 1;
	select ($old_handle);
}

sub show_error_dlg($) {
	my ($error_text) = @_;
	my $error_show = (($error_text eq '') ? ' display: none;' : '');
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
<div id="error_msg_collapsed" style="border: dashed 1px darkred; background-color: red; float: right; cursor: pointer; display: none;" onclick="javascript:document.getElementById('error_msg_area').style.display='';document.getElementById('error_msg_collapsed').style.display='none';" title="Expand">
<table border="0" cellpadding="1" cellspacing="1">
  <tr>
    <td align="left" style="white-space: nowrap;"><font color="white"><b>&nbsp;There are some problems!</b></font></td>
    <td width="15"></td>
    <td width="11"><img src="images/expand.png" alt="O" width="20" height="20" /></td>
  </tr>
</table>
</div>
<div id="error_msg_area" style="border: none;$error_show">
<table border="0" cellpadding="1" cellspacing="1" width="70%" align="center">
  <tr>
    <th style="border: dashed 1px darkred; background: red; color: white; font-size: large;">
      <table border="0" cellpadding="0" cellspacing="0" align="center">
        <tr>
          <td width="100%">Errors!</td>
          <td><img src="images/collapse.png" alt="_" width="20" height="20" style="cursor: pointer;" title="Collapse" onclick="javascript:document.getElementById('error_msg_area').style.display='none';document.getElementById('error_msg_collapsed').style.display='';" /></td>
        </tr>
      </table>
    </th>
  </tr>
  <tr><td align="center" style="border: dashed 1px darkred; border-top: none;">
    <table border="0" cellpadding="0" cellspacing="0">
      <tr><td height="10" colspan="3"></td></tr>
      <tr><td width="50%"></td><td align="left" id="error_msg_text" style="font-size: medium; white-space: nowrap;">$error_text</td><td width="50%"></td></tr>
      <tr><td height="10" colspan="3"></td></tr>
    </table>
  </td></tr>
</table>
<br />
</div>
DATA
}

1;
