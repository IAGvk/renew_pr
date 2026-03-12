import sys, os, pandas as pd, json
from dotenv import load_dotenv
from etl.utils.db import get_conn, get_seed_ids, upsert_inverter_timeseries
load_dotenv()

def main(path):
    site_id, inv_id = get_seed_ids()
    df = pd.read_csv(path)
    # Heuristic: try to infer columns; adjust for PVDAQ/NSRDB/POWER formats as needed
    # Expect a datetime column named 'datetime' or similar; transform to UTC ISO
    dt_col = next((c for c in df.columns if c.lower() in ("datetime","time","timestamp","ts")), None)
    if not dt_col: raise RuntimeError("No datetime column found")
    df["ts"] = pd.to_datetime(df[dt_col], utc=True, errors="coerce")
    rows = []
    for _,r in df.iterrows():
        if pd.isna(r["ts"]): continue
        rows.append({
          "site_id": site_id,
          "equipment_id": inv_id,
          "ts": r["ts"].to_pydatetime(),
          "energy_wh": int(r.get("energy_wh", 0)) if "energy_wh" in df.columns else None,
          "power_w": int(r.get("power_w", 0)) if "power_w" in df.columns else None,
          "dc_voltage_v": float(r.get("dc_voltage_v", "nan")) if "dc_voltage_v" in df.columns else None,
          "dc_current_a": float(r.get("dc_current_a", "nan")) if "dc_current_a" in df.columns else None,
          "temperature_c": float(r.get("temperature_c", "nan")) if "temperature_c" in df.columns else None,
          "source_meta": json.dumps({"source_path": path})
        })
    if rows:
        upsert_inverter_timeseries(rows)
        print(f"Upserted {len(rows)} rows from {path}")
    else:
        print("No rows parsed.")

if __name__=="__main__":
    if len(sys.argv)<2: 
        print("Usage: load_inverter_csv.py <path_to_csv>")
        sys.exit(1)
    main(sys.argv[1])