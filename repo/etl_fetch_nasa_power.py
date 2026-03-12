import os, requests, datetime as dt
from dotenv import load_dotenv
load_dotenv()

BASE = os.getenv("NASA_POWER_BASE", "https://power.larc.nasa.gov")
LAT = os.getenv("SITE_LAT"); LON = os.getenv("SITE_LON")
ROOT = "data/raw/nasa_power"

def main():
    os.makedirs(ROOT, exist_ok=True)
    end = dt.date.today() - dt.timedelta(days=1)
    start = end - dt.timedelta(days=7)
    params = {
        "latitude": LAT, "longitude": LON,
        "start": start.strftime("%Y%m%d"),
        "end": end.strftime("%Y%m%d"),
        "parameters": "ALLSKY_SFC_SW_DWN,T2M,WS10M",
        "community": "RE",
        "format": "CSV",
        "temporal": "HOURLY"
    }
    url = f"{BASE}/api/temporal/hourly/point"
    r = requests.get(url, params=params, timeout=60)
    r.raise_for_status()
    out = os.path.join(ROOT, "nasa_power_hourly.csv")
    with open(out, "wb") as f:
        f.write(r.content)
    print(f"Saved: {out}")

if __name__ == "__main__":
    main()