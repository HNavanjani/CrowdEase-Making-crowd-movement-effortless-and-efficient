import os
import requests
from pathlib import Path

# Load .env locally only (skip on Render)
if not os.getenv("ORS_API_KEY"):
    from dotenv import load_dotenv
    env_path = Path(__file__).resolve().parents[2] / '.env'
    load_dotenv(dotenv_path=env_path)

# Load API key
ORS_API_KEY = os.getenv("ORS_API_KEY")

def get_route_duration_and_distance(start_coords: list, end_coords: list):
    url = "https://api.openrouteservice.org/v2/directions/driving-car"
    headers = {
        "Authorization": ORS_API_KEY,
        "Content-Type": "application/json"
    }
    body = {
        "coordinates": [start_coords, end_coords]
    }

    response = requests.post(url, json=body, headers=headers)

    try:
        data = response.json()
    except Exception as e:
        return {
            "status": response.status_code,
            "message": "Invalid JSON response",
            "details": str(e),
            "raw": response.text
        }

    if response.status_code != 200:
        return {
            "status": response.status_code,
            "message": "ORS request failed",
            "details": data
        }

    if "routes" not in data or not data["routes"]:
        return {
            "status": response.status_code,
            "message": "No routes returned in ORS response",
            "details": data
        }

    summary = data["routes"][0]["summary"]

    return {
        "distance_meters": summary["distance"],
        "duration_minutes": summary["duration"] / 60
    }
