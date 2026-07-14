#!/usr/bin/env python3
"""
🚌 NMMT Bus 76 — Live Location Tracker
=======================================
Tracks NMMT Route 76 buses in Navi Mumbai (Panvel-Karanjade / Asudgaon-Panvel).

Usage:
  python3 bus76_tracker.py                   # Auto-detect & track active 76 buses
  python3 bus76_tracker.py --list-routes      # List all Route 76 variants
  python3 bus76_tracker.py --route 5692       # Track a specific route by RouteId
  python3 bus76_tracker.py --all              # Check ALL Route 76 variants
  python3 bus76_tracker.py --poll 5           # Keep polling every 5 seconds
"""

import sys
import json
import re
import time
import urllib.request
import urllib.parse

BASE_URL = "https://nmmtservice.infinium.management/TransistService.asmx"
HEADERS = {"User-Agent": "Mozilla/5.0 (Linux; Android 13; Pixel 7)"}

# ─── Route 76 Known Variants ───────────────────────────────────────────────
ROUTE_76_VARIANTS = {
    5692: "076 - Panvel Rly. Stn.(W) → Karanjade Sector 6 (Non AC)",
    5693: "076 - Karanjade Sector 6 → Panvel Rly. Stn.(W) (Non AC)",
    6375: "076 - Asudgaon Depot → Panvel Rly. Stn.(W) (Non AC)",
    6376: "076 - Panvel Rly. Stn.(W) → Asudgaon Depot (Non AC)",
    9716: "076 AC - Karanjade Sector 6 → Panvel Rly. Stn.(W) (AC)",
    9715: "076 AC - Panvel Rly. Stn.(W) → Karanjade Sector 6 (AC)",
}


# ─── API Helpers ───────────────────────────────────────────────────────────

def http_get(method, query_params=None):
    """Simple HTTP GET to the ASMX endpoint."""
    url = f"{BASE_URL}/{method}"
    if query_params:
        url += "?" + urllib.parse.urlencode(query_params)
    try:
        with urllib.request.urlopen(
            urllib.request.Request(url, headers=HEADERS), timeout=15
        ) as resp:
            content = resp.read().decode("utf-8")
        if not content:
            return None
        match = re.search(r"<string[^>]*>(.*?)</string>", content, re.DOTALL)
        if match:
            result = match.group(1)
            # Empty JSON array or object is valid
            if result.strip():
                return json.loads(result)
            return None
        return None
    except Exception as e:
        return {"error": str(e)}


def check_server(retries=3, delay=2, timeout=20):
    """Check if the NMMT API server is responding. Retries on failure."""
    for attempt in range(1, retries + 1):
        try:
            req = urllib.request.Request(
                f"{BASE_URL}/GetRouteList",
                headers=HEADERS,
            )
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                content = resp.read().decode("utf-8")
                if "<string" in content:
                    return True
                return False  # Got response but unexpected format
        except Exception as e:
            if attempt < retries:
                print(f"  ⚡ Server check attempt {attempt}/{retries} failed — retrying in {delay}s...")
                time.sleep(delay)
            else:
                return False
    return False


def get_stations(route_id):
    """Get all stations/stops for a route."""
    result = http_get("GetStationsFromRoute", {"routeid": route_id})
    if isinstance(result, dict) and "error" in result:
        return None  # Server error — not station data
    if isinstance(result, list):
        return result
    return None


def get_schedule(route_id, station_id=2776):
    """Get the schedule for a route."""
    result = http_get("GetBusScheduleForRoute", {"RouteId": route_id, "StationID": station_id})
    if isinstance(result, dict) and "error" in result:
        return None
    return result


def find_active_buses(route_id, station_id, schedule_time):
    """Find active buses on a route at a given station/time. (Direct HTTP GET)"""
    result = http_get("GetRouteWiseBusList_test", {
        "LocationId": station_id,
        "RouteId": route_id,
        "ScheduleDate": schedule_time,
    })
    # Explicit error
    if result is None:
        return None  # "NO BUS AVAILABLE" — not an error
    if isinstance(result, dict) and "error" in result:
        return result  # Network/timeout error
    if isinstance(result, list):
        return result
    return []


def get_bus_tracker(trip_id, trip_start_time, status=1):
    """Get detailed tracking data for a specific bus trip. (Direct HTTP GET)"""
    result = http_get("GetBusTrackerDetails", {
        "TripId": trip_id,
        "TripStatus": status,
        "TripStartTime": trip_start_time,
    })
    return result


# ─── Helpers for schedule ─────────────────────────────────────────────────

