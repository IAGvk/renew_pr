import os, requests
from dotenv import load_dotenv
load_dotenv()

BASE = os.getenv("PVGIS_BASE", "https://re.jrc.ec.europa.eu/api")
LAT = os.getenv("SITE_LAT"); LON = os.getenv("SITE_LON")
ROOT = "data/raw/pvgis"

def main():
    os.makedirs(ROOT, exist_ok=True)
    url = f"{BASE}/hourly"
    params = {
        "lat": LAT, "lon": LON,
        "startyear": 2020, "endyear": 2020,
        "components": 1, "format": "csv"
    }
    r = requests.get(url, params=params, timeout=60)
    r.raise_for_status()
    out = os.path.join(ROOT, "pvgis_hourly_2020.csv")
    with open(out, "wb") as f:
        f.write(r.content)
    print(f"Saved: {out}")

if __name__ == "__main__":
    main()