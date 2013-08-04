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

public class FITImporter : Importer {
	public override int64 get_file_activity_id(File file) {
		return 0;
	}

	public override Activity? import_file(File file) throws ImportError {
		// TODO: Create an Activity with the result
		var activity = new Activity();
		var activity_parser = new ActivityFITParser(activity);
		activity_parser.parse_file(file);
		return activity;
	}
}

class ActivityFITParser : FITParser, Object {
	private unowned Activity activity;

	public ActivityFITParser(Activity activity) {
		this.activity = activity;
	}

	protected void found_file_id(Fit.Message.FileID * file_id) {
		stdout.printf("File ID: type=%u, number=%u\n",
			file_id.type,
			file_id.number
		);
	}

	protected void found_file_creator(Fit.Message.FileCreator * file_creator) {
		stdout.printf("File Creator: software=%u, hardware=%u\n",
			file_creator.software_version,
			file_creator.hardware_version
		);
	}

	protected void found_device_info(Fit.Message.DeviceInfo * device_info) {
		stdout.printf("Device Info: manufacturer=%s, product=%u, software=%u, hardware=%u, serial=%u\n",
			device_info.manufacturer.to_string(),
			device_info.product,
			device_info.software_version,
			device_info.hardware_version,
			device_info.serial_number
		);
	}

	protected void found_activity(Fit.Message.Activity * activity) {
		stdout.printf("Activity: timestamp=%u, type=%s, event=%u, event_type=%s, num_sessions=%u\n",
			activity.timestamp,
			activity.type.to_string(),
			activity.event,
			activity.event_type.to_string(),
			activity.num_sessions
		);
	}

	protected void found_session(Fit.Message.Session * session) {
		stdout.printf("Session: timestamp=%u, start_time=%u, sport=%s, avg_speed=%u\n",
			session.timestamp,
			session.start_time,
			session.sport.to_string(),
			session.avg_speed
		);
	}

	protected void found_lap(Fit.Message.Lap * lap) {
		stdout.printf("Lap: timestamp=%u, lap_trigger=%u, total_distance=%u, avg_speed=%u\n",
			lap.timestamp,
			lap.lap_trigger,
			lap.total_distance,
			lap.avg_speed
		);
	}

	protected void found_record(Fit.Message.Record * record) {
		stdout.printf("Record: timestamp=%u\n",
			record.timestamp
		);
	}

	protected void found_event(Fit.Message.Event * event) {
		stdout.printf("Event: timestamp=%u, event_type=%s\n",
			event.timestamp,
			event.event_type.to_string()
		);
	}
}

interface FITParser : Object {
	protected abstract void found_file_id(Fit.Message.FileID * file_id);
	protected abstract void found_file_creator(Fit.Message.FileCreator * file_creator);
	protected abstract void found_device_info(Fit.Message.DeviceInfo * device_info);
	protected abstract void found_activity(Fit.Message.Activity * activity);
	protected abstract void found_session(Fit.Message.Session * session);
	protected abstract void found_lap(Fit.Message.Lap * lap);
	protected abstract void found_record(Fit.Message.Record * record);
	protected abstract void found_event(Fit.Message.Event * event);

	public void parse_file(File file) throws ImportError {
		Fit.Convert.State convert_state = Fit.Convert.State();
		Fit.Convert.init(ref convert_state, true);

		// FIXME: This should all be freed automatically, but alleyoop says we
		// have memory leaking from here.
		var file_stream = file.read();
		var data_stream = new DataInputStream(file_stream);

		uint8[] buffer = new uint8[8];
		ssize_t buffer_size = 0;
		Fit.Convert.Result convert_result = Fit.Convert.Result.CONTINUE;

		do {
			buffer_size = data_stream.read(buffer);
			do {
				convert_result = Fit.Convert.read(ref convert_state, buffer, (uint32)buffer_size);
				switch (convert_result) {
					case Fit.Convert.Result.MESSAGE_AVAILABLE:
						void * message_data = Fit.Convert.get_message_data(ref convert_state);
						var message_number = Fit.Convert.get_message_number(ref convert_state);
						stdout.printf("Message %d:\t", message_number);

						switch (message_number) {
							case Fit.Message.Number.FILE_ID:
								this.found_file_id((Fit.Message.FileID *)message_data);
								break;

							case Fit.Message.Number.FILE_CREATOR:
								this.found_file_creator((Fit.Message.FileCreator *)message_data);
								break;

							case Fit.Message.Number.DEVICE_INFO:
								this.found_device_info((Fit.Message.DeviceInfo *)message_data);
								break;

							case Fit.Message.Number.ACTIVITY:
								this.found_activity((Fit.Message.Activity *)message_data);
								break;

							case Fit.Message.Number.SESSION:
								this.found_session((Fit.Message.Session *)message_data);
								break;

							case Fit.Message.Number.LAP:
								this.found_lap((Fit.Message.Lap *)message_data);
								break;

							case Fit.Message.Number.RECORD:
								this.found_record((Fit.Message.Record *)message_data);
								break;

							case Fit.Message.Number.EVENT:
								this.found_event((Fit.Message.Event *)message_data);
								break;

							default:
								GLib.debug("Unhandled message type: %d", message_number);
								break;
						}

						// FIXME: free(message_data) causes a very unhappy error.
						// Please make sure there are no problems with not freeing it.

						break;

					default:
						break;
				}
			} while (convert_result == Fit.Convert.Result.MESSAGE_AVAILABLE);
		} while (buffer_size != 0 && convert_result == Fit.Convert.Result.CONTINUE);

		if (convert_result == Fit.Convert.Result.ERROR) {
			throw new ImportError.INVALID_DATA("Error decoding file.");
		}

		if (convert_result == Fit.Convert.Result.PROTOCOL_VERSION_NOT_SUPPORTED) {
			throw new ImportError.INVALID_DATA("Protocol version not supported.");
		}

		if (convert_result == Fit.Convert.Result.CONTINUE) {
			GLib.warning("Unexpected end of file.");
		}

		if (convert_result == Fit.Convert.Result.END_OF_FILE) {
			stdout.printf("File converted successfully! :D\n");
		}
	}
}
