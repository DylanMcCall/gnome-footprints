/*
 * This file is part of "Footprints" GPS Track Manager.
 * 
 * Footprints is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * Footprints is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with Footprints.  If not, see <http://www.gnu.org/licenses/>.
 */

// Okay, we're going to use GVolumeMonitor and GMount
// ...watch for a mount that matches content type x-content/gps-garmin
// ...or skip ahead (if we've been launched with a path to a folder already)
// ...and then read garmin/GarminDevice.xml for all sorts of information!
// ...and then parse the .fit files and stuff :)

public class Application : Gtk.Application {
	const string app_id = "com.dylanmccall.footprints";
	const string app_name = _("Footprints GPS Track Manager");

	public Database database {public get; private set;}
	private VolumeMonitor volume_monitor;
	
	public Application() {
		Object(application_id: app_id, flags: ApplicationFlags.FLAGS_NONE);
		GLib.Environment.set_application_name(app_name);
	}

	private void populate_actions() {
		SimpleAction about_action = new SimpleAction("about", null);
		this.add_action(about_action);
		about_action.activate.connect(this.on_about_activate_cb);

		SimpleAction quit_action = new SimpleAction("quit", null);
		this.add_action(quit_action);
		quit_action.activate.connect(this.quit);

		Menu app_menu = new Menu();
		app_menu.append(_("About"), "app.about");
		app_menu.append(_("Quit"), "app.quit");
		this.set_app_menu(app_menu);
	}
	
	public override void activate() {
		base.activate();
	}
	
	public override void startup() {
		base.startup();

		this.populate_actions();

		this.database = new Database();

		this.volume_monitor = GLib.VolumeMonitor.get();
		this.volume_monitor.mount_added.connect((monitor, mount) => {
			this.handle_device_mount(mount);
		});
		foreach (Mount mount in this.volume_monitor.get_mounts()) {
			this.handle_device_mount(mount);
		}

		MainWindow window = new MainWindow(this);
		window.show_all();
		this.add_window(window);
	}

	private void handle_device_mount(Mount mount) {
		stdout.printf (" * %s\n", mount.get_name());
		mount.guess_content_type.begin(false, null, (obj, res) => {
			string[] content_types = mount.guess_content_type.end(res);
			if ("x-content/gps-garmin" in content_types) {
				try {
					Device device = new GarminDevice(mount.get_root());
					stdout.printf("\tDetected Garmin device\n");
				} catch (DeviceError device_error) {
					warning("DeviceError: %s", device_error.message);
				}
			}
		});
	}

	private void on_about_activate_cb() {

	}
}

public class Database : Object {
	private File device_data;
	private File activities;

	public Database() {
		File user_data = File.new_for_path(Environment.get_user_data_dir());
		File application_data = user_data.get_child("footprints");

		this.device_data = this.make_child_directory(application_data, "devices");
		this.activities = this.make_child_directory(application_data, "activities");
	}

	/**
	 * Helper function to proactively make a directory inside another one
	 */
	private File make_child_directory(File parent, string child_name) {
		File child_dir = parent.get_child(child_name);
		if (! child_dir.query_exists()) {
			child_dir.make_directory_with_parents();
		}
		return child_dir;
	}

	public File get_data_for_device(Device device) {
		return this.make_child_directory(this.device_data, device.id);
	}
}

public class Activity : Object {
	public string id {public get; private set;}
	public Device origin;
}

public class MainWindow : Gtk.ApplicationWindow {
	private SimpleAction import_device_action;
	private SimpleAction import_file_action;
	private SimpleAction map_type_action;
	private SimpleAction recent_tracks_action;

	private Champlain.View map_view;

	public MainWindow(Application app) {
		Object(application: app);

		this.populate_actions();

		this.set_size_request(900,650);
		this.set_title(_("GPS Tracks"));
		this.hide_titlebar_when_maximized = true;

		var wrapper = new Gtk.Grid();
		this.add(wrapper);
		wrapper.set_orientation(Gtk.Orientation.VERTICAL);

		var header = new Header();
		wrapper.add(header);
		header.set_hexpand(true);

		var stack = new Gd.Stack();
		wrapper.add(stack);
		header.set_stack(stack);

		var activities_wrapper = new Gtk.Paned(Gtk.Orientation.HORIZONTAL);
		stack.add_titled(activities_wrapper, "activities", _("Activities"));

		var activity_selector = new ActivitySelector();
		activities_wrapper.add1(activity_selector);

		var current_activity_wrapper = new Gtk.Grid();
		activities_wrapper.add2(current_activity_wrapper);
		current_activity_wrapper.set_orientation(Gtk.Orientation.VERTICAL);

		var activity_map = new GtkChamplain.Embed();
		current_activity_wrapper.add(activity_map);
		this.map_view = activity_map.get_view();
		this.map_view.set_zoom_level(14);
		// TODO: Calculate the center of the currently visible activity
		this.map_view.center_on(49.251, -123.112);
		this.set_map_type("street");

		var activity_details = new Gtk.Grid();
		current_activity_wrapper.add(activity_details);

		var details_label = new Gtk.Label("Hello, world!");
		activity_details.attach(details_label, 0, 0, 1, 1);

		var reports_wrapper = new Gtk.Grid();
		stack.add_titled(reports_wrapper, "reports", _("Reports"));
	}

