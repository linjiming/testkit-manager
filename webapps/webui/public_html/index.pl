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

print "HTTP/1.0 200 OK" . CRLF;
print "Content-type: text/html" . CRLF . CRLF;

print_header( "$MTK_BRANCH Manager Main Page", "" );

print <<DATA;
<map name="home_menu" id="home_menu">
  <area href="tests_report.pl" alt="Report" title="Report" shape="rect" coords="528,16,843,250" />
  <area href="tests_custom.pl" alt="Custom" title="Custom" shape="rect" coords="34,88,313,330" />
  <area href="tests_help.pl" alt="Help" title="Help" shape="rect" coords="850,173,1164,411" />
  <area href="tests_execute.pl" alt="Execute" title="Execute" shape="rect" coords="315,295,626,528" />
  <area href="tests_statistic.pl" alt="Statistic" title="Statistic" shape="rect" coords="633,444,946,684" />
  <area href="#about" alt="About" title="About" shape="rect" coords="1133,674,1267,740" onclick="javascript:showAbout()" />
</map>
<img src="images/home_menu.png" width="1280" height="740" alt="home_menu" usemap="#home_menu" />
<div id="about" style="display:none" onclick="javascript:showAbout()">
  <div align="left">
    <div style="position:relative; width:350px; height:130px; left: 90px; top: 75px;">Testkit-manager is a GUI, which is developed as an auto-testing tool.
It uses &quot;testkit-lite&quot; as execution tool for running case. With this tool, we can filter cases that we want to run with several properties' value, the
filtered cases can be run automatically and the report will be generated after finishing running. We can also submit report and view report with this tool.</div>
    </div>
  </div>
</div>

<script language="javascript" type="text/javascript">
// <![CDATA[
function showAbout() {
	var about = document.getElementById('about');
	if (about.style.display == "none") {
		about.style.display = "";
	} else {
		about.style.display = "none";
	}
}
// ]]>
</script>
DATA

print_footer("footer_home");

