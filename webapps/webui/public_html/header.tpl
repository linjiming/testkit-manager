<!-- 
# Distribution Checker
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
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
#
#   Changlog:
#			07/16/2010, 
#			Remove the 'home' and 'help' tags and make the other tags bigger for keeping the width unchanged by Tang, Shao-Feng  <shaofeng.tang@intel.com>. 
#			Update the background and logo image by Tang, Shao-Feng  <shaofeng.tang@intel.com>.
#
-->
<!-- tina: replaced the new UI
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
-->

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en" dir="ltr">

  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<script type="text/javascript" src="blackbirdjs/blackbird.js"></script>
	<script>
		log.debug("This is a debug");
	</script>
<link type="text/css" rel="Stylesheet" href="blackbirdjs/blackbird.css" />
    <link rel="shortcut icon" href="/favicon.ico" />
    <title>$$$PAGE_TITLE$$$</title>
    
    <style type="text/css" media="screen,projection">/*<![CDATA[*/ @import "css/main.css"; /*]]>*/</style>
    <link rel="stylesheet" type="text/css" media="print" href="css/commonPrint.css" />
    <link rel="stylesheet" type="text/css" href="css/report.css" />
    <!--[if lt IE 5.5000]><style type="text/css">@import "css/IE50Fixes.css";</style><![endif]-->
    <!--[if IE 5.5000]><style type="text/css">@import "css/IE55Fixes.css";</style><![endif]-->
    <!--[if IE 6]><style type="text/css">@import "css/IE60Fixes.css";</style><![endif]-->
    <!--[if IE]><script type="text/javascript" src="css/IEFixes.js"></script>
    <meta http-equiv="imagetoolbar" content="no" /><![endif]-->
    <script type="text/javascript" src="css/dtk.js"></script>
<!--Script and CSS includes for YUI dependencies on this page-->
<link rel="stylesheet" type="text/css" href="yui/build/container/assets/skins/sam/container.css" />
<link rel="stylesheet" type="text/css" href="yui/build/menu/assets/skins/sam/menu.css" />
<link rel="stylesheet" type="text/css" href="yui/build/button/assets/skins/sam/button.css" />
<link rel="stylesheet" type="text/css" href="yui/build/resize/assets/skins/sam/resize.css" />
<link rel="stylesheet" type="text/css" href="yui/build/layout/assets/skins/sam/layout.css" />
<link rel="stylesheet" type="text/css" href="yui/build/treeview/assets/skins/sam/treeview.css" />
<link rel="stylesheet" type="text/css" href="yui/build/datatable/assets/skins/sam/datatable.css" />
<link rel="stylesheet" type="text/css" href="yui/build/tabview/assets/skins/sam/tabview.css" />

<!--end YUI CSS infrastructure--><!--begin YUIL Utilities -->
<style type="text/css">
/*margin and padding on body element
  can introduce errors in determining
  element position and are not recommended;
  we turn them off as a foundation for YUI
  CSS treatments. */

body {
        margin:0;
        padding:0;
}


/* Remove row striping, column borders, and sort highlighting */

.ygtvlabel, .ygtvlabel:link, .ygtvlabel:visited, .ygtvlabel:hover { 
    margin-left:2px;
    text-decoration: none;
    background-color: white; /* workaround for IE font smoothing bug */
    cursor:pointer;
    font-family:arial;font-size:12;
}
.yui-skin-sam .yui-dt table {
    font-family:arial;font-size:12;
    width:100%;
}
.yui-skin-sam .yui-dt th,
.yui-skin-sam .yui-dt th a {
    text-align:left;
}
.yui-skin-sam .yui-layout .yui-layout-unit div.yui-layout-bd {
    background-color: #FFFFFF;
    font-family:arial;font-size:12;
}

.yui-dt-editor {
	font-family:arial;font-size:12;
}
#meta_div tbody td {
    border-bottom: 1px solid #ddd;
}
#meta_div tr.yui-dt-last td,
#meta_div th,
#meta_div td {
    border: none;
}
#meta_div thead {
        display: none;
}

/* Class for marked rows */
#meta_div tr,
#meta_div tr td.yui-dt-asc,
#meta_div tr td.yui-dt-desc,
#meta_div tr td.yui-dt-asc,
#meta_div tr td.yui-dt-desc {
    background-color: #778899;
    color: #fff;
}
/*#step_div tr.yui-dt-first td {
	height:500px;
}
*/


</style>
<!--end YUI CSS infrastructure--><!--begin YUIL Utilities -->

<script src="yui/build/yahoo/yahoo.js"></script>
<script src="yui/build/event/event.js"></script>
<script src="yui/build/yahoo-dom-event/yahoo-dom-event.js"></script>
<script src="yui/build/utilities/utilities.js"></script>
<script src="yui/build/container/container-min.js"></script>
<script src="yui/build/resize/resize-min.js"></script>
<script src="yui/build/layout/layout-min.js"></script>
<script src="yui/build/treeview/treeview.js"></script>
<script src="yui/build/connection/connection-min.js"></script>
<script src="yui/build/datasource/datasource-min.js"></script> 
<script src="yui/build/datatable/datatable-min.js"></script> 
<script src="yui/build/element/element-min.js"></script>
<script src="yui/build/button/button-min.js"></script>
<script src="yui/build/json/json-min.js"></script>
<script src="yui/build/tabview/tabview-min.js"></script>






  </head> 

  <body class="ns-0" onclick="javascript:if (typeof(onBodyClick)!='undefined') onBodyClick();" onload="javascript:if (typeof(ajaxInit)!='undefined') ajaxInit();" onmousemove="javascript:dragMove(event);" onmouseup="javascript:dragStop(event);">

    
    <!-- BEGIN globalWrapper -->

    <div id="globalWrapper">      
    <!-- START masthead -->