def find_next_trip(schedule_data):
    """From the schedule list, find the current/next trip."""
    if not schedule_data or not isinstance(schedule_data, list):
        return None
    from datetime import datetime
    now = datetime.now()
    trips = []
    for entry in schedule_data:
        start_str = entry.get("TripStartTime", "")
        if not start_str:
            continue
        # Parse "06:35 AM" format
        try:
            t = datetime.strptime(start_str.strip(), "%I:%M %p")
            trip_dt = now.replace(hour=t.hour, minute=t.minute, second=0, microsecond=0)
            trips.append((trip_dt, start_str.strip()))
        except ValueError:
            try:
                t = datetime.strptime(start_str.strip(), "%H:%M:%S")
                trip_dt = now.replace(hour=t.hour, minute=t.minute, second=0, microsecond=0)
                trips.append((trip_dt, start_str.strip()))
            except ValueError:
                continue

    if not trips:
        return None

    # Sort by how close to now (looking for current/next trip)
    trips.sort(key=lambda x: abs((x[0] - now).total_seconds()))
    return trips[0]


# ─── Display ───────────────────────────────────────────────────────────────

def print_bus_card(bus, route_name):
    """Print a nicely formatted bus card."""
    bus_no = bus.get("BusNo", "Unknown")
    status = bus.get("BusRunningStatus", "Running")
    lat = bus.get("lattitude", "")
    lon = bus.get("longitude", "")
    dest = bus.get("destination", "Unknown")
    trip_id = bus.get("TripId", "")
    eta = bus.get("Eta", "N/A")
    dist = bus.get("TotalDistanceCovered", "0")
    duration = bus.get("TripDuration", "N/A")

    print()
    print("╔══════════════════════════════════════════════╗")
    print("║  🚌  BUS 76 LIVE TRACKER")
    print("╠══════════════════════════════════════════════╣")
    print(f"║  Route: {route_name}")
    print(f"║  Bus:   {bus_no}")
    print(f"║  Status: {status}")
    print(f"║  TripID: {trip_id}")
    print(f"║  ETA at next stop: {eta}")
    print(f"║  Distance covered: {dist} km")
    print(f"║  Destination: {dest}")
    print(f"║  Duration: {duration}")
    print("╠══════════════════════════════════════════════╣")
    if lat and lon:
        print(f"║  📍 Live Location:")
        print(f"║     Lat: {lat}")
        print(f"║     Lon: {lon}")
        print(f"║     🗺  https://www.google.com/maps?q={lat},{lon}")
    print("╚══════════════════════════════════════════════╝")


def print_station_tracker(details):
    """Print stop-by-stop tracking details with summary."""
    if not details or not isinstance(details, list):
        print("  ⚠️  No stop-by-stop data available")
        return

    # Separate passed, current, and upcoming stops
    passed = []
    current = None
    upcoming = []

    for stop in details:
        name = stop.get("LocationName", stop.get("stationname", "Unknown"))
        status = stop.get("CoveredStatus", "notcovered")
        arrived = stop.get("ArrivedTime", "")
        eta = stop.get("ETA", "--:--")
        dist = stop.get("Distance", "0")

        if status == "covered":
            passed.append(name)
        else:
            if not current:
                current = name
            upcoming.append(name)

    # Also check LastLocationCovered from first entry for better accuracy
    last_covered = details[0].get("LastLocationCovered", "") if details else ""
    if last_covered and last_covered in passed:
        current = last_covered
        # Remove current from passed list for display
        if current in passed:
            passed = [s for s in passed if s != current]

    print()
    print(f"  📍 CURRENT STOP: **{current or 'Unknown'}**")
    print()
    if passed:
        print(f"  ✅ ✅ PASSED ({len(passed)} stops):", ", ".join(passed))
        print()
    if upcoming:
        print(f"  ⏳ UPCOMING ({len(upcoming)} stops):", ", ".join(upcoming))
    print()

    print("📋  STOP-BY-STOP TRACKING")
    print("────────────────────────────────────────────────────────────")

    for stop in details:
        sr = stop.get("srno", "?")
        name = stop.get("LocationName", stop.get("stationname", "Unknown"))
        dist = stop.get("Distance", "0")
        eta = stop.get("ETA", "--:--")
        status = stop.get("CoveredStatus", "notcovered")
        arrived = stop.get("ArrivedTime", "")

        if status == "covered":
            marker = "✅"
        else:
            marker = "⏳"

        arrived_str = f" ✓{arrived}" if arrived else ""
        print(f"  {marker} {name}  ({dist} km)  ETA: {eta}{arrived_str}")

    print()


