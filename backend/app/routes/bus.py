from fastapi import APIRouter
from app.services import tfnsw_bus

router = APIRouter()

@router.get("/getBusPositions")
def get_bus_positions():
    return tfnsw_bus.get_bus_positions()
