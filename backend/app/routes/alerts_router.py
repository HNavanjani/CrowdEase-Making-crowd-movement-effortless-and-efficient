from fastapi import APIRouter
from app.services.alerts_service import get_bus_alerts

router = APIRouter()

@router.get("/alerts")
def read_alerts():
    return get_bus_alerts()
