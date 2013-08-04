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

public class Activity : Object {
	public uint64 id {public get; public set;}
	public Device origin {public get; public set;}
	private List<TrackPoint> points;

	public Activity() {
		this.points = new List<TrackPoint>();
	}

	public void append_point(TrackPoint point) {
		// TODO: Record an error if this point has a timestamp smaller than the previous
		this.points.append(point);
	}
}

public class TrackPoint {
	public int64 timestamp;
	public double latitude;
	public double longitude;
	public double elevation;
	public double? distance;
	public double? speed;
}
