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
 */

var getNodePath = function(node) {
	// construct node path
	var path = "";
	if (node.depth > 1) {
		for ( var i = 0; i < (node.depth); i++) {
			path = path + node.getAncestor(i).label + "///";
		}
		path = path + node.label;
	} else {
		if (node.depth == 1) {
			path = path + node.parent.label + "///";
		}
		path = path + node.label;
	}
	return path;
};

var drawAttributesTable = function(nodePath, queryUrl) {

	var myColumnDefs1 = [ {
		key : "key",
		label : "Attributes",
		width : 250
	}, {
		key : "value",
		label : "Values",
		width : 250
	} ];
	myDataSource = new YAHOO.util.DataSource(queryUrl);
	myDataSource.responseType = YAHOO.util.DataSource.TYPE_JSON;

	myDataSource.responseSchema = {
		resultsList : "attr",
		fields : [ "key", "value" ]
	};
	myDataSource.maxCacheEntries = 0;
	YAHOO.widget.DataTable.MSG_EMPTY = 'This case contains no messages';
	var attrTable = new YAHOO.widget.DataTable('attributes_div', myColumnDefs1,
			myDataSource, {
				width : "60em",
				initialRequest : 'case=' + nodePath
			});
	attrTable.render();
};

var buildCommonTree = function(body_innerhtml) {
	var l = layout.getUnitByPosition('left');
	l.set('body', body_innerhtml);

	// create a new tree:
	tree = new YAHOO.widget.TreeView("treediv");
	// get root node for tree:
	var root = tree.getRoot();

	tree.setNodesProperty('propagateHighlightUp', true);
	tree.setNodesProperty('propagateHighlightDown', true);
	tree
			.subscribe(
					'clickEvent',
					function(oArgs) {
						var nodePath = encodeURIComponent(getNodePath(oArgs.node));
						
						if (oArgs.node.title == "folder") {
							oArgs.node.toggle();
							oArgs.node.toggleHighlight();
							var centerbody_innerHtml = 'Select Test Case from left panel to view';
							var c = layout.getUnitByPosition('center');
							c.set('body', centerbody_innerHtml);
						} else if (oArgs.node.title == "package") {
							oArgs.node.toggle();
							oArgs.node.toggleHighlight();
							setPackageTable(nodePath);
						} else if (oArgs.node.title == "suit") {
							oArgs.node.toggle();
							// oArgs.node.toggleHighlight();
							setSuitTable(nodePath);
						} else if (oArgs.node.title == "set") {
							oArgs.node.toggle();
							// oArgs.node.toggleHighlight();
							setSetTable(nodePath);
						} else {
							setTable(nodePath);
						}
					});
	tree.draw();
};

var buildTree = function(treeHtmlCodes) {
	var treediv_html = treeHtmlCodes;
	var body_innerhtml = treediv_html;

	buildCommonTree(treeHtmlCodes, body_innerhtml);
};

var buildCheckBoxTree = function(treeHtmlCodes) {
	var treediv_html = treeHtmlCodes;
	var body_innerhtml = '<table cellpadding="0" cellspacing="0" border="0" width="100%" height="100%" id="table296"><tr><td height="20"><input type="text" id="myInput"style="width:100">&nbsp;<button id="saveProfile">Save As</button><button id="executeProfile">Execute Test</button><br /><br /></td></tr>';
	body_innerhtml += '<tr><td valign="top">' + treediv_html + '</td></tr>';
	body_innerhtml += '<tr><td height="20"><input type="text" id="myInput1"style="width:100">&nbsp;<button id="saveProfileBottom">Save As</button><button id="executeProfileBottom">Execute Test</button><br /><br /></td></tr></table>';

	buildCommonTree(body_innerhtml);
};

var rightTableHead = '<div style="display: none;" class="yui-dt-mask"></div>' + '<table summary=""><colgroup><col><col></colgroup><thead>' + '<tr class="yui-dt-first yui-dt-last">';
var thFirstColumnHead = '<th width="50%" class="yui-dt51-col-key yui-dt-col-key yui-dt-first" colspan="1" rowspan="1" id="yui-dt51-th-key">' + '<div class="yui-dt-liner" id="yui-dt51-th-key-liner">' + '<span class="yui-dt-label">';
var thFirstColumnTail = '</span></div></th>';
var thSecondColumnHead = '<th width="50%" class="yui-dt51-col-value yui-dt-col-value yui-dt-last" colspan="1" rowspan="1" id="yui-dt51-th-value">' + '<div class="yui-dt-liner" id="yui-dt51-th-value-liner"><span class="yui-dt-label">';
var thSecondColumnTail = '</span></div></th></tr></thead>';
var norecordsRaw = '<tbody style="" class="yui-dt-message">' + '<tr class="yui-dt-first yui-dt-last">' + '<td class="yui-dt-empty" colspan="2"><div class="yui-dt-liner">No records found.</div>' + '</td></tr></tbody><tbody class="yui-dt-data" tabindex="0">';
var valueBodyHead = '<tbody style="" class="yui-dt-data" tabindex="0">';

