import os
import pandas as pd
import json
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import List
from pathlib import Path

router = APIRouter()

# File paths
PREFERENCES_FILE = Path("data/user_preferences.csv")
ROUTES_JSON_PATH = Path("dropdown_data/routes.json")


# Create data dir if missing
PREFERENCES_FILE.parent.mkdir(parents=True, exist_ok=True)

# Load valid route list
with open(ROUTES_JSON_PATH, "r") as f:
    route_data = json.load(f)
VALID_ROUTES = set(route_data if isinstance(route_data[0], str) else [r["route"] for r in route_data])

# Initialize CSV if missing
if not PREFERENCES_FILE.exists():
    pd.DataFrame(columns=["user_id", "favorite_routes", "regular_route"]).to_csv(PREFERENCES_FILE, index=False)

class Preference(BaseModel):
    user_id: str
    favorite_routes: List[str] = Field(max_items=5)
    regular_route: str

def read_preferences():
    return pd.read_csv(PREFERENCES_FILE)

def save_preferences(df: pd.DataFrame):
    df.to_csv(PREFERENCES_FILE, index=False)

def validate_routes(favs: List[str], regular: str):
    invalid = [r for r in favs + [regular] if r not in VALID_ROUTES]
    if invalid:
        raise HTTPException(status_code=400, detail=f"Invalid route(s): {invalid}")

@router.post("/save-preferences")
def save_user_preferences(pref: Preference):
    validate_routes(pref.favorite_routes, pref.regular_route)
    df = read_preferences()
    if pref.user_id in df["user_id"].values:
        raise HTTPException(status_code=400, detail="User already exists. Use PUT to update.")
    df.loc[len(df)] = [pref.user_id, json.dumps(pref.favorite_routes), pref.regular_route]
    save_preferences(df)
    return {"message": "Preferences saved successfully"}

@router.get("/get-preferences/{user_id}")
def get_user_preferences(user_id: str):
    df = read_preferences()
    user = df[df["user_id"] == user_id]
    if user.empty:
        raise HTTPException(status_code=404, detail="User not found")
    row = user.iloc[0]
    return {
        "user_id": row["user_id"],
        "favorite_routes": json.loads(row["favorite_routes"]),
        "regular_route": row["regular_route"]
    }

@router.put("/update-preferences")
def update_user_preferences(pref: Preference):
    validate_routes(pref.favorite_routes, pref.regular_route)
    df = read_preferences()
    if pref.user_id not in df["user_id"].values:
        raise HTTPException(status_code=404, detail="User not found")
    idx = df[df["user_id"] == pref.user_id].index[0]
    df.at[idx, "favorite_routes"] = json.dumps(pref.favorite_routes)
    df.at[idx, "regular_route"] = pref.regular_route
    save_preferences(df)
    return {"message": "Preferences updated successfully"}

@router.delete("/remove-preferences/{user_id}")
def delete_user_preferences(user_id: str):
    df = read_preferences()
    if user_id not in df["user_id"].values:
        raise HTTPException(status_code=404, detail="User not found")
    df = df[df["user_id"] != user_id]
    save_preferences(df)
    return {"message": "Preferences deleted successfully"}
