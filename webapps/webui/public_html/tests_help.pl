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
#
# Authors:
#              Zhang, Huihui <huihuix.zhang@intel.com>
#              Wendong,Sui  <weidongx.sun@intel.com>

use strict;
use Templates;

print "HTTP/1.0 200 OK" . CRLF;
print "Content-type: text/html" . CRLF . CRLF;

print_header( "$MTK_BRANCH Manager Main Page", "help" );

print <<DATA;
<table width="768" border="0" cellspacing="0" cellpadding="0" class="help_list">
  <tr>
    <td>&nbsp;</td>
    <td><table width="30%" border="1" cellpadding="0" cellspacing="0" bordercolor="#E2E3E3">
        <tr>
          <td align="center">Contents [<a id="contents_text" href="#" onClick="javascript:showContents()">hide</a>]</td>
        </tr>
      </table></td>
    <td>&nbsp;</td>
  </tr>
  <tr>
    <td width="2%">&nbsp;</td>
    <td><div id="contents">
        <table width="30%" border="1" cellpadding="0" cellspacing="0" bordercolor="#E2E3E3">
          <tr>
            <td align="left"><ol>
                <li><a href="#overview">Overview</a></li>
                <li><a href="#building_test_case">Building Test Case</a></li>
                <li><a href="#customzing_tests">Customzing Tests</a></li>
                <li><a href="#executing_test_cases">Executing Test Cases</a></li>
                <li><a href="#viewing_report">Viewing Report</a></li>
                <li><a href="#Statistic_tests">Statistic Test Case</a></li>
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
            <td><p>Testkit-Manager, a Graphical User Interface (GUI) front-end in browser, manages auto test cases execution remotely and provides unified web UI to help manual tests execution. </p>
              <p>Testkit-Manager has the following features: </p>
              <ol>
                <li>You can filter test cases as per their property value, including architecture, version, category, priority, status, execution type, test suite, type, test set, and component. After that, you can view the detailed information of the test cases.</li>
                <li>You can save the detailed test case information as a test plan, and load, delete, or execute the test plan.</li>
                <li>You can install, update, and delete test case packages.</li>
                <li>You can execute both auto test cases and manual test cases as well as add test result to manual test cases.</li>
                <li>After executing test cases, Testkit-Manager generates a report automatically. After that, you can view, compare, delete, submit, and export the report.</li>
              </ol></td>
          </tr>
        </table>
      </div></td>
    <td width="2%">&nbsp;</td>
  </tr>
  