var columnHead = '<td class="yui-dt51-col-key yui-dt-col-key yui-dt-first" headers="yui-dt51-th-key "><div class="yui-dt-liner">';
var columnTail = '</div></td>';
var secondcolumnHead = '<td class="yui-dt51-col-value yui-dt-col-value yui-dt-last" headers="yui-dt51-th-value "><div class="yui-dt-liner">';
var rawTail = '</tr>';
var rightTableTail = '</tbody></table>';
var singleThColumnHead = '<th width="100%" class="yui-dt51-col-key yui-dt-col-key yui-dt-first" colspan="1" rowspan="1" id="yui-dt51-th-key">' + '<div class="yui-dt-liner" id="yui-dt51-th-key-liner">' + '<span class="yui-dt-label">';
var singleThColumnTail = '</span></div></th>';

var drawTestCaseAttrTable = function(jsonTableHtml, jsonArray,
		getFirstColumnValue, getSecondColumnValue) {
	if (jsonArray.length > 0) {
		jsonTableHtml += valueBodyHead;
		for (i = 0; i < jsonArray.length; i++) {
			var rawHead = '<tr id="yui-rec' + i + '" style="" class="';
			if (i % 2 == 0) {
				rawHead += 'yui-dt-even';
			} else {
				rawHead += 'yui-dt-odd';
			}
			if (i == 0) {
				rawHead += ' yui-dt-first';
			}
			if (i == (jsonArray.length - 1)) {
				rawHead += ' yui-dt-last';
			}
			rawHead += '">';

			jsonTableHtml += rawHead + columnHead;
			jsonTableHtml += getFirstColumnValue(jsonArray[i]);
			jsonTableHtml += columnTail + secondcolumnHead;
			jsonTableHtml += getSecondColumnValue(jsonArray[i]);
			jsonTableHtml += columnTail + rawTail;
		}
	} else {
		jsonTableHtml += norecordsRaw;
	}
	jsonTableHtml += rightTableTail;

	return jsonTableHtml;
};

var setTable = function(node) {
	var body_innerHtml = '<div class="yui-dt" id="attributes_div"></div><div class="yui-dt"  id="step_div"></div><div id="meta_div"></div>';
	var c = layout.getUnitByPosition('center');
	c.set('body', body_innerHtml);

	var queryUrl = "ajax_srv.pl?action=load_testcase&";

	var query_tc_Url = 'ajax_srv.pl?action=load_testcase&case=' + node;
	var query_tc_callback = {
		success : function(o) {
			var test_case = eval('(' + o.responseText + ')');

			var testCaseAttrHtml = rightTableHead + thFirstColumnHead
					+ 'Attributes' + thFirstColumnTail + thSecondColumnHead
					+ 'Values' + thSecondColumnTail;

			testCaseAttrHtml = drawTestCaseAttrTable(testCaseAttrHtml,
					test_case.attr, function(item) {
						return item.key;
					}, function(item) {
						return item.value;
					});
			var attr_div = document.getElementById('attributes_div');
			attr_div.innerHTML = testCaseAttrHtml;

			var testCaseStepHtml = rightTableHead + thFirstColumnHead
					+ 'Commands' + thFirstColumnTail + thSecondColumnHead
					+ 'Expect Results' + thSecondColumnTail;

			testCaseStepHtml = drawTestCaseAttrTable(testCaseStepHtml,
					test_case.step, function(item) {
						return item.Command;
					}, function(item) {
						return item.Expected;
					});
			var step_div = document.getElementById('step_div');
			step_div.innerHTML = testCaseStepHtml;
		},
		failure : function(o) {
			var attr_div = document.getElementById('attributes_div');
			attr_div.innerHTML = "<li>HTTP status: " + o.status + "</li>"
					+ "<li>Status code message: " + o.statusText + "</li>";
		}
	};

	YAHOO.util.Connect.asyncRequest('GET', query_tc_Url, query_tc_callback);
};

var setPackageTable = function(nodePath) {
	var body_innerHtml = '<div id="attributes_div"></div>';
	var c = layout.getUnitByPosition('center');
	c.set('body', body_innerHtml);

	var queryUrl = "ajax_srv.pl?action=load_package&";

	// Draw the attribute table.
	drawAttributesTable(nodePath, queryUrl);
};

var setSuitTable = function(nodePath) {
	var body_innerHtml = '<div id="attributes_div"></div>';
	var c = layout.getUnitByPosition('center');
	c.set('body', body_innerHtml);

	var queryUrl = "ajax_srv.pl?action=load_suit&";

	// Draw the attribute table.
	drawAttributesTable(nodePath, queryUrl);
};

