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
use FileHandle;
use TestKitLogger;

autoflush_on();

if($_GET{'generate'}){
	my $thisTestId = $_GET{'details'};
	my $profile_path = $CONFIG{'TESTS_DIR'}.'/../../results/'.$thisTestId.'/profile.auto';
	$TestKitLogger::logger->log(message =>  "\nEnter test_report.generate, Path:$profile_path\n");
    system($CONFIG{'TESTS_DIR'}."/testkit_lite_start.pl --report report.htm --not-run -t $thisTestId -f $profile_path >/dev/null");
}

if($_GET{'send'}){
      system($CONFIG{'TESTS_DIR'}.'/testkit_lite_start.pl --mail-to '.$_GET{'send'}.' --not-run -t '.$_GET{'details'}.' >/dev/null');
}

print "HTTP/1.0 200 OK" . CRLF;
print "Content-type: text/html" . CRLF . CRLF;

#my $default_user = $SERVER_PARAM{'APP_DATA'}.'/profiles/user/user.profile';
#my $user = 'Guest';
#if (!open (MYFILE, $default_user)) {
#        $error_text = "Could not obtain user!<br />($!) \n";
#}
#else {
#        while (<MYFILE>) {
#                if ($_ =~ /^Name:\s+(.*)/)
#                {
#                        $user = $1;
#                        last;
#                }
#        }
#     }
print_header("$MTK_BRANCH Testkit", "");

sub process_output($) {
        return 0 if ($_[0] eq '');
        my $newln_pos = rindex($_[0], "\n");
        my $res_size = length($_[0]);
        if ($newln_pos != -1) {
                # Convert Windows-style line endings to Unix-style
                $_[0] =~ s/\r\n/\n/g;
                my @lines = split(m/^/m, $_[0]);
                for (my $i = 1; $i < scalar(@lines); ++$i) {
                        # Make every ^M control character (\x0d) erase all from the beginning of line
                        while (($lines[$i] =~ s/^[^\x0d]*\x0d//sg) > 0) {}
                        # Make every ^H control character (\x08) erase the previous character (if present)
                        while (($lines[$i] =~ s/[^\x08]\x08//sg) > 0) {}
                        # Remove remaining ^H characters in the beginning of line (if there were some excessive)
                        $lines[$i] =~ s/^\x08+//s;
                }
                $_[0] = join('', @lines);
        }
        $_[0] =~ s/[\x00-\x08\x0b-\x0c\x0e-\x1f]/./g;           # Remaining control characters replaced with dots (XML parser cannot stand them)
        $_[0] =~ s/]]>/]]>]]&gt;<![CDATA[/g;                    # Escape ]]> which would close CDATA block otherwise
        $_[0] =~ s/\x0d/]]>&#13;<![CDATA[/g;                    # Escape remaining ^M characters - else they come to browser as ^J
        return $res_size;
}

my $file = ""; 
if($_GET{'log'}){
       $file = $CONFIG{'RESULTS_DIR'}.'/'.$_GET{'details'}.'/log';
}
else{
       $file = $CONFIG{'RESULTS_DIR'}.'/'.$_GET{'details'}.'/report.htm';
}


if(-f $file){
      my $fh = new FileHandle($file);

      my $file_data = "";
      my $filesize = -s $file; 
      my $sz = read($fh, $file_data, $filesize);
      process_output($file_data);

      if($_GET{"log"}){
	print <<DATA;
  <table cellpadding="0" cellspacing="0" width="1020" height="27">
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
  <td>
  <table cellpadding="0" cellspacing="0" width="100%" height="100%" bgcolor="#333333" >
  <tr><td></td></tr>
  </table> 
  </td>
  </tr>
  </table>

  <table color="#333333">
  <tr>
  <td>
  Log - $_GET{'details'}
  </td>
  </tr>
  <tr><td></td></tr>
  <tr>
  <td>
                <textarea cols="120" rows="30" id="details" style="color:black;font-size:12px" readonly="readonly">
		$file_data;
		</textarea>
  </td>
  </tr>
  <tr>
  <td>
                <FORM><INPUT type="button" value="Back to Report" name="viewreport" onClick="window.location='tests_report.pl?details=$_GET{details}'"/></FORM>
 </td>
  </tr>
  </table>
DATA
      }
      else{
        print $file_data;
      }

      $fh->close();
}
else{
       print 'Can not open file '.$file;
}

print_footer();

exit 0;

