import os
import requests
from pathlib import Path

# Load .env locally only (skip on Render)
if not os.getenv("ORS_API_KEY"):
    from dotenv import load_dotenv
    env_path = Path(__file__).resolve().parents[2] / '.env'
    load_dotenv(dotenv_path=env_path)

ORS_API_KEY = os.getenv("ORS_API_KEY")

def get_matrix_durations_and_distances(coords: list, profile: str = "driving-car"):
    url = f"https://api.openrouteservice.org/v2/matrix/{profile}"
    headers = {
        "Authorization": ORS_API_KEY,
        "Content-Type": "application/json"
    }

    body = {
        "locations": coords,
        "sources": [0],  # first is origin
        "destinations": list(range(1, len(coords)))
    }

    response = requests.post(url, json=body, headers=headers)

    try:
        return response.json()
    except Exception as e:
        return {
            "status": response.status_code,
            "message": "Invalid JSON response",
            "details": str(e),
            "raw": response.text
        }
