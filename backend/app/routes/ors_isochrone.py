from fastapi import APIRouter, Query
from app.services.ors_isochrone_service import get_isochrone

router = APIRouter()

@router.get("/ors/isochrone")
def isochrone_area(
    lon: float = Query(...),
    lat: float = Query(...),
    minutes: int = Query(10),
    profile: str = Query("foot-walking") 
):
    return get_isochrone(lon, lat, minutes * 60, profile)