var setSetTable = function(nodePath) {
	var body_innerHtml = '<div id="attributes_div"></div>';
	var c = layout.getUnitByPosition('center');
	c.set('body', body_innerHtml);

	var queryUrl = "ajax_srv.pl?action=load_set&";

	// Draw the attribute table.
	drawAttributesTable(nodePath, queryUrl);
};

var loadEventResponse = function(treeHtmlCodes) {

	var changeIconMode = function() {
		var newVal = parseInt(this.value);

		if (newVal != currentIconMode) {
			currentIconMode = newVal;
		}
		buildTree(treeHtmlCodes);
	};
	layout = new YAHOO.widget.Layout('treeDiv1', {
		height : 678,
		units : [ {
			position : 'left',
			width : 300,
			body : '',
			gutter : '0 5 0 2',
			scroll : true
		}, {
			position : 'center',
			body : 'Select Test Case from left panel to view',
			gutter : '0 2 0 0',
			scroll : true
		} ]
	});

	layout
			.on('render', function() {
				var c = layout.getUnitByPosition('center');
				// log.debug('enter left panel');
					// buildTree start
					YAHOO.util.Event.on( [ "mode0", "mode1" ], "click",
							changeIconMode);
					var elment = document.getElementById("mode1");
					if (elment && elment.checked) {
						currentIconMode = parseInt(element.value);
					} else {
						currentIconMode = 0;
					}
					// create a new tree:
					buildTree(treeHtmlCodes);
					// buildTree End

					resize = new YAHOO.util.Resize('demo', {
						handles : [ 'br' ],
						autoRatio : true,
						status : true,
						proxy : true,
						useShim : true,
						minWidth : 700,
						minHeight : 400
					});
					resize
							.on(
									'resize',
									function(args) {
										var h = args.height;
										var hh = this.header.clientHeight;
										var padding = ((10 * 2) + 2); // Sam's
										var bh = (h - hh - padding);
										Dom.setStyle(this.body, 'height',
												bh + 'px');
										layout.set('height', bh);
										layout.set('width',
												(args.width - padding));
										layout.resize();

										// Editor Resize
										var th = (myDataTable.get('element').clientHeight + 2);
										var eH = (h - th);
										myDataTable.set('width',
												args.width + 'px');
										myDataTable.set('height', eH + 'px');
									}, panel, true);
					resize.on('endResize', function() {
						// Fixing IE's calculations
							this.innerElement.style.height = '';
							// Focus the Editor so they can type.
							myDataTable._focusWindow();
						}, panel, true);
				});
	layout.render();
};

var showtest_view = function(treeHtmlCodes) {
	var Dom = YAHOO.util.Dom, Event = YAHOO.util.Event, layout = null, panel = null, tree = null;

	currentIconMode = 0;
	myDataTable = null;
	myDataSource = null;
	Event.onDOMReady(function() {
		loadEventResponse(treeHtmlCodes);
	});
};

var executeProfile = function(profile_name) {
	var postData = '';
	var sUrl = "ajax_srv.pl?action=save_profile&profile=" + profile_name;

	var hiLit = tree.getNodesByProperty('highlightState', 1);
	if (YAHOO.lang.isNull(hiLit)) {
		alert("None Tests are selected");
	} else {
		var labels = [];
		for ( var i = 0; i < hiLit.length; i++) {
			if (hiLit[i].title == "package") {
				var nodePath = encodeURI(getNodePath(hiLit[i]));
				labels.push(nodePath);
			}
		}
		var jsonStr = YAHOO.lang.JSON.stringify(labels);
		postData = 'jsonStr=' + jsonStr;
	}

	var div = document.getElementById('container');
	var callback = {
		success : function(o) {
			var root = o.responseXML.documentElement;
			div.innerHTML = '<font size="1" face="Arial" color="#FFFFFF"><li>' + root
					.getElementsByTagName('profile_result')[0].childNodes[0].nodeValue + '</li></font>';
			document.location = 'tests_exec.pl?profile=' + profile_name;
		},
		failure : function(o) {
			div.innerHTML = "<li>HTTP status: " + o.status + "</li>";
			div.innerHTML += "<li>Status code message: " + o.statusText
					+ "</li>";
		}
	};

	YAHOO.util.Connect.asyncRequest('POST', sUrl, callback, postData);
	div.innerHTML = '';
};

