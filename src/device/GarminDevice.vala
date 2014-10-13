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

public class GarminDevice : Device {
	private DeviceInfo device_info {protected get; private set;}

	public GarminDevice(File root) throws DeviceError {
		File garmin_dir = root.get_child("GARMIN");
		File device_info_file = garmin_dir.get_child("GarminDevice.xml");

		this.device_info = new DeviceInfo(device_info_file);

		stdout.printf("Found '%s' device with ID '%s'\n",
			this.device_info.model.description,
			this.device_info.device_id);

		foreach (DeviceDataType data_type in this.device_info.data_types) {
			if (data_type.name == "FIT_TYPE_29") {
				foreach (DeviceDataFile data_file in data_type.data_files) {
					if (data_file.transfer_direction == "OutputFromUnit" || data_file.transfer_direction == "InputOutput") {
						print("Activities are stored in %s\n", data_file.path);
					}
				}
			}
		}

		// TODO: Parse device_info to find where activity data is stored
		File device_activities = garmin_dir.get_child("ACTIVITY");
	}

	// It is tempting to grab all the new activities and put them on the local filesystem
	// right away. However, that has some hairy corner cases (malformed data? flawed device
	// detection, leading us to a 10GB file?). So, we'll wait for the user to tell us :)

	public override List<Activity> get_new_activities() {
		return new List<Activity>();
	}
}

private class DeviceInfo : Object {
	public string? device_id;
	public DeviceModel? model;
	public List<DeviceDataType> data_types;

	public DeviceInfo(File info_file) throws DeviceError {
		this.data_types = new List<DeviceDataType>();

		string? info_path = info_file.get_path();
		if (info_path == null || ! info_file.query_exists()) {
			throw new DeviceError.UNEXPECTED_CONTENT("Missing GarminDevice.xml");
		}

		this.parse_info_file(info_path);
	}

	private void parse_info_file(string path) throws DeviceError {
		Xml.Doc* info_xmldoc = Xml.Parser.parse_file(path);

		if (info_xmldoc == null) {
			throw new DeviceError.UNEXPECTED_CONTENT("Missing or invalid file '%s'", path);
		}

		// Get the root node. notice the dereferencing operator -> instead of .
		Xml.Node* root = info_xmldoc->get_root_element();

		if (root == null) {
			delete info_xmldoc;
			throw new DeviceError.MALFORMED_DATA("The file ('%s') does not contain a root node", path);
		} else {
			this.parse_node(root);
		}

		delete info_xmldoc;

		if (this.device_id == null || this.model == null) {
			throw new DeviceError.MALFORMED_DATA("Device info file ('%s') is incomplete", path);
		}
	}

	private void parse_node(Xml.Node* node) {
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			string node_name = iter->name;
			string node_content = iter->get_content();

			switch (node_name) {
			case "Model":
				this.model = new DeviceModel.from_xml_node(iter);
				break;
			case "DataType":
				DeviceDataType data_type = new DeviceDataType.from_xml_node(iter);
				this.data_types.append(data_type);
				break;
			case "Id":
				this.device_id = node_content;
				break;
			default:
				// parse any remaining child nodes
				this.parse_node(iter);
				break;
			}
		}
	}
}

private class DeviceModel : Object {
	public string? part_number;
	public string? software_version;
	public string? description;

	public DeviceModel.from_xml_node(Xml.Node* node) {
		this.parse_node(node);
		if (this.description == null) {
			this.description = _("Unknown Garmin device");
		}
	}

	private void parse_node(Xml.Node* node) {
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			string node_name = iter->name;
			string node_content = iter->get_content();

			switch (node_name) {
			case "PartNumber":
				this.part_number = node_content;
				break;
			case "SoftwareVersion":
				this.software_version = node_content;
				break;
			case "Description":
				this.description = node_content;
				break;
			default:
				warning("Encountered unknown DeviceInfo node: %s", node_name);
				break;
			}
		}
	}
}

private class DeviceDataType : Object {
	public string? name;
	public List<DeviceDataFile> data_files;

	public DeviceDataType() {
		this.data_files = new List<DeviceDataFile>();
	}

	public DeviceDataType.from_xml_node(Xml.Node* node) {
		this();
		this.parse_node(node);
	}

	private void parse_node(Xml.Node* node) {
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			string node_name = iter->name;
			string node_content = iter->get_content();

			switch (node_name) {
			case "Name":
				this.name = node_content;
				break;
			case "File":
				DeviceDataFile data_file = new DeviceDataFile.from_xml_node(this, iter);
				this.data_files.append(data_file);
				break;
			default:
				warning("Encountered unknown DeviceInfo node: %s", node_name);
				break;
			}
		}
	}
}

private class DeviceDataFile : Object {
	public DeviceDataType type;
	public string? specification_id;
	public string? transfer_direction;
	public string? path;
	public string? base_name;
	public string? file_extension;

	public DeviceDataFile(DeviceDataType type) {
		this.type = type;
	}

	public DeviceDataFile.from_xml_node(DeviceDataType type, Xml.Node* node) {
		this(type);
		this.parse_node(node);
	}

	private void parse_node(Xml.Node* node) {
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			string node_name = iter->name;
			string node_content = iter->get_content();

			switch (node_name) {
			case "Specification":
				this.parse_specification_node(iter);
				break;
			case "Location":
				// we assume there is only a single location node
				// this appears to be the case for the Garmin Forerunner 10,
				// but it probably is not always true
				this.parse_location_node(iter);
				break;
			case "TransferDirection":
				this.transfer_direction = node_content;
				break;
			default:
				warning("Encountered unknown DeviceInfo node: %s", node_name);
				break;
			}
		}
	}

	private void parse_specification_node(Xml.Node* node) {
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			string node_name = iter->name;
			string node_content = iter->get_content();

			switch (node_name) {
			case "Identifier":
				this.specification_id = node_content;
				break;
			default:
				warning("Encountered unknown DeviceInfo node: %s", node_name);
				break;
			}
		}
	}

	private void parse_location_node(Xml.Node* node) {
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			string node_name = iter->name;
			string node_content = iter->get_content();

			switch (node_name) {
			case "Path":
				this.path = node_content;
				break;
			case "BaseName":
				this.base_name = node_content;
				break;
			case "FileExtension":
				this.file_extension = node_content;
				break;
			default:
				warning("Encountered unknown DeviceInfo node: %s", node_name);
				break;
			}
		}
	}
}
