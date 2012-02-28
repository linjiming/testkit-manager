////////////////////////////////////////////////////////////////////////////////
// Images preloading

// Array to store preloaded images.
var preload_images_arr = new Array();

// Preload images so that there was no flickering when showing previously invisible
// (and not loaded by the browser) picture.
function preload_images(image_names) {
	for (var i=0; i<image_names.length; ++i) {
		preload_images_arr[i] = new Image;
		preload_images_arr[i].src = 'images/' + image_names[i];
	}
}


////////////////////////////////////////////////////////////////////////////////
// Supplemental functions

// Toggles visibility of the additional parameters block
function showHideDetails() {
	var elem_div = document.getElementById('additional_data');
	var elem_img = document.getElementById('block_arrow_img');
	if (elem_div && elem_img) {
		var to_show = (elem_div.style.display == 'none');
		elem_div.style.display = to_show ? '' : 'none';
		elem_img.setAttribute('src', to_show ? 'images/arr_d.png' : 'images/arr_r.png');
	}
}

// Bake Cookies
function setCookie(c_name, value, expiredays) {
	var exdate = new Date();
	exdate.setDate(exdate.getDate() + expiredays);
	document.cookie = c_name + '=' + encodeURIComponent(value) + ((expiredays == null) ? '' : ';expires=' + exdate.toGMTString());
}

function getCookie(c_name) {
	if (document.cookie.length > 0) {
		var c_start = document.cookie.indexOf(c_name + '=');
		if (c_start != -1) {
			c_start = c_start + c_name.length + 1;
			c_end = document.cookie.indexOf(';', c_start);
			if (c_end == -1)
				c_end = document.cookie.length;
			return unescape(document.cookie.substring(c_start, c_end));
		}
	}
	return null;
}

// Determines absolute dynamic position of an element (1 pixel below its left bottom corner).
// Used for displaying the dialog box just below the element.
function getPosition(elem) {
	if (!elem)
		return {x: -1, y: -1};
	var x = 0;
	var y = 0;
	while (elem) {
		x += elem.offsetLeft;
		y += elem.offsetTop;
		elem = elem.offsetParent;
	}
	return {x: x, y: y};
}


////////////////////////////////////////////////////////////////////////////////
// Color fade-out

// Global array to store all fading objects (we need it
// for using in setTimeout that takes global expressions only)
var fadeingObjs = new Array();

// Object constructor to start fading the object with DOM id specified.
// Fading is performed from rgb(rb, gb, bb) to rgb(re, ge, be), full cycle takes ~3 sec.
// If hide is true, then after fading the element becomes hidden.
function fadeOut(id, rb, gb, bb, re, ge, be, hide) {
	// Starting color
	this.rb = rb;
	this.gb = gb;
	this.bb = bb;
	// Ending color
	this.re = re;
	this.ge = ge;
	this.be = be;
	// Current color
	this.rc = rb;
	this.gc = gb;
	this.bc = bb;

	this.id = id;
	this.hide = hide;

	this.numstep = 0;
	this.maxstep = 127;

	// Find a free cell to store the object
	// (there will hardly be more than 1024 ones simultaneously)
	for (var i = 0; i < 1024; ++i) {
		if (!fadeingObjs[i])
			break;
	}
	if (i == 1024)
		return;
	// Remember the index we found
	this.idx = i;
	fadeingObjs[i] = this;
	// Start fading
	setTimeout('fadeingObjs[' + this.idx + '].step()', 0);

	// The function to perform a step of fading
	this.step = function() {
		var elem = document.getElementById(this.id);
		if (elem) {
			var rc = Math.round(this.rb + (this.re - this.rb) * this.numstep / this.maxstep);
			var gc = Math.round(this.gb + (this.ge - this.gb) * this.numstep / this.maxstep);
			var bc = Math.round(this.bb + (this.be - this.bb) * this.numstep / this.maxstep);
			elem.style.color = 'rgb(' + rc + ', ' + gc + ', ' + bc + ')';
			elem.style.display = '';
		}
		++this.numstep;
		// If reached black, stop fading and free the array cell; else continue with next step
		if (this.numstep > this.maxstep) {
			if (this.hide)
				elem.style.display = 'none';
			fadeingObjs[this.idx] = null;
		}
		else
			setTimeout('fadeingObjs[' + this.idx + '].step()', 15);
	};
}


////////////////////////////////////////////////////////////////////////////////
// Drag elements with mouse

var current_draggable_elem = null;
var mouse_delta_pos = {x: 0, y: 0};
var drag_save_element_pos = false;

function dragStart(event, elem, save_pos) {
	current_draggable_elem = elem;
	mouse_delta_pos.x = event.clientX - parseInt(current_draggable_elem.style.left);
	mouse_delta_pos.y = event.clientY - parseInt(current_draggable_elem.style.top);
	drag_save_element_pos = save_pos;
}

