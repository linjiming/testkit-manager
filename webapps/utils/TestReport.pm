#!/usr/bin/perl -w

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

package TestReport;
use strict;
use Fcntl qw/:flock :seek/;
use FindBin;
use Error;
use Common;
use Misc;
use FileHandle;
use TestKitLogger;

# Export symbols
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
        &rebuild_report	
	);

push @EXPORT, @Error::EXPORT;

# Parse auto test result autotest.res
sub parseAutoResult{
        my ($result_dir) = @_;
        my $auto = {}; 

        $auto->{'total'} = 0;
        $auto->{'pass'} = 0;
        $auto->{'fail'} = 0;
        $auto->{'manual_case'} = 0;
		$auto->{'notrun'} = 0;
        #$auto->{'block'} = 0;
        $auto->{'details'} = "";

        if(-f $result_dir."/auto_summary"){
            my $fh = new FileHandle($result_dir."/auto_summary");
            my $line = "";
            #my $details = "";
            foreach $line (<$fh>){
                if($line =~ /\/usr\/share\/(.*)\/.*\.xml\s+XML\s+(\d+)\s+(\d+)\s+(\d+)/){
					my $packageName = $1;
                      my $pass = $2;
                      my $fail = $3;
					  my $na = $4;
					  my $total = $pass + $fail;
					
                      $auto->{'total'} += $total;
                      $auto->{'pass'} += $pass;
                      $auto->{'fail'} += $fail;
                      $auto->{'manual_case'} += $na;
				}
            }
            #$auto->{'details'} = $details;
            $fh->close();
        }
		#$TestKitLogger::logger->log(message =>  "Preparing reading auto_summary_htm from $result_dir");
		#if(-f $result_dir."/auto_summary_htm"){
		#	my $fh = new FileHandle($result_dir."/auto_summary_htm");
        #    my $line = "";
		#	my $details = "";
		#	foreach $line (<$fh>){
		#		$details .= $line;
		#	}
		#	$auto->{'details'} = $details;
		#	#$TestKitLogger::logger->log(message =>  "HTML:\n$auto->{'details'} ");
        #    $fh->close();
		#}
        return $auto;
}

#parse manual test result manualtest.res
sub parseManualResult{
        my ($result_dir) = @_;
        my $manual = {}; 
        
        $manual->{'total'} = 0;
        $manual->{'pass'} = 0;
        $manual->{'fail'} = 0;
        $manual->{'notrun'} = 0;
        $manual->{'details'} = "";
        #$manual->{'block'} = 0;

       if(-f $result_dir."/manual_summary"){
            my $fh = new FileHandle($result_dir."/manual_summary");
            my $line = "";
            my $details ="";
            foreach $line (<$fh>){
                $details = $details.$line;
                #if($line =~ /(.*)(\s+)(.*)(\s+)(PASS|FAIL|NotRun|BLOCK)/){
				if($line =~ /^\[TOTAL\]\s+PASS:(.*)\s+FAIL:(.*)\s+N\/A:(.*)\s+Sum:(.*)/){
                      $manual->{'pass'} = $1; 
                      $manual->{'fail'} = $2; 
                      $manual->{'notrun'} =$3; 
                      #$manual->{'block'} += 1 if($result eq "BLOCK");
                      $manual->{'total'} =$4;
                }
            }   
            $manual->{'details'} = $details;
            $fh->close();
        }
       
        return $manual;
}

# Function for writing Perl->HTML->JS templates.
# Input argument is a text variable containing HTML template code.
# The function converts it into a JS single-quotes string representing the
# appropriate HTML layout which can be passed into elem.innerHTML or so.
# <<<smth>>> patterns contain plain JS code snippets and are put into the resultant
# JS code unchanged (surrounded with '+' string operator).
# Also, compactification is performed (excessive spaces and newlines are removed).
# Starting and trailing quotes are not added.
#
# Example: html_compact("<b>Item No. '<<<x['1']>>>'</b>") eq "<b>Item No.\'' + x['1'] + '\'</b>";
# Known issue: additional "+ ''" is added to the end of the line.
sub html_compact($) {
	my ($html) = @_;
	$html =~ s/\n\s*//g;
	my @parts = split(/<<<|>>>/, $html);
	my $raw_js = 0;
	foreach my $part (@parts) {
		if ($raw_js) {
			$part .= ' + \'';
		}
		else {
			$part =~ s/\'/\\\'/g;
			$part .= '\' + ';
		}
		$raw_js = !$raw_js;
	}
	return join('', @parts).'\'';
}


