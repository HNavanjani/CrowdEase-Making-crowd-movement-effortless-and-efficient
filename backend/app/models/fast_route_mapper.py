import os
import pandas as pd
from tqdm import tqdm

# === CONFIG ===
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
LOOKUP_PATH = os.path.join(BASE_DIR, "lookup_route_mapping.csv")
DATASET_FOLDER = os.path.join(BASE_DIR, "datasets")
OUTPUT_FOLDER = os.path.join(BASE_DIR, "processed_with_route")
UNMATCHED_LOG_PATH = os.path.join(OUTPUT_FOLDER, "unmatched_route_log.txt")
os.makedirs(OUTPUT_FOLDER, exist_ok=True)

def encode_capacity_bucket(value):
    return {
        "MANY_SEATS_AVAILABLE": 0,
        "FEW_SEATS_AVAILABLE": 1,
        "STANDING_ROOM_ONLY": 2,
        "CRUSH_CAPACITY": 3
    }.get(value, -1)

print(" Loading route lookup...")
lookup_df = pd.read_csv(LOOKUP_PATH, dtype=str)

print(f"\n Scanning dataset folder: {DATASET_FOLDER}")
csv_files = [f for f in os.listdir(DATASET_FOLDER) if f.endswith(".csv")]

# === STATS TRACKERS ===
total_rows, total_matched = 0, 0
unmatched_records = []

for file_name in tqdm(csv_files, desc=" Files"):
    input_path = os.path.join(DATASET_FOLDER, file_name)
    output_path = os.path.join(OUTPUT_FOLDER, file_name)
    df = pd.read_csv(input_path, dtype=str)

    df["dataset_route_id"] = df["ROUTE"]  # Backup original
    df = df.drop(columns=["ROUTE"], errors="ignore")

    df = df.merge(lookup_df, on=["TRANSIT_STOP", "TIMETABLE_TIME"], how="left")

    # Rename columns
    df = df.rename(columns={
        "ROUTE_y": "ROUTE"
    })

    df["CAPACITY_BUCKET_ENCODED"] = df["CAPACITY_BUCKET"].apply(encode_capacity_bucket)

    # Track stats
    total_rows += len(df)
    matched = df["ROUTE"].notna().sum()
    total_matched += matched

    unmatched = df[df["ROUTE"].isna()][["TRANSIT_STOP", "TIMETABLE_TIME", "dataset_route_id"]]
    unmatched_records.append(unmatched)

    df.to_csv(output_path, index=False)

# === FINAL SUMMARY ===
unmatched_df = pd.concat(unmatched_records, ignore_index=True)
unmatched_df.to_csv(UNMATCHED_LOG_PATH, index=False)

match_pct = (total_matched / total_rows) * 100 if total_rows else 0
print(f"\n Summary:")
print(f"    Matched rows   : {total_matched:,}")
print(f"    Unmatched rows : {total_rows - total_matched:,}")
print(f"    Match rate     : {match_pct:.2f}%")
print(f"    Log saved to   : {UNMATCHED_LOG_PATH}")
