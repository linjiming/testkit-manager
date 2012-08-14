/**
 * 
 * Copyright (C) 2010 Intel Corporation
 * 
 * This program is written by Shaofeng Tang <shaofeng.tang@intel.com> This
 * program is free software; you can redistribute it and/or modify it under the
 * terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 2 of the License, or (at your option) any later
 * version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 * 
 * You should have received a copy of the GNU General Public License along with
 * this program; if not, write to the Free Software Foundation, Inc., 51
 * Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 * 
 * Authors:
 * 
 * Tang, Shao-Feng <shaofeng.tang@intel.com>
 * 
 * Changlog:
 * 
 * 07/16/2010, submit the first version.
 */

function setOpacity(elem, opacity_value) {
	var pos_elem = getPosition(elem);
	var drag_rect = {
		l : pos_elem.x,
		r : pos_elem.x + elem.offsetWidth,
		t : pos_elem.y,
		b : pos_elem.y + elem.offsetHeight
	};
	var pos_cmdlog = getPosition(cmdlog);
	var cons_rect = {
		l : pos_cmdlog.x,
		r : pos_cmdlog.x + cmdlog.offsetWidth,
		t : pos_cmdlog.y,
		b : pos_cmdlog.y + cmdlog.offsetHeight
	};
	if ((cons_rect.l <= drag_rect.r) && (drag_rect.l <= cons_rect.r)
			&& (cons_rect.t <= drag_rect.b) && (drag_rect.t <= cons_rect.b)) {
		elem.style.opacity = opacity_value;
		// IE opacity support
		elem.style.filter = 'alpha(opacity=' + (opacity_value * 100) + ')';
	}
}

function format_time(tm) {
	var h = Math.floor(tm / 3600);
	var m = Math.floor(tm / 60 - h * 60);
	var s = tm - h * 3600 - m * 60;
	return h + ':' + ((m < 10) ? '0' + m : m) + ':' + ((s < 10) ? '0' + s : s);
}

function updateTestTimer() {
	var next_call_period = 1000;
	test_timer_var = setTimeout('updateTestTimer()', next_call_period);
}

function stopTests() {
	if (confirm('Are you sure to terminate test execution?')) {
		if (stop_button)
			stop_button.disabled = true;
		exec_info.innerHTML = 'Tests are stopping&hellip;';
		ajax_call_get('action=stop_tests&tree=tests');
	}
}

function startTestsPrepareGUI() {
	if (start_button)
		start_button.disabled = true;
	if (stop_button)
		stop_button.disabled = false;
	if (test_profile)
		test_profile.disabled = true;
	exec_info.innerHTML = 'Preparing to run the tests&hellip;';
	exec_status.innerHTML = '&nbsp;&nbsp;&nbsp;<img src="images/ajax_progress.gif" width="16" height="16" alt="" />';
	cmdlog.innerHTML = '';
	cmdlog.style.color = 'black';
	log_contents = '';
	last_line = '';
}

function startTests(profile_name) {
	if (!profile_name || profile_name == '') {
		var profile = document.getElementById('test_profile');
		if (profile) {
			if (profile.value) {
				profile_name = profile.value;
			} else {
				alert('Profile is not specified!');
				return;
			}
		} else {
			alert("Internal error: Cannot find 'profile' form field! Please, contact the authors.!");
			return;
		}
	}
	global_profile_name = profile_name;
	startTestsPrepareGUI();
	// alert("RunTest.js: " + profile_name);
	ajax_call_get('action=run_tests&profile='
			+ encodeURIComponent(profile_name));
}

function startRefresh() {
	exec_info.innerHTML = 'Test cases are running &hellip;';
	exec_status.innerHTML = '&nbsp;&nbsp;&nbsp;<img src="images/ajax_progress.gif" width="16" height="16" alt="" />';
	cmdlog.innerHTML = '';
	cmdlog.style.color = 'black';
	log_contents = '';
	last_line = '';
	start_button.disabled = true;
	stop_button.disabled = false;
	for ( var i = 0; i < test_profile.length; i++) {
		if (test_profile.options[i].value == "temp_profile") {
			test_profile.options[i].selected = true;
		}
	}
	var view = test_profile.value;
	var page = document.getElementsByTagName("*");
	for ( var i = 0; i < page.length; i++) {
		var temp_id = page[i].id;
		if (temp_id.indexOf("progress_bar_") >= 0) {
			page[i].style.display = "none";
			if (temp_id == "progress_bar_" + view) {
				page[i].style.display = "";
			}
		}
	}
	test_profile.disabled = true;
	ajax_call_get('action=get_test_log&start=0');
	updateTestTimer();
}

