# Distribution Checker
# ptyshell Tool Integration Module (Subshell.pm)
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

package Subshell;
use strict;
use IPC::Open2;
use POSIX qw(EAGAIN EBADF WNOHANG);    # error constants
use Fcntl;

use Misc;

my $wait_hup = 5;                      # seconds.

#----------------------------------------------------------------------

# Class constructor
sub New {
	my $subshell = {};

	bless $subshell;
	return $subshell;
}

# Spawns a new subshell.
# The $user parameter is optional.
sub Spawn {
	my ( $subshell, $command ) = @_;

	my $pidfile = $globals->{'temp_dir'} . "/PTYSUB_PID";

	$SIG{PIPE} = sub {
		local $SIG{PIPE} = 'IGNORE';
		close $subshell->{OUT} if $subshell->{OUT};
		close $subshell->{IN}  if $subshell->{IN};
	};

	my $pid = open2( $subshell->{OUT}, $subshell->{IN}, $command )
	  or return error "open2 failed ($!).";

# Set non-blocking I/O mode for the output filehandle of the subshell
# This is needed to prevent buffering of sended commands instead of delivering them to the subshell.
	eval {    # Try
		my $flags = fcntl( $subshell->{OUT}, F_GETFL, 0 ) or die $!;
		fcntl( $subshell->{OUT}, F_SETFL, $flags | O_NONBLOCK ) or die $!;
	};
	if ($@) {    # Catch
		return error "Failed to set non-blocking I/O mode for output"
		  . " filehandle of the subshell. ($@)";
	}

	## Some initializations

	# ptyshell's PID
	$subshell->{PTY_PID} = $pid;

	my $user = "root";
	$subshell->{USER} = $user ? $user : "root";

	$subshell->{DEFAULT_TIMEOUT} = 60 * 60;

	# Default timeout is one hour.

	$subshell->{NOTIF_INTERVAL} = 60;    # 1 minute
	$subshell->{LAST_NOTIFICATION} = $subshell->{LAST_ACTIVE} = time();

	# Notify each minute if no output from the subshell.

# Keep last N lines of the subshell output for debug information in case of an error.
	$subshell->{LAST_LINE}       = "";
	$subshell->{LAST_LINES}      = [];
	$subshell->{KEEP_LAST_LINES} = 15;

	$subshell->{TIMEOUT} = 0;

	# Sleep a bit allowing subshell to get ready
	sleep 1;

	# Read anything from the subshell's output (usually a shell prompt)
	# to be sure that the subshell is ready.
	my $line = "";
	$subshell->Settle( $line, 3 );
	if ( $line ne "" ) {
		$subshell->{SHELL_PROMPT} = $line; # Save this line for... just in case.
	}

	# Read the PID of the subshell saved by the ptyshell tool to the file.
	my $text = read_file($pidfile);
	if ( is_ok($text) ) {
		chomp $text;
		( $subshell->{PTY_PID}, $subshell->{SUB_PID} ) = split /\|/, $text;
	}

	# Write some info to the log file
	if ( $subshell->{LOGFILE} ) {
		print { $subshell->{LOGFILE} } "@@ pipe pid: $pid;";
		print { $subshell->{LOGFILE} } " ptyshell pid: "
		  . $subshell->{PTY_PID} . ";"
		  if defined $subshell->{PTY_PID};
		print { $subshell->{LOGFILE} } " subshell pid: "
		  . $subshell->{SUB_PID} . ";"
		  if defined $subshell->{SUB_PID};
		print { $subshell->{LOGFILE} } "\n";
	}

	return 1;    # OK
}

#----------------------------------------------------------------------

sub Close {
	my ($subshell) = @_;

	# Close in and out pipes
	close $subshell->{IN} if $subshell->{IN};
	$subshell->{IN} = undef;
	close $subshell->{OUT} if $subshell->{OUT};
	$subshell->{OUT}      = undef;
	$subshell->{DETACHED} = 1;
}

#----------------------------------------------------------------------

sub stale_notification {
	my ($time) = @_;

	inform "No output from testkit-lite for " . format_duration($time) . "\n";
}

# Setup logging subshell output to the file.
# Returns the log file handle.
sub LogFile {
	my ( $subshell, $filename ) = @_;

	return $subshell->{LOGFILE} if !defined $filename;

	my $logfile;
	open $logfile, ">>$filename"
	  or return error "Failed to open '$filename' for writing: $!";

	$logfile->autoflush(1);

	$subshell->{LOGFILE} = $logfile;

	return $subshell->{LOGFILE};    # OK
}

