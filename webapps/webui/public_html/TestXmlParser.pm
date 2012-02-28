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
#
#   Authors:
#
#          Tang, Shao-Feng  <shaofeng.tang@intel.com>
#

package TestXmlParser;

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(outputTestCasesInJSFormat queryTestCase generateXml formatResult formatTestPackageResult queryTestSuit queryTestSet queryTestPackage extractDescription updateManualTestCaseResult queryManualTestCaseResult getPackageStatus generatePackageResultHtml);
@EXPORT_OK = qw($PASS_STR $FAIL_STR $NA_STR $SUM_STR);

use strict;
use XML::Simple;
use Data::Dumper;

use TestKitLogger;

my $caseKey = "name";

sub xmlIterator{
	my ($refXml);
	($refXml) = @_;

	my $type = ref ($refXml);
	
	if( $type eq "HASH"){
	        foreach ( keys (%$refXml)){
        	        print "Key: $_\n";
			&xmlIterator($$refXml{$_});
        	}
	}
	elsif( $type eq "ARRAY"){
		foreach (@$refXml){
       			&xmlIterator($_); 
		}
	}
	else{
        	print $refXml;
	}
	
	print "\n";
}

my @attrNameList = ("manual", "insignificant", "level", "requirement", "type", "subfeature", "result");

sub extractDescription{
	my ($refXml, $attrArrayRef);
	($refXml, $attrArrayRef) = @_;

	#Convert description
	my $desRef = $refXml-> {description};
	if($desRef){
		my %descriptionHash;
		$descriptionHash{"key"} = "Description";
		if(ref ($desRef) eq "ARRAY" ){
			if($$desRef[0] and (ref ($$desRef[0]) ne "HASH")){
				$descriptionHash{"value"} = $$desRef[0];
			}elsif ($desRef > 1 and (ref ($$desRef[1]) ne "HASH")){
				$descriptionHash{"value"} = $$desRef[1];
			}
		}
		else {
			$descriptionHash{"value"} = $desRef;
		}
		push @$attrArrayRef, \%descriptionHash;
	}
}

sub formatTestPackageResult{
	my ($refXml);
	($refXml) = @_;
	
	my %case;
	
	#Convert attributes
	my @attrArray; 
	
	$TestKitLogger::logger->log(message =>  "Version Attribute :$refXml->{version}\n");
	if($refXml->{version}){
		my %attrHash;
		$attrHash{"key"} = "version";
		$attrHash{"value"} = $refXml->{version};
		push @attrArray, \%attrHash;
	}
	#Convert description
	&extractDescription($refXml, \@attrArray);
	
	$case{"attr"} = \@attrArray;
	
	return \%case;
}

sub departDescription{
	my ($refXml) = @_;

	#Convert description
	my $desRef = $refXml-> {description};
	if($desRef){
		my $desc;
		if(ref ($desRef) eq "ARRAY" ){
			if($$desRef[0]){
				$desc = $$desRef[0];
			}elsif ($desRef > 1){
				$desc = $$desRef[1];
			}
		}
		else{
			$desc = $desRef;
		}
		return $desc;
	}
}


sub formatResult{
	my ($refXml, $elemName, $excludeDescription);
	($refXml, $elemName, $excludeDescription) = @_;
	
	my %case;
	
	#Convert attributes
	my @attrArray; 
	{
		my %attrHash;
		$attrHash{"key"} = "Name";
		$attrHash{"value"} = $elemName;
		push @attrArray, \%attrHash;
		
		if ($refXml->{'manual'} eq 'true'){
		}
		else{
			if($refXml->{timeout}){
				my %timeoutHash;
				$timeoutHash{"key"} = "timeout";
				$timeoutHash{"value"} = $refXml->{timeout}." seconds";
				push @attrArray, \%timeoutHash;
			}
		}
	}
	
	foreach (@attrNameList){
		if($refXml->{$_}){
			my %attrHash;
			$attrHash{"key"} = $_;
			$attrHash{"value"} = $refXml->{$_};
			push @attrArray, \%attrHash;
		}
	}
	
	#Convert description
	if(!$excludeDescription){
		&extractDescription($refXml, \@attrArray);
	}else{
		my $desc = &departDescription($refXml);
		if($desc){
			$case{"desc"} = $desc;
		}else{
			$case{"desc"} = "";
		}
	}
	
	$case{"attr"} = \@attrArray;
	
	#Convert Steps
	my @stepArray; 
	my $stepRef = $refXml-> {step};
	$TestKitLogger::logger->log(message =>  "Step:$stepRef\n");
	foreach (@$stepRef){
		my %stepItemHash;
		$TestKitLogger::logger->log(message =>  "StepItem:$_\n");
		my $stepItemType = ref($_);
		
		if( $stepItemType eq "HASH"){
			$stepItemHash{"Command"} = $$_{"content"};
			$stepItemHash{"Expected"} = $$_{"expected_result"};
		}else{
			$stepItemHash{"Command"} = $_;
			$stepItemHash{"Expected"} = "";
		}
		
		push @stepArray, \%stepItemHash;
	}
	$case{"step"}  = \@stepArray;
	
	
	return \%case;
}