function make_merge(line) {
	var tmp;
	// Make every ^M control character (\\x0d) erase all from the beginning of
	// line
	while (1) {
		re_x0d.lastIndex = 0;
		tmp = line.replace(re_x0d, '');
		if (tmp != line)
			line = tmp;
		else
			break;
	}
	return line;
}

function updateCmdLog(txt) {
	var scroll_top = cmdlog.scrollTop;
	var scroll_height = cmdlog.scrollHeight;
	var auto_scroll = (scroll_height - cmdlog_height - scroll_top < 10);
	last_line += txt;
	var fnewln_pos = last_line.indexOf('\\n');
	var lnewln_pos = last_line.lastIndexOf('\\n');

	if (fnewln_pos == -1) {
		// merge and make new last_line
		last_line = make_merge(last_line);
	} else {
		// block1 (till first '\\n'): for merging and adding to log_contents
		// block2 (from first till last '\\n'): for adding to log_contents (no
		// merging needed)
		// block3 (after last '\\n'): to be the new last_line (no merging
		// needed)
		log_contents += make_merge(last_line.substring(0, fnewln_pos + 1))
				+ last_line.substring(fnewln_pos + 1, lnewln_pos + 1);
		last_line = last_line.substring(lnewln_pos + 1);
	}
	if (typeof (cmdlog.innerText) == 'undefined')
		cmdlog.textContent = log_contents + last_line;
	else
		cmdlog.innerText = log_contents + last_line;
	if (auto_scroll) {
		cmdlog.scrollTop = cmdlog.scrollHeight;
		cmdlog.scrollTop = cmdlog.scrollHeight; // IE fix
	}
}

