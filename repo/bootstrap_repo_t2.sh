#```bash
#chmod +x bootstrap_repo.sh
#bash bootstrap_repo.sh
#```

#!/usr/bin/env bash
set -euo pipefail

REPO="amplyfy-om-intel"
mkdir -p "$REPO"
cd "$REPO"

# ---------- Root files ----------
cat > README.md <<'EOF'
# Amplyfy O&M Intelligence – Open Data Test Rig

**Purpose:** A ready-to-run repository to validate the full data path for our combined **O&M Prioritization + C&I/Rooftop Intelligence** product **before any client data**.  
It includes schema migrations, ETL scripts for **open datasets**, and loaders to populate the DB for smoke tests.

**Datasets used (all openly available):**
- **PVDAQ** – PV performance time-series & metadata (OEDI S3; CSV/Parquet). Useful to populate `inverter_telemetry`.  
- **PV‑IV‑EL** – 613 paired IV curves + EL images (Sandia). Useful to test `iv_curve*` ingestion and EL artifact linkage.  
- **NASA POWER** – global irradiance & weather (hourly/daily/monthly via REST; no key). Populate `weather_snapshot` & QC normalization.  
- **NSRDB** – irradiance (US + some regions). API (key required) and open S3 buckets. Use for higher‑frequency irradiance backfills.  
- **PVGIS** – JRC APIs for solar radiation & PV performance worldwide. Another normalization/reference input.  
- **ERA5** *(optional)* – global hourly reanalysis from Copernicus CDS; free key required for API. Useful for weather backfills.  
- **OpenAerialMap (OAM)** – open orthomosaics to validate imagery ingestion & CRS georeferencing (not always solar, but ideal for pipeline smoke‑tests).

**Thermal/photogrammetry QC rules** (for capture validation & `qc_flag`): ensure adequate **irradiance**, set **emissivity**, confirm modules **under load**, and maintain **overlap/GSD**—derived from industry guidance.

---

## Quickstart

```bash
# 1) Python env
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# 2) Database (PostgreSQL + PostGIS). Set DATABASE_URL in .env
cp .env.example .env   # edit values

# 3) Create schema & seed pilot site/inverter
make db.migrate
make db.seed

# 4) Pull open datasets & load a small sample
make fetch.all        # PVDAQ, PV-IV-EL, NASA POWER, PVGIS, OAM (NSRDB if you run fetch.nsrdb)
make load.sample      # loads a sample PV time-series + registers sample ortho artifact
````

> **Note:** NSRDB API requires a free key + email. If you don’t set one, the NSRDB fetch step will be skipped.

***

## Environment

Copy `.env.example` → `.env` and fill values:

*   `DATABASE_URL` — e.g., `postgresql://postgres:postgres@localhost:5432/amplyfy`
*   `SITE_LAT`, `SITE_LON`, `SITE_TZ` — seed site location & timezone
*   `NREL_API_KEY`, `NREL_API_EMAIL` — (optional) for NSRDB API
*   `CDS_API_URL`, `CDS_API_KEY` — (optional) for ERA5 via CDS

***

## Mermaid ER Diagram



> This schema targets **v1 → v2** and is forward‑compatible with **v3 O&M digital twin light**.

***

## Make Targets

*   `make db.migrate` → run schema DDL
*   `make db.seed` → seed 1 org/site/inverter + ROI settings
*   `make fetch.all` → PVDAQ, PV‑IV‑EL, NASA POWER, PVGIS, OAM (NSRDB separate)
*   `make fetch.nsrdb` → only if `NREL_API_KEY` & email set
*   `make load.sample` → load PVDAQ sample CSV into `inverter_telemetry` + register sample RGB ortho

***

## Roadmap

*   Wire **ΔMWh/$** calculators → `impact_estimate`
*   Agentic **prioritizer** → `priority_queue`
*   Work order integrations (Jira/ServiceNow) via webhooks

EOF

cat > .env.example <<'EOF'

# Database

DATABASE_URL=postgresql://postgres:postgres@localhost:5432/amplyfy

# Site defaults (seed)

SITE_NAME=Pilot C&I Rooftop
SITE_LAT=-33.870
SITE_LON=151.205
SITE_TZ=Australia/Sydney

# APIs

# NSRDB (optional; API key + email)

NREL_API_KEY=tRMfLF9wdFpkOTY9flnqJJg0EtdzK4w1Y5TnUtdV
NREL_API_EMAIL=learnervk7@gmail.com 

