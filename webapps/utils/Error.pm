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

package Error;

use warnings;
use strict;

require Carp;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
	&is_err_obj &is_err &is_ok &error &join_errors
);

$Error::Depth = 0;  # Depth to pass to caller()
$Error::Debug = 0;  # Generate verbose stack traces

our $Last;  # Last error created

use overload (
	'""'       =>  sub { overload_error($_[0], "Using Error in a string context") },
	'0+'       =>  sub { overload_error($_[0], "Using Error in a numeric context") },
	'bool'     =>  sub { return; }, # return false
	'nomethod' =>  sub { overload_error($_[0], "Using Error in a weird way") },
	'fallback' =>  undef,
);

sub overload_error {
	my ($self, $msg) = @_;
	
	my (undef, $filename, $line) = caller($Error::Depth+1);
	$filename =~ s{.*/}{};

	local $Error::Debug = 0;
	warn "$msg at $filename line $line:\n".$self->tostring();
}
#----------------------------------------------------------------------

# Hack the import() subroutine to pick the "-debug" parameter
sub import {
	my ($module, @params) = @_;
	
	__PACKAGE__->export_to_level(1, $module);
	
	if ( grep { /-debug/ } @params ) {
		$Error::Debug = 1;
	}
}

sub my_caller {
	
	my (undef, $filename, $line) = caller($Error::Depth+1);
	$filename =~ s{.*/}{};
	
	my $subroutine;
	my $deeper = 2;
	{
		(undef, undef, undef, $subroutine) = caller($Error::Depth + $deeper);
		if ( !defined $subroutine ) { $subroutine = ""; }
		if ( $subroutine =~ /__ANON__/ ) { $deeper++; redo; }
		if ( $subroutine =~ /\(eval\)/ ) { $deeper++; redo; }
		#if ( $subroutine =~ /try/ ) { $subroutine = "try/catch"; }
	}
	
	return ($filename, $line, $subroutine);
}

sub new {
	my $self = shift;
	my ($text, $prev, @other ) = @_;
	
	if ( !defined($text) || ref($text) ne "" ) {
		$text = "Error::new: unexpected parameter \$text: '$text'";
	}
	$text =~ s/[\n\r]+$//; # Remove trailing line feeds
	
	if ( defined($prev) && !is_err_obj($prev) ) {
		# $prev is not an Error.
		if ( ref($prev) eq "" && $prev =~ /^-/ ) {
			unshift @other, $prev;
			$prev = undef;
		} else {
			$prev = $self->new("Error::new: unexpected parameter \$prev: '$prev'");
			@other = ();
			warn $prev->tostring();
		}
	}
	
	my $err = bless {
		-text => $text,
		-place => [ my_caller() ],
		-prev => $prev,
		@other
	};
	
	if ( 1 ) { # Always save the stack trace
		local $Carp::CarpLevel = $Error::Depth;
		my $trace = Carp::longmess();
		$err->{-stacktrace} = $trace;
	}
	
	return $err;
}
#----------------------------------------------------------------------

sub DESTROY {
	# Complain about unhandled errors
	if ( $Error::Debug ) {
		my $self = shift;
		
		if ( !$self->{-worked} ) {
			warn "Ignored error:\n".$self->tostring();
		}
		if ( defined $self->{-prev} ) {
			$self->{-prev}{-worked} = 1; # Mark as worked-out to avoid warnings
			$self->{-prev} = undef;
		}
	}
}
#----------------------------------------------------------------------

sub is_err_obj { UNIVERSAL::isa($_[0], __PACKAGE__) }

sub is_err {
	my ($self) = @_;
	
	if ( is_err_obj($self) ) {
		$Last = $self;
		if ( !$self->{-worked} ) {
			do {
				$self->{-worked} = 1; # Mark as worked-out
				$self = $self->{-prev};
			} while ( defined $self );
		}
		return 1; # Return true
	}
	# else: not an Error object
	$Last = undef;
	return; # Return false
}

sub is_ok { !&is_err }
#----------------------------------------------------------------------

sub first {
	my $self = shift;
	
	$self = $self->{-prev} while defined $self->{-prev};
	
	return $self;
}

sub tostring {
	my $self = shift;
	my ($prefix) = @_;
	
	if ( !is_err_obj($self) ) {
		warn "Error::tostring: wrong parameter";
		return "[not an Error!]";
	}
	
	if ( !defined $prefix ) { $prefix = " "; }
	my $marker = "";
	
	my $res = "";
	my $err = $self;
	
	LOOP: {
		$err->{-worked} = 1; # Mark as worked-out
		
		my $text = $err->{-text}; # Error text
		if ( $err->{-arr} ) { # joined errors
			# Re-create the -text, because tostring() options may be changed
			$text = join "\n", map $_->tostring($prefix), @{$err->{-arr}};
		}
		$text =~ s/[\r\n]+$//; # remove trailing linefeeds (if any)
		my $marker_sp = $marker; # =~ s/./ /g;
		$text =~ s/(\r*[\r\n])/$1$prefix$marker_sp/sg; # Add prefix
		$text = $prefix.$marker.$text;
		$res .= $text;
		
		if ( $Error::Debug && defined $err->{-place} ) { # subroutine and line number
			my ($filename, $line, $subroutine) = @{$err->{-place}};
			$res .= "\n".$prefix.$marker;
			$res .= "(".($subroutine ? "in $subroutine\() " : "")."at $filename:$line)";
		}
		$res .= "\n";
		
		if ( defined $err->{-prev} ) {
			# Previous error is usualy a cause of the current error
			$err = $err->{-prev};
			$prefix .= "   "; # increase indentation
			redo LOOP;
		}
	}
	
	# at the bottom
	#if ( $Error::Debug && defined $err->{-stacktrace} ) {
		#$res .= " Reported".$err->{-stacktrace};
	#}
	
	return $res;
}
#----------------------------------------------------------------------

sub error {
	local $Error::Depth = $Error::Depth + 1;
	
	( ref($_[0]) eq "" ) or die if $Error::Debug;
	
	return new Error(@_);
}
#----------------------------------------------------------------------

sub join_errors {
	my (@errors) = @_;

	my $err = error(join "\n", map $_->tostring, @errors);
	
	$err->{-place} = undef;
	$err->{-arr} = \@errors;
	
	return $err;
}

#----------------------------------------------------------------------

#----------------------------------------------------------------------
return 1;
