#!/usr/bin/env bash
set -euo pipefail

python etl/fetch_pvdaq.py
python etl/fetch_pv_iv_el.py
python etl/fetch_nasa_power.py
python etl/fetch_pvgis.py
python etl/fetch_oam.py
echo "If NSRDB key is set, fetching NSRDB..."
python etl/fetch_nsrdb.py || true

# Load a small PV time-series and one orthomosaic (if present)
if [ -f data/raw/pvdaq/sample_timeseries.csv ]; then
  python etl/load_inverter_csv.py data/raw/pvdaq/sample_timeseries.csv
fi
if [ -f data/raw/oam/sample_rgb_ortho.tif ]; then
  python etl/load_artifact.py data/raw/oam/sample_rgb_ortho.tif rgb_ortho
fi