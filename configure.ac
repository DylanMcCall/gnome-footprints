AC_INIT([footprints],
	[1.0],
	[],
	[FOOTPRINTS],
	[])
AC_CONFIG_MACRO_DIR([m4])
AM_INIT_AUTOMAKE([1.11 no-dist-gzip dist-xz foreign])
LT_INIT
AM_MAINTAINER_MODE
AC_CONFIG_HEADERS([config.h])

AC_PATH_PROG(VALAC, valac, valac)
AC_SUBST(VALAC)

IT_PROG_INTLTOOL(0.40)
AM_GNU_GETTEXT([external])
AM_GNU_GETTEXT_VERSION([0.17])
GETTEXT_PACKAGE=AC_PACKAGE_NAME
AC_SUBST([GETTEXT_PACKAGE])
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE,"$GETTEXT_PACKAGE",[The name of the gettext domain])

GLIB_GSETTINGS

AC_SUBST(CFLAGS)
AC_SUBST(CPPFLAGS)
AC_SUBST(LDFLAGS)

GLIB_REQUIRED=2.32.0
GTK_REQUIRED=3.4.0

PKG_CHECK_MODULES([BASE], [
	clutter-1.0 >= 1.14.4
	clutter-gtk-1.0 >= 1.4.2
	champlain-0.12 >= 0.12.3
	champlain-gtk-0.12 >= 0.12.3
	gee-1.0 >= 0.6.2
	gio-2.0 >= 2.30.0
	glib-2.0 >= $GLIB_REQUIRED
	gobject-2.0 >= $GLIB_REQUIRED
	gtk+-3.0 >= $GTK_REQUIRED
	libcanberra >= 0.28
	libnotify >= 0.4.5
	libxml-2.0 >= 2.9.0
])

LIBGD_INIT([header-bar stack revealer vapi])

AC_CONFIG_FILES([Makefile
	libgd/Makefile
	data/Makefile
	data/mime/Makefile
	src/Makefile
	src/fit/Makefile
	po/Makefile.in])

AC_OUTPUT