#----------------------------------------------------------------------

# Wait for process $pid no longer than $maxtime seconds;
sub wait_for_pid {
	my ( $pid, $maxtime ) = @_;

	( ref($pid) eq "" )
	  or return error "wrong parameter for wait_for_pid: '$pid'";

	my $exit_code = undef;          # No code.

	if ( waitpid( $pid, WNOHANG ) eq $pid )
	{    # To purge zombies before checking is_process_running()
		$exit_code = ( $? >> 8 );
	}

	my $sleeped = 0;
	{
		if ( !is_process_running($pid) ) {
			if ( waitpid( $pid, WNOHANG ) eq $pid ) {
				$exit_code = ( $? >> 8 );
			}
			return $exit_code;    # Finished
		}
		if ( $sleeped < $maxtime ) {
			sleep 1;
			$sleeped++;
			redo;
		}
	}
	return error "Not finished";    # Not finished
}

#----------------------------------------------------------------------

# Allow the subshell to close gracefully in $maxtime seconds, otherwise kill it.
sub ExpectLogout {
	my ( $subshell, $maxtime ) = @_;

	return 1 if $subshell->{TERMINATED};

	$maxtime = $wait_hup if !defined $maxtime;

	myprint( "\n", undef, 'ss' ) if ( $subshell->{LAST_LINE} ne "" );

	$subshell->{DETACHED} = 1;
	$subshell->Close();

	inform "Waiting for logout...";
	{
		my $ret = wait_for_pid( $subshell->{PTY_PID}, $maxtime );
		if ( is_ok $ret ) { $subshell->{EXIT_CODE} = $ret; last }

		inform "Sending SIGINT to pid " . $subshell->{PTY_PID} . "";
		kill 'INT', $subshell->{PTY_PID};
		$ret = wait_for_pid( $subshell->{PTY_PID}, 2 );
		if ( is_ok $ret ) { $subshell->{EXIT_CODE} = $ret; last }

		inform "Sending SIGINT to pid " . $subshell->{SUB_PID} . "";
		kill 'INT', $subshell->{SUB_PID};
		is_ok wait_for_pid( $subshell->{SUB_PID}, 1 );
		$ret = wait_for_pid( $subshell->{PTY_PID}, 1 );
		if ( is_ok $ret ) { $subshell->{EXIT_CODE} = $ret; last }

		inform "Sending SIGTERM to pid " . $subshell->{PTY_PID} . "";
		kill 'TERM', $subshell->{PTY_PID};
		$ret = wait_for_pid( $subshell->{PTY_PID}, 2 );
		if ( is_ok $ret ) { $subshell->{EXIT_CODE} = $ret; last }

		inform "Sending SIGTERM to pid " . $subshell->{SUB_PID} . "";
		kill 'TERM', $subshell->{SUB_PID};
		is_ok wait_for_pid( $subshell->{SUB_PID}, 1 );
		$ret = wait_for_pid( $subshell->{PTY_PID}, 1 );
		if ( is_ok $ret ) { $subshell->{EXIT_CODE} = $ret; last }

		inform "Sending SIGKILL to pid " . $subshell->{PTY_PID} . "";
		kill 'KILL', $subshell->{PTY_PID};
		$ret = wait_for_pid( $subshell->{PTY_PID}, 2 );
		if ( is_ok $ret ) { $subshell->{EXIT_CODE} = $ret; last }

		inform "Sending SIGKILL to pid " . $subshell->{SUB_PID} . "";
		kill 'KILL', $subshell->{SUB_PID};
		is_ok wait_for_pid( $subshell->{SUB_PID}, 1 );
		$ret = wait_for_pid( $subshell->{PTY_PID}, 1 );
		if ( is_ok $ret ) { $subshell->{EXIT_CODE} = $ret; last }

		# Failed to close the subshell

		$subshell->{TERMINATED} = 0;

		return error "Failed to close the subshell";
	}

	if ( !defined $subshell->{EXIT_CODE} ) {
		if ( waitpid( $subshell->{PTY_PID}, WNOHANG ) eq $subshell->{PTY_PID} )
		{    # To kill zombies
			$subshell->{EXIT_CODE} = $?;
		}
	}

	inform "Subshell closed"
	  . (
		defined $subshell->{EXIT_CODE}
		? " with exit code " . $subshell->{EXIT_CODE}
		: ""
	  ) . ".";

	$subshell->{TERMINATED} = 1;
	return 1;    # OK
}

