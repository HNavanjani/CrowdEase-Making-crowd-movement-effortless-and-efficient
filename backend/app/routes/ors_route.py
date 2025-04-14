from fastapi import APIRouter, Query
from app.services.ors_route_service import get_route_duration_and_distance

router = APIRouter()

@router.get("/ors/route")
def route_duration(
    start_lon: float = Query(...),
    start_lat: float = Query(...),
    end_lon: float = Query(...),
    end_lat: float = Query(...)
):
    return get_route_duration_and_distance([start_lon, start_lat], [end_lon, end_lat])
