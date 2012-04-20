# Distribution Checker
# Auxilary Stuff (Misc.pm)
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

package Misc;

use strict;
use MIME::Base64 qw(encode_base64);
use Common;

# Export symbols
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
 
	$globals $host_info
	
	&ask_for_password &backup_and_replace &myprint
	&print_log &print_vlog &sendmail
	&status_updated
	&suggest_packages &missing_packages_message
	
	@all_warnings
	&print_stderr
);

push @EXPORT, @Common::EXPORT; # Re-export Common
push @EXPORT, @Error::EXPORT; # Re-export Error

#==== Global variables ================================================

# verbose level: (-v[0-2] option)
#   0 - minimal. Only error messages are put into stderr; 
#   1 - default; 
#   2 - extended debug information.
#
our $verbose_lvl = 1;
$verbose_lvl = 2 if DEBUG;
# Shouldn't be used in code!
# Use debug_inform() function instead of it.

# Other script globals:
#
our $globals = {};
# ->
# PID:  Process ID
# temp_dir:       Temporary directory for the current run.
# script_directory:  Directory of this script
# testrun_id:   Subdirectory of the results repository for the current run.
# result_dir:   Where to save results to ($RESULTS_DIR."/".testrun_id).
# test_result_dir:   Where the test-related results are saved. (result_dir."/results").
# downloading:  Whether downloading enabled or not
# dl_method:    Downloading method: HTTP is default / FTP /
#                FTP_HTTP means FTP through a HTTP proxy (e.g. squid)
#                non-HTTP FTP proxies are not supported.
# check_only:   Check if the tests specified can be run
# report_only:  Make the report
# noreport:     Don't make report
# webui:        Is running behind the WebUI.
# force_reinstall:
# start_time:   Script start time
# log_file_handle:   Log file
# vlog_file_handle:  Verbose log
# log_append:
# LAST_LINE:
# LAST_LINE_TYPE:
# std_profile: core,c++ | core,c++,desktop
# cert_mode:  Certification mode
# profile: User profile (--profile parameter)
# profile_filename: ^
# tester_name:  Tester name (facultative info, used for certification)
# tester_org:   Tester organization (facultative info, used for certification)
# run_comments: Some text that will be displayed by the WebUI alongside with results of the test.
# mailto:    Send results tarball by this email address.
# manifest:  Manifest data
# status:
# standard:
# ptyshell:  ptyshell tool executable
# interrupt_request: flag that being set when the SIGINT is caught, causing to interrupt the execution of the running test.
# done: Running|Finished|Terminated
# verdict, verdict_man: Overall verdict based on results analysis.

# Information about the host machine:
#
our $host_info = {};
# ->
# architecture:    (e.g. ia32)
# machine:         (e.g. i686)
# package_manager:  rpm or dpkg
# kernel:          (e.g. "2.6.18-4-powerpc #1 Mon Mar 26 09:11:14 CEST 2007")
# OS:              (e.g. "Debian GNU/Linux 4.0r2 (etch)")
# etc_issue:        /etc/issue contents. Sometimes is an only way to determine the host OS.
#

our @all_warnings = ();

#======================================================================

# This module allows to intercept printing to a FILEHANDLE and pass it to a HOOK function.
# It is used to copy STDERR output to log files. See stderr_hook().

package Misc::IOHook;

require 5.004;
use warnings;
use strict;

sub new {
    my $class = shift;
	my ($fh) = @_;
	return tie *$fh, $class, @_;
}

sub TIEHANDLE {
	my ($class, $fh, $hook_sub) = @_;
	
	my $h = new_from_fd IO::Handle(fileno($fh), "w");
	( defined $h ) or die "Failed to reopen $fh for writing";
	
	my $obj = {
		FILEHANDLE => $h,
		HOOK => $hook_sub,
	};
	
    return bless $obj, $class;
}