var saveProfile = function(profile_name) {
	var postData = '';
	var sUrl = "ajax_srv.pl?action=save_profile&profile=" + profile_name;

	var hiLit = tree.getNodesByProperty('highlightState', 1);
	if (YAHOO.lang.isNull(hiLit)) {
		alert("None Tests are selected");
	} else {
		var labels = [];
		for ( var i = 0; i < hiLit.length; i++) {
			if (hiLit[i].title == "package") {
				var nodePath = encodeURI(getNodePath(hiLit[i]));
				labels.push(nodePath);
			}
		}
		var jsonStr = YAHOO.lang.JSON.stringify(labels);
		postData = 'jsonStr=' + jsonStr;
	}

	var div = document.getElementById('container');
	var callback = {
		success : function(o) {
			var root = o.responseXML.documentElement;
			var profile_exist = 0;

			var profile_list = document.getElementById('profile_list');
			for (i = profile_list.length - 1; i >= 0; i--) {
				if (profile_list.options[i].text == profile_name) {
					profile_exist = 1;
				}
			}
			/* alert("profile_exist"+profile_exist); */
			if (profile_exist == 0) {
				var elOptNew = document.createElement('option');
				elOptNew.text = profile_name;
				elOptNew.value = profile_name;
				try {
					/* standards compliant; doesn't work in IE */
					profile_list.add(elOptNew, null);
				} catch (ex) {
					/* IE only */
					profile_list.add(elOptNew);
				}
			}
			div.innerHTML += '<font size="1" face="Arial" color="#FFFFFF"><li>' + root
					.getElementsByTagName('profile_result')[0].childNodes[0].nodeValue + '</li></font>';
		},
		failure : function(o) {
			div.innerHTML = "<li>HTTP status: " + o.status + "</li>";
			div.innerHTML += "<li>Status code message: " + o.statusText
					+ "</li>";

		}
	};

	YAHOO.util.Connect.asyncRequest('POST', sUrl, callback, postData);
	div.innerHTML = '';

};

var invokeSaveProfile = function() {
	var profile_name = '';

	var myInputField = document.getElementById('myInput');
	if (myInputField.value != "") {
		profile_name = myInputField.value;
		saveProfile(profile_name);
	} else {
		myInputField = document.getElementById('myInput1');
		if (myInputField.value != "") {
			profile_name = myInputField.value;
			saveProfile(profile_name);
		} else {
			alert("Need Fill a profile name !");
		}
	}
};

var invokeExecuteProfile = function(profile_name) {
	/*
	 * var myInputField = document.getElementById('myInput'); if
	 * (myInputField.value != "") { profile_name = myInputField.value; }else{
	 * myInputField = document.getElementById('myInput1'); if
	 * (myInputField.value != "") { profile_name = myInputField.value; } }
	 */
	executeProfile(profile_name);
};

var loadProfile = function(profile_name) {
	var sUrl = "ajax_srv.pl?action=load_profile&profile=" + profile_name;
	var div = document.getElementById('container');
	var callback = {
		success : function(o) {
			var root = o.responseXML.documentElement;
			div.innerHTML += '<font size="1" face="Arial" color="#FFFFFF"><li>' + root
					.getElementsByTagName('profile_result')[0].childNodes[0].nodeValue + '</li></font>';
			var hiLit = tree.getNodesByProperty('highlightState', 1);
			if (!YAHOO.lang.isNull(hiLit)) {
				for ( var i = 0; i < hiLit.length; i++) {
					hiLit[i].unhighlight();
				}
			}
			var profiled_paths = [];
			if (root.getElementsByTagName('test_packages').length > 0) {
				var testNode = root.getElementsByTagName('test_packages')[0]
						.getElementsByTagName('test_package');
				if (testNode.length > 0) {
					for ( var i = 0; i < testNode.length; ++i) {
						var nodePath = testNode[i].childNodes[0].nodeValue;
						profiled_paths.push(nodePath);
					}
				}
			}
			var dynamicNodes = tree.getNodesByProperty('enableHighlight', true);
			for ( var i = 0; i < dynamicNodes.length; i++) {
				if (dynamicNodes[i].title == "package") {
					var nodePath = getNodePath(dynamicNodes[i]);
					for ( var j = 0; j < profiled_paths.length; j++) {
						var profiled_path = profiled_paths[j];
						if (nodePath === profiled_path) {
							dynamicNodes[i].toggleHighlight();
							break;
						}
					}
				}
			}
		},
		failure : function(o) {
			div.innerHTML = "<li>HTTP status: " + o.status + "</li>";
			div.innerHTML += "<li>Status code message: " + o.statusText
					+ "</li>";
		}
	};

	YAHOO.util.Connect.asyncRequest('GET', sUrl, callback);
	div.innerHTML = '';

};

var deleteProfile = function(profile_name) {
	var sUrl = "ajax_srv.pl?action=delete_profile&profile=" + profile_name;
	var div = document.getElementById('container');
	var callback = {
		success : function(o) {
			var root = o.responseXML.documentElement;
			var profile_list = document.getElementById('profile_list');
			for (i = profile_list.length - 1; i >= 0; i--) {
				if (profile_list.options[i].selected) {
					profile_list.remove(i);
					break;
				}
			}
			div.innerHTML += '<font size="1" face="Arial" color="#FFFFFF"><li>' + root
					.getElementsByTagName('profile_result')[0].childNodes[0].nodeValue + '</li></font>';
		},
		failure : function(o) {
			div.innerHTML = "<li>HTTP status: " + o.status + "</li>";
			div.innerHTML += "<li>Status code message: " + o.statusText
					+ "</li>";

		}
	};
	YAHOO.util.Connect.asyncRequest('GET', sUrl, callback);
	div.innerHTML = '';
};

