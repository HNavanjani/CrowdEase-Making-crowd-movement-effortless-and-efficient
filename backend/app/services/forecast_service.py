import os
import glob
import pandas as pd
from pathlib import Path

# Path to 'processed' folder (adjusted to your structure)
data_dir = Path(__file__).resolve().parents[3] / "processed"

def get_weekly_forecast():
    print(f"[INFO] Looking for CSVs in: {data_dir}")

    all_files = sorted(glob.glob(str(data_dir / "*.csv")))
    print(f"[INFO] Found {len(all_files)} files")

    total_rows = 0
    df_list = []

    for file in all_files:
        print(f"[INFO] Reading file: {file}")
        try:
            df = pd.read_csv(file, usecols=["CALENDAR_DATE", "CAPACITY_BUCKET_ENCODED"])
            row_count = len(df)
            total_rows += row_count
            print(f"[INFO] Loaded {row_count} rows from {Path(file).name}")
            df_list.append(df)
        except Exception as e:
            print(f"[ERROR] Failed to read {file}: {e}")

    if not df_list:
        print("[WARN] No data loaded from any CSV")
        return {"weekly_forecast": {}}

    df = pd.concat(df_list, ignore_index=True)
    print(f"[INFO] Total rows combined from all files: {total_rows}")
    print(df.head(3))  # Preview first few rows

    # Parse CALENDAR_DATE like '21/NOV/16'
    df['CALENDAR_DATE'] = pd.to_datetime(df['CALENDAR_DATE'], format='%d/%b/%y', errors='coerce')
    df['CAPACITY_BUCKET_ENCODED'] = pd.to_numeric(df['CAPACITY_BUCKET_ENCODED'], errors='coerce')

    before_drop = len(df)
    df = df.dropna(subset=["CALENDAR_DATE", "CAPACITY_BUCKET_ENCODED"])
    dropped = before_drop - len(df)
    print(f"[INFO] Dropped {dropped} rows with missing or invalid data")

    if df.empty:
        print("[WARN] All rows dropped after cleaning — no valid data")
        return {"weekly_forecast": {}}

    df['weekday'] = df['CALENDAR_DATE'].dt.day_name()
    print("[INFO] Weekday breakdown sample:")
    print(df[['CALENDAR_DATE', 'weekday', 'CAPACITY_BUCKET_ENCODED']].head(3))

    weekday_avg = (
        df.groupby('weekday')['CAPACITY_BUCKET_ENCODED']
        .mean()
        .reindex([
            'Monday', 'Tuesday', 'Wednesday', 'Thursday',
            'Friday', 'Saturday', 'Sunday'
        ])
        .round(2)
        .fillna(0)
        .to_dict()
    )

    print(f"[INFO] Weekly forecast: {weekday_avg}")
    return {"weekly_forecast": weekday_avg}
