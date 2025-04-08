import pandas as pd
import glob
import os

def load_csv_preview(n_rows=5, max_files=3, folder="datasets"):
    base_path = os.path.abspath(os.path.join(os.path.dirname(__file__), f"../../../{folder}"))
    files = sorted(glob.glob(os.path.join(base_path, "*.csv")))[:max_files]
    preview_result = []

    for file in files:
        try:
            df = pd.read_csv(file, nrows=n_rows)
            for i, row in df.iterrows():
                cleaned_row = row.fillna("N/A").to_dict()
                preview_result.append({
                    "file": os.path.basename(file),
                    "row_number": i + 1,
                    "data": cleaned_row
                })
        except Exception as e:
            print(f"Error reading {file}: {e}")

    return preview_result

def get_common_columns(sample_file_limit=1, folder="datasets"):
    base_path = os.path.abspath(os.path.join(os.path.dirname(__file__), f"../../../{folder}"))
    files = sorted(glob.glob(os.path.join(base_path, "*.csv")))[:sample_file_limit]

    for file in files:
        try:
            df = pd.read_csv(file, nrows=1)
            return list(df.columns)
        except Exception as e:
            print(f"Error reading columns from {file}: {e}")

    return []
