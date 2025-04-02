from fastapi import APIRouter, HTTPException
from app.services.historical_crowd_service import get_average_crowd, get_available_bus_ids

router = APIRouter()

# Endpoint for fetching average crowd data for a route
@router.get("/historical-crowd")
def historical_crowd(route_id: str):
    try:
        result = get_average_crowd(route_id)
        if 'error' in result:
            raise HTTPException(status_code=404, detail=result['error'])
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# Endpoint to get all available route IDs
@router.get("/available-routes")
def available_routes():
    try:
        routes = get_available_bus_ids()
        return {"routes": routes}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
