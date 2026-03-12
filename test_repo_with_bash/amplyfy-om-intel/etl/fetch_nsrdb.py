import os
import requests
from dotenv import load_dotenv

load_dotenv()

API = "https://developer.nrel.gov/api/nsrdb/v2/solar/nsrdb-GOES-aggregated-v4-0-0-download.csv"
LAT = os.getenv("SITE_LAT")
LON = os.getenv("SITE_LON")
KEY = os.getenv("NREL_API_KEY")
EMAIL = os.getenv("NREL_API_EMAIL")
ROOT = "data/raw/nsrdb"


def main():
    if not KEY or not EMAIL:
        print("NSRDB skipped: set NREL_API_KEY and NREL_API_EMAIL in .env")
        return
    if not LAT or not LON:
        raise RuntimeError("SITE_LAT and SITE_LON must be set")
    os.makedirs(ROOT, exist_ok=True)
    params = {
        "wkt": f"POINT({LON} {LAT})",
        "names": 2020,
        "interval": 60,
        "api_key": KEY,
        "email": EMAIL,
    }
    r = requests.get(API, params=params, timeout=180)
    r.raise_for_status()
    out = os.path.join(ROOT, "nsrdb_2020_hourly.csv")
    with open(out, "wb") as f:
        f.write(r.content)
    print(f"Saved: {out}")


if __name__ == "__main__":
    main()
