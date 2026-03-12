import os
import requests

ROOT = "data/raw/pv_iv_el"

# Source: https://catalog.data.gov/dataset/photovoltaic-module-current-voltage-and-electroluminescence-image-data-pv-iv-el
# Files are hosted on OpenEI (data.openei.org/submissions/8378)
EL_URL = "https://data.openei.org/files/8378/EL.zip"
IV_URL = "https://data.openei.org/files/8378/IV.zip"


def fetch(url, out):
    r = requests.get(url, timeout=180)
    r.raise_for_status()
    with open(out, "wb") as f:
        f.write(r.content)
    print(f"Saved: {out}")


def main():
    os.makedirs(ROOT, exist_ok=True)
    fetch(EL_URL, os.path.join(ROOT, "EL_Data.zip"))
    fetch(IV_URL, os.path.join(ROOT, "IV_Data.zip"))


if __name__ == "__main__":
    main()
