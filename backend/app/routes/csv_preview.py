from fastapi import APIRouter, HTTPException
from app.services.csv_preview_service import load_csv_preview

router = APIRouter()

# Endpoint to get a preview (first 10 rows) of the CSV
@router.get("/view-csv-preview")
def view_csv_preview():
    try:
        preview = load_csv_preview()
        if preview.empty:
            raise HTTPException(status_code=404, detail="No data found in CSV files.")
        return {"data": preview.to_dict(orient="records")}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error loading CSV: {str(e)}")
