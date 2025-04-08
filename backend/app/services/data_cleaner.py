import os
import pandas as pd
import glob

def encode_capacity_bucket(value):
    return {
        "MANY_SEATS_AVAILABLE": 0,
        "FEW_SEATS_AVAILABLE": 1,
        "STANDING_ROOM_ONLY": 2,
        "CRUSH_CAPACITY": 3
    }.get(value, -1)

def clean_chunk(chunk):
    # Replace bad/missing TRIP_POINT values
    chunk["TRIP_POINT"] = chunk.get("TRIP_POINT", "Unknown").fillna("Unknown").replace("N/A", "Unknown")

    # Encode CAPACITY_BUCKET
    chunk["CAPACITY_BUCKET_ENCODED"] = chunk["CAPACITY_BUCKET"].apply(encode_capacity_bucket)

    # Skip parsing time to save memory, only drop missing columns
    chunk.dropna(subset=["ROUTE", "CAPACITY_BUCKET", "TIMETABLE_HOUR_BAND"], inplace=True)
    chunk.drop_duplicates(inplace=True)

    return chunk

def clean_and_save_all():
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../.."))
    raw_folder = os.path.join(base_dir, "datasets")
    output_folder = os.path.join(base_dir, "processed")
    os.makedirs(output_folder, exist_ok=True)

    files = sorted(glob.glob(os.path.join(raw_folder, "*.csv")))
    total_files = len(files)

    print(f"Found {total_files} CSV files to process in: {raw_folder}")

    for idx, file in enumerate(files, 1):
        print(f"[{idx}/{total_files}] Processing {os.path.basename(file)}...")

        try:
            # Output file path
            output_file = os.path.join(output_folder, os.path.basename(file))

            # If the output file exists from previous runs, remove it
            if os.path.exists(output_file):
                os.remove(output_file)

            # Process in chunks
            chunk_iter = pd.read_csv(
                file,
                dtype=str,
                chunksize=10000,
                usecols=lambda col: col in ["ROUTE", "CAPACITY_BUCKET", "TRIP_POINT", "TIMETABLE_TIME", "ACTUAL_TIME", "TIMETABLE_HOUR_BAND"]
            )

            for chunk_num, chunk in enumerate(chunk_iter, 1):
                cleaned = clean_chunk(chunk)

                # Append mode, no header if not first chunk
                cleaned.to_csv(output_file, mode='a', index=False, header=not os.path.exists(output_file))
                print(f" - Chunk {chunk_num} cleaned and written.")

            print(" - Done")

        except Exception as e:
            print(f" - Failed to process {file}: {e}")

    print("Cleaning complete.")
