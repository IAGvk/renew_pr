import os, requests, json
from dotenv import load_dotenv
load_dotenv()

OAM = os.getenv("OAM_API_BASE","https://api.openaerialmap.org")
LAT = float(os.getenv("SITE_LAT")); LON = float(os.getenv("SITE_LON"))
ROOT = "data/raw/oam"

def bbox(lat, lon, size_deg=0.01):
    return [lon-size_deg, lat-size_deg, lon+size_deg, lat+size_deg]

def main():
    os.makedirs(ROOT, exist_ok=True)
    bb = ",".join(map(str, bbox(LAT, LON)))
    url = f"{OAM}/meta?bbox={bb}&limit=1"
    r = requests.get(url, timeout=60)
    r.raise_for_status()
    data = r.json()
    if not data.get("results"):
        print("No OAM imagery found near bbox; try increasing size.")
        return
    item = data["results"][0]
    # Prefer GeoTIFF if available; otherwise grab the first tile URL
    out = os.path.join(ROOT, "sample_rgb_ortho.tif")
    gti = None
    for prov in item.get("properties", {}).get("files", []):
        if prov.get("type","").lower() in ("geotiff","geotif","tif","tiff"):
            gti = prov.get("href"); break
    if not gti:
        # fall back to thumbnail/tiles if needed
        gti = item["properties"]["thumbnail"]
        out = os.path.join(ROOT, "sample_rgb_ortho.jpg")
    print(f"Downloading: {gti}")
    r = requests.get(gti, timeout=180)
    r.raise_for_status()
    with open(out,"wb") as f: f.write(r.content)
    print(f"Saved: {out}")

if __name__ == "__main__":
    main()