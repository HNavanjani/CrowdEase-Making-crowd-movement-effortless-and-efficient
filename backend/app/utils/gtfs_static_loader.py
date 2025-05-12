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
        extracted_files = os.listdir(data_path)
        print("Extracted GTFS files:", extracted_files)
        if 'routes.txt' not in extracted_files or 'trips.txt' not in extracted_files:
            raise FileNotFoundError("routes.txt or trips.txt not found after extraction")

#  Auto-trigger on Render only
if os.getenv("RENDER") == "true":
    download_and_extract_gtfs()

_trip_route_map_cache = None

def load_trip_route_map():
    global _trip_route_map_cache
    if _trip_route_map_cache is not None:
        return _trip_route_map_cache

    gtfs_path = Path(__file__).resolve().parents[2] / 'gtfs_data'
    routes_path = gtfs_path / 'routes.txt'
    trips_path = gtfs_path / 'trips.txt'

    if not routes_path.exists() or not trips_path.exists():
        raise FileNotFoundError("routes.txt or trips.txt not found. Make sure GTFS data is extracted.")

    routes_df = pd.read_csv(routes_path, dtype=str)
    trips_df = pd.read_csv(trips_path, dtype=str)

    joined = trips_df.merge(routes_df, on="route_id")[["trip_id", "route_short_name", "route_long_name"]]
    _trip_route_map_cache = joined.set_index("trip_id").to_dict(orient="index")
    return _trip_route_map_cache
