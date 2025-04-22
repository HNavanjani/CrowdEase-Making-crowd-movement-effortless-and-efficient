import os
import zipfile
import requests
import shutil

def download_and_unzip_force():
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
    data_dir = os.path.join(base_dir, "processed")

    # Remove processed folder if it exists
    if os.path.exists(data_dir):
        print("Deleting existing processed folder...")
        shutil.rmtree(data_dir)

    os.makedirs(data_dir, exist_ok=True)

    zip_links = [
        (
            "https://www.dropbox.com/scl/fi/0hoofh8zshqnos4hq2959/processed_part1.zip?rlkey=s8whew84ybgj0o3qfa0t4jden&st=cyuit38z&dl=1",
            "processed_part1.zip"
        ),
        (
            "https://www.dropbox.com/scl/fi/495g6685yzvzf4ohhgiqn/processed_part2.zip?rlkey=0o3cy0rmng9g89z4vd3po83gl&st=emd7cnlp&dl=1",
            "processed_part2.zip"
        ),
        (
            "https://www.dropbox.com/scl/fi/33q5slggs3q9vez52bcle/processed_part3.zip?rlkey=zlbq9j87g79u7uxp2df6sncpz&st=fro5sgzy&dl=1",
            "processed_part3.zip"
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

    print("All processed CSVs freshly downloaded and extracted.")
