include $(top_srcdir)/base.am

bin_PROGRAMS = \
	fit_example

fit_example_VALASOURCES = \
	FitExample.vala

fit_example_SOURCES = \
	$(fit_example_VALASOURCES)
	sdk/fit.c \
	sdk/fit_convert.c \
	sdk/fit_crc.c \
	sdk/fit_product.c \
	sdk/fit_ram.c \
	FitSDK.vapi

fit_example_VALAFLAGS = $(BASE_VALAFLAGS) \
	--pkg gio-2.0

fit_example_CPPFLAGS = $(AM_CPPFLAGS) \
	$(BASE_CFLAGS)

fit_example_LDADD = $(BASE_LIBS)

junk_files = \
	$(fit_example_VALASOURCES:.vala=.c) \
	libfit_la_vala.stamp

dist-hook:
	cd $(distdir) && rm -f $(junk_files)

CLEANFILES = \
	$(junk_files)

