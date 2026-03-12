import os
import requests
from dotenv import load_dotenv

load_dotenv()

BASE = os.getenv("PVGIS_BASE", "https://re.jrc.ec.europa.eu/api/v5_3")
LAT = os.getenv("SITE_LAT")
LON = os.getenv("SITE_LON")
ROOT = "data/raw/pvgis"


def main():
    if not LAT or not LON:
        raise RuntimeError("SITE_LAT and SITE_LON must be set")
    os.makedirs(ROOT, exist_ok=True)
    # seriescalc = hourly radiation series; outputformat replaces old 'format' param
    url = f"{BASE}/seriescalc"
    params = {
        "lat": LAT,
        "lon": LON,
        "startyear": 2020,
        "endyear": 2020,
        "components": 1,
        "outputformat": "csv",
    }
    r = requests.get(url, params=params, timeout=120)
    r.raise_for_status()
    out = os.path.join(ROOT, "pvgis_hourly_2020.csv")
    with open(out, "wb") as f:
        f.write(r.content)
    print(f"Saved: {out}")


if __name__ == "__main__":
    main()
