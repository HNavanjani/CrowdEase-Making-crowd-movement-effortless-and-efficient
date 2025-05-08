import pandas as pd
import os, json

base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "../gtfs_data"))
output_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "../dropdown_data"))
os.makedirs(output_dir, exist_ok=True)

def save_json(data, name):
    with open(os.path.join(output_dir, name), "w") as f:
        json.dump(data, f, indent=2)

# ROUTES
routes_df = pd.read_csv(os.path.join(base_dir, "routes.txt"), usecols=[
    "route_id", "route_short_name", "route_long_name", "route_desc"
])
routes_df.dropna(subset=["route_short_name", "route_long_name"], inplace=True)
# Convert to list of dicts
routes = routes_df.to_dict(orient="records")
save_json(routes, "routes.json")


# routes_df = pd.read_csv(os.path.join(base_dir, "routes.txt"), usecols=["route_short_name"])
# routes = sorted(routes_df["route_short_name"].dropna().unique().tolist())
# save_json(routes, "routes.json")

# TRIP POINTS
stops_df = pd.read_csv(os.path.join(base_dir, "stops.txt"), usecols=["stop_name", "location_type"])
# Keep only stops with location_type 0 or empty (standard bus stops)
bus_stops = stops_df[
    (stops_df["location_type"].isna()) | (stops_df["location_type"] == 0)
]
# Drop duplicates and missing names, then sort
trip_points = sorted(bus_stops["stop_name"].dropna().unique().tolist())
# Save to JSON
save_json(trip_points, "trip_points.json")


# stops_df = pd.read_csv(os.path.join(base_dir, "stops.txt"), usecols=["stop_name"])
# trip_points = sorted(stops_df["stop_name"].dropna().unique().tolist())[:30]
# save_json(trip_points, "trip_points.json")

# HOUR BANDS
times_df = pd.read_csv(os.path.join(base_dir, "stop_times.txt"), usecols=["arrival_time"])
def to_hour_band(time_str):
    try:
        hour = int(time_str.split(":")[0])
        hour = hour % 24
        next_hour = (hour + 1) % 24
        return f"{hour:02d}:00 to {next_hour:02d}:00"
    except:
        return None
bands = times_df["arrival_time"].dropna().map(to_hour_band).dropna()
hour_bands = sorted(set(bands))
save_json(hour_bands, "hour_bands.json")

# times_df = pd.read_csv(os.path.join(base_dir, "stop_times.txt"), usecols=["arrival_time"])
# bands = times_df["arrival_time"].dropna().apply(
#     lambda t: f"{t[:2]}:00 to {str(int(t[:2]) + 1).zfill(2)}:00"
# )
# hour_bands = sorted(bands.unique().tolist())
# save_json(hour_bands, "hour_bands.json")

print("JSON files created in dropdown_data/")
