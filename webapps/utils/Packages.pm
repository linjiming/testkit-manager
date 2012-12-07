# Copyright (C) 2012 Intel Corporation
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
# Authors:
#              Zhang, Huihui <huihuix.zhang@intel.com>
#              Wendong,Sui  <weidongx.sun@intel.com>

package Packages;
use strict;

use Common;

# Export symbols
require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(
  &guess_package_manager
  &package_info &packages_info
  &install_package &remove_package
);

#----------------------------------------------------------------------

our $package_manager = undef;
our $cache           = {};      # The cache is disabled when set to undef

#----------------------------------------------------------------------

# Determines which package manager to use.
# Returns "rpm", "dpkg" or undef.
sub guess_package_manager {
	my ($host_os) = @_;

	if ( $host_os =~ /(suse|red\W?hat|asianux|mandriva|turbolinux|gentoo)/i ) {

		# Native package manager for Suse and Redhat is rpm
		return "rpm";
	}
	elsif ( $host_os =~ /(ubuntu|debian|freespire|linspire|rays.?lx)/i ) {

		# For Debian and Ubuntu use alien and dpkg.
		return "dpkg";
	}
	else {
		if ( does_shell_know("dpkg") ) {
			return "dpkg";
		}
		else {
			return "rpm";
		}
	}
	return undef;
}

#---------------------------------------------------------------------
# Check if rpm package is installed
# If $arch is specified, architecture of the package is also checked.
# Returns version of installed package, or "" if not installed (or errors).
# Used by function package_info().
sub rpm_package_info {
	my ( $package_name, $arch ) = @_;

	if ( $cache && defined $cache->{$package_name} ) {
		if ( $arch && exists $cache->{$package_name}{$arch} ) {
			return $cache->{$package_name}{$arch};
		}
	}

	my $result = capture(
		"rpm -q --qf '\%{ARCH}\\t\%{VERSION}-\%{RELEASE}\\n' --whatprovides "
		  . shq($package_name)
		  . " 2>/dev/null" );
	chomp $result;

	if ( $? != 0 ) {
		return undef;
	}    # Non-zero exit code means the package is not installed.

	my ( $package_arch, $version ) = split /[\t\n\r]/, $result;

	if ( defined $arch ) {

		# check the package architecture
		$package_arch = guess_architecture( $package_arch, "noarch" );
		unless ( $package_arch eq "noarch" ) {
			if ( $package_arch ne $arch ) {
				$version = undef;    # wrong architecture - not installed.
			}
		}
		if ( $cache && $arch ) {
			$cache->{$package_name}{$arch} = $version;
		}
	}

	return $version;
}

#---------------------------------------------------------------------

# Check if deb package is installed
# If $arch is specified, architecture of the package is also checked.
# Returns version of installed package, or "" if not installed (or errors).
# Used by function package_info().
sub dpkg_package_info {
	my ( $package_name, $arch ) = @_;

	$package_name =~ s/_/-/g;    # alien replaces "_" to "-" in package names.

	if ( $cache && defined $cache->{$package_name} ) {
		if ( $arch && exists $cache->{$package_name}{$arch} ) {
			return $cache->{$package_name}{$arch};
		}
	}

	# TODO: ${MD5sum} may be used to check installed package.
	my $result = capture(
		    "dpkg-query -W -f='\${Architecture}\\t\${Version}\\t\${Status}\\n' "
		  . shq($package_name)
		  . " 2>/dev/null" );
	chomp $result;

	if ( $? != 0 ) {
		return undef;
	}    # Ignore the error. Return undef, which means 'not installed'.

	my ( $package_arch, $version, $status ) = split /[\t\n\r]/, $result;

	if ( !defined $status || $status !~ m/\w+\s+ok\s+installed/ ) {
		return undef;    # not installed
	}

	if ( defined $arch ) {

		# check the package architecture
		$package_arch = guess_architecture( $package_arch, "noarch" );
		unless ( $package_arch eq "noarch" ) {
			if ( $package_arch ne $arch ) {
				$version = undef;    # wrong architecture - not installed.
			}
		}
		if ($cache) {
			$cache->{$package_name}{$arch} = $version;
		}
	}

	return $version;
}

