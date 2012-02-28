#!/usr/bin/perl -w

# Distribution Checker
# Web-server Module (dc-server.pl)
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

use strict;
use Socket;
use IO::Socket;
use POSIX ':sys_wait_h';
use POSIX 'setsid';
use Fcntl qw/:flock :seek/;
use Cwd qw/cwd abs_path/;
use File::Temp qw/tmpnam/;
use FindBin;

# First, demonize ourselves
# Fork to not be the group leader (if we are)
my $pid = fork();
if (!defined($pid)) {
	die "Error: Failed to fork.\n";
}
elsif ($pid != 0) {
	exit 0;     # Terminate the parent process
}
# Start new session
if (setsid() == -1) {
	die "Error: Failed to start new session. $!\n";
}

# $SERVER_ROOT - path where the server script is located.
my $SERVER_ROOT = abs_path($0);
$SERVER_ROOT =~ s!/[^/]+$!!;
print "server root = $SERVER_ROOT\n";
# $DOCUMENT_ROOT - path to directory connected to http://localhost:<port>/
# It's the 'public_html' subdirectory in the dc-server.pl script directory.
my $DOCUMENT_ROOT = "$SERVER_ROOT/public_html";

my ($MTK_VERSION, $MTK_BRANCH);
# Read the Distribution Checker branch name and version
if (open(INFO, $SERVER_ROOT.'/../utils/VERSION')) {
	if (defined(my $info = <INFO>)) {   # read first line
		$info =~ s/[\r\n]//g;
		($MTK_VERSION, $MTK_BRANCH) = split(/:/, $info);
	}
	close(INFO);
}

$MTK_BRANCH = 'MeeGo' if (!$MTK_BRANCH);
$MTK_VERSION = '' if ($MTK_VERSION !~ m/^\d/);    # Version should start with digit

#my $APP_DATA = '/var/opt/'.(lc($MTK_BRANCH)).'/test/manager';                    # Directory where Distribution Checker's data are stored.
my $APP_DATA = $FindBin::Bin.'/../..'; 
my $CONF_FILE = $FindBin::Bin.'/dc-server.conf.default';    # Location of the configuration file.

my $port = shift;
my $default_port = (($MTK_BRANCH eq 'MeeGo') ? 8890 : 8889);
if (!defined($port)) {
	$port = $default_port;
}
elsif ($port =~ m/^(\d{1,5})$/) {
	$port = $1;
	if ($port > 65535) {
		print STDERR "The port number is too large ($port). Default $default_port will be used instead.\n";
		$port = $default_port;
	}
}
else {
	print STDERR "Invalid port number specified ($port). Default $default_port will be used instead.\n";
	$port = $default_port;
}

my $LOG_FILE = "$APP_DATA/log/dc-server.log.$port";

$LOG_FILE =~ s/webapps\/webui\/\.\.\/\.\.\///g;

my $LOCK_FILE = "/tmp/dc-server.lock.$port";
my $first_log_line = "Log file refreshed. HTTP server is running on port '$port'. PID: $$.";

my %mime_types = ();
my %config = ();

# Adds the address/mask pair to the internal configuration structure.
# Returns 1 if address/mask pair is valid, 0 otherwise.
# TODO: Check for duplicates
sub addSubnetAddresses($$) {
	my ($addr, $mask) = @_;
	if ($addr eq 'LOCAL') {
		push @{$config{'AcceptConnections'}}, { 'ADDR' => 'LOCAL', 'MASK' => '' };
	}
	else {
		# Check the IP address for validity and create bit structure
		my $addr_bits = '';
		return 0 if ($addr !~ m/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/);
		return 0 if (($1 > 255) or ($2 > 255) or ($3 > 255) or ($4 > 255));
		vec($addr_bits, 0, 8) = $1;
		vec($addr_bits, 1, 8) = $2;
		vec($addr_bits, 2, 8) = $3;
		vec($addr_bits, 3, 8) = $4;

		# Check the network mask for validity and create bit structure
		my $mask_bits = '';
		if ($mask =~ m/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/) {
			# Mask is in the form like 192.168.0.1/255.255.255.0
			return 0 if (($1 > 255) or ($2 > 255) or ($3 > 255) or ($4 > 255));
			vec($mask_bits, 0, 8) = $1;
			vec($mask_bits, 1, 8) = $2;
			vec($mask_bits, 2, 8) = $3;
			vec($mask_bits, 3, 8) = $4;
			return 0 if ((sprintf '%08b%08b%08b%08b', $1, $2, $3, $4) !~ m/^1*0*$/);
		}
		elsif ($mask =~ m/^\d+$/) {
			# Mask is in the form like 192.168.0.1/24
			return 0 if ($mask > 32);
			if ($mask == 0) {
				vec($mask_bits, 0, 32) = 0;
			}
			else {
				vec($mask_bits, 0, 32) = (1 << (32 - $mask)) - 1;
				$mask_bits = ~ $mask_bits;
			}
		}
		else {
			return 0;
		}

		$addr_bits &= $mask_bits;
		push @{$config{'AcceptConnections'}}, { 'ADDR' => $addr_bits, 'MASK' => $mask_bits };
	}
	return 1;
}

