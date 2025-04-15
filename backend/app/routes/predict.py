from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import traceback
from app.models.bus_occupancy_prediction_model import train_models, predict, append_feedback, model_dir
import os

router = APIRouter()

class FeedbackInput(BaseModel):
    ROUTE: str
    TIMETABLE_HOUR_BAND: str
    TRIP_POINT: str
    TIMETABLE_TIME: str
    ACTUAL_TIME: str
    CAPACITY_BUCKET: str
    CAPACITY_BUCKET_ENCODED: int

class PredictionInput(BaseModel):
    ROUTE: str
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

@router.get("/check-new-model")
def check_new_model():
    try:
        model_path = os.path.join(model_dir, "best_model.pkl")
        model_time = os.path.getmtime(model_path)
        threshold_time = os.path.getmtime(feedback_file) if os.path.exists(feedback_file) else 0
        if threshold_time > model_time:
            return {"new_model_available": True}
        return {"new_model_available": False}
    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))    

@router.get("/model-version")
def get_model_version():
    try:
        version_file = os.path.abspath(os.path.join(model_dir, "model_version.txt"))
        if os.path.exists(version_file):
            with open(version_file, "r") as f:
                return {"version": f.read().strip()}
        return {"version": "Unknown"}
    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/model-metrics")
def get_model_metrics():
    try:
        metrics_path = os.path.join(model_dir, "model_metrics.txt")
        with open(metrics_path, "r") as f:
            return {"metrics": f.read()}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))        

