import sys
import os
import json
import pandas as pd
from dotenv import load_dotenv
from etl.utils.db import get_seed_ids, upsert_inverter_timeseries

load_dotenv()


def _find_col(df, *patterns):
    """Return first column whose name contains any of the given substrings (case-insensitive)."""
    cols_lower = {c.lower(): c for c in df.columns}
    for pat in patterns:
        for lower, orig in cols_lower.items():
            if pat in lower:
                return orig
    return None


def main(path):
    site_id, inv_id = get_seed_ids()
    df = pd.read_csv(path)

    # Detect datetime column — covers standard names + PVDAQ's 'measured_on'
    dt_candidates = [
        c for c in df.columns
        if c.lower() in ("datetime", "time", "timestamp", "ts", "date_time", "measured_on")
    ]
    if not dt_candidates:
        raise RuntimeError(
            f"No datetime-like column found. Columns: {list(df.columns)}"
        )
    dt_col = dt_candidates[0]
    df["ts"] = pd.to_datetime(df[dt_col], utc=True, errors="coerce")

    # Flexible column mapping: exact name first, then substring fallback (for PVDAQ etc.)
    energy_col   = _find_col(df, "energy_wh")
    power_col    = _find_col(df, "power_w", "ac_power", "dc_power")
    voltage_col  = _find_col(df, "dc_voltage_v", "dc_pos_voltage", "dc_voltage")
    current_col  = _find_col(df, "dc_current_a", "dc_pos_current", "dc_current")
    temp_col     = _find_col(df, "temperature_c", "inverter_temp", "module_temp_1", "ambient_temp")

    def safe_int(val):
        try:
            v = float(val)
            return None if v < -9000 else int(v)  # PVDAQ uses -99999 as NaN sentinel
        except (TypeError, ValueError):
            return None

    def safe_float(val):
        try:
            v = float(val)
            return None if v < -9000 else v
        except (TypeError, ValueError):
            return None

    rows = []
    for _, r in df.iterrows():
        if pd.isna(r["ts"]):
            continue
        rows.append({
            "site_id": site_id,
            "equipment_id": inv_id,
            "ts": r["ts"].to_pydatetime(),
            "energy_wh":   safe_int(r[energy_col])   if energy_col  else None,
            "power_w":     safe_int(r[power_col])     if power_col   else None,
            "dc_voltage_v": safe_float(r[voltage_col]) if voltage_col else None,
            "dc_current_a": safe_float(r[current_col]) if current_col else None,
            "temperature_c": safe_float(r[temp_col])  if temp_col    else None,
            "source_meta": json.dumps({"source_path": path, "dt_col": dt_col}),
        })
    if rows:
        upsert_inverter_timeseries(rows)
        print(f"Upserted {len(rows)} rows from {path}")
    else:
        print("No rows parsed.")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: load_inverter_csv.py <path_to_csv>")
        sys.exit(1)
    main(sys.argv[1])