sub formatIP($) {
	my ($ip) = @_;
	my $res = '';
	foreach (split(//, $ip)) {
		$res .= (($res eq '') ? '' : '.').sprintf('%d', ord($_));
	}
	return $res;
}

# Checks whether the client is allowed to connect.
sub isClientAllowed($) {
	my ($client) = @_;
	my $remote_addr = $client->peeraddr();
	my $local_addr = $client->sockaddr();
	my $allow = 0;
	my $log_info = "Processing AcceptConnections:\nRemote address: ".formatIP($remote_addr).'; local address: '.formatIP($local_addr)."\n";
	foreach my $subnet (@{$config{'AcceptConnections'}}) {
		if ($subnet->{'ADDR'} eq 'LOCAL') {
			$log_info .= 'Next subnet: LOCAL';
			if ($remote_addr eq $local_addr) {
				$allow = 1;
				$log_info .= " (matched)\n";
				last;
			}
			else {
				$log_info .= " (failed)\n";
			}
		}
		else {
			$log_info .= 'Next subnet: '.formatIP($subnet->{'ADDR'}).'/'.formatIP($subnet->{'MASK'});
			if (($remote_addr & $subnet->{'MASK'}) eq $subnet->{'ADDR'}) {
				$allow = 1;
				$log_info .= " (matched)\n";
				last;
			}
			else {
				$log_info .= " (failed)\n";
			}
		}
	}
	$log_info .= 'Verdict: Connection '.($allow ? 'allowed.' : 'refused.');
	LOG("[$$]: $log_info", 2);
	return $allow;
}

sub readConfFile($) {
	my ($errlog) = @_;
	# We need the $! variable outside the function left unchanged
	local $!;
	my $err_sub;
	if ($errlog) {
		$err_sub = sub($) { LOG("Reconf: $_[0]", 1); };
		LOG("Reloading the config file", 1);
	}
	else {
		$err_sub = sub($) { print STDERR "$_[0]\n"; };
	}

	# Reset settings to default
	%config = (
		'AcceptConnections' => [],
		'LogLevel' => 1,
		'DirectoryIndex' => ['index.html', 'index.htm', 'tests_view.pl'],
		'ProxyServer' => '',
		'ProxyServerAuth' => 'basic',
		'HTTPProxyServer' => '',
		'HTTPProxyServerAuth' => 'basic',
		'FTPProxyServer' => '',
		'FTPProxyServerAuth' => 'basic'
	);
	addSubnetAddresses('0.0.0.0', 0);

	if (open(CONFIG, $CONF_FILE)) {
		flock(CONFIG, LOCK_SH);

		my $line_num = 0;
		while (my $line = <CONFIG>) {
			++$line_num;
			if ($line =~ m/^[^\s#]/) {
				$line =~ s/[\r\n]//g;
				my ($key, $value) = split(/\s*=\s*/, $line, 2);
				if ($key eq 'AcceptConnections') {
					$config{'AcceptConnections'} = [];
					my @addresses = split(/\s+/, $value);
					foreach my $addr (@addresses) {
						my $error = 0;
						if ($addr eq 'LOCAL') {
							addSubnetAddresses('LOCAL', '');
						}
						elsif ($addr eq 'ALL') {
							addSubnetAddresses('0.0.0.0', 0);
						}
						elsif ($addr =~ m/^([0-9.]+)$/) {
							if (!addSubnetAddresses($1, 32)) {
								$error = 1;
							}
						}
						elsif ($addr =~ m/^([0-9.]+)\/([0-9.]+)$/) {
							if (!addSubnetAddresses($1, $2)) {
								$error = 1;
							}
						}
						else {
							$error = 1;
						}
						if ($error) {
							&$err_sub("Warning: Incorrect AcceptConnections value '$addr', skipping ($CONF_FILE:$line_num).");
						}
					}
				}
				elsif ($key eq 'LogLevel') {
					if ($value =~ m/^([0-2])$/) {
						$config{'LogLevel'} = $1;
					}
					else {
						&$err_sub("Warning: Incorrect LogLevel value '$value', skipping ($CONF_FILE:$line_num).");
					}
				}
				elsif ($key eq 'DirectoryIndex') {
					$config{'DirectoryIndex'} = [];
					foreach (split(/\s+/, $value)) {
						if (m/^([a-z0-9._][a-z0-9._\-]*)$/i) {
							push @{$config{'DirectoryIndex'}}, $1;
						}
						else {
							&$err_sub("Warning: Incorrect DirectoryIndex element '$_', skipping ($CONF_FILE:$line_num).");
						}
					}
				}
				elsif ($key =~ m/^(HTTP|FTP|)ProxyServer$/) {
					if ($value =~ m/^(?:([A-Za-z0-9\-_.\@]+)(?::(.*))?\@)?([A-Za-z0-9\-_.]+):(\d+)$/) {
						my ($puser, $ppasswd, $phost, $pport) = ($1, $2, $3, $4);
						if ($pport > 65535) {
							&$err_sub("Warning: Proxy port number is too large ($pport). $key key will be ignored ($CONF_FILE:$line_num).");
						}
						else {
							$config{$key} = $value;
						}
					}
					elsif ($value eq '') {
						$config{$key} = '';
					}
					else {
						&$err_sub("Warning: Incorrect $key value '$value', skipping ($CONF_FILE:$line_num).");
					}
				}
				elsif ($key =~ m/^(HTTP|FTP|)ProxyServerAuth$/) {
					if ($value =~ m/^(anyauth|basic|digest|ntlm|negotiate)(?:,notunnel)?$/) {
						$config{$key} = $value;
					}
					else {
						&$err_sub("Warning: Incorrect $key value '$value', skipping ($CONF_FILE:$line_num).");
					}
				}
				else {
					&$err_sub("Warning: Unknown configuration key found '$key', ignoring ($CONF_FILE:$line_num).");
				}
			}
		}
		if ($config{'ProxyServer'}) {
			$config{'HTTPProxyServer'} = $config{'ProxyServer'};
			$config{'HTTPProxyServerAuth'} = $config{'ProxyServerAuth'};
			$config{'FTPProxyServer'} = $config{'ProxyServer'};
			$config{'FTPProxyServerAuth'} = $config{'ProxyServerAuth'};
		}
		flock(CONFIG, LOCK_UN);
		close(CONFIG);
	}
	else {
		if ($errlog) {
			&$err_sub("Error: Failed to open the file $CONF_FILE for reading: $!");
		}
	}
}

readConfFile(0);

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Additional functions

sub LOG($$;$) {
	my ($msg, $level, $ignore_empty_log) = @_;
	return if ($level > $config{'LogLevel'});
	my $is_empty = !(-s $LOG_FILE);
	if (open(LOGFILE, ">>$LOG_FILE")) {
		flock(LOGFILE, LOCK_EX);
		seek(LOGFILE, 0, SEEK_END); # In the case if someone has written to the file in between open() and flock().
		my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime();
		my $date = sprintf('%02d.%02d.%04d %02d:%02d:%02d', $mday, ($mon + 1), ($year + 1900), $hour, $min, $sec);
		if ($is_empty and !$ignore_empty_log) {
			print LOGFILE "$date\t$first_log_line\n";
		}
		print LOGFILE "$date\t".$msg."\n";
		flock(LOGFILE, LOCK_UN);
		close(LOGFILE);
	}
}

sub HTTP_Response($$;$) {
	my ($client, $code, $connect_refused) = @_;
	my $info;
	if ($connect_refused) {
		$info = 'Connection from your IP address ('.$client->peerhost().') refused due to server configuration.<br />You need to specify the proper value for the <b>AcceptConnections</b> in the server config file on the host machine.<br />The config file location is specified in the README file.';
	}
	else {
		$info = 'Please contact the <a href="mailto:shaofeng.tang@intel.com">Intel MeeGo QA team</a> to report about this error.<br />See the <a href="/get.pl?file='.$LOG_FILE.'" target="_blank">server log file</a> for details.';
	}
	print $client "HTTP/1.0 $code" . Socket::CRLF;
	print $client Socket::CRLF;
	print $client <<DATA;
<html>
<head>
<title>$code</title>
</head>
<body>
<h1>$code</h1>
<p><br />
$info
</p>
</body>
</html>
DATA
	LOG("[$$]: Response: $code", 1);
	LOG("[$$]: HTTP response header:\nHTTP/1.0 $code", 2);
}

sub stopServer {
	LOG('Caught terminating signal for HTTP server. Stopping...', 1);
	flock(LOCKFILE, LOCK_UN);
	close(LOCKFILE);
	unlink($LOCK_FILE);
	exit;
}

$SIG{'HUP'} = sub($) { readConfFile(1); };
$SIG{'INT'}  = \&stopServer;
$SIG{'TERM'} = \&stopServer;
$SIG{'CHLD'} = 'IGNORE';

# Check if another Distribution Checker server is already running
# and if not, enter critical section.
if (open(LOCKFILE, '+>>'.$LOCK_FILE)) {
	if (flock(LOCKFILE, LOCK_EX | LOCK_NB)) {
		my $oldh = select(LOCKFILE);
		$| = 1;
		select($oldh);

		seek(LOCKFILE, 0, SEEK_SET);
		truncate(LOCKFILE, 0);

		print LOCKFILE 'G:'.$$;
	}
	else {
		seek(LOCKFILE, 0, SEEK_SET);
		my $pid = <LOCKFILE>;
		close(LOCKFILE);
		$pid =~ s/^G:(\d+)$/$1/;
		die "Error: An instance of Distribution Checker is running on the port '$port' already! (PID: $pid)\n";
	}
}
else {
	die "Error: Cannot open lock file $LOCK_FILE: $!\n";
}

my $server = new IO::Socket::INET(Proto => 'tcp',
                                  LocalPort => $port,
                                  Listen => SOMAXCONN,
                                  Reuse => 1);
unless ($server) {
print "error!!!\n";
	my $msg = "Could not create server socket on port '$port': $!";
	flock(LOCKFILE, LOCK_UN);
	close(LOCKFILE);
	unlink($LOCK_FILE);
	die $msg;
}

unlink($LOG_FILE);
LOG("Started HTTP server on port '$port'. PID: $$.", 1, 1);

if (open(EXT_INFO, "$SERVER_ROOT/mime.types")) {
	while (<EXT_INFO>) {
		if (/^[^\s#]/) {
			s/[\r\n]//g;
			my ($read_type, @read_exts) = split(/\s+/);
			foreach (@read_exts) {
				$mime_types{$_} = $read_type;
			}
		}
	}
	close(EXT_INFO);
}

chdir($DOCUMENT_ROOT);
while(1) {      # Protection from exiting from accept() on SIGHUP
	while (my $client = $server->accept()) {
		$client->autoflush(1);

		my $child = fork();
		if (!defined($child)) {
			LOG('Connection accepted. ERROR: Could not start fork!', 1);
			my $content_length = 0;
			while (<$client>) {     # Read the client's input (else browser doesn't accept the response)
				s/[\r\n]//g;
				if (m/^Content-Length:\s*(.*)/i) {
					$content_length = $1;
				}
				elsif (m/^$/) {
					if ($content_length) {
						my $tmp;
						read($client, $tmp, $content_length);
					}
					last;
				}
			}
			HTTP_Response($client, '500 Internal Server Error');
			close($client);
		}
		elsif ($child == 0) {
			$SIG{'CHLD'} = 'DEFAULT';
			select(undef, undef, undef, 0.1);
			LOG("Connection accepted. ID: $$.", 1);
			my $valid_http_req = 0;
			my %request = (
				'HOST' => $client->sockhost().':'.$client->sockport(),
				'METHOD' => '',
				'URL' => '',
				'HTTP_VERSION' => '',
				'GET_ARGS' => '',
				'POST_ARGS' => '',
				'COOKIES' => ''
			);
			{
				local $/ = Socket::CRLF;
				my $content_length = 0;

				my $full_request = '';
				my $is_first_line = 1;
				while (<$client>) {
					$full_request .= $_;
					s/[\r\n]//g;
					if ($is_first_line) {
						$is_first_line = 0;
						if (m/\s*(\w+)\s*([^\s\?]+)(\?([^\s]*))?\s*HTTP\/(\d\.\d)/) {
							$request{'METHOD'} = uc($1);
							$request{'URL'} = $2;
							$request{'HTTP_VERSION'} = $5;
							$request{'GET_ARGS'} = $4 ? $4 : '';
							$request{'GET_ARGS'} =~ s/#.*$//;
							$valid_http_req = 1;
							LOG("[$$]: Requested: $_", 1);
						}
						else {
							LOG("[$$]: Invalid request: $_", 1);
						}
					}
					else {
						# The request is valid, read and parse other parts of it
						if (m/^Content-Length:\s*(.*)/i) {
							$content_length = $1;
						}
						elsif (m/^Cookie:\s*(.*)/i) {
							$request{'COOKIES'} = $1;
						}
						elsif (m/^Host:\s*(.*)/i) {
							$request{'HOST'} = $1;
						}
						elsif (m/^$/) {
							if ($content_length) {
								read($client, $request{'POST_ARGS'}, $content_length);
								$full_request .= $request{'POST_ARGS'};
							}
							last;
						}
					}
				}
				$full_request =~ s/[\r\n]+$//s;             # Remove the last \n's, if present
				LOG("[$$]: HTTP request contents:\n$full_request", 2);
				$request{'URL'} =~ s/%([0-9a-fA-F]{2})/chr(hex($1))/eg;
			}

			# Respond as 400 Bad Request
			if (!$valid_http_req) {
				HTTP_Response($client, '400 Bad Request', 1);
				LOG("[$$]: Processing finished.", 1);
				close($client);
				close($server);
				exit;
			}

			# Check if the client is permitted to connect.
			if (!isClientAllowed($client)) {
				LOG("[$$]: ERROR: Remote address ".$client->peerhost().' is not allowed!', 1);
				HTTP_Response($client, '403 Forbidden', 1);
				LOG("[$$]: Processing finished.", 1);
				close($client);
				close($server);
				exit;
			}

			# process request
			if (($request{'METHOD'} eq 'GET') or ($request{'METHOD'} eq 'POST') or ($request{'METHOD'} eq 'HEAD')) {
				# Forbid '..' sequence inside URL
				if ($request{'URL'} =~ m/\.\./) {
					HTTP_Response($client, '403 Forbidden');
				}
				else {
					if ($request{'URL'} eq '/') {
						foreach (@{$config{'DirectoryIndex'}}) {
							if (-f $DOCUMENT_ROOT.'/'.$_) {
								$request{'URL'} = '/'.$_;
								last;
							}
						}
					}
					my $get_pl_pos = index($request{'URL'}, '/get.pl/');
					if ($get_pl_pos != -1) {
						$get_pl_pos += 7;
						$request{'GET_ARGS'} = 'file='.substr($request{'URL'}, $get_pl_pos);
						$request{'URL'} = substr($request{'URL'}, 0, $get_pl_pos);
					}

					my $localfile = $DOCUMENT_ROOT.$request{'URL'};
					if (-f $localfile) {
						my $buffer;
						my $is_executable = ($request{'URL'} =~ m/\.(pl|cgi|php)$/);
						my $opened;
						my $script_err_file = tmpnam();
						if ($is_executable) {
							$ENV{'DTKM_GET_ARGS'} = $request{'GET_ARGS'};
							$ENV{'DTKM_POST_ARGS'} = $request{'POST_ARGS'};
							$ENV{'DTKM_COOKIES'} = $request{'COOKIES'};
							$ENV{'DTKM_HOST'} = $request{'HOST'};
							$ENV{'DTKM_PEER_IP'} = $client->peerhost();
							$ENV{'DTKM_PORT'} = $port;
							$ENV{'DTKM_SERVER_PID'} = getppid();
							$ENV{'DTKM_DOCUMENT_ROOT'} = $DOCUMENT_ROOT;
							$ENV{'DTKM_APP_DATA'} = $APP_DATA;
							$ENV{'DTKM_CONF_FILE'} = $CONF_FILE;
							$ENV{'DTKM_PROXY'} = $config{'ProxyServer'};
							$ENV{'DTKM_PROXY_AUTH'} = $config{'ProxyServerAuth'};
							$ENV{'DTKM_HTTP_PROXY'} = $config{'HTTPProxyServer'};
							$ENV{'DTKM_HTTP_PROXY_AUTH'} = $config{'HTTPProxyServerAuth'};
							$ENV{'DTKM_FTP_PROXY'} = $config{'FTPProxyServer'};
							$ENV{'DTKM_FTP_PROXY_AUTH'} = $config{'FTPProxyServerAuth'};
							$localfile =~ s/([ ()\'])/\\$1/g;
							$opened = open(FILE, "$localfile 2>$script_err_file |");
						}
						else {
							$opened = open(FILE, $localfile);
						}
						if ($opened) {
							my $mime_type;
							my $first_line;
							my $response_hdr = '';
							my $null_output = 0;
							if ($is_executable) {
								$first_line = <FILE>;
								if (defined($first_line)) {
									print $client $first_line if ($client->connected);
									$first_line =~ s/[\r\n]//g;
									my $resp = $first_line;
									$first_line .= ' <from script>';
									while($resp ne '') {
										$response_hdr .= (($response_hdr eq '') ? '' : "\n").$resp;
										$resp = <FILE>;
										print $client $resp if ($client->connected);
										$resp =~ s/[\r\n]//g;
									}
								}
								else {
									$null_output = 1;
									$first_line = '<null> <from script>';
								}
							}
							else {
								my $ext = ($request{'URL'} =~ m/^.*\.([^\.]*)$/) ? $1 : '';
								$mime_type = ($mime_types{$ext} or 'text/html');
								$first_line = "HTTP/1.0 200 OK ($mime_type)";
								$response_hdr = 'HTTP/1.0 200 OK' . Socket::CRLF . 'Content-Type: ' . $mime_type;
								print $client $response_hdr . Socket::CRLF . Socket::CRLF;
							}
							while(<FILE>) {
								print $client $_ if ($client->connected and ($request{'METHOD'} ne 'HEAD'));
							}
							close(FILE);
							if ($is_executable) {
								my $err;
								if (open(ERR_FILE, $script_err_file)) {
									read(ERR_FILE, $err, -s $script_err_file);
									close(ERR_FILE);
								}
								if ($err) {
									LOG("[$$]: Error text received from script:\n$err", 1);
								}
								if ($null_output and (-s $script_err_file != 0)) {
									LOG("[$$]: Script execution error!", 1);
									HTTP_Response($client, '500 Internal Server Error');
								}
								else {
									LOG("[$$]: Response: $first_line", 1);
								}
							}
							else {
								LOG("[$$]: Response: $first_line", 1);
							}
							LOG("[$$]: HTTP response header:\n$response_hdr", 2);
						}
						else {
							HTTP_Response($client, '403 Forbidden');
						}
						unlink($script_err_file);
					}
					else {
						HTTP_Response($client, '404 Not Found');
					}
				}
			}
			else {
				HTTP_Response($client, '501 Not Implemented');
			}
			LOG("[$$]: Processing finished.", 1);
			close($client);
			close($server);
			exit;
		}
		else {
			close($client);
		}
	}
	# accept() fails if a signal was caught; errno == EINTR.
	# Catch this situation and continue listening to the port as if nothing happened.
	last if (!$!{'EINTR'});
}
