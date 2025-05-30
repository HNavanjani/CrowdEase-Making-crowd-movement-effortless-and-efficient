import pandas as pd
import os
import glob

# Define base directories
base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../.."))
datasets_folder = os.path.join(base_dir, "datasets")

# Find all CSV files
dataset_files = sorted(glob.glob(os.path.join(datasets_folder, "*.csv")))
total_files = len(dataset_files)

print(f"Found {total_files} CSV files to process in: {datasets_folder}")

# Mapping for raw CAPACITY_BUCKET → encoded
bucket_map = {
    "MANY_SEATS_AVAILABLE": 0,
    "FEW_SEATS_AVAILABLE": 1,
    "STANDING_ROOM_ONLY": 2,
    "FULL": 3
}

# Initialize totals
total_rows = 0
total_label_counts = pd.Series(dtype=int)

for idx, file_path in enumerate(dataset_files, 1):
    print(f"\nProcessing file {idx}/{total_files}: {os.path.basename(file_path)}")

    try:
        df = pd.read_csv(file_path, dtype=str)
    except Exception as e:
        print(f"  [ERROR] Failed to read file: {e}")
        continue

    row_count = len(df)
    total_rows += row_count
    print(f"  Row count: {row_count}")

    print("  Columns in file:")
    print("   ", list(df.columns))

    df.columns = df.columns.str.strip().str.upper()

    if "CAPACITY_BUCKET" in df.columns:
        df["CAPACITY_BUCKET_ENCODED"] = df["CAPACITY_BUCKET"].map(bucket_map)
        df = df.dropna(subset=["CAPACITY_BUCKET_ENCODED"])
        df["CAPACITY_BUCKET_ENCODED"] = df["CAPACITY_BUCKET_ENCODED"].astype(int)
        counts = df["CAPACITY_BUCKET_ENCODED"].value_counts().sort_index()
        total_label_counts = total_label_counts.add(counts, fill_value=0).astype(int)
        total_in_file = counts.sum()
        print("  Class distribution:")
        for cls, count in counts.items():
            percentage = (count / total_in_file) * 100
            print(f"    Class {int(cls)}: {count} rows ({percentage:.2f}%)")
    else:
        print("  [WARNING] 'CAPACITY_BUCKET' column not found in this file.")

print(f"\nTotal rows across all files: {total_rows}")
print("\nTotal class distribution across all files:")
total_all = total_label_counts.sum()
for cls, count in total_label_counts.sort_index().items():
    percentage = (count / total_all) * 100
    print(f"  Class {int(cls)}: {count} rows ({percentage:.2f}%)")