sub readXml{
	my ($filePath);
	($filePath) = @_;
	
	# create object
	my $xml = new XML::Simple;

	# read XML file
	$TestKitLogger::logger->log(message =>  "read XML file: \n$filePath");
	if(-f $filePath){
		my $data = $xml->XMLin($filePath, KeyAttr => {suite => 'name', set => 'name', case => $caseKey}, ForceArray => 1);
		return $data;
	}
}

sub queryTestPackage{
	my($filePath);
	($filePath) = @_;
	
	# read XML file
	my $data = &readXml($filePath);
	
	return $data;
}

sub queryTestSuit{
	my($filePath, $suitName);
	($filePath, $suitName) = @_;
	
	# read XML file
	my $data = &readXml($filePath);
	
	my $suit = $data->{suite}->{$suitName};
	
	return $suit;
}

sub queryTestSet{
	my($filePath, $suitName, $setName);
	($filePath, $suitName, $setName) = @_;
	
	# read XML file
	my $data = &readXml($filePath);
	
	my $set = $data->{suite}->{$suitName}->{set}->{$setName};
	
	return $set;
}

sub queryTestCase{
	my($filePath, $suitName, $setName, $caseName);
	($filePath, $suitName, $setName, $caseName) = @_;
	
	# read XML file
	my $data = &readXml($filePath);
	
	my $case = $data->{suite}->{$suitName}->{set}->{$setName}->{case}->{$caseName};
	
	#print Dumper ($case);
	
	return $case;
}

sub queryManualTestCaseResult{
	my($filePath, $suitName, $setName, $caseName);
	($filePath, $suitName, $setName, $caseName) = @_;
	
	# read XML file
	# create object
	my $xml = new XML::Simple;

	# read XML file
	$TestKitLogger::logger->log(message =>  "\nread XML file: \n$filePath");
	my $data = $xml->XMLin($filePath, KeyAttr => {suite => 'name', set => 'name', case => $caseKey}, ForceArray => 1);
	
	my $case = $data->{suite}->{$suitName}->{set}->{$setName}->{case}->{$caseName};
	
	$TestKitLogger::logger->log(message =>  "Unpadting Case: ".Dumper $case);
	my $result = "N/A";
	if($case){
		$result = $case->{result};
	}
	return $result;
}

sub updateManualTestCaseResult{
	my($filePath, $suitName, $setName, $caseName, $result);
	($filePath, $suitName, $setName, $caseName, $result) = @_;
	
	# read XML file
	# create object
	my $xml = new XML::Simple;

	# read XML file
	$TestKitLogger::logger->log(message =>  "\nread XML file: \n$filePath");
	my $data = $xml->XMLin($filePath, KeyAttr => {suite => 'name', set => 'name', case => $caseKey}, ForceArray => 1);
	
	my $case = $data->{suite}->{$suitName}->{set}->{$setName}->{case}->{$caseName};
	
	$TestKitLogger::logger->log(message =>  "Unpadting Case: ".Dumper $case);
	$case->{result} = $result;
	
	$TestKitLogger::logger->log(message =>  "\nWriting XML file: \n$filePath");
	if (open(my $fh, ">$filePath")) {
		$xml->XMLout($data, OutputFile => $fh, RootName => 'testresults', XMLDecl => '<?xml version="1.0" encoding="UTF-8"?>');
	}else{
		$TestKitLogger::logger->log(message =>  "\nFail to write XML file: \n$filePath");
	}
}

my $PASS_COLOR = "GREEN";
my $FAIL_COLOR = "RED";
my $NORUN_COLOR = "#CCCC00";