var loadCBTreeEventResponse = function(treeHtmlCodes, profileName) {

	var changeIconMode = function() {
		var newVal = parseInt(this.value);
		if (newVal != currentIconMode) {
			currentIconMode = newVal;
		}
		buildCheckBoxTree(treeHtmlCodes);
	};

	YAHOO.util.Event.on('executeProfile', 'click', function() {
		invokeExecuteProfile(profileName);
	});
	YAHOO.util.Event.on('executeProfileBottom', 'click', function() {
		invokeExecuteProfile(profileName);
	});
	YAHOO.util.Event.on('saveProfileBottom', 'click', invokeSaveProfile);
	YAHOO.util.Event.on('saveProfile', 'click', invokeSaveProfile);

	YAHOO.util.Event.on('loadProfile', 'click', function() {
		// alert("click loadProfile");
			var profile_list = document.getElementById('profile_list');
			var profile_name = profile_list.value;
			// alert("select profile "+ profile_name);
			var myInputField = document.getElementById('myInput');
			myInputField.value = profile_name;
			var myInputField1 = document.getElementById('myInput1');
			myInputField1.value = profile_name;
			loadProfile(profile_name);
		});
	YAHOO.util.Event.on('deleteProfile', 'click', function() {
		// alert("click loadProfile");
			var profile_list = document.getElementById('profile_list');
			var profile_name = profile_list.value;
			// alert("select profile "+ profile_name);
			deleteProfile(profile_name);
		});

	// This is my requery method
	YAHOO.widget.DataTable.prototype.requery = function(newRequest) {
		var ds = this.getDataSource(), req;
		if (this.get('dynamicData')) {
			// For dynamic data, newRequest is ignored since the request is
			// built by function generateRequest.
			var paginator = this.get('paginator');
			this.onPaginatorChangeRequest(paginator.getState( {
				'page' : paginator.getCurrentPage()
			}));
		} else {
			// The LocalDataSource needs to be treated different
			if (ds instanceof YAHOO.util.LocalDataSource) {
				ds.liveData = newRequest;
				req = "";
			} else {
				// log.debug('enter requery '+newRequest);
				req = (newRequest === undefined ? this.get('initialRequest')
						: newRequest);
			}
			ds.sendRequest(req, {
				success : this.onDataReturnInitializeTable,
				failure : this.onDataReturnInitializeTable,
				scope : this,
				argument : this.getState()
			});
		}
	};

	layout = new YAHOO.widget.Layout('treeDiv1', {
		height : 772,
		units : [ {
			position : 'left',
			width : 300,
			body : '',
			gutter : '0 5 0 2',
			scroll : true
		}, {
			position : 'center',
			body : 'Select Test Case from left panel to view',
			gutter : '0 2 0 0',
			scroll : true
		} ]
	});

	layout.on(
			'render',
			function() {
				var c = layout.getUnitByPosition('center');
				// buildTree start
				YAHOO.util.Event.on( [ "mode0", "mode1" ], "click",
						changeIconMode);
				var elment = document.getElementById("mode1");
				if (elment && elment.checked) {
					currentIconMode = parseInt(element.value);
				} else {
					currentIconMode = 0;
				}
				// create a new tree:

				buildCheckBoxTree(treeHtmlCodes);
				// buildTree End

				resize = new YAHOO.util.Resize('demo', {
					handles : [ 'br' ],
					autoRatio : true,
					status : true,
					proxy : true,
					useShim : true,
					minWidth : 700,
					minHeight : 400
				});
				resize.on('resize', function(args) {
					var h = args.height;
					var hh = this.header.clientHeight;
					var padding = ((10 * 2) + 2);
					var bh = (h - hh - padding);
					Dom.setStyle(this.body, 'height', bh + 'px');
					layout.set('height', bh);
					layout.set('width', (args.width - padding));
					layout.resize();
					var th = (myDataTable.get('element').clientHeight + 2);
					var eH = (h - th);
					myDataTable.set('width', args.width + 'px');
					myDataTable.set('height', eH + 'px');
				}, panel, true);
				resize.on('endResize', function() {
					// Fixing IE's calculations
						this.innerElement.style.height = '';
						// Focus the Editor so they can type.
						myDataTable._focusWindow();
					}, panel, true);
			});
	layout.render();
};