function dragStop(event) {
	current_draggable_elem = null;
	drag_save_element_pos = false;
}

function clearSelection() {
	var sel;
	if (document.selection && document.selection.empty) {
		document.selection.empty();
	}
	else if (window.getSelection) {
		sel = window.getSelection();
		if (sel && sel.removeAllRanges)
			sel.removeAllRanges();
	}
}

function dragMove(event) {
	if (current_draggable_elem) {
		current_draggable_elem.style.left = (event.clientX - mouse_delta_pos.x) + 'px';
		current_draggable_elem.style.top = (event.clientY - mouse_delta_pos.y) + 'px';
		if (drag_save_element_pos)
			setCookie('pos_' + current_draggable_elem.id, current_draggable_elem.style.left + ',' + current_draggable_elem.style.top, 365);
		clearSelection();
	}
}


////////////////////////////////////////////////////////////////////////////////
// AJAX

// -----------------------------------------------------------------------------
// Global settings (overridable from different HTMLs).

// The progress dialog is not shown at once so that user was not annoyed by
// flickering (local requests are usually fast enough). But if it takes longer
// time for some reason, the dialog is displayed. Here the time in milliseconds
// is specified, after which the dialog will be shown, if AJAX request is still
// in progress.
// If the value is -1, the dialog will not be shown at all.
var timeout_show_progress = 250;

// -----------------------------------------------------------------------------
// AJAX internals.

// Global variable containing list of current AJAX requests.
var ajax_reqs = new Array();
var ajax_reqs_num = 0;

// Indicator, whether at least one request is in progress now.
var ajax_req_busy = false;

// Full URL to the AJAX server script. Must be on the same domain name, else
// AJAX does not work (security issue), even if two domain names point to the
// same real location.
var ajax_srv_url = document.location.protocol + '//' + document.location.host + '/ajax_srv.pl';

// Progress dialog.
var progressDiv = null;

// Error message area. Can be absent - in this case AJAX errors will be shown in
// a message box.
var err_area = null;
var err_text = null;
var ajax_error = '';

// AJAX initialization. Must be started after the HTML document is loaded.
function ajaxInit() {
	progressDiv = document.getElementById('ajax_loading');
	if (!progressDiv)
		ajax_error += 'Cannot find essential HTML entries!\n';
	else {
		if (navigator.appName == 'Microsoft Internet Explorer')
			progressDiv.style.height = '7.5em';
	}
	err_area = document.getElementById('error_msg_area');
	err_text = document.getElementById('error_msg_text');
	if (typeof(ajaxProcessResult) == 'undefined')
		ajax_error += 'No ajaxProcessResult was found!\n';
}

// Displaying AJAX error message, depending on whether HTML provides special
// location for them or not.
function ajaxError(error_text) {
	if (err_text && err_area) {
		err_text.innerHTML = error_text;
		err_area.style.display = '';
		// Try to scroll the error message into view, if not visible
		var scrollTop = document.body.scrollTop;
		if (scrollTop == 0)
		{
			if (window.pageYOffset)
				scrollTop = window.pageYOffset;
			else
				scrollTop = (document.body.parentElement) ? document.body.parentElement.scrollTop : 0;
		}
		var windowHeight = document.documentElement.clientHeight;
		var elemBottomScrolled = getPosition(err_area).y - scrollTop;
		var elemTopScrolled = elemBottomScrolled - err_area.offsetHeight;
		var toScrollDiff = 0;
		// First, move the bottom border into view
		if (elemBottomScrolled > windowHeight)
			toScrollDiff = elemBottomScrolled - windowHeight;
		// Then move the top border, overriding the just calculated scrolling
		// (if the message is longer than one screen, show it top-aligned)
		elemTopScrolled -= toScrollDiff;
		if (elemTopScrolled < 0)
			toScrollDiff += elemTopScrolled;
		window.scrollBy(0, toScrollDiff);
	}
	else
		alert(error_text.replace(/<br\s*\/>/g, '\n'));
}

// Starts counting time before the progress dialog appears.
function setBusyOn() {
	ajax_req_busy = true;
	if (timeout_show_progress != -1)
		setTimeout('showAjaxProgress()', timeout_show_progress);
}

// Displays the progress dialog.
function showAjaxProgress() {
	if (ajax_req_busy)
		progressDiv.style.display = '';
}

// Hides the progress dialog and marks AJAX request as not running.
function setBusyOff() {
	ajax_req_busy = false;
	if (progressDiv)
		progressDiv.style.display = 'none';
}

// Forces aborting all the current AJAX calls.
function onAbort() {
	setBusyOff();
	do {
		var req = ajax_reqs.pop();
		if (!req)
			continue;
		req['aborted'] = 1;
		--ajax_reqs_num;
		req.abort();
		// Break the cyclic reference to avoid memory leak in IE
		req.onreadystatechange = null;
	} while (ajax_reqs.length > 0);
	// Sanity check
	if (ajax_reqs_num != 0)
		alert('Internal errors:\nAJAX requests counter mismatching. Please write to linux@ispras.ru.');
}

