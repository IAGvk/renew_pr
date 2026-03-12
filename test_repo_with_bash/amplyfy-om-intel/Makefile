.PHONY: db.migrate db.seed fetch.all fetch.pvdaq fetch.pv_iv_el fetch.nasa_power fetch.pvgis fetch.nsrdb fetch.oam load.sample

VENV=.venv/bin
PY=$(VENV)/python
PSQL=psql
export PYTHONPATH := $(CURDIR)

db.migrate:
	$(PSQL) -d $$DATABASE_URL -f db/migrations/001_init.sql

db.seed:
	$(PSQL) -d $$DATABASE_URL -f db/migrations/002_seed.sql

fetch.pvdaq:
	$(PY) etl/fetch_pvdaq.py

fetch.pv_iv_el:
	$(PY) etl/fetch_pv_iv_el.py

fetch.nasa_power:
	$(PY) etl/fetch_nasa_power.py

fetch.pvgis:
	$(PY) etl/fetch_pvgis.py

fetch.nsrdb:
	$(PY) etl/fetch_nsrdb.py

fetch.oam:
	$(PY) etl/fetch_oam.py

fetch.all: fetch.pvdaq fetch.pv_iv_el fetch.nasa_power fetch.pvgis fetch.oam
	@echo "NSRDB optional; run 'make fetch.nsrdb' if API key is set."

load.sample:
	$(PY) etl/load_inverter_csv.py data/raw/pvdaq/sample_timeseries.csv
	$(PY) etl/load_artifact.py data/raw/oam/sample_rgb_ortho.tif rgb_ortho