function ajaxProcessResult(responseXML) {

	var tid;

	/*
	 * if (responseXML.getElementsByTagName('progress').length > 0) { var
	 * progress_data = responseXML.getElementsByTagName('progress')[0]; var
	 * testsuites_data = progress_data.getElementsByTagName('testsuite');
	 * 
	 * var id = testsuites_data[0].getAttribute('id'); var status =
	 * testsuites_data[0].getElementsByTagName('status')[0].childNodes[0].nodeValue;
	 * var percent =
	 * testsuites_data[0].getElementsByTagName('percent')[0].childNodes[0].nodeValue;
	 * var progress_width = Math.round(percent * 1.0);
	 * 
	 * var percent_value = document.getElementById('percent');
	 * percent_value.innerHTML = percent + '%'; var percent_bar =
	 * document.getElementById('progress_bar'); percent_bar.style.width =
	 * progress_width + '%'; }
	 */
	if (responseXML.getElementsByTagName('network_connection_timeout').length > 0) {
		document.getElementById('error_msg_area').style.display = "";
		document.getElementById('error_msg_text').innerHTML = "failed: Connection timed out";
		document.getElementById('progress_waiting').style.display = "none";
		document.getElementById('select_arc').disabled = false;
		document.getElementById('select_ver').disabled = false;
		document.getElementById('sort_packages').onclick = function() {
			return sortPackages();
		}
		document.getElementById('sort_packages').style.cursor = "pointer";
		document.getElementById('button_adv').disabled = false;
		document.getElementById('update_package_list').disabled = false;
		document.getElementById('load_profile_button').disabled = false;
		document.getElementById('delete_profile_button').disabled = false;
	}

	if (responseXML.getElementsByTagName('no_package_update_or_install').length > 0) {
		alert("No packages need to install or update!");

		document.getElementById('update_package_list').disabled = false;
		document.getElementById('select_arc').disabled = false;
		document.getElementById('select_ver').disabled = false;
		document.getElementById('sort_packages').onclick = function() {
			return sortPackages();
		}
		document.getElementById('sort_packages').style.cursor = "pointer";
		document.getElementById('button_adv').disabled = false;
		document.getElementById('load_profile_button').disabled = false;
		document.getElementById('delete_profile_button').disabled = false;
		document.getElementById('progress_waiting').style.display = "none";

	}

	if (responseXML.getElementsByTagName('uninstall_package_name').length > 0) {
		uninstall_pkg_name = responseXML
				.getElementsByTagName('uninstall_package_name')[0].childNodes[0].nodeValue;
		uninstall_pkg_version = responseXML
				.getElementsByTagName('uninstall_package_version')[0].childNodes[0].nodeValue;
		install_pkg_update_flag = responseXML
				.getElementsByTagName('update_package_flag')[0].childNodes[0].nodeValue;
		uninstall_pkg_name_arr = uninstall_pkg_name.split(" ");
		uninstall_pkg_version_arr = uninstall_pkg_version.split(" ")
		install_pkg_update_flag_arr = install_pkg_update_flag.split(" ");
		for ( var i = 0; i < install_pkg_update_flag_arr.length; i++) {
			if (install_pkg_update_flag_arr[i] == "a") {
				var update_pkg_id_temp = "update_package_name_" + i;
				var update_pkg = "update_"
						+ document.getElementById(update_pkg_id_temp).value;
				var update_pkg_id = document.getElementById(update_pkg);
				update_pkg_id.title = "Update package";
				update_pkg_id.style.cursor = "pointer";
				update_pkg_id.src = "images/operation_update.png";
				update_pkg_id.onclick = function(num) {
					return function() {
						updatePackage(num);
					};
				}(i);
			}
		}
		document.getElementById('update_package_list').disabled = false;
		document.getElementById('select_arc').disabled = false;
		document.getElementById('select_ver').disabled = false;
		document.getElementById('sort_packages').onclick = function() {
			return sortPackages();
		}
		document.getElementById('sort_packages').style.cursor = "pointer";
		document.getElementById('button_adv').disabled = false;
		document.getElementById('update_package_list').disabled = false;
		document.getElementById('load_profile_button').disabled = false;
		document.getElementById('delete_profile_button').disabled = false;
		// document.getElementById('update_package_list').value = "Reload";
		// document.getElementById('update_package_list').title = "Refresh
		// current page and load only installed packages, so you can start
		// testing.";
		document.getElementById('update_package_list').onclick = function() {
			document.getElementById('update_package_list').disabled = true;
			// document.location = "tests_custom.pl";
			return onUpdatePackages();
		};
		for ( var i = 0; i < uninstall_pkg_name_arr.length; i++) {
			var id = "uninstall_" + i;
			var pkg_name_id = "pn_" + i;
			var pkg_ver_id = "ver_" + i;
			if (uninstall_pkg_name_arr[i].indexOf("-") >= 0) {
				document.getElementById(id).style.display = "";
				document.getElementById(pkg_name_id).innerHTML = uninstall_pkg_name_arr[i];
				document.getElementById(pkg_name_id).title = uninstall_pkg_name_arr[i];
				document.getElementById(pkg_ver_id).innerHTML = uninstall_pkg_version_arr[i];
			}
		}
		document.getElementById('progress_waiting').style.display = "none";
		// Update packages successfully!;
	}
	if (responseXML.getElementsByTagName('execute_profile_name').length > 0) {
		tid = responseXML.getElementsByTagName('execute_profile_name')[0].childNodes[0].nodeValue;
		document.location = 'tests_execute.pl?profile=' + tid;
	}

	if (responseXML.getElementsByTagName('save_profile_success').length > 0) {
		tid = responseXML.getElementsByTagName('save_profile_success')[0].childNodes[0].nodeValue;
		var count = 0;
		for ( var i = 0; i < msg.length; i++) {
			if (msg[i] == tid) {
				count++;
			}
		}
		if (count == "0") {
			msg.push(tid);
		}
		alert("Profile saved successfully.");
	}
	if (responseXML.getElementsByTagName('load_profile').length > 0) {
		var packages_isExist_flag_arr = new Array();
		var packages_need_arr = new Array();
		var packages_isExist_flag = responseXML
				.getElementsByTagName('packages_isExist_flag')[0].childNodes[0].nodeValue;
		var packages_need = responseXML.getElementsByTagName('packages_need')[0].childNodes[0].nodeValue;
		var message_not_load = "";
		var load_flag = 1;

		packages_isExist_flag_arr = packages_isExist_flag.split(" ");
		packages_need_arr = packages_need.split("tests");

		for ( var i = 0; i < packages_need_arr.length; i++) {
			if (packages_isExist_flag_arr[i] == 0) {
				load_flag = 0;
				message_not_load = message_not_load + packages_need_arr[i]
						+ "tests";
			}
		}
		if (load_flag == 0) {
			alert("The following packages from the profile are not installed:\n"
					+ message_not_load);
			document.getElementById('load_profile_button').disabled = false;
		} else {
			document.location = "tests_custom.pl?load_profile_button="
					+ edit_profile_name.value;
		}
	}
	if (responseXML.getElementsByTagName('delete_profile_success').length > 0) {
		tid = responseXML.getElementsByTagName('delete_profile_success')[0].childNodes[0].nodeValue;
		for ( var i = 0; i < msg.length; i++) {
			if (msg[i] == tid) {
				msg.splice(i, 1);
			}
		}
		edit_profile_name.value = "";
		alert("Profile deleted successfully.");
	}
	if (responseXML.getElementsByTagName('check_profile_name').length > 0) {
		tid = responseXML.getElementsByTagName('check_profile_name')[0].childNodes[0].nodeValue;
		var sel_arc = document.getElementById("select_arc");
		var sel_ver = document.getElementById("select_ver");
		var sel_category = document.getElementById("select_category");
		var sel_pri = document.getElementById("select_pri");
		var sel_status = document.getElementById("select_status");
		var sel_exe = document.getElementById("select_exe");
		var sel_testsuite = document.getElementById("select_testsuite");
		var sel_type = document.getElementById("select_type");
		var sel_testset = document.getElementById("select_testset");
		var sel_com = document.getElementById("select_com");
		var package_name_number = document
				.getElementById("package_name_number");

		var checkbox_value = new Array();
		var arc = sel_arc.value;
		var ver = sel_ver.value;
		var category = sel_category.value;
		var pri = sel_pri.value;
		var status = sel_status.value;
		var exe = sel_exe.value;
		var testsuite = sel_testsuite.value;
		var type = sel_type.value;
		var testset = sel_testset.value;
		var com = sel_com.value;
		var pkg_num = package_name_number.value;
		var advanced = arc + '*' + ver + '*' + category + '*' + pri + '*'
				+ status + '*' + exe + '*' + testsuite + '*' + type + '*'
				+ testset + '*' + com;
		var webapi_flag = "0";
		for ( var count = 0; count < pkg_num; count++) {
			var checkbox_package_name_tmp = "checkbox_package_name" + count;
			var checkbox_package_name = document
					.getElementById(checkbox_package_name_tmp);
			var temp = checkbox_package_name.name;
			if (checkbox_package_name.checked) {
				if (webapi_flag == "0") {
					if (temp.indexOf('webapi') > 0) {
						webapi_flag = "1";
					} else {
						webapi_flag = "2";
					}
				} else if (webapi_flag == "1") {
					if (temp.indexOf('webapi') < 0) {
						webapi_flag = "yes";
					}
				} else if (webapi_flag == "2") {
					if (temp.indexOf('webapi') > 0) {
						webapi_flag = "yes";
					}
				}
				checkbox_value[count] = "select" + checkbox_package_name.name;
			} else {
				checkbox_value[count] = checkbox_package_name.name;
			}
		}
		if (tid == "save") {
			if (webapi_flag == "yes") {
				alert("Profile should not contain both webapi and non-webapi packages!");
			} else {
				if (confirm("Are you sure to save this profile?")) {
					ajax_call_get('action=save_profile&save_profile_name='
							+ edit_profile_name.value + '&checkbox='
							+ checkbox_value.join("*") + '&advanced='
							+ advanced + "&auto_count="
							+ filter_auto_count_string + "&manual_count="
							+ filter_manual_count_string + "&pkg_flag="
							+ package_name_flag.join("*"));
				}
			}
		} else if ((tid != "save") && (tid.indexOf("save") == 0)) {
			if (webapi_flag == "yes") {
				alert("Profile should not contain both webapi and non-webapi packages!");
			} else {
				if (confirm("Profile: " + tid.slice(4)
						+ " exists. Are you sure to overwirte it?")) {
					ajax_call_get('action=save_profile&save_profile_name='
							+ edit_profile_name.value + '&checkbox='
							+ checkbox_value.join("*") + '&advanced='
							+ advanced + "&auto_count="
							+ filter_auto_count_string + "&manual_count="
							+ filter_manual_count_string + "&pkg_flag="
							+ package_name_flag.join("*"));
				}
			}
		} else if (tid == "delete") {
			ajax_call_get('action=delete_profile&delete_profile_name='
					+ edit_profile_name.value);
		} else {
			alert("Profile " + tid.slice(6) + " does not exist.");
		}
	}
	if (responseXML.getElementsByTagName('install_package_name').length > 0) {
		tid = responseXML.getElementsByTagName('install_package_name')[0].childNodes[0].nodeValue;
		var install_package_count = responseXML
				.getElementsByTagName('install_package_count')[0].childNodes[0].nodeValue;
		var install_pkg_name_id = "pn_"
				+ responseXML.getElementsByTagName('install_package_count')[0].childNodes[0].nodeValue;
		var install_pkg_case_cn_id = "cn_"
				+ responseXML.getElementsByTagName('install_package_count')[0].childNodes[0].nodeValue;
		var install_pkg_id = "install_pkg_"
				+ responseXML.getElementsByTagName('install_package_count')[0].childNodes[0].nodeValue;
		if (tid.indexOf("SUCCESS_") == 0) {
			var case_number = responseXML
					.getElementsByTagName('case_number_temp')[0].childNodes[0].nodeValue;
			document.getElementById(install_pkg_name_id).style.color = "#116795";
			document.getElementById(install_pkg_case_cn_id).innerHTML = "&nbsp"
					+ case_number;
			document.getElementById(install_pkg_id).src = "images/operation_install_disable.png";
			document.getElementById(install_pkg_id).height = "23";
			document.getElementById(install_pkg_id).width = "23";
			document.getElementById(install_pkg_id).hspace = "0";
			document.getElementById(install_pkg_id).vspace = "0";
			document.getElementById(install_pkg_id).style.cursor = "default";
			document.getElementById(install_pkg_id).onclick = "";
			document.location = "tests_custom.pl";
			// Install package successfully!
		} else {
			alert("Install package fail\n" + tid);
			document.getElementById(install_pkg_id).src = "images/operation_install.png";
			document.getElementById(install_pkg_id).style.cursor = "pointer";
			document.getElementById(install_pkg_id).height = "23";
			document.getElementById(install_pkg_id).width = "23";
			document.getElementById(install_pkg_id).hspace = "0";
			document.getElementById(install_pkg_id).vspace = "0";
			document.getElementById(install_pkg_id).onclick = function(num) {
				return function() {
					installPackage(num);
				};
			}(install_package_count);
		}
	}

	if (responseXML.getElementsByTagName('update_package_name').length > 0) {
		tid = responseXML.getElementsByTagName('update_package_name')[0].childNodes[0].nodeValue;
		var update_package_count = responseXML
				.getElementsByTagName('update_package_count')[0].childNodes[0].nodeValue;
		var flag = responseXML.getElementsByTagName('update_package_name_flag')[0].childNodes[0].nodeValue;
		var version_latest = responseXML
				.getElementsByTagName('update_package_latest_version')[0].childNodes[0].nodeValue;
		if (tid.indexOf("SUCCESS_") == 0) {
			var version_id = "ver_" + flag;
			update_pic_id = "update_" + flag;
			document.getElementById(update_pic_id).src = "images/operation_update_disable.png";
			document.getElementById(update_pic_id).height = "23";
			document.getElementById(update_pic_id).width = "23";
			document.getElementById(update_pic_id).hspace = "0";
			document.getElementById(update_pic_id).vspace = "0";
			document.getElementById(update_pic_id).style.cursor = "default";
			document.getElementById(update_pic_id).onclick = "";
			document.getElementById(version_id).innerHTML = version_latest;
			document.location = "tests_custom.pl";
			// Update package successfully!
		} else {
			var version_id = "ver_" + flag;
			alert("Update package fail\n" + tid);
			update_pic_id = "update_" + flag;
			document.getElementById(update_pic_id).src = "images/operation_update.png";
			document.getElementById(update_pic_id).style.cursor = "pointer";
			document.getElementById(update_pic_id).height = "23";
			document.getElementById(update_pic_id).width = "23";
			document.getElementById(update_pic_id).hspace = "0";
			document.getElementById(update_pic_id).vspace = "0";
			document.getElementById(update_pic_id).onclick = function(num) {
				return function() {
					updatePackage(num);
				};
			}(update_package_count);
			document.getElementById(version_id).innerHTML = version_latest;
		}
	}
	if (responseXML.getElementsByTagName('save_manual_redirect').length > 0) {
		if (responseXML.getElementsByTagName('save_manual_refresh').length > 0) {
			document.location = 'tests_execute_manual.pl?time='
					+ responseXML.getElementsByTagName('save_manual_time')[0].childNodes[0].nodeValue;
		}
	}
	if (responseXML.getElementsByTagName('started').length > 0) {
		setTimeout('startRefresh()', 100);
	} else {
		if (responseXML.getElementsByTagName('output').length > 0) {
			var output = '';
			for ( var i = 0; i < responseXML.getElementsByTagName('output').length; ++i) {
				for ( var j = 0; j < responseXML.getElementsByTagName('output')[i].childNodes.length; ++j)
					output += responseXML.getElementsByTagName('output')[i].childNodes[j].nodeValue;
			}
			updateCmdLog(output);
			// change color for total progress bar
			var r_mul, re_mul;
			re_mul = new RegExp("testing now", "g");
			r_mul = output.match(re_mul);
			if (r_mul) {
				document.getElementById('text_' + global_profile_name + '_all').style.color = "#137717";
				document.getElementById('text_progress_' + global_profile_name
						+ '_all').style.color = "#137717";
				global_package_name = "all";
			}
			// change color for detailed progress bar
			for ( var i = 0; i < package_list.length; i++) {
				var r, re;
				re = new RegExp("execute suite: " + package_list[i], "g");
				r = output.match(re);
				if (r) {
					global_package_name = package_list[i];
					global_case_number = 0;
					var page = document.getElementsByTagName("*");
					for ( var i = 0; i < page.length; i++) {
						var temp_id = page[i].id;
						if (temp_id.indexOf("text_") >= 0) {
							page[i].style.color = "";
						}
					}
					document.getElementById('text_' + global_profile_name + '_'
							+ global_package_name).style.color = "#137717";
					document.getElementById('text_progress_'
							+ global_profile_name + '_' + global_package_name).style.color = "#137717";
				}
			}
			// update progress bar
			var r, re;
			re = new RegExp("execute case:", "g");
			r = output.match(re);
			if (r) {
				var case_number_before = global_case_number;
				if (r) {
					global_case_number = global_case_number + r.length;
				} else {
					global_case_number = global_case_number + r_webapi.length;
				}
				if (global_package_name != "none") {
					var max_value = 0;
					for ( var i = 0; i < progress_bar_max_value_list.length; i++) {
						if (progress_bar_max_value_list[i].indexOf('bar_'
								+ global_profile_name + '_'
								+ global_package_name) >= 0) {
							var reg_both = progress_bar_max_value_list[i]
									.split("::");
							max_value = parseInt(reg_both[1]);
						}
					}
					if (global_case_number >= max_value) {
						global_case_number = max_value;
					}
					if (max_value > 0) {
						document.getElementById('text_progress_'
								+ global_profile_name + '_'
								+ global_package_name).innerHTML = "&nbsp;&nbsp;"
								+ global_case_number + "/" + max_value;
						document.getElementById('bar_' + global_profile_name
								+ '_' + global_package_name).innerHTML = "";
						var pb = new YAHOO.widget.ProgressBar().render('bar_'
								+ global_profile_name + '_'
								+ global_package_name);
						pb.set('minValue', 0);
						pb.set('maxValue', max_value);
						pb.set('width', 90);
						pb.set('height', 6);
						pb.set('value', case_number_before);

						pb.set('anim', true);
						var anim = pb.get('anim');
						anim.duration = 1;
						anim.method = YAHOO.util.Easing.easeBothStrong;

						pb.set('value', global_case_number);
					}
				}
			}
		}
		if (responseXML.getElementsByTagName('tid').length > 0) {
			tid = responseXML.getElementsByTagName('tid')[0].childNodes[0].nodeValue;
		}
		if (responseXML.getElementsByTagName('size').length > 0) {
			var sz = responseXML.getElementsByTagName('size')[0].childNodes[0].nodeValue;
			timeout_var = setTimeout(
					"ajax_call_get('action=get_test_log&start=" + sz + "&tid="
							+ tid + "')", refresh_delay);
		} else {
			if (responseXML.getElementsByTagName('tr_status').length > 0) {
				exec_info.innerHTML = 'Tests are finished';
				exec_status.innerHTML = responseXML
						.getElementsByTagName('tr_status')[0].childNodes[0].nodeValue;
				stopRefresh();
			}
			if (responseXML.getElementsByTagName('redirect').length > 0) {
				if (responseXML.getElementsByTagName('redirect_manual').length > 0) {
					document.location = 'tests_execute_manual.pl?time='
							+ responseXML.getElementsByTagName('redirect')[0].childNodes[0].nodeValue;
				} else {
					stopRefresh();
					exec_info.innerHTML = 'Redirect to report page';
					document.location = 'tests_report.pl?time='
							+ responseXML.getElementsByTagName('redirect')[0].childNodes[0].nodeValue
							+ '&summary=1';
				}
			}
		}
	}
}

