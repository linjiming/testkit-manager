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
#

package TestKitLogger;

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(log);
@EXPORT_OK = qw($logger);

#use Log::Log4perl::Appender::File;

#our $logger = Log::Log4perl::Appender::File->new(
#      filename  => 'file.log',
#      mode      => 'append',
#      autoflush => 1,
#      umask     => 0222,
#    );
our $logger = new TestKitLogger;

my $logFile = '>>../../../log/testkit-manager.log';
my $recordLog = 0;

sub new {
	my $this={};
	bless $this;
	return $this;
}

sub log{
	if($recordLog){
		my ($thisObj, $level, $msg) = @_;	
		if($msg){
			my $now_string = localtime;
			if (open ($logFH, $logFile)){
				print $logFH "$now_string\t $msg\n";
				close($logFH);
			}
		}
	}
}

1;