#
#  Makefile for lumail, the console mail client.  Further details online
# at http://lumail.org/
#



#
#  Only used to build distribution tarballs.
#
TMP?=/tmp
BASE        = lumail
DIST_PREFIX = ${TMP}
VERSION     = $(shell sh -c 'git describe --abbrev=0 --tags | tr -d "release-"')


#
#  Source objects.
#
SRCS= bindings.cc debug.cc file.cc global.cc history.cc input.cc lua.cc maildir.cc message.cc main.cc screen.cc variables.cc
OBJS=$(subst .cc,.o,$(SRCS))
TARGET=lumail


#
#  The version of Lua we're building against.
#  Valid options are "lua5.1" & "lua5.2".
#
LVER=lua5.1


#
# NOTE: We use "-std=gnu++0x" so we can use "unordered_map", which is in the STL.
#
#
CPPFLAGS+=-std=gnu++0x -g -Wall -Werror $(shell pkg-config --cflags ${LVER}) $(shell pcre-config --cflags) -O2 -I/usr/include/ncursesw/
LDLIBS+=$(shell pkg-config --libs ${LVER}) -lncursesw  -lmimetic -lpcre -lpcrecpp


#
# Default target.
#
all: $(TARGET)


#
# Debug target.
#
lumail-debug: CXX += -DLUMAIL_DEBUG=1
lumail-debug: CPPFLAGS += -DLUMAIL_DEBUG=1 -ggdb
lumail-debug: TARGET=lumail-debug
lumail-debug: $(TARGET)


#
#  Build the target
#
$(TARGET): $(OBJS)
	$(CXX) $(CPPFLAGS) $(LDFLAGS) -o $(TARGET) $(OBJS) $(LDLIBS)


#
#  Dependency generation.
#
depend: .depend

.depend: $(SRCS)
	rm -f ./.depend
	$(CXX) $(CPPFLAGS) $(LDLIBS) -MM $^>>./.depend;


#
# Cleanup
#
clean:
	$(RM) $(TARGET) lumail-debug $(OBJS) core || true
	cd ./util  && make clean || true

#
# Cleanup, even more.
#
dist-clean: clean
	$(RM) *~ .dependtool


#
#  Install to /usr/local.
#
install: all
	if [ -e /etc/lumail.lua ]; then mv /etc/lumail.lua /etc/lumail.lua.old ; fi
	cp ./lumail.lua /etc/lumail.lua
	cp ./lumail /usr/local/bin


#
#  Make a release tarball
#
release: clean style
	rm -rf $(DIST_PREFIX)/$(BASE)-$(VERSION)
	rm -f $(DIST_PREFIX)/$(BASE)-$(VERSION).tar.gz
	cp -R . $(DIST_PREFIX)/$(BASE)-$(VERSION)
	rm -rf $(DIST_PREFIX)/$(BASE)-$(VERSION)/debian
	rm -rf $(DIST_PREFIX)/$(BASE)-$(VERSION)/.git*
	rm -rf $(DIST_PREFIX)/$(BASE)-$(VERSION)/.depend || true
	perl -pi -e "s/__UNRELEASED__/$(VERSION)/g" $(DIST_PREFIX)/$(BASE)-$(VERSION)/version.h
	cd $(DIST_PREFIX) && tar -cvf $(DIST_PREFIX)/$(BASE)-$(VERSION).tar $(BASE)-$(VERSION)/
	gzip $(DIST_PREFIX)/$(BASE)-$(VERSION).tar
	mv $(DIST_PREFIX)/$(BASE)-$(VERSION).tar.gz .
	rm -rf $(DIST_PREFIX)/$(BASE)-$(VERSION)


#
# Build any utilities.
#
utilities:
	cd ./util && make


#
# Style-checks on the source-code.
#
.PHONY: style
style:
	prove --shuffle ./style/


include .depend
