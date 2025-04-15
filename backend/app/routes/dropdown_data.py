from fastapi import APIRouter, HTTPException
import os, json

router = APIRouter()
data_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../dropdown_data"))

@router.get("/dropdown/{file_name}")
def get_dropdown_data(file_name: str):
    try:
        file_path = os.path.join(data_dir, f"{file_name}.json")
        if not os.path.exists(file_path):
            raise HTTPException(status_code=404, detail="Dropdown file not found")
        with open(file_path, "r") as f:
            return json.load(f)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