function stopRefresh() {
	clearTimeout(timeout_var);
	timeout_var = null;
	clearTimeout(test_timer_var);
	test_timer_var = null;
	stopTestsPrepareGUI();
	progress_table_present = false;
	cmdlog.style.color = 'green';
}

function stopTestsPrepareGUI() {
	if (start_button)
		start_button.disabled = false;
	if (stop_button)
		stop_button.disabled = true;
	if (test_profile)
		test_profile.disabled = false;
}

function onAjaxError() {
	clearTimeout(timeout_var);
	timeout_var = null;
	clearTimeout(test_timer_var);
	test_timer_var = null;
	stopTestsPrepareGUI();
	exec_info.innerHTML = 'Nothing started';
	exec_status.innerHTML = '';
}

function installPackage(count) {
	var install_pkg_count = "pn_" + count;
	var install_pkg_pic = "install_pkg_" + count;
	var pkg_name = document.getElementById(install_pkg_count);
	if (confirm('Are you sure to install ' + pkg_name.innerHTML + "?")) {
		document.getElementById(install_pkg_pic).src = "images/ajax_progress.gif";
		document.getElementById(install_pkg_pic).onclick = "";
		document.getElementById(install_pkg_pic).style.cursor = "default";
		document.getElementById(install_pkg_pic).height = "14";
		document.getElementById(install_pkg_pic).width = "14";
		document.getElementById(install_pkg_pic).hspace = "5";
		document.getElementById(install_pkg_pic).vspace = "5";
		ajax_call_get('action=install_package&package_name='
				+ pkg_name.innerHTML + '&package_count=' + count);
	}
}

