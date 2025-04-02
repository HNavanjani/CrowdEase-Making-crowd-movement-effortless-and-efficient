from fastapi import APIRouter, Query
from app.services.route_service import get_route_duration_distance  # corrected

router = APIRouter()

@router.get("/route")
def get_route_distance_and_duration(
    start_lon: float = Query(...),
    start_lat: float = Query(...),
    end_lon: float = Query(...),
    end_lat: float = Query(...)
):
    return get_route_duration_distance(start_lon, start_lat, end_lon, end_lat)
