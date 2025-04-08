from fastapi import APIRouter, HTTPException, Query
from typing import Optional
from app.services.csv_preview_service import load_csv_preview, get_common_columns

router = APIRouter()

@router.get("/view-csv-preview")
def view_csv_preview(
    n_rows: Optional[int] = Query(5, ge=1),
    max_files: Optional[int] = Query(3, ge=1),
    folder: Optional[str] = Query("datasets")
):
    try:
        preview_data = load_csv_preview(n_rows=n_rows, max_files=max_files, folder=folder)
        if not preview_data:
            raise HTTPException(status_code=404, detail="No preview data found.")
        return {"preview": preview_data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error loading CSV preview: {str(e)}")


@router.get("/available-columns")
def get_column_names(
    sample_file_limit: Optional[int] = Query(1, ge=1),
    folder: Optional[str] = Query("datasets")
):
    try:
        columns = get_common_columns(sample_file_limit=sample_file_limit, folder=folder)
        if not columns:
            raise HTTPException(status_code=404, detail="No columns found in sample CSV.")
        return {"columns": columns}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error retrieving column names: {str(e)}")