function onUpdatePackages() {
	document.getElementById('progress_waiting').style.display = "";
	document.getElementById('list_advanced').style.display = "none";
	document.getElementById('select_arc').disabled = true;
	document.getElementById('select_ver').disabled = true;
	document.getElementById('sort_packages').onclick = "";
	document.getElementById('sort_packages').style.cursor = "default";
	document.getElementById('button_adv').value = "Advanced";
	document.getElementById('button_adv').disabled = true;
	document.getElementById('update_package_list').disabled = true;
	document.getElementById('execute_profile').disabled = true;
	document.getElementById('view_package_info').disabled = true;
	document.getElementById('save_profile_button').disabled = true;
	document.getElementById('load_profile_button').disabled = true;
	document.getElementById('delete_profile_button').disabled = true;
	if (document.getElementById('update_null_page_div')) {
		document.getElementById('update_null_page_div').style.display = "none";
	}
	ajax_call_get('action=update_page_with_uninstall_pkg&installed_packages='
			+ package_name.join(":"));
}

function updatePackage(count) {
	var update_pkg_count = "update_package_name_" + count;
	var pkg_name = document.getElementById(update_pkg_count);
	var package_name_id = "pn_" + pkg_name.value;
	var package_name = document.getElementById(package_name_id).innerHTML;
	var update_pkg_pic = "update_" + pkg_name.value;
	if (confirm('Are you sure to update ' + package_name + "?")) {
		document.getElementById(update_pkg_pic).src = "images/ajax_progress.gif";
		document.getElementById(update_pkg_pic).style.cursor = "default";
		document.getElementById(update_pkg_pic).onclick = "";
		document.getElementById(update_pkg_pic).height = "14";
		document.getElementById(update_pkg_pic).width = "14";
		document.getElementById(update_pkg_pic).hspace = "5";
		document.getElementById(update_pkg_pic).vspace = "5";
		ajax_call_get('action=update_package&package_name=' + package_name
				+ '&flag=' + pkg_name.value + '&package_count=' + count);
	}
}

