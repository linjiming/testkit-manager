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
package ProcessSummary;

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(generateManualSummary getSelectedPackages);
@EXPORT_OK = qw();

use strict;
use warnings;
use File::Find;
use TestXmlParser;
use Data::Dumper;

use TestKitLogger;

sub getSelectedPackages{
	my($resultPath) = @_;
	$TestKitLogger::logger->log(message =>  "\n[Generate Summary] Enter the method 'readProfile' parameters: $resultPath\n");
	my $profile_path = $resultPath."/profile.auto";
	
	my (@selectedpkgs);
	if (open(FILE, $profile_path)) {
		while (<FILE>) {
			my $line = $_;
			if ($line !~ s/(\[Auto\]|\[Manual\])// ){
				$line =~ s/\n//g;
				push (@selectedpkgs, $line);
			}
		}
		close(FILE);
		$TestKitLogger::logger->log(message =>  "[Generate Summary] Result files: \n".Dumper( @selectedpkgs));
	}else{
		$TestKitLogger::logger->log(message =>  "[Generate Summary]:Fail to read the profile:$profile_path");
	}
	
	return \@selectedpkgs;
}

# If all manual cases are finished, return 0; else return the number of 'N/A' case.
sub generateManualSummary{
	my($resultPath) = @_;
	
	if($resultPath){
		my %summary;
		$summary{$TestXmlParser::M_PASS_STR} = 0;
		$summary{$TestXmlParser::M_FAIL_STR} = 0;
		$summary{$TestXmlParser::M_NA_STR} = 0;
		$summary{$TestXmlParser::M_SUM_STR} = 0;
		my $pakRef = &getSelectedPackages($resultPath);
		my $sumfilePath = $resultPath."/manual_summary";
		$TestKitLogger::logger->log(message =>  "\n[Generate Summary]: Summary File: $sumfilePath\nSelected Packages:".Dumper $pakRef);
		if($pakRef){
			if (open (my $fh, ">$sumfilePath")) {
				foreach (@$pakRef){
					my $xmlPath = $resultPath."/".$_."/result.tests.xml";
					my $pakSumRef = &getPackageStatus($xmlPath);
				
					$summary{$TestXmlParser::M_PASS_STR} += $$pakSumRef{$TestXmlParser::M_PASS_STR};
					$summary{$TestXmlParser::M_FAIL_STR} += $$pakSumRef{$TestXmlParser::M_FAIL_STR};
					$summary{$TestXmlParser::M_NA_STR} += $$pakSumRef{$TestXmlParser::M_NA_STR};
					$summary{$TestXmlParser::M_SUM_STR} += $$pakSumRef{$TestXmlParser::M_SUM_STR};
					
					if($$pakSumRef{$TestXmlParser::M_SUM_STR}){
						$TestKitLogger::logger->log(message =>  "\n[Generate Summary]: Writing below msg into manual_summary\n"."Package: ".$_.":\t".$$pakSumRef{$TestXmlParser::M_PASS_STR}."\t".$$pakSumRef{$TestXmlParser::M_FAIL_STR}."\t".$$pakSumRef{$TestXmlParser::M_NA_STR}."\t".$$pakSumRef{$TestXmlParser::M_SUM_STR}."\n");
						print $fh "[Package]".$_.":\tPASS:".$$pakSumRef{$TestXmlParser::M_PASS_STR}."\tFAIL:".$$pakSumRef{$TestXmlParser::M_FAIL_STR}."\tN/A:".$$pakSumRef{$TestXmlParser::M_NA_STR}."\tSum:".$$pakSumRef{$TestXmlParser::M_SUM_STR}."\n";
					}
					
				}
				print $fh "[TOTAL] PASS:".$summary{$TestXmlParser::M_PASS_STR}."\tFAIL:".$summary{$TestXmlParser::M_FAIL_STR}."\tN/A:".$summary{$TestXmlParser::M_NA_STR}."\tSum:".$summary{$TestXmlParser::M_SUM_STR};
				close($fh);
			}else {
				$TestKitLogger::logger->log(message =>  "[Generate Summary]: Fail to open $sumfilePath to output!");
			}
		}
		
		return $summary{$TestXmlParser::M_NA_STR};
	} else{
		return -1;
	}
}

1;