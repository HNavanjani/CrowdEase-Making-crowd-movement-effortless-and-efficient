from fastapi import APIRouter
from app.services.trip_updates_service import get_trip_updates

router = APIRouter()

@router.get("/trip-updates")
def read_trip_updates():
    return get_trip_updates()