sub AUTOLOAD {
	my $method = our $AUTOLOAD;
	$method =~ s/.*:://;
	
	if ( $method =~ /^(WRITE|PRINTF?)$/ ) {
		goto &{$_[0]->{HOOK}};
	}
	elsif ( $method eq 'DESTROY' ) {
		#
	}
	else {
		my $self = shift;
		my $can = $self->{FILEHANDLE}->can(lc $method);
		if ( $can ) {
			unshift @_, $self->{FILEHANDLE};
			goto $can;
		} else {
			die "Can't method: $method";
		}
	}
}

1;
#======================================================================

package Misc;

our $tmp_log_data = "";
our $tmp_vlog_data = "";

sub setup_logging {
	
	## Output log
	my $log_fh;
	my $log_file = $globals->{'result_dir'}."/log";
	open $log_fh, ">>$log_file"
		or return error "Failed to open file '$log_file' for writing: $!";
	# Setup immediate flushing for log file handle.
	$log_fh->autoflush(1);
	$globals->{'log_file_handle'} = $log_fh;
	$globals->{LINE_N}{0} = 1;
	if ( $tmp_log_data ) {
		print {$globals->{'log_file_handle'}} $tmp_log_data;
		while ( $tmp_log_data =~ /\n/g ) { $globals->{LINE_N}{0}++; } # fix LINE_N
		$tmp_log_data = "";
	}
	
	## Verbose log
	my $vlog_fh;
	my $vlog_file = $globals->{'result_dir'}."/verbose_log";
	open $vlog_fh, ">>$vlog_file"
		or return error "Failed to open log file '$vlog_file' for writing: $!";
	# Setup immediate flushing for log file handle.
	$vlog_fh->autoflush(1);
	$globals->{'vlog_file_handle'} = $vlog_fh;
	$globals->{LINE_N}{1} = 1;
	if ( $tmp_vlog_data ) {
		print {$globals->{'vlog_file_handle'}} $tmp_vlog_data;
		while ( $tmp_vlog_data =~ /\n/g ) { $globals->{LINE_N}{1}++; } # fix LINE_N
		$tmp_vlog_data = "";
	}
}

sub print_log {
	my ($text) = @_;
	
	if ( !$globals->{'log_file_handle'} ) {
		$tmp_log_data .= $text;
		return;
	}
	
	print {$globals->{'log_file_handle'}} $text;
}

sub print_vlog {
	my ($text) = @_;
	
	if ( !$globals->{'vlog_file_handle'} ) {
		$tmp_vlog_data .= $text;
		return;
	}
	
	print {$globals->{'vlog_file_handle'}} $text;
}
#----------------------------------------------------------------------

sub myprint_timestamp {
	my ($type, $verbose) = @_;
	
	# Get the current time for timestamp.
	my ($sec, $min, $hour) = localtime();
	
	my $timestamp;
	if ( $verbose || $verbose_lvl >= 2 ) {
		$timestamp = sprintf ('%02d:%02d:%02d', $hour, $min, $sec);
	} else {
		$timestamp = sprintf ('%02d:%02d', $hour, $min);
	}
	
	if ( $type eq 'ss' ) {
		return "<$timestamp> ";
	}
	elsif ( $type eq 'cmd' ) {
		return "[$timestamp] | ";
	}
	elsif ( $type eq 'stderr' ) {
		return "[$timestamp] ! ";
	}

	return "[$timestamp] ";
}

sub myprint_fin {
	my ($verbose, $txt) = @_;
	
	if ( !$verbose ) {
		print $txt;
		print_log $txt;
	} else {
		print_vlog $txt;
	}
}
	