var showtest_select = function(treeHtmlCodes, profileName) {
	var Dom = YAHOO.util.Dom, Event = YAHOO.util.Event, layout = null, panel = null, tree = null;
	currentIconMode = 0;
	myDataTable = null;
	myDataSource = null;

	Event.onDOMReady(function() {
		loadCBTreeEventResponse(treeHtmlCodes, profileName);
	});
};

var show_manual_test_view = function(treeHtmlCodes, test_id) {
	var Dom = YAHOO.util.Dom, Event = YAHOO.util.Event, layout = null, panel = null, tree = null;
	currentIconMode = 0;
	myDataTable = null;
	myDataSource = null;
	Event.onDOMReady(function() {
		loadManualResponse(treeHtmlCodes, test_id);
		var oManSubmitButton = new YAHOO.widget.Button("man_submit");

		oManSubmitButton.on("click", onFormSubmit);

		var oManFinishButton = new YAHOO.widget.Button("man_finish");

		oManFinishButton.on("click", onFinish);
	});
};

var setManualPackageTable = function(node) {
	var body_innerHtml = '<div id="attributes_div"></div>';
	var manual_test_div = document.getElementById('manual_test');
	manual_test_div.innerHTML = body_innerHtml;

	var queryUrl = "ajax_srv.pl?action=load_package&";

	// Draw the attribute table.
	drawAttributesTable(node, queryUrl);
};

var setManualSuitTable = function(node) {
	var body_innerHtml = '<div id="attributes_div"></div>';
	var manual_test_div = document.getElementById('manual_test');
	manual_test_div.innerHTML = body_innerHtml;

	var queryUrl = "ajax_srv.pl?action=load_suit&";

	// Draw the attribute table.
	drawAttributesTable(node, queryUrl);
};

var setManualSetTable = function(node) {
	var body_innerHtml = '<div id="attributes_div"></div>';
	var manual_test_div = document.getElementById('manual_test');
	manual_test_div.innerHTML = body_innerHtml;

	var queryUrl = "ajax_srv.pl?action=load_set&";

	// Draw the attribute table.
	drawAttributesTable(node, queryUrl);
};

function ajaxProcessResult(responseXML) {
	var manual_summary_div = document.getElementById('summary_div');
	manual_summary_div.innerHTML = '<span class="ygtvlabel"><p>Description:</p><p>' + responseXML
			.getElementsByTagName('description')[0].childNodes[0].nodeValue + '</p></span>';
	var case_status = responseXML.getElementsByTagName('case_status')[0].childNodes[0].nodeValue;
	for (i = 0; i < document.mantest_result.teststatus.length; i++) {
		if (document.mantest_result.teststatus[i].value == case_status) {
			document.mantest_result.teststatus[i].checked = true;
		}
	}
}

