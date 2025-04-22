from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from firebase_admin import firestore
from typing import List
import datetime

router = APIRouter()
db = firestore.client()

class TravelHistoryEntry(BaseModel):
    user_id: str
    route: str
    date: str  # Format: 'YYYY-MM-DD'
    crowd_level: str  # e.g., 'Few Seats', 'Standing Room Only', etc.

@router.post("/travel-history", status_code=201)
def create_history(entry: TravelHistoryEntry):
    try:
        doc_ref = db.collection("travel_history").document()
        doc_ref.set(entry.dict())
        return {"message": "Travel history saved successfully."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/travel-history/{user_id}", response_model=List[TravelHistoryEntry])
def get_user_history(user_id: str):
    try:
        docs = db.collection("travel_history").where("user_id", "==", user_id).stream()
        history = [doc.to_dict() for doc in docs]
        return history
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/travel-history/{user_id}")
def delete_user_history(user_id: str):
    try:
        docs = db.collection("travel_history").where("user_id", "==", user_id).stream()
        deleted_count = 0
        for doc in docs:
            db.collection("travel_history").document(doc.id).delete()
            deleted_count += 1
        return {"message": f"Deleted {deleted_count} history records for user {user_id}."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))