<!-- tina: replaced the new UI 
    <table width="100%" border="0" cellpadding="0" cellspacing="0" bgcolor="#ffffff">

      <tr>
        <td height="10"><img src="images/environment-spacer.gif" width="1" height="1" alt="" /></td>
      </tr>

      <tr>
        <td>

          <table width="100%" border="0" cellspacing="0" cellpadding="0">
            <tr>
              <td>
                <table width="100%" border="0" cellpadding="0" cellspacing="0">
                  <tr>
                    <td height="45" align="left" valign="bottom">
                      <table width="100%" border="0" cellpadding="0" cellspacing="0">
                        <tr>
                          <td height="70">
<!--elva
                            <a href="http://www.linuxfoundation.org/" target="_blank"><img hspace="13" src="images/lflogo.png" alt="The Linux Foundation" title="The Linux Foundation" /></a>
                            <a href="/"><img src="images/$$$MTK_BRANCH_LC$$$-dist-checker-logo.png" width="220" height="59" border="0" alt="$$$MTK_BRANCH$$$ Distribution Checker Homepage" title="$$$MTK_BRANCH$$$ Distribution Checker Start Page" /></a>
-->

<!-- tina: replaced the new UI 
                            <a href="/"><img src="images/moblin-testkit-logo.png" width="220" height="59" border="0" alt="MeeGo Testkit Homepage" title="MeeGo Testkit Start Page" /></a>
                          </td>
                        </tr>
                      </table>
                    </td>
                  </tr>

                  <!-- START level 1 links -->

<!-- tina: replaced the new UI 
                  <tr>
                    <td align="left" valign="bottom" bgcolor="#003E69">
<div id="level_1_links">
  <table width="100%" border="0" cellpadding="0" cellspacing="0">
    <tr>
      <td width="100%" align="left" style="white-space: nowrap;">
        <img src="images/environment-spacer.gif" width="8" height="1" alt="" />
        <a href='tests_view.pl' class='link-level1$$$CERT_STYLE$$$'>View Tests</a> |
        <a href='tests_conf.pl' class='link-level1$$$CONFIGURE_STYLE$$$'>Select Tests</a> |
        <a href='tests_exec.pl' class='link-level1$$$PROGRESS_STYLE$$$'>Tests Execution</a> |
        <a href='tests_results.pl' class='link-level1$$$RESULTS_STYLE$$$'>Test Report</a> |
        <a href='tests_help.pl' class='link-level1$$$HELP_STYLE$$$'>Help</a> |
        <a href='tests_about.pl' class='link-level1$$$ABOUT_STYLE$$$'>About</a>
        <img src="images/environment-spacer.gif" width="8" height="1" alt="" />
      </td>
<!--elva: remove Administration
      <td align="right" style="white-space: nowrap;">
        <img src="images/environment-spacer.gif" width="8" height="1" alt="" />
        <a href='tests_admin.pl' class='link-level1$$$ADMIN_STYLE$$$'>Administration</a>
        <img src="images/environment-spacer.gif" width="8" height="1" alt="" />
      </td>
-->

<!-- tina: replaced the new UI 
    </tr>
  </table>
</div>
                    </td>
                  </tr>
                  <!-- END level 1 links -->
<!-- tina: replaced the new UI 
                </table>
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
    <!-- END masthead -->
<table width="1020" height="54" cellpadding="0" cellspacing="0" bgcolor="#ffffff">
  	<tr>
		<td valign="top" height="16"></td>
		<td valign="top" rowspan="2" width="243">   
		<img border="0" src="images/logo4.png" width="197" height="54"></td>
	</tr>
                  <!-- START level 1 links -->
	<tr>
		<td valign="top" height="38" width="805">
	<table cellpadding="0" cellspacing="0" width="805" height="38" id="table451">
	 <tr>
<!-- Comment the Home page Joey
	 <td valign="middle" width="115" background="images/button2.png">
<p align="center"><font face="Arial " size="1"><a href='index.pl' class='link-level1'>HOME</a></font></td>
-->
	 <td width="115" background="images/button1.png" align="center">
<font face="Arial " size="1"><a href='tests_view.pl' class='link-level1'>VIEW TEST</a></font></td>
	 <td width="115" background="images/button1.png" align="center">
<font face="Arial " size="1"><a href='tests_conf.pl' class='link-level1'>SELECT TEST</a></font></td>
	 <td width="115" background="images/button1.png" align="center">
<font face="Arial " size="1"><a href='tests_exec.pl' class='link-level1'>EXECUTE TEST</a></font></td>
	 <td width="115" background="images/button1.png" align="center">
<font face="Arial " size="1"><a href='tests_results.pl' class='link-level1'>TEST REPORT</a></font></td>

<!-- Comment the Help page Joey
	 <td width="115" background="images/button1.png" align="center">
<font face="Arial " size="1"><a href='tests_help.pl' class='link-level1'>HELP</a></font></td>
-->
	 <td height="38" width="115" background="images/button1.png" align="center">
<font face="Arial " size="1"><a href='tests_about.pl' class='link-level1'>ABOUT</a></font></td>
	 </tr>
     </table>
   </td>
                  <!-- END level 1 links -->
  </tr>
</table>
    <!-- END masthead -->

    <!-- START level2 links -->
<!-- tina: change css style
<div id="level_2_links">

</div>
    <!-- END level2 links -->

    <!-- START main body -->
              <!-- START content -->
<!-- tina: change css style
              <div id="content">
<br />
-->