var setManualCaseTable = function(node, test_id) {
	var manual_test_div = document.getElementById('manual_test');
	var body_innerHtml = '<div class="yui-dt"  id="summary_div"></div><div class="yui-dt" id="attributes_div"></div><div class="yui-dt"  id="step_div"></div><div id="result_div"></div>';
	manual_test_div.innerHTML = body_innerHtml;

	var queryManualCaseUrl = 'ajax_srv.pl?action=load_manual_testcase&case=' + node;
	var query_mc_callback = {
		success : function(o) {
			var manual_case = eval('(' + o.responseText + ')');

			var testCaseAttrHtml = rightTableHead + thFirstColumnHead
					+ 'Attributes' + thFirstColumnTail + thSecondColumnHead
					+ 'Values' + thSecondColumnTail;

			testCaseAttrHtml = drawTestCaseAttrTable(testCaseAttrHtml,
					manual_case.attr, function(item) {
						return item.key;
					}, function(item) {
						return item.value;
					});
			var attr_div = document.getElementById('attributes_div');
			attr_div.innerHTML = testCaseAttrHtml;

			var testCaseStepHtml = rightTableHead + thFirstColumnHead
					+ 'Commands' + thFirstColumnTail + thSecondColumnHead
					+ 'Expect Results' + thSecondColumnTail;

			testCaseStepHtml = drawTestCaseAttrTable(testCaseStepHtml,
					manual_case.step, function(item) {
						return item.Command;
					}, function(item) {
						return item.Expected;
					});
			var step_div = document.getElementById('step_div');
			step_div.innerHTML = testCaseStepHtml;

			var manualCaseDescHtml = rightTableHead + singleThColumnHead
					+ 'Description:' + singleThColumnTail;
			if (manual_case.desc.length) {
				manualCaseDescHtml += valueBodyHead;
				var rawHead = '<tr id="yui-rec0" style="" class="yui-dt-even yui-dt-first yui-dt-last">';

				manualCaseDescHtml += rawHead + columnHead;
				manualCaseDescHtml += manual_case.desc;
				manualCaseDescHtml += columnTail + rawTail;
			} else {
				manualCaseDescHtml += norecordsRaw;
			}
			manualCaseDescHtml += rightTableTail;
			var manual_summary_div = document.getElementById('summary_div');
			manual_summary_div.innerHTML = manualCaseDescHtml;
		},
		failure : function(o) {
			var attr_div = document.getElementById('attributes_div');
			attr_div.innerHTML = "<li>HTTP status: " + o.status + "</li>"
					+ "<li>Status code message: " + o.statusText + "</li>";
		}
	};

	YAHOO.util.Connect.asyncRequest('GET', queryManualCaseUrl,
			query_mc_callback);

	var result_innerHTML = '<br /><form name="mantest_result">';
	result_innerHTML += '<table cellpadding="0" cellspacing="0" border="0" width="100%" height="100%">';
	result_innerHTML += '<tr><td valign="top" height="20"><font size="2" face="Arial">&nbsp;Select Test Result'
			+ '</font></td><td valign="top" height="20"><font size="1" face="Arial"> '
			+ '<input type="radio" value="PASS" id="teststatus" name="teststatus">PASS</input></font></td> '
			+ '<td valign="top"><font size="1" face="Arial"> '
			+ '<input type="radio" value="FAIL" id="teststatus" name="teststatus">FAIL</input></font></td> '
			+ '<td valign="top"><font size="1" face="Arial"> '
			+ '<input type="radio" value="N/A" id="teststatus" name="teststatus">N/A</input></font></td>'
			+ '</tr></table></form><input type="hidden" name="nodePath" id="nodePath" value="'
			+ encodeURI(decodeURIComponent(node)) + '" />';
	var result_div = document.getElementById("result_div");
	result_div.innerHTML = result_innerHTML;

	var query_status_Url = 'load_tc_status.pl?case=' + node + '&test_run='
			+ test_id;
	var query_status_callback = {
		success : function(o) {
			var root = o.responseXML.documentElement;
			var case_status = root.getElementsByTagName('case_status')[0].childNodes[0].nodeValue;

			for (i = 0; i < document.mantest_result.teststatus.length; i++) {
				if (document.mantest_result.teststatus[i].value == case_status) {
					document.mantest_result.teststatus[i].checked = true;
				}
			}
		},
		failure : function(o) {
			var manual_summary_div = document.getElementById('summary_div');
			manual_summary_div.innerHTML = "<li>HTTP status: " + o.status
					+ "</li>";
			manual_summary_div.innerHTML += "<li>Status code message: "
					+ o.statusText + "</li>";
		}
	};

	YAHOO.util.Connect.asyncRequest('GET', query_status_Url,
			query_status_callback);
};

var drawManualCaseAttributesTable = function(nodePath, queryUrl) {
	var myColumnDefs1 = [ {
		key : "key",
		label : "Attributes",
		width : 250
	}, {
		key : "value",
		label : "Values",
		width : 250
	} ];
	myDataSource = new YAHOO.util.DataSource(queryUrl);
	myDataSource.responseType = YAHOO.util.DataSource.TYPE_JSON;

	myDataSource.responseSchema = {
		resultsList : "attr",
		fields : [ "key", "value" ]
	};
	myDataSource.maxCacheEntries = 0;
	YAHOO.widget.DataTable.MSG_EMPTY = 'This case contains no messages';
	var attrTable = new YAHOO.widget.DataTable('attributes_div', myColumnDefs1,
			myDataSource, {
				width : "60em",
				initialRequest : 'case=' + nodePath
			});
	attrTable.render();
};

var buildManualCaseTree = function(body_innerhtml, test_id) {
	var l = layout.getUnitByPosition('left');
	l.set('body', body_innerhtml);

	// create a new tree:
	tree = new YAHOO.widget.TreeView("treediv");
	// get root node for tree:
	var root = tree.getRoot();

	tree.setNodesProperty('propagateHighlightUp', true);
	tree.setNodesProperty('propagateHighlightDown', true);
	tree.subscribe('clickEvent', function(oArgs) {
		var nodePath = encodeURIComponent(getNodePath(oArgs.node));
		if (oArgs.node.title == "package") {
			oArgs.node.toggle();
			oArgs.node.toggleHighlight();
			setManualPackageTable(nodePath);
		} else if (oArgs.node.title == "suit") {
			oArgs.node.toggle();
			setManualSuitTable(nodePath);
		} else if (oArgs.node.title == "set") {
			oArgs.node.toggle();
			setManualSetTable(nodePath);
		} else if (oArgs.node.title == "case") {
			setManualCaseTable(nodePath, test_id);
		}
	});
	tree.draw();
};

