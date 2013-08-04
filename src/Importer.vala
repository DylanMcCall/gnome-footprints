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

public errordomain ImportError {
	INVALID_DATA
}

/**
 * An Importer takes some file and, on success, produces an Activity object
 * with data stored locally in a supported format such as GPX.
 */
public abstract class Importer : Object {
	public abstract int64 get_file_activity_id(File file);
	public abstract Activity? import_file(File file) throws ImportError;
}