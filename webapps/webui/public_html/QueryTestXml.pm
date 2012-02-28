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

package QueryTestXml;


require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(query_testcase query_testsuit query_testset query_testpackage query_testcase_desc updateCaseResult query_result_status);
@EXPORT_OK = qw();

use JSON;
use TestXmlParser;
use URI::Escape;
use Templates;
use UserProfile;
use TestStatus;
use Common;
use Error;
use Fcntl qw/:flock :seek/;
use File::Temp qw/tmpnam tempfile/;
use TestKitLogger;
	
sub query_testpackage($){
	my ($whole_path)=@_;	
	
	my($filePath);
	
	my @folders = split("\/\/\/", $whole_path);
	
	if (@folders < 1){
        $data .="This suit path is illegal\n";
		return $data;
    }
	
	#$filePath = $SERVER_PARAM{'APP_DATA'}.'/tests/';
	$filePath = '/usr/share/';
	foreach (@folders){
		$filePath.="$_/";
	}
	
	$filePath.="tests.xml";	
	$TestKitLogger::logger->log(message =>  "$filePath\n");
	
	my $packageRef = &queryTestPackage($filePath);
	
	$packageRef = &formatTestPackageResult($packageRef);
	my $json_text = JSON->new->utf8(1)->pretty(1)->encode($packageRef);
	
	$TestKitLogger::logger->log(message =>  "JSON String of test package \"$whole_path\": $json_text\n");
	
	return $json_text;
}

sub query_testset($){
	my ($whole_path)=@_;	
	
	my($filePath, $suitName, $setName);
	
	my @folders = split("\/\/\/", $whole_path);
	
	if (@folders < 1){
        $data .="This suit path is illegal\n";
		return $data;
    }
	
	$setName = pop(@folders);
	$suitName = pop(@folders);
	$TestKitLogger::logger->log(message =>  "SetName:$setName\n");
	
	#$filePath = $SERVER_PARAM{'APP_DATA'}.'/tests/';
	$filePath = '/usr/share/';
	foreach (@folders){
		$filePath.="$_/";
	}
	
	$filePath.="tests.xml";	
	$TestKitLogger::logger->log(message =>  "$filePath\n");
	
	my $setRef = &queryTestSet($filePath, $suitName, $setName);
	
	$setRef = &formatResult($setRef, $setName);
	my $json_text = JSON->new->utf8(1)->pretty(1)->encode($setRef);
	
	$TestKitLogger::logger->log(message =>  "JSON String of test case \"$whole_path\": $json_text\n");
	
	return $json_text;
}
	
sub query_testsuit($){
	my ($whole_path)=@_;	
	
	my($filePath, $suitName);
	
	my @folders = split("\/\/\/", $whole_path);
	
	if (@folders < 1){
        $data .="This suit path is illegal\n";
		return $data;
    }
	
	$suitName = pop(@folders);
	$TestKitLogger::logger->log(message =>  "SuitName:$suitName\n");
	
	#$filePath = $SERVER_PARAM{'APP_DATA'}.'/tests/';
	$filePath = '/usr/share/';
	foreach (@folders){
		$filePath.="$_/";
	}
	
	$filePath.="tests.xml";	
	$TestKitLogger::logger->log(message =>  "$filePath\n");
	
	my $suitRef = &queryTestSuit($filePath, $suitName);
	
	$suitRef = &formatResult($suitRef, $suitName);
	my $json_text = JSON->new->utf8(1)->pretty(1)->encode($suitRef);
	
	$TestKitLogger::logger->log(message =>  "JSON String of test case \"$whole_path\": $json_text\n");
	
	return $json_text;
}

sub query_testcase($){
	my ($whole_path, $excludeDescription)=@_;	
	
	my $caseRef = &find_case($whole_path);
	
	my @folders = split("\/\/\/", $whole_path);
	
	my $caseName = pop(@folders);
	
	$caseRef = &formatResult($caseRef, $caseName, $excludeDescription);
	my $json_text = JSON->new->utf8(1)->pretty(1)->encode($caseRef);
	
	$TestKitLogger::logger->log(message =>  "JSON String of test case \"$whole_path\": $json_text\n");
	
	return $json_text;
}

sub find_case($){
	my ($whole_path)=@_;	
	
	my($filePath, $suitName, $setName, $caseName);
	
	my @folders = split("\/\/\/", $whole_path);
	
	if (@folders < 3){
        $data .="The test case path is illegal\n";
		return $data;
    }
	
	$caseName = pop(@folders);
	$TestKitLogger::logger->log(message =>  "CaseName:$caseName\n");
	$setName = pop(@folders);
	$suitName = pop(@folders);
	
	#$filePath = $SERVER_PARAM{'APP_DATA'}.'/tests/';
	$filePath = '/usr/share/';
	foreach (@folders){
		$filePath.="$_/";
	}
	
	$filePath.="tests.xml";	
	$TestKitLogger::logger->log(message =>  "$filePath\n");
	
	my $caseRef = &queryTestCase($filePath, $suitName, $setName, $caseName);
	
	return $caseRef;
}

sub query_testcase_desc($){
	my ($whole_path)=@_;	
	
	my $caseRef = &find_case($whole_path);
	
	my @descArray; 
	
	&extractDescription($caseRef, \@descArray);
	
	my $description;
	if(@descArray){
		$description = $descArray[0]->{'value'};
	}
	
	#my $json_text = JSON->new->utf8(1)->pretty(1)->encode($description);
	
	$TestKitLogger::logger->log(message =>  "Desc String of test case \"$whole_path\": $description\n");
	
	return $description;
}

sub updateCaseResult($){
	my ($resultXMLPath, $casePath, $result) = @_;
	
	my($suitName, $setName, $caseName);
	
	my @folders = split("\/\/\/", $casePath);
	
	if (@folders < 3){
        $data .="The test case path is illegal\n";
		return $data;
    }
	
	$caseName = pop(@folders);
	$setName = pop(@folders);
	$suitName = pop(@folders);

	$TestKitLogger::logger->log(message =>  "\nCaseName:$caseName\nSetName:$setName\nSuiteName:$suitName\n XML path:\n $resultXMLPath\n Status:$result");
	&updateManualTestCaseResult($resultXMLPath, $suitName, $setName, $caseName, $result);
}  

sub query_result_status($) {
	my ($resultXMLPath, $casePath) = @_;
	my($suitName, $setName, $caseName);
	
	my @folders = split("\/\/\/", $casePath);
	
	if (@folders < 3){
        $data .="The test case path is illegal\n";
		return $data;
    }
	
	$caseName = pop(@folders);	
	$setName = pop(@folders);
	$suitName = pop(@folders);
	
	$TestKitLogger::logger->log(message =>  "\nCaseName:$caseName\nSetName:$setName\nSuiteName:$suitName\n XML path:\n $resultXMLPath\n");
	
	&queryManualTestCaseResult($resultXMLPath, $suitName, $setName, $caseName);
}

1;