var loadManualResponse = function(treeHtmlCodes, test_id) {

	var changeIconMode = function() {
		var newVal = parseInt(this.value);

		if (newVal != currentIconMode) {
			currentIconMode = newVal;
		}
		buildManualCaseTree(treeHtmlCodes, test_id);
	};
	layout = new YAHOO.widget.Layout('treeDiv1', {
		height : 678,
		units : [ {
			position : 'left',
			width : 300,
			body : '',
			gutter : '0 5 0 2',
			scroll : true
		}, {
			position : 'center',
			body : 'Select Test Case from left panel to view',
			gutter : '0 2 0 0',
			scroll : true
		} ]
	});

	layout
			.on(
					'render',
					function() {
						var c = layout.getUnitByPosition('center');
						var body_innerHTML = '<table cellpadding="0" cellspacing="0" border="0" id="table168" width="100%" height="100%">';
						body_innerHTML += '<tr> <td valign="top" width="100%" height="520"><div id="manual_test"></div></td></tr>';
						body_innerHTML += '<tr><td valign="top" height="20"><font size="2" color="#FFFFFF"><input type="submit" id="man_submit" value="SAVE RESULT" name="B17" /><input type="submit" id="man_finish" value="FINISH TEST" name="B18" />&nbsp;&nbsp; </font><div id="container"></div></td></tr></table>';
						c.set('body', body_innerHTML);

						YAHOO.util.Event.on( [ "mode0", "mode1" ], "click",
								changeIconMode);
						var elment = document.getElementById("mode1");
						if (elment && elment.checked) {
							currentIconMode = parseInt(element.value);
						} else {
							currentIconMode = 0;
						}
						// create a new tree:
						var test_id = document.getElementById("test_id").value;
						buildManualCaseTree(treeHtmlCodes, test_id);
						// buildTree End

						resize = new YAHOO.util.Resize('demo', {
							handles : [ 'br' ],
							autoRatio : true,
							status : true,
							proxy : true,
							useShim : true,
							minWidth : 700,
							minHeight : 400
						});
						resize
								.on('resize', function(args) {
									var h = args.height;
									var hh = this.header.clientHeight;
									var padding = ((10 * 2) + 2); // Sam's
										var bh = (h - hh - padding);
										Dom.setStyle(this.body, 'height',
												bh + 'px');
										layout.set('height', bh);
										layout.set('width',
												(args.width - padding));
										layout.resize();

										// Editor Resize
										var th = (myDataTable.get('element').clientHeight + 2);
										var eH = (h - th);
										myDataTable.set('width',
												args.width + 'px');
										myDataTable.set('height', eH + 'px');
									}, panel, true);
						resize.on('endResize', function() {
							// Fixing IE's calculations
								this.innerElement.style.height = '';
								// Focus the Editor so they can type.
								myDataTable._focusWindow();
							}, panel, true);
					});
	layout.render();
};

var onFormSubmit = function() {
	var sUrl = "ajax_srv.pl?action=mantest_submit&test_run=";
	var data = new Array();
	var test_id = document.getElementById("test_id").value;
	sUrl = sUrl + test_id;
	var testcase_status = "None";
	for (i = 0; i < document.mantest_result.teststatus.length; i++) {
		if (document.mantest_result.teststatus[i].checked == true) {
			testcase_status = document.mantest_result.teststatus[i].value;
		}
	}
	if ("None" == testcase_status) {
		alert("Please Select The Test Result!");
		return;
	} else {
		sUrl = sUrl + "&teststatus=" + testcase_status;
	}
	var nodePath = document.getElementById("nodePath").value;
	sUrl = sUrl + "&case=" + encodeURIComponent(nodePath);
	var div = document.getElementById('container');
	var callback = {
		success : function(o) {
			var root = o.responseXML.documentElement;
			div.innerHTML = '<font size="2" face="Arial"><li>' + root
					.getElementsByTagName('man_result')[0].childNodes[0].nodeValue + '</li></font>';
		},
		failure : function(o) {
			div.innerHTML = "<li>HTTP status: " + o.status + "</li>";
			div.innerHTML += "<li>Status code message: " + o.statusText
					+ "</li>";
		}
	};

	YAHOO.util.Connect.asyncRequest('GET', sUrl, callback);
	div.innerHTML = '';
};
var onFinish = function() {
	var test_id = document.getElementById("test_id").value;
	var sUrl = "ajax_srv.pl?action=mantest_finish&test_run=" + test_id;
	var div = document.getElementById('container');
	var callback = {
		success : function(o) {
			var root = o.responseXML.documentElement;
			var response_msg = root.getElementsByTagName('man_result')[0].childNodes[0].nodeValue;
			div.innerHTML = '<font size="2" face="Arial"><li>' + response_msg + '</li></font>';
			if (response_msg == "test status saved") {
				document.location = 'tests_report.pl?details=' + test_id + '&generate=1';
			}
		},
		failure : function(o) {
			div.innerHTML = "<li>HTTP status: " + o.status + "</li>";
			div.innerHTML += "<li>Status code message: " + o.statusText
					+ "</li>";
		}
	};

	YAHOO.util.Connect.asyncRequest('GET', sUrl, callback);
	div.innerHTML = '';

};
