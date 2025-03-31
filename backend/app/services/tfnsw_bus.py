import os
import requests
from google.transit import gtfs_realtime_pb2
from pathlib import Path

# Load .env locally only (skip on Render)
if not os.getenv("TFNSW_API_KEY"):
    from dotenv import load_dotenv
    env_path = Path(__file__).resolve().parents[2] / '.env'
    load_dotenv(dotenv_path=env_path)

# Load API key from environment
TFNSW_API_KEY = os.getenv("TFNSW_API_KEY")

def get_bus_positions():
    from datetime import datetime

    if not TFNSW_API_KEY:
        print("ERROR: API key not found. Set TFNSW_API_KEY.")
        return {"error": "API key not found. Check .env or Render settings."}, 500

    url = 'https://api.transport.nsw.gov.au/v1/gtfs/vehiclepos/buses'
    headers = {'Authorization': f"apikey {TFNSW_API_KEY}"}

    try:
        response = requests.get(url, headers=headers)

        print("TfNSW API status code:", response.status_code)
        if response.status_code != 200:
            return {
                "error": "Failed to fetch data from TfNSW",
                "status": response.status_code,
                "message": response.text[:300]
            }, response.status_code

        feed = gtfs_realtime_pb2.FeedMessage()
        feed.ParseFromString(response.content)

        buses = []
        for entity in feed.entity[:5]:
            if entity.HasField('vehicle'):
                v = entity.vehicle
                buses.append({
                    "trip_id": v.trip.trip_id,
                    "label": v.vehicle.label or v.vehicle.id,
                    "lat": v.position.latitude,
                    "lon": v.position.longitude,
                    "bearing": getattr(v.position, "bearing", None),
                    "last_updated": datetime.utcfromtimestamp(v.timestamp).isoformat() + "Z"
                    if v.HasField("timestamp") else "N/A"
                })

        return {"buses": buses}
    except Exception as e:
        print("Exception in get_bus_positions:", e)
        return {"error": str(e)}, 500
