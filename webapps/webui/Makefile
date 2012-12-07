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

#<variables settings>
FILES = dc-server.conf.default  dc-server.pl  mime.types  public_html
SUBDIRS=$(shell ls -Q)

# mandatory targets
all: build

build:
	for n in $(SUBDIRS); do \
		if [ -d $$n -a -f $$n/Makefile ]; then \
			$(MAKE) -C $$n || exit 1; \
		fi; \
	done

install:
	echo "Installing" 
	INSTALL_DIR=$(DESTDIR)/opt/testkit/manager/webapps/webui;\
	mkdir -p $$INSTALL_DIR;\
	cp -a $(FILES) $$INSTALL_DIR

	for n in $(SUBDIRS); do \
	if [ -d $$n -a -f $$n/Makefile ]; then \
		$(MAKE) -C $$n install || exit 1; \
	fi; \
	done

uninstall:
	for n in $(SUBDIRS); do \
		if [ -d $$n -a -f $$n/Makefile ]; then \
			$(MAKE) -C $$n uninstall || exit 1; \
		fi; \
	done

clean:
	for n in $(SUBDIRS); do \
		if [ -d $$n -a -f $$n/Makefile ]; then \
			$(MAKE) -C $$n clean || exit 1; \
		fi; \
	done
