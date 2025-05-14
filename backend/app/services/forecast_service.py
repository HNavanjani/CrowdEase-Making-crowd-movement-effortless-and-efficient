import os
import glob
import pandas as pd
import json
from pathlib import Path

# Paths
base_dir = Path(__file__).resolve().parents[3]
data_dir = base_dir / "processed"
cache_file = base_dir / "insight_outputs" / "forecast_weekly.json"
os.makedirs(cache_file.parent, exist_ok=True)

def get_weekly_forecast():
    # Load from cache if available
    if cache_file.exists():
        print(f"[CACHE] Returning saved forecast from {cache_file}")
        with open(cache_file, "r") as f:
            return json.load(f)

    print(f"[INFO] Looking for CSVs in: {data_dir}")
    all_files = sorted(glob.glob(str(data_dir / "*.csv")))
    print(f"[INFO] Found {len(all_files)} files")

    total_rows = 0
    df_list = []

    for file in all_files:
        print(f"[INFO] Reading file: {file}")
        try:
            df = pd.read_csv(file, usecols=["CALENDAR_DATE", "TIMETABLE_HOUR_BAND", "CAPACITY_BUCKET_ENCODED"])
            row_count = len(df)
            total_rows += row_count
            print(f"[INFO] Loaded {row_count} rows from {Path(file).name}")
            df_list.append(df)
        except Exception as e:
            print(f"[ERROR] Failed to read {file}: {e}")

    if not df_list:
        print("[WARN] No data loaded from any CSV")
        return {"weekly_forecast": {}, "time_band_forecast": {}}

    df = pd.concat(df_list, ignore_index=True)
    print(f"[INFO] Total rows combined from all files: {total_rows}")
    print(df.head(3))

    df['CALENDAR_DATE'] = pd.to_datetime(df['CALENDAR_DATE'], format='%d/%b/%y', errors='coerce')
    df['CAPACITY_BUCKET_ENCODED'] = pd.to_numeric(df['CAPACITY_BUCKET_ENCODED'], errors='coerce')
    before_drop = len(df)
    df = df.dropna(subset=["CALENDAR_DATE", "CAPACITY_BUCKET_ENCODED", "TIMETABLE_HOUR_BAND"])
    print(f"[INFO] Dropped {before_drop - len(df)} rows with missing/invalid data")

    if df.empty:
        print("[WARN] All rows dropped after cleaning — no valid data")
        return {"weekly_forecast": {}, "time_band_forecast": {}}

    df['weekday'] = df['CALENDAR_DATE'].dt.day_name()

    # Weekly forecast
    weekday_avg = (
        df.groupby('weekday')['CAPACITY_BUCKET_ENCODED']
        .mean()
        .reindex(['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'])
        .round(2)
        .fillna(0)
        .to_dict()
    )

    # Hourly bands forecast grouped by weekday and time
    time_band = (
        df.groupby(['weekday', 'TIMETABLE_HOUR_BAND'])['CAPACITY_BUCKET_ENCODED']
        .mean()
        .round(2)
        .reset_index()
    )

    # Convert to nested dict: { weekday: { time_band: avg } }
    time_band_forecast = {}
    for _, row in time_band.iterrows():
        day = row['weekday']
        time_band = row['TIMETABLE_HOUR_BAND']
        value = row['CAPACITY_BUCKET_ENCODED']
        time_band_forecast.setdefault(day, {})[time_band] = value

    result = {
        "weekly_forecast": weekday_avg,
        "time_band_forecast": time_band_forecast
    }

    print(f"[INFO] Final result: {json.dumps(result, indent=2)[:300]}...")  # partial print
    with open(cache_file, "w") as f:
        json.dump(result, f)

    return result