sub myprint_line {
	my ($line, $verbose, $type) = @_;
	
	# Prevent mixing lines
	$globals->{LAST_LINE_TYPE}{$verbose} ||= "";
	my $last_line_type = \$globals->{LAST_LINE_TYPE}{$verbose};
	
	$globals->{LAST_LINE}{$verbose}{$$last_line_type} ||= "";
	my $last_line = $globals->{LAST_LINE}{$verbose}{$$last_line_type};
	
	$globals->{LAST_LINE}{$verbose}{$type} ||= "";
	my $prev_line = \$globals->{LAST_LINE}{$verbose}{$type};
	
	if ( $line eq "\n" || $line eq "\n" ) {
		$globals->{LINE_N}{$verbose}++;
	}
	
	if ( $$last_line_type eq $type ) { # of the same type
		if ( $line eq "\n" ) {
			myprint_fin( $verbose, myprint_timestamp($type, $verbose) ) if $last_line eq "";
			myprint_fin( $verbose, "\n" );
			$$prev_line = "";
		}
		elsif ( $line eq "\r" ) {
			if ( $last_line ne "" ) {
				myprint_fin( $verbose, "\r" );
				$$prev_line = "\r";
			}
		}
		else {
			if ( $$prev_line eq "" || $$prev_line eq "\r") {
				$line = myprint_timestamp($type, $verbose).$line;
			}
			myprint_fin( $verbose, $line );
			$$prev_line .= $line;
		}
	}
	else { # another type
		if ( $line eq "\n" ) {
			if ( $$prev_line ne "" ) {
				$$prev_line = "";
			} else {
				myprint_fin( $verbose, "\n" ) if $last_line ne "";
				myprint_fin( $verbose, myprint_timestamp($type, $verbose)."\n" ); # print
				$$last_line_type = $type;
				$$prev_line = "";
			}
		}
		elsif ( $line eq "\r" ) {
			if ( $$prev_line ne "" ) {
				$$prev_line = "\r";
			}
		}
		else {
			myprint_fin( $verbose, "\n" ) if $last_line ne "";
			if ( $$prev_line eq "" || $$prev_line eq "\r" ) {
				$line = myprint_timestamp($type, $verbose).$line;
			} else {
				$line = $$prev_line.$line;
			}
			myprint_fin( $verbose, $line ); # print
			$$last_line_type = $type;
			$$prev_line = $line;
		}
	}
}

sub myprint {
	my ($message, $lvl, $type) = @_;
	$lvl = 1 if !defined $lvl;
	$type = '' if !defined $type;
	
	while ( $message =~ s/^([^\r\n]+|[\r\n])// ) {
		#print "!!!\n";
		if ( $lvl <= $verbose_lvl ) {
			myprint_line($1, 0, $type); # common output
		}
		myprint_line($1, 1, $type); # verbose log
	}
}

#---------------------------------------------------------------------

# Prints the message
sub inform_misc {
	my ($message) = @_;
	
	$message .= "\n" if $message !~ /\n$/s;
	
	myprint $message;
}

# Prints the message if verbose mode is enabled.
sub debug_inform_misc {
	my ($message) = @_;

	return if !defined $message;
	
	$message .= "\n" if $message !~ /\n$/s;
	
	myprint $message, 2;
}
#---------------------------------------------------------------------

sub complain_misc {
	my ($err, @params) = @_;
	
	( defined $err ) or $err = "";
	
	if ( !is_err_obj($err) ) {
		local $Error::Depth = $Error::Depth + 1;
		$err = error($err, @params);
	}
	
	if ( $globals->{'webui'} ) {
		print_stderr("Error:\n".$err->tostring()."--------------------\n");
	}
	
	myprint "!!! ERROR:\n".$err->tostring()."--------------------\n";
	
	# Print the stacktrace to the verbose log only.
	myprint $err->first->{-stacktrace}, 3;
	myprint "--------------------\n", 3; # to verbose log
	
	return $err;
}

sub warning_misc {
	my ($err, @params) = @_;
	
	( defined $err ) or $err = "";
	
	if ( !is_err_obj($err) ) {
		local $Error::Depth = $Error::Depth + 1;
		$err = error($err, @params);
	}
	
	#fail("Failed due to DEBUG mode", $err) if DEBUG;
	
	if ( DEBUG ) {
		push @all_warnings, $err;
	}
	
	if ( $globals->{'webui'} ) {
		print_stderr("Warning:\n".$err->tostring()."--------------------\n");
	}
	
	myprint "!!! Warning:\n".$err->tostring()."--------------------\n";
	
	# Print the stacktrace to the verbose log.
	myprint $err->first->{-stacktrace}, 3;
	myprint "--------------------\n", 3; # to verbose log
	
	return $err;
}
#---------------------------------------------------------------------

