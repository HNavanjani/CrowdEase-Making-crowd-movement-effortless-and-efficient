import os
import pandas as pd
from tqdm import tqdm
from datetime import datetime

# === CONFIG ===
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
GTFS_FOLDER = os.path.join(BASE_DIR, "backend", "gtfs_data")
DATASET_FOLDER = os.path.join(BASE_DIR, "datasets")
LOOKUP_OUTPUT_PATH = os.path.join(BASE_DIR, "lookup_route_mapping.csv")
TIME_TOLERANCE = 3

print(f" Loading GTFS files from: {GTFS_FOLDER}")
stop_times_df = pd.read_csv(os.path.join(GTFS_FOLDER, "stop_times.txt"), low_memory=False)
trips_df = pd.read_csv(os.path.join(GTFS_FOLDER, "trips.txt"), low_memory=False)
routes_df = pd.read_csv(os.path.join(GTFS_FOLDER, "routes.txt"), low_memory=False)

trip_to_route = trips_df.set_index("trip_id")["route_id"].to_dict()
route_to_name = routes_df.set_index("route_id")["route_long_name"].to_dict()

stop_times_df["departure_minutes"] = stop_times_df["departure_time"].str.split(":").apply(
    lambda x: int(x[0]) * 60 + int(x[1]) if len(x) >= 2 and x[0].isdigit() else -1
)
stop_times_df["stop_sequence"] = pd.to_numeric(stop_times_df["stop_sequence"], errors="coerce")
stop_times_df.dropna(subset=["stop_sequence"], inplace=True)

stop_times_dict = {stop_id: group.copy() for stop_id, group in stop_times_df.groupby("stop_id")}

def time_to_minutes(t):
    try:
        h, m = map(int, str(t).split(":")[:2])
        return h * 60 + m
    except:
        return None

def match_route(stop_id, timetable_time):
    target_min = time_to_minutes(timetable_time)
    group = stop_times_dict.get(str(stop_id))
    if target_min is None or group is None or group.empty:
        return pd.Series([None, None])
    try:
        candidates = group[
            (group["departure_minutes"] >= target_min - TIME_TOLERANCE) &
            (group["departure_minutes"] <= target_min + TIME_TOLERANCE)
        ]
        if not candidates.empty:
            closest_row = candidates.loc[candidates["stop_sequence"].idxmin()]
        else:
            group["abs_diff"] = (group["departure_minutes"] - target_min).abs()
            closest_row = group.loc[group["abs_diff"].idxmin()]
        trip_id = closest_row["trip_id"]
        route_id = trip_to_route.get(trip_id)
        route_name = route_to_name.get(route_id)
        return pd.Series([route_id, route_name])
    except:
        return pd.Series([None, None])

# === Collect Unique Pairs ===
print(" Collecting unique (TRANSIT_STOP, TIMETABLE_TIME) pairs...")
unique_keys = set()
for file in tqdm(os.listdir(DATASET_FOLDER), desc="Scanning"):
    if file.endswith(".csv"):
        df = pd.read_csv(os.path.join(DATASET_FOLDER, file), usecols=["TRANSIT_STOP", "TIMETABLE_TIME"], dtype=str)
        unique_keys.update(tuple(x) for x in df.dropna().drop_duplicates().to_numpy())

print(f" Total unique keys: {len(unique_keys):,}")

# === Match all unique pairs ===
print(" Matching routes...")
keys_df = pd.DataFrame(list(unique_keys), columns=["TRANSIT_STOP", "TIMETABLE_TIME"])
matched_df = keys_df.copy()
matched_df[["ROUTE", "matched_route_name"]] = keys_df.apply(
    lambda row: match_route(row["TRANSIT_STOP"], row["TIMETABLE_TIME"]),
    axis=1
)

# === Save Lookup ===
matched_df.to_csv(LOOKUP_OUTPUT_PATH, index=False)
print(f"\n Lookup saved to: {LOOKUP_OUTPUT_PATH}")
