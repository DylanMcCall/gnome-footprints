SUBDIRS = \
	data \
	fit \
	src \
	po

ACLOCAL_AMFLAGS = -I m4

INTLTOOL_FILES = intltool-extract.in \
                 intltool-merge.in \
                 intltool-update.in

Footprintsdocdir = ${prefix}/doc/Footprints
Footprintsdoc_DATA = \
	README \
	COPYING \
	AUTHORS

EXTRA_DIST = \
	autogen.sh \
	$(BrainBreakdoc_DATA) \
	intltool-extract.in \
	intltool-merge.in \
	intltool-update.in

DISTCLEANFILES = \
	intltool-extract \
	intltool-merge \
	intltool-update \
	po/.intltool-merge-cache