# Send a mail via *sendmail* utility.
# Parameter is a link to hash which shall contain field "TEXT" and may contain
# fields "TO", "FROM", "SUBJECT", "ATTACHMENT".
sub sendmail {
	my (%params) = @_;
	
	# Sendmail parameters are: 
	# -t   read the message to obtain recipients from the To: header
	# -oi  ignore dots alone on lines by themselves in incoming messages
	my $sendmail_cmd = "/usr/sbin/sendmail -t -oi";
	my $boundary = "Simple-Boundary--";
	debug_inform($sendmail_cmd);
	
	# Temporary suppress SIGPIPE to survive failure of the sendmail.
	my $old_sigpipe = $SIG{PIPE};
	$SIG{PIPE} = 'IGNORE';
	
	# Senmail reads its standard input
	open SENDMAIL, "| $sendmail_cmd"
		or return error "Failed to call sendmail: $!";

	if ( $params{SUBJECT} ) {
		$params{SUBJECT} =~ s/[\n\r]+/ /g;
		print SENDMAIL "Subject: ".$params{SUBJECT}."\n";
	}
	if ( $params{TO} ) {
		print SENDMAIL "To: ".$params{TO}."\n";
	}
	if ( $params{FROM} ) {
		print SENDMAIL "From: ".$params{FROM}."\n";
	}

	if ( $params{ATTACHMENT} ) {
		print SENDMAIL "Content-Type: multipart/mixed; boundary=\"$boundary\"\n";
		print SENDMAIL "\nThis is a multi-part message in MIME format.\n";
		print SENDMAIL "--$boundary\n"
	}
	
	print SENDMAIL "Content-type: text/plain\n";
	print SENDMAIL "\n".$params{TEXT}."\n";

	if ( $params{ATTACHMENT} ) {
		print SENDMAIL "--$boundary\n";
		print SENDMAIL "Content-Type: application/octet-stream; name=\"".extract_filename($params{ATTACHMENT})."\"\n"; 
		print SENDMAIL "Content-Transfer-Encoding: base64\n";
		print SENDMAIL "Content-Disposition: attachment; filename=\"".extract_filename($params{ATTACHMENT})."\"\n";
		print SENDMAIL "\n";
		
		my $buf;
		open FILE, $params{ATTACHMENT}
			or return error "Failed to open attachement: '".$params{ATTACHMENT}."': $!";
		
		while ( read(FILE, $buf, 16*1024) ) { 
			print SENDMAIL encode_base64($buf) or last; 
		}
		close FILE;
	}
	close(SENDMAIL);
	$SIG{PIPE} = $old_sigpipe;
	
	return 1;
}
#---------------------------------------------------------------------

# Runs a command and returns its output.
sub capture_misc {
	my ($command) = @_;
	
	debug_inform("%> ".$command);
	
	$command = "( ".$command." ) 2>&1";
	
	# Temporary suppress SIGPIPE to survive failure of the command.
	my $old_sigpipe = $SIG{PIPE};
	$SIG{PIPE} = 'IGNORE';

	open CMDPIPE, $command." |"
		or return error "Failed to open pipe '$command |': $!";

	my $result = "";
	my $buf = "";
	my $ret; # Returns the number of bytes actually read, 0 at end of file, or undef if there was an error.
	while ( $ret = sysread(CMDPIPE, $buf, 1024) ) { # Read the output of the command
		$result .= $buf;
		myprint $buf, 2, 'cmd';
	}
	if ( $result =~ /[^\n\r]\z/ ) { myprint "\n", 2, 'cmd' }
	
	close CMDPIPE;
	$SIG{PIPE} = $old_sigpipe if defined $old_sigpipe;

	if ( !defined $ret ) {
		# There was an error while reading
		debug_inform ("^ Warning: $!");
	}
	if( $? != 0 ) {
		# Warning on fail
		debug_inform ("^ Warning: code ".($?>>7)." (".($? & 127).")"." has been returned.");
	}
	
	return $result;
}
#---------------------------------------------------------------------

