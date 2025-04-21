import os
import zipfile
import requests

def download_and_unzip_if_needed():
    root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
    data_dir = os.path.join(root_dir, "processed")
    zip_path = os.path.join(root_dir, "processed.zip")

    if not os.path.exists(data_dir):
        os.makedirs(data_dir)

    has_csv = any(file.endswith(".csv") for file in os.listdir(data_dir)) if os.path.exists(data_dir) else False
    if has_csv:
        print("Processed folder already ready.")
        return

    print("Downloading processed.zip from Dropbox...")

    url = "https://www.dropbox.com/scl/fi/hzyp6el8mjjhuro62qvsu/processed.zip?rlkey=a5cxvovq1dxewhgllv9tmqyyz&st=pbj50rtw&dl=1"
    headers = { "User-Agent": "Mozilla/5.0" }
    response = requests.get(url, headers=headers)

    if response.status_code != 200:
        raise Exception(f"Failed to download ZIP: {response.status_code} - {response.text}")

    with open(zip_path, "wb") as f:
        f.write(response.content)

    print("Extracting processed.zip...")
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        for member in zip_ref.infolist():
            filename = os.path.basename(member.filename)
            if not filename.endswith(".csv") or not filename:
                continue
            with zip_ref.open(member) as source:
                with open(os.path.join(data_dir, filename), "wb") as target:
                    target.write(source.read())

    os.remove(zip_path)
    print("Extraction complete. Processed files are ready.")
