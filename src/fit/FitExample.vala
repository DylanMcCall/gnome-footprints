public void do_conversion(string file_name) {
	//void * convert_state = Fit.create_convert_state();
	Fit.Convert.State convert_state = Fit.Convert.State();
	Fit.Convert.init(ref convert_state, true);

	// FIXME: This should all be freed automatically, but alleyoop says we
	// have memory leaking from here.
	var file = File.new_for_path(file_name);
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
							var file_id = (Fit.Message.FileID *)message_data;
							stdout.printf("File ID: type=%u, number=%u\n",
								file_id.type,
								file_id.number
							);
							break;

						case Fit.Message.Number.FILE_CREATOR:
							var file_creator = (Fit.Message.FileCreator *)message_data;
							stdout.printf("File Creator: software=%u, hardware=%u\n",
								file_creator.software_version,
								file_creator.hardware_version
							);
							break;

						case Fit.Message.Number.DEVICE_INFO:
							var device_info = (Fit.Message.DeviceInfo *)message_data;
							stdout.printf("Device Info: software=%u, hardware=%u, serial=%u\n",
								device_info.software_version,
								device_info.hardware_version,
								device_info.serial_number
							);
							break;

						case Fit.Message.Number.ACTIVITY:
							var activity = (Fit.Message.Activity *)message_data;
							stdout.printf("Activity: timestamp=%u, type=%s, event=%u, event_type=%s, num_sessions=%u\n",
								activity.timestamp,
								activity.type.to_string(),
								activity.event,
								activity.event_type.to_string(),
								activity.num_sessions
							);
							break;

						case Fit.Message.Number.SESSION:
							var session = (Fit.Message.Session *)message_data;
							stdout.printf("Session: timestamp=%u, start_time=%u, sport=%s, avg_speed=%u\n",
								session.timestamp,
								session.start_time,
								session.sport.to_string(),
								session.avg_speed
							);
							break;

						case Fit.Message.Number.LAP:
							var lap = (Fit.Message.Lap *)message_data;
							stdout.printf("Lap: timestamp=%u, lap_trigger=%u, total_distance=%u, avg_speed=%u\n",
								lap.timestamp,
								lap.lap_trigger,
								lap.total_distance,
								lap.avg_speed
							);
							break;

						case Fit.Message.Number.RECORD:
							var record = (Fit.Message.Record *)message_data;
							stdout.printf("Record: timestamp=%u\n",
								record.timestamp
							);
							break;

						case Fit.Message.Number.EVENT:
							var event = (Fit.Message.Event *)message_data;
							stdout.printf("Event: timestamp=%u, event_type=%s\n",
								event.timestamp,
								event.event_type.to_string()
							);
							break;

						default:
							GLib.debug("Unhandled message type: %d", message_number);
							break;
					}

					break;

				default:
					break;
			}
		} while (convert_result == Fit.Convert.Result.MESSAGE_AVAILABLE);
	} while (buffer_size != 0 && convert_result == Fit.Convert.Result.CONTINUE);

	if (convert_result == Fit.Convert.Result.ERROR) {
		stdout.printf("Error decoding file.\n");
	}

	if (convert_result == Fit.Convert.Result.CONTINUE) {
		stdout.printf("Unexpected end of file.\n");
	}

	if (convert_result == Fit.Convert.Result.PROTOCOL_VERSION_NOT_SUPPORTED) {
		stdout.printf("Protocol version not supported.\n");
	}

	if (convert_result == Fit.Convert.Result.END_OF_FILE) {
		stdout.printf("File converted successfully.\n");
	}
}

public int main(string[] args) {
	string file_name = args[1];
	if (file_name != null) {
		stdout.printf("Testing file conversion with %s\n", file_name);
	} else {
		stdout.printf("Please run with %s FILE_TO_CONVERT\n", args[0]);
		return 1;
	}
	do_conversion(file_name);
	return 0;
}