sub rebuild_report {
     my ($report, $testid_dir, $profile_path) = @_;
     if($testid_dir && -d $testid_dir) {
       my $result_dir = $testid_dir;

       my $testid = $result_dir;
       $testid =~ s/(.*)\/results\///g;

       my $auto = parseAutoResult($result_dir);
       my $manual = parseManualResult($result_dir);
	   
	   if($manual->{'total'} eq 0){
		$manual->{'notrun'} = $auto->{'manual_case'};
		$manual->{'total'} =$auto->{'manual_case'};
	   }
	   

       my $total={};
       $total->{'pass'} =  $auto->{'pass'}+$manual->{'pass'};
       $total->{'fail'} =  $auto->{'fail'}+$manual->{'fail'};
       #$total->{'block'} =  $manual->{'block'};
       $total->{'notrun'} = $auto->{'notrun'}+$manual->{'notrun'}; 
       $total->{'total'} = $auto->{'total'}+$manual->{'total'};

       my $color={};
       $color->{'totalpass'} = $total->{'pass'} > 0 ? '#008000':'BLACK'; 
       $color->{'autopass'} = $auto->{'pass'} > 0 ? '#008000':'BLACK';  
       $color->{'manualpass'} = $manual->{'pass'} > 0 ? '#008000':'BLACK'; 
        
       $color->{'totalfail'} = $total->{'fail'} > 0 ? '#FF0000':'BLACK'; 
       $color->{'autofail'} = $auto->{'fail'} > 0 ? '#FF0000':'BLACK';  
       $color->{'manualfail'} = $manual->{'fail'} > 0 ? '#FF0000':'BLACK'; 
        
       $color->{'totalnotrun'} = $total->{'notrun'} > 0 ? '#CCCC00':'BLACK'; 
       $color->{'autonotrun'} = $auto->{'notrun'} > 0 ? '#CCCC00':'BLACK'; 
       $color->{'manualnotrun'} = $manual->{'notrun'} > 0 ? '#CCCC00':'BLACK'; 

       #$color->{'totalblock'} = $total->{'block'} > 0 ? '#CCFFFF': 'BLACK';
       #$color->{'autoblock'} = $auto->{'block'} > 0 ? '#CCFFFF': 'BLACK';
       #$color->{'manualblock'} = $manual->{'block'} > 0 ? '#CCFFFF': 'BLACK';

       my @values;
       my @colors;
		
		#, $total->{'block'}
       @values = (
             [ "", "PASS", "FAIL", "NOT RUN", "SUM" ],
             ["TOTAL", $total->{'pass'}, $total->{'fail'}, $total->{'notrun'}, $total->{'total'} ],
             ["AUTO TEST", $auto->{'pass'}, $auto->{'fail'}, $auto->{'notrun'}, $auto->{'total'} ],
             ["MANUAL TEST", $manual->{'pass'}, $manual->{'fail'}, $manual->{'notrun'}, $manual->{'total'} ]
       );     

       @colors = (
             [ "BLACK", "BLACK", "BLACK","BLACK","BLACK","BLACK" ],
             [ "BLACK", $color->{'totalpass'}, $color->{'totalfail'}, $color->{'totalnotrun'}, "BLACK" ],
             [ "BLACK", $color->{'autopass'}, $color->{'autofail'}, $color->{'autonotrun'}, "BLACK" ],
             [ "BLACK", $color->{'manualpass'}, $color->{'manualfail'}, $color->{'manualnotrun'}, "BLACK" ]
       );
	   
	   my $detail_tree_html = "";
	   if($profile_path){
			use ParseResult;
			my $packageResults = &readProfileResults($profile_path, $result_dir);
			
			my @sortedPackages = sort(@$packageResults);
			foreach (@sortedPackages){
				my $resultPath = $_;
				$resultPath =~ s/\/usr\/share/$result_dir/;
				my @resultXmlPathArray = split("\/", $resultPath);
				
				pop(@resultXmlPathArray);
				my $pkg_name = pop(@resultXmlPathArray);
				$TestKitLogger::logger->log(message =>  "Reading result XML, path: $resultPath");
				use TestXmlParser;
				$detail_tree_html .= &generatePackageResultHtml($resultPath, $pkg_name);
				no TestXmlParser;
			}
		}
		
		my $test_tree_code = '<div id="treeDiv1"><ul><li><B><font size="2">Test Result per Package ( Total | <font color="GREEN">Pass</font> | <font color="RED">Fail</font> | <font color="#CCCC00">NotRun</font> )</font></B></li>';
		#$test_tree_code .= $auto->{'details'}.'</ul></div>';
		$test_tree_code .= $detail_tree_html.'</ul></div>';
		#$TestKitLogger::logger->log(message =>  "Uncompacted HTML:\n$test_tree_code");
		$test_tree_code = html_compact($test_tree_code);
		#$TestKitLogger::logger->log(message =>  "Compacted HTML:\n$test_tree_code");
       my $data =<<DATA;

<table cellpadding="0" cellspacing="0" width="1021" height="690">
		  <!-- MSTableType="layout" -->
		  <tr>
		       <td height="1">
			    <img alt="" width="1" height="1" src="images/MsSpacer.gif">
		       </td>
		  </tr>
		  <tr>
	               <td width="1">
			    <img alt="" width="1" height="1" src="images/MsSpacer.gif">
		       </td>
 
		       <td valign="top">
		       <table cellpadding="0" cellspacing="0" width="1020" height="26" id="table94">
				<!-- MSTableType="layout" -->
				<tr>
					<td valign="middle" bgcolor="#333333" width="447">
					<font size="1" face="Arial" color="#FFFFFF">&nbsp;</font></td>
					<td valign="middle" bgcolor="#333333" width="424">
					</td>
					<td valign="middle" bgcolor="#333333" width="148"></td>
					<td width="1" height="26"></td>
					</tr>
			</table>
			<table cellpadding="0" cellspacing="0" id="table95" width="1020" height="503">
				<!-- MSTableType="layout" -->
				<tr>
					<td valign="top" height="503" width="1020">
					<table cellpadding="0" cellspacing="0" border="0" width="100%" height="100%" id="table96">
						<!-- MSCellFormattingTableID="36" -->
						<tr>
							<td valign="top" width="100%" height="100%">
							<!-- MSCellFormattingType="content" -->
							<table cellpadding="0" cellspacing="0" id="table138" width="1019" height="503">
	<!-- MSTableType="layout" -->
	<tr>
		<td valign="top" height="503" width="1019">
		<table cellpadding="0" cellspacing="0" border="0" width="100%" height="100%" id="table139">
			<!-- MSCellFormattingTableID="36" -->
			<tr>
				<td valign="top" width="100%" height="100%">
				<!-- MSCellFormattingType="content" -->
				<table cellpadding="0" cellspacing="0" width="1019" height="30" id="table140">
	<!-- MSTableType="layout" -->
	<tr>
		<td valign="middle" height="30" width="1019">
		<table cellpadding="0" cellspacing="0" border="0" width="100%" height="100%">
			<!-- MSCellFormattingTableID="33" -->
			<tr>
				<td bgcolor="#FFFFFF" height="1">
				<img alt="" width="1" height="1" src="MsSpacer.gif"></td>
			</tr>
			<tr>
				<td valign="middle" bgcolor="#808080" height="100%" width="100%">
				<!-- MSCellFormattingType="content" -->
				<b><font face="Arial" size="2">&nbsp;<font color="#FFFFFF"> 
DATA
       $data = $data."Test Report - $testid";
       $data = $data.<<DATA;
		        	</font></font></b></td>
			</tr>
		</table>
		</td>
	</tr>
				</table>
DATA
		#Comment outputing the user's profile.
        #$data = $data.userprofile($result_dir);
        $data = $data.<<DATA;
				<table cellpadding="0" cellspacing="0" width="1019" height="20" id="table144">
					<!-- MSTableType="layout" -->
					<tr>
						<td valign="top" height="20" width="1019">
						<table cellpadding="0" cellspacing="0" border="0" width="100%" height="100%" id="table145">
							<!-- MSCellFormattingTableID="2" -->
							<tr>
								<td bgcolor="#FFFFFF" width="1">
								<img alt="" width="1" height="1" src="MsSpacer.gif"></td>
								<td valign="top" bgcolor="#CCCCCC" width="100%">
								<!-- MSCellFormattingType="content" -->
								<font size="2" face="Arial"><b>&nbsp;TEST 
								SUMMARY</b></font></td>
								<td bgcolor="#FFFFFF" height="100%" width="1">
								<img alt="" width="1" height="1" src="MsSpacer.gif"></td>
							</tr>
							<tr>
								<td bgcolor="#FFFFFF" colspan="3" height="1">
								<img alt="" width="1" height="1" src="MsSpacer.gif"></td>
							</tr>
						</table>
						</td>
					</tr>
				</table>
                                <!-- table cellpadding="0" cellspacing="0" width="1018" height="150" id="table146" -->
								<table cellpadding="0" cellspacing="0" width="509" height="80" id="table146">

DATA
        my $i = 0;
        for $i (0 .. $#values ){
                my $j = 0;
                $data = $data.<<DATA;
                <!-- MSTableType="layout" -->
		<tr>
	        <td></td>
DATA
                for $j ( 0 .. $#{$values[$i]} ) {
                    $data = $data.<<DATA;
                                               <td valign="top" align="center">
						<table cellpadding="0" cellspacing="0" border="0" width="103" height="100%" id="table147">
							<!-- MSCellFormattingTableID="3" -->
							<tr>
                                                                <td bgcolor="#333333" width="1"><b>
								<img alt="" width="1" height="1" src="MsSpacer.gif"></td>
							</tr>
							<tr>
								<td bgcolor="#333333" width="1">
								<img alt="" width="1" height="1" src="MsSpacer.gif"></td>
DATA
                    $data = $data."<td valign=\"top\" width=\"100%\" bgcolor=\"WHITE\" >";
                    $data = $data.<<DATA;
						<!--		<td valign="top" width="100%"> -->
								<!-- MSCellFormattingType="content" -->
                                                                <font size="2" face="Arial" color=\"$colors[$i][$j]\" > 
DATA
                    $data = $data.$values[$i][$j];
                    $data = $data.<<DATA;
                                                                </font>
								</td>
								<td bgcolor="#333333" height="100%" width="1">
								<img alt="" width="1" height="1" src="MsSpacer.gif"></td>
							</tr>
							<tr>
								<td bgcolor="#333333" colspan="3" height="1">
								<img alt="" width="1" height="1" src="MsSpacer.gif"></td>
							</tr>
						</table>
						</td>
DATA
                }
                $data = $data."</tr>";
        } 

        $data = $data.<<DATA;
<tr>
						<td width="1"></td>
						<td width="204"></td>
						<td width="203"></td>
						<td width="203"></td>
						<td width="203"></td>
						<td height="1" width="204"></td>
					</tr>
				</table>
				
				<table cellpadding="0" cellspacing="0" border="0" id="table171" width="1018" height="20">
					<!-- MSTableType="layout" -->
					<tr>
						<td valign="top" height="100%" width="1018">
						<table cellpadding="0" cellspacing="0" border="0" width="100%" height="100%">
							<!-- MSCellFormattingTableID="34" -->
							<tr>
								<td bgcolor="#333333" width="1">
								<!-- img alt="" width="1" height="1" src="MsSpacer.gif" --></td>
								<td valign="top" width="100%">
								<!-- MSCellFormattingType="content" -->
								<input type="submit" value="VIEW HISTORY" name="B17" onClick="window.location='tests_results.pl'" />
								<input type="submit" value="VIEW TEST LOG" name="B15" onClick="window.location='tests_report.pl?details=$testid\&log=1'" />
DATA
         #my $mail = `grep "E-mail:" $result_dir/profile.user`;
         #$mail =~ s/E-mail: //g;
         #$mail = quotemeta($mail);
		 
		 if($manual->{'total'} > 0){
			my $isManualFinished = `grep "Manual: Finished" $result_dir/test_status -c`;
			$TestKitLogger::logger->log(message =>  "The manual test is finished? $isManualFinished");
								
			if($isManualFinished eq "" or $isManualFinished == "0"){
				$data = $data.<<DATA;
				<input type="submit" value="RUN MAUNLAL TEST" name="B16" onClick="window.location='tests_appbat.pl?test_run=$testid'"/>
DATA
			}
		}
		else{
			if (open (NEW_FILE, ">$result_dir/test_status")) {
				print NEW_FILE "Auto: Finished\nManual: None";
				close(NEW_FILE);
			}
		}
		$data = $data.<<DATA;
								
								<!-- font color="#FFFFFF">
									<input type="submit" value="SEND REPORT" name="B11" onClick="window.location='tests_report.pl?details=$testid\&send=\$mail'"" >
								</font -->
								</td>
								<td bgcolor="#333333" height="100%" width="1">
								<!-- img alt="" width="1" height="1" src="MsSpacer.gif" --></td>
							</tr>
						</table>
						</td>
					</tr>
					<tr><td height="1" >&nbsp;</td></tr>
				</table>
				
					<table cellpadding="0" cellspacing="0" width="1019" height="20" id="table167">
					<!-- MSTableType="layout" -->
					<tr>
						<td valign="middle" height="20" width="1019">
						<table cellpadding="0" cellspacing="0" border="0" width="100%" height="100%" id="table168">
							<!-- MSCellFormattingTableID="26" -->							
							<tr>
								<td valign="middle" bgcolor="#CCCCCC" height="100%">
								<!-- MSCellFormattingType="content" -->
								<b><font size="2" face="Arial">&nbsp;DETAILS</font></b></td>
							</tr>
							<tr>
								<td bgcolor="#FFFFFF" height="1" width="100%">
								<img alt="" width="1" height="1" src="MsSpacer.gif"></td>
							</tr>
						</table>
						</td>
					</tr>
				</table>
				<table cellpadding="0" cellspacing="0" width="1018" height="220" id="table169">
					<!-- MSTableType="layout" -->
					<tr>
						<td valign="top" width="1018" height="200">
						<!-- MSCellFormattingTableID="29" -->
						<table cellpadding="0" cellspacing="0" border="0" width="100%" height="100%" id="table170">
							
							<tr>
								<td bgcolor="#333333" colspan="3" height="1">
								<img alt="" width="1" height="1" src="MsSpacer.gif"></td>
							</tr>
							<tr>
								<td bgcolor="#333333" width="1">
								<img alt="" width="1" height="1" src="MsSpacer.gif"></td>
								<td valign="top" width="100%">
								<div id="tree_details"></div>
DATA
                    #$data = $data.$auto->{'details'};
					#."\n".$manual->{'details'}
                    $data = $data.<<DATA;
								</td>
						        	<td bgcolor="#333333" height="100%" width="1">
								<img alt="" width="1" height="1" src="MsSpacer.gif"></td>
							</tr>
							<tr>
								<td bgcolor="#333333" colspan="3" height="1">
								<img alt="" width="1" height="1" src="MsSpacer.gif"></td>
							</tr>
						</table>
						</td>
					</tr>
				</table>
				
	</td>
				</tr>
		</table>
		</td>
	</tr>
</table>
	</td>
							</tr>
					</table>
					</td>
				</tr>
			</table>
			</td>
		</tr>
</table>
<script type="text/javascript">
var getNodePath = function(node) {
	var path = "";
	if (node.depth > 1) {
		for ( var i = 0; i < (node.depth); i++) {
			path = path + node.getAncestor(i).label + "/";
		}
		path = path + node.label;
	} else {
		if (node.depth == 1) {
			path = path + node.parent.label + "/";
		}
		path = path + node.label;
	}
	return path;
};

var onPackageClick = function(packageName){
	//alert('load_result_xml.pl?pkg=' + packageName + '&testId=$testid');
	window.open('load_result_xml.pl?pkg=' + packageName + '&testId=$testid');
};
</script>
<script type="text/javascript">
	var treediv_html = '$test_tree_code';
	var div = document.getElementById('tree_details');
	div.innerHTML = treediv_html;
	tree = new YAHOO.widget.TreeView(document.getElementById("treeDiv1"));
	tree.draw();
</script>

DATA
            write_string_as_file($result_dir."/".$report, $data);

            my $test_summary = <<DATA;
                     \tPASS          \tFAIL          \tNot Run         
Total:               \t$total->{'pass'}        \t$total->{'fail'}         \t$total->{'notrun'} 
Auto Test:           \t$auto->{'pass'}        \t$auto->{'fail'}          \t$auto->{'notrun'}
Manual Test:          \t$manual->{'pass'}        \t$manual->{'fail'}         \t$manual->{'notrun'}  
DATA
            write_string_as_file($result_dir."/test_summary", $test_summary);

        }elsif($testid_dir && !(-d $testid_dir)){
            warning "testrun_id folder $testid_dir does not exists, can not create report!\n";
        }

}



