# import os
# import shutil
# import pandas as pd
# from datetime import datetime
# from tqdm import tqdm

# # === CONFIG ===
# CHUNK_SIZE = 1000  #  Best for low memory machines (adjust only if needed)
# TIME_TOLERANCE = 3

# BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
# GTFS_FOLDER = os.path.join(BASE_DIR, "backend", "gtfs_data")
# DATASET_FOLDER = os.path.join(BASE_DIR, "datasets")
# OUTPUT_FOLDER = os.path.join(BASE_DIR, "processed_with_route")
# UNMATCHED_LOG = os.path.join(OUTPUT_FOLDER, "unmatched_log.txt")

# # === RESET OUTPUT FOLDER ===
# if os.path.exists(OUTPUT_FOLDER):
#     shutil.rmtree(OUTPUT_FOLDER)
# os.makedirs(OUTPUT_FOLDER, exist_ok=True)
# # 
# # === LOAD GTFS FILES ===
# print(f" Loading GTFS files from: {GTFS_FOLDER}")
# stop_times_df = pd.read_csv(os.path.join(GTFS_FOLDER, "stop_times.txt"), low_memory=False)
# trips_df = pd.read_csv(os.path.join(GTFS_FOLDER, "trips.txt"), low_memory=False)
# routes_df = pd.read_csv(os.path.join(GTFS_FOLDER, "routes.txt"), low_memory=False)

# trip_to_route = trips_df.set_index("trip_id")["route_id"].to_dict()
# route_to_name = routes_df.set_index("route_id")["route_long_name"].to_dict()

# stop_times_df["departure_minutes"] = stop_times_df["departure_time"].str.split(":").apply(
#     lambda x: int(x[0]) * 60 + int(x[1]) if len(x) >= 2 and x[0].isdigit() else -1
# )
# stop_times_df["stop_sequence"] = pd.to_numeric(stop_times_df["stop_sequence"], errors="coerce")
# stop_times_df.dropna(subset=["stop_sequence"], inplace=True)

# stop_times_dict = {stop_id: group.copy() for stop_id, group in stop_times_df.groupby("stop_id")}

# # === UTIL FUNCTIONS ===
# def time_to_minutes(t):
#     try:
#         h, m = map(int, str(t).split(":")[:2])
#         return h * 60 + m
#     except:
#         return None

# def encode_capacity_bucket(value):
#     return {
#         "MANY_SEATS_AVAILABLE": 0,
#         "FEW_SEATS_AVAILABLE": 1,
#         "STANDING_ROOM_ONLY": 2,
#         "CRUSH_CAPACITY": 3
#     }.get(value, -1)

# memo_cache = {}

# def get_matched_route(stop_id, timetable_time):
#     key = (stop_id, timetable_time)
#     if key in memo_cache:
#         return memo_cache[key]

#     target_min = time_to_minutes(timetable_time)
#     group = stop_times_dict.get(str(stop_id))

#     if target_min is None or group is None or group.empty:
#         memo_cache[key] = (None, None)
#         return None, None

#     try:
#         candidates = group[
#             (group["departure_minutes"] >= target_min - TIME_TOLERANCE) &
#             (group["departure_minutes"] <= target_min + TIME_TOLERANCE)
#         ]
#         if not candidates.empty:
#             closest_row = candidates.loc[candidates["stop_sequence"].idxmin()]
#         else:
#             group["abs_diff"] = (group["departure_minutes"] - target_min).abs()
#             closest_row = group.loc[group["abs_diff"].idxmin()]

#         trip_id = closest_row["trip_id"]
#         route_id = trip_to_route.get(trip_id)
#         route_name = route_to_name.get(route_id)
#         result = (route_id, route_name)
#         memo_cache[key] = result
#         return result
#     except:
#         memo_cache[key] = (None, None)
#         return None, None

# # === MAIN PROCESSOR ===
# total_rows, total_matched, total_unmatched = 0, 0, 0
# unmatched_ids = []

# def process_file(file_path, output_path):
#     global total_rows, total_matched, total_unmatched, unmatched_ids
#     print(f"\n Processing: {os.path.basename(file_path)}")
#     first_write = True

#     for chunk in pd.read_csv(file_path, chunksize=CHUNK_SIZE, low_memory=False):
#         processed_rows = []

#         for i, row in chunk.iterrows():
#             if i % 100 == 0:
#                 print(f"   ↪ Processed row {i}...")

#             route_id, route_name = get_matched_route(row["TRANSIT_STOP"], row["TIMETABLE_TIME"])
#             encoded_bucket = encode_capacity_bucket(row["CAPACITY_BUCKET"])

#             row_data = row.to_dict()
#             row_data["datasetrouteid"] = row_data["ROUTE"]
#             row_data["ROUTE"] = route_id
#             row_data["matched_route_name"] = route_name
#             row_data["CAPACITY_BUCKET_ENCODED"] = encoded_bucket

#             processed_rows.append(row_data)

#             if route_name is None:
#                 unmatched_ids.append(row["TRANSIT_STOP"])

#         df_out = pd.DataFrame(processed_rows)
#         matched = df_out["matched_route_name"].notna().sum()
#         unmatched = len(df_out) - matched

#         total_rows += len(df_out)
#         total_matched += matched
#         total_unmatched += unmatched

#         df_out.to_csv(output_path, mode='w' if first_write else 'a', header=first_write, index=False)
#         first_write = False

#     print(f" Saved: {output_path}")

# # === EXECUTION ===
# start_time = datetime.now()
# print(f"\n Scanning dataset folder: {DATASET_FOLDER}\n")
# csv_files = [f for f in os.listdir(DATASET_FOLDER) if f.endswith(".csv")]

# for file_name in tqdm(csv_files, desc=" Files"):
#     input_path = os.path.join(DATASET_FOLDER, file_name)
#     output_path = os.path.join(OUTPUT_FOLDER, file_name)
#     process_file(input_path, output_path)

# # Save unmatched stop IDs
# with open(UNMATCHED_LOG, "w") as f:
#     for stop_id in unmatched_ids:
#         f.write(f"{stop_id}\n")

# # Final Summary
# percent = (total_matched / total_rows) * 100 if total_rows > 0 else 0
# print(f"\n Summary:")
# print(f"    Matched route names : {total_matched}")
# print(f"    Unmatched (N/A)      : {total_unmatched}")
# print(f"    Match %%              : {percent:.2f}%")
# print(f"    Log file saved to     : {UNMATCHED_LOG}")
# print(f"\n Completed in: {datetime.now() - start_time}")
