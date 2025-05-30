import os
import zipfile
import requests
import shutil

def download_and_unzip_force():
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
    data_dir = os.path.join(base_dir, "processed_with_route")

    # Remove processed_with_route folder if it exists
    if os.path.exists(data_dir):
        print("Deleting existing processed_with_route folder...")
        shutil.rmtree(data_dir)

    os.makedirs(data_dir, exist_ok=True)

    zip_links = [
        (
            "https://www.dropbox.com/scl/fi/u7lhkba3ickjkap9ho3yb/processed_with_route_part_1.zip?rlkey=d5v5jfewufezy7k7hkvgkdpie&st=xyfu6cu1&dl=1",
            "processed_with_route_part_1.zip"
        ),
        (
            "https://www.dropbox.com/scl/fi/j8vzvdb239o2cfvhlxh05/processed_with_route_part_2.zip?rlkey=97u1ojfi83f83rhvwjggjojc9&st=db4ogm8p&dl=1",
            "processed_with_route_part_2.zip"
        ),
        (
            "https://www.dropbox.com/scl/fi/yb2melgf06yihaxu6dryp/processed_with_route_part_3.zip?rlkey=z6xi5eqi91eu77sjnag6nowqx&st=dv3q3koy&dl=1",
            "processed_with_route_part_3.zip"
        ),
    ]

    for url, name in zip_links:
        zip_path = os.path.join(data_dir, name)

        print(f"Downloading {name}...")
        response = requests.get(url, headers={"User-Agent": "Mozilla/5.0"})
        if response.status_code != 200:
            raise Exception(f"Failed to download {name}: {response.status_code}")
        with open(zip_path, "wb") as f:
            f.write(response.content)

        print(f"Extracting {name}...")
        with zipfile.ZipFile(zip_path, "r") as zip_ref:
            zip_ref.extractall(data_dir)

        os.remove(zip_path)

    print("All processed_with_route CSVs freshly downloaded and extracted.")