# Creates a copy of the old file (if there is no backup copies)
# and replaces the file with a new file.
sub backup_and_replace {
	my ($old_file, $new_file) = @_;
	
	unless ( -f "$old_file.orig" ) {
		cmd( "cp -f ".shq($old_file)." ".shq($old_file.".orig") ); 
	}
	
	# Check the copy has appeared
	( -f "$old_file.orig" )
		or return error "Failed to copy: cp -f '$old_file' '$old_file.orig'";
	
	cmd( "cp -f ".shq($new_file)." ".shq($old_file) ) == 0
		or return error "Failed to copy: '$new_file' to '$old_file'.";
	
	return 1;
}
#----------------------------------------------------------------------

sub ask_for_password {
	my ($request) = @_;
	( !$globals->{'webui'} ) or return error "ask_for_password can't be used under web-ui.";
	
	myprint $request;
	my $password = `stty -echo >/dev/null 2>&1; read -r password; stty echo >/dev/null 2>&1; echo \$password`;
	myprint "\n";
	chomp $password;
	return $password;
}
#----------------------------------------------------------------------

sub suggest_packages {
	my (@libs) = @_;

	my %debian_packages = (
		'libQtCore.so.4' => 'libqtcore4',
		'libQtGui.so.4' => 'libqt4-gui',
		'libQtSql.so.4' => 'libqt4-sql',
		'libQtSvg.so.4' => 'libqt4-svg',
		'libQtOpenGL.so.4' => 'libqt4-opengl',
		'libQtXml.so.4' => 'libqt4-xml',
		'libQtNetwork.so.4' => 'libqt4-network',
		'libqt-mt.so.3' => 'libqt3-mt',
		'libcups.so.2' => 'libcups2',
		'libcupsimage.so.2' => 'libcupsimage2',
		'xlsfonts' => 'x11-utils',
		'Tie::Hash' => 'perl-base',
		'Time::HiRes' => 'perl',
		'Test::Harness' => 'perl-modules|libtest-harness-perl',
		'Test::Harness::Assert' => 'perl-modules',
		'Test::Harness::Straps' => 'perl-modules',
		'Test::Simple' => 'perl-modules|libtest-simple-perl',
		'Test::More' => 'perl-modules|libtest-simple-perl',
		'Test::Builder' => 'perl-modules|libtest-simple-perl',
		'File::Spec' => 'perl-base|libfile-spec-perl',
		'ExtUtils::MakeMaker' => 'perl-modules',
		'XML::SAX::Expat' => 'libxml-sax-expat-perl',
		'XML::SAX::ExpatXS' => 'libxml-sax-expatxs-perl',
		'XML::LibXML::SAX' => 'libxml-libxml-perl',
		'XML::Parser::PerlSAX' => 'libxml-perl',
		'Data::Dumper' => 'perl',
		'File::Basename' => 'perl-modules',
		'File::Spec' => 'perl-base|libfile-spec-perl',
		'Getopt::Long' => 'perl-base',
		'Getopt::Std' => 'perl-modules',
		'URI::file' => 'liburi-perl',
		'foomatic-rip' => 'foomatic-filters',
		'gs' => 'ghostscript',
		'hpijs' => 'hpijs',
	);
	my %ubuntu_packages = (
		'libQtCore.so.4' => 'libqtcore4',
		'libQtGui.so.4' => 'libqtgui4',
		'libQtSql.so.4' => 'libqt4-sql',
		'libQtSvg.so.4' => 'libqt4-svg',
		'libQtOpenGL.so.4' => 'libqt4-opengl',
		'libQtXml.so.4' => 'libqt4-xml',
		'libQtNetwork.so.4' => 'libqt4-network',
		'libqt-mt.so.3' => 'libqt3-mt',
		'libcups.so.2' => 'libcups2',
		'libcupsimage.so.2' => 'libcupsimage2',
		'xlsfonts' => 'x11-utils',
		'Tie::Hash' => 'perl-base',
		'Time::HiRes' => 'perl',
		'Test::Harness' => 'perl-modules|libtest-harness-perl',
		'Test::Harness::Assert' => 'perl-modules',
		'Test::Harness::Straps' => 'perl-modules',
		'Test::Simple' => 'perl-modules|libtest-simple-perl',
		'Test::More' => 'perl-modules|libtest-simple-perl',
		'Test::Builder' => 'perl-modules|libtest-simple-perl',
		'File::Spec' => 'perl-base|libfile-spec-perl',
		'ExtUtils::MakeMaker' => 'perl-modules',
		'XML::SAX::Expat' => 'libxml-sax-expat-perl',
		'XML::SAX::ExpatXS' => 'libxml-sax-expatxs-perl',
		'XML::LibXML::SAX' => 'libxml-libxml-perl',
		'XML::Parser::PerlSAX' => 'libxml-perl',
		'Data::Dumper' => 'perl',
		'File::Basename' => 'perl-modules',
		'File::Spec' => 'perl-base|libfile-spec-perl',
		'Getopt::Long' => 'perl-base',
		'Getopt::Std' => 'perl-modules',
		'URI::file' => 'liburi-perl',
		'foomatic-rip' => 'foomatic-filters',
		'gs' => 'ghostscript',
		'hpijs' => 'hpijs',
	);
	my %rpm_packages = (
		'libQtCore.so.4' => 'qt',
		'libQtGui.so.4' => 'qt-x11',
		'libQtSql.so.4' => 'qt',
		'libQtSvg.so.4' => 'qt-x11',
		'libQtOpenGL.so.4' => 'qt-x11',
		'libQtXml.so.4' => 'qt',
		'libQtNetwork.so.4' => 'qt',
		'libqt-mt.so.3' => 'qt3',
		'libcups.so.2' => 'cups-libs',
		'libcupsimage.so.2' => 'cups-libs',
		'xlsfonts' => 'xorg-x11-utils-xlsfonts',
		'Tie::Hash' => 'perl',
		'Time::HiRes' => 'perl',
		'Test::Harness' => 'perl-Test-Harness',
		'Test::Harness::Assert' => '?',
		'Test::Harness::Straps' => '?',
		'Test::Simple' => 'perl-Test-Simple',
		'Test::More' => 'perl-Test-Simple',
		'Test::Builder' => 'perl-Test-Simple',
		'File::Spec' => 'perl',
		'ExtUtils::MakeMaker' => 'perl-ExtUtils-MakeMaker',
		'XML::SAX::Expat' => 'perl-XML-SAX-Expat',
		'XML::SAX::ExpatXS' => 'perl-XML-SAX-Expat',
		'XML::LibXML::SAX' => 'perl-XML-LibXML',
		'XML::Parser::PerlSAX' => 'perl-libxml-perl',
		'Data::Dumper' => 'perl',
		'File::Basename' => 'perl',
		'File::Spec' => 'perl',
		'Getopt::Long' => 'perl',
		'Getopt::Std' => 'perl',
		'URI::file' => 'perl-URI',
		'foomatic-rip' => 'foomatic',
		'gs' => 'ghostscript',
		'hpijs' => 'hpijs',
	);
	my %suse_packages = (
		'libQtCore.so.4' => 'libqt4',
		'libQtGui.so.4' => 'libqt4-x11',
		'libQtSql.so.4' => 'libqt4',
		'libQtSvg.so.4' => 'libqt4-x11',
		'libQtOpenGL.so.4' => 'libqt4-x11',
		'libQtXml.so.4' => 'libqt4',
		'libQtNetwork.so.4' => 'libqt4',
		'libqt-mt.so.3' => 'qt3',
		'libcups.so.2' => 'cups-libs',
		'libcupsimage.so.2' => 'cups-libs',
		'xlsfonts' => 'xorg-x11',
		'Tie::Hash' => 'perl',
		'Time::HiRes' => 'perl',
		'Test::Harness' => 'perl-Test-Harness',
		'Test::Harness::Assert' => 'perl',
		'Test::Harness::Straps' => 'perl',
		'Test::Simple' => 'perl-Test-Simple',
		'Test::More' => 'perl-Test-Simple',
		'Test::Builder' => 'perl-Test-Simple',
		'File::Spec' => 'perl-base',
		'ExtUtils::MakeMaker' => 'perl-ExtUtils-MakeMaker',
		'XML::SAX::Expat' => 'perl-XML-SAX-Expat',
		'XML::SAX::ExpatXS' => 'perl-XML-SAX-Expat',
		'XML::LibXML::SAX' => 'perl-XML-LibXML',
		'XML::Parser::PerlSAX' => 'perl-libxml-perl',
		'Data::Dumper' => 'perl-base',
		'File::Basename' => 'perl-base',
		'File::Spec' => 'perl-base',
		'Getopt::Long' => 'perl-base',
		'Getopt::Std' => 'perl-base',
		'URI::file' => 'perl-URI',
		'foomatic-rip' => 'foomatic-filters',
		'gs' => 'ghostscript-library',
		'hpijs' => 'hplib-hpijs',
	);
	my $package_set = \%rpm_packages;
	if ( $host_info->{'OS'} =~ /suse/i ) {
		$package_set = \%suse_packages;
	}
	elsif ( $host_info->{'OS'} =~ /debian/i ) {
		$package_set = \%debian_packages;
	}
	elsif ( $host_info->{'package_manager'} =~ /rpm/i ) {
		$package_set = \%rpm_packages;
	}
	elsif ( $host_info->{'package_manager'} =~ /dpkg/i ) {
		$package_set = \%ubuntu_packages;
	}
	
	return $package_set;
}

