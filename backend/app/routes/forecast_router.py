from fastapi import APIRouter
from app.services.forecast_service import get_weekly_forecast

router = APIRouter()

@router.get("/forecast/weekly")
def read_weekly_forecast():
    return get_weekly_forecast()