#---------------------------------------------------------------------

# Returns info about installed package,
# or empty string if the package isn't installed (or in case of errors).
sub package_info {
	my (@params) = @_;

	( defined $package_manager ) or fail "Package manager is undefined";

	if ( $package_manager eq "rpm" ) {
		return rpm_package_info(@params);
	}
	elsif ( $package_manager eq "dpkg" ) {
		return dpkg_package_info(@params);
	}

	fail "Unknown package manager: '$package_manager'";
}

#-----------------------------------------------------------------------

# Enquire rpm package manager about state of several packages.
# Returns structure $packages->{$package_name}{VERSIONS}{$package_ver} = 1;
# Used by function packages_info().
sub rpm_packages_info {
	my ($packages) = @_;

	my $result = {};
	return $result if ( !$packages || !%$packages );

	my $resp = capture(
"rpm -q --qf '\%{ARCH}\\t\%{NAME}\\t\%{VERSION}-\%{RELEASE}\\n' --whatprovides "
		  . ( join " ", map shq($_), sort keys %$packages )
		  . " 2>/dev/null" );
	my @lines = split( /\n/, $resp );

	while (@lines) {
		my $line = shift @lines;

		my ( $package_arch, $package_name, $package_ver ) = split /[\t\n\r]/,
		  $line;
		next if !defined $package_ver;    # wrong line
		next
		  if !
			  exists
			  $packages->{$package_name};    # it should be undefined, but exist
		$package_arch = guess_architecture( $package_arch, "noarch" );
		my @arch = ();
		if ($package_arch) {
			push @arch, $package_arch;
			if ( $package_arch eq 'noarch' ) {
				push @arch, @all_archs;
			}
		}
		for my $arch (@arch) {
			$result->{$package_name}{$arch}{$package_ver} = 1;

			if ($cache) {
				$cache->{$package_name}{$arch} = $package_ver;
			}
		}
	}

	return $result;
}

# Enquire dpkg package manager about state of several packages.
# Returns structure $packages->{$package_name}{VERSIONS}{$package_ver} = 1;
# Used by function packages_info().
sub dpkg_packages_info {
	my ($packages) = @_;

	my $result = {};
	return $result if ( !$packages || !%$packages );

	s/_/-/g for keys %$packages;   # alien replaces "_" to "-" in package names.

	my $resp = capture(
"dpkg-query -W -f='\${Architecture}\\t\${Package}\\t\${Version}\\t\${Status}\\n' "
		  . ( join " ", map shq($_), sort keys %$packages )
		  . " 2>/dev/null" );
	my @lines = split( /\n/, $resp );

	while (@lines) {
		my $line = shift @lines;

		my ( $package_arch, $package_name, $package_ver, $status ) =
		  split /[\t\n\r]/, $line;

		next if ( !defined $status || $status !~ m/\w+\s+ok\s+installed/ );
		next
		  if !
			  exists
			  $packages->{$package_name};    # it should be undefined, but exist
		$package_arch = guess_architecture( $package_arch, "noarch" );
		my @arch = ();
		if ($package_arch) {
			push @arch, $package_arch;
			if ( $package_arch eq 'noarch' ) {
				push @arch, @all_archs;
			}
		}
		for my $arch (@arch) {
			$result->{$package_name}{$arch}{$package_ver} = 1;

			if ($cache) {
				$cache->{$package_name}{$arch} = $package_ver;
			}
		}
	}

	return $result;
}

# Enquire package manager about state of several packages.
# Returns structure $packages->{$package_name}{VERSIONS}{$package_ver} = 1;
sub packages_info {
	my (@params) = @_;

	( defined $package_manager )
	  or return error("Package manager is undefined");

	if ( $package_manager eq "rpm" ) {
		return rpm_packages_info(@params);
	}
	elsif ( $package_manager eq "dpkg" ) {
		return dpkg_packages_info(@params);
	}

	fail "Unknown package manager: '$package_manager'";
}

