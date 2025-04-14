from fastapi import APIRouter
from pydantic import BaseModel
from typing import List
from app.services.ors_matrix_service import get_matrix_durations_and_distances

router = APIRouter()

class MatrixRequest(BaseModel):
    coordinates: List[List[float]]  # [ [lon, lat], [lon, lat], ... ]
    profile: str = "driving-car"

@router.post("/ors/matrix")
def matrix_lookup(data: MatrixRequest):
    return get_matrix_durations_and_distances(data.coordinates, data.profile)
