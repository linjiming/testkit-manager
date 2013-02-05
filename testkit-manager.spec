%define _unpackaged_files_terminate_build 0

Summary: Testkit Manager
Name: testkit-manager
Version: 2.3.1
Release: 1
License: GPLv2
Group: System/Libraries
Source: %name-%version.tar.gz
BuildRoot: %_tmppath/%name-%version-buildroot
Requires: perl-libxml-perl perl-App-cpanminus perl-XML-Simple perl-XML-LibXSLT wget

%description
Testkit-Manager, a Graphical User Interface (GUI) front-end in browser, manages auto test cases, execution remotely and provides unified web UI to help manual tests execution.

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
