from fastapi import APIRouter, HTTPException
import os, json, requests
from datetime import datetime
from app.models.bus_occupancy_prediction_model import predict
from pathlib import Path

router = APIRouter()
dropdown_dir = Path(__file__).resolve().parents[2] / "dropdown_data"

@router.get("/predicted-crowd-levels")
def get_predicted_crowd_levels():
    try:
        routes_file = dropdown_dir / "routes.json"
        if not routes_file.exists():
            raise HTTPException(status_code=404, detail="routes.json not found")

        with open(routes_file, "r") as f:
            routes = json.load(f)

        current_time = datetime.now()
        timetable_time = current_time.strftime("%H:%M")
        actual_time = timetable_time

        hour_band_start = current_time.replace(minute=0)
        hour_band_end = hour_band_start.replace(minute=59)
        hour_band_str = f"{hour_band_start.strftime('%H')}:00 to {hour_band_end.strftime('%H')}:00"

        results = []
        for route in routes[:5]:  # Limit for performance
            prediction_input = {
                "ROUTE": route,
                "TIMETABLE_HOUR_BAND": hour_band_str,
                "TRIP_POINT": "Mid Trip",
                "TIMETABLE_TIME": timetable_time,
                "ACTUAL_TIME": actual_time
            }

            try:
                prediction = predict(prediction_input)
                level = ["Low", "Medium", "Medium", "High"][min(prediction, 3)]
                results.append({
                    "route": f"Route {route}",
                    "level": level,
                    "time": current_time.strftime("As of %I:%M %p").lstrip("0")
                })
            except Exception as e:
                continue

        return {"predictions": results}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