def list_routes():
    """List all Route 76 variants."""
    print("\n📋  ROUTE 76 VARIANTS")
    print("═" * 60)
    for rid, rname in sorted(ROUTE_76_VARIANTS.items()):
        print(f"  [{rid}] {rname}")
    print(f"\n  Total: {len(ROUTE_76_VARIANTS)} variants")


def route_details(route_id):
    """Show detailed info for a route."""
    route_name = ROUTE_76_VARIANTS.get(int(route_id), f"Route #{route_id}")
    print(f"\n📋  DETAILS FOR {route_name}")
    print("═" * 60)

    # Stations
    print("\n📍  STATIONS:")
    stations = get_stations(route_id)
    if stations and isinstance(stations, list):
        for s in stations:
            sr = s.get("srno", "?")
            name = s.get("stationname", "?")
            sid = s.get("stationid", "?")
            print(f"     {sr:>2}. {name} (ID: {sid})")
    else:
        print("     ⚠️  Could not load station data")

    # Schedule
    print("\n⏱  SCHEDULE (first 12 trips):")
    schedule = get_schedule(route_id)
    if schedule and isinstance(schedule, list):
        for i, entry in enumerate(schedule):
            start = entry.get("TripStartTime", "?")
            # Show days active
            days = []
            for day in ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]:
                if entry.get(day, "0") == "True":
                    days.append(day)
            days_active = days if days else ["All days"]
            print(f"  ⏱  {start:>10}  ({', '.join(days_active)})")
            if i >= 12:  # Show first 12 then summary
                remaining = len(schedule) - 12
                if remaining > 0:
                    print(f"  ... and {remaining} more trips")
                break


def track_bus(route_id, station_id=None, schedule_time=None):
    """Track active buses on a route."""
    # Quick server check (3 retries, total ~6s before giving up)
    if not check_server(retries=3, delay=3, timeout=20):
        print("")
        print("╔══════════════════════════════════════════════╗")
        print("║  🚌  NMMT TRACKING SERVER OFFLINE            ║")
        print("╠══════════════════════════════════════════════╣")
        print("║  Still no response after 3 attempts.         ║")
        print("║  The NMMT server may be down — try again     ║")
        print("║  in a few minutes!                           ║")
        print("╚══════════════════════════════════════════════╝")
        return False

    route_name = ROUTE_76_VARIANTS.get(int(route_id), f"Route #{route_id}")

    # If no schedule_time provided, determine from schedule
    if not schedule_time:
        schedule = get_schedule(route_id)
        if schedule and isinstance(schedule, list):
            next_trip = find_next_trip(schedule)
            if next_trip:
                schedule_time = next_trip[0].strftime("%Y-%m-%dT%H:%M:%S")
            else:
                schedule_time = time.strftime("%Y-%m-%dT%H:%M:%S")
        else:
            schedule_time = time.strftime("%Y-%m-%dT%H:%M:%S")

    # If no station_id, try the first station from route details
    if not station_id:
        stations = get_stations(route_id)
        if stations and isinstance(stations, list) and len(stations) > 0:
            station_id = stations[0].get("stationid", 2776)
        else:
            station_id = 2776  # Default: Panvel Rly. Stn.(W)

    print(f"\n🔍  Searching for buses on {route_name}")
    print(f"  Station ID: {station_id}  |  Schedule: {schedule_time}")
    print(f"  ({time.strftime('%H:%M:%S')} IST)")

    buses = find_active_buses(route_id, station_id, schedule_time)

    if not buses:
        print("\n  ❌ No active buses found on this route right now.")
        print("  Try a different departure time or check back later.")
        print("  Buses run every 30-60 mins on this route.")
        return False

    if isinstance(buses, dict) and "error" in buses:
        print(f"\n  ❌ API Error: {buses['error']}")
        return False

    print(f"\n  ✅ Found {len(buses)} active bus(es)!\n")

    for bus in buses:
        trip_id = bus.get("TripId", "")
        trip_start = schedule_time
        print_bus_card(bus, route_name)

        # Get detailed tracking
        if trip_id:
            print(f"\n  📡  Fetching detailed tracking for Trip {trip_id}...")
            details = get_bus_tracker(trip_id, trip_start)
            if details and isinstance(details, list) and len(details) > 0:
                print_station_tracker(details)
            else:
                print("  ⚠️  Detailed tracking data not available (bus may have just started)")

    return True


