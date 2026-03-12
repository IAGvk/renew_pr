import os, requests

ROOT = "data/raw/pv_iv_el"
EL_URL = "https://catalog.data.gov/dataset/photovoltaic-module-current-voltage-and-electroluminescence-image-data-pv-iv-el/resource/4b7f6b31-6e6d-4b5b-86b2-1a0e40dbd879/download/el-data.zip"
IV_URL = "https://catalog.data.gov/dataset/photovoltaic-module-current-voltage-and-electroluminescence-image-data-pv-iv-el/resource/6d9e7f6e-6d3f-4dd2-9e0d-21ef1fe6b614/download/iv-data.zip"

def fetch(url, out):
    r = requests.get(url, timeout=120)
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