sub generatePackageResultHtml{
	my($filePath, $packageName);
	($filePath, $packageName) = @_;
	
	my $htmlStr = "<li title=\"package\">";
	$htmlStr.= "<font size=\"2px\" color=\"BLACK\">".$packageName;
	
	# read XML file
	# create object
	my $xml = new XML::Simple;

	# read XML file
	$TestKitLogger::logger->log(message =>  "\nread XML file: \n$filePath");
	
	if(-f $filePath and -e $filePath){
	  my $data = $xml->XMLin($filePath, KeyAttr => {suite => 'name', set => 'name', case => $caseKey}, ForceArray => 1);
	
	  if(keys(%{$data->{suite}}) > 0){
		my %packageCounter;
		$packageCounter{pass} = 0;
		$packageCounter{fail} = 0;
		$packageCounter{na} = 0;
		my $tempSuitesStr = "";
		
		my @sortedSuites = sort(keys(%{$data->{suite}}));
		foreach(@sortedSuites){
			my $thisSuite = $data->{suite}->{$_};
			my $thisSuiteHtml = "<li title=\"suit\"><font size=\"2px\" color=\"BLACK\">".$_;
			
			if(keys(%{$thisSuite->{set}}) > 0){
				my %suiteCounter;
				$suiteCounter{pass} = 0;
				$suiteCounter{fail} = 0;
				$suiteCounter{na} = 0;
				my $tempSetsStr = "";
				
				my @sortedStes = sort(keys(%{$thisSuite->{set}}));
				foreach(@sortedStes){
					my $thisSet = $thisSuite->{set}->{$_};
					my $thisSetHtml = "<li title=\"set\"><font size=\"2px\" color=\"BLACK\">".$_;
					if(keys(%{$thisSet->{case}}) > 0){
						my %setCounter;
						$setCounter{pass} = 0;
						$setCounter{fail} = 0;
						$setCounter{na} = 0;
						my $tempCaseStr = "";
						
						my @sortedCases = sort(keys(%{$thisSet->{case}}));
						foreach(@sortedCases){
							my $thisCase = $thisSet->{case}->{$_};
							my $thisCaseHtml = "<li title=\"case\"><font size=\"2px\" color=\"BLACK\">".$_;
							my $result = $thisCase->{result};
							if($result eq "PASS"){
								$thisCaseHtml.= " ( <font size=\"2px\" color=\"$PASS_COLOR\">PASS</font> )</font>";
								$setCounter{pass} += 1;
							}elsif ($result eq "FAIL"){
								$thisCaseHtml.= " ( <font size=\"2px\" color=\"$FAIL_COLOR\">FAIL</font> )</font>";
								$setCounter{fail} += 1;
							}else{
								$thisCaseHtml.= " ( <font size=\"2px\" color=\"$NORUN_COLOR\">Not Run</font> )</font>";
								$setCounter{na} += 1;
							}
							$thisCaseHtml.= "</li>";
							$tempCaseStr.=$thisCaseHtml;
						}
						
						$thisSetHtml.= &getColorStr(\%setCounter);
						$thisSetHtml.= "</font><ul>".$tempCaseStr."</ul></li>";
						
						&sumCounter(\%suiteCounter, \%setCounter);
					}else{
						$thisSetHtml .= &getEmptyColorStr();
						$thisSetHtml .= "</font></li>";
					}
					$tempSetsStr .= $thisSetHtml;
				}
				
				$thisSuiteHtml .= &getColorStr(\%suiteCounter);
				$thisSuiteHtml .= "</font><ul>".$tempSetsStr."</ul></li>";
				
				&sumCounter(\%packageCounter, \%suiteCounter);
			}else{
				$thisSuiteHtml .= &getEmptyColorStr();
				$thisSuiteHtml .= "</font></li>";
			}
			
			$tempSuitesStr .= $thisSuiteHtml;
		}
		
		$htmlStr.= &getColorStr(\%packageCounter);
		my $href = &getTheHrefStr($packageName);
		$htmlStr.= "</font><ul>".$tempSuitesStr.$href."</ul></li>";
	  }
	  }
	  else{
		$htmlStr.= &getEmptyColorStr();
		$htmlStr.= "</font></li>";
	  }
	
	return $htmlStr;
}

sub getTheHrefStr(){
	my ($packageName) = @_;
	my $href = "<li title=\"url\"><a href=\"javascript: onPackageClick('".$packageName."')\">More details</a></li>";
	return $href;
}

sub sumCounter(){
	my($parentCounterRef, $childCounterRef)=@_;
	
	$parentCounterRef->{pass} += $childCounterRef->{pass};
	$parentCounterRef->{fail} += $childCounterRef->{fail};
	$parentCounterRef->{na} += $childCounterRef->{na};
}

sub getEmptyColorStr(){
	my %counter;
	$counter{pass} = 0;
	$counter{fail} = 0;
	$counter{na} = 0;
	
	return &getColorStr(\%counter);
}

