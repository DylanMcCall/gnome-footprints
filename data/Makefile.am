@INTLTOOL_XML_NOMERGE_RULE@
@INTLTOOL_DESKTOP_RULE@
@GSETTINGS_RULES@

SUBDIRS = mime

gsettings_SCHEMAS = 

desktopdir = $(datadir)/applications
desktop_DATA = footprints.desktop

autostartdir = $(sysconfdir)/xdg/autostart
autostart_DATA = 

check: $(desktop_DATA) $(autostart_DATA)
	@for desktop in $(desktop_DATA); do \
		desktop-file-validate $${desktop} || exit 1; \
	done

EXTRA_DIST= \
    footprints.desktop \
    $(gsettingsschema_in_files) \
    $(service_in_files) \
    $(desktop_in_files)

CLEANFILES = \
    $(gsettings_SCHEMAS) \
    $(desktop_DATA) \
    $(autostart_DATA)
