from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import List
import firebase_admin
from firebase_admin import credentials, firestore
import os
import json

# Detect if running on Render or locally
if "FIREBASE_CREDENTIAL_JSON" in os.environ:
    # On Render: Load from env
    cred_dict = json.loads(os.environ["FIREBASE_CREDENTIAL_JSON"])
    cred = credentials.Certificate(cred_dict)
else:
    # Local: Load from file
    cred = credentials.Certificate("serviceAccountKey.json")
print("Running on Render" if "FIREBASE_CREDENTIAL_JSON" in os.environ else "Running locally")
firebase_admin.initialize_app(cred)
db = firestore.client()
router = APIRouter()

# Constants
COLLECTION = "user_preferences"

# Model
class Preference(BaseModel):
    user_id: str
    favorite_routes: List[str] = Field(max_items=5)
    regular_route: str

# POST (create)
@router.post("/save-preferences")
def save_preferences(pref: Preference):
    doc_ref = db.collection(COLLECTION).document(pref.user_id)
    if doc_ref.get().exists:
        raise HTTPException(status_code=400, detail="User already exists. Use PUT to update.")
    doc_ref.set(pref.dict())
    return {"message": "Preferences saved successfully"}

# GET
@router.get("/get-preferences/{user_id}")
def get_preferences(user_id: str):
    doc = db.collection(COLLECTION).document(user_id).get()
    if not doc.exists:
        raise HTTPException(status_code=404, detail="User not found")
    return doc.to_dict()

# PUT (update)
@router.put("/update-preferences")
def update_preferences(pref: Preference):
    doc_ref = db.collection(COLLECTION).document(pref.user_id)
    if not doc_ref.get().exists:
        raise HTTPException(status_code=404, detail="User not found")
    doc_ref.update(pref.dict())
    return {"message": "Preferences updated successfully"}

# DELETE
@router.delete("/remove-preferences/{user_id}")
def delete_preferences(user_id: str):
    doc_ref = db.collection(COLLECTION).document(user_id)
    if not doc_ref.get().exists:
        raise HTTPException(status_code=404, detail="User not found")
    doc_ref.delete()
    return {"message": "Preferences deleted successfully"}
