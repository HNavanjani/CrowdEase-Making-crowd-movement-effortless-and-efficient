import os
import requests
from pathlib import Path
from google.transit import gtfs_realtime_pb2

# Load .env locally only (skip on Render)
if not os.getenv("TFNSW_API_KEY"):
    from dotenv import load_dotenv
    env_path = Path(__file__).resolve().parents[2] / '.env'
    load_dotenv(dotenv_path=env_path)

# Load API key from environment
TFNSW_API_KEY = os.getenv("TFNSW_API_KEY")

def get_trip_updates():
    url = "https://api.transport.nsw.gov.au/v1/gtfs/realtime/buses"
    headers = {
        "Authorization": f"apikey {TFNSW_API_KEY}",
        "Accept": "application/x-protobuf"
    }

    response = requests.get(url, headers=headers)

    if response.status_code != 200:
        return {
            "status": response.status_code,
            "message": "Failed to fetch trip updates",
            "details": response.text
        }

    feed = gtfs_realtime_pb2.FeedMessage()
    feed.ParseFromString(response.content)

    trip_updates = []
    for entity in feed.entity:
        if entity.HasField("trip_update"):
            trip = entity.trip_update.trip

            if not trip.trip_id:
                continue

            update = {
                "trip_id": trip.trip_id,
                "route_id": trip.route_id,
                "start_time": trip.start_time,
                "start_date": trip.start_date,
                "delay_seconds": None
            }

            if entity.trip_update.stop_time_update:
                arrival = entity.trip_update.stop_time_update[0].arrival
                if arrival and arrival.HasField("delay"):
                    update["delay_seconds"] = arrival.delay

            trip_updates.append(update)

    return trip_updates
