# Distribution Checker
# Module for Generating Lists of Tests (BuildList.pm)
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

package BuildList;
use strict;
use Exporter;
#use Manifest;
#use Packages;
use Common;
use Error;

@BuildList::ISA = 'Exporter';
@BuildList::EXPORT = (
	qw(
		@supported_archs
		&generate_profile_init
	),
	@Manifest::EXPORT
);

# $manifest: reference to the hash containing Manifest data
our $manifest;

# List of error messages
our @buildlist_errors = ();

# Supported architectures
our @supported_archs;

our @all_std_versions;

# %tests_tree: Categorized list of tests
# {std_version => {category => {'SUBCAT' => {subcategory => {'TESTS' => [test1, test2, ...] } } } } }
my %tests_tree;

# Builds the tree of tests from manifest data
# jenny:delete the Manifest related functions

# PUBLIC: Generates JS code for setting all options according to profile data.
# $page specifies the caller page ('cert' for 'Get Certified' or 'conf' for 'Custom Tests').
sub generate_profile_init($$) {
	my ($profile, $page) = @_;
	return '' if (!$profile);
	my %js_names = (
		'NAME' => 'tester_name',
		'ORGANIZATION' => 'organization',
		'EMAIL' => 'tester_email',
		'SEND_EMAIL' => 'send_email_report',
		'VERBOSE_LEVEL' => 'verbose_level',
		'ARCHITECTURE' => 'architecture',
		'USE_INTERNET' => 'use_internet',
		'STD_VERSION' => 'std_version',
		'STD_PROFILE' => 'std_profile',
		'COMMENTS' => 'comments'
	);

	my $current_std = $profile->{'GENERAL'}->{'STD_VERSION'};
	my $current_std_id = $current_std;
	$current_std_id =~ s/ /:/g;
	my $current_arch = $profile->{'GENERAL'}->{'ARCHITECTURE'};

	my $res = <<DATA;
	var elem;
	// Reset all values changed by user
	main_form.reset();

	elem = document.getElementById('architecture');
	if (elem) {
		elem.value = '$current_arch';
	}
	elem = document.getElementById('std_version');
	if (elem) {
		elem.value = '$current_std';
	}

DATA

	if ($page ne 'cert') {
		$res .= <<DATA;
	ts_file_inst = new Array();
	ts_file_dl = new Array();
	for (var arch_std in ts_expect_info) {
		for (var ts in ts_expect_info[arch_std]) {
			for (var status in ts_expect_info[arch_std][ts]) {
				for (var ver in ts_expect_info[arch_std][ts][status]) {
					for (var id in ts_expect_info[arch_std][ts][status][ver]) {
						var option = ts_expect_info[arch_std][ts][status][ver][id];
						option.answer = option.def_answer;
					}
				}
			}
		}
	}
	show_modules();
DATA
	}

	$res .= "\tvar to_set_value = new Array();\n";
	foreach my $name (qw/NAME ORGANIZATION EMAIL VERBOSE_LEVEL STD_PROFILE/) {
		my $val = $profile->{'GENERAL'}->{$name};
		if (defined($val)) {
			$val =~ s/'/\\'/g;
			$res .= "\tto_set_value['".$js_names{$name}."'] = '$val';\n";
		}
	}
	my $comments = $profile->{'GENERAL'}->{'COMMENTS'};
	if (defined($comments)) {
		$comments =~ s/\r?\n/\\n/g;
		$comments =~ s/'/\\'/g;
		$res .= "\tto_set_value['".$js_names{'COMMENTS'}."'] = '".$comments."';\n";
	}

	$res .= "\tvar to_set_check = new Array();\n";
	foreach my $name (qw/SEND_EMAIL USE_INTERNET/) {
		$res .= "\tto_set_check['".$js_names{$name}."'] = ".($profile->{'GENERAL'}->{$name} ? "1" : "0").";\n" if (defined($profile->{'GENERAL'}->{$name}));
	}

	$res .= <<DATA;

	for (var elem_id in to_set_check) {
		elem = document.getElementById(elem_id);
		if (elem) {
			elem.checked = to_set_check[elem_id];
		}
	}
	for (var elem_id in to_set_value) {
		elem = document.getElementById(elem_id);
		if (elem) {
			elem.value = to_set_value[elem_id];
		}
	}

DATA

	if ($page ne 'cert') {
		my $set_versions = '';
		my $expect_info = '';
		my $check_ts = '';
		if (defined($profile->{'TEST_SUITES'})) {
			foreach my $ts (keys %{$profile->{'TEST_SUITES'}}) {
				my $ts_info = $profile->{'TEST_SUITES'}->{$ts};
				if ($ts_info->{'RUN'}) {
					$check_ts .= "\tto_check_ts['$ts'] = 1;\n";
				}
				if ($ts_info->{'OPTIONS'}) {
					my $check_ts_tmp = '';
					foreach (keys %{$ts_info->{'OPTIONS'}}) {
						$check_ts_tmp .= "\tto_check_ts_opt['$ts']['$_'] = '".$ts_info->{'OPTIONS'}->{$_}."';\n";
					}
					if ($check_ts_tmp ne '') {
						$check_ts .= "\tto_check_ts_opt['$ts'] = new Array();\n".$check_ts_tmp;
					}
				}
				if ($ts_info->{'AUTO_REPLIES'}) {
					$expect_info .= "\tif (check_array_elem(ts_expect_info, '$current_arch-$current_std_id', '$ts')) {\n";
					foreach my $status (keys %{$ts_info->{'AUTO_REPLIES'}}) {
						$expect_info .= "\t\tif (ts_expect_info['$current_arch-$current_std_id']['$ts']['$status']) {\n";
						foreach my $ver (keys %{$ts_info->{'AUTO_REPLIES'}->{$status}}) {
							$expect_info .= "\t\t\telem = ts_expect_info['$current_arch-$current_std_id']['$ts']['$status']['$ver'];\n\t\t\tif (elem) {\n";
							my $auto_replies = $ts_info->{'AUTO_REPLIES'}->{$status}->{$ver};
							foreach my $id (keys %$auto_replies) {
								$expect_info .= "\t\t\t\tif (elem['$id']) {\n\t\t\t\t\telem['$id'].answer = '".(defined($auto_replies->{$id}) ? $auto_replies->{$id} : '[default]')."';\n\t\t\t\t}\n";
							}
							$expect_info .= "\t\t\t}\n";
						}
						$expect_info .= "\t\t}\n";
					}
					$expect_info .= "\t}\n";
				}
				if ($ts_info->{'STATUS'} and $ts_info->{'VERSION'}) {
					$set_versions .= "\tacceptVersion('$ts', '".$ts_info->{'STATUS'}."', '".$ts_info->{'VERSION'}."', false);\n";
				}
			}
		}

		$set_versions .= "\n" if ($set_versions ne '');
		$expect_info .= "\n" if ($expect_info ne '');

		if ($check_ts ne '') {
			$res .= <<DATA;
	var to_check_ts = new Array();
	var to_check_ts_opt = new Array();
$check_ts
	var cat_list = new Array();
	// Make a copy of the array mod_cat_list (for current arch-std only).
	for (var cat in mod_cat_list[current_arch_std]) {
		cat_list[cat] = mod_cat_list[current_arch_std][cat].slice(0);
	}
	for (var mod in to_check_ts) {
		// Remove the test suite from the array cat.
		for (var cat in cat_list) {
			for (var i=0; i<cat_list[cat].length; ++i) {
				if (cat_list[cat][i] == mod) {
					cat_list[cat].splice(i, 1);
					break;
				}
			}
		}
		elem = document.getElementById('mod-' + current_arch_std + '-' + mod);
		if (elem) {
			elem.checked = true;
		}
		if (to_check_ts_opt[mod]) {
			for (var opt_name in to_check_ts_opt[mod]) {
				var opt_value = to_check_ts_opt[mod][opt_name];
				var elems = document.getElementsByName('modopt-' + current_arch_std + '-' + mod + '-' + opt_name);
				if (elems) {
					for (var i=0; i<elems.length; ++i) {
						elems[i].checked = (elems[i].value == opt_value);
					}
				}
			}
		}
	}
	for (var cat in cat_list) {
		elem = document.getElementById('check-' + cat + '-' + current_arch_std);
		if (elem) {
			elem.checked = ((cat_list[cat].length > 0) ? false : true);
		}
	}

DATA
		}

		if (defined($profile->{'FILES'})) {
			foreach my $file (keys %{$profile->{'FILES'}}) {
				if ($profile->{'FILES'}->{$file}->{'DOWNLOAD'}) {
					$res .= "\tts_file_dl['$file'] = ".$profile->{'FILES'}->{$file}->{'DOWNLOAD'}.";\n";
				}
				if ($profile->{'FILES'}->{$file}->{'INSTALL'}) {
					$res .= "\tts_file_inst['$file'] = ".$profile->{'FILES'}->{$file}->{'INSTALL'}.";\n";
				}
			}
			$res .= "\n";
		}

		$res .= $expect_info;
		$res .= $set_versions;
		$res .= "\tupdate_elements_state();\n";
	}
	else {
		$res .= "\tcontrol_profile_list();\n";
	}
	$res .= "\telem = document.getElementById('std_profile');\n\tif (elem) {\n\t\telem.value = to_set_value['std_profile'];\n\t}\n";

	return $res;
}

################################################################################
# Initialization code

sub init() {
	#$Packages::package_manager = guess_package_manager(detect_OS());
	
	# Load the Manifest
	#$manifest = load_manifest();
	#if (!is_ok($manifest)) {
	#	push @buildlist_errors, error("Failed to load manifest", $Error::Last)->tostring;
	#	return;
	#}
	#@all_std_versions = @{$manifest->{'ALL'}->{'STANDARDS'}};

	# Detect the architecture
	my $arch = detect_architecture();
	if (!$arch) {
		push @buildlist_errors, "Can't determine the machine architecture";
		return;
	}
	@supported_archs = backward_compatible_platforms($arch);

	# Build the tests tree
	#build_tests_tree();
}


init();

1;
