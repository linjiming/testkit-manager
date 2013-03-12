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

print_header( "$MTK_BRANCH Manager Help Page", "help" );

my $user_guide =
  $SERVER_PARAM{'APP_DATA'} . "/doc/Testkit-Manager_User_Guide.pdf";

print <<DATA;
<iframe id="help_frame" frameborder="0" scrolling="no" width="768" height="700" src="/get.pl?file=$user_guide"></iframe>
DATA

print_footer("");