function onExecute() {
	var sel_arc = document.getElementById("select_arc");
	var sel_ver = document.getElementById("select_ver");
	var sel_category = document.getElementById("select_category");
	var sel_pri = document.getElementById("select_pri");
	var sel_status = document.getElementById("select_status");
	var sel_exe = document.getElementById("select_exe");
	var sel_testsuite = document.getElementById("select_testsuite");
	var sel_type = document.getElementById("select_type");
	var sel_testset = document.getElementById("select_testset");
	var sel_com = document.getElementById("select_com");
	var package_name_number = document.getElementById("package_name_number");

	var checkbox_value = new Array();
	var arc = sel_arc.value;
	var ver = sel_ver.value;
	var category = sel_category.value;
	var pri = sel_pri.value;
	var status = sel_status.value;
	var exe = sel_exe.value;
	var testsuite = sel_testsuite.value;
	var type = sel_type.value;
	var testset = sel_testset.value;
	var com = sel_com.value;
	var pkg_num = package_name_number.value;
	var advanced = arc + '*' + ver + '*' + category + '*' + pri + '*' + status
			+ '*' + exe + '*' + testsuite + '*' + type + '*' + testset + '*'
			+ com;
	var webapi_flag = "0";
	for ( var count = 0; count < pkg_num; count++) {
		var checkbox_package_name_tmp = "checkbox_package_name" + count;
		var checkbox_package_name = document
				.getElementById(checkbox_package_name_tmp);
		var temp = checkbox_package_name.name;
		if (checkbox_package_name.checked) {
			if (webapi_flag == "0") {
				if (temp.indexOf('webapi') > 0) {
					webapi_flag = "1";
				} else {
					webapi_flag = "2";
				}
			} else if (webapi_flag == "1") {
				if (temp.indexOf('webapi') < 0) {
					webapi_flag = "yes";
				}
			} else if (webapi_flag == "2") {
				if (temp.indexOf('webapi') > 0) {
					webapi_flag = "yes";
				}
			}
			checkbox_value[count] = "select" + checkbox_package_name.name;
		} else {
			checkbox_value[count] = checkbox_package_name.name;
		}
	}
	if (webapi_flag == "yes") {
		alert("Can not execute both webapi and non-webapi packages at the same time!");
	} else {
		if (confirm("Are you sure to execute this profile?")) {
			ajax_call_get('action=execute_profile&checkbox='
					+ checkbox_value.join("*") + '&advanced=' + advanced
					+ "&auto_count=" + filter_auto_count_string
					+ "&manual_count=" + filter_manual_count_string
					+ "&pkg_flag=" + package_name_flag.join("*"));
		}
	}
}

