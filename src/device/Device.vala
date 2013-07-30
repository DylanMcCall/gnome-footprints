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

errordomain DeviceError {
	UNEXPECTED_CONTENT,
	MALFORMED_DATA
}

public abstract class Device : Object {
	public string id {public get; protected set;}
	public string name {public get; protected set;}

	private File local_data;

	public Device() {
	}

	public abstract List<Activity> get_new_activities();
}