#-----------------------------------------------------------------------

# Install the specified package file.
# The function caller should check the result by calling package_info() then.
sub install_package {
	my ( $package_file, $temp_dir ) = @_;

	$cache = undef;    # disable the cache

	# Check that package_file exists
	unless ( -f $package_file ) {
		return error("File doesn't exist (or not a file): $package_file");
	}

	# Install it.
	inform "Installing '$package_file'";

	if ( $package_manager eq "rpm" ) {

		# Check the file
		if ( $package_file =~ /\.rpm$/ ) {
			cmd( "rpm -i " . shq($package_file) ) == 0
			  or inform
			  "!!! Warning: Installation of '$package_file' may be failed";
			return
			  1;    # Caller should check the result by calling package_info().
		}

		# else
		return ( error("Not an RPM package: '$package_file'") );
	}
	elsif ( $package_manager eq "dpkg" ) {

		# Check the file
		if ( $package_file =~ /\.deb$/ ) {
			cmd( "dpkg -i " . shq($package_file) ) == 0
			  or inform
			  "!!! Warning: Installation of '$package_file' may be failed";
			return
			  1;    # Caller should check the result by calling package_info().
		}
		elsif ( $package_file =~ /\.rpm$/ ) {

			# Using alien to convert .rpm to .deb

			# An rpm package is first converted to a deb, then installed.
			# It's not Ok to install it straightway using 'alien -ick' command,
			# because some old versions of alien have an issue
			# related to execution of control scripts when -i option is used.

			( defined $temp_dir ) or return error("Temporary dir is undefined");
			my $convert_dir = $temp_dir . '/alien-convert';
			create_empty_directory($convert_dir) == 1
			  or return error(
				"Failed to create directory for convertation: '$convert_dir'",
				$Error::Last );
			my $resp =
			  capture( "cd "
				  . shq($convert_dir)
				  . " && alien -d -c -k "
				  . shq($package_file) );
			if ( $? != 0 ) {
				inform "!!! Warning: Alien may be failed on '$package_file'";
			}
			my $resp_orig = $resp;

			# expected response: "package_name.deb generated"
			chomp $resp;
			$resp =~ s/([^\n\x0D]*[\n\x0D])*//sg;  # Leave only the last line;
			$resp =~ s/ .*//;                      # Remove error message if any
			if ( !$resp || $resp !~ /\.deb$/ || !-f $convert_dir . "/" . $resp )
			{
				cmd( "rm -rf " . shq($convert_dir) );    # to free space
				return error("Failed to parse the response:\n$resp_orig");
			}

			cmd( "dpkg -i " . shq( $convert_dir . "/" . $resp ) ) == 0
			  or inform
			  "!!! Warning: Installation of '$package_file' may be failed";

			return
			  1;    # Caller should check the result by calling package_info().
		}
	}
}

#----------------------------------------------------------------------------

# Uninstall the specified package if it is installed.
# The function caller should check the result by calling package_info() then.
sub remove_package {
	my ($package_name) = @_;

	$cache = undef;    # disable the cache

	# Check whether the package is installed.
	my $ver = package_info($package_name);
	if ( !defined $ver ) {

		# The package seems not to be installed.
		return 1;      # OK
	}

	# The package seems to be installed, trying to uninstall it.

	# Failure to uninstall package is (mostly) not fatal.
	if ( $package_manager eq "rpm" ) {
		cmd( "rpm -e --allmatches --nodeps " . shq($package_name) . " 2>&1" );
	}
	elsif ( $package_manager eq "dpkg" ) {
		$package_name =~ s/_/-/g; # alien replaces "_" with "-" in package names
		cmd( "dpkg -P " . shq($package_name) . " 2>&1" );
	}

	return 1;                     # OK
}

#----------------------------------------------------------------------

#-----------------------------------------------------------------------

return 1;
