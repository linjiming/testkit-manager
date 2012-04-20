#!/usr/bin/perl -w

# Distribution Checker
# Get File Module (get.pl)
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
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

use Templates;
use TestKitLogger;

sub report_error($$) {
	my $code = $_[0];
	my $msg = $_[1];
	print "HTTP/1.0 $code" . CRLF . 'Content-Type: text/html' . CRLF . CRLF;
	print <<DATA;
<html>
<head>
<title>$code</title>
</head>
<body>
<h1>$code</h1>
<p><br>
$msg</p>
</body>
</html>
DATA
	exit;
}

my $APP_BIN = $SERVER_PARAM{'DOCUMENT_ROOT'};
$APP_BIN =~ s!/[^/]+/[^/]+$!!;

if (!$_GET{'file'}) {
	report_error('403 Forbidden', 'File name is not specified.');
}

if (($_GET{'file'} =~ m/[\/\\]\.\.+[\/\\]/) or
	($_GET{'file'} =~ m/[\/\\]\.\.+$/) or
	($_GET{'file'} =~ m/^\.\.+[\/\\]/)) {
	report_error('403 Forbidden', "File path cannot contain '<b>..</b>'.");
}

my $directPath = $SERVER_PARAM{'APP_DATA'};
$TestKitLogger::logger->log(message =>  "The SERVER_PARAM('APP_DATA'): $directPath");
$directPath =~ s/webapps\/webui\/\.\.\/\.\.//g;
$directPath_result = $directPath . "results";
$directPath .= "log";
$TestKitLogger::logger->log(message =>  "The $directPath: $directPath");
if (($_GET{'file'} !~ m!^\Q$SERVER_PARAM{'APP_DATA'}\E/results/!) and
	($_GET{'file'} !~ m!^\Q$SERVER_PARAM{'APP_DATA'}\E/log/!) and
	($_GET{'file'} !~ m!^\Q$SERVER_PARAM{'APP_DATA'}\E/data/!) and
	($_GET{'file'} !~ m!^\Q$APP_BIN\E/!) and 
	($_GET{'file'} !~ m!^\Q$directPath_result\E/!) and 
	($_GET{'file'} !~ m!^\Q/opt\E/!) and 
	($_GET{'file'} !~ m!^\Q$directPath\E/!)) {
	report_error('403 Forbidden', 'Access denied. Only specific directories can be accessed.');
}

if (-d $_GET{'file'}) {
	report_error('403 Forbidden', 'Directory listing denied.');
}

if (!-f $_GET{'file'}) {
	report_error('404 Not Found', 'The file requested is not found.');
}

if (open(FILE, $_GET{'file'})) {
	my $ext = ($_GET{'file'} =~ m/^.*\.([^\.]*)$/) ? $1 : '';
	my $sz = -s $_GET{'file'};
	my $mime_type;
	my $found = 0;
	if (open(EXT_INFO, $SERVER_PARAM{'DOCUMENT_ROOT'}.'/../mime.types')) {
		my $ln;
		while (defined($ln = <EXT_INFO>) and !$found) {
			if ($ln =~ m/^[^\s#]/) {
				$ln =~ s/[\r\n]//g;
				my ($read_type, @read_exts) = split(/\s+/, $ln);
				foreach (@read_exts) {
					if ($_ eq $ext) {
						$mime_type = $read_type;
						$found = 1;
						last;
					}
				}
			}
		}
		close(EXT_INFO);
	}
	$mime_type = 'text/plain' if (!$found);
	if (defined $_GET{'line'} && $mime_type eq 'text/plain') {
		$mime_type = 'text/html';
		print 'HTTP/1.0 200 OK' . CRLF . "Content-Type: $mime_type" . CRLF . CRLF;
		print '<html><body><pre>';
		while (<FILE>) {
			s/&/&amp;/g;
			s/</&lt;/g;
			s/>/&gt;/g;
			if ($_GET{'line'} eq $.) {
				print '<a name="line'.$..'"></a>'; # drop anchor
				print '<span style="background: #ffff00;">';
				print $_;
				print '</span>';
			}
			else {
				print $_;
			}
		}
		print '</pre></body></html>';
	}
	else {
		my $filename = $_GET{'file'};
		$filename =~ s!^.*/([^/]+)$!$1!;
		my $disp_type = ($_GET{'download'} ? 'attachment' : 'inline');
		print 'HTTP/1.0 200 OK' . CRLF;
		print 'Content-Type: ' . $mime_type . CRLF;
		print 'Content-Length: ' . $sz . CRLF;
		print 'Content-Disposition: ' . $disp_type . '; filename=' . $filename . CRLF;
		print CRLF;
		while (<FILE>) {
			print $_;
		}
	}
	close(FILE);
}
else {
	report_error('403 Forbidden', "Error opening the file:<br />$!");
}
