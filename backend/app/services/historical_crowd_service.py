import pandas as pd
import glob
import os
from collections import Counter

# Load and process historical data
def load_historical_crowd_data():
    base_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../datasets"))
    files = glob.glob(os.path.join(base_path, "*.csv"))

    print(f"Found {len(files)} CSV file(s) in {base_path}")

    all_data = []

    for file in files:
        try:
            print(f"Reading file: {os.path.basename(file)}")
            chunks = pd.read_csv(file, usecols=['ROUTE', 'CAPACITY_BUCKET'], chunksize=100000, low_memory=False)

            for chunk in chunks:
                chunk = chunk.dropna(subset=['ROUTE', 'CAPACITY_BUCKET'])
                all_data.append(chunk)

        except Exception as e:
            print(f"Error reading {file}: {e}")

    if all_data:
        return pd.concat(all_data, ignore_index=True)
    else:
        return pd.DataFrame(columns=['ROUTE', 'CAPACITY_BUCKET'])


# API logic: return average crowd level for a given route
def get_average_crowd(route_id: str):
    df = load_historical_crowd_data()

    if df.empty:
        return {"error": "No data available"}

    # Filter by ROUTE
    route_df = df[df['ROUTE'].astype(str) == str(route_id)]

    if route_df.empty:
        return {"error": f"No data found for route {route_id}"}

    # Count crowd levels
    bucket_counts = route_df['CAPACITY_BUCKET'].value_counts().to_dict()

    return {
        "route": route_id,
        "total_records": len(route_df),
        "crowd_levels": bucket_counts
    }


# Helper to list available routes
def get_available_bus_ids():
    df = load_historical_crowd_data()
    return df['ROUTE'].dropna().astype(str).unique().tolist()
