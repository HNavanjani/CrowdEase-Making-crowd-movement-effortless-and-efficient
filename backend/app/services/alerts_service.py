import os
import requests
from pathlib import Path
from google.transit import gtfs_realtime_pb2

# Load .env locally only (skip on Render)
if not os.getenv("TFNSW_API_KEY"):
    from dotenv import load_dotenv
    env_path = Path(__file__).resolve().parents[2] / '.env'
    load_dotenv(dotenv_path=env_path)

TFNSW_API_KEY = os.getenv("TFNSW_API_KEY")


def get_bus_alerts():
    url = "https://api.transport.nsw.gov.au/v2/gtfs/alerts/buses"
    headers = {
        "Authorization": f"apikey {TFNSW_API_KEY}",
        "Accept": "application/x-protobuf"
    }

    response = requests.get(url, headers=headers)
    if response.status_code != 200:
        return {
            "status": response.status_code,
            "message": "Failed to fetch alerts",
            "details": response.text
        }

    feed = gtfs_realtime_pb2.FeedMessage()
    feed.ParseFromString(response.content)

    alerts = []
    for entity in feed.entity:
        if entity.HasField("alert"):
            alert = entity.alert

            title = ""
            if alert.header_text and alert.header_text.translation:
                title = alert.header_text.translation[0].text.strip()

            message = ""
            if alert.description_text and alert.description_text.translation:
                message = alert.description_text.translation[0].text.strip()

            routes = [e.route_id for e in alert.informed_entity if e.route_id]

            alerts.append({
                "title": title,
                "message": message,
                "routes": routes
            })

    return {"alerts": alerts}
