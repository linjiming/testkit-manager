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
#use BuildList;
use UserProfile;
use TestStatus;
use Common;
use Error;
use Fcntl qw/:flock :seek/;
use File::Temp qw/tmpnam tempfile/;
use JSON;

use TestKitLogger;

my $error_text = '';
my $test_case=$_GET{'case'};
my $testrun_id = $_GET{'test_run'};
my @folders = split("\/\/\/", $test_case);
my $packageName=shift @folders;
my $tests_result = $CONFIG{'RESULTS_DIR'}.'/'.$testrun_id.'/'.$packageName.'/result.tests.xml';
my $data .= "";
if(-e $tests_result and -f $tests_result) {
	use QueryTestXml;
	#$data .="<description><![CDATA[".&query_testcase_desc($test_case)."]]></description>";
	$TestKitLogger::logger->log(message =>  "Result File: $tests_result");
	$data .="<case_status><![CDATA[".&query_result_status($tests_result, $test_case)."]]></case_status>";
	no QueryTestXml;
}else{
	$error_text = "The corresponding result XML file isn't available. Path:$tests_result";
}
my $output_xml = "HTTP/1.0 200 OK" . CRLF . "Content-type: text/xml" . CRLF . CRLF . "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n";
if ($error_text) {
	my $prefix = '';
	if ($error_text !~ m/^(Error|Warning):/mi) {
		$prefix = '<font color="red"><u><b>Error:</b></u></font> ';
	}
	$error_text = "<ul><li>$prefix<font color=\"darkblue\">$error_text</font></li></ul>";
	print $output_xml."<root>\n<error><![CDATA[$error_text]]></error>\n</root>";
}else {
	my $response = $output_xml."<root>$data</root>";
	$TestKitLogger::logger->log(message =>  "[load_tc_desc.pl]: the response:\n$response");
	print $response;
}
