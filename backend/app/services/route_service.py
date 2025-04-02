import os
import openrouteservice
from dotenv import load_dotenv

load_dotenv()
ORS_API_KEY = os.getenv("ORS_API_KEY")
client = openrouteservice.Client(key=ORS_API_KEY)

def get_route_duration_distance(start_lon, start_lat, end_lon, end_lat):
    coords = [[start_lon, start_lat], [end_lon, end_lat]]
    try:
        # print(f"Calculating route from ({start_lat}, {start_lon}) to ({end_lat}, {end_lon})")
        result = client.directions(
            coordinates=coords,
            profile='driving-car',
            format='json'
        )
        summary = result['routes'][0]['summary']
        return {
            "distance_m": summary['distance'],
            "duration_min": round(summary['duration'] / 60, 2)
        }
    except Exception as e:
        return {"error": str(e)}
