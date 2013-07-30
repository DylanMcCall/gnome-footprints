include $(top_srcdir)/base.am

SUBDIRS = fit

bin_PROGRAMS = \
	footprints

footprints_SOURCES = \
	footprints.vala \
	device/Device.vala \
	device/GarminDevice.vala

footprints_VALAFLAGS = $(BASE_VALAFLAGS) \
	--pkg gtk+-3.0 \
	--pkg gee-1.0 \
	--pkg gio-2.0 \
	--pkg clutter-1.0 \
	--pkg clutter-gtk-1.0 \
	--pkg champlain-0.12 \
	--pkg champlain-gtk-0.12 \
	--pkg libxml-2.0 \
	$(top_builddir)/libgd/gd-1.0.vapi

footprints_CPPFLAGS = $(AM_CPPFLAGS)

footprints_LDADD = $(BASE_LIBS) \
	$(top_builddir)/libgd/libgd.la

junk_files = \
	$(footprints_SOURCES:.vala=.c) \
	footprints_vala.stamp

dist-hook:
	cd $(distdir) && rm -f $(junk_files)

CLEANFILES = \
	$(junk_files)

