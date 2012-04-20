%define _unpackaged_files_terminate_build 0 

Summary: Testkit Manager
Name: testkit-manager
Version: 2.0.0
Release: 1
License: GPLv2
Group: System/Libraries
Source: %name-%version.tar.gz
BuildRoot: %_tmppath/%name-%version-buildroot
Requires: testkit-lite perl-XML-SAX perl-XML-Simple perl-JSON perl-Digest-SHA

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
* Thu Jul 15 2010 Tang, Shao-Feng <shaofeng.tang@intel.com> 0.6.1-1 
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