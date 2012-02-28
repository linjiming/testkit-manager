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
#
#   Authors:
#
#          Tang, Shao-Feng  <shaofeng.tang@intel.com>
#

package ParseResult;

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(readProfileResults);
@EXPORT_OK = qw();

use strict;
use Data::Dumper;

sub readProfileResults{
	my ($profile_path, $result_dir) = @_;

	my @packages;
	if (open(FILE, $profile_path)) {
		while (<FILE>) {
			my $line = $_;
			if ($line !~ s/(\[Auto\]|\[Manual\])// ){
				$line =~ s/\n//g;
				push (@packages, "$result_dir/$line/result.tests.xml");
			}
		}
		close(FILE);
		#$logger->log(message =>  "[Parsing Results] Result files: \n".Dumper @packages);
	}else{
		#$logger->log(message =>  "[Parsing Results]:Fail to read the profile:$profile_path");
	}
	
	return \@packages;
}

1;