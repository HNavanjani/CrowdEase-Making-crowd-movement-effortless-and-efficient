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

# Initialize total row count
total_rows = 0

# Check each file
for idx, file_path in enumerate(dataset_files, 1):
    df = pd.read_csv(file_path)
    row_count = len(df)
    total_rows += row_count
    print(f"{os.path.basename(file_path)}: {row_count} rows")

print(f"\nTotal rows across all files: {total_rows}")
