import os
import requests
from fastapi import APIRouter
from fastapi.responses import JSONResponse
from google.transit import gtfs_realtime_pb2

router = APIRouter()

@router.get("/live_buses")
def get_live_bus_positions():
    # Load .env locally only (skip on Render)
    if not os.getenv("TFNSW_API_KEY"):
        from dotenv import load_dotenv
        env_path = Path(__file__).resolve().parents[2] / '.env'
        load_dotenv(dotenv_path=env_path)

    # Load API key from environment
    TFNSW_API_KEY = os.getenv("TFNSW_API_KEY")

    url = "https://api.transport.nsw.gov.au/v1/gtfs/vehiclepos/buses" 
    headers = {"Authorization": f"apikey {TFNSW_API_KEY}"}

    res = requests.get(url, headers=headers)
    if res.status_code != 200:
        return JSONResponse(status_code=500, content={"error": "Failed to fetch live bus data"})

    feed = gtfs_realtime_pb2.FeedMessage()
    feed.ParseFromString(res.content)

    buses = []
    for entity in feed.entity:
        if entity.vehicle:
            buses.append({
                "vehicle_id": entity.vehicle.vehicle.id,
                "label": entity.vehicle.vehicle.label,
                "route_id": entity.vehicle.trip.route_id,
                "latitude": entity.vehicle.position.latitude,
                "longitude": entity.vehicle.position.longitude,
                "speed": entity.vehicle.position.speed,
                "timestamp": entity.vehicle.timestamp
            })

    return {"live_buses": buses}
