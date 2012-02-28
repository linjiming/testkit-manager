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
#			Update the title 'MeeGo Testkit' by Tang, Shao-Feng  <shaofeng.tang@intel.com>
#			Comment the user-profile related codes by Tang, Shao-Feng  <shaofeng.tang@intel.com>
# 
#

use Templates;

print "HTTP/1.0 200 OK" . CRLF;
print "Content-type: text/html" . CRLF . CRLF;

#print_header("About $MTK_BRANCH Distribution Checker", "about");
#my $default_user = $SERVER_PARAM{'APP_DATA'}.'/profiles/user/user.profile';
#my $user = 'Guest';
#if (!open (MYFILE, $default_user)) {
#        $error_text = "Could not obtain user!<br />($!) \n";
#}
#else {
#        while (<MYFILE>) {
#                if ($_ =~ /^Tester Name:\s+(.*)/)
#                {
#                        $user = $1;
#                        last;
#                }
#        }
#     }
print_header("About $MTK_BRANCH Testkit", "about");

print <<DATA;
<div style="width: 54em;">
<!--elva: need update
<h1>$MTK_BRANCH Distribution Checker</h1>
<p><b>Version $MTK_VERSION</b></p>
<p>Copyright &copy; 2007&ndash;2009 <a href="http://linuxfoundation.org/" target="_blank">The Linux Foundation</a>. All rights reserved.</p>
<p>Note: this product uses the ptyshell tool which was originally written by Jiri Dluhos and copyrighted by SuSE Linux Products GmbH.</p>

<h2>Product Support</h2>
<p>Should you have any questions, comments or feature requests, please contact the <a href="mailto:lsb-dtk-support\@linuxfoundation.org">ISP RAS support team</a>. You can also use the project <a href="http://ispras.linuxfoundation.org/index.php/About_Distribution_Checker" target="_blank">home page</a> for more information about the $MTK_BRANCH Distribution Checker.</p>

<h2>License</h2>
<p>This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License version 2 as published by the Free Software Foundation.</p>

<p>This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.</p>

<p>You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.</p>
-->
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
<h1>MeeGo Testkit</h1>
<p>will come soon</p>
</div>
DATA

print_footer();