sub missing_packages_message {
	my ($title, @missing_libs) = @_;
	
	my $package_set = suggest_packages(@missing_libs);

	my $msg = $title;
	
	$msg .= join ", ", map "$_ (".($package_set->{$_} or "?").")", @missing_libs;
	$msg .= ".\n";

	my $search_tool = "you may try to search them with your package manager";
	if ( $host_info->{'package_manager'} eq 'rpm' && does_shell_know('yum') ) {
		$search_tool = "you may try 'yum whatprovides FILENAME' search command";
	}
	elsif ( $host_info->{'package_manager'} eq 'dpkg' && does_shell_know('apt-get') ) {
		if ( does_shell_know('apt-file') ) {
			$search_tool = "you may try 'apt-file search FILENAME' command";
		} else {
			$search_tool = "you may try to install apt-file tool and use 'apt-file search FILENAME'";
		}
	}
	elsif ( does_shell_know('yast2') ) {
		$search_tool = "you may try searching in YaST2";
	}
	elsif ( does_shell_know('yast') ) {
		$search_tool = "you may try searching in YaST";
	}
	$msg .= "If suggested packages (specified in parentheses) cannot be found on your distro,\n".$search_tool." in this case.";

	return $msg;
}
#-----------------------------------------------------------------------

sub status_updated {
	return main::write_status();
}
#----------------------------------------------------------------------

sub stderr_hook {
	my $self = shift;
	myprint "@_", undef, 'stderr';
}

sub print_stderr {
	my $hook = tied *STDERR;
	if ( $hook ) {
		return print {$hook->{FILEHANDLE}} @_;
	} else {
		return print STDERR @_;
	}
}
#----------------------------------------------------------------------

sub Init {
	Misc::IOHook->new(*STDERR, \&stderr_hook);
	
	$Common::inform_sub = \&inform_misc;
	$Common::debug_inform_sub = \&debug_inform_misc;
	$Common::complain_sub = \&complain_misc;
	$Common::warning_sub = \&warning_misc;
	$Common::capture_sub = \&capture_misc;
}
#----------------------------------------------------------------------
1; #return value
