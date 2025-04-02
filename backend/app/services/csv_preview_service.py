import pandas as pd
import glob
import os

# Load and process historical data to get preview
def load_csv_preview():
    # Assuming the datasets folder is in the correct relative path
    base_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../datasets"))
    files = glob.glob(os.path.join(base_path, "*.csv"))

    print(f"Found {len(files)} CSV file(s) in {base_path}")

    all_data = []

    for file in files:
        try:
            print(f"Reading file: {os.path.basename(file)}")
            chunk = pd.read_csv(file, usecols=['ROUTE', 'CAPACITY_BUCKET'], nrows=10)  # Only reading first 10 rows
            all_data.append(chunk)

        except Exception as e:
            print(f"Error reading {file}: {e}")

    # Combine chunks if any and return
    if all_data:
        return pd.concat(all_data, ignore_index=True)
    else:
        return pd.DataFrame(columns=['ROUTE', 'CAPACITY_BUCKET'])
