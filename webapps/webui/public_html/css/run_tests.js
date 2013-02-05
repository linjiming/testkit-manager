/*
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
		if (stop_button) {
			stop_button.disabled = true;
			stop_button.className = "medium_button_disable";
		}
		var page = document.getElementsByTagName("*");
		exec_info.innerHTML = 'Tests are stopping&hellip;';
		exec_status.innerHTML = 'Please wait&hellip;';
		exec_icon.innerHTML = '';
		ajax_call_get('action=stop_tests&tree=tests');
	}
}

function startTestsPrepareGUI(clean_progress_bar) {
	if (clean_progress_bar) {
		var page = document.getElementsByTagName("*");
		for ( var i = 0; i < page.length; i++) {
			var temp_id = page[i].id;
			if (temp_id.indexOf("text_progress") >= 0) {
				var reg = new RegExp("text_progress");
				var bar_id = temp_id.replace(reg, "bar");
				var text_id = temp_id.replace(reg, "text");
				var max_value = 0;
				for ( var j = 0; j < progress_bar_max_value_list.length; j++) {
					if (progress_bar_max_value_list[j].indexOf(bar_id) >= 0) {
						var reg_both = progress_bar_max_value_list[j]
								.split("::");
						max_value = parseInt(reg_both[1]);
					}
				}
				document.getElementById(temp_id).innerHTML = "(" + max_value
						+ ")";
				document.getElementById(temp_id).style.color = "";
				document.getElementById(text_id).style.color = "";
				document.getElementById(bar_id).innerHTML = "";
				global_package_name = 'none';
				global_case_number = 0;
				global_case_number_all = 0;
			}
		}
	}
	if (start_button) {
		start_button.disabled = true;
		start_button.className = "medium_button_disable";
	}
	if (stop_button) {
		stop_button.disabled = false;
		stop_button.className = "medium_button";
	}
	if (test_profile) {
		test_profile.disabled = true;
	}
	exec_info.className = '';
	exec_info.innerHTML = 'Preparing to run the tests&hellip;';
	exec_status.innerHTML = 'Please wait&hellip;';
	exec_icon.innerHTML = '<img src="images/ajax_progress_large.gif" width="40" height="40" alt="execution progress gif"/>';
	cmdlog.innerHTML = '';
	cmdlog.style.color = 'black';
	log_contents = '';
	last_line = '';
}

function startTests(profile_name) {
	var profile_name_temp = profile_name;
	if (!profile_name || profile_name == '') {
		var profile = document.getElementById('test_profile');
		if (profile) {
			if (profile.value) {
				profile_name = profile.value;
			} else {
				alert('Test plan is not specified!');
				return;
			}
		} else {
			alert("Internal error: Cannot find 'test_profile' field from the page! Please, contact the authors.!");
			return;
		}
	}
	if (profile_name_temp == '') {
		startTestsPrepareGUI(true);
	} else {
		startTestsPrepareGUI(false);
	}
	// alert("RunTest.js: " + profile_name);
	ajax_call_get('action=run_tests&profile='
			+ encodeURIComponent(profile_name));
}

function startRefresh(profile_name, have_alert) {
	if (have_alert == "true") {
		alert("A test is already running.\nYou cannot run another instance before it is finished.\nStart watching the current run...");
	}
	exec_info.innerHTML = 'Test cases are running&hellip;';
	exec_status.innerHTML = 'Please wait&hellip;';
	exec_icon.innerHTML = '<img src="images/ajax_progress_large.gif" width="40" height="40" alt="execution progress gif"/>';
	cmdlog.innerHTML = '';
	cmdlog.style.color = 'black';
	log_contents = '';
	last_line = '';
	start_button.disabled = true;
	start_button.className = "medium_button_disable";
	stop_button.disabled = false;
	stop_button.className = "medium_button";
	global_profile_name = profile_name;
	for ( var i = 0; i < test_profile.length; i++) {
		if (test_profile.options[i].value == profile_name) {
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
		network_status = responseXML
				.getElementsByTagName('network_connection_timeout')[0].childNodes[0].nodeValue;
		document.getElementById('msg_area_error').style.display = "";
		document.getElementById('msg_text_error').innerHTML = network_status;
		document.getElementById('progress_waiting').style.display = "none";
		document.getElementById('select_arc').disabled = false;
		document.getElementById('select_ver').disabled = false;
		document.getElementById('sort_packages').onclick = function() {
			return sortPackages();
		}
		document.getElementById('sort_packages').style.cursor = "pointer";
		document.getElementById('button_adv').disabled = false;
		document.getElementById('update_package_list').disabled = false;
		document.getElementById('save_profile_panel_button').disabled = false;
		document.getElementById('load_profile_panel_button').disabled = false;
		document.getElementById('manage_profile_panel_button').disabled = false;
		document.getElementById('button_adv').className = "medium_button";
		document.getElementById('update_package_list').className = "medium_button";
		document.getElementById('save_profile_panel_button').className = "medium_button";
		document.getElementById('load_profile_panel_button').className = "medium_button";
		document.getElementById('manage_profile_panel_button').className = "medium_button";
	}

	if (responseXML.getElementsByTagName('no_package_update_or_install').length > 0) {
		alert("No package needs to be installed or upgraded.");

		document.getElementById('update_package_list').disabled = false;
		document.getElementById('update_package_list').className = "medium_button";
		document.getElementById('select_arc').disabled = false;
		document.getElementById('select_ver').disabled = false;
		document.getElementById('sort_packages').onclick = function() {
			return sortPackages();
		}
		document.getElementById('sort_packages').style.cursor = "pointer";
		document.getElementById('button_adv').disabled = false;
		document.getElementById('save_profile_panel_button').disabled = false;
		document.getElementById('load_profile_panel_button').disabled = false;
		document.getElementById('manage_profile_panel_button').disabled = false;
		document.getElementById('button_adv').className = "medium_button";
		document.getElementById('save_profile_panel_button').className = "medium_button";
		document.getElementById('load_profile_panel_button').className = "medium_button";
		document.getElementById('manage_profile_panel_button').className = "medium_button";
		document.getElementById('progress_waiting').style.display = "none";
		update_state();
	}

	if (responseXML.getElementsByTagName('uninstall_package_name').length > 0) {
		var package_name_number = document
				.getElementById("package_name_number").value;
		uninstall_pkg_name = responseXML
				.getElementsByTagName('uninstall_package_name')[0].childNodes[0].nodeValue;
		uninstall_pkg_name_with_ver = responseXML
				.getElementsByTagName('uninstall_package_name_with_version')[0].childNodes[0].nodeValue;
		uninstall_pkg_version = responseXML
				.getElementsByTagName('uninstall_package_version')[0].childNodes[0].nodeValue;
		install_pkg_update_flag = responseXML
				.getElementsByTagName('update_package_flag')[0].childNodes[0].nodeValue;

		uninstall_pkg_name_arr = uninstall_pkg_name.split(" ");
		uninstall_pkg_name_arr_with_ver = uninstall_pkg_name_with_ver
				.split(" ");
		var pkg_len = uninstall_pkg_name_arr.length;
		uninstall_pkg_version_arr = uninstall_pkg_version.split(" ")
		install_pkg_update_flag_arr = install_pkg_update_flag.split(" ");

		if (package_name_number > 0) {
			update_pkg_version_latest = responseXML
					.getElementsByTagName('update_package_version_latest')[0].childNodes[0].nodeValue;
			update_pkg_version_latest_arr = update_pkg_version_latest
					.split(" ");
		}

		for ( var i = 0; i < install_pkg_update_flag_arr.length; i++) {
			if (install_pkg_update_flag_arr[i] == "a") {
				var update_pkg_id_temp = "update_package_name_" + i;
				var update_pkg = "update_"
						+ document.getElementById(update_pkg_id_temp).value;
				var update_pkg_latest_ver = "ver_in_repo_"
						+ document.getElementById(update_pkg_id_temp).value;
				var update_pkg_id = document.getElementById(update_pkg);
				document.getElementById(update_pkg_latest_ver).innerHTML = update_pkg_version_latest_arr[i];
				update_pkg_id.title = "Upgrade package";
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

		if (package_name_number > 0) {
			document.getElementById('sort_packages').onclick = function() {
				return sortPackages();
			}
			document.getElementById('sort_packages').style.cursor = "pointer";
		}

		document.getElementById('button_adv').disabled = false;
		document.getElementById('update_package_list').disabled = false;
		document.getElementById('save_profile_panel_button').disabled = false;
		document.getElementById('load_profile_panel_button').disabled = false;
		document.getElementById('manage_profile_panel_button').disabled = false;

		document.getElementById('button_adv').className = "medium_button";
		document.getElementById('update_package_list').className = "medium_button";
		document.getElementById('save_profile_panel_button').className = "medium_button";
		document.getElementById('load_profile_panel_button').className = "medium_button";
		document.getElementById('manage_profile_panel_button').className = "medium_button";

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
				document.getElementById(pkg_name_id).name = uninstall_pkg_name_arr_with_ver[i];
				document.getElementById(pkg_name_id).title = uninstall_pkg_name_arr[i];
				document.getElementById(pkg_ver_id).innerHTML = uninstall_pkg_version_arr[i];
			}
		}
		var uninstall_package_count_max = document
				.getElementById('uninstall_package_count_max').value;
		for ( var i = pkg_len; i < uninstall_package_count_max; i++) {
			var id = "uninstall_" + i;
			document.getElementById(id).style.display = "none";
		}
		document.getElementById('progress_waiting').style.display = "none";
		update_state();
		// Upgrade packages successfully!;
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
		updateTestPlanSelect();
		alert("Test plan is saved successfully.");
	}
	if (responseXML.getElementsByTagName('load_profile').length > 0) {
		var packages_isExist_flag_arr = new Array();
		var packages_need_arr = new Array();
		var packages_isExist_flag = responseXML
				.getElementsByTagName('packages_isExist_flag')[0].childNodes[0].nodeValue;
		var packages_need = responseXML.getElementsByTagName('packages_need')[0].childNodes[0].nodeValue;
		var message_not_load = "";
		var load_test_plan_select = document
				.getElementById('load_test_plan_select');
		var load_flag = 1;

		packages_isExist_flag_arr = packages_isExist_flag.split(" ");
		packages_need_arr = packages_need.split("tests");

		for ( var i = 0; i < packages_need_arr.length; i++) {
			if (packages_isExist_flag_arr[i] == 0) {
				load_flag = 0;
				message_not_load = message_not_load + packages_need_arr[i]
						+ "tests";
			} else if (packages_isExist_flag_arr[i] == 2) {
				load_flag = 2;
				if (responseXML.getElementsByTagName('return_value').length > 0) {
					var return_value = responseXML
							.getElementsByTagName('return_value')[0].childNodes[0].nodeValue;
					loaddiv_string = "<span class='report_list_no_border'>&nbsp;&nbsp;"
							+ return_value + "</span></br>";
					document.getElementById('loadProgressBarDiv').innerHTML += loaddiv_string;
				}
			}
		}
		if (load_flag == 0) {
			var loaddiv_string = "";
			var message_not_load_arr = new Array();
			var packages_need_count = 0;
			message_not_load_arr = message_not_load.split(" ");
			for ( var j = 0; j < message_not_load_arr.length; j++) {
				if (message_not_load_arr[j]) {
					packages_need_count++;
				}
			}
			if (responseXML.getElementsByTagName('load_profile_title').length > 0) {

				if (packages_need_count == 1) {
					var packages = "package that needs";
				} else {
					var packages = "packages that need";
				}
				document.getElementById('loadProgressBarDiv').innerHTML = '<tr><table width="450" border="1" cellspacing="0" cellpadding="0" frame="void" rules="all"><tr><td height="10" width="3%" align="left" class="report_list view_test_plan_edge"></td><td height="10" align="left" class="view_test_plan_edge" width="94%">&nbsp;</td><td height="10" width="3%" class="view_test_plan_edge" align="left"></td></tr><tr><td height="30" width="3%" align="left" class="view_test_plan_edge"></td><td id="loadtitle" height="30" align="left" class="view_test_plan_title" width="94%">&nbsp;Find '
						+ packages_need_count
						+ ' missing '
						+ packages
						+ ' to be installed</td><td height="30" width="3%" align="left" class="view_test_plan_edge"></td></tr></table></tr>';
				document.getElementById('loadProgressBarDiv').style.display = 'block';
				document.getElementById('popIframe').style.display = 'block';
			}

			if (responseXML.getElementsByTagName('return_value').length > 0) {
				var return_value = responseXML
						.getElementsByTagName('return_value')[0].childNodes[0].nodeValue;
				loaddiv_string = "<span class='report_list_no_border'>&nbsp;&nbsp;"
						+ return_value + "</span></br>";
			}
			var loadtitle = document.getElementById('loadtitle').innerHTML;
			var packages_need_count_total = loadtitle.split(" ");
			var install_count = packages_need_count_total[1]
					- packages_need_count + 1;
			if (message_not_load_arr[0]) {
				loaddiv_string += "<span class='report_list_no_border'>&nbsp;&nbsp;&nbsp;&nbsp;Install package "
						+ install_count
						+ ": "
						+ message_not_load_arr[0]
						+ "...</span>";
			} else {
				loaddiv_string += "<span class='report_list_no_border'>&nbsp;&nbsp;&nbsp;&nbsp;Install package "
						+ install_count
						+ ": "
						+ message_not_load_arr[1]
						+ "...</span>";
			}
			document.getElementById('loadProgressBarDiv').innerHTML += loaddiv_string;
			ajax_call_get('action=install_plan_package&packages_need='
					+ message_not_load);
		} else if (load_flag == 1) {
			document.location = "tests_custom.pl?load_profile_button="
					+ load_test_plan_select.value;
		} else {
			var text = document.getElementById('loadProgressBarDiv').innerHTML;
			if (text.indexOf("[FAIL]") > 0) {
				document.getElementById('loadProgressBarDiv').innerHTML += '</br>&nbsp;&nbsp;&nbsp;&nbsp;Fail to install one or more package(s), please try manually.</br>&nbsp;&nbsp;&nbsp;&nbsp;<a onclick="javascript:refresh_custom_page()">Click here to refresh the page.</a>';
			} else {
				document.location = "tests_custom.pl?load_profile_button="
						+ load_test_plan_select.value;
			}
		}
	}
	if (responseXML.getElementsByTagName('delete_profile_success').length > 0) {
		tid = responseXML.getElementsByTagName('delete_profile_success')[0].childNodes[0].nodeValue;
		for ( var i = 0; i < msg.length; i++) {
			if (msg[i] == tid) {
				msg.splice(i, 1);
			}
		}
		updateTestPlanSelect();
		alert("Test plan is deleted successfully.");
	}
	// view test plan
	if (responseXML.getElementsByTagName('view_profile_success').length > 0) {
		var test_plan_name = responseXML
				.getElementsByTagName('view_profile_success')[0].childNodes[0].nodeValue;
		var view_profile_package_name = responseXML
				.getElementsByTagName('view_profile_package_name')[0].childNodes[0].nodeValue;
		var view_profile_auto_case_number = responseXML
				.getElementsByTagName('view_profile_auto_case_number')[0].childNodes[0].nodeValue;
		var view_profile_manual_case_number = responseXML
				.getElementsByTagName('view_profile_manual_case_number')[0].childNodes[0].nodeValue;
		var view_profile_advanced_value = responseXML
				.getElementsByTagName('view_profile_advanced_value')[0].childNodes[0].nodeValue;
		var package_name = view_profile_package_name.split("!__! ");
		var auto_case_number = view_profile_auto_case_number.split("!__! ");
		var manual_case_number = view_profile_manual_case_number.split("!__! ");
		var planDiv_string = "";

		var advanced_key = new Array("Architecture", "Version", "Category",
				"Priority", "Status", "Execution Type", "Test Suite", "Type",
				"Test Set", "Component");

		planDiv_string += '<tr><td height="30" width="100%" align="left" class="report_list view_test_plan_edge">&nbsp;</td></tr><tr><table width="660" height="30" border="1" cellspacing="0" cellpadding="0" frame="void" rules="all"><tr><td height="30" width="7%" align="left" class="view_test_plan_edge"></td><td height="30" width="93%" align="left" class="view_test_plan_edge">Test Plan: '
				+ test_plan_name
				+ '</td></tr></table></tr><tr><table width="660" height="30" border="1" cellspacing="0" cellpadding="0" frame="void" rules="all"><tr><td height="30" width="7%" align="left" class="view_test_plan_edge"></td><td height="30" align="left" class="view_test_plan_title" width="90%">&nbsp;Package</td><td height="30" width="3%" align="left" class="view_test_plan_edge"></td></tr><tr><table width="660" height="30" border="1" cellspacing="0" cellpadding="0" frame="below" rules="all">';
		planDiv_string += '<tr><td height="30" width="7%" align="left" class="view_test_plan_edge"></td><td height="30" width="60%" align="left" class="view_test_plan_popup ">&nbsp;Name</td><td height="30" width="15%" align="left" class="view_test_plan_popup ">&nbsp;Auto</td><td height="30" width="15%" align="left" class="view_test_plan_popup ">&nbsp;Manual</td><td height="30" width="3%" align="left" class="view_test_plan_edge"></td></tr>';
		for ( var i = 0; i < package_name.length; i++) {
			if (package_name[i].indexOf('!__!') >= 0) {
				package_name[i] = package_name[i].split('!__!')[0];
				auto_case_number[i] = auto_case_number[i].split('!__!')[0];
				manual_case_number[i] = manual_case_number[i].split('!__!')[0];
			}
			if (package_name[i]) {
				planDiv_string += '<tr><td height="30" width="7%" align="left" class="view_test_plan_edge"></td><td height="30" width="60%" align="left" class="view_test_plan_popup ">&nbsp;'
						+ package_name[i]
						+ '</td><td height="30" width="15%" align="left" class="view_test_plan_popup ">&nbsp;'
						+ auto_case_number[i]
						+ '</td><td height="30" width="15%" align="left" class="view_test_plan_popup ">&nbsp;'
						+ manual_case_number[i]
						+ '</td><td height="30" width="3%" align="left" class="view_test_plan_edge"></td></tr>';
			}
		}
		planDiv_string += '</table></tr></table></tr><tr><td height="30" width="100%" align="left" class="view_test_plan_edge">&nbsp;</td></tr><tr><table width="660" height="30" border="1" cellspacing="0" cellpadding="0" frame="void" rules="none"><tr><td height="30" width="7%" align="left" class="view_test_plan_edge"></td><td height="30" align="left" class="view_test_plan_title" width="90%">&nbsp;Filter</td><td height="30" width="3%" align="left" class="view_test_plan_edge"></td></tr><tr><table width="660" height="30" border="1" cellspacing="0" cellpadding="0" frame="below" rules="all">';
		var advanced_value = view_profile_advanced_value.split("!::!");
		for ( var i = 0; i < advanced_value.length; i++) {
			if (advanced_value[i].indexOf('Any') >= 0) {
				advanced_value[i] = "- -";
			}
		}
		for ( var i = 0; i < advanced_value.length; i++) {
			if (i % 2 == 0) {
				var j = i;
				var k = j + 1;
				planDiv_string += '<tr><td height="30" width="7%" align="left" class="view_test_plan_edge"></td><td height="30" width="18%" align="left" class="view_test_plan_popup ">&nbsp;'
						+ advanced_key[j]
						+ '</td><td height="30" width="27%" align="left" class="view_test_plan_popup ">&nbsp;'
						+ advanced_value[j]
						+ '</td><td height="30" width="18%" align="left" class="view_test_plan_popup ">&nbsp;'
						+ advanced_key[k]
						+ '</td><td height="30" width="27%" align="left" class="view_test_plan_popup ">&nbsp;'
						+ advanced_value[k]
						+ '</td><td height="30" width="3%" align="left" class="view_test_plan_edge"></td></tr>';
			}
		}
		planDiv_string += '</table></tr><tr><table width="660" height="30" border="1" cellspacing="0" cellpadding="0" frame="void" rules="all"><tr><td height="30" width="95%" align="right" class="view_test_plan_edge">&nbsp;</td><td height="30" width="5%" align="right" class="view_test_plan_edge">&nbsp;</td></tr><tr><td height="30" width="95%" align="right" class="view_test_plan_edge"><input type="button" class="small_button" id="close_view_popup" name="close_view_popup" value="Close" onclick="javascript:onClosePopup();"></td><td height="30" width="5%" align="right" class="view_test_plan_edge">&nbsp;</td></tr><tr><td height="30" width="95%" align="right" class="view_test_plan_edge">&nbsp;</td><td height="30" width="5%" align="right" class="view_test_plan_edge">&nbsp;</td></tr></table></tr></table></tr>';
		document.getElementById('planDiv').innerHTML = planDiv_string;
		document.getElementById('planDiv').style.display = 'block';
		document.getElementById('popIframe').style.display = 'block';
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
			if (confirm("Are you sure to save this test plan?")) {
				var save_test_plan_text = document
						.getElementById("save_test_plan_text");
				ajax_call_get('action=save_profile&save_profile_name='
						+ save_test_plan_text.value + '&checkbox='
						+ checkbox_value.join("*") + '&advanced=' + advanced
						+ "&auto_count=" + filter_auto_count_string
						+ "&manual_count=" + filter_manual_count_string
						+ "&pkg_flag=" + package_name_flag.join("*"));
			}
		} else if ((tid != "save") && (tid.indexOf("save") == 0)) {
			if (confirm("Test plan " + tid.slice(4)
					+ " exists.\nAre you sure to overwirte it?")) {
				var save_test_plan_select = document
						.getElementById("save_test_plan_select");
				ajax_call_get('action=save_profile&save_profile_name='
						+ save_test_plan_select.value + '&checkbox='
						+ checkbox_value.join("*") + '&advanced=' + advanced
						+ "&auto_count=" + filter_auto_count_string
						+ "&manual_count=" + filter_manual_count_string
						+ "&pkg_flag=" + package_name_flag.join("*"));
			}
		} else if (tid == "delete") {
			var manage_test_plan_select = document
					.getElementById("manage_test_plan_select");
			ajax_call_get('action=delete_profile&delete_profile_name='
					+ manage_test_plan_select.value);
		} else {
			alert("Test plan " + tid.slice(6) + " does not exist.");
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
			document.getElementById(install_pkg_name_id).style.color = "#238BD1";
			document.getElementById(install_pkg_case_cn_id).innerHTML = "&nbsp"
					+ case_number;
			document.getElementById(install_pkg_id).src = "images/operation_install_disable.png";
			document.getElementById(install_pkg_id).height = "16";
			document.getElementById(install_pkg_id).width = "16";
			document.getElementById(install_pkg_id).hspace = "0";
			document.getElementById(install_pkg_id).vspace = "0";
			document.getElementById(install_pkg_id).style.cursor = "default";
			document.getElementById(install_pkg_id).onclick = "";
			document.location = "tests_custom.pl";
			// Install package successfully!
		} else {
			var package_name_number = document
					.getElementById('package_name_number').value;
			var uninstall_package_count_max = document
					.getElementById('uninstall_package_count_max').value;

			alert("Install package fail\n" + tid);
			document.getElementById(install_pkg_id).src = "images/operation_install.png";
			document.getElementById(install_pkg_id).style.cursor = "pointer";
			document.getElementById(install_pkg_id).height = "16";
			document.getElementById(install_pkg_id).width = "16";
			document.getElementById(install_pkg_id).hspace = "0";
			document.getElementById(install_pkg_id).vspace = "0";
			document.getElementById(install_pkg_id).onclick = function(num) {
				return function() {
					installPackage(num);
				};
			}(install_package_count);

			for ( var i = 0; i < uninstall_package_count_max; i++) {
				var install_pkg_id_tmp = "install_pkg_" + i;
				var temp = install_package_count - i;
				if (temp) {
					document.getElementById(install_pkg_id_tmp).onclick = function(
							num) {
						return function() {
							installPackage(num);
						};
					}(i);
					document.getElementById(install_pkg_id_tmp).style.cursor = "pointer";
				}
			}

			for ( var i = 0; i < package_name_number; i++) {
				var update_pkg_count_tmp = "update_package_name_" + i;
				var pkg_name_tmp = document
						.getElementById(update_pkg_count_tmp);
				var update_pkg_pic_tmp = "update_" + pkg_name_tmp.value;

				var del_pkg_count_tmp = "pn_package_name_" + i;
				var del_pkg_name_tmp = document
						.getElementById(del_pkg_count_tmp);
				var del_pkg_pic_tmp = "delete_" + del_pkg_name_tmp.value;

				var view_pkg_count_tmp = "view_package_name_" + i;
				var view_pkg_name_tmp = document
						.getElementById(view_pkg_count_tmp);
				var view_pkg_pic_tmp = "view_" + view_pkg_name_tmp.value;

				document.getElementById(update_pkg_pic_tmp).onclick = function(
						num) {
					return function() {
						updatePackage(num);
					};
				}(i);

				document.getElementById(del_pkg_pic_tmp).onclick = function(num) {
					return function() {
						onDeletePackage(num);
					};
				}(i);

				document.getElementById(view_pkg_pic_tmp).onclick = function(
						num) {
					return function() {
						onViewPackage(num);
					};
				}(i);

				document.getElementById(update_pkg_pic_tmp).style.cursor = "pointer";
				document.getElementById(del_pkg_pic_tmp).style.cursor = "pointer";
				document.getElementById(view_pkg_pic_tmp).style.cursor = "pointer";
			}
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
			document.getElementById(update_pic_id).height = "16";
			document.getElementById(update_pic_id).width = "16";
			document.getElementById(update_pic_id).hspace = "0";
			document.getElementById(update_pic_id).vspace = "0";
			document.getElementById(update_pic_id).style.cursor = "default";
			document.getElementById(update_pic_id).onclick = "";
			document.getElementById(version_id).innerHTML = version_latest;
			document.location = "tests_custom.pl";
			// Upgrade package successfully!
		} else {
			var version_id = "ver_" + flag;
			var package_name_number = document
					.getElementById('package_name_number').value;
			var uninstall_package_count_max = document
					.getElementById('uninstall_package_count_max').value;

			alert("Upgrade package fail\n" + tid);
			update_pic_id = "update_" + flag;
			document.getElementById(update_pic_id).src = "images/operation_update.png";
			document.getElementById(update_pic_id).style.cursor = "pointer";
			document.getElementById(update_pic_id).height = "16";
			document.getElementById(update_pic_id).width = "16";
			document.getElementById(update_pic_id).hspace = "0";
			document.getElementById(update_pic_id).vspace = "0";
			document.getElementById(version_id).innerHTML = version_latest;
			document.getElementById(update_pic_id).onclick = function(num) {
				return function() {
					updatePackage(num);
				};
			}(update_package_count);

			for ( var i = 0; i < package_name_number; i++) {
				var update_pkg_count_tmp = "update_package_name_" + i;
				var pkg_name_tmp = document
						.getElementById(update_pkg_count_tmp);
				var update_pkg_pic_tmp = "update_" + pkg_name_tmp.value;

				var del_pkg_count_tmp = "pn_package_name_" + i;
				var del_pkg_name_tmp = document
						.getElementById(del_pkg_count_tmp);
				var del_pkg_pic_tmp = "delete_" + del_pkg_name_tmp.value;

				var view_pkg_count_tmp = "view_package_name_" + i;
				var view_pkg_name_tmp = document
						.getElementById(view_pkg_count_tmp);
				var view_pkg_pic_tmp = "view_" + view_pkg_name_tmp.value;

				var temp = update_package_count - i;
				if (temp) {
					document.getElementById(update_pkg_pic_tmp).onclick = function(
							num) {
						return function() {
							updatePackage(num);
						};
					}(i);
					document.getElementById(update_pkg_pic_tmp).style.cursor = "pointer";
				}

				document.getElementById(del_pkg_pic_tmp).onclick = function(num) {
					return function() {
						onDeletePackage(num);
					};
				}(i);

				document.getElementById(view_pkg_pic_tmp).onclick = function(
						num) {
					return function() {
						onViewPackage(num);
					};
				}(i);

				document.getElementById(del_pkg_pic_tmp).style.cursor = "pointer";
				document.getElementById(view_pkg_pic_tmp).style.cursor = "pointer";
			}

			for ( var i = 0; i < uninstall_package_count_max; i++) {
				var install_pkg_id_tmp = "install_pkg_" + i;
				document.getElementById(install_pkg_id_tmp).onclick = function(
						num) {
					return function() {
						installPackage(num);
					};
				}(i);
				document.getElementById(install_pkg_id_tmp).style.cursor = "pointer";
			}
		}
	}
	if (responseXML.getElementsByTagName('save_manual_redirect').length > 0) {
		if (responseXML.getElementsByTagName('save_manual_refresh').length > 0) {
			document.location = 'tests_execute_manual.pl?time='
					+ responseXML.getElementsByTagName('save_manual_time')[0].childNodes[0].nodeValue;
		}
	}
	if (responseXML.getElementsByTagName('rerun_test_plan').length > 0) {
		var test_plan = responseXML.getElementsByTagName('rerun_test_plan')[0].childNodes[0].nodeValue;
		document.location = 'tests_execute.pl?profile=' + test_plan;
	}
	if (responseXML.getElementsByTagName('rerun_test_plan_error').length > 0) {
		var error_message = responseXML
				.getElementsByTagName('rerun_test_plan_error')[0].childNodes[0].nodeValue;
		document.getElementById('msg_area_error').style.display = "";
		document.getElementById('msg_text_error').innerHTML = error_message;
	}
	if (responseXML.getElementsByTagName('pre_config_success').length > 0) {
		document.getElementById('preConfigDiv').innerHTML = '<table width="660" border="1" cellspacing="0" cellpadding="0" class="table_normal" rules="all" frame="void"><tr><td height="200" class="report_list_no_border">&nbsp;</td></tr><tr><td align="center" class="report_list_no_border">Configuration is successful !</td></tr><tr><td align="center" class="report_list_no_border"><input type="submit" name="close_config_div" id="close_config_div" value="Close" class="small_button" onclick="javascript:onClosePopup();" /></td></tr></table>';
	}
	if (responseXML.getElementsByTagName('pre_config_error').length > 0) {
		var error_message = responseXML
				.getElementsByTagName('pre_config_error')[0].childNodes[0].nodeValue;
		var error_messages = new Array();
		error_messages = error_message.split("!::!");
		var display_message = "";
		for (i = 0; i < error_messages.length; i++) {
			if (error_messages[i] != "") {
				display_message += "&nbsp;" + error_messages[i] + "<br/>";
			}
		}
		document.getElementById('preConfigDiv').innerHTML = '<table width="660" border="1" cellspacing="0" cellpadding="0" class="table_normal" rules="all" frame="void"><tr align="left"><td width="10%" class="report_list_no_border">&nbsp;</td><td width="80%" height="65" class="report_list_no_border">&nbsp;</td><td width="10%" class="report_list_no_border">&nbsp;</td></tr><tr align="left"><td width="10%" class="report_list_no_border">&nbsp;</td><td width="80%" class="top_button_bg report_list_inside"><p>&nbsp;Configuration is failed !</p><p>&nbsp;Please finish the remanining configurations according to the document</p><p>&nbsp;</p><p>&nbsp;Error log:</p></td><td width="10%" class="report_list_no_border">&nbsp;</td></tr><tr align="left"><td width="10%" class="report_list_no_border">&nbsp;</td><td width="80%" class="report_list_inside">'
				+ display_message
				+ '</td><td width="10%" class="report_list_no_border">&nbsp;</td></tr><tr><td width="10%" align="left" class="report_list_no_border">&nbsp;</td><td width="80%" align="right" class="report_list_no_border"><input type="submit" name="close_config_div" id="close_config_div" value="Close" class="small_button" onclick="javascript:onClosePopup();" /></td><td width="10%" align="left" class="report_list_no_border">&nbsp;</td></tr></table>';
	}
	if (responseXML.getElementsByTagName('started').length > 0) {
		var profile_name = responseXML.getElementsByTagName('started')[0].childNodes[0].nodeValue;
		setTimeout('startRefresh("' + profile_name + '", "false")', 100);
	} else {
		if (responseXML.getElementsByTagName('output').length > 0) {
			var output = '';
			for ( var i = 0; i < responseXML.getElementsByTagName('output').length; ++i) {
				for ( var j = 0; j < responseXML.getElementsByTagName('output')[i].childNodes.length; ++j)
					output += responseXML.getElementsByTagName('output')[i].childNodes[j].nodeValue;
			}
			updateCmdLog(output);
			if (responseXML.getElementsByTagName('run_time').length > 0) {
				var run_time = responseXML.getElementsByTagName('run_time')[0].childNodes[0].nodeValue;
				var run_time_unit = responseXML
						.getElementsByTagName('run_time_unit')[0].childNodes[0].nodeValue;
				exec_info.innerHTML = "Test cases have been running <span class='timer_number'>"
						+ run_time + "</span> " + run_time_unit;
			}
			if (need_update_progress_bar) {
				// change color for progress bar
				for ( var i = 0; i < package_list.length; i++) {
					var r_auto, re_auto, r_manual, re_manual;
					// get auto package name
					re_auto = new RegExp("testing xml:.*" + package_list[i]
							+ "\.auto\.xml", "g");
					r_auto = output.match(re_auto);
					if (r_auto) {
						global_package_name = package_list[i] + "_auto";
						global_case_number = 0;
						var page = document.getElementsByTagName("*");
						for ( var i = 0; i < page.length; i++) {
							var temp_id = page[i].id;
							if (temp_id.indexOf("text_") >= 0) {
								page[i].style.color = "";
							}
						}
						document.getElementById('text_' + global_profile_name
								+ '_' + global_package_name).style.color = "#238BD1";
						document.getElementById('text_progress_'
								+ global_profile_name + '_'
								+ global_package_name).style.color = "#238BD1";
					}
					// get maunal package name
					re_manual = new RegExp("testing xml:.*" + package_list[i]
							+ "\.manual\.xml", "g");
					r_manual = output.match(re_manual);
					if (r_manual) {
						global_package_name = package_list[i] + "_manual";
						global_case_number = 0;
						var page = document.getElementsByTagName("*");
						for ( var i = 0; i < page.length; i++) {
							var temp_id = page[i].id;
							if (temp_id.indexOf("text_") >= 0) {
								page[i].style.color = "";
							}
						}
						document.getElementById('text_' + global_profile_name
								+ '_' + global_package_name).style.color = "#238BD1";
						document.getElementById('text_progress_'
								+ global_profile_name + '_'
								+ global_package_name).style.color = "#238BD1";
						// add progress bar for manual package, will remove
						// later
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
						if (max_value > 0) {
							document.getElementById('text_progress_'
									+ global_profile_name + '_'
									+ global_package_name).innerHTML = max_value
									+ "/" + max_value;
							document.getElementById('text_progress_'
									+ global_profile_name + '_'
									+ global_package_name).title = max_value
									+ "/" + max_value;
							document.getElementById('bar_'
									+ global_profile_name + '_'
									+ global_package_name).innerHTML = "";
							var pb = new YAHOO.widget.ProgressBar()
									.render('bar_' + global_profile_name + '_'
											+ global_package_name);
							pb.set('minValue', 0);
							pb.set('maxValue', max_value);
							pb.set('width', 80);
							pb.set('height', 6);
							pb.set('value', max_value);
						}
						// add manual case number to the total number, will
						// remove later
						var manual_case_number = 0;
						var case_number_before_all = global_case_number_all;
						var max_value_all = 0;
						for ( var i = 0; i < progress_bar_max_value_list.length; i++) {
							if (progress_bar_max_value_list[i].indexOf('bar_'
									+ global_profile_name + '_'
									+ global_package_name) >= 0) {
								var reg_both = progress_bar_max_value_list[i]
										.split("::");
								manual_case_number = parseInt(reg_both[1]);
							}
							if (progress_bar_max_value_list[i].indexOf('bar_'
									+ global_profile_name + '_all') >= 0) {
								var reg_both = progress_bar_max_value_list[i]
										.split("::");
								max_value_all = parseInt(reg_both[1]);
							}
						}
						global_case_number_all = global_case_number_all
								+ manual_case_number;
						if (global_case_number_all >= max_value_all) {
							global_case_number_all = max_value_all;
						}
						if (max_value_all > 0) {
							document.getElementById('text_progress_'
									+ global_profile_name + '_all').innerHTML = global_case_number_all
									+ "/" + max_value_all;
							document.getElementById('text_progress_'
									+ global_profile_name + '_all').title = global_case_number_all
									+ "/" + max_value_all;
							document.getElementById('bar_'
									+ global_profile_name + '_all').innerHTML = "";
							var pb = new YAHOO.widget.ProgressBar()
									.render('bar_' + global_profile_name
											+ '_all');
							pb.set('minValue', 0);
							pb.set('maxValue', max_value_all);
							pb.set('width', 80);
							pb.set('height', 6);
							pb.set('value', case_number_before_all);
							pb.set('anim', true);
							var anim = pb.get('anim');
							anim.duration = 1;
							anim.method = YAHOO.util.Easing.easeBothStrong;
							pb.set('value', global_case_number_all);
						}
					}
				}
				// update progress bar
				var r, re;
				re = new RegExp("execute case:", "g");
				r = output.match(re);
				if (r) {
					var case_number_before = global_case_number;
					var case_number_before_all = global_case_number_all;
					global_case_number_all = global_case_number_all + r.length;
					global_case_number = global_case_number + r.length;
					if (global_package_name != "none") {
						var max_value = 0;
						var max_value_all = 0;
						for ( var i = 0; i < progress_bar_max_value_list.length; i++) {
							if (progress_bar_max_value_list[i].indexOf('bar_'
									+ global_profile_name + '_all') >= 0) {
								var reg_both = progress_bar_max_value_list[i]
										.split("::");
								max_value_all = parseInt(reg_both[1]);
							}
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
						if (global_case_number_all >= max_value_all) {
							global_case_number_all = max_value_all;
						}
						if (max_value_all > 0) {
							document.getElementById('text_progress_'
									+ global_profile_name + '_all').innerHTML = global_case_number_all
									+ "/" + max_value_all;
							document.getElementById('text_progress_'
									+ global_profile_name + '_all').title = global_case_number_all
									+ "/" + max_value_all;
							document.getElementById('bar_'
									+ global_profile_name + '_all').innerHTML = "";
							var pb = new YAHOO.widget.ProgressBar()
									.render('bar_' + global_profile_name
											+ '_all');
							pb.set('minValue', 0);
							pb.set('maxValue', max_value_all);
							pb.set('width', 80);
							pb.set('height', 6);
							pb.set('value', case_number_before_all);
							pb.set('anim', true);
							var anim = pb.get('anim');
							anim.duration = 1;
							anim.method = YAHOO.util.Easing.easeBothStrong;
							pb.set('value', global_case_number_all);
						}
						if (max_value > 0) {
							document.getElementById('text_progress_'
									+ global_profile_name + '_'
									+ global_package_name).innerHTML = global_case_number
									+ "/" + max_value;
							document.getElementById('text_progress_'
									+ global_profile_name + '_'
									+ global_package_name).title = global_case_number
									+ "/" + max_value;
							document.getElementById('bar_'
									+ global_profile_name + '_'
									+ global_package_name).innerHTML = "";
							var pb = new YAHOO.widget.ProgressBar()
									.render('bar_' + global_profile_name + '_'
											+ global_package_name);
							pb.set('minValue', 0);
							pb.set('maxValue', max_value);
							pb.set('width', 80);
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
			} else {
				need_update_progress_bar = true;
				// update progress bar for all completed packages
				for ( var i = 0; i < complete_package_list.length; i++) {
					var complete_package = complete_package_list[i];
					var max_value = 0;
					for ( var j = 0; j < progress_bar_max_value_list.length; j++) {
						if (progress_bar_max_value_list[j].indexOf('bar_'
								+ global_profile_name + '_' + complete_package) >= 0) {
							var reg_both = progress_bar_max_value_list[j]
									.split("::");
							max_value = parseInt(reg_both[1]);
						}
					}
					if (max_value > 0) {
						global_case_number_all = global_case_number_all
								+ max_value;
						document.getElementById('text_progress_'
								+ global_profile_name + '_' + complete_package).innerHTML = max_value
								+ "/" + max_value;
						document.getElementById('text_progress_'
								+ global_profile_name + '_' + complete_package).title = max_value
								+ "/" + max_value;
						document.getElementById('bar_' + global_profile_name
								+ '_' + complete_package).innerHTML = "";
						var pb = new YAHOO.widget.ProgressBar().render('bar_'
								+ global_profile_name + '_' + complete_package);
						pb.set('minValue', 0);
						pb.set('maxValue', max_value);
						pb.set('width', 80);
						pb.set('height', 6);
						pb.set('value', max_value);
					}
				}
				// update progress bar for total
				var max_value_all = 0;
				for ( var i = 0; i < progress_bar_max_value_list.length; i++) {
					if (progress_bar_max_value_list[i].indexOf('bar_'
							+ global_profile_name + '_all') >= 0) {
						var reg_both = progress_bar_max_value_list[i]
								.split("::");
						max_value_all = parseInt(reg_both[1]);
					}
				}
				if (max_value_all > 0) {
					// add manual case number to the total number, will remove
					// later
					if (global_package_name.indexOf('_manual') >= 0) {
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
						if (max_value > 0) {
							global_case_number_all = global_case_number_all
									+ max_value;
						}
					}
					document.getElementById('text_progress_'
							+ global_profile_name + '_all').innerHTML = global_case_number_all
							+ "/" + max_value_all;
					document.getElementById('text_progress_'
							+ global_profile_name + '_all').title = global_case_number_all
							+ "/" + max_value_all;
					document.getElementById('bar_' + global_profile_name
							+ '_all').innerHTML = "";
					var pb = new YAHOO.widget.ProgressBar().render('bar_'
							+ global_profile_name + '_all');
					pb.set('minValue', 0);
					pb.set('maxValue', max_value_all);
					pb.set('width', 80);
					pb.set('height', 6);
					pb.set('value', global_case_number_all);
				}
				// update text and progress bar for current run package
				if (global_package_name != 'none') {
					// change color for current run package's progress bar
					document.getElementById('text_' + global_profile_name + '_'
							+ global_package_name).style.color = "#238BD1";
					document.getElementById('text_progress_'
							+ global_profile_name + '_' + global_package_name).style.color = "#238BD1";
					// update progress bar for current run package
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
						// set progress bar to the end for manual package, will
						// remove later
						if (global_package_name.indexOf('_auto') >= 0) {
							document.getElementById('text_progress_'
									+ global_profile_name + '_'
									+ global_package_name).innerHTML = global_case_number
									+ "/" + max_value;
							document.getElementById('text_progress_'
									+ global_profile_name + '_'
									+ global_package_name).title = global_case_number
									+ "/" + max_value;
						} else {
							document.getElementById('text_progress_'
									+ global_profile_name + '_'
									+ global_package_name).innerHTML = max_value
									+ "/" + max_value;
							document.getElementById('text_progress_'
									+ global_profile_name + '_'
									+ global_package_name).title = max_value
									+ "/" + max_value;
						}
						document.getElementById('bar_' + global_profile_name
								+ '_' + global_package_name).innerHTML = "";
						var pb = new YAHOO.widget.ProgressBar().render('bar_'
								+ global_profile_name + '_'
								+ global_package_name);
						pb.set('minValue', 0);
						pb.set('maxValue', max_value);
						pb.set('width', 80);
						pb.set('height', 6);
						// set progress bar to the end for manual package, will
						// remove later
						if (global_package_name.indexOf('_auto') >= 0) {
							pb.set('value', global_case_number);
						} else {
							pb.set('value', max_value);
						}
					}
				}
			}
		}
		if (responseXML.getElementsByTagName('set_device').length > 0) {
			var status = responseXML.getElementsByTagName('set_device')[0].childNodes[0].nodeValue;
			if (status == 'TRUE') {
				var value = responseXML.getElementsByTagName('sdb_serial')[0].childNodes[0].nodeValue;
				alert("Device serial number is set to " + value
						+ ",\nthe current page will be refreshed...");
				window.top.location.reload();
			} else {
				var error_message = responseXML
						.getElementsByTagName('set_device_error')[0].childNodes[0].nodeValue;
				alert("Fail to set device serial number, error message:\n"
						+ error_message);
				window.top.location.reload();
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
			if ((responseXML.getElementsByTagName('tr_status').length > 0)) {
				if ((responseXML.getElementsByTagName('missing_package').length > 0)) {
					stopRefresh();
					exec_info.className = 'result_fail';
					exec_info.innerHTML = 'Not all packages in this test plan are installed';
					exec_status.innerHTML = 'Try to load this test plan or install missing package(s) manually';
					exec_icon.innerHTML = '';
				} else {
					stopRefresh();
					exec_info.innerHTML = 'The test has been stopped';
					exec_status.innerHTML = '';
					exec_icon.innerHTML = '';
				}
			}
			if ((responseXML.getElementsByTagName('stopped').length > 0)) {
				stopRefresh();
				exec_info.innerHTML = 'The test has been stopped';
				exec_status.innerHTML = '';
				exec_icon.innerHTML = '';
			}
			if (responseXML.getElementsByTagName('redirect').length > 0) {
				if (responseXML.getElementsByTagName('lose_connection').length > 0) {
					stopRefresh();
					exec_info.className = 'result_fail';
					exec_info.innerHTML = 'Lost connection to the device';
					exec_status.innerHTML = 'Refresh this page to restart testing';
					exec_icon.innerHTML = '';
					if (start_button) {
						start_button.disabled = true;
						start_button.className = "medium_button_disable";
					}
				} else {
					if (responseXML.getElementsByTagName('redirect_manual').length > 0) {
						document.location = 'tests_execute_manual.pl?time='
								+ responseXML.getElementsByTagName('redirect')[0].childNodes[0].nodeValue;
					} else {
						stopRefresh();
						exec_info.innerHTML = 'Redirect to report page';
						exec_status.innerHTML = 'Please wait&hellip;';
						exec_icon.innerHTML = '';
						document.location = 'tests_report.pl?time='
								+ responseXML.getElementsByTagName('redirect')[0].childNodes[0].nodeValue
								+ '&summary=1';
					}
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
	if (start_button) {
		start_button.disabled = false;
		start_button.className = "medium_button";
	}
	if (stop_button) {
		stop_button.disabled = true;
		stop_button.className = "medium_button_disable";
	}
	if (test_profile) {
		test_profile.disabled = false;
	}
}

function onAjaxError() {
	clearTimeout(timeout_var);
	timeout_var = null;
	clearTimeout(test_timer_var);
	test_timer_var = null;
	stopTestsPrepareGUI();
	exec_info.className = '';
	exec_info.innerHTML = 'Nothing started';
	exec_status.innerHTML = '';
	exec_icon.innerHTML = '';
}

function installPackage(count) {
	var install_pkg_count = "pn_" + count;
	var install_pkg_pic = "install_pkg_" + count;
	var pkg_name = document.getElementById(install_pkg_count);
	var package_name_number = document.getElementById('package_name_number').value;
	var uninstall_package_count_max = document
			.getElementById('uninstall_package_count_max').value;

	if (confirm('Are you sure to install package:\n' + pkg_name.name
			+ "?\nAny existing version will be deleted.")) {
		document.getElementById(install_pkg_pic).src = "images/ajax_progress.gif";
		document.getElementById(install_pkg_pic).onclick = "";
		document.getElementById(install_pkg_pic).style.cursor = "default";
		document.getElementById(install_pkg_pic).height = "16";
		document.getElementById(install_pkg_pic).width = "16";
		document.getElementById(install_pkg_pic).hspace = "0";
		document.getElementById(install_pkg_pic).vspace = "0";
		for ( var i = 0; i < uninstall_package_count_max; i++) {
			var install_pkg_id_tmp = "install_pkg_" + i;
			var temp = count - i;
			if (temp) {
				document.getElementById(install_pkg_id_tmp).onclick = "";
				document.getElementById(install_pkg_id_tmp).style.cursor = "default";
			}
		}

		for ( var i = 0; i < package_name_number; i++) {
			var update_pkg_count_tmp = "update_package_name_" + i;
			var pkg_name_tmp = document.getElementById(update_pkg_count_tmp);
			var update_pkg_pic_tmp = "update_" + pkg_name_tmp.value;

			var del_pkg_count_tmp = "pn_package_name_" + i;
			var del_pkg_name_tmp = document.getElementById(del_pkg_count_tmp);
			var del_pkg_pic_tmp = "delete_" + del_pkg_name_tmp.value;

			var view_pkg_count_tmp = "view_package_name_" + i;
			var view_pkg_name_tmp = document.getElementById(view_pkg_count_tmp);
			var view_pkg_pic_tmp = "view_" + view_pkg_name_tmp.value;

			document.getElementById(update_pkg_pic_tmp).onclick = "";
			document.getElementById(update_pkg_pic_tmp).style.cursor = "default";
			document.getElementById(del_pkg_pic_tmp).onclick = "";
			document.getElementById(del_pkg_pic_tmp).style.cursor = "default";
			document.getElementById(view_pkg_pic_tmp).onclick = "";
			document.getElementById(view_pkg_pic_tmp).style.cursor = "default";
		}
		ajax_call_get('action=install_package&package_name=' + pkg_name.name
				+ '&package_count=' + count);
	}
}

function onUpdatePackages() {
	document.getElementById('progress_waiting').style.display = "";
	document.getElementById('list_advanced').style.display = "none";
	document.getElementById('button_adv').title = "Show filter list";
	document.getElementById('list_advanced_sec').style.display = "none";
	document.getElementById('button_adv_sec_td').style.display = "none";
	document.getElementById('pic_adv_sec').src = "images/advance-down.png";
	document.getElementById('select_arc').disabled = true;
	document.getElementById('select_ver').disabled = true;
	document.getElementById('sort_packages').onclick = "";
	document.getElementById('sort_packages').style.cursor = "default";
	document.getElementById('button_adv').value = "Filter";
	document.getElementById('button_adv').disabled = true;
	document.getElementById('update_package_list').disabled = true;
	document.getElementById('execute_profile').disabled = true;
	document.getElementById('pre_config').disabled = true;
	document.getElementById('clear_information').disabled = true;
	document.getElementById('view_package_info').disabled = true;
	document.getElementById('save_profile_panel_button').disabled = true;
	document.getElementById('load_profile_panel_button').disabled = true;
	document.getElementById('manage_profile_panel_button').disabled = true;

	document.getElementById('button_adv').className = "medium_button_disable";
	document.getElementById('update_package_list').className = "medium_button_disable";
	document.getElementById('execute_profile').className = "medium_button_disable";
	document.getElementById('pre_config').className = "medium_button_disable";
	document.getElementById('clear_information').className = "medium_button_disable";
	document.getElementById('view_package_info').className = "medium_button_disable";
	document.getElementById('save_profile_panel_button').className = "medium_button_disable";
	document.getElementById('load_profile_panel_button').className = "medium_button_disable";
	document.getElementById('manage_profile_panel_button').className = "medium_button_disable";
	close_all_test_plan_panel();
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
	var package_name_number = document.getElementById('package_name_number').value;
	var uninstall_package_count_max = document
			.getElementById('uninstall_package_count_max').value;

	if (confirm('Are you sure to upgrade package:\n' + package_name + "?")) {
		document.getElementById(update_pkg_pic).src = "images/ajax_progress.gif";
		document.getElementById(update_pkg_pic).style.cursor = "default";
		document.getElementById(update_pkg_pic).onclick = "";
		document.getElementById(update_pkg_pic).height = "16";
		document.getElementById(update_pkg_pic).width = "16";
		document.getElementById(update_pkg_pic).hspace = "0";
		document.getElementById(update_pkg_pic).vspace = "0";
		ajax_call_get('action=update_package&package_name=' + package_name
				+ '&flag=' + pkg_name.value + '&package_count=' + count);
		for ( var i = 0; i < package_name_number; i++) {
			var update_pkg_count_tmp = "update_package_name_" + i;
			var pkg_name_tmp = document.getElementById(update_pkg_count_tmp);
			var update_pkg_pic_tmp = "update_" + pkg_name_tmp.value;

			var del_pkg_count_tmp = "pn_package_name_" + i;
			var del_pkg_name_tmp = document.getElementById(del_pkg_count_tmp);
			var del_pkg_pic_tmp = "delete_" + del_pkg_name_tmp.value;

			var view_pkg_count_tmp = "view_package_name_" + i;
			var view_pkg_name_tmp = document.getElementById(view_pkg_count_tmp);
			var view_pkg_pic_tmp = "view_" + view_pkg_name_tmp.value;

			var temp = count - i;
			if (temp) {
				document.getElementById(update_pkg_pic_tmp).onclick = "";
				document.getElementById(update_pkg_pic_tmp).style.cursor = "default";
			}

			document.getElementById(del_pkg_pic_tmp).onclick = "";
			document.getElementById(del_pkg_pic_tmp).style.cursor = "default";
			document.getElementById(view_pkg_pic_tmp).onclick = "";
			document.getElementById(view_pkg_pic_tmp).style.cursor = "default";
		}

		for ( var i = 0; i < uninstall_package_count_max; i++) {
			var install_pkg_id_tmp = "install_pkg_" + i;
			document.getElementById(install_pkg_id_tmp).onclick = "";
			document.getElementById(install_pkg_id_tmp).style.cursor = "default";
		}
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
	if (confirm("Are you sure to execute this test plan?")) {
		ajax_call_get('action=execute_profile&checkbox='
				+ checkbox_value.join("*") + '&advanced=' + advanced
				+ "&auto_count=" + filter_auto_count_string + "&manual_count="
				+ filter_manual_count_string + "&pkg_flag="
				+ package_name_flag.join("*"));
	}
}

function save_profile(type) {
	var save_test_plan;
	if (type == 'text') {
		save_test_plan = document.getElementById("save_test_plan_text");
		var reg = /^[a-zA-Z]{1}\w{0,19}$/;
		var str = save_test_plan.value;
		var result = reg.exec(str);
		if (!result) {
			alert('Test plan name should start with a letter and follow by letters, numbers or "_", and maximum length is 20 characters');
			return false;
		}
		reg = /^pre_template/;
		result = reg.exec(str);
		if (result) {
			alert("'pre_template' is a reserved test plan name, please change another one");
			return false;
		}
		reg = /^rerun/;
		result = reg.exec(str);
		if (result) {
			alert("'rerun' is a reserved test plan name, please change another one");
			return false;
		}
	} else {
		save_test_plan = document.getElementById("save_test_plan_select");
	}
	ajax_call_get('action=check_profile_isExist&profile_name='
			+ save_test_plan.value + '&option=save');
}

function load_profile() {
	if (confirm("Are you sure to load this test plan?")) {
		var load_test_plan_select = document
				.getElementById('load_test_plan_select');
		document.getElementById('load_profile_button').disabled = true;
		ajax_call_get('action=check_package_isExist&load_profile_name='
				+ load_test_plan_select.value);
	}
}

function delete_profile() {
	if (confirm("Are you sure to delete this test plan?")) {
		var manage_test_plan_select = document
				.getElementById("manage_test_plan_select");
		ajax_call_get('action=check_profile_isExist&profile_name='
				+ manage_test_plan_select.value + '&option=delete');
	}
}

function show_save_panel() {
	document.getElementById("load_profile_panel").style.display = "none";
	document.getElementById("manage_profile_panel").style.display = "none";
	document.getElementById("load_profile_panel_button").title = "Open load test plan panel";
	document.getElementById("manage_profile_panel_button").title = "Open manage test plan panel";
	if (document.getElementById("save_profile_panel").style.display == "none") {
		document.getElementById("save_profile_panel").style.display = "";
		document.getElementById("save_profile_panel_button").title = "Close save test plan panel";
		document.getElementById("save_profile_panel_button").value = "Close";
		document.getElementById("load_profile_panel_button").value = "Load";
		document.getElementById("manage_profile_panel_button").value = "Delete";
	} else {
		document.getElementById("save_profile_panel").style.display = "none";
		document.getElementById("save_profile_panel_button").title = "Open save test plan panel";
		document.getElementById("save_profile_panel_button").value = "Save";
	}
}

function show_load_panel() {
	document.getElementById("save_profile_panel").style.display = "none";
	document.getElementById("manage_profile_panel").style.display = "none";
	document.getElementById("save_profile_panel_button").title = "Open save test plan panel";
	document.getElementById("manage_profile_panel_button").title = "Open manage test plan panel";
	if (document.getElementById("load_profile_panel").style.display == "none") {
		document.getElementById("load_profile_panel").style.display = "";
		document.getElementById("load_profile_panel_button").title = "Close load test plan panel";
		document.getElementById("save_profile_panel_button").value = "Save";
		document.getElementById("load_profile_panel_button").value = "Close";
		document.getElementById("manage_profile_panel_button").value = "Delete";
	} else {
		document.getElementById("load_profile_panel").style.display = "none";
		document.getElementById("load_profile_panel_button").title = "Open load test plan panel";
		document.getElementById("load_profile_panel_button").value = "Load";
	}
}

function show_manage_panel() {
	document.getElementById("save_profile_panel").style.display = "none";
	document.getElementById("load_profile_panel").style.display = "none";
	document.getElementById("save_profile_panel_button").title = "Open save test plan panel";
	document.getElementById("load_profile_panel_button").title = "Open load test plan panel";
	if (document.getElementById("manage_profile_panel").style.display == "none") {
		document.getElementById("manage_profile_panel").style.display = "";
		document.getElementById("manage_profile_panel_button").title = "Close manage test plan panel";
		document.getElementById("save_profile_panel_button").value = "Save";
		document.getElementById("load_profile_panel_button").value = "Load";
		document.getElementById("manage_profile_panel_button").value = "Close";
	} else {
		document.getElementById("manage_profile_panel").style.display = "none";
		document.getElementById("manage_profile_panel_button").title = "Open manage test plan panel";
		document.getElementById("manage_profile_panel_button").value = "Delete";
	}
}

function refresh_custom_page() {
	document.location = "tests_custom.pl";
}

function close_all_test_plan_panel() {
	document.getElementById("save_profile_panel_button").value = "Save";
	document.getElementById("load_profile_panel_button").value = "Load";
	document.getElementById("manage_profile_panel_button").value = "Delete";
	document.getElementById("save_profile_panel_button").title = "Open save test plan panel";
	document.getElementById("load_profile_panel_button").title = "Open load test plan panel";
	document.getElementById("manage_profile_panel_button").title = "Open manage test plan panel";
	document.getElementById("save_profile_panel").style.display = "none";
	document.getElementById("load_profile_panel").style.display = "none";
	document.getElementById("manage_profile_panel").style.display = "none";
}

function view_profile(type) {
	var test_plan_select;
	if (type == 'save') {
		test_plan_select = document.getElementById("save_test_plan_select");
	}
	if (type == 'load') {
		test_plan_select = document.getElementById("load_test_plan_select");
	}
	if (type == 'manage') {
		test_plan_select = document.getElementById("manage_test_plan_select");
	}
	var test_plan_name = test_plan_select.value;
	document.getElementById('planDiv').innerHTML = "";
	ajax_call_get('action=view_test_plan&test_plan_name=' + test_plan_name);
}

function onClosePopup() {
	var pop_div = document.getElementById('planDiv');
	var about_div = document.getElementById('aboutDiv');
	var pre_config_div = document.getElementById('preConfigDiv');
	var pop_iframe = document.getElementById('popIframe');
	if (pop_div) {
		pop_div.style.display = 'none';
	}
	if (about_div) {
		about_div.style.display = 'none';
	}
	if (pre_config_div) {
		pre_config_div.style.display = 'none';
	}
	if (pop_iframe) {
		pop_iframe.style.display = 'none';
	}
}

function updateTestPlanSelect() {
	var save_test_plan_select = document
			.getElementById("save_test_plan_select");
	var load_test_plan_select = document
			.getElementById("load_test_plan_select");
	var manage_test_plan_select = document
			.getElementById("manage_test_plan_select");
	var save_test_plan_text = document.getElementById("save_test_plan_text");

	save_test_plan_select.options.length = 0;
	load_test_plan_select.options.length = 0;
	manage_test_plan_select.options.length = 0;
	save_test_plan_text.value = "";

	if (msg.length < 1) {
		save_test_plan_select.add(new Option("<no plans present>",
				"<no plans present>"));
		save_test_plan_select.disabled = true;
		load_test_plan_select.add(new Option("<no plans present>",
				"<no plans present>"));
		load_test_plan_select.disabled = true;
		manage_test_plan_select.add(new Option("<no plans present>",
				"<no plans present>"));
		manage_test_plan_select.disabled = true;
		document.getElementById("save_profile_button_select").disabled = true;
		document.getElementById("view_profile_button_save").disabled = true;
		document.getElementById("view_profile_button_load").disabled = true;
		document.getElementById("view_profile_button_manage").disabled = true;
		document.getElementById("save_profile_button_select").className = "medium_button_disable";
		document.getElementById("view_profile_button_save").className = "medium_button_disable";
		document.getElementById("view_profile_button_load").className = "medium_button_disable";
		document.getElementById("view_profile_button_manage").className = "medium_button_disable";
		document.getElementById("load_profile_button").disabled = true;
		document.getElementById("load_profile_button").className = "medium_button_disable";
		document.getElementById("delete_profile_button").disabled = true;
		document.getElementById("delete_profile_button").className = "medium_button_disable";
	} else {
		for ( var i = 0; i < msg.length; i++) {
			save_test_plan_select.add(new Option(msg[i], msg[i]));
			save_test_plan_select.disabled = false;
			load_test_plan_select.add(new Option(msg[i], msg[i]));
			load_test_plan_select.disabled = false;
			manage_test_plan_select.add(new Option(msg[i], msg[i]));
			manage_test_plan_select.disabled = false;
			document.getElementById("save_profile_button_select").disabled = false;
			document.getElementById("view_profile_button_save").disabled = false;
			document.getElementById("view_profile_button_load").disabled = false;
			document.getElementById("view_profile_button_manage").disabled = false;
			document.getElementById("save_profile_button_select").className = "medium_button";
			document.getElementById("view_profile_button_save").className = "medium_button";
			document.getElementById("view_profile_button_load").className = "medium_button";
			document.getElementById("view_profile_button_manage").className = "medium_button";
			document.getElementById("load_profile_button").disabled = false;
			document.getElementById("load_profile_button").className = "medium_button";
			document.getElementById("delete_profile_button").disabled = false;
			document.getElementById("delete_profile_button").className = "medium_button";
		}
	}
}

function saveManual() {
	var truthBeTold = window
			.confirm("Are you sure to save the modified test results?");
	if (truthBeTold) {
		var arr = new Array();
		var transfer = "";
		var time = document.getElementById('time').innerHTML;
		transfer += time + "!:::!";
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
						transfer_temp = package_name + "!__!" + name + "!:!"
								+ result + "!__!" + testarea.value + "!__!"
								+ bugnumber.value;
					} else {
						transfer_temp = package_name + "!__!" + name + "!:!"
								+ result + "!__!auto!__!auto";
					}
					arr.push(transfer_temp);
				}
			}
		}
		transfer += arr.join("!::!");
		ajax_call_get('action=save_manual&content=' + transfer);
		document.getElementById("button_save").className = "small_button_disable";
		document.getElementById("button_finish").className = "small_button_disable";
		document.getElementById("manual_exec_icon").innerHTML = '<img src="images/ajax_progress.gif" width="16" height="16" alt="execution progress gif"/>';
	}
}

function finishManual() {
	var truthBeTold = window
			.confirm("Unsaved results will be lost. Do you want to continue?");
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

function notrunAll() {
	var result = document.getElementById("result").innerHTML;
	var result_list = new Array();
	result_list = result.split("::");
	for ( var i = 0; i < result_list.length; i++) {
		if (document.getElementById("summary_case_" + result_list[i]).style.display != "none") {
			var reg = new RegExp("_P:", "g");
			var radio_id = result_list[i].replace(reg, "__P:");
			reg = new RegExp("_N:", "g");
			radio_id = radio_id.replace(reg, "__N:");
			document.getElementById("not_run__radio__" + radio_id).checked = true;
		}
	}
}

function clearRadioAll() {
	var page = document.getElementsByTagName("*");
	for ( var i = 0; i < page.length; i++) {
		var temp_id = page[i].id;
		if (temp_id.indexOf("_all_button") >= 0) {
			page[i].checked = false;
		}
	}
}

function setDevice() {
	var sdb_serial = document.getElementById('device_list').value;
	ajax_call_get('action=set_device&serial=' + sdb_serial);
}

function showAbout() {
	about_div_string = '<table width="100%" border="0" cellspacing="0" cellpadding="0" class="about_div_table"><tr><td align="left">Testkit-manager is a GUI for testkit-lite. With this tool, we can filter cases with several properties\' value. The filtered cases can be run automatically and the report will be generated after finishing running. We can also submit report and view report with this tool.</td></tr><tr><td align="right"><label><input class="small_button" type="button" name="close_about_popup" id="close_about_popup" value="Close" onclick="javascript:onClosePopup();" /></label>&nbsp;&nbsp;</td></tr></table>';
	document.getElementById('aboutDiv').innerHTML = about_div_string;
	document.getElementById('aboutDiv').style.display = 'block';
	document.getElementById('popIframe').style.display = 'block';
}

function rerunNotPassedCases(time, plan_name) {
	if (plan_name == "none") {
		alert("Invalid test plan name 'none', rerun is not available");
	} else {
		ajax_call_get('action=rerun_test_plan&time=' + time);
	}
}

function onSaveConfig() {
	var have_all_info = true;
	var server1_name = document.getElementById('pre_config_apache_name_text').value;
	if (server1_name == "") {
		have_all_info = false;
		document.getElementById('pre_config_apache_name_text').style.borderColor = "red";
	} else {
		document.getElementById('pre_config_apache_name_text').style.borderColor = "green";
	}
	var server1_port = document.getElementById('pre_config_apache_port_text').value;
	if (server1_port == "") {
		have_all_info = false;
		document.getElementById('pre_config_apache_port_text').style.borderColor = "red";
	} else {
		document.getElementById('pre_config_apache_port_text').style.borderColor = "green";
	}
	var server2_name = document.getElementById('pre_config_tomcat_name_text').value;
	if (server2_name == "") {
		have_all_info = false;
		document.getElementById('pre_config_tomcat_name_text').style.borderColor = "red";
	} else {
		document.getElementById('pre_config_tomcat_name_text').style.borderColor = "green";
	}
	var server2_port = document.getElementById('pre_config_tomcat_port_text').value;
	if (server2_port == "") {
		have_all_info = false;
		document.getElementById('pre_config_tomcat_port_text').style.borderColor = "red";
	} else {
		document.getElementById('pre_config_tomcat_port_text').style.borderColor = "green";
	}
	var server3_name = document.getElementById('pre_config_socket_name_text').value;
	if (server3_name == "") {
		have_all_info = false;
		document.getElementById('pre_config_socket_name_text').style.borderColor = "red";
	} else {
		document.getElementById('pre_config_socket_name_text').style.borderColor = "green";
	}
	var server3_port = document.getElementById('pre_config_socket_port_text').value;
	if (server3_port == "") {
		have_all_info = false;
		document.getElementById('pre_config_socket_port_text').style.borderColor = "red";
	} else {
		document.getElementById('pre_config_socket_port_text').style.borderColor = "green";
	}
	var bluetooth_name = document
			.getElementById('pre_config_bluetooth_name_text').value;
	if (bluetooth_name == "") {
		have_all_info = false;
		document.getElementById('pre_config_bluetooth_name_text').style.borderColor = "red";
	} else {
		document.getElementById('pre_config_bluetooth_name_text').style.borderColor = "green";
	}
	var bluetooth_address = document
			.getElementById('pre_config_bluetooth_address_text').value;
	if (bluetooth_address == "") {
		have_all_info = false;
		document.getElementById('pre_config_bluetooth_address_text').style.borderColor = "red";
	} else {
		document.getElementById('pre_config_bluetooth_address_text').style.borderColor = "green";
	}
	if (have_all_info) {
		document.getElementById('preConfigDiv').innerHTML = '<table width="660" border="1" cellspacing="0" cellpadding="0" class="table_normal" rules="all" frame="void"><tr><td height="200" class="report_list_no_border">&nbsp;</td></tr><tr><td align="center" class="report_list_no_border"><img src="images/ajax_progress_large.gif" width="40" height="40" alt="execution progress gif"/></td></tr><tr><td align="center" class="report_list_no_border">Configuring, please wait&hellip;</td></tr></table>';
		ajax_call_get('action=pre_config_device&parameter=' + server1_name
				+ '!::!' + server1_port + '!::!' + server2_name + '!::!'
				+ server2_port + '!::!' + server3_name + '!::!' + server3_port
				+ '!::!' + bluetooth_name + '!::!' + bluetooth_address);
	}
}