function onSave() {
	var edit_profile_name = document.getElementById("edit_profile_name");
	var reg = /^[a-zA-Z]+\w*$/;
	var str = edit_profile_name.value;
	var result = reg.exec(str);
	if (!result) {
		edit_profile_name.style.borderColor = 'white';
		alert('Please check the profile name. It should be started with a letter and follows by letters, numbers or "_"');
		return false;
	} else {
		ajax_call_get('action=check_profile_isExist&profile_name='
				+ edit_profile_name.value + '&option=save');
	}
}

function onLoad() {
	var flag = 1;
	if (edit_profile_name.value == '') {
		edit_profile_name.style.borderColor = 'white';
		alert('Specify the profile name.');
		return false;
	} else {
		for ( var count = 0; count < msg.length; count++) {
			if (msg[count] == edit_profile_name.value) {
				flag = 0;
			}
		}
		if (flag) {
			alert("Profile " + edit_profile_name.value + " does not exist.");
		} else {
			document.getElementById('load_profile_button').disabled = true;
			ajax_call_get('action=check_package_isExist&load_profile_name='
					+ edit_profile_name.value);
		}
	}
}

function onDelete() {
	var edit_profile_name = document.getElementById("edit_profile_name");
	if (edit_profile_name.value == '') {
		edit_profile_name.style.borderColor = 'white';
		alert('Specify the profile name.');
		return false;
	} else {
		ajax_call_get('action=check_profile_isExist&profile_name='
				+ edit_profile_name.value + '&option=delete');
	}
}

