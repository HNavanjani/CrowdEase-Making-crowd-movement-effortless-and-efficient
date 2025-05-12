import os
import requests
from google.transit import gtfs_realtime_pb2
from pathlib import Path
from datetime import datetime
from app.utils.gtfs_static_loader import load_trip_route_map

# Lazy loading function for trip_route_map
def get_trip_route_map():
    return load_trip_route_map()

# Load .env locally only (skip on Render)
if not os.getenv("TFNSW_API_KEY"):
    from dotenv import load_dotenv
    env_path = Path(__file__).resolve().parents[2] / '.env'
    load_dotenv(dotenv_path=env_path)

TFNSW_API_KEY = os.getenv("TFNSW_API_KEY")

def get_bus_positions():
    if not TFNSW_API_KEY:
        return {"error": "API key not found"}, 500

    url = 'https://api.transport.nsw.gov.au/v1/gtfs/vehiclepos/buses'
    headers = {'Authorization': f'apikey {TFNSW_API_KEY}'}

    try:
        response = requests.get(url, headers=headers)
        if response.status_code != 200:
            return {"error": "TfNSW fetch failed", "status": response.status_code}, response.status_code

        feed = gtfs_realtime_pb2.FeedMessage()
        feed.ParseFromString(response.content)

        buses = []
        trip_route_map = get_trip_route_map()

        for entity in feed.entity:
            if entity.HasField("vehicle"):
                v = entity.vehicle
                trip_id = v.trip.trip_id
                route_info = trip_route_map.get(trip_id, {})

                buses.append({
                    "trip_id": trip_id,
                    "label": v.vehicle.label or v.vehicle.id,
                    "lat": v.position.latitude,
                    "lon": v.position.longitude,
                    "bearing": getattr(v.position, "bearing", None),
                    "last_updated": datetime.utcfromtimestamp(v.timestamp).isoformat() + "Z"
                    if v.HasField("timestamp") else "N/A",
                    "route_short": route_info.get("route_short_name", "–"),
                    "route_long": route_info.get("route_long_name", "")
                })

        return {"buses": buses}
    except Exception as e:
        return {"error": str(e)}, 500