	private void populate_actions() {
		this.import_device_action = new SimpleAction("import-device", VariantType.STRING);
		this.add_action(import_device_action);
		this.import_device_action.activate.connect(this.on_import_device_cb);

		this.import_file_action = new SimpleAction("import-file", null);
		this.add_action(import_file_action);
		this.import_file_action.activate.connect(this.on_import_file_cb);

		this.map_type_action = new SimpleAction.stateful("map", VariantType.STRING, "street");
		this.add_action(this.map_type_action);
		this.map_type_action.activate.connect(this.on_map_activate_cb);

		this.recent_tracks_action = new SimpleAction.stateful("recent-tracks", null, new Variant.boolean(true));
		this.add_action(this.recent_tracks_action);
		this.recent_tracks_action.activate.connect(this.on_recent_tracks_activate_cb);
	}

	private void on_import_device_cb(Variant? value) {
		string device_path = (string)value;
		stdout.printf("Import from device: %s\n", device_path);
	}

	private void on_import_file_cb(Variant? value) {
		stdout.printf("Import from file\n");
	}

	private void set_map_type(string map_type) {
		this.map_type_action.set_state(map_type);
		
		var map_source_factory = Champlain.MapSourceFactory.dup_default();
		string previous_source_id = this.map_view.get_map_source().get_id();
		string source_id;
		switch (map_type) {
		case "street":
			source_id = Champlain.MAP_SOURCE_OSM_MAPQUEST;
			break;
		case "trails":
			source_id = Champlain.MAP_SOURCE_OSM_CYCLE_MAP;
			break;
		default:
			source_id = Champlain.MAP_SOURCE_OSM_MAPNIK;
			break;
		}
		if (source_id != previous_source_id) {
			var map_source = map_source_factory.create_cached_source(source_id);
			this.map_view.set_map_source(map_source);
		}
	}

	private void on_map_activate_cb(SimpleAction action, Variant? value) {
		string map_type = (string)value;
		stdout.printf("Map type: %s\n", map_type);
		this.set_map_type(map_type);
	}

	private void on_recent_tracks_activate_cb(Variant? value) {
		bool show_tracks = ! (bool)this.recent_tracks_action.get_state();
		this.recent_tracks_action.set_state(show_tracks);
		if (show_tracks) {
			stdout.printf("Show recent tracks\n");
		} else {
			stdout.printf("Don't show recent tracks\n");
		}
	}
}

// TODO: Port this to GtkHeaderBar, asap!
public class Header : Gd.HeaderBar {
	private Gtk.MenuButton import_menubutton;
	private Gd.StackSwitcher stack_switcher;
	private Gtk.MenuButton options_menubutton;

	public Header() {
		Object();

		this.import_menubutton = new Gtk.MenuButton();
		this.pack_start(this.import_menubutton);
		this.import_menubutton.set_image(
			new Gtk.Image.from_icon_name("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
		this.import_menubutton.set_label(_("Add"));
		this.import_menubutton.set_always_show_image(true);

		this.stack_switcher = new Gd.StackSwitcher();
		this.set_custom_title(this.stack_switcher);

		this.options_menubutton = new Gtk.MenuButton();
		this.pack_end(this.options_menubutton);
		this.options_menubutton.set_image(
			new Gtk.Image.from_icon_name("emblem-system-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
		this.options_menubutton.set_tooltip_text(_("Options"));
		this.options_menubutton.set_halign(Gtk.Align.END);

		Menu import_menu = this.build_import_menu();
		this.import_menubutton.set_menu_model(import_menu);

		Menu options_menu = this.build_options_menu();
		this.options_menubutton.set_menu_model(options_menu);
	}

	public void set_stack(Gd.Stack stack) {
		this.stack_switcher.set_stack(stack);
	}

	private Menu build_import_menu() {
		Menu import_menu = new Menu();

		var source_section = new Menu();
		source_section.append(_("From Garmin Forerunner 10"), "win.import-device::garmin-forerunner-10");
		source_section.append(_("GPS track file"), "win.import-file");
		import_menu.append_section(null, source_section);

		return import_menu;
	}

	private Menu build_options_menu() {
		Menu options_menu = new Menu();

		/* FIXME: For some reason a menu item is deselected if it is selected and then clicked again.
		 * To make things weirder, that does not reflect the state, which stays where it was. */
		var map_type_section = new Menu();
		map_type_section.append(_("Street Map"), "win.map::street");
		map_type_section.append(_("Trail Map"), "win.map::trails");
		// map_type_section.append(_("Satellite Map"), "win.map::satellite");
		options_menu.append_section(null, map_type_section);

		var map_extra_section = new Menu();
		map_extra_section.append(_("Show Recent Tracks"), "win.recent-tracks");
		options_menu.append_section(null, map_extra_section);

		return options_menu;
	}
}

public class ActivitySelector : Gtk.Box {
	public ActivitySelector() {
		Object(orientation: Gtk.Orientation.VERTICAL);

		this.get_style_context().add_class(Gtk.STYLE_CLASS_SIDEBAR);

		var sidebar_scroll = new Gtk.ScrolledWindow(null, null);
		this.add(sidebar_scroll);
		sidebar_scroll.set_vexpand(true);
	}
}

public int main(string[] args) {
	Gtk.init(ref args);
	GtkClutter.init(ref args);

	Xml.Parser.init();

	Application application = new Application();
	return application.run(args);
}