sub getColorStr(){
	my ($hashref);
	($hashref) = @_;
	my $total = $hashref->{pass} + $hashref->{fail} + $hashref->{na};
	
	my $html_str = " ( ".$total." | <font size=\"2px\" color=\"$PASS_COLOR\">".$hashref->{pass}."</font>";
	$html_str .= "<font size=\"2px\" color=\"BLACK\"> | </font>";
	$html_str .= "<font size=\"2px\" color=\"$FAIL_COLOR\">".$hashref->{fail}."</font>";
	$html_str .= "<font size=\"2px\" color=\"BLACK\"> | </font>";
	$html_str .= "<font size=\"2px\" color=\"$NORUN_COLOR\">".$hashref->{na}."</font>";
	$html_str .= "<font size=\"2px\" color=\"BLACK\"> )</font>";
	
	return $html_str;
}

sub generateXml{
	my ($hashref);
	($hashref) = @_;
	# create object
	my $xml = new XML::Simple;
	my $data = $xml->XMLout($hashref);
	
	return $data;
}

sub outputTestCasesInJSFormat{
	my ($filePath, $onlyManual);
	($filePath, $onlyManual) = @_;

	# read XML file
	my $data = &readXml($filePath);
	
	#print Dumper ($data);
	
	my $domStr;
	#print suits
	
	#print ref ($data->{suite});
	if(keys(%{$data->{suite}}) > 0){
		#$domStr.="<ul>";
		my $suitDom = $data->{suite};
		#foreach suit
		my @sortedSuits = sort (keys(%$suitDom));
		foreach (@sortedSuits){
			my $setDom = $suitDom->{$_}->{set};
			if(keys(%$setDom) > 0){
				$domStr.= "<li title=\"suit\">$_";
				#foreach set
				$domStr.="<ul>";
				my @sortedSets = sort (keys(%$setDom));
				foreach(@sortedSets){
					my $caseDom = $setDom->{$_}->{case};
					if(keys(%$caseDom) > 0){
						$domStr.= "<li title=\"set\">$_";
						$domStr.="<ul>";
						my @sortedCases = sort (keys(%$caseDom));
						foreach(@sortedCases){
							if($onlyManual){
								my $thisCase = $caseDom->{$_};
								if($thisCase->{'manual'} eq 'true'){
									$domStr.= "<li title=\"case\">$_</li>";
								}
							}else{
								$domStr.= "<li title=\"case\">$_</li>";
							}
						}
						$domStr.="</ul>";
					}else{
						$domStr.= "<li title=\"set\">$_";
					}
					$domStr.= "</li>";
				}
				$domStr.="</ul>";
			}else{
				$domStr.= "<li title=\"suit\">$_";
			}			
			$domStr.= "</li>";
		}
		#$domStr.="</ul>";
	}
	
	$TestKitLogger::logger->log(message =>  "Scaning XML result: \n$domStr");
	return $domStr;
}

our $M_PASS_STR = "PASS";
our $M_FAIL_STR = "FAIL";
our $M_NA_STR = "N/A";
our $M_SUM_STR = "SUM";

sub getPackageStatus{
	my ($xmlPath) = @_;
	
	if($xmlPath){
		my $xmlRef = &readXml($xmlPath);
		return &sumStatus($xmlRef);
	}
}

sub sumStatus{
	my ($xmlRef) = @_;
	my $pass_num = 0; 
	my $fail_num = 0;
	my $na_num = 0;
	my $sum_num = 0;
	my %summary;

	my $type = ref ($xmlRef);
	
	if( $type eq "HASH"){
		my $suiteType = ref ($xmlRef->{suite});
		if( $suiteType eq "HASH"){
			my $suitesRef = $xmlRef->{suite};
			foreach (keys (%$suitesRef)){
				my $setType = ref ($suitesRef->{$_}->{set});
				if( $setType eq "HASH"){
					my $setsRef = $suitesRef->{$_}->{set};
					foreach (keys (%$setsRef)){
						my $caseType = ref ($setsRef->{$_}->{case});
						if( $caseType eq "HASH"){
							my $casesRef = $setsRef->{$_}->{case};
							foreach (keys (%$casesRef)){
								my $thisCase = $casesRef->{$_};
								
								if($thisCase->{result}){
									if($thisCase->{manual} eq "true"){
										my $thisStatus = $thisCase->{result};
										$sum_num++;
										if($thisStatus eq $M_PASS_STR){
											$pass_num++;
										}elsif ($thisStatus eq $M_FAIL_STR){
											$fail_num++;
										}elsif ($thisStatus eq $M_NA_STR){
											$na_num++;
										}
									}
								}
								
							}
						}
					}
				}
			}
		}
	}
	
	$summary{$M_PASS_STR} = $pass_num;
	$summary{$M_FAIL_STR} = $fail_num;
	$summary{$M_NA_STR} = $na_num;
	$summary{$M_SUM_STR} = $sum_num;
	
	return \%summary;
}

1;
