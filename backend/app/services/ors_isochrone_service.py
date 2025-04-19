import os
import requests
from pathlib import Path

# Load .env locally only (skip on Render)
if not os.getenv("ORS_API_KEY"):
    from dotenv import load_dotenv
    env_path = Path(__file__).resolve().parents[2] / '.env'
    load_dotenv(dotenv_path=env_path)

# Load API key from environment
ORS_API_KEY = os.getenv("ORS_API_KEY")

def get_isochrone(lon: float, lat: float, range_seconds: int = 600, profile: str = "foot-walking"):
    url = f"https://api.openrouteservice.org/v2/isochrones/{profile}"
    headers = {
        "Authorization": ORS_API_KEY,
        "Content-Type": "application/json"
    }
    body = {
        "locations": [[lon, lat]],
        "range": [range_seconds]
    }

    response = requests.post(url, json=body, headers=headers)

    try:
        return response.json()
    except Exception as e:
        return {
            "status": response.status_code,
            "message": "Invalid JSON",
            "details": str(e),
            "raw": response.text
        }
