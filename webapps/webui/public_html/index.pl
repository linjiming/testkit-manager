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

print "HTTP/1.0 200 OK" . CRLF;
print "Content-type: text/html" . CRLF . CRLF;

print_header( "$MTK_BRANCH Manager Main Page", "" );

print <<DATA;
<map name="home_menu" id="home_menu">
  <area href="tests_report.pl" alt="Report" title="Vie Test Report" shape="rect" coords="316,8,506,150" />
  <area href="tests_custom.pl" alt="Plan" title="Create Test Plan" shape="rect" coords="20,53,203,199" />
  <area href="tests_help.pl" alt="Help" title="View Help Document" shape="rect" coords="509,102,700,248" />
  <area href="tests_execute.pl" alt="Execute" title="Execute Test Plan" shape="rect" coords="204,175,378,317" />
  <area href="tests_statistic.pl" alt="Statistic" title="View Test Packages' Statistics" shape="rect" coords="379,266,570,411" />
</map>
<img src="images/home_menu.png" width="768" height="444" alt="home_menu" usemap="#home_menu" />
DATA

print_footer("footer_home");

