%define _unpackaged_files_terminate_build 0

Summary: Testkit Manager
Name: testkit-manager
Version: 2.2.4
Release: 3
License: GPLv2
Group: System/Libraries
Source: %name-%version.tar.gz
BuildRoot: %_tmppath/%name-%version-buildroot
Requires: perl-libxml-perl perl-App-cpanminus perl-XML-Simple perl-XML-LibXSLT wget

%description
This is testkit manager with WebUI

%prep
%setup -q

%build
./autogen
./configure
make

%install
[ "\$RPM_BUILD_ROOT" != "/" ] && rm -rf "\$RPM_BUILD_ROOT"
make install DESTDIR=$RPM_BUILD_ROOT

%clean
[ "\$RPM_BUILD_ROOT" != "/" ] && rm -rf "\$RPM_BUILD_ROOT"

%files
/opt/testkit/manager

%changelog
* Thu Sep 28 2012 Wendong,Sui <weidongx.sun@intel.com> 2.2.4-3
- add known issues section in README

Thu Sep 25 2012 Wendong,Sui <weidongx.sun@intel.com> 2.2.4-2
- update manual cases' number on manual execution page

Thu Sep 17 2012 Wendong,Sui <weidongx.sun@intel.com> 2.2.4-1
- add 'sudo' for all commands in README
- change xsl files to the latest version
- support new schema of <specs> in tests.xml
- go to List View first, when enter case view page
- leave only useful files in the tar log
- kill all existing widgets before executing tests
- update warning text when losing connection to the device

Thu Sep 7 2012 Wendong,Sui <weidongx.sun@intel.com> 2.2.3-2
- update report page's UI and alien it with case view
- change use XSLT.pm to LibXSLT.pm

Thu Aug 30 2012 Wendong,Sui <weidongx.sun@intel.com> 2.2.3-1
- change pack result to noarch rpm
- add list view for cases
- modify title and UI text
- add support for Block result

Thu Aug 16 2012 Wendong,Sui <weidongx.sun@intel.com> 2.2.2-1
- support run both core and web api test packages in one test run
- remove internal URL from CONF
- change profile to test plan
- remove login region
- rename Custom to Plan
- improve repo format
- fill test plan name into result XML
- restore execution info when return from other pages
- remove shaofeng's email address
- save test plan with both core and webapi packages

Thu Aug 3 2012 Wendong,Sui <weidongx.sun@intel.com> 2.2.1-1
- merging the update and reload function
- support one page 'list view'
- polish UI text
- remove test.result.txt from result folder
- load 'temp_profile' when go back to execute page from other pages

Thu Jul 26 2012 Wendong,Sui <weidongx.sun@intel.com> 2.2.0-3
- disable install an update icon during the installation or updating progress
- add detailed error information during the installation or updating progress
- resize page to 60%
- add support for firefox
- update HELP page

Thu Jul 18 2012 Wendong,Sui <weidongx.sun@intel.com> 2.2.0-2
- support core packages
- move repo from code to a configuration file
- remove package if it's not in the widget list
- add tip for disabled icons

Thu Jul 12 2012 Wendong,Sui <weidongx.sun@intel.com> 2.2.0-1
- provides interface to install testkit-lite before execution
- keep host temporary repo be aligned with target device
- install and update package to target device through sdb
- write manual result back to the XML file, and update tar file before download

Tue Jul 10 2012 Wendong,Sui <weidongx.sun@intel.com> 2.0.0-1
- support testkit-lite 2.2.0-1
- remove Ptyshell from the code tree
- change installation location from device to PC
- redesign communication module to support 'sdb'

Thu Jul 15 2010 Tang, Shao-Feng <shaofeng.tang@intel.com> 0.6.1-1
- tuning the test-case querying performance, to reduce the delay to almost 3 seconds
- resolve the special character issue. In this version, the test cases name can contain some special characters (such as '&', '<', '>').

Tue Jul 20 2010 Tang, Shao-Feng <shaofeng.tang@intel.com> 0.6.1-2
- show the description of test-case in the detail page of test-result.
- show the test cases/sets/suits/packages in 'ASCII' order in the tree, the pages 'view_test', 'select_test' and 'run_manual_test' are involved
- change the source folder from 'manager' to 'webapps'
- remove the percentage related info from the page 'run test'
- fix the issue that 'in profile management tab, select one profile and REMOVE, it will remove 2 profiles which is not expected'
- convert the new line to HTML <BR/> in 'stdout' and 'stderr' on the page 'more detail'
- change the name of button 'RUN TEST' to 'EXECUTE TEST'
- show 'name' as an attribute when showing test cases/sets/suits
- show 'seconds' as the unit of the attribute 'timeout'
- if no manual case is selected, the button 'RUN MANUAL TEST' will not be available
- when the test case is a manual case (manual='true'), the attribute 'timeout' will not be displayed.

Wed Jul 21 2010 Wei, Zhang <wei.z.zhang@intel.com> 1.0.0-1
- for 1.0.0 release