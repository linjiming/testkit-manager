#!/usr/bin/perl -w
#
# Copyright (C) 2010 Intel Corporation
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
#          Tang, Shao-Feng  <shaofeng.tang@intel.com>
#

use Templates;
use TestStatus;
use Common;
use Error;
use Fcntl qw/:flock :seek/;
use File::Temp qw/tmpnam tempfile/;
use JSON;

use TestKitLogger;
use FileHandle;

my $pkgName = $_GET{'pkg'};
my $testId = $_GET{'testId'};
my $result_path = $CONFIG{'RESULTS_DIR'}.'/'.$testId.'/'.$pkgName.'/result.tests.xml';
my $result_ori_path = '/usr/share/'.$pkgName.'/tests.xml';

my $fh = new FileHandle($result_path);

my $file_data = "";
my $filesize = -s $result_path; 
my $sz = read($fh, $file_data, $filesize);

my $ori_fh = new FileHandle($result_ori_path);
my $ori_file_data = "";
my $ori_filesize = -s $result_ori_path; 
my $ori_sz = read($ori_fh, $ori_file_data, $ori_filesize);

$ori_file_data =~ s/<\?xml version=(\"|\')1.0(\"|\') encoding=(\"|\')(.*)(\"|\')\?>//;
#$ori_file_data =~ s/<!\[CDATA\[//g;
#$ori_file_data =~ s/\]\]>//g;
$ori_file_data =~ s/\s*\n\s*//g;
$ori_file_data =~ s/\'/&apos;/g;


$ori_file_data = '<ori_tests>'.$ori_file_data.'</ori_tests></testresults>';

$file_data =~ s/<\/testresults>/$ori_file_data/;

my $wholeXML .= $file_data;

my $output_xml = "HTTP/1.0 200 OK" . CRLF . "Content-type: text/xml" . CRLF . CRLF;
if($wholeXML){
	$wholeXML =~ s/<\?xml version=(\"|\')1.0(\"|\') encoding=(\"|\')(.*)(\"|\')\?>/<\?xml version=\"1.0\" encoding=\"$4\"\?><\?xml-stylesheet type=\"text\/xsl\" href=\"\/resultstyle2.xsl\" \?>/;
	print $output_xml.$wholeXML;
}else{
	print $output_xml."<?xml version=\"1.0\" encoding=\"utf-8\"?><?xml-stylesheet type=\"text\/xsl\" href=\"/resultstyle2.xsl\" ?>\n"."<testresults>The corresponding XML file isn't available</testresults>";
}