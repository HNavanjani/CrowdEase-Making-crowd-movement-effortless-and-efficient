# from fastapi import APIRouter
# from typing import List
# import pandas as pd
# import os
# import glob

# router = APIRouter()

# data_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", "processed"))

# def get_sample_data():
#     files = sorted(glob.glob(os.path.join(data_dir, "*.csv")))
#     for file in files:
#         try:
#             df = pd.read_csv(file, dtype=str, nrows=5000)  # read small part
#             return df.fillna("Unknown")
#         except Exception:
#             continue
#     return pd.DataFrame()

# @router.get("/available-routes")
# def get_routes() -> dict:
#     df = get_sample_data()
#     unique = sorted(df["ROUTE"].dropna().astype(str).unique().tolist())
#     return {"routes": unique}

# @router.get("/available-hour-bands")
# def get_hour_bands() -> dict:
#     df = get_sample_data()
#     unique = sorted(df["TIMETABLE_HOUR_BAND"].dropna().astype(str).unique().tolist())
#     return {"hour_bands": unique}

# @router.get("/available-trip-points")
# def get_trip_points() -> dict:
#     df = get_sample_data()
#     unique = sorted(df["TRIP_POINT"].dropna().astype(str).unique().tolist())
#     return {"trip_points": unique}
