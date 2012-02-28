#!/usr/bin/perl -w

# Distribution Checker
# 
# Copyright (C) 2007-2009 The Linux Foundation. All rights reserved.
#
# This program has been developed by ISP RAS for LF.
# The ptyshell tool is originally written by Jiri Dluhos <jdluhos@suse.cz>
# Copyright (C) 2005-2007 SuSE Linux Products GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 2 as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
#
#   Changlog:
#			07/16/2010, 
#			Move the JavaScript codes to a JS-format file 'run_test.js' by Tang, Shao-Feng <shaofeng.tang@intel.com>.
#			Remove the user-profile related codes by Tang, Shao-Feng <shaofeng.tang@intel.com>.
#

use Templates;
use UserProfile;
use Fcntl qw/:flock :seek/;
use TestKitLogger;

autoflush_on();

if ($_POST{'compare'}) {
	my @dirs = ();
	if (open(FILE, $CONFIG{'RESULTS_DIR'}.'/HISTORY')) {
		flock(FILE, LOCK_SH);
		while (<FILE>) {
			s/[\r\n]//g;
			next if ($_ eq '');
			next if (m/\//);
			my $path = $CONFIG{'RESULTS_DIR'}.'/'.$_;
			if (-d $path) {
				if (defined($_POST{$_})) {
					push @dirs, $path;
				}
			}
		}
		flock(FILE, LOCK_UN);
		close(FILE);
		
		if (scalar(@dirs) < 2) {
			# Can't compare less than 2 results. Should not happen, but...
			print 'HTTP/1.0 302 Moved' . CRLF . 'Location: tests_results.pl' . CRLF . CRLF;
		}
		else {
			print 'HTTP/1.0 200 OK' . CRLF;
			print 'Content-type: text/html' . CRLF . CRLF;
			
			print_header('Test Results', 'results');
			
			system($CONFIG{'TESTS_DIR'}."/jdiff.pl --webui --link 'tests_results.pl?details=' -r ".join(' ', map shq($_), @dirs));
			
			print_footer();
		}
	}
	else {
		print 'HTTP/1.0 302 Moved' . CRLF . 'Location: tests_results.pl' . CRLF . CRLF;
		print STDERR "Cannot open HISTORY file: $!\n";
	}
	exit;
}
#$TestKitLogger::logger->log(message =>  "Entering tests_results.pl");
if ($_POST{'remove'}) {
	$TestKitLogger::logger->log(message =>  "Removing Reports :POST_Remove");
	if (open(FILE, '+>>'.$CONFIG{'RESULTS_DIR'}.'/HISTORY')) {
		flock(FILE, LOCK_EX);
		seek(FILE, 0, SEEK_SET);
		while(<FILE>) {
			s/[\r\n]//g;
			next if ($_ eq '');
			next if (m/\//);
			my $path = $CONFIG{'RESULTS_DIR'}.'/'.$_;
			
			$TestKitLogger::logger->log(message =>  "Removing Reports :$path");
			if (-d $path) {
				if (defined($_POST{$_})) {
					system("rm -rf $path");
				}
				else {
					push @list, $_;
				}
			}
		}
		seek(FILE, 0, SEEK_SET);
		truncate(FILE, 0);
		print FILE join("\n", @list)."\n";
		flock(FILE, LOCK_UN);
		close(FILE);
	}
	else {
		print STDERR "Cannot open HISTORY file: $!\n";
	}
	print 'HTTP/1.0 302 Moved' . CRLF . 'Location: tests_results.pl' . CRLF . CRLF;
	exit;
}

if ($_GET{'generate'}) {
	system($CONFIG{'TESTS_DIR'}.'/dist-checker.pl --keep --report '.$CONFIG{'RESULTS_DIR'}.'/'.$_GET{'generate'}.' >/dev/null');
	print 'HTTP/1.0 302 Moved' . CRLF . 'Location: tests_results.pl?details='.$_GET{'generate'}.'&summary=1' . CRLF . CRLF;
	exit;
}

sub print_integration_stuff($$) {
	my ($file_location, $certification) = @_;

	return if ($file_location =~ m/^\s*$/);

	my $cert_system_base_addr = "http://$cert_sys_host$cert_sys_base";
	my $cert_system_welcome_addr = $cert_system_base_addr.'welcome_cert.php';

	my $link_title = 'Upload the test results';
	if ($certification) {
		print '<p>You can easily apply for certification by uploading the test results to the <a href="'.$cert_system_welcome_addr.'">Certification System</a> for audit. Just click the button below and follow the instructions.</p>';

		$link_title = 'Apply for certification';
	}
	else {
		print '<p>You can easily upload these test results to the <a href="'.$cert_system_welcome_addr.'">Certification System</a>.</p>';
	}

	print '<p>[<a href="cert_integration.pl?start='.$file_location.'">'.$link_title.'</a>]</p>';
}

# Formats the table cell for a specific set of tests.
# Arg1 - test result:  1 - passed;
#                      0 - failed;
#                     -1 - incomplete;
#                     -2 - not selected.
# Arg2 - name of the test set.
sub format_line($$) {
	my ($test_res, $test_name) = @_;
	my $res = '';
	$res .= '<td width="100"'.(($test_res == -2) ? ' style="color: #7f7f7f;"' : '')."><b>$test_name</b></td>\n";
	if ($test_res == -2) {
		$res .= '<td style="text-align: center; color: #7f7f7f; background-color: #e0e0e0;"><b>NOT SELECTED</b></td>';
	}
	elsif ($test_res == -1) {
		$res .= '    <td style="text-align: center; color: #000000; background-color: #ffff00;"><b><a href="tests_appbat.pl?test_run='.$_GET{'details'}.'" style="color: #000000;" title="Run '.$test_name.'">NOT FINISHED YET</a></b></td>';
	}
	elsif ($test_res == 0) {
		$res .= '<td style="text-align: center; color: #ffffff; background-color: #ff0000;"><b>FAILED</b></td>';
	}
	elsif ($test_res == 1) {
		$res .= '    <td style="width: 100px; text-align: center; color: #000000; background-color: #00ff00;"><b>PASSED</b></td>';
	}
	return $res;
}

print 'HTTP/1.0 200 OK' . CRLF;
print 'Content-type: text/html' . CRLF . CRLF;

if ($_GET{'details'}) {
	my $result_dir = $CONFIG{'RESULTS_DIR'}.'/'.$_GET{'details'};
	if ($_GET{'summary'}) {
		my $auto_verdict = -2;
		my $man_verdict = -2;
		
		my $tester_name = '';
		my $organization = '';
		my $std_version = $DEFAULT_STANDARD_VER;
		my $certification_mode = 0;
		my $host_os = '';
		my $host_platform = '';
		
		my $runconfig = read_config($result_dir.'/runconfig');
		if (is_ok($runconfig)) {
			$std_version = $runconfig->{'STANDARD'} if ($runconfig->{'STANDARD'});
			$host_os = $runconfig->{'HOST_OS'} if ($runconfig->{'HOST_OS'});
			$host_platform = $runconfig->{'HOST_machine'} if ($runconfig->{'HOST_machine'});
			$tester_name = $runconfig->{'TESTER_NAME'} if ($runconfig->{'TESTER_NAME'});
			$organization = $runconfig->{'ORGANIZATION'} if ($runconfig->{'ORGANIZATION'});
		}
		if (open(INFO, $result_dir.'/INFO')) {
			while (<INFO>) {
				if (m/^Verdict:\s*(.*)/i) {
					if (($1 eq 'Passed') or ($1 eq 'Warning')) {
						$auto_verdict = 1;
					}
					elsif ($1 eq 'Failed') {
						$auto_verdict = 0;
					}
					elsif ($1 eq 'Incomplete') {
						$auto_verdict = -1;
					}
				}
				if (m/^Verdict-manual:\s*(.*)/i) {
					if ($1 eq 'Passed') {
						$man_verdict = 1;
					}
					elsif ($1 eq 'Failed') {
						$man_verdict = 0;
					}
					elsif ($1 eq 'Incomplete') {
						$man_verdict = -1;
					}
				}
				elsif (m/^Certification/i) {
					$certification_mode = 1;
				}
			}
			close(INFO);
		}

		print_header('Test Results', 'sumreport');

		my $email_body = "Body= Name: $tester_name;\n Organization: $organization;\n OS: $host_os;\n Architecture: $host_platform;\n Standard: $std_version";
		$email_body =~ s/ /%20/g;
		$email_body =~ s/[\r\n]/%0A/g;

		my $show_date = $_GET{'details'};
		$show_date =~ s/^.*\-([^\-]*)\-([^\-]*)\-([^\-]*)\-([^\-]*)h\-([^\-]*)m\-([^\-]*)s/$3.$2.$1&nbsp;$4:$5:$6/;

		my $line_auto = format_line($auto_verdict, 'Automatic Tests');
		my $line_man = format_line($man_verdict, 'Manual Tests');

		print <<DATA;
<h1>Summary Report for Test Run of $show_date</h1>

<h2>Test Execution Status</h2>
<table class="main" width="350">
  <tr>
    $line_auto
    <td valign="middle" rowspan="2"><a href="tests_report.pl?details=$_GET{'details'}">View detailed report</a></td>
  </tr>
  <tr>
    $line_man
  </tr>
</table>
DATA

		if ($man_verdict == -1) {
			print "<p align=\"justify\">The manual tests are not executed yet. You can <a href=\"tests_appbat.pl?test_run=$_GET{'details'}\"><b>run them now</b></a>.</p>\n";
		}

		if (($man_verdict == 0) or ($auto_verdict == 0)) {
			print <<DATA;
<h2>Analyze the Failing Tests</h2>
<p align="justify">
Please analyze the <a href="tests_results.pl?details=$_GET{'details'}"><b>detailed report</b></a>
to understand the reasons of each fail and classify them into the following groups:</p>
<ol>
<li><b>Confirmed FAILs</b>, which are due to the real inconsistencies of your system with the standard. To continue with the certification, you have to fix your implementation to remedy such FAILs and then rerun the tests again.</li>
<li><b>False FAILs</b>, which you believe are due to the incorrect tests.
Please report such FAILs to the <a href="mailto:lf_lsbcert\@lists.linuxfoundation.org?Subject=False%20positive%20FAIL&amp;$email_body">lf_lsbcert\@lists.linuxfoundation.org</a> list.
If the problem reported is confirmed you will be granted a <i>waiver</i> so the test failure will not affect your ability to certify.</li>
<li><b>Unknown FAILs</b>, which you have no idea about. Please ask help at the <a href="mailto:lf_lsbcert\@lists.linuxfoundation.org?Subject=Unknown%20FAIL&amp;$email_body">lf_lsbcert\@lists.linuxfoundation.org</a> list.</li>
</ol>
<p align="justify"><b>Note:</b> only test results with all the FAILs waived are eligible for certification.</p>
DATA
		}

		print <<DATA;
<h2>Locating Test Journals</h2>
<p align="justify">You can find the consolidated test journals of this test run at the following path (click to download to another location):<br />
<a href="get.pl$result_dir/$_GET{'details'}.tgz">$result_dir/$_GET{'details'}.tgz</a><br />
You need to attach them when applying for certification or when communicating with the support staff.</p>
DATA
		if ($MTK_BRANCH eq 'LSB') {
			if ($certification_mode and ($man_verdict != -1)) {
				print <<DATA;
<h2>Apply for Certification</h2>
<p align="justify">With all the tests performed successfully, you may apply for certification. 

</p>
<p align="justify">Organizational details of the certification procedure are described at the <a href="http://www.linuxfoundation.org/en/Certification" target="_blank">Certification Home Page</a>.</p>
DATA
			}

			if ($certification_mode and ($man_verdict != -1)) {
				# Good certification results
				print_integration_stuff($_GET{'details'}, 1);
			} else {
				# Non-applicable for certification results.
				print_integration_stuff($_GET{'details'}, 0);
			}
}

		print <<DATA;
<h2>Viewing this Page Again</h2>
<p align="justify">This page has been saved as a part of the test run results. You may view it at any time by clicking particular test result at the <a href="tests_results.pl">Results</a> page.</p>
DATA
	}
	else {
		# Detailed results
		my $fips_file = $result_dir.'/results/fips';
		my $need_repack = 0;
		my $results_tarball = $result_dir.'/'.$_GET{'details'}.'.tgz';
		if (-f $fips_file) {
			my $fips_mtime = (stat($fips_file))[9];
			my $tgz_mtime = (stat($results_tarball))[9];
			if (!$tgz_mtime || $fips_mtime > $tgz_mtime) {
				$need_repack = 1;
			}
		}
		
		print_header('Test Results', 'detreport');
		print <<HEREDOC;
<div id="ajax_loading" style="display: none; position: fixed; width: 13em; height: 5.8em; top: 40%; left: 50%; margin-top: -2.9em; margin-left: -7.5em; border: solid 1px #00007f; background-color: #e7f0ff; text-align: center; padding: 6px;"><div align="center">
Please, wait...<br />
<img src="images/environment-spacer.gif" width="1" height="5" alt="" /><br />
<img src="images/ajax_progress.gif" width="16" height="16" alt="" /><br />
<img src="images/environment-spacer.gif" width="1" height="7" alt="" /><br />
<input type="button" name="ajax_abort" id="ajax_abort" value="Abort" style="border: solid 1px #00007f; background: #e0e0ff; color: blue; width: 6em;" onclick="javascript:onAbort();" />
</div></div>

<script language="javascript" type="text/javascript">
// <![CDATA[

preload_images(new Array('ajax_progress.gif', 'environment-spacer.gif'));
timeout_show_progress = -1; // This timeout is for background saving after choosing pass/fail.

var fip_need_repack = $need_repack;
var webui_details = '$_GET{'details'}';
var results_tarball = '$results_tarball';

function ajaxProcessResult(responseXML) {
	if (responseXML.getElementsByTagName('updated').length > 0) {
		fip_need_repack = 1;
		if (typeof(fip_update_header) != 'undefined')
			fip_update_header();
	}
	if (responseXML.getElementsByTagName('repacked').length > 0) {
		fip_need_repack = 0;
		if (typeof(fip_update_header) != 'undefined')
			fip_update_header();
	}
}
// ]]>
</script>

HEREDOC
		if (open(FILE, $result_dir.'/report.htm')) {
			my $transfer = 0;
			while (<FILE>) {
				if (m/<body>/) {
					s/^.*<body>\n?//i;
					$transfer = 1;
				}
				if ($transfer) {
					s/(<\/body>|<\/html>)\n?//i;
					print $_;
				}
			}
			close(FILE);
		}
		else {
			print "<b><font color=\"red\">Sorry, the report '".$_GET{'details'}."' cannot be opened!</font><br />\nReason: $!</b>\n";
		}

		# Load results/fips and fill FIP forms.
		my $fips_data = {};
		# Read FIPs data from the file
		if (-f $fips_file && open(my $fh, $fips_file)) {
			flock($fh, LOCK_SH);
			my $testcase = undef;
			while (my $line = <$fh>) {
				chomp $line;
				if ($line =~ m/^TESTCASE:\s*(.*)/) {
					$testcase = $1;
				}
				elsif ($line =~ m/^RESULT:\s*(.*)/) {
					$fips_data->{$testcase}{'RESULT'} = $1;
				}
				elsif ($line =~ m/^COMMENT:\s*(.*)/) {
					local $_;
					$_ .= (defined($_) ? "\n" : '').$1 for $fips_data->{$testcase}{'COMMENT'};
				}
			}
			flock($fh, LOCK_UN);
			close $fh;
		}

		# Fill FIP forms with previously saved data via JS
		print <<HEREDOC;
<script language="javascript" type="text/javascript">
// <![CDATA[
HEREDOC
		if (%$fips_data) {
			print "var fip_results = Array();\n";
			print "var fip_comments = Array();\n";
			foreach my $testcase (sort keys %$fips_data) {
				if ($fips_data->{$testcase}{'RESULT'}) {
					my $result = $fips_data->{$testcase}{'RESULT'};
					($result eq 'pass' || $result eq 'fail') or next;
					print "fip_results['$testcase'] = \"".$result."\";\n";
				}
				if ($fips_data->{$testcase}{'COMMENT'}) {
					my $comment = $fips_data->{$testcase}{'COMMENT'};
					$comment =~ s/(?:\r\n?|\n)/\\n/g;
					$comment =~ s/\"/&quot;/g;
					# TODO: better escaping?
					print "fip_comments['$testcase'] = \"".$comment."\";\n";
				}
			}

			print "fip_update_form();\n";
		}
		print <<HEREDOC;
if (typeof(fip_update_header) != 'undefined')
	fip_update_header();

// ]]>
</script>
HEREDOC
	} # end of 'Detailed Results' page
}
else {
	print_header('Test Results', 'results');

	print <<DATA;

<!-- elva: <h1>Test Results</h1> -->
<!-- tina changed for UI
<h1>Test Reports</h1>
-->


<!-- elva: delete
<input type="submit" name="remove" id="remove_button1" value="Remove Selected Entries" disabled="disabled" onclick='javascript:return confirm_remove();' /><img src="images/environment-spacer.gif" alt="" width="15" height="1" /><input type="submit" name="compare" id="compare_button1" value="Compare Selected Results" disabled="disabled" onclick="javascript:return confirm_compare();" />
end of delete-->
<!-- tina changed for UI
<br /><br />
-->
<table cellpadding="0" cellspacing="0" width="1020" id="table_bartop">
  <tr>
  <td height="1">
    <img alt="" width="1" height="1" src="images/MsSpacer.gif">
  </td>
  </tr>
  <tr>
  <td width="1">
    <img alt="" width="1" height="1" src="images/MsSpacer.gif">
  </td>
  <td height="26" valign="top" bgcolor="#333333" width="766">
  </td>
  </tr>
</table>
<form method="post" action="tests_results.pl" name="results_list">
<table class="main">
  <tr>
  <td><input type="checkbox" name="check_all" id="check_all" onclick="javascript:check_uncheck_all();" /></td>

<!-- elva: add more columns -->
<!-- tina changed for UI
    <th style="width: 14em;">Date/Time</th>
    <th style="width: 14em;">Tester</th>
    <th style="width: 14em;">SKU</th>
    <th style="width: 14em;">Summary</th>
    <th style="width: 14em;">Status</th>
  </tr>
-->
<!-- tina: draw barmiddle -->
    <th style="width: 189; background: #A9A9A9; font-size:10px; color: #ffffff">DATE/TIME</th>
    <!-- th style="width: 189; background: #A9A9A9; font-size:10px; color: #ffffff">TESTER</th>
    <th style="width: 189; background: #A9A9A9; font-size:10px; color: #ffffff">SKU</th -->
    <th style="width: 378; background: #A9A9A9; font-size:10px; color: #ffffff">SUMMARY</th>
    <th style="width: 378; background: #A9A9A9; font-size:10px; color: #ffffff">STATUS</th>
  </tr>


DATA

	my @list = ();
	if (open(FILE, '+>>'.$CONFIG{'RESULTS_DIR'}.'/HISTORY')) {
		flock(FILE, LOCK_EX);
		seek(FILE, 0, SEEK_SET);
		while(<FILE>) {
			s/[\r\n]//g;
			next if ($_ eq '');
			push @list, $_ if (-d $CONFIG{'RESULTS_DIR'}.'/'.$_);
		}
		seek(FILE, 0, SEEK_SET);
		truncate(FILE, 0);
		print FILE join("\n", @list)."\n";
		flock(FILE, LOCK_UN);
		close(FILE);
		@list = reverse(@list);
		foreach my $name (@list) {
			my @summary = ();
			my @comment = ();
#elva: add
			my @username = ();
			my @teststatus = ();
			my @sku = ();
			my $auto_fail = -1;
			my $man_fail = -1;
			my $inprogress = 0;
			my $certification = 0;
			my $filling_summary = 1;
#elva: need update      if (open(FILE, $CONFIG{'RESULTS_DIR'}.'/'.$name.'/INFO')) {
			if (open(FILE, $CONFIG{'RESULTS_DIR'}.'/'.$name.'/test_summary')) {
				while (<FILE>) {
					s/&/&amp;/g;
					s/</&lt;/g;
					s/>/&gt;/g;
					s/[\r\n]//g;
					if ($filling_summary) {
						if ($_ eq '') {
							$filling_summary = 0;
						}
						else {
							if (m/^Verdict: (\S+)/i) {
								if (($1 eq 'Success') or ($1 eq 'Warning')) {
									$auto_fail = 0;
								}
								elsif ($1 eq 'Failed') {
									$auto_fail = 1;
								}
							}
							elsif (m/^Verdict-manual:\s*(.*)/i) {
								if ($1 eq 'Passed') {
									$man_fail = 0;
								}
								elsif ($1 eq 'Failed') {
									$man_fail = 1;
								}
								elsif ($1 eq 'Incomplete') {
									$inprogress = 1;
								}
							}
							elsif (m/^Certification/i) {
								$certification = 1;
							}
							else {
								# Align numbers by right side (6 digits max)
								#s/^(\d+) /('&nbsp;'x(6-length($1))).$1.' '/e;
								s/^ /&nbsp;/;
								push @summary, $_;
							}
						}
					}
					else {
						push @comment, $_;
					}
				}
				close(FILE);
			}

#elva: add
                        if (open(FILE, $CONFIG{'RESULTS_DIR'}.'/'.$name.'/profile.user')) {
                        	while (<FILE>) {
                                	if (m/^Name: (\S+)/i) {
                                        	push @username, $1;
                                        }
                                        elsif (m/^SKU: (\S+)/i) {
						push @sku, $1;
                                        }
               				else {
						push @comment, $_;
					}


                              	}
                        }
                        close(FILE);

			my $jusername = join('<br />', @username);
			$jusername = '&nbsp;' if ($jusername eq '');
			
			my $jsku = join('<br />', @sku);
			$jsku = '&nbsp;' if ($jsku eq '');
#elva: end of adding	

#elva: add

			if (open(FILE, $CONFIG{'RESULTS_DIR'}.'/'.$name.'/test_status')) {
                                while (<FILE>) {
                                                push @teststatus, $_;
                                        }


                        }
                        close(FILE);

                        my $jteststatus = join('<br />', @teststatus);
                        $jteststatus = '&nbsp;' if ($jteststatus eq '');

#elva: end of adding
		
			my $jsummary = join('<br />', @summary);
			$jsummary = '&nbsp;' if ($jsummary eq '');
			my $jcomment = join('<br />', @comment);
			if ($jcomment eq '') {
				$jcomment = '&nbsp;';
			}
			my $image = '';
			my $img_alt = '';
			my $manual_tests = '';
			my $img_float = '';
			if (($auto_fail == -1) and ($man_fail == -1)) {
				if ($jsummary =~ m/\bfailed\b/si) {
					$auto_fail = 1;
				}
				elsif ($jsummary =~ m/\bpassed\b/si) {
					$auto_fail = 0;
				}
			}
			$img_alt .= ($certification ? 'Cert' : 'Tests');
			$img_alt .= ((($auto_fail == 1) or ($man_fail == 1)) ? 'Failed' : 'Passed');
			$img_alt .= ($inprogress ? 'Gray' : '');
			$image = "$img_alt.png";
			if ($inprogress) {
				$manual_tests = '<a href="tests_appbat.pl?test_run='.$name.'" title="Run manual tests"><img src="images/run_manual.png" alt="Manual" width="16" height="16" /></a>&nbsp;';
			}
			my $show_name = $name;
			$show_name =~ s/^.*\-([^\-]*)\-([^\-]*)\-([^\-]*)\-([^\-]*)h\-([^\-]*)m\-([^\-]*)s/$3.$2.$1&nbsp;$4:$5:$6/;
			print <<DATA;
  <tr>

<!--elva: update -->
    <td rowspan="3"><input type='checkbox' name='$name' onclick='javascript:update_state();' /></td>
<!--elva    <td rowspan="1" style="border-bottom: none;"><img src="images/environment-spacer.gif" width="1" height="16" alt="" /></td>
-->
    <td rowspan="1" style="border-bottom: none;"><img src="images/environment-spacer.gif" width="1" height="16" alt="" /></td>
    <!-- td rowspan="3" style="text-align: center; font-size:12px;">$jusername</td>
    <td rowspan="3" style="text-align: center; font-size:12px;">$jsku</td -->
    <td rowspan="3" style="font-size:12px;">$jsummary</td>
    <td rowspan="3" style="text-align: center; font-size:12px;">$jteststatus</td>

<!--elva: remove
    <td rowspan="3" style="text-align: center; vertical-align: middle;" width="5" height="5">
      <a href="tests_results.pl?details=$name" title="Delete this test report"><img src="images/DeleteReport.png" alt="Details"/></a>
    </td>
    <td rowspan="3" style="text-align: center; vertical-align: middle;" width="5" height="5">
      <a href="tests_results.pl?details=$name" title="Send this test report"><img src="images/SendReport.png" alt="Details"/></a>    
    </td>
-->
  </tr>
  <tr>
    <td valign="middle" style="border: none;">
<!--elva update     <img src="images/$image" alt="$img_alt" width="33" height="30" />&nbsp;<a href="tests_results.pl?details=$name&amp;summary=1" class='link-level2'>$show_name</a>
-->
      <a href="tests_report.pl?details=$name" class='link-level2'>$show_name</a>
   </td>
  </tr>
  <tr>
    <td style="border: none; text-align: right; vertical-align: bottom;" width="5" height="5">
<!--elva: delete      $manual_tests<a href="tests_results.pl?details=$name" title="Show detailed report"><img src="images/report_details.gif" alt="Details" width="16" height="16" /></a>&nbsp;<a href="tests_results.pl?details=$name&amp;summary=1" title="Show summary report"><img src="images/report_summary.gif" alt="Summary" width="16" height="16" /></a>
elva: end of delete-->
    </td>
  </tr>
DATA
		}
	}
	print <<DATA;
</table>
<br />

<input type="submit" name="remove" id="remove_button2" value="DELETE REPORT" disabled="disabled" onclick='javascript:return confirm_remove();' /><img src="images/environment-spacer.gif" alt="" width="15" height="1" /><!-- input type="hidden" name="compare" id="compare_button2" value="SEND REPORT" disabled="disabled" onclick="javascript:return confirm_compare();" / -->
</form>

<script language="javascript" type="text/javascript">
// <![CDATA[
function count_checked() {
	var num = 0;
	var form = document.results_list;
	for (var i=0; i<form.length; ++i) {
		if ((form[i].type.toLowerCase() == 'checkbox') && (form[i].name != 'check_all') && form[i].checked) {
			++num;
		}
	}
	return num;
}

function update_state() {
	var button;
	var num_checked = count_checked();
	for (var i = 1; i <= 2; ++i) {
		button = document.getElementById('remove_button' + i);
		if (button) {
			button.disabled = (num_checked == 0);
		}
		button = document.getElementById('compare_button' + i);
		if (button) {
			button.disabled = (num_checked < 2);
		}
	}
}

function check_uncheck(box, check) {
	temp = box.onchange;
	box.onchange = null;
	box.checked = check;
	box.onchange = temp;
}

function check_uncheck_all() {
	var elem = document.getElementById('check_all');
	if (elem) {
		var checked = elem.checked;
		var form = document.results_list;
		for (var i=0; i<form.length; ++i) {
			if ((form[i].type.toLowerCase() == 'checkbox') && (form[i].name != 'check_all'))
				check_uncheck(form[i], checked);
		}
		update_state();
	}
}

function confirm_remove() {
	var num = count_checked();
	if (num == 0) {
		alert('Nothing selected!');
		return false;
	}
	else
		return confirm('Do you wish to delete ' + num + ' selected report(s)?');
}

function confirm_compare() {
	var num = count_checked();
	if (num < 2) {
		alert('At least two results should be selected!');
		return false;
	}
	else
		return true;
}
// ]]>
</script>
DATA
}

print_footer();

