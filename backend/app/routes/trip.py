import requests
from fastapi import APIRouter, Request
from fastapi.responses import JSONResponse
from datetime import datetime
import os

router = APIRouter()

@router.post("/trip")
async def get_trip(request: Request):
    body = await request.json()

    origin = body.get("origin")      # Stop ID or coord string
    destination = body.get("destination")
    date = body.get("date", datetime.now().strftime("%Y%m%d"))   # Optional
    time = body.get("time", datetime.now().strftime("%H%M"))     # Optional

    if not origin or not destination:
        return JSONResponse(status_code=400, content={"error": "Origin and destination are required"})

    # Load .env locally only (skip on Render)
    if not os.getenv("TFNSW_API_KEY"):
        from dotenv import load_dotenv
        env_path = Path(__file__).resolve().parents[2] / '.env'
        load_dotenv(dotenv_path=env_path)

    # Load API key from environment
    TFNSW_API_KEY = os.getenv("TFNSW_API_KEY")

    url = "https://api.transport.nsw.gov.au/v1/tp/trip"
    headers = {"Authorization": f"apikey {TFNSW_API_KEY}"}
    params = {
        "outputFormat": "rapidJSON",
        "coordOutputFormat": "EPSG:4326",
        "depArrMacro": "dep",
        "itdDate": date,
        "itdTime": time,
        "type_origin": "stop",
        "name_origin": origin,
        "type_destination": "stop",
        "name_destination": destination,
        "TfNSWTR": "true"
    }

    response = requests.get(url, headers=headers, params=params)
    if response.status_code != 200:
        return JSONResponse(status_code=500, content={"error": "Failed to fetch journey"})

    trips = response.json().get("journeys", [])
    result = []

    for journey in trips:
        legs = journey.get("legs", [])
        trip_summary = []
        for leg in legs:
            origin_name = leg.get("origin", {}).get("disassembledName", "")
            destination_name = leg.get("destination", {}).get("disassembledName", "")
            departure = leg.get("origin", {}).get("departureTimePlanned", "")
            arrival = leg.get("destination", {}).get("arrivalTimePlanned", "")
            mode = leg.get("transportation", {}).get("product", {}).get("name", "Unknown")

            trip_summary.append({
                "mode": mode,
                "from": origin_name,
                "to": destination_name,
                "departure": departure,
                "arrival": arrival
            })

        result.append(trip_summary)

    return {"journeys": result}