<tr>
    <td width="2%">&nbsp;</td>
    <td align="left"><div id="building_test_case">
        <table width="100%" border="0" cellspacing="0" cellpadding="0">
          <tr>
            <td class="report_list_one_row help_level_1"><table width="100%" border="0" cellspacing="0" cellpadding="0">
                <tr>
                  <td>Building Test Case</td>
                  <td align="right" class="help_list" style="font-weight:normal">[<a href="#">top</a>]</td>
                </tr>
              </table></td>
          </tr>
          <tr>
            <td>
              <p>To build a test case, perform the following steps: </p>
              <ol>
                <li>\'git clone git\@github.com:testkit/testkit-manager.git\'</li>
                <li>\'cd testkit-manager; ./autogen; ./configure; make; make install\'</li>
                <li>Download WebAPI test suite by git clone ssh://username\@tizendev.org:29418/test/webapi.git.</li>
                <li>Build and install the WebAPI test suite.</li>
                </ol></td>
          </tr>
        </table>
      </div></td>
    <td width="2%">&nbsp;</td>
  </tr>
  
  
  <tr>
    <td width="2%">&nbsp;</td>
    <td align="left"><div id="customzing_tests">
        <table width="100%" border="0" cellspacing="0" cellpadding="0">
          <tr>
            <td class="report_list_one_row help_level_1"><table width="100%" border="0" cellspacing="0" cellpadding="0">
                <tr>
                  <td>Customizing Tests</td>
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
                                <td>Filtering Test Cases</td>
                                <td align="right" class="help_list" style="font-weight:normal">[<a href="#">top</a>]</td>
                              </tr>
                            </table></td>
                        </tr>
                        <tr>
                          <td><p>You can filter test cases according to their property values:</p>
                            <p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.Architecture	2.Version	3.Category	4.Priority	5.Status</p>
                            <p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;6.Execution Type	7.Test suite	8.Type	9.Test set	10.Component</p>
                            <p>To filter test cases, perform the following steps:</p>  
                            <ol>
                              <li>Log in to http://localhost:8899.</li>
                              <li>Click the CUSTOM tab.</li>
                              <p>When the tab page is refreshing, all the buttons are disabled, and the progress bar is displayed on the right top of the tab page, as shown by [1] in Figure 3-1.</p>
                              <img src="images/pic_3_1.png" width="600" height="199" />
                              <p>After the tab page is refreshed, some buttons are enabled, and the progress bar is hidden. The tab page:</p>
                              <ul>
                                  <li>Displays Filter, View, and Update on top, as shown by [1] in Figure 3-2. </li>
                                  <li>Lists installed packages, as shown by [2] in Figure 3-2.</li>
                                  <li>Lists uninstalled or later-version packages which are scanned from repos , as shown by [3] in Figure 3-2.</li>                                  
                              </ul>
                              <img src="images/pic_3_2.png" width="600" height="466" />
                              <li>Click Filter.</li>
                              <p>Options display, as shown by [2] in Figure 3-3. If you click Filter button again, options are hidden.</p>
                              <img src="images/pic_3_3.png" width="600" height="587" />
                              <li>Take the Priority and Execution type options for example.</li>
                              Note: Assume that all the 10 options\' value are initial values \"Any ***\". All the installed test case packages display.
                              <ol>
                                <li>Select P3 from the Priority checkbox.</li>
                                The test case packages display, which include test cases whose priority is P3, as shown in Figure 3-4.
                                <img src="images/pic_3_4.png" width="600" height="563" />
                                <li>Select auto from the Execution type check box. </li>
                                The test case packages display, which include the test cases whose priority is P3 and whose Execution type is auto, as shown in Figure 3-5.
                                <img src="images/pic_3_5.png" width="600" height="565" />
                              </ol>
                              Note: You can select other options in the same way. All the required test case packages display.
                              <li>Select a test case package to test, as shown in Figure 3-6.</li>
                              <img src="images/pic_3_6.png" width="600" height="565" />
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
                                <td>Using Test Plan</td>
                                <td align="right" class="help_list" style="font-weight:normal">[<a href="#">top</a>]</td>
                              </tr>
                            </table></td>
                        </tr>
                        <tr>
                          <td><p>A test plan saves the information of filtered test cases for future test. You can save, load, or manage a test plan.</p>
                            <ol>
                              <li>Saving Test Plan</li>
                              To save a test plan, perform the following steps:
                              <ol>
                                <li>Filter test case packages. For details, see section 3.1.</li>
                                <li>Click Save. </li>
                                <p>Save operations display, as shown by [2] in Figure 3-7. The Save button updates to Close, as shown by [1] in Figure 3-7. If you click Close, the save operations are hidden.</p>
                                <img src="images/pic_3_7.png" width="600" height="635" />
                                <li>Enter the test plan name in text box [1]. Then click Save, as shown by [2] in Figure 3-8.</li>
                                <img src="images/pic_3_8.png" width="600" height="630" />
                                <li>An alert displays, as shown in Figure 3-9. Click OK to save the test plan. </li>
                                <img src="images/pic_3_9.png" width="358" height="116" />
                                <p>After the test plan is saved successfully, the test plan name displays, as shown by [1] in figure 3-10.</p>
                                <img src="images/pic_3_10.png" width="600" height="632" />
                                <li>If there has been a test plan whose name is the same as the entered test plan name, as shown in Figure 3-11: </li>
                                <img src="images/pic_3_11.png" width="600" height="697" />
                                <p>Click Save. A dialog box pops up, reading \"Test plan: &lt;Test plan name input &gt; exists, Are you sure to overwrite it?\"</p>
                                <img src="images/pic_3_12.png" width="354" height="132" />
                                <ul>
                                   <li>Click OK -> The test plan test_plan overwrites the existing one. </li>
                                   <li>Click Cancel -> The test plan test_plan is not saved.</li>
                                </ul>
                                <li>Select a test plan that you want to view, as shown by [1] in Figure 3-13. Then click View, as shown by [2] in Figure 3-13.</li>
                                <img src="images/pic_3_13.png" width="600" height="636" />
                                <li>A popup page displays, as shown in Figure 3-14. </li>
                                <ul>
                                    <li>View test plan name, as shown by [1].</li>
                                    <li>View packages name, as shown by [2].</li>
                                    <li>View the filtered value, as shown by [3]. If the filtered value is "Any ***", it displays as "- -".</li>
                                    <li>Click Close to close the popup page.</li>
                                </ul>
                                <img src="images/pic_3_14.png" width="577" height="391" />
                                <p>Note:</p>
                                <p>Do not leave test plan name blank. If you click Save without entering a test plan name, an alert pops up,  as shown in Figure 3-15. Click OK.</p>
                                <img src="images/pic_3_15.png" width="358" height="178" />
                              </ol>
                              <li>Loading Test Plan</li>
                              <p>To load a test plan, perform the following steps:</p>
                              <ol>
                                  <li>Click Load, as shown in Figure 3-16.</li>
                                  <img src="images/pic_3_16.png" width="600" height="468" />
                                  <li>Load operations display, as shown by [2] in Figure 3-17. The Load button updates to Close, as shown by [1] in Figure 3-17. If you click Close, load operations are hidden. Select a test plan name, and click Load.</li>
                                  <img src="images/pic_3_17.png" width="600" height="491" />
                                  <li>If there are missing packages that need to be installed. The number of missing packages will display on the top , as shown by [1] in Figure 3-18. The number of installing packages will display , as shown by [2]. After finish installing, the results will display, as shown by [3] [4] . If there are packages that fail to be installed, the test plan would not be loaded, and you can click link, as shown by [6] to refresh the page.  If all the packages have been installed successfully, the test plan will be loaded automatically.</li>
                                  <img src="images/pic_3_18.png" width="444" height="354" />
                                  <li>Click the View button to view the test plan, as shown in Figure 3-17. For details, see step 7 in section 3.2.1.</li>
                              </ol>
                              <li>Managing Test Plan</li>
                              <p>To manage a test plan that has been saved, perform the following steps:</p>
                              <ol>
                                  <li>Click Manage, as shown in Figure 3-19.</li>
                                  <img src="images/pic_3_19.png" width="600" height="468" />
                                  <li>Manage operations  display, as shown by [2] in Figure 3-20. The Manage button updates to Close, as shown by [1] in Figure 3-20. If you click the Close button, the manage operations are hidden.</li>
                                  <img src="images/pic_3_20.png" width="600" height="488" />
                                  <li>Select a test plan name, and click the View button. View popup page will display. For details, see step 7 in section 3.2.1.</li>
                                  <li>Select one test plan name, and click the Delete button. An alert pops up, as shown in Figure 3-21. Click OK. The test plan is deleted.</li>
                                  <img src="images/pic_3_21.png" width="358" height="116" />
                              </ol>
                              <li>Executing Test Plan</li>
                              <p>Execute an existing test plan:</p>
                              <ol>
                                <li>
                                  <p>Type the test plan name and click Load.</p>
                                  <p>The test plan is loaded and the page automatically refreshes.</p>
                                </li>
                                <li>
                                  <p>Click Execute. The page refreshes and the test plan is executed.</p>
                                  </li>
                              </ol>
                              <p>Execute a temporary test plan:</p>
                               <ol>
                                <li>
                                  <p>Select a test case package. For details, see section 3.1.  </p>
                                </li>
                                <li>
                                  <p>Click Execute. The page refreshes and the test plan is executed.</p>
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
                              <li>Viewing Test Case Information</li>
                              <p>To view test case information, perform the following steps:</p>
                              <ol>
                                <li>Click view. The page refreshes, as shown in Figure 3-22. Current View method is displayed, as shown by [1] in Figure 3-22. Click List View to view test cases in list view, as shown by [2] in Figure 3-22. </li>
                                <img src="images/pic_3_22.png" width="600" height="525" />
                                <li>Click the Tree View button to view test cases in tree view, as shown by [3] in Figure 3-22. The page refreshes, as shown in Figure 3-23.</li>
                                <img src="images/pic_3_23.png" width="600" height="517" />
                                <li>Click the test case name. The detailed test case information displays in the right pane of the page.</li>
                              </ol>
                              <li>Sorting Test Case Packages</li>
                              <p>Click button with arrow icon. The test case packages are sorted. </p>
                              <p>Note: You can click the arrow icon again. The test case packages are reversely sorted.</p>
                              <p>Figure 3-24 shows the details.</p>
                              <img src="images/pic_3_24.png" width="600" height="469" />
                              <li>Deleting Test Case Package </li>
                              <p>Click the delete icon, as shown in Figure 3-25. </p>
                              <img src="images/pic_3_25.png" width="600" height="469" />
                              <p>A dialog box is displayed, asking for your confirmation. Click OK.</p>
                              <li>Listing Test Case Package Information</li>
                              <p>Click the test case package name. The detailed information displays, as shown in Figure 3-26.</p>
                              <img src="images/pic_3_26.png" width="600" height="624" />
                              <li>Update package list from repo</li>
                              <p>Click Update button ,testkit-manager will scan package list from repo, and list all the packages that not installed , we can click install icon to install these packages. At the same time, if there are newer version for the package which has been installed from repo, the update icon for this package will be enabled.We can click update icon to update this package to the latest  version, as shown in Figure 3-27 and Figure 3-28.</p>
                              <img src="images/pic_3_27.png" width="600" height="467" />
                              <img src="images/pic_3_28.png" width="600" height="469" />
                              <li>Clear all filters and package check box</li>
                              <p>After selecting filters or package check box, the clear button will be enabled, as shown in Figure 3-29.</p>
                              <img src="images/pic_3_29.png" width="600" height="589" />
                              <p>Click Clear button, all filters and package check box will change to init value, as shown in Figure 3-30.</p>
                              <img src="images/pic_3_30.png" width="600" height="587" />
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
    <td align="left"><div id="executing_test_cases">
        <table width="100%" border="0" cellspacing="0" cellpadding="0">
          <tr>
            <td class="report_list_one_row help_level_1"><table width="100%" border="0" cellspacing="0" cellpadding="0">
                <tr>
                  <td>Executing Test Cases</td>
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
                                <td>Executing Auto Test Cases</td>
                                <td align="right" class="help_list" style="font-weight:normal">[<a href="#">top</a>]</td>
                              </tr>
                            </table></td>
                        </tr>
                        <tr>
                          <td><p>You can use either of the following two ways to execute test cases:</p>
                            <ul>
                              <li>Filter test cases or load test plan (with auto test cases), and click Execute on the CUSTOM page.</li>
                              <li>Select a test plan and click Execute on the EXECUTE page.</li>
                            </ul>
                            <p>The test plan runs with log. When the profile finishes running, a test report generates automatically. Click the Stop button to stop executing the test plan.</p>
                              <img src="images/pic_4_1.png" width="600" height="359" />
                          </td>
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
                                <td>Executing Manual Test Cases</td>
                                <td align="right" class="help_list" style="font-weight:normal">[<a href="#">top</a>]</td>
                              </tr>
                            </table></td>
                        </tr>
                        <tr>
                          <td>
                            <ol>
                              <li>When the test plan (with manual test cases) finishes running, the page refreshes, as shown in Figure 4-2. Then, you can add the result of manual test cases:</li>
                              <img src="images/pic_4_2.png" width="600" height="451" />
                              <ul>
                                <li>Click Manual Test. All the manual test cases display on the right pane of the page.</li>
                                <li>Run the test cases manually, obtain the results, and then select Pass, Fail, Block or N/A for the test results.</li>
                                <li>Click Save.</li>
                                <li>Click Finish to complete the execution. </li>
                              </ul>
                              <li>Then, the REPORT page refreshes and displays, as shown in Figure 4-3. Current View method is displayed, as shown by [1] in Figure 4-3. Click Tree  View to view test report in tree view, as shown by [2] in Figure 4-3.</li>
                              <img src="images/pic_4_3.png" width="600" height="656" />
                              <li>View test report in tree view.</li>
                              <img src="images/pic_4_4.png" width="600" height="487" />
                              </ol>
                            </td>
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
    <td align="left"><div id="viewing_report">
        <table width="100%" border="0" cellspacing="0" cellpadding="0">
          <tr>
            <td class="report_list_one_row help_level_1"><table width="100%" border="0" cellspacing="0" cellpadding="0">
                <tr>
                  <td>Viewing Report</td>
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
                                <td>Viewing Summary Reports</td>
                                <td align="right" class="help_list" style="font-weight:normal">[<a href="#">top</a>]</td>
                              </tr>
                            </table></td>
                        </tr>
                        <tr>
                          <td>
                              <p>Click the view icon to view summary reports, as shown in Figure 5-1.</p>
                              <img src="images/pic_5_1.png" width="600" height="146" />
                              <p>You can view summary information, including:</p>
                              <ul>
                                  <li>Test environment</li>
                                  <li>Total number of test cases</li>
                                  <li>Number of passed, failed, and blocked test cases</li>
                                  <li>Test log</li>
                              </ul>
                              <p>You can also click: </p>
                              <ul>
                                <li>button to view detailed reports</li>
                                <li>button to download consolidated log</li>
                                <li>button copy uniform resource locator (URL) to clipboard and paste it anywhere</li>
                              </ul>
                            </td>
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
                                <td>Viewing Test Report in List View</td>
                                <td align="right" class="help_list" style="font-weight:normal">[<a href="#">top</a>]</td>
                              </tr>
                            </table></td>
                        </tr>
                        <tr>
                          <td>
                          <p>After the icon shown by [1] in Figure 5-1 is clicked, the page refreshes, as shown in Figure 5-2.</p>
                          <img src="images/pic_5_2.png" width="600" height="656" />
                          </td>
                        </tr>
                        <tr>
                          <td class="report_list_one_row help_level_2"><table width="100%" border="0" cellspacing="0" cellpadding="0">
                              <tr>
                                <td>Viewing Test Report in Tree View</td>
                                <td align="right" class="help_list" style="font-weight:normal">[<a href="#">top</a>]</td>
                              </tr>
                            </table></td>
                        </tr>
                        <tr>
                          <td>
                          <p>Click the Tree View button in Figure 5-2. The page refreshes, as shown in Figure 5-3.</p>
                          <img src="images/pic_5_3.png" width="600" height="487" />
                          <ol>
                              <li>Select Package from the View by: drop-down list box.</li>
                              <p>Note: You can view the detailed reports by \"Packages\", \"Component\", or \"Test type\". The following steps use \"Packages\" as an example.</p>
                              <img src="images/pic_5_4.png" width="600" height="268" />
                              <li>Filter a test report by selecting Result and Type, by the same way as step 1.</li>
                              <li>Click the test case name to view its detailed information. </li>
                              <img src="images/pic_5_5.png" width="600" height="610" />
                          </ol>
                          </td>
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
                                <td>Useful Features</td>
                                <td align="right" class="help_list" style="font-weight:normal">[<a href="#">top</a>]</td>
                              </tr>
                            </table></td>
                        </tr>
                        <tr>
                          <td><ol>
                              <li>Submitting Report</li>
                              <p>To submit a test report to QA test tools, perform the following steps:</p>
                              <ol>
                                <li>Log in to http://localhost:8899/.</li>
                                <li>Click the REPORT tab. </li>
                                <p>The REPORT tab page displays, as shown in Figure 5-6.</p>
                                <img src="images/pic_5_6.png" width="600" height="176" />
                                <li>Select one or multiple check boxes. </li>
                                <p>The buttons Compare and Delete become available.</p>
                                <li>Click Submit, as shown [1] in Figure 5-7.  </li>
                                <img src="images/pic_5_7.png" width="600" height="174" />
                                <li>The page refreshes, as shown in Figure 5-8.</li>
                                <img src="images/pic_5_8.png" width="600" height="124" />
                                <ol>
                                  <li>Type server name in context Input Server Name. </li>
                                  <li>Type token in context Input Token. </li>
                                  <p>Note: The token is a string which records account and password. You can obtain it after logging in to QA test tools.</p>
                                  <li>Type the report date in context Input Image Date.  </li>
                                  <p>Note: %2E is used to indicate \".\". For example, type 20120319%2E5 for "20120319.5".</p> 
                                  <li>Select values from the target, testtype, and hwproduct combo boxes, as shown in Figure 5-9.</li>
                                  <img src="images/pic_5_9.png" width="600" height="162" />
                                  <li>Click Submit, as shown in Figure 5-10. The report is submitted to the QA test tools.</li>
                                  <img src="images/pic_5_10.png" width="600" height="124" />
                                </ol>
                              </ol>
                              <li>Comparing Reports</li>
                              <p>To compare reports, perform the following steps:</p>
                              <ol>
                                  <li>Select reports, and click the Compare button, as shown in Figure 5-11.</li>
                                  <img src="images/pic_5_11.png" width="600" height="172" />
                                  <li>The page refreshes as shown in Figure 5-12.</li>
                                  <img src="images/pic_5_12.png" width="600" height="463" />
                              </ol>
                              <li>Deleting Report</li>
                              <p>To delete a test report, perform the following steps:</p>
                              <ol>
                                <li>Select one or multiple test reports, as shown in Figure 5-13.</li>
                                <img src="images/pic_5_13.png" width="600" height="175" />
                                <li>Click Delete. An alert pops up, as shown in Figure 5-14.</li>
                                <img src="images/pic_5_14.png" width="359" height="114" />
                                <ul>
                                   <li>Click OK -> The report is deleted.</li>
                                   <li>Click Cancel -> The report is not deleted.</li>
                                </ul>
                              </ol>
                              <li>Complete Report with Manual Test Cases</li>
                              <p>The test case packages include manual test cases whose results need to be submitted to the report manually.</p>
                              <p>As Figure 5-15 tells:</p>
                              <ul>
                                <li>If Manual Status is \"Complete\", the button becomes unavailable with the title "Execution Complete".</li>
                                <li>If Manual Status is "Incomplete",the button becomes available with the title "Continue Execution".</li>
                             </ul>
                             	<img src="images/pic_5_15.png" width="600" height="171" />
                              <ol>
                                <li>Click  . The page refreshes, as shown in Figure 5-16. Then, you can select the result of manual test cases.</li>
                                <img src="images/pic_5_16.png" width="600" height="451" />
                                <p>Caution: Use caution in the following step, for the result cannot be changed after it.</p>
                                <li>Click Finish to refresh the REPORT tab page. The   button becomes unavailable.</li>
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
  <tr>
    <td width="2%">&nbsp;</td>
    <td align="left"><div id="Statistic_tests">
    <table width="100%" border="0" cellspacing="0" cellpadding="0">
          <tr>
            <td class="report_list_one_row help_level_1"><table width="100%" border="0" cellspacing="0" cellpadding="0">
                <tr>
                  <td>Statistic Test Case</td>
                  <td align="right" class="help_list" style="font-weight:normal">[<a href="#">top</a>]</td>
                </tr>
              </table></td>
          </tr>
          <tr>
            <td><table width="100%" border="0" cellspacing="0" cellpadding="0">
                <tr>
                          <td class="report_list_one_row help_level_2"><table width="100%" border="0" cellspacing="0" cellpadding="0">
                              <tr>
                                <td>Viewing results</td>
                                <td align="right" class="help_list" style="font-weight:normal">[<a href="#">top</a>]</td>
                              </tr>
                            </table></td>
                        </tr>
          	</td>
            <td>
               <ol>
                   <li>Click the STATISTIC tab to view statistics by package chart. The page refreshes, as shown in Figure 6-1. The filter function becomes available.</li>
                   <img src="images/pic_6_1.png" width="600" height="259" />
                   <li>Click the icon marked by [2] in Figure 6-1 to view statistic by component chart. The page refreshes, as shown in Figure 6-2. The filter function becomes available.</li>
                   <img src="images/pic_6_2.png" width="600" height="308" />
                   <li>Click the icon marked by [3] in Figure 6-1 to view statistics by spec chart. The page refreshes, as shown in Figure 6-3. The filter function becomes available.</li>
                   <img src="images/pic_6_3.png" width="600" height="326" />
                   <li>Click the spec filter in Figure 6-3 to view statistics by spec chart. The page refreshes, as shown in Figure 6-4 and 6-5. The filter function becomes available.</li>
                   <img src="images/pic_6_4.png" width="600" height="351" />
                   <img src="images/pic_6_5.png" width="600" height="415" />
               </ol>
            </td>
          </tr>
		  <tr>
            <td><table width="100%" border="0" cellspacing="0" cellpadding="0">
                <tr>
                          <td class="report_list_one_row help_level_2"><table width="100%" border="0" cellspacing="0" cellpadding="0">
                              <tr>
                                <td>Viewing cases</td>
                                <td align="right" class="help_list" style="font-weight:normal">[<a href="#">top</a>]</td>
                              </tr>
                            </table></td>
                        </tr>
            </td>
            <td>
               <ol>
                   <li>Click button "cases", as shown by [4] in Figure 6-1. The page refreshes, as shown in Figure 6-1. The filter function becomes available.</li>
                   <img src="images/pic_6_6.png" width="600" height="229" />
                   <li>Click the icon marked by [2] in Figure 6-6 to view statistic by tree diagram. The page refreshes, as shown in Figure 6-7. The filter function becomes available.</li>
                   <img src="images/pic_6_7.png" width="600" height="491" />
                   <li>Click the icon marked by [3] in Figure 6-6 to view statistic by component chart. The page refreshes, as shown in Figure 6-8. The filter function becomes available.</li>
                   <img src="images/pic_6_8.png" width="600" height="272" />
               </ol>
            </td>
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
