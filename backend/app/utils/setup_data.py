import os
import zipfile
import requests

def download_and_unzip_if_needed():
    # Set the target data directory to project root level /processed
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
    data_dir = os.path.join(base_dir, "processed")
    os.makedirs(data_dir, exist_ok=True)

    zip_links = [
        (
            "https://www.dropbox.com/scl/fi/l71i9y8x57idx87677rux/processed_part1.zip?rlkey=2hcrx73jslud8ltm57g8p6jkr&st=np3l4x6e&dl=1",
            "processed_part1.zip"
        ),
        (
            "https://www.dropbox.com/scl/fi/vdbtx1e233lwilz99k04c/processed_part2.zip?rlkey=7b6w4x89a0aqnmjl9j9v7vk8s&st=t9sj002u&dl=1",
            "processed_part2.zip"
        ),
        (
            "https://www.dropbox.com/scl/fi/kzm26ihazvvrhpqmtfcyk/processed_part3.zip?rlkey=s0kx1gxgx62zlbdjabp0x5wu9&st=amnjgj6s&dl=1",
            "processed_part3.zip"
        ),
    ]

    already_ready = any(f.endswith(".csv") for f in os.listdir(data_dir))
    if already_ready:
        print("Processed folder already ready.")
        return

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

    print("All processed CSVs extracted to project root /processed folder.")
