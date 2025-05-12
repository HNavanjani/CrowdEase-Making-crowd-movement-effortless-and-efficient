import os
import zipfile
import requests
import pandas as pd
from pathlib import Path

def download_and_extract_gtfs():
    data_path = Path(__file__).resolve().parents[2] / "gtfs_data"
    zip_path = data_path / "gtfs_data.zip"

    if not data_path.exists():
        data_path.mkdir(parents=True)

    if not zip_path.exists():
        print("Downloading GTFS zip from URL...")
        url = os.getenv("GTFS_ZIP_URL")
        if not url:
            raise EnvironmentError("GTFS_ZIP_URL not set in environment")

        response = requests.get(url)
        with open(zip_path, "wb") as f:
            f.write(response.content)

        print("Extracting GTFS zip...")
        with zipfile.ZipFile(zip_path, "r") as zip_ref:
            zip_ref.extractall(data_path)
        print("GTFS static data ready.")

# 🔁 Auto-trigger on Render only
if os.getenv("RENDER") == "true":
    download_and_extract_gtfs()

def load_trip_route_map():
    gtfs_path = Path(__file__).resolve().parents[2] / 'gtfs_data'
    routes_path = gtfs_path / 'routes.txt'
    trips_path = gtfs_path / 'trips.txt'

    routes_df = pd.read_csv(routes_path, dtype=str)
    trips_df = pd.read_csv(trips_path, dtype=str)

    joined = trips_df.merge(routes_df, on="route_id")[["trip_id", "route_short_name", "route_long_name"]]
    return joined.set_index("trip_id").to_dict(orient="index")
