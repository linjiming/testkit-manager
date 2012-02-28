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
#

package Scanfolder;

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(dynamicScanFolders dynamicScanManualcaseFolders);
@EXPORT_OK = qw();

use strict;
use warnings;
use File::Find;
use TestXmlParser;

use TestKitLogger;

# Function for dynamically scanning the folder structure of testsuits
# 
# Author: Joey.

my $testSuitesPath;
my $testResultPath;
my %full_testsuites_dom;
my %full_testresult_dom;

my $pathKey = "\$path";

sub scanSubDom {
	my ($refSubDom, $this, $child, $refFolders, $wholePath);
	($refSubDom, $this, $refFolders, $wholePath) = @_;
	
	if(@$refFolders > 0){
		$child = shift(@$refFolders);
		#print "Enter scanSubDom, this=$this, child=$child\n";
		#my @logkeys = keys %{$refSubDom};
		#print "The keys of subDom is @logkeys\n";
	
		my $tempSubSubDom;
	
		if(exists ${$refSubDom}{$this}){
			$tempSubSubDom = $$refSubDom{$this};
		
			#my @temp = keys %{$refSubDom};
			#print "Keys: @temp; \t Child: $child\t This: $this\n";
		
			if(!exists ${$tempSubSubDom}{$child}){
				my %emptyHash;
				${$tempSubSubDom}{$child} = \%emptyHash;
				$this = $child;
				
				#@logkeys = keys %{$tempSubSubDom};
				#print "The keys of updated subDom is @logkeys\n";
			
				&scanSubDom($tempSubSubDom, $this, $refFolders, $wholePath);
			}else{
				#print "The key\"$this\" already exists, check sub-folder!";
				$this = $child;
				&scanSubDom($tempSubSubDom, $this, $refFolders, $wholePath);
			}
		}
		else{
			my %emptyHash;
			${$refSubDom}{$this}={$child=>\%emptyHash};
			$tempSubSubDom = $$refSubDom{$this};
			$this = $child;
			
			#@logkeys = keys %{$tempSubSubDom};
			#print "The keys of updated subDom is @logkeys\n";
			
			&scanSubDom($tempSubSubDom, $this, $refFolders, $wholePath);
		}
		#@logkeys = keys %{$tempSubSubDom};
		#print "The updated Keys: @logkeys\n";
	}
	else{
		my %emptyHash;
		${$refSubDom}{$this}={$pathKey=>$wholePath};
	}
}

sub getPackageName {
	if($_ =~ /^tests\.xml$/){
		my $relative = $File::Find::dir;
		my $wholePath = $File::Find::name;
		$relative=~s/$testSuitesPath//g;
		
		my @folders = split("\/", $relative);
		my $this = shift(@folders);
		
		&scanSubDom(\%full_testsuites_dom, $this, \@folders, $wholePath);
	}
}

sub outputDom{
	
	sub outputDom;
	
	my ($subDom, $onlyManual) = @_;
	
	my @keyArray = keys(%$subDom);
	my $domStr;
	
	if(keys(%$subDom) > 0){
		$domStr.="<ul>";
		my @sortedKeys = sort (keys(%$subDom));
		foreach (@sortedKeys){
			my $subsubDom = $$subDom{$_};
			if( ref ($subsubDom) ne "HASH"){
					$domStr.= &outputTestCasesInJSFormat($subsubDom, $onlyManual);
			}
			else{
				if(keys(%$subsubDom) > 0){
					my @subKeys = keys(%$subsubDom);
					if(ref ($$subsubDom{$subKeys[0]}) ne  "HASH"){
						$domStr.= "<li title=\"package\">$_";
					}else{
						$domStr.= "<li title=\"folder\">$_";				
					}
					$domStr.= &outputDom($subsubDom, $onlyManual);
				}else{
					$domStr.= "<li title=\"folder\">$_";
				}
				$domStr.= "</li>";
			}
		}
		$domStr.= "</ul>";
	}
	
	$TestKitLogger::logger->log(message =>  "Whole Tree XML:$domStr\n");
	return $domStr;
}

sub dynamicScanFolders {
	my ($onlyManual) = @_;
	$testSuitesPath = "/usr/share/";
	%full_testsuites_dom=();
	
	find(\&getPackageName, $testSuitesPath);
	
	return &outputDom(\%full_testsuites_dom, $onlyManual);
}

sub readSelectedPackages{
	my $profile_path;
	($profile_path) = @_;
	$TestKitLogger::logger->log(message =>  "\n[Parsing Selected Packages] Enter the method 'readSelectedPackages' parameters: $profile_path\n");
	my @packages;
	if (open(FILE, $profile_path)) {
		while (<FILE>) {
			my $line = $_;
			if ($line !~ s/(\[Auto\]|\[Manual\])// ){
				$line =~ s/\n//g;
				$line =~ s/(.w)\/(.w)/$1/g;
				push (@packages, $line);
			}
		}
		
		$TestKitLogger::logger->log(message =>  "\n[Scan folder]:The packages:@packages\n");
		close(FILE);
	}else{
		$TestKitLogger::logger->log(message =>  "\n[Scan folder]:Fail to read the profile:$profile_path\n");
	}
	
	return \@packages;
}

sub dynamicScanManualcaseFolders {
	my ($profilePath) = @_;
	if($profilePath){
		my $packagesRef = &readSelectedPackages($profilePath);
		$testSuitesPath = "/usr/share/";
		%full_testsuites_dom=();
	
		find(\&getPackageName, $testSuitesPath);
		
		foreach (keys %full_testsuites_dom){
			my $thisPackage = $_;
			my $isSelected = 0;
			foreach (@$packagesRef){
				if($thisPackage eq $_ ){
					$isSelected = 1;
					last;
				}
			}
			
			if(!$isSelected){
				delete ($full_testsuites_dom{$thisPackage});
			}
		}
		
		return &outputDom(\%full_testsuites_dom, 1);
	}
}


1;