#get user profile
sub userprofile {
        my ($result_dir) = @_;
        my $testid = ""; 
        my $name = "";
        my $org = "";
        my $email = "";
        my $sku = "";

        if(-f $result_dir."/profile.user"){
             my $fh = new FileHandle($result_dir."/profile.user"); 
             my $line;
             
             $testid = $result_dir; 
             $testid =~ s/(.*)\/results\///g;

             foreach $line (<$fh>){
                 if($line =~ /Name: (.*)/){
                      $name = $1;
                 }
                 elsif($line =~ /Orgnazation: (.*)/){
                      $org = $1;
                 } 
                 elsif($line =~ /E-mail: (.*)/){
                      $email = $1;
                 } 
                 if($line =~ /SKU: (.*)/){
                      $sku = $1;
                 } 
             }
             $fh->close();  
        }
       
        my $testinfo =<<DATA;
<table cellpadding="0" cellspacing="0" width="1019" height="20" id="table141">
					<!-- MSTableType="layout" -->
					<tr>
						<td valign="middle" height="20" width="1019">
						<table cellpadding="0" cellspacing="0" border="0" id="table142" width="100%" height="100%">
							<!-- MSCellFormattingTableID="1" -->
							<tr>
								<td bgcolor="#FFFFFF" height="1">
								<img alt="" width="1" height="1" src="MsSpacer.gif"></td>
							</tr>
							<tr>
								<td valign="middle" bgcolor="#CCCCCC" height="100%">
								<!-- MSCellFormattingType="content" -->
								<font size="2" face="Arial">&nbsp;<b>USER 
								PROFILE</b></font></td>
							</tr>
							<tr>
								<td bgcolor="#FFFFFF" height="1" width="100%">
								<img alt="" width="1" height="1" src="MsSpacer.gif"></td>
							</tr>
						</table>
						</td>
					</tr>
				</table>
				<table cellpadding="0" cellspacing="0" id="table143" width="1019" height="81">
					<!-- MSTableType="layout" -->
					<tr>
						<td></td>
						<td valign="middle">
						<table cellpadding="0" cellspacing="0" border="0" width="100%" height="100%">
							<!-- MSCellFormattingTableID="9" -->
							<tr>
								<td bgcolor="#333333" colspan="2" height="1">
								<img alt="" width="1" height="1" src="MsSpacer.gif"></td>
							</tr>
							<tr>
								<td bgcolor="#333333" width="1">
								<img alt="" width="1" height="1" src="MsSpacer.gif"></td>
								<td valign="middle" height="100%" width="100%">
								<!-- MSCellFormattingType="content" -->
								<font size="2" face="Arial">&nbsp;Test 
								ID</font></td>
							</tr>
						</table>
						</td>
						<td valign="top">
						<table cellpadding="0" cellspacing="0" border="0" width="100%" height="100%">
							<!-- MSCellFormattingTableID="10" -->
							<tr>
								<td bgcolor="#333333" colspan="2" height="1">
								<img alt="" width="1" height="1" src="MsSpacer.gif"></td>
							</tr>
							<tr>
								<td valign="top" width="100%">
								<!-- MSCellFormattingType="content" -->
								<font face="Arial" size="2">&nbsp;
DATA
            $testinfo = $testinfo.$testid;
            $testinfo = $testinfo.<<DATA;
                                                               </font></td>
								<td bgcolor="#333333" height="100%" width="1">
								<img alt="" width="1" height="1" src="MsSpacer.gif"></td>
							</tr>
						</table>
						</td>
						<td height="20"></td>
					</tr>
					<tr>
						<td></td>
						<td valign="top">
						<table cellpadding="0" cellspacing="0" border="0" width="100%" height="100%">
							<!-- MSCellFormattingTableID="30" -->
							<tr>
								<td bgcolor="#333333" width="1">
								<img alt="" width="1" height="1" src="MsSpacer.gif"></td>
								<td valign="top" height="100%" width="100%">
								<!-- MSCellFormattingType="content" -->
								<font size="2" face="Arial">&nbsp;Organization</font></td>
							</tr>
						</table>
						</td>
						<td valign="top">
						<table cellpadding="0" cellspacing="0" border="0" width="100%" height="100%">
							<!-- MSCellFormattingTableID="11" -->
							<tr>
								<td valign="top" width="100%">
								<!-- MSCellFormattingType="content" -->
								<font face="Arial" size="2">&nbsp;
DATA
            $testinfo = $testinfo.$org;
            $testinfo = $testinfo.<<DATA;
                                                                </font></td>
								<td bgcolor="#333333" height="100%" width="1">
								<img alt="" width="1" height="1" src="MsSpacer.gif"></td>
							</tr>
						</table>
						</td>
						<td height="20"></td>
					</tr>
					<tr>
						<td></td>
						<td valign="top">
						<table cellpadding="0" cellspacing="0" border="0" width="100%" height="100%">
							<!-- MSCellFormattingTableID="31" -->
							<tr>
								<td bgcolor="#333333" width="1">
								<img alt="" width="1" height="1" src="MsSpacer.gif"></td>
								<td valign="top" height="100%" width="100%">
								<!-- MSCellFormattingType="content" -->
								<font size="2" face="Arial">&nbsp;Email</font></td>
							</tr>
						</table>
						</td>
						<td valign="top">
						<table cellpadding="0" cellspacing="0" border="0" width="100%" height="100%">
							<!-- MSCellFormattingTableID="27" -->
							<tr>
								<td valign="top" width="100%">
								<!-- MSCellFormattingType="content" -->
								<font face="Arial" size="2">&nbsp;
DATA
            $testinfo = $testinfo.$email;
            $testinfo = $testinfo.<<DATA;
                                                                </font></td>
								<td bgcolor="#333333" height="100%" width="1">
								<img alt="" width="1" height="1" src="MsSpacer.gif"></td>
							</tr>
						</table>
						</td>
						<td height="20"></td>
					</tr>
					<tr>
						<td></td>
						<td valign="top">
						<table cellpadding="0" cellspacing="0" border="0" width="100%" height="100%">
							<!-- MSCellFormattingTableID="32" -->
							<tr>
								<td bgcolor="#333333" width="1">
								<img alt="" width="1" height="1" src="MsSpacer.gif"></td>
								<td valign="top" height="100%" width="100%">
								<!-- MSCellFormattingType="content" -->
								<font size="2" face="Arial">&nbsp;SKU</font></td>
							</tr>
							<tr>
								<td bgcolor="#333333" colspan="2" height="1">
								<img alt="" width="1" height="1" src="MsSpacer.gif"></td>
							</tr>
						</table>
						</td>
						<td valign="top">
						<table cellpadding="0" cellspacing="0" border="0" width="100%" height="100%">
							<!-- MSCellFormattingTableID="28" -->
							<tr>
								<td valign="top" width="100%">
								<!-- MSCellFormattingType="content" -->
								<font face="Arial" size="2">&nbsp;
DATA
            $testinfo = $testinfo.$sku;
            $testinfo = $testinfo.<<DATA;
                                                                </font></td>
								<td bgcolor="#333333" height="100%" width="1">
								<img alt="" width="1" height="1" src="MsSpacer.gif"></td>
							</tr>
							<tr>
								<td bgcolor="#333333" colspan="2" height="1">
								<img alt="" width="1" height="1" src="MsSpacer.gif"></td>
							</tr>
						</table>
						</td>
					</tr>
				</table>
DATA
 
        return $testinfo;
}

;#return value
