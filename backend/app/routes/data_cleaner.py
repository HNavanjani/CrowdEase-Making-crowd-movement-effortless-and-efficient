from fastapi import APIRouter, HTTPException
from app.services.data_cleaner import clean_and_save_all

router = APIRouter()

@router.post("/clean-datasets")
def clean_datasets():
    try:
        clean_and_save_all()
        return {"message": "Dataset cleaning completed successfully."}
    except Exception as e:
        print(f"Error during dataset cleaning: {e}")
        raise HTTPException(status_code=500, detail=f"Dataset cleaning failed: {str(e)}")