function saveManual() {
	var arr = new Array();
	var transfer = "";
	var time = document.getElementById('time').innerHTML;
	transfer += time + "::::";
	var page = document.getElementsByTagName("*");
	for ( var i = 0; i < page.length; i++) {
		var temp_id = page[i].id;
		if (temp_id.indexOf("radio__") >= 0) {
			if (page[i].checked) {
				var result = page[i].value;
				var name_all = temp_id.split("__");
				var case_type_temp = name_all[2].split(":");
				var package_temp = name_all[3].split(":");
				var name_temp = name_all[4].split(":");
				var case_type = case_type_temp[1];
				var package_name = package_temp[1];
				var name = name_temp[1];
				var transfer_temp = "none";
				if (case_type == "manual") {
					var testarea = document.getElementById('textarea__'
							+ name_all[3] + "__" + name_all[4]);
					var bugnumber = document.getElementById('bugnumber__'
							+ name_all[3] + "__" + name_all[4]);
					transfer_temp = package_name + "__" + name + ":" + result
							+ "__" + testarea.value + "__" + bugnumber.value;
				} else {
					transfer_temp = package_name + "__" + name + ":" + result
							+ "__auto__auto";
				}
				arr.push(transfer_temp);
			}
		}
	}
	transfer += arr.join(":::");
	ajax_call_get('action=save_manual&content=' + transfer);
}

function finishManual() {
	var truthBeTold = window
			.confirm("Unsaved result will be lost. Do you want to continue?");
	if (truthBeTold) {
		var time = document.getElementById('time').innerHTML;
		document.location = 'tests_report.pl?time=' + time + '&summary=1';
	}
}

function passAll() {
	var result = document.getElementById("result").innerHTML;
	var result_list = new Array();
	result_list = result.split("::");
	for ( var i = 0; i < result_list.length; i++) {
		if (document.getElementById("summary_case_" + result_list[i]).style.display != "none") {
			var reg = new RegExp("_P:", "g");
			var radio_id = result_list[i].replace(reg, "__P:");
			reg = new RegExp("_N:", "g");
			radio_id = radio_id.replace(reg, "__N:");
			document.getElementById("pass__radio__" + radio_id).checked = true;
		}
	}
}

function failAll() {
	var result = document.getElementById("result").innerHTML;
	var result_list = new Array();
	result_list = result.split("::");
	for ( var i = 0; i < result_list.length; i++) {
		if (document.getElementById("summary_case_" + result_list[i]).style.display != "none") {
			var reg = new RegExp("_P:", "g");
			var radio_id = result_list[i].replace(reg, "__P:");
			reg = new RegExp("_N:", "g");
			radio_id = radio_id.replace(reg, "__N:");
			document.getElementById("fail__radio__" + radio_id).checked = true;
		}
	}
}

function blockAll() {
	var result = document.getElementById("result").innerHTML;
	var result_list = new Array();
	result_list = result.split("::");
	for ( var i = 0; i < result_list.length; i++) {
		if (document.getElementById("summary_case_" + result_list[i]).style.display != "none") {
			var reg = new RegExp("_P:", "g");
			var radio_id = result_list[i].replace(reg, "__P:");
			reg = new RegExp("_N:", "g");
			radio_id = radio_id.replace(reg, "__N:");
			document.getElementById("block__radio__" + radio_id).checked = true;
		}
	}
}