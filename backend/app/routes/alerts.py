import requests
from fastapi import APIRouter
from fastapi.responses import JSONResponse
from datetime import datetime
import os

router = APIRouter()

@router.get("/alerts")
def get_alerts():
    # Load .env locally only (skip on Render)
    if not os.getenv("TFNSW_API_KEY"):
        from dotenv import load_dotenv
        env_path = Path(__file__).resolve().parents[2] / '.env'
        load_dotenv(dotenv_path=env_path)

    # Load API key from environment
    TFNSW_API_KEY = os.getenv("TFNSW_API_KEY")

    today = datetime.now().strftime("%d-%m-%Y")

    url = "https://api.transport.nsw.gov.au/v1/tp/add_info"
    headers = {"Authorization": f"apikey {TFNSW_API_KEY}"}
    params = {
        "outputFormat": "rapidJSON",
        "coordOutputFormat": "EPSG:4326",
        "filterDateValid": today,
        "filterPublicationStatus": "current"
    }

    res = requests.get(url, headers=headers, params=params)
    if res.status_code != 200:
        return JSONResponse(status_code=500, content={"error": "Failed to fetch alerts"})

    data = res.json()
    raw_alerts = data.get("infos", {}).get("current", [])
    parsed_alerts = []

    for alert in raw_alerts:
        parsed_alerts.append({
            "title": alert.get("subtitle", "No Title"),
            "message": alert.get("properties", {}).get("speechText") or alert.get("content", "No Content"),
            "url": alert.get("url", "")
        })

    return {"alerts": parsed_alerts}