// Initiates the AJAX request (GET type).
function ajax_call_get(get_params) {
	if (ajax_error) {
		alert('Internal errors:\n' + ajax_error + '\nAJAX will not work correctly. Please write to linux@ispras.ru.');
		return;
	}
	setBusyOn();
	loadXMLDoc(ajax_srv_url + '?' + get_params, 'GET', null);
}

// Initiates the AJAX request (POST type).
// form_id is the form where to take parameters from.
function ajax_call_post(get_params, form_id) {
	if (ajax_error) {
		alert('Internal errors:\n' + ajax_error + '\nAJAX will not work correctly. Please write to linux@ispras.ru.');
		return;
	}
	setBusyOn();
	loadXMLDoc(ajax_srv_url + '?' + get_params, 'POST', getFormValues(document.getElementById(form_id)));
}

// Simulates the POST request by collecting all the fields from the form and
// combining them into POST data.
function getFormValues(fobj)
{
	var str = '';
	for(var i=0; i<fobj.elements.length; ++i)
	{
		if ((fobj.elements[i].type == 'hidden') || (fobj.elements[i].type == 'text') ||
			(fobj.elements[i].type == 'password') ||
			(fobj.elements[i].type == 'textarea') || (fobj.elements[i].type == 'select-one'))
		{
			if (fobj.elements[i].value)
				str += fobj.elements[i].name + '=' + encodeURIComponent(fobj.elements[i].value) + '&';
		}
		else if (fobj.elements[i].type == 'checkbox') {
			if (fobj.elements[i].checked)
				str += fobj.elements[i].name + '=on&';
		}
		else if (fobj.elements[i].type == 'radio') {
			if (fobj.elements[i].checked)
				str += fobj.elements[i].name + '=' + encodeURIComponent(fobj.elements[i].value) + '&';
		}
	}
	str = str.substr(0, (str.length - 1));
	return str;
}

// Creates a cross-browser AJAX request object and performs the data transfer.
function loadXMLDoc(url, method, post_params) {
	var ajax_req;
	if (window.XMLHttpRequest) {        // native XMLHttpRequest object
		ajax_req = new XMLHttpRequest();
	}
	else if (window.ActiveXObject) {    // IE/Windows ActiveX version
		try {
			ajax_req = new ActiveXObject('Msxml2.XMLHTTP');
		}
		catch (e) {
			try {
				ajax_req = new ActiveXObject('Microsoft.XMLHTTP');
			}
			catch (e) {
				alert('Sorry, your browser does not support AJAX.');
				return false;
			}
		}
	}
	if (!ajax_req) {
		alert('Sorry, your browser does not support AJAX.');
		return false;
	}

	// Search for the first empty cell in the requests array
	var idx;
	for (idx=0; idx<5000; ++idx) {
		if (!ajax_reqs[idx])
			break;
	}
	if (ajax_reqs[idx]) {
		alert('Internal error: AJAX requests array overflow!\nPlease write to linux@ispras.ru.');
		return;
	}
	ajax_req['index'] = idx;
	ajax_reqs[idx] = ajax_req;
	++ajax_reqs_num;

	ajax_req.onreadystatechange = function() { processReqChange(ajax_req); };
	ajax_req.open(method, url, true);
	ajax_req.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
	// Workaround for IE always caching AJAX results:
	ajax_req.setRequestHeader('If-Modified-Since', 'Tue, 01 Jan 1980 00:00:00 GMT');
	ajax_req.setRequestHeader('Content-length', (post_params ? post_params.length : 0));
	ajax_req.setRequestHeader('Connection', 'close');
	ajax_req.send(post_params);
}

// Main function for processing results.
function processReqChange(ajax_req) {
	if ((ajax_req.readyState == 4) && (!ajax_req['aborted'])) {     // Process only 'Finished' state.
		// Remove from the global requests array
		ajax_reqs[ajax_req['index']] = null;
		--ajax_reqs_num;
		if (ajax_reqs_num == 0)
			setBusyOff();
		// Break the cyclic reference to avoid memory leak in IE
		ajax_req.onreadystatechange = null;
		// Process the response
		if (ajax_req.status == 200) {
			if (ajax_req.responseXML.getElementsByTagName('error').length > 0) {
				var error_text = ajax_req.responseXML.getElementsByTagName('error')[0].childNodes[0].nodeValue;
				ajaxError(error_text);
				if (typeof(onAjaxError) == 'function')
					onAjaxError();
			}
			else {
				if (err_area)
					err_area.style.display = 'none';
				ajaxProcessResult(ajax_req.responseXML);
			}
		}
		else {
			alert('AJAX call failed:\n' + ajax_req.statusText);
		}
	}
}
