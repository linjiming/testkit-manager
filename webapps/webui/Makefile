#
#
# Copyright (C) 2007, Intel Corporation.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms and conditions of the GNU General Public License,
# version 2, as published by the Free Software Foundation.
#
# This program is distributed in the hope it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 59 Temple
# Place - Suite 330, Boston, MA 02111-1307 USA.
#
# Authors:
#       Wang,Jing  <jing.j.wang@intel.com>
#
# Date Created: 06-12--2007
#

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
