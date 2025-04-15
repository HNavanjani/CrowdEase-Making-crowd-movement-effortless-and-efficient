import pandas as pd
import os, json

base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "../gtfs_data"))
output_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "../dropdown_data"))
os.makedirs(output_dir, exist_ok=True)

def save_json(data, name):
    with open(os.path.join(output_dir, name), "w") as f:
        json.dump(data, f, indent=2)

# ROUTES
routes_df = pd.read_csv(os.path.join(base_dir, "routes.txt"), usecols=["route_short_name"])
routes = sorted(routes_df["route_short_name"].dropna().unique().tolist())
save_json(routes, "routes.json")

# TRIP POINTS
stops_df = pd.read_csv(os.path.join(base_dir, "stops.txt"), usecols=["stop_name"])
trip_points = sorted(stops_df["stop_name"].dropna().unique().tolist())[:30]
save_json(trip_points, "trip_points.json")

# HOUR BANDS
times_df = pd.read_csv(os.path.join(base_dir, "stop_times.txt"), usecols=["arrival_time"])
bands = times_df["arrival_time"].dropna().apply(
    lambda t: f"{t[:2]}:00 to {str(int(t[:2]) + 1).zfill(2)}:00"
)
hour_bands = sorted(bands.unique().tolist())
save_json(hour_bands, "hour_bands.json")

print("JSON files created in dropdown_data/")
