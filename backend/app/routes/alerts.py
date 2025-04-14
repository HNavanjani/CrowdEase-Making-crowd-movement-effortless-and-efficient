import requests
from fastapi import APIRouter
from fastapi.responses import JSONResponse
from datetime import datetime
import os

router = APIRouter()

@router.get("/alerts")
def get_alerts():
    api_key = os.getenv("TFNSW_API_KEY")
    today = datetime.now().strftime("%d-%m-%Y")

    url = "https://api.transport.nsw.gov.au/v1/tp/add_info"
    headers = {"Authorization": f"apikey {api_key}"}
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
