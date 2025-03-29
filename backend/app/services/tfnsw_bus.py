import requests
from google.transit import gtfs_realtime_pb2
from dotenv import load_dotenv
import os
from pathlib import Path

# Load environment variables from the .env file located in the backend root directory
env_path = Path(__file__).resolve().parents[2] / '.env'
load_dotenv(dotenv_path=env_path)

# Read the TfNSW API key from environment variables
TFNSW_API_KEY = os.getenv("TFNSW_API_KEY")

# Print the path and loaded API key for debugging purposes
print("ENV PATH:", env_path)
print("Loaded API KEY:", TFNSW_API_KEY)


def get_bus_positions():
    """
    Fetches real-time bus positions from the TfNSW GTFS Realtime API.
    Returns a simplified list of buses with trip ID, label, and coordinates.
    """

    if not TFNSW_API_KEY:
        return {"error": "API key not found. Check .env file."}

    # TfNSW GTFS-Realtime Vehicle Positions API endpoint
    url = 'https://api.transport.nsw.gov.au/v1/gtfs/vehiclepos/buses'
    headers = {'Authorization': f"apikey {TFNSW_API_KEY}"}

    # Send GET request to the API
    response = requests.get(url, headers=headers)

    # Log response metadata for debugging
    print("Status Code:", response.status_code)
    print("Content-Type:", response.headers.get("Content-Type"))
    print("First 200 bytes:", response.content[:200])

    # Return error message if API response is unsuccessful
    if response.status_code != 200:
        return {
            "error": "Failed to fetch data",
            "status": response.status_code,
            "message": response.text[:300]
        }

    # Parse the Protobuf response
    feed = gtfs_realtime_pb2.FeedMessage()
    feed.ParseFromString(response.content)

    # Extract basic details for the first 5 bus entities
    buses = []
    for entity in feed.entity[:5]:
        if entity.HasField('vehicle'):
            v = entity.vehicle
            buses.append({
                "trip_id": v.trip.trip_id,
                "label": v.vehicle.label,
                "lat": v.position.latitude,
                "lon": v.position.longitude,
            })

    return {"buses": buses}
