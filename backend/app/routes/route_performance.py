from fastapi import APIRouter
from app.services.route_performance_service import get_route_performance

router = APIRouter()

@router.get("/route-performance")
def read_route_performance():
    return get_route_performance()