def scan_all_routes():
    """Check all Route 76 variants for active buses."""
    # Server check (3 retries)
    if not check_server(retries=3, delay=3, timeout=20):
        print("")
        print("╔══════════════════════════════════════════════╗")
        print("║  🚌  NMMT TRACKING SERVER OFFLINE            ║")
        print("╠══════════════════════════════════════════════╣")
        print("║  Still no response after 3 attempts.         ║")
        print("║  The NMMT server may be down — try again     ║")
        print("║  in a few minutes!                           ║")
        print("╚══════════════════════════════════════════════╝")
        return

    print("\n🔍  SCANNING ALL ROUTE 76 VARIANTES FOR ACTIVE BUSES")
    print("=" * 60)

    found_any = False
    for rid, rname in sorted(ROUTE_76_VARIANTS.items()):
        print(f"\n─── Checking [{rid}] {rname} ───")

        # Get stations
        stations = get_stations(rid)
        if not stations or not isinstance(stations, list):
            print("  ⚠️  No station data")
            continue

        first_station = stations[0].get("stationid")
        if not first_station:
            continue

        # Get schedule
        schedule = get_schedule(rid)
        schedule_time = time.strftime("%Y-%m-%dT%H:%M:%S")
        if schedule and isinstance(schedule, list):
            next_trip = find_next_trip(schedule)
            if next_trip:
                schedule_time = next_trip[0].strftime("%Y-%m-%dT%H:%M:%S")

        buses = find_active_buses(rid, first_station, schedule_time)
        if buses and isinstance(buses, list) and len(buses) > 0:
            found_any = True
            last_station = stations[-1].get("stationname", "?")
            for bus in buses:
                print_bus_card(bus, rname)
                trip_id = bus.get("TripId", "")
                if trip_id:
                    details = get_bus_tracker(trip_id, schedule_time)
                    if details and isinstance(details, list) and len(details) > 0:
                        print_station_tracker(details)

    if not found_any:
        print("\n❌  No active buses found on any Route 76 variant right now.")
        print("    Try again during operating hours (6:35 AM - 10:00 PM).")


def polling_mode(route_ids=None, interval=30):
    """Continuously poll for bus location updates."""
    print(f"\n🔄  POLLING MODE — refreshing every {interval}s")
    print("    Press Ctrl+C to stop\n")

    try:
        while True:
            now = time.strftime("%H:%M:%S")
            print(f"\n{'─' * 50}")
            print(f"  ⏰  {now} IST")
            print(f"{'─' * 50}")

            if route_ids:
                for rid in route_ids:
                    track_bus(rid)
            else:
                scan_all_routes()

            if interval > 0:
                print(f"\n  😴  Sleeping {interval}s...")
                time.sleep(interval)
    except KeyboardInterrupt:
        print("\n\n  👋  Stopped polling.")


# ─── CLI Entry Point ────────────────────────────────────────────────────────

def main():
    import argparse

    parser = argparse.ArgumentParser(
        description="🚌 NMMT Bus 76 Live Tracker — Panvel/Navi Mumbai",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python3 bus76_tracker.py                    # Auto-track active Route 76 buses
  python3 bus76_tracker.py --list-routes      # List all 76 variants
  python3 bus76_tracker.py --route 5692       # Track Panvel→Karanjade route
  python3 bus76_tracker.py --route 5692 --details  # Show schedule+stations too
  python3 bus76_tracker.py --all              # Check ALL 76 variants
  python3 bus76_tracker.py --poll 15          # Poll every 15 seconds
        """,
    )

    parser.add_argument("--list-routes", action="store_true", help="List all Route 76 variants")
    parser.add_argument("--route", type=int, help="Track a specific route by RouteId")
    parser.add_argument("--details", action="store_true", help="Show route details (stations + schedule)")
    parser.add_argument("--all", action="store_true", help="Check ALL Route 76 variants")
    parser.add_argument("--poll", type=int, nargs="?", const=30, metavar="SECONDS",
                        help="Polling mode (default interval: 30s)")

    args = parser.parse_args()

    if args.list_routes:
        list_routes()
    elif args.route:
        if args.details:
            route_details(args.route)
        track_bus(args.route)
    elif args.all:
        scan_all_routes()
    elif args.poll is not None:
        route_ids = [args.route] if args.route else None
        polling_mode(route_ids, args.poll)
    else:
        # Default: scan all variants
        scan_all_routes()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n  👋  Stopped.\n")
    except Exception as e:
        print(f"\n  ❌  Unexpected error: {e}")
        print("  Try again in a few minutes.\n")