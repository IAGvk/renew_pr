import os
import requests
from dotenv import load_dotenv

load_dotenv()

OAM = os.getenv("OAM_API_BASE", "https://api.openaerialmap.org")
LAT = float(os.getenv("SITE_LAT", "-33.870"))
LON = float(os.getenv("SITE_LON", "151.205"))
ROOT = "data/raw/oam"


def bbox(lat, lon, size_deg=0.01):
    return [lon - size_deg, lat - size_deg, lon + size_deg, lat + size_deg]


def main():
    os.makedirs(ROOT, exist_ok=True)
    bb = ",".join(map(str, bbox(LAT, LON)))
    url = f"{OAM}/meta?bbox={bb}&limit=1"
    r = requests.get(url, timeout=120)
    r.raise_for_status()
    data = r.json()
    if not data.get("results"):
        print("No OAM imagery found near bbox; try increasing bbox size.")
        return
    item = data["results"][0]
    # OAM: uuid field is the direct download URL for the full-res image
    download_url = item.get("uuid") or item.get("thumbnail")
    if not download_url:
        print("No download URL found in OAM result.")
        return
    out = os.path.join(ROOT, "sample_rgb_ortho.tif")
    if download_url.lower().endswith((".jpg", ".jpeg", ".png")):
        out = os.path.join(ROOT, "sample_rgb_ortho.jpg")
    print(f"Downloading: {download_url}")
    r = requests.get(download_url, timeout=300, stream=True)
    r.raise_for_status()
    with open(out, "wb") as f:
        for chunk in r.iter_content(chunk_size=8192):
            f.write(chunk)
    print(f"Saved: {out}")


if __name__ == "__main__":
    main()
