from fastapi import APIRouter, HTTPException, Query
import traceback
from app.models.bus_occupancy_prediction_model import predict

router = APIRouter()

@router.get("/forecast-daily", tags=["Forecast"])
def get_daily_hourly_forecast(
    route: str = Query(...),
    trip_point: str = Query(...),
    day: str = Query(...)
):
    try:
        hours = [f"{str(h).zfill(2)}:00" for h in range(24)]  # '00:00' to '23:00'
        graph_data = []

        for hour in hours:
            hour_band = get_hour_band(hour)
            payload = {
                "ROUTE": route,
                "TIMETABLE_HOUR_BAND": hour_band,
                "TRIP_POINT": trip_point,
                "TIMETABLE_TIME": hour,
                "ACTUAL_TIME": hour
            }

            try:
                prediction = predict(payload)
                graph_data.append({
                    "hour": hour,
                    "crowd_level": prediction
                })
            except Exception:
                graph_data.append({
                    "hour": hour,
                    "crowd_level": -1
                })

        return {
            "route": route,
            "trip_point": trip_point,
            "day": day,
            "graph_data": graph_data
        }

    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


def get_hour_band(hour_str: str) -> str:
    hour = int(hour_str.split(":")[0])
    if 7 <= hour < 9:
        return "07:00-09:00"
    elif 9 <= hour < 12:
        return "09:00-12:00"
    elif 12 <= hour < 15:
        return "12:00-15:00"
    elif 15 <= hour < 18:
        return "15:00-18:00"
    else:
        return "00:00-07:00"  # default low crowd band
