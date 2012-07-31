#!/usr/bin/perl -w
#
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
#   Authors:
#
#          Wendong,Sui  <weidongx.sun@intel.com>
#          Tao,Lin  <taox.lin@intel.com>
#
#

use strict;
use Templates;

print "HTTP/1.0 200 OK" . CRLF;
print "Content-type: text/html" . CRLF . CRLF;

print_header( "$MTK_BRANCH Manager Main Page", "help" );

print <<DATA;
<table width="1280" border="0" cellspacing="0" cellpadding="0" class="help_list">
  <tr>
    <td>&nbsp;</td>
    <td><table width="27%" border="1" cellpadding="0" cellspacing="0" bordercolor="#E2E3E3">
        <tr>
          <td align="center">Contents [<a id="contents_text" href="#" onClick="javascript:showContents()">hide</a>]</td>
        </tr>
      </table></td>
    <td>&nbsp;</td>
  </tr>
  <tr>
    <td width="2%">&nbsp;</td>
    <td><div id="contents">
        <table width="27%" border="1" cellpadding="0" cellspacing="0" bordercolor="#E2E3E3">
          <tr>
            <td align="left"><ol>
                <li><a href="#overview">Overview</a></li>
                <li><a href="#custom_tests">Custom Tests</a>
                  <ol>
                    <li><a href="#filter_function">Filter function</a></li>
                    <li><a href="#how_to_use_profiles">How to use profiles</a></li>
                    <li><a href="#useful_features_custom">Useful features</a></li>
                  </ol>
                </li>
                <li><a href="#how_to_execute">How to Execute</a>
                  <ol>
                    <li><a href="#execute_auto_cases">Execute auto cases</a></li>
                    <li><a href="#execute_manual_cases">Execute manual cases</a></li>
                  </ol>
                </li>
                <li><a href="#how_to_view_report">How to View Report</a>
                  <ol>
                    <li><a href="#how_to_view_summary_reports">How to view summary reports</a></li>
                    <li><a href="#how_to_view_detailed_reports">How to view detailed reports</a></li>
                    <li><a href="#useful_features_report">Useful features</a></li>
                  </ol>
                </li>
              </ol></td>
          </tr>
        </table>
      </div></td>
    <td width="2%">&nbsp;</td>
  </tr>
  <tr>
    <td width="2%">&nbsp;</td>
    <td align="left"><div id="overview">
        <table width="100%" border="0" cellspacing="0" cellpadding="0">
          <tr>
            <td class="report_list_one_row help_level_1"><table width="100%" border="0" cellspacing="0" cellpadding="0">
                <tr>
                  <td>Overview</td>
                  <td align="right" class="help_list" style="font-weight:normal">[<a href="#">top</a>]</td>
                </tr>
              </table></td>
          </tr>
          <tr>
            <td><p>Testkit-manager is a GUI (Graphical User Interface), which is developed as an auto-testing tool. It uses "testkit-lite" as execution tool for running case. With this tool, we can filter cases that we want to run with several properties' value, the filtered cases can be run automatically and the report will be generated after finishing running. We can also submit report and view report with this tool.</p>
              <p>Some major features are listed as bellow:</p>
              <ol>
                <li>We can filter cases with the property value of the case, such as version, category, priority, status, execution type, test suite, type, test set and component. And we can view the detailed information of the cases that we have filtered.</li>
                <li>We can save profile which contains test case information that we have filtered, load profile and delete profile which we have saved, and execute profile which we have loaded.</li>
                <li>We can install packages, update packages and delete packages.</li>
                <li>We can execute both auto cases and manual cases which we have filtered, and add test result for manual cases.</li>
                <li>After executing test cases, the tool will generate a report automatically, we can view report, compare report, delete report, submit report and export report.</li>
              </ol></td>
          </tr>
        </table>
      </div></td>
    <td width="2%">&nbsp;</td>
  </tr>
  <tr>
    <td width="2%">&nbsp;</td>
    <td align="left"><div id="custom_tests">
        <table width="100%" border="0" cellspacing="0" cellpadding="0">
          <tr>
            <td class="report_list_one_row help_level_1"><table width="100%" border="0" cellspacing="0" cellpadding="0">
                <tr>
                  <td>Custom Tests</td>
                  <td align="right" class="help_list" style="font-weight:normal">[<a href="#">top</a>]</td>
                </tr>
              </table></td>
          </tr>
          <tr>
            <td><table width="100%" border="0" cellspacing="0" cellpadding="0">
                <tr>
                  <td align="left"><div id="filter_function">
                      <table width="100%" border="0" cellspacing="0" cellpadding="0">
                        <tr>
                          <td class="report_list_one_row help_level_2"><table width="100%" border="0" cellspacing="0" cellpadding="0">
                              <tr>
                                <td>Filter function</td>
                                <td align="right" class="help_list" style="font-weight:normal">[<a href="#">top</a>]</td>
                              </tr>
                            </table></td>
                        </tr>
                        <tr>
                          <td><p>There are ten properties for testcase as below. We can filter the cases that we want to test by filter function according to these properties' value.</p>
                            <p>1.Architecture	2.Version	3.Category	4.Priority	5.Status</p>
                            <p>6.Execution Type	7.Test suite	8.Type	9.Test set	10.Component</p>
                            <ol>
                              <li>Click icon "Custom", and then the page as below will display, options &lt;Architecture&gt;, &lt;Version&gt; and button &lt;Advanced&gt; will display at the top of this page.</li>
                              <img src="images/pic_3_1.png" width="544" height="224" />
                              <li>Click button &lt;Advanced&gt;, the hidden options will display.</li>
                              <img src="images/pic_3_2.png" width="482" height="276" />
                              <li>Take &lt;category&gt; option and &lt;priority&gt; option for example:</li>
                              <ol>
                                <li>At first, consuming that all the ten options' value are init values which are "Any ***", then all the packages installed in the device will display.</li>
                                <li>Select &lt;category&gt; option with value "Netbook". The packages, which include testcase whose category is "Netbook" , will  display.</li>
                                <img src="images/pic_3_3.png" width="560" height="272" />
                                <li>Then, select &lt;priority&gt; option with value "P1", the packages displayed in step (2), which also include testcase whose priority is "P1", will  display.</li>
                                <img src="images/pic_3_4.png" width="573" height="258" />
                                <li>Select other options in the same way.</li>
                              </ol>
                              <li>Among these displayed packages, we can click "checkbox" to choose the packages that we want to test.</li>
                              <img src="images/pic_3_5.png" width="574" height="260" />
                            </ol></td>
                        </tr>
                      </table>
                    </div></td>
                </tr>
                <tr>
                  <td align="left"><div id="how_to_use_profiles">
                      <table width="100%" border="0" cellspacing="0" cellpadding="0">
                        <tr>
                          <td class="report_list_one_row help_level_2"><table width="100%" border="0" cellspacing="0" cellpadding="0">
                              <tr>
                                <td>How to use profiles</td>
                                <td align="right" class="help_list" style="font-weight:normal">[<a href="#">top</a>]</td>
                              </tr>
                            </table></td>
                        </tr>
                        <tr>
                          <td><p>Profiles are used to save the information of test cases which we have filtered for testing in future, we can load profile and delete profile which we have saved, and execute profile which we have loaded.</p>
                            <ol>
                              <li>Save profiles:</li>
                              <ol>
                                <li>Filter packages as introduced in 3.1</li>
                                <li>Input &lt;Profile name :&gt; in the context [8]. We add a "auto search" function for this context.  When we input one profile name, it will automatically search files under the path://***/testkit-manager/profiles/test/ to check whether the profile name has existed.</li>
                                <img src="images/pic_3_6.png" width="560" height="260" />
                                <li>If the "auto search" shows "No match profile"[9], then click button &lt;Save&gt;, and the profile will be saved under path://***/testkit-manager/profiles/test/.</li>
                                <img src="images/pic_3_7.png" width="540" height="255" />
                                <li>
                                  <p>If the "auto search" shows the matched profile name, it represents that there has been profiles whose name are similar to or the same as that you input. [10].</p>
                                  <p>When you select one profile name which has been saved before and then click button &lt;Save&gt;, one confirmation will pop up with content "Profile: &lt;profile name input&gt; exists, Would you like to overwirte it?".</p>
                                </li>
                                <img src="images/pic_3_8.png" width="360" height="121" />
                                <p>click OK return true, profile "temp_profile" will cover the profile saved before.</p>
                                <p>Click Cancel return false, profile won't be saved.</p>
                                <li>
                                  <p>Notes:</p>
                                  <p>The profile name can't be empty. When click button &lt;Save&gt; without profile name, one alert will popup with content "Please, specify the profile name!".</p>
                                </li>
                                <img src="images/pic_3_9.png" width="363" height="122" />
                              </ol>
                              <li>Load profiles:</li>
                              <p>We can load profile which we have saved, and run the profile.</p>
                              <ol>
                                <li>As picture 3-10, fill in the profile name, and click button &lt;Load&gt;.</li>
                                <img src="images/pic_3_10.png" width="627" height="284" />
                                <li>As picture 3-11, the profile "temp_profile" will be loaded.</li>
                                <img src="images/pic_3_11.png" width="628" height="281" />
                                <li>Notes:</li>
                                <ol>
                                  <li>If the "auto search" shows the matched profile name, it represents that there has been profiles whose name are similar to or the same as what you input..  Then you can select one profile you want to run and click button &lt;Load&gt;. The profile will be loaded and the page will be automatically refreshed to the page saved before.</li>
                                  <li>The profile name can't be empty. When click button &lt;Save&gt; without profile name, one alert will pop up with content "Please, specify the profile name!".</li>
                                  <li>When profile is loaded, if all the eight options' value listed by button &lt;Advanced&gt; are "Any ***", the page will be refreshed without eight options displaying. if one of the eight options has values such as category="Netbook", the page will be refreshed with eight options displayed.</li>
                                </ol>
                              </ol>
                              <li>Delete profiles:</li>
                              <p>We can delete profile which we have saved.</p>
                              <ol>
                                <li>If the "auto search" shows "No match profile", If click button &lt;Delete&gt; at this moment, one alert will popup with content "Does not exist profile: &lt;the profile input&gt;!".</li>
                                <li>If the "auto search" shows the matched profile name, it represents that there has been profiles whose name are similar to or the same as what you input..  Then you can select one profile you want to delete and click button &lt;Delete&gt;. One confirmation will pop up.</li>
                              </ol>
                              <li>Execute profiles:</li>
                              <p>There are two ways to execute profiles:  execute existing profile and execute temporary profile.</p>
                              <ol>
                                <li>
                                  <p>Execute existing profile:</p>
                                  <p>Input profile name, then click button &lt;Load&gt;, the profile will be loaded and the page will be automatically refreshed to the page saved before. After that click button &lt;Execute&gt;. The page will jump to execute page and the profile is executed.</p>
                                </li>
                                <li>
                                  <p>Execute temporary profile:</p>
                                  <p>Use Filter function introduced in part 1 and select the packages you want to run, then click button &lt;Execute&gt;. The page will jump to execute page and the profile is executed.</p>
                                </li>
                              </ol>
                            </ol></td>
                        </tr>
                      </table>
                    </div></td>
                </tr>
                <tr>
                  <td align="left"><div id="useful_features_custom">
                      <table width="100%" border="0" cellspacing="0" cellpadding="0">
                        <tr>
                          <td class="report_list_one_row help_level_2"><table width="100%" border="0" cellspacing="0" cellpadding="0">
                              <tr>
                                <td>Useful features</td>
                                <td align="right" class="help_list" style="font-weight:normal">[<a href="#">top</a>]</td>
                              </tr>
                            </table></td>
                        </tr>
                        <tr>
                          <td><ol>
                              <li>View case information</li>
                              <ol>
                                <li>Click button &lt;view&gt;, the page will be refreshed as bellow:</li>
                                <img src="images/pic_3_12.png" width="562" height="390" />
                                <li>Click the case name, the detailed case info will display in the right of the page.</li>
                              </ol>
                              <li>Sort packages</li>
                              <p>Click button with arrow icon, the packages will be sorted. Click this button again and the packages will be reversely sorted.</p>
                              <img src="images/pic_3_13.png" width="627" height="258" />
                              <li>Delete packages</li>
                              <p>Click button wich delete icon in picture 3-14, and one confirmation will pop up.</p>
                              <img src="images/pic_3_14.png" width="628" height="257" />
                              <li>List package information</li>
                              <p>Click package name, and detailed packages information will be listed.</p>
                              <img src="images/pic_3_15.png" width="535" height="325" />
                            </ol></td>
                        </tr>
                      </table>
                    </div></td>
                </tr>
              </table></td>
          </tr>
        </table>
      </div></td>
    <td width="2%">&nbsp;</td>
  </tr>
  <tr>
    <td width="2%">&nbsp;</td>
    <td align="left"><div id="how_to_execute">
        <table width="100%" border="0" cellspacing="0" cellpadding="0">
          <tr>
            <td class="report_list_one_row help_level_1"><table width="100%" border="0" cellspacing="0" cellpadding="0">
                <tr>
                  <td>How to execute</td>
                  <td align="right" class="help_list" style="font-weight:normal">[<a href="#">top</a>]</td>
                </tr>
              </table></td>
          </tr>
          <tr>
            <td><table width="100%" border="0" cellspacing="0" cellpadding="0">
                <tr>
                  <td align="left"><div id="execute_auto_cases">
                      <table width="100%" border="0" cellspacing="0" cellpadding="0">
                        <tr>
                          <td class="report_list_one_row help_level_2"><table width="100%" border="0" cellspacing="0" cellpadding="0">
                              <tr>
                                <td>Execute auto cases</td>
                                <td align="right" class="help_list" style="font-weight:normal">[<a href="#">top</a>]</td>
                              </tr>
                            </table></td>
                        </tr>
                        <tr>
                          <td><p>There are two ways to execute cases:</p>
                            <ul>
                              <li>Filter cases or load profile, and click button &lt;Execute&gt; in custom page.</li>
                              <li>Select profile to run in execute page.</li>
                            </ul>
                            <ol>
                              <li>After click button &lt;Execute&gt;, the profile will run with log on the screen. When finish running, the report will be generated automatically.</li>
                              <img src="images/pic_4_1.png" width="504" height="298" />
                              <li>When the profile (without manual cases) has finished running, the page will directly jump to "Report page".</li>
                              <img src="images/pic_4_2.png" width="621" height="131" />
                            </ol></td>
                        </tr>
                      </table>
                    </div></td>
                </tr>
                <tr>
                  <td align="left"><div id="execute_manual_cases">
                      <table width="100%" border="0" cellspacing="0" cellpadding="0">
                        <tr>
                          <td class="report_list_one_row help_level_2"><table width="100%" border="0" cellspacing="0" cellpadding="0">
                              <tr>
                                <td>Execute manual cases</td>
                                <td align="right" class="help_list" style="font-weight:normal">[<a href="#">top</a>]</td>
                              </tr>
                            </table></td>
                        </tr>
                        <tr>
                          <td><ol>
                              <li>When the profile (with manual cases) has finished running, the page will be refreshed as Picture 4-3, then we can add the result of manual cases.</li>
                              <img src="images/pic_4_3.png" width="556" height="353" />
                              <ul>
                                <li>Click &lt;Manual Test&gt; and all the manual cases will display on the right of the page.</li>
                                <li>Test case manually and get the results, then select real result for pass/fail or N/A.</li>
                                <li>Then Click button &lt;SAVE&gt;.</li>
                                <li>By the way, the buttons &lt;PASS&gt; (&lt;FAIL&gt;, &lt;N/A&gt;) is used for selecting all the manual cases displayed in the page to pass (fail, N/A).</li>
                                <li>Click button &lt;FINISH&gt; to complete execution.</li>
                              </ul>
                              <li>After adding the result of manual cases, the page will be refreshed as Picture 4-4.</li>
                              <img src="images/pic_4_4.png" width="628" height="131" />
                            </ol></td>
                        </tr>
                      </table>
                    </div></td>
                </tr>
              </table></td>
          </tr>
        </table>
      </div></td>
    <td width="2%">&nbsp;</td>
  </tr>
  <tr>
    <td width="2%">&nbsp;</td>
    <td align="left"><div id="how_to_view_report">
        <table width="100%" border="0" cellspacing="0" cellpadding="0">
          <tr>
            <td class="report_list_one_row help_level_1"><table width="100%" border="0" cellspacing="0" cellpadding="0">
                <tr>
                  <td>How to view report</td>
                  <td align="right" class="help_list" style="font-weight:normal">[<a href="#">top</a>]</td>
                </tr>
              </table></td>
          </tr>
          <tr>
            <td><table width="100%" border="0" cellspacing="0" cellpadding="0">
                <tr>
                  <td align="left"><div id="how_to_view_summary_reports">
                      <table width="100%" border="0" cellspacing="0" cellpadding="0">
                        <tr>
                          <td class="report_list_one_row help_level_2"><table width="100%" border="0" cellspacing="0" cellpadding="0">
                              <tr>
                                <td>How to view summary reports</td>
                                <td align="right" class="help_list" style="font-weight:normal">[<a href="#">top</a>]</td>
                              </tr>
                            </table></td>
                        </tr>
                        <tr>
                          <td><ol>
                              <li>Click view summary icon to view summary reports.</li>
                              <img src="images/pic_5_1.png" width="609" height="224" />
                              <li>The page will be refreshed as picture 5-2.</li>
                              <img src="images/pic_5_2.png" width="582" height="385" />
                              <p>According to picture 5-2, we can view summary information such as test environment information, case' total numbers, pass/fail/block numbers, and test log. We can also use three buttons below:</p>
                              <ul>
                                <li>Click view detailed report icon to view detailed reports.</li>
                                <li>Click download icon to download consolidated log.</li>
                                <li>Click copy URL icon to copy URL to the clipboard and you can paste it to anywhere.</li>
                              </ul>
                            </ol></td>
                        </tr>
                      </table>
                    </div></td>
                </tr>
                <tr>
                  <td align="left"><div id="how_to_view_detailed_reports">
                      <table width="100%" border="0" cellspacing="0" cellpadding="0">
                        <tr>
                          <td class="report_list_one_row help_level_2"><table width="100%" border="0" cellspacing="0" cellpadding="0">
                              <tr>
                                <td>How to view detailed reports</td>
                                <td align="right" class="help_list" style="font-weight:normal">[<a href="#">top</a>]</td>
                              </tr>
                            </table></td>
                        </tr>
                        <tr>
                          <td><ol>
                              <li>Click view detailed icon to view detailed reports.</li>
                              <img src="images/pic_5_3.png" width="627" height="238" />
                              <li>The page will refreshed as picture 5-4, you can view by three types including "Packages", "Component" or "Test type".</li>
                              <img src="images/pic_5_4.png" width="628" height="134" />
                              <li>Take "View by Package" for example, and we can filter a report with option &lt;Result&gt; and &lt;Type&gt; with related values in picture 5-5</li>
                              <img src="images/pic_5_5.png" width="628" height="148" />
                              <li>According to picture 5-6:</li>
                              <ul>
                                <li>Click Case name, and you can view detailed case information.</li>
                                <li>Click view summary report icon, and you can view summary report.</li>
                              </ul>
                              <img src="images/pic_5_6.png" width="627" height="557" />
                            </ol></td>
                        </tr>
                      </table>
                    </div></td>
                </tr>
                <tr>
                  <td align="left"><div id="useful_features_report">
                      <table width="100%" border="0" cellspacing="0" cellpadding="0">
                        <tr>
                          <td class="report_list_one_row help_level_2"><table width="100%" border="0" cellspacing="0" cellpadding="0">
                              <tr>
                                <td>Useful features</td>
                                <td align="right" class="help_list" style="font-weight:normal">[<a href="#">top</a>]</td>
                              </tr>
                            </table></td>
                        </tr>
                        <tr>
                          <td><ol>
                              <li>Submit report</li>
                              <p>Use button &lt;Submit&gt; to submit report to QA tools. Use button &lt;Delete&gt; to delete reports.</p>
                              <ol>
                                <li>Log in http://localhost:8899/</li>
                                <li>Click icon "Report", then the page as below will display.</li>
                                <img src="images/pic_5_7.png" width="628" height="237" />
                                <li>According to Picture 5-7, click the checkbox in the report page (one report or several reports can be selected), then the buttons will display (black) from hidden states (gray).</li>
                                <li>Click button &lt;Submit&gt;, the page will be refreshed as below:</li>
                                <img src="images/pic_5_8.png" width="627" height="134" />
                                <p>According to Picture 5-8:</p>
                                <ol>
                                  <li>Input server name in context &lt;Input Server Name&gt;</li>
                                  <p>Input Token in context &lt;Input Token&gt;. The token is a string which records your account and password information. You can get token after logging in QA tools with your account.</p>
                                  <li>Input the report date in context &lt;Input Image Date&gt;. We use %2E represent ".". Take "20120319.5" for example, we should input "20120319%2E5".</li>
                                  <img src="images/pic_5_9.png" width="627" height="134" />
                                  <li>Select values for the three options &lt;target&gt; &lt;test type&gt; &lt;hwproduct&gt; in picture 5-10</li>
                                  <img src="images/pic_5_10.png" width="627" height="310" />
                                  <li>After these steps, click button &lt;Submit&gt;, and the report(s) will be submitted to the QA tools.</li>
                                  <img src="images/pic_5_11.png" width="627" height="133" />
                                </ol>
                              </ol>
                              <li>Delete report</li>
                              <ol>
                                <li>Check the report you want to delete with checkbox. (one or more reports can be checked)</li>
                                <img src="images/pic_5_12.png" width="628" height="233" />
                                <li>Click button &lt;Delete&gt; and one alert will popup as below:</li>
                                <img src="images/pic_5_13.png" width="351" height="120" />
                                <p>Click OK, report(s) will be deleted.</p>
                                <p>Click Cancel, report(s) won't be deleted.</p>
                              </ol>
                              <li>Complete report with manual cases</li>
                              <p>Packages include some manual cases whose results need submitting manually to the report.</p>
                              <ol>
                                <li>According to picture 5-14, If the "Not run" case number is 0, the button is gray (The button is disable and can't be clicked) with title "Execution Complete". If the "Not run" case number is not 0, the button is colorful (the button is enable and can be clicked) with title "Continue Execution"</li>
                                <img src="images/pic_5_14.png" width="627" height="214" />
                                <li>Click execute manual button, and the page will be refreshed as picture 5-15. then we can modify the result of manual cases.</li>
                                <img src="images/pic_5_15.png" width="556" height="353" />
                                <li>The result won't be edited after this step. Refresh the report page, and you will find the button is gray.</li>
                              </ol>
                            </ol></td>
                        </tr>
                      </table>
                    </div></td>
                </tr>
              </table></td>
          </tr>
        </table>
      </div></td>
    <td width="2%">&nbsp;</td>
  </tr>
</table>

<script language="javascript" type="text/javascript">
// <![CDATA[
function showContents() {
	var contents = document.getElementById('contents');
	var contents_text = document.getElementById('contents_text');
	if (contents.style.display == "none") {
		contents.style.display = "";
		contents_text.innerHTML = "hide";
	} else {
		contents.style.display = "none";
		contents_text.innerHTML = "show";
	}
}
// ]]>
</script>
DATA

print_footer("");