# NASA POWER (no key)

NASA_POWER_BASE=<https://power.larc.nasa.gov>

# PVGIS (no key)

PVGIS_BASE=<https://re.jrc.ec.europa.eu/api>

# Copernicus CDS (optional)

CDS_API_URL=<https://cds.climate.copernicus.eu/api/v2>
CDS_API_KEY=

# OpenAerialMap

OAM_API_BASE=<https://api.openaerialmap.org>
EOF

cat > requirements.txt <<'EOF'
boto3==1.34.34
botocore==1.34.34
requests==2.31.0
pandas==2.2.1
python-dateutil==2.9.0
python-dotenv==1.0.1
psycopg2-binary==2.9.9
geopandas==0.14.3
shapely==2.0.3
rasterio==1.3.9
fiona==1.9.6
EOF

cat > Makefile <<'EOF'
.PHONY: db.migrate db.seed fetch.all fetch.pvdaq fetch.pv_iv_el fetch.nasa_power fetch.pvgis fetch.nsrdb fetch.oam load.sample

VENV=.venv/bin
PY=$(VENV)/python
PSQL=psql

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
EOF

# ---------- DB Migrations ----------

mkdir -p db/migrations

cat > db/migrations/001_init.sql <<'EOF'
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE org (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
name text NOT NULL,
country_code char(2),
created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE user_account (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
email citext UNIQUE NOT NULL,
full_name text,
password_hash text,
created_at timestamptz NOT NULL DEFAULT now(),
is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE org_user_role (
org_id uuid REFERENCES org(id) ON DELETE CASCADE,
user_id uuid REFERENCES user_account(id) ON DELETE CASCADE,
role text CHECK (role IN ('owner','admin','editor','viewer')),
PRIMARY KEY (org_id, user_id)
);

CREATE TABLE site (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
org_id uuid REFERENCES org(id) ON DELETE CASCADE,
name text NOT NULL,
dc_capacity_mw numeric(8,3) NOT NULL,
commissioning_date date,
timezone text,
centroid geography(point, 4326),
boundary geography(polygon, 4326),
address_line1 text,
city text,
state_region text,
country_code char(2),
created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_site_geom ON site USING gist(boundary);

CREATE TABLE array (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
site_id uuid REFERENCES site(id) ON DELETE CASCADE,
name text,
boundary geography(polygon, 4326),
tilt_deg numeric(5,2),
azimuth_deg numeric(6,2),
created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_array_geom ON array USING gist(boundary);

CREATE TABLE equipment (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
site_id uuid REFERENCES site(id) ON DELETE CASCADE,
type text CHECK (type IN ('inverter','combiner','tracker','transformer')),
make_model text,
serial_number text,
name text,
location geography(point, 4326),
created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_equipment_loc ON equipment USING gist(location);

CREATE TABLE ingestion_job (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
site_id uuid REFERENCES site(id) ON DELETE CASCADE,
kind text CHECK (kind IN ('rgb_ortho','thermal_ortho','pointcloud','report')),
requested_by uuid REFERENCES user_account(id),
status text CHECK (status IN ('queued','processing','complete','error')),
message text,
created_at timestamptz NOT NULL DEFAULT now(),
completed_at timestamptz
);

CREATE TABLE artifact (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
site_id uuid REFERENCES site(id) ON DELETE CASCADE,
kind text CHECK (kind IN ('rgb_ortho','thermal_ortho','flight_log','kml_worldfile','raw_frame_zip')),
storage_uri text NOT NULL,
checksum_sha256 text,
epsg int,
capture_started_at timestamptz,
capture_ended_at timestamptz,
created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE artifact_version (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
artifact_id uuid REFERENCES artifact(id) ON DELETE CASCADE,
pipeline_version text NOT NULL,
derived_uri text,
metadata_json jsonb,
created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE capture_metadata (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
artifact_id uuid REFERENCES artifact(id) ON DELETE CASCADE,
gsd_cm numeric(6,2),
overlap_front_pct numeric(5,2),
overlap_side_pct numeric(5,2),
emissivity numeric(4,3),
irradiance_wm2 numeric(7,2),
wind_ms numeric(5,2),
ambient_c numeric(5,2),
notes text,
qc_flags text[]
);

CREATE TABLE detection (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
site_id uuid REFERENCES site(id) ON DELETE CASCADE,
artifact_id uuid REFERENCES artifact(id) ON DELETE SET NULL,
type text CHECK (type IN ('SOILING','VEGETATION','HOTSPOT','CRACK','OTHER')),
confidence numeric(4,3) CHECK (confidence BETWEEN 0 AND 1),
geom geography(polygon, 4326),
stats_json jsonb,
created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_detection_geom ON detection USING gist(geom);

CREATE TABLE detection_cluster (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
site_id uuid REFERENCES site(id) ON DELETE CASCADE,
type text CHECK (type IN ('SOILING','VEGETATION','HOTSPOT')),
geom geography(polygon, 4326),
severity text CHECK (severity IN ('low','med','high')),
created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_detection_cluster_geom ON detection_cluster USING gist(geom);

CREATE TABLE impact_estimate (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
site_id uuid REFERENCES site(id) ON DELETE CASCADE,
detection_id uuid REFERENCES detection(id) ON DELETE CASCADE,
method_version text NOT NULL,
delta_mwh_year numeric(10,3) NOT NULL,
delta_value_year numeric(12,2) NOT NULL,
payback_months numeric(8,2),
assumptions_json jsonb,
created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE priority_queue (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
site_id uuid REFERENCES site(id) ON DELETE CASCADE,
detection_id uuid REFERENCES detection(id) ON DELETE CASCADE,
rank_score numeric(6,3),
rationale text,
status text CHECK (status IN ('proposed','scheduled','in_progress','done','deferred')),
created_at timestamptz NOT NULL DEFAULT now(),
updated_at timestamptz
);

CREATE TABLE work_order (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
site_id uuid REFERENCES site(id) ON DELETE CASCADE,
title text NOT NULL,
description text,
status text CHECK (status IN ('open','assigned','in_progress','complete','cancelled')),
planned_start timestamptz,
planned_end timestamptz,
created_at timestamptz NOT NULL DEFAULT now(),
updated_at timestamptz
);

CREATE TABLE work_order_item (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
work_order_id uuid REFERENCES work_order(id) ON DELETE CASCADE,
detection_id uuid REFERENCES detection(id) ON DELETE SET NULL,
action text CHECK (action IN ('CLEAN','TRIM_VEGETATION','REPAIR_STRING','INSPECT_MANUAL','REPLACE_MODULE')),
location geography(point, 4326),
estimate_hours numeric(6,2),
estimate_cost numeric(12,2),
created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_work_item_loc ON work_order_item USING gist(location);

CREATE TABLE inverter_telemetry (
site_id uuid NOT NULL REFERENCES site(id) ON DELETE CASCADE,
equipment_id uuid NOT NULL REFERENCES equipment(id) ON DELETE CASCADE,
ts timestamptz NOT NULL,
energy_wh bigint,
power_w bigint,
dc_voltage_v numeric(10,2),
dc_current_a numeric(10,2),
temperature_c numeric(6,2),
source_meta jsonb,
PRIMARY KEY (site_id, equipment_id, ts)
);
CREATE INDEX IF NOT EXISTS idx_inv_ts ON inverter_telemetry (site_id, ts DESC);

CREATE TABLE iv_curve (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
site_id uuid REFERENCES site(id) ON DELETE CASCADE,
equipment_id uuid REFERENCES equipment(id) ON DELETE SET NULL,
ts timestamptz NOT NULL,
method text CHECK (method IN ('SMART_IV','FIELD_TRACER','LAB')),
meta_json jsonb,
created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE iv_curve_point (
iv_curve_id uuid REFERENCES iv_curve(id) ON DELETE CASCADE,
idx int NOT NULL,
voltage_v numeric(10,3) NOT NULL,
current_a numeric(10,3) NOT NULL,
PRIMARY KEY (iv_curve_id, idx)
);

CREATE TABLE settings_roi (
site_id uuid PRIMARY KEY REFERENCES site(id) ON DELETE CASCADE,
currency text DEFAULT 'USD',
energy_price_per_mwh numeric(10,2),
labor_rate_per_hour numeric(10,2),
cleaning_cost_per_m2 numeric(10,2),
vegetation_cost_per_m2 numeric(10,2),
json_extras jsonb,
updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE calibration_baseline (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
site_id uuid REFERENCES site(id) ON DELETE CASCADE,
window_start date NOT NULL,
window_end date NOT NULL,
modeled_mwh numeric(12,3),
observed_mwh numeric(12,3),
scaling_factor numeric(6,4),
created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE weather_snapshot (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
site_id uuid REFERENCES site(id) ON DELETE CASCADE,
ts timestamptz NOT NULL,
source text,
ghi_wm2 numeric(8,2),
temp_c numeric(5,2),
wind_ms numeric(5,2),
cloud_okta numeric(3,1),
created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE qc_flag (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
artifact_id uuid REFERENCES artifact(id) ON DELETE CASCADE,
code text,
severity text CHECK (severity IN ('info','warn','fail')),
notes text,
created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE crew (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
org_id uuid REFERENCES org(id) ON DELETE CASCADE,
name text,
home_base geography(point, 4326),
created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_crew_home ON crew USING gist(home_base);

CREATE TABLE crew_shift (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
crew_id uuid REFERENCES crew(id) ON DELETE CASCADE,
shift_date date NOT NULL,
start_time_local time NOT NULL,
end_time_local time NOT NULL,
capacity_hours numeric(6,2),
created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE route_plan (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
crew_id uuid REFERENCES crew(id) ON DELETE CASCADE,
work_order_id uuid REFERENCES work_order(id) ON DELETE CASCADE,
planned_start timestamptz,
planned_end timestamptz,
route_geo geography(linestring, 4326),
created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_route_geo ON route_plan USING gist(route_geo);
EOF

cat > db/migrations/002_seed.sql <<'EOF'
INSERT INTO org (name, country_code) VALUES ('Amplyfy Pilot Org','AU');

INSERT INTO user_account (email, full_name, password_hash)
VALUES ('<ops@amplyfy.example>','Ops User','$2b$12$seedONLY');

INSERT INTO org_user_role (org_id, user_id, role)
SELECT o.id, u.id, 'owner'
FROM org o, user_account u
WHERE o.name='Amplyfy Pilot Org' AND u.email='<ops@amplyfy.example>';

INSERT INTO site (org_id, name, dc_capacity_mw, commissioning_date, timezone, centroid, boundary, address_line1, city, state_region, country_code)
SELECT o.id, 'Pilot C&I Rooftop', 3.000, '2020-03-01', 'Australia/Sydney',
ST_SetSRID(ST_MakePoint(151.205, -33.870),4326)::geography,
ST_GeogFromText('POLYGON((151.2045 -33.8696,151.2056 -33.8696,151.2056 -33.8704,151.2045 -33.8704,151.2045 -33.8696))'),
'123 George St','Sydney','NSW','AU'
FROM org o WHERE o.name='Amplyfy Pilot Org';

INSERT INTO equipment (site_id, type, make_model, serial_number, name, location)
SELECT s.id, 'inverter', 'SMA STP', 'SMA-INV-001', 'INV-1', s.centroid
FROM site s WHERE s.name='Pilot C&I Rooftop';

INSERT INTO settings_roi (site_id, currency, energy_price_per_mwh, labor_rate_per_hour, cleaning_cost_per_m2, vegetation_cost_per_m2, json_extras)
SELECT s.id, 'AUD', 140.00, 85.00, 0.45, 0.35, '{}'
FROM site s WHERE s.name='Pilot C&I Rooftop';

INSERT INTO artifact (site_id, kind, storage_uri, epsg, capture_started_at, capture_ended_at)
SELECT s.id, 'rgb_ortho',
'<https://api.openaerialmap.org/tiles/{oam_item_id}/0/0/0.png>',
3857, now()-interval '10 days', now()-interval '10 days' + interval '30 minutes'
FROM site s WHERE s.name='Pilot C&I Rooftop';

INSERT INTO artifact (site_id, kind, storage_uri, epsg, capture_started_at, capture_ended_at)
SELECT s.id, 'thermal_ortho',
's3://your-bucket/thermal/pilot_20240301_orthomosaic.tif',
3857, now()-interval '10 days', now()-interval '10 days' + interval '30 minutes'
FROM site s WHERE s.name='Pilot C&I Rooftop';

INSERT INTO capture_metadata (artifact_id, gsd_cm, overlap_front_pct, overlap_side_pct, emissivity, irradiance_wm2, wind_ms, ambient_c, notes, qc_flags)
SELECT a.id, 2.50, 75.0, 70.0, 0.95, 800.0, 2.5, 24.0, 'Daytime flight; radiometric; panel under load', ARRAY['OK']
FROM artifact a JOIN site s ON s.id=a.site_id
WHERE s.name='Pilot C&I Rooftop' AND a.kind='thermal_ortho';

INSERT INTO weather_snapshot (site_id, ts, source, ghi_wm2, temp_c, wind_ms, cloud_okta)
SELECT s.id, now()-interval '10 days', 'NASA_POWER', 780, 23.0, 2.0, 1.0
FROM site s WHERE s.name='Pilot C&I Rooftop';

INSERT INTO inverter_telemetry (site_id, equipment_id, ts, energy_wh, power_w, dc_voltage_v, dc_current_a, temperature_c, source_meta)
SELECT s.id, e.id, now()-interval '1 day', 1523400, 23000, 780.0, 30.5, 46.0, '{"source":"CSV_UPLOAD"}'::jsonb
FROM site s JOIN equipment e ON e.site_id=s.id
WHERE s.name='Pilot C&I Rooftop' AND e.name='INV-1';
EOF

# ---------- ETL ----------

mkdir -p etl/utils data/raw data/processed

cat > etl/utils/db.py <<'EOF'
import os
import psycopg2
from psycopg2.extras import execute_values

def get_conn():
url = os.getenv("DATABASE_URL")
if not url:
raise RuntimeError("DATABASE_URL not set")
return psycopg2.connect(url)

def upsert_inverter_timeseries(rows):
sql = """
INSERT INTO inverter_telemetry
(site_id, equipment_id, ts, energy_wh, power_w, dc_voltage_v, dc_current_a, temperature_c, source_meta)
VALUES %s
ON CONFLICT (site_id, equipment_id, ts)
DO UPDATE SET
energy_wh=EXCLUDED.energy_wh,
power_w=EXCLUDED.power_w,
dc_voltage_v=EXCLUDED.dc_voltage_v,
dc_current_a=EXCLUDED.dc_current_a,
temperature_c=EXCLUDED.temperature_c,
source_meta=EXCLUDED.source_meta;
"""
with get_conn() as conn, conn.cursor() as cur:
vals = [
(r['site_id'], r['equipment_id'], r['ts'], r.get('energy_wh'), r.get('power_w'),
r.get('dc_voltage_v'), r.get('dc_current_a'), r.get('temperature_c'), r.get('source_meta'))
for r in rows
]
execute_values(cur, sql, vals)

def register_artifact(site_id, kind, storage_uri, epsg=None, capture_started_at=None, capture_ended_at=None):
sql = """
INSERT INTO artifact (site_id, kind, storage_uri, epsg, capture_started_at, capture_ended_at)
VALUES (%s, %s, %s, %s, %s, %s)
RETURNING id
"""
with get_conn() as conn, conn.cursor() as cur:
cur.execute(sql, (site_id, kind, storage_uri, epsg, capture_started_at, capture_ended_at))
return cur.fetchone()[0]

def get_seed_ids(site_name_env="SITE_NAME"):
import os
site_name = os.getenv(site_name_env, "Pilot C&I Rooftop")
with get_conn() as conn, conn.cursor() as cur:
cur.execute("SELECT id FROM site WHERE name=%s", (site_name,))
site_row = cur.fetchone()
if not site_row:
raise RuntimeError("Seed site not found. Run migrations & seed.")
site_id = site_row[0]
cur.execute("SELECT id FROM equipment WHERE site_id=%s AND type='inverter' LIMIT 1", (site_id,))
inv_row = cur.fetchone()
if not inv_row:
raise RuntimeError("Seed inverter not found.")
return site_id, inv_row[0]
EOF

cat > etl/fetch_pvdaq.py <<'EOF'
import os, boto3
from botocore import UNSIGNED
from botocore.config import Config

ROOT = "data/raw/pvdaq"
BUCKET = "oedi-data-lake"
PREFIX = "pvdaq/csv/"

def main():
os.makedirs(ROOT, exist_ok=True)
s3 = boto3.client("s3", config=Config(signature_version=UNSIGNED))
resp = s3.list_objects_v2(Bucket=BUCKET, Prefix=PREFIX, MaxKeys=100)
items = [c["Key"] for c in resp.get("Contents", []) if c["Key"].endswith(".csv")]
if not items:
print("No PVDAQ CSV objects found"); return
key = items[0]
out = os.path.join(ROOT, "sample_timeseries.csv")
s3.download_file(BUCKET, key, out)
print(f"Downloaded {key} -> {out}")

if **name** == "**main**":
main()
EOF

cat > etl/fetch_pv_iv_el.py <<'EOF'
import os, requests

ROOT = "data/raw/pv_iv_el"

# If resource UUIDs change, open the landing page to refresh links (Data.gov).

EL_URL = "<https://catalog.data.gov/dataset/photovoltaic-module-current-voltage-and-electroluminescence-image-data-pv-iv-el/resource/4b7f6b31-6e6d-4b5b-86b2-1a0e40dbd879/download/el-data.zip>"
IV_URL = "<https://catalog.data.gov/dataset/photovoltaic-module-current-voltage-and-electroluminescence-image-data-pv-iv-el/resource/6d9e7f6e-6d3f-4dd2-9e0d-21ef1fe6b614/download/iv-data.zip>"

def fetch(url, out):
r = requests.get(url, timeout=180)
r.raise_for_status()
with open(out, "wb") as f:
f.write(r.content)
print(f"Saved: {out}")

def main():
os.makedirs(ROOT, exist_ok=True)
fetch(EL_URL, os.path.join(ROOT, "EL_Data.zip"))
fetch(IV_URL, os.path.join(ROOT, "IV_Data.zip"))

if **name** == "**main**":
main()
EOF

cat > etl/fetch_nasa_power.py <<'EOF'
import os, requests, datetime as dt
from dotenv import load_dotenv
load_dotenv()

BASE = os.getenv("NASA_POWER_BASE", "<https://power.larc.nasa.gov>")
LAT = os.getenv("SITE_LAT"); LON = os.getenv("SITE_LON")
ROOT = "data/raw/nasa_power"

def main():
if not LAT or not LON:
raise RuntimeError("SITE_LAT and SITE_LON must be set")
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
r = requests.get(url, params=params, timeout=120)
r.raise_for_status()
out = os.path.join(ROOT, "nasa_power_hourly.csv")
with open(out, "wb") as f:
f.write(r.content)
print(f"Saved: {out}")

if **name** == "**main**":
main()
EOF

cat > etl/fetch_pvgis.py <<'EOF'
import os, requests
from dotenv import load_dotenv
load_dotenv()

BASE = os.getenv("PVGIS_BASE", "<https://re.jrc.ec.europa.eu/api>")
LAT = os.getenv("SITE_LAT"); LON = os.getenv("SITE_LON")
ROOT = "data/raw/pvgis"

def main():
if not LAT or not LON:
raise RuntimeError("SITE_LAT and SITE_LON must be set")
os.makedirs(ROOT, exist_ok=True)
url = f"{BASE}/hourly"
params = {"lat": LAT, "lon": LON, "startyear": 2020, "endyear": 2020, "components": 1, "format": "csv"}
r = requests.get(url, params=params, timeout=120)
r.raise_for_status()
out = os.path.join(ROOT, "pvgis_hourly_2020.csv")
with open(out, "wb") as f:
f.write(r.content)
print(f"Saved: {out}")

if **name** == "**main**":
main()
EOF

cat > etl/fetch_nsrdb.py <<'EOF'
import os, requests
from dotenv import load_dotenv
load_dotenv()

API = "<https://developer.nrel.gov/api/nsrdb/v2/solar/nsrdb-GOES-aggregated-v4-0-0-download.csv>"
LAT = os.getenv("SITE_LAT"); LON = os.getenv("SITE_LON")
KEY = os.getenv("NREL_API_KEY")
EMAIL = os.getenv("NREL_API_EMAIL")
ROOT = "data/raw/nsrdb"

def main():
if not KEY or not EMAIL:
print("NSRDB skipped: set NREL_API_KEY and NREL_API_EMAIL in .env"); return
if not LAT or not LON:
raise RuntimeError("SITE_LAT and SITE_LON must be set")
os.makedirs(ROOT, exist_ok=True)
params = {"wkt": f"POINT({LON} {LAT})", "names": 2020, "interval": 60, "api_key": KEY, "email": EMAIL}
r = requests.get(API, params=params, timeout=180)
r.raise_for_status()
out = os.path.join(ROOT, "nsrdb_2020_hourly.csv")
with open(out, "wb") as f: f.write(r.content)
print(f"Saved: {out}")

if **name** == "**main**":
main()
EOF

cat > etl/fetch_oam.py <<'EOF'
import os, requests, json
from dotenv import load_dotenv
load_dotenv()

OAM = os.getenv("OAM_API_BASE","<https://api.openaerialmap.org>")
LAT = float(os.getenv("SITE_LAT")); LON = float(os.getenv("SITE_LON"))
ROOT = "data/raw/oam"

def bbox(lat, lon, size_deg=0.01):
return [lon-size_deg, lat-size_deg, lon+size_deg, lat+size_deg]

def main():
os.makedirs(ROOT, exist_ok=True)
bb = ",".join(map(str, bbox(LAT, LON)))
url = f"{OAM}/meta?bbox={bb}&limit=1"
r = requests.get(url, timeout=120)
r.raise_for_status()
data = r.json()
if not data.get("results"):
print("No OAM imagery found near bbox; try increasing bbox size."); return
item = data["results"][0]
# Prefer GeoTIFF if available
out = os.path.join(ROOT, "sample_rgb_ortho.tif")
gti = None
for f in item.get("properties", {}).get("files", []):
if f.get("type","").lower() in ("geotiff","geotif","tif","tiff"):
gti = f.get("href"); break
if not gti:
gti = item["properties"].get("thumbnail")
out = os.path.join(ROOT, "sample_rgb_ortho.jpg")
print(f"Downloading: {gti}")
r = requests.get(gti, timeout=300)
r.raise_for_status()
with open(out,"wb") as f: f.write(r.content)
print(f"Saved: {out}")

if **name** == "**main**":
main()
EOF

cat > etl/load_inverter_csv.py <<'EOF'
import sys, os, pandas as pd, json
from dotenv import load_dotenv
from etl.utils.db import get_seed_ids, upsert_inverter_timeseries
load_dotenv()

def main(path):
site_id, inv_id = get_seed_ids()
df = pd.read_csv(path)
dt_candidates = [c for c in df.columns if c.lower() in ("datetime","time","timestamp","ts","date_time")]
if not dt_candidates:
raise RuntimeError("No datetime-like column found")
dt_col = dt_candidates[0]
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
"dc_voltage_v": float(r.get("dc_voltage_v")) if "dc_voltage_v" in df.columns else None,
"dc_current_a": float(r.get("dc_current_a")) if "dc_current_a" in df.columns else None,
"temperature_c": float(r.get("temperature_c")) if "temperature_c" in df.columns else None,
"source_meta": json.dumps({"source_path": path})
})
if rows:
upsert_inverter_timeseries(rows)
print(f"Upserted {len(rows)} rows from {path}")
else:
print("No rows parsed.")

if **name**=="**main**":
if len(sys.argv)<2:
print("Usage: load_inverter_csv.py <path_to_csv>")
sys.exit(1)
main(sys.argv[1])
EOF

cat > etl/load_artifact.py <<'EOF'
import sys, os, datetime as dt
from dotenv import load_dotenv
from etl.utils.db import get_seed_ids, register_artifact
load_dotenv()

def main(path, kind):
site_id, _ = get_seed_ids()
if not os.path.exists(path):
print(f"File not found: {path}"); return
aid = register_artifact(site_id, kind, os.path.abspath(path), epsg=3857,
capture_started_at=dt.datetime.utcnow(),
capture_ended_at=dt.datetime.utcnow())
print(f"Registered artifact {aid} kind={kind} uri={path}")

if **name**=="**main**":
if len(sys.argv)<3:
print("Usage: load_artifact.py <file_path> <kind> (rgb_ortho|thermal_ortho|...)")
sys.exit(1)
main(sys.argv[1], sys.argv[2])
EOF

# ---------- Git init ----------

git init -q
git add .
git commit -m "feat: initial open-data test rig (schema + ETL + loaders + docs)" -q

echo
echo "✅ Repo scaffolded at: $(pwd)"
echo "Next:"
echo " 1) python3 -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt"
echo " 2) cp .env.example .env  # edit DATABASE_URL etc."
echo " 3) make db.migrate && make db.seed"
echo " 4) make fetch.all && make load.sample"

```

---

### ✅ After you run it
You’ll have a fully‑initialized repo with:

- Postgres + PostGIS schema (v1→v2 ready)  
- Seeded org/site/inverter + ROI settings  
- ETL scripts to fetch **open** PV time‑series, IV/EL data, irradiance/weather, and an RGB orthomosaic  
- Loaders to populate `inverter_telemetry` and `artifact` for smoke testing

Want me to also add a **GitHub Actions CI** (lint + dry‑run ETL) or jump to **UX wireframes** and the **5‑site AU/IN pilot plan** next?
```
