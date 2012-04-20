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
	if (confirm('Are you sure you want to terminate test execution?')) {
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
	startTestsPrepareGUI();
	// alert("RunTest.js: " + profile_name);
	ajax_call_get('action=run_tests&profile='
			+ encodeURIComponent(profile_name));
}

function startRefresh() {
	exec_info.innerHTML = 'Tests are running &hellip;';
	exec_status.innerHTML = '&nbsp;&nbsp;&nbsp;<img src="images/ajax_progress.gif" width="16" height="16" alt="" />';
	cmdlog.innerHTML = '';
	cmdlog.style.color = 'black';
	log_contents = '';
	last_line = '';
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

	if (responseXML.getElementsByTagName('save_manual_redirect').length > 0) {
		if (responseXML.getElementsByTagName('save_manual_refresh').length > 0) {
			document.location = 'tests_execute_manual.pl?time='
					+ responseXML.getElementsByTagName('save_manual_time')[0].childNodes[0].nodeValue;
		}
		if (responseXML.getElementsByTagName('save_manual_redirect_report').length > 0) {
			document.location = 'tests_report.pl?time='
					+ responseXML.getElementsByTagName('save_manual_time')[0].childNodes[0].nodeValue
					+ '&detailed=1';
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
							+ '&detailed=1';
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

function saveManual() {
	var arr = new Array();
	var transfer = "";
	var time = document.getElementById('time').innerHTML;
	transfer += time + "::::";
	var page = document.all;
	for ( var i = 0; i < page.length; i++) {
		var temp_id = page[i].id;
		if (temp_id.indexOf("radio__") >= 0) {
			if (page[i].checked) {
				var result = page[i].value;
				var name_all = temp_id.split("__");
				var package_temp = name_all[2].split(":");
				var name_temp = name_all[3].split(":");
				var package_name = package_temp[1];
				var name = name_temp[1];
				var testarea = document.getElementById('textarea__'
						+ name_all[2] + "__" + name_all[3]);
				var bugnumber = document.getElementById('bugnumber__'
						+ name_all[2] + "__" + name_all[3]);
				var transfer_temp = package_name + "__" + name + ":" + result
						+ "__" + testarea.value + "__" + bugnumber.value;
				arr.push(transfer_temp);
			}
		}
	}
	transfer += arr.join(":::");
	ajax_call_get('action=save_manual&content=' + transfer);
}

function finishManual() {
	var truthBeTold = window.confirm("Unsaved result will be lost. Continue?");
	if (truthBeTold) {
		var time = document.getElementById('time').innerHTML;
		document.location = 'tests_report.pl?time=' + time + '&detailed=1';
	}
}

function passAll() {
	var result = document.getElementById("result").innerHTML;
	var result_list = new Array();
	result_list = result.split("::");
	for ( var i = 0; i < result_list.length; i++) {
		document.getElementById("pass__radio__" + result_list[i]).checked = true;
	}
}

function failAll() {
	var result = document.getElementById("result").innerHTML;
	var result_list = new Array();
	result_list = result.split("::");
	for ( var i = 0; i < result_list.length; i++) {
		document.getElementById("fail__radio__" + result_list[i]).checked = true;
	}
}

function blockAll() {
	var result = document.getElementById("result").innerHTML;
	var result_list = new Array();
	result_list = result.split("::");
	for ( var i = 0; i < result_list.length; i++) {
		document.getElementById("block__radio__" + result_list[i]).checked = true;
	}
}