#----------------------------------------------------------------------

# Write to the input of the subshell
#
# If you want to run a command in subshell don't forget to call Settle() before.
# And don't forget to add "\n" at the end of the command.
sub Send {
	my ( $subshell, $txt ) = @_;

	if ( $subshell->{DETACHED} ) {
		return error "Trying to send to a detached subshell";
	}

	my $result = print { $subshell->{IN} } $txt;

	if ( !$result ) {
		unless ( $subshell->{DETACHED} ) {
			inform "Subshell detached! ($!)";
			$subshell->{DETACHED} = 1;
		}
		return error "Subshell detached";
	}

	return 1;    # OK
}

#----------------------------------------------------------------------

sub print_echo {
	my ( $subshell, $c ) = @_;

	if ( $subshell->{LOGFILE} ) {

		# Write to the log
		print { $subshell->{LOGFILE} } $c;
	}

	# Print the output
	myprint( $c, undef, "ss" );
}

#----------------------------------------------------------------------

# Read the subshell's output in non-blocking mode.
# Stops if a line feed is encountered.
# Waits for each character no longer than $max_wait_time.
# Returns the last line of the output.
sub Read {
	my ( $subshell, $max_wait_time ) = @_;

	if ( !defined $max_wait_time ) {
		$max_wait_time = $subshell->{DEFAULT_TIMEOUT};
	}

	return undef if $subshell->{DETACHED};

	my $started = time();

	$subshell->{TIMEOUT} = 0;

	my $notif_interval = $subshell->{NOTIF_INTERVAL};

	my $c = "";

	my $read_b = 0;

	my $sleep = 0.1;

  READ_LOOP:
	while (1) {    # No condition since 'redo' is used
		last if $subshell->{DETACHED};

		my $result = read $subshell->{OUT}, $c, 1;    # read char by char
		       # The OUT fd was configured for non-blocking read

		if ( !defined $result ) {    # Error
			if ( $! == EAGAIN ) {

				# EAGAIN is OK for non-blocking reading.

				if ($read_b) {

					# Return if at least one char was read.
					last READ_LOOP;
				}

				# else
				next READ_LOOP;      # read again
			}
			elsif ( $! == EBADF ) {

				# Bad file descriptor. This is OK for a terminated subshell,
				# don't panic.
			}
			elsif ($!) {
				debug_inform "Error at the subshell (" . int($!) . "): $!.";
			}
			inform "PTY FINISH: DETACHED";
			$subshell->{DETACHED} = 1;
			last READ_LOOP;
		}
		elsif ( $result == 1 ) {    # read OK
			                        # Echo
			print_echo( $subshell, $c );
			$read_b++;

			# delimit the last line
			if ( $subshell->{LAST_LINE} =~ s/[\n\x0D]$// ) {    # chomp
				if ( $subshell->{LAST_LINE} ne "" ) {  # don't keep empty lines.
					                                   # Push the last line
					push @{ $subshell->{LAST_LINES} }, $subshell->{LAST_LINE};
					$subshell->{LAST_LINE} = "";

					# Keep a number of last lines
					while ( @{ $subshell->{LAST_LINES} } >
						$subshell->{KEEP_LAST_LINES} )
					{
						shift @{ $subshell->{LAST_LINES} };    # drop old lines
					}
				}
			}

			# Append the character
			$subshell->{LAST_LINE} .= $c;

			if ( $c =~ /[\n\x0D]/s ) {                         # Line break
				last READ_LOOP;                                # EOL
			}

			# Reset the time counter
			# Have to keep it in the $subshell structure, because it
			# should be kept between Read(<small wait time>) calls.
			$subshell->{LAST_NOTIFICATION} = $subshell->{LAST_ACTIVE} = time();

			redo READ_LOOP;    # read further, don't sleep
		}
		elsif ( $result == 0 ) {

			# EOF
			debug_inform "EOF at subshell's output.";    # Ususally it's OK.
			last READ_LOOP;
		}
		else {

			# Should never be reached
			debug_inform
"Something strange happened (Subshell::Read has returned '$result').";

			# Treat this as an error.
			$subshell->{DETACHED} = 1;
			last READ_LOOP;
		}
	}
	continue {
		my $time = time();

		if ( ( $time - $subshell->{LAST_NOTIFICATION} ) >= $notif_interval ) {

			# Notification about no output for too long time
			stale_notification( $time - $subshell->{LAST_ACTIVE} );
			$subshell->{LAST_NOTIFICATION} = $time;
		}

		if ( ( $time - $started ) >= $max_wait_time ) {

			# Timeout

			# Do not detach the subshell yet.

			if ( $max_wait_time && !$read_b ) {
				$subshell->{TIMEOUT} = 1;

				#debug_inform "Timeout in subshell ($max_wait_time seconds).";
			}

			last;
		}

		sleep_ms $sleep;
	}

	return $subshell->{LAST_LINE};
}

#----------------------------------------------------------------------

# Reads output from the subshell until it closed.
# Doesn't sleep longer than $max_silence_time.
sub WaitForSubshell {
	my ( $subshell, $max_silence_time ) = @_;

	if ( !defined $max_silence_time ) {
		$max_silence_time = $subshell->{DEFAULT_TIMEOUT};
	}

	inform "Waiting for subshell...";

	while ( !$subshell->{DETACHED} ) {
		$subshell->Read($max_silence_time);

		if ( $subshell->{TIMEOUT} ) {
			inform "Timeout at subshell";
			last;
		}
		last if $subshell->{DETACHED};
	}

	return $subshell->ExpectLogout();
}

#----------------------------------------------------------------------

# Waits for $text (usually a prompt) and sends $reply.
# $text is a regexp.
sub expect_and_reply {
	my ( $subshell, $text, $reply, $max_wait_time ) = @_;

	if ( !defined $max_wait_time ) {
		$max_wait_time = $subshell->{DEFAULT_TIMEOUT};
	}

	( !$subshell->{DETACHED} ) or return error "Subshell is detached";

	my $deadline = time() + $max_wait_time;
	my $left     = $max_wait_time;

  WAIT_LOOP:
	while (1) {
		my $line = $subshell->Read($left);

		last if !defined $line;
		next if $line !~ /$text\s*$/;    # wait for the text expected

		# Have matched the text, wait for a prompt to paste the reply.

	  SETTLE:
		{
			$left = $deadline - time();
			last WAIT_LOOP if $left < 0;

			$subshell->Settle( $line, $left ) or redo SETTLE;
		}

		is_ok $subshell->Send($reply) or return $Error::Last; # Paste the reply.

		return 1;                                             # OK
	}

	if ( $subshell->{EXPECT_NO_COMPLAIN} ) {
		my $errmsg = "!!! Error: Time out expecting '$text'";
		$subshell->print_echo("\n$errmsg\n");
		push @{ $subshell->{LAST_LINES} }, $errmsg;
	}

	return error "timed out expecting '$text'";
}

#-----------------------------------------------------------------------

sub Settle {
	my ( $subshell, $text, $max_wait_time, $max_read_time ) = @_;

	if ( !defined $max_wait_time ) { $max_wait_time = $wait_hup; }
	if ( !defined $max_read_time ) { $max_read_time = 0.5; }

	( !$subshell->{DETACHED} ) or return 1;

	my $deadline = time() + $max_wait_time;

	while ( time() <= $deadline ) {
		my $s = $subshell->Read($max_read_time);

		return 1 if !defined $s;    # DETACHED

		if ( $subshell->{TIMEOUT} ) {
			$subshell->{TIMEOUT} = 0;
			return 1;
		}

		# else try again

		if ( defined $text ) {
			$_[1] = $text = $s;     # Set the $text variable
			return 0
			  if $s =~ /[\n\x0D]$/
			;  # End of line, immediate return (non-settled) if $text is defined
		}
	}
	return 0;
}

#-----------------------------------------------------------------------

sub get_last_lines {
	my ($subshell) = @_;

	return "" if ( !$subshell->{LAST_LINES} || !@{ $subshell->{LAST_LINES} } );
	return "" if ( $subshell->{LAST_LINES_REPORTED} );

	# To avoid prining this stuff twice.
	# One should unset LAST_LINES_REPORTED if not reporting this message.
	$subshell->{LAST_LINES_REPORTED} = 1;

	return
	  "Below are the last few lines of subshell output (may be helpful or not):"
	  . "\n============================================\n"
	  . ( join "\n", @{ $subshell->{LAST_LINES} } )
	  . "\n============================================\n";
}

#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
1;    # Returned value
