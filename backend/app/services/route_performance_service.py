import os
import glob
import pandas as pd
import json
from pathlib import Path

base_dir = Path(__file__).resolve().parents[3]
data_dir = base_dir / "datasets"
cache_file = base_dir / "insight_outputs" / "route_performance.json"
os.makedirs(cache_file.parent, exist_ok=True)

def get_route_performance():
    if cache_file.exists():
        print(f"[CACHE] Returning saved route performance from {cache_file}")
        with open(cache_file, "r") as f:
            return json.load(f)

    print(f"[INFO] Looking for CSVs in: {data_dir}")
    all_files = sorted(glob.glob(str(data_dir / "*.csv")))
    print(f"[INFO] Found {len(all_files)} files")

    df_list = []
    for file in all_files:
        print(f"[INFO] Reading file: {file}")
        try:
            df = pd.read_csv(file, usecols=["ROUTE", "TIMETABLE_TIME", "ACTUAL_TIME", "CAPACITY_BUCKET", "TRANSIT_STOP_DESCRIPTION"])
            df_list.append(df)
            print(f"[INFO] Loaded {len(df)} rows from {Path(file).name}")
        except Exception as e:
            print(f"[ERROR] Failed to read {file}: {e}")

    if not df_list:
        print("[WARN] No data loaded from any CSV")
        return {"route_performance": {}}

    df = pd.concat(df_list, ignore_index=True)

    # Encode capacity
    capacity_map = {
        "MANY_SEATS_AVAILABLE": 0,
        "FEW_SEATS_AVAILABLE": 1,
        "STANDING_ROOM_ONLY": 2,
        "CRUSH_CAPACITY": 3
    }
    df["CAPACITY_BUCKET_ENCODED"] = df["CAPACITY_BUCKET"].map(capacity_map)

    # Time parsing
    def to_minutes(t):
        try:
            h, m = map(int, str(t).split(":"))
            return h * 60 + m
        except:
            return None

    df["timetable_min"] = df["TIMETABLE_TIME"].map(to_minutes)
    df["actual_min"] = df["ACTUAL_TIME"].map(to_minutes)
    df["delay_min"] = df["actual_min"] - df["timetable_min"]

    df["ROUTE"] = pd.to_numeric(df["ROUTE"], errors="coerce")
    df = df.dropna(subset=["ROUTE", "delay_min", "CAPACITY_BUCKET_ENCODED", "TRANSIT_STOP_DESCRIPTION"])

    # Round route IDs and group
    df["ROUTE"] = df["ROUTE"].astype(int)

    result = {}
    for route_id, group in df.groupby("ROUTE"):
        avg_delay = group["delay_min"].mean()
        avg_crowd = group["CAPACITY_BUCKET_ENCODED"].mean()
        most_common_stop = group["TRANSIT_STOP_DESCRIPTION"].value_counts().idxmax()
        result[str(route_id)] = {
            "average_delay_minutes": round(avg_delay, 2),
            "average_crowding_score": round(avg_crowd, 2),
            "total_trips": len(group),
            "most_common_stop": most_common_stop
        }

    with open(cache_file, "w") as f:
        json.dump({"route_performance": result}, f, indent=2)

    print(f"[INFO] Final result: {json.dumps(result, indent=2)[:300]}...")
    return {"route_performance": result}
