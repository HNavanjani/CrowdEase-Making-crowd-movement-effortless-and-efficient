from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import traceback
from app.models.bus_occupancy_prediction_model import train_models, predict, append_feedback

router = APIRouter()

class FeedbackInput(BaseModel):
    ROUTE: int
    TIMETABLE_HOUR_BAND: str
    TRIP_POINT: str
    TIMETABLE_TIME: str
    ACTUAL_TIME: str
    CAPACITY_BUCKET: str
    CAPACITY_BUCKET_ENCODED: int

class PredictionInput(BaseModel):
    ROUTE: int
    TIMETABLE_HOUR_BAND: str
    TRIP_POINT: str
    TIMETABLE_TIME: str
    ACTUAL_TIME: str

@router.post("/train-model")
def trigger_training():
    try:
        train_models()
        return {"message": "Model trained and best model saved successfully."}
    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/predict-crowd")
def get_prediction(data: PredictionInput):
    try:
        result = predict(data.dict())
        return {"predicted_capacity_bucket_encoded": result}
    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/submit-feedback")
def save_feedback(data: FeedbackInput):
    try:
        append_feedback(data.dict())
        return {"message": "Feedback saved successfully."}
    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))
