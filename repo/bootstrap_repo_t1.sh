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

**Thermal/photogrammetry QC rules** (for capture validation & `qc_flag`): ensure adequate **irradiance**, set **emissivity**, confirm modules **under load**, and maintain **overlap/GSD**—derived from FLIR and DJI enterprise guidance. 

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

> **Note:** NSRDB API requires a free key + email. If you don’t set one, the NSRDB fetch step will be skipped. [\[pulse2.com\]](https://pulse2.com/pexapark-21-million-funding/)

***

## Environment

Copy `.env.example` → `.env` and fill values:

*   `DATABASE_URL` — e.g., `postgresql://postgres:postgres@localhost:5432/amplyfy`
*   `SITE_LAT`, `SITE_LON`, `SITE_TZ` — seed site location & timezone
*   `NREL_API_KEY`, `NREL_API_EMAIL` — (optional) for NSRDB API [\[pulse2.com\]](https://pulse2.com/pexapark-21-million-funding/)
*   `CDS_API_URL`, `CDS_API_KEY` — (optional) for ERA5 via CDS [\[efiling.en...rgy.ca.gov\]](https://efiling.energy.ca.gov/GetDocument.aspx?tn=251918\&DocumentContentId=86918)

***

## Mermaid ER Diagram



> This schema targets **v1 → v2** (detections, ΔMWh/$, priorities, work orders, inverter time series & IV curves) and is forward‑compatible with **v3 O\&M digital twin light** (artifacts, versions, geospatial). DJI’s enterprise photogrammetry guidance supports drone‑only twins; we don’t need PVSyst for an O\&M twin. [\[granular-energy.com\]](https://www.granular-energy.com/insights/granular-energy-becomes-accrediated-issuer-of-granular-certificates-under-energytag)

***

## Data Sources (Open)

*   **PVDAQ**: OEDI S3 (CSV/Parquet) + docs; multi‑site PV performance & metadata.\
    Docs & access: [OpenEI/OEDI entry](https://www.flexidao.com/resources/flexidao-energytag), [Data.gov landing](https://myenergi.info/intelligent-octopus-tariff-with-zappi-charging-con-t10420.html)
*   **PV‑IV‑EL**: Paired module IV + EL datasets (Sandia). [Data.gov entry & downloads](https://www.woodmac.com/reports/power-markets-oandm-economics-and-cost-data-for-onshore-wind-power-markets-2023-150161452/)
*   **NASA POWER**: REST for hourly/daily irradiance & meteorology; viewer + APIs. [DAV](https://atb.nrel.gov/electricity/2024/utility-scale_pv)
*   **NSRDB**: API + open S3; GHI/DNI/DHI & meteorology at several cadences. [API](https://pulse2.com/pexapark-21-million-funding/), [AWS registry](https://www.iea.org/reports/renewables-2023)
*   **PVGIS**: EC JRC APIs for radiation & PV performance global coverage. [PVGIS hub](https://atb.nrel.gov/electricity/2024/Land-Based_Wind)
*   **ERA5**: Copernicus CDS (optional) global hourly reanalysis; requires free key. [CDS dataset](https://efiling.energy.ca.gov/GetDocument.aspx?tn=251918\&DocumentContentId=86918)
*   **OpenAerialMap**: open orthomosaics for imagery ingestion testing. [OAM browser/API](https://arena.gov.au/projects/infravision-next-generation-line-monitoring-system-demonstration/)

**QC references:**

*   **Thermal**: irradiance $$≥\~600 W/m²$$, emissivity set, modules under load; overlap & resolution requirements. [FLIR tech note](https://energytag.org/wp-content/uploads/2025/09/PUBLIC-Flexidao-GC-Scheme-Protocol_Configuration-3.pdf)
*   **Photogrammetry** (twin capture): overlap patterns, automation, GSD. [DJI enterprise blog](https://www.granular-energy.com/insights/granular-energy-becomes-accrediated-issuer-of-granular-certificates-under-energytag)

***

## Make Targets

*   `make db.migrate` → run schema DDL
*   `make db.seed` → seed 1 org/site/inverter + ROI settings
*   `make fetch.all` → PVDAQ, PV‑IV‑EL, NASA POWER, PVGIS, OAM (NSRDB separate)
*   `make fetch.nsrdb` → if `NREL_API_KEY` & email set [\[pulse2.com\]](https://pulse2.com/pexapark-21-million-funding/)
*   `make load.sample` → load PVDAQ sample CSV into `inverter_telemetry` + register sample RGB ortho

***

## Roadmap

*   Wire **ΔMWh/$** calculators → `impact_estimate`
*   Agentic **prioritizer** → `priority_queue`
*   Work order integrations (Jira/ServiceNow) via webhooks

EOF

cat > .env.example <<'EOF'

# Database

DATABASE\_URL=postgresql://postgres:postgres\@localhost:5432/amplyfy

# Site defaults (seed)

SITE\_NAME=Pilot C\&I Rooftop
SITE\_LAT=-33.870
SITE\_LON=151.205
SITE\_TZ=Australia/Sydney

# APIs

# NSRDB (optional; API key + email)

NREL\_API\_KEY=
NREL\_API\_EMAIL=

# NASA POWER (no key)

NASA\_POWER\_BASE=<https://power.larc.nasa.gov>

# PVGIS (no key)

PVGIS\_BASE=<https://re.jrc.ec.europa.eu/api>

# Copernicus CDS (optional)

CDS\_API\_URL=<https://cds.climate.copernicus.eu/api/v2>
CDS\_API\_KEY=

# OpenAerialMap

OAM\_API\_BASE=<https://api.openaerialmap.org>
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
.PHONY: db.migrate db.seed fetch.all fetch.pvdaq fetch.pv\_iv\_el fetch.nasa\_power fetch.pvgis fetch.nsrdb fetch.oam load.sample

VENV=.venv/bin
PY=$(VENV)/python
PSQL=psql

db.migrate:
$(PSQL) -d $$DATABASE\_URL -f db/migrations/001\_init.sql

db.seed:
$(PSQL) -d $$DATABASE\_URL -f db/migrations/002\_seed.sql

fetch.pvdaq:
$(PY) etl/fetch\_pvdaq.py

fetch.pv\_iv\_el:
$(PY) etl/fetch\_pv\_iv\_el.py

fetch.nasa\_power:
$(PY) etl/fetch\_nasa\_power.py

fetch.pvgis:
$(PY) etl/fetch\_pvgis.py

fetch.nsrdb:
$(PY) etl/fetch\_nsrdb.py

fetch.oam:
$(PY) etl/fetch\_oam.py

fetch.all: fetch.pvdaq fetch.pv\_iv\_el fetch.nasa\_power fetch.pvgis fetch.oam
@echo "NSRDB optional; run 'make fetch.nsrdb' if API key is set."

load.sample:
$(PY) etl/load\_inverter\_csv.py data/raw/pvdaq/sample\_timeseries.csv
$(PY) etl/load\_artifact.py data/raw/oam/sample\_rgb\_ortho.tif rgb\_ortho
EOF

# ---------- DB Migrations ----------

mkdir -p db/migrations

cat > db/migrations/001\_init.sql <<'EOF'
\-- See earlier message for full commentary; this is the full DDL.

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE org (
id uuid PRIMARY KEY DEFAULT gen\_random\_uuid(),
name text NOT NULL,
country\_code char(2),
created\_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE user\_account (
id uuid PRIMARY KEY DEFAULT gen\_random\_uuid(),
email citext UNIQUE NOT NULL,
full\_name text,
password\_hash text,
created\_at timestamptz NOT NULL DEFAULT now(),
is\_active boolean NOT NULL DEFAULT true
);

CREATE TABLE org\_user\_role (
org\_id uuid REFERENCES org(id) ON DELETE CASCADE,
user\_id uuid REFERENCES user\_account(id) ON DELETE CASCADE,
role text CHECK (role IN ('owner','admin','editor','viewer')),
PRIMARY KEY (org\_id, user\_id)
);

CREATE TABLE site (
id uuid PRIMARY KEY DEFAULT gen\_random\_uuid(),
org\_id uuid REFERENCES org(id) ON DELETE CASCADE,
name text NOT NULL,
dc\_capacity\_mw numeric(8,3) NOT NULL,
commissioning\_date date,
timezone text,
centroid geography(point, 4326),
boundary geography(polygon, 4326),
address\_line1 text,
city text,
state\_region text,
country\_code char(2),
created\_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx\_site\_geom ON site USING gist(boundary);

CREATE TABLE array (
id uuid PRIMARY KEY DEFAULT gen\_random\_uuid(),
site\_id uuid REFERENCES site(id) ON DELETE CASCADE,
name text,
boundary geography(polygon, 4326),
tilt\_deg numeric(5,2),
azimuth\_deg numeric(6,2),
created\_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx\_array\_geom ON array USING gist(boundary);

CREATE TABLE equipment (
id uuid PRIMARY KEY DEFAULT gen\_random\_uuid(),
site\_id uuid REFERENCES site(id) ON DELETE CASCADE,
type text CHECK (type IN ('inverter','combiner','tracker','transformer')),
make\_model text,
serial\_number text,
name text,
location geography(point, 4326),
created\_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx\_equipment\_loc ON equipment USING gist(location);

CREATE TABLE ingestion\_job (
id uuid PRIMARY KEY DEFAULT gen\_random\_uuid(),
site\_id uuid REFERENCES site(id) ON DELETE CASCADE,
kind text CHECK (kind IN ('rgb\_ortho','thermal\_ortho','pointcloud','report')),
requested\_by uuid REFERENCES user\_account(id),
status text CHECK (status IN ('queued','processing','complete','error')),
message text,
created\_at timestamptz NOT NULL DEFAULT now(),
completed\_at timestamptz
);

CREATE TABLE artifact (
id uuid PRIMARY KEY DEFAULT gen\_random\_uuid(),
site\_id uuid REFERENCES site(id) ON DELETE CASCADE,
kind text CHECK (kind IN ('rgb\_ortho','thermal\_ortho','flight\_log','kml\_worldfile','raw\_frame\_zip')),
storage\_uri text NOT NULL,
checksum\_sha256 text,
epsg int,
capture\_started\_at timestamptz,
capture\_ended\_at timestamptz,
created\_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE artifact\_version (
id uuid PRIMARY KEY DEFAULT gen\_random\_uuid(),
artifact\_id uuid REFERENCES artifact(id) ON DELETE CASCADE,
pipeline\_version text NOT NULL,
derived\_uri text,
metadata\_json jsonb,
created\_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE capture\_metadata (
id uuid PRIMARY KEY DEFAULT gen\_random\_uuid(),
artifact\_id uuid REFERENCES artifact(id) ON DELETE CASCADE,
gsd\_cm numeric(6,2),
overlap\_front\_pct numeric(5,2),
overlap\_side\_pct numeric(5,2),
emissivity numeric(4,3),
irradiance\_wm2 numeric(7,2),
wind\_ms numeric(5,2),
ambient\_c numeric(5,2),
notes text,
qc\_flags text\[]
);

CREATE TABLE detection (
id uuid PRIMARY KEY DEFAULT gen\_random\_uuid(),
site\_id uuid REFERENCES site(id) ON DELETE CASCADE,
artifact\_id uuid REFERENCES artifact(id) ON DELETE SET NULL,
type text CHECK (type IN ('SOILING','VEGETATION','HOTSPOT','CRACK','OTHER')),
confidence numeric(4,3) CHECK (confidence BETWEEN 0 AND 1),
geom geography(polygon, 4326),
stats\_json jsonb,
created\_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx\_detection\_geom ON detection USING gist(geom);

CREATE TABLE detection\_cluster (
id uuid PRIMARY KEY DEFAULT gen\_random\_uuid(),
site\_id uuid REFERENCES site(id) ON DELETE CASCADE,
type text CHECK (type IN ('SOILING','VEGETATION','HOTSPOT')),
geom geography(polygon, 4326),
severity text CHECK (severity IN ('low','med','high')),
created\_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx\_detection\_cluster\_geom ON detection\_cluster USING gist(geom);

CREATE TABLE impact\_estimate (
id uuid PRIMARY KEY DEFAULT gen\_random\_uuid(),
site\_id uuid REFERENCES site(id) ON DELETE CASCADE,
detection\_id uuid REFERENCES detection(id) ON DELETE CASCADE,
method\_version text NOT NULL,
delta\_mwh\_year numeric(10,3) NOT NULL,
delta\_value\_year numeric(12,2) NOT NULL,
payback\_months numeric(8,2),
assumptions\_json jsonb,
created\_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE priority\_queue (
id uuid PRIMARY KEY DEFAULT gen\_random\_uuid(),
site\_id uuid REFERENCES site(id) ON DELETE CASCADE,
detection\_id uuid REFERENCES detection(id) ON DELETE CASCADE,
rank\_score numeric(6,3),
rationale text,
status text CHECK (status IN ('proposed','scheduled','in\_progress','done','deferred')),
created\_at timestamptz NOT NULL DEFAULT now(),
updated\_at timestamptz
);

CREATE TABLE work\_order (
id uuid PRIMARY KEY DEFAULT gen\_random\_uuid(),
site\_id uuid REFERENCES site(id) ON DELETE CASCADE,
title text NOT NULL,
description text,
status text CHECK (status IN ('open','assigned','in\_progress','complete','cancelled')),
planned\_start timestamptz,
planned\_end timestamptz,
created\_at timestamptz NOT NULL DEFAULT now(),
updated\_at timestamptz
);

CREATE TABLE work\_order\_item (
id uuid PRIMARY KEY DEFAULT gen\_random\_uuid(),
work\_order\_id uuid REFERENCES work\_order(id) ON DELETE CASCADE,
detection\_id uuid REFERENCES detection(id) ON DELETE SET NULL,
action text CHECK (action IN ('CLEAN','TRIM\_VEGETATION','REPAIR\_STRING','INSPECT\_MANUAL','REPLACE\_MODULE')),
location geography(point, 4326),
estimate\_hours numeric(6,2),
estimate\_cost numeric(12,2),
created\_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx\_work\_item\_loc ON work\_order\_item USING gist(location);

CREATE TABLE inverter\_telemetry (
site\_id uuid NOT NULL REFERENCES site(id) ON DELETE CASCADE,
equipment\_id uuid NOT NULL REFERENCES equipment(id) ON DELETE CASCADE,
ts timestamptz NOT NULL,
energy\_wh bigint,
power\_w bigint,
dc\_voltage\_v numeric(10,2),
dc\_current\_a numeric(10,2),
temperature\_c numeric(6,2),
source\_meta jsonb,
PRIMARY KEY (site\_id, equipment\_id, ts)
);
CREATE INDEX IF NOT EXISTS idx\_inv\_ts ON inverter\_telemetry (site\_id, ts DESC);

CREATE TABLE iv\_curve (
id uuid PRIMARY KEY DEFAULT gen\_random\_uuid(),
site\_id uuid REFERENCES site(id) ON DELETE CASCADE,
equipment\_id uuid REFERENCES equipment(id) ON DELETE SET NULL,
ts timestamptz NOT NULL,
method text CHECK (method IN ('SMART\_IV','FIELD\_TRACER','LAB')),
meta\_json jsonb,
created\_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE iv\_curve\_point (
iv\_curve\_id uuid REFERENCES iv\_curve(id) ON DELETE CASCADE,
idx int NOT NULL,
voltage\_v numeric(10,3) NOT NULL,
current\_a numeric(10,3) NOT NULL,
PRIMARY KEY (iv\_curve\_id, idx)
);

CREATE TABLE settings\_roi (
site\_id uuid PRIMARY KEY REFERENCES site(id) ON DELETE CASCADE,
currency text DEFAULT 'USD',
energy\_price\_per\_mwh numeric(10,2),
labor\_rate\_per\_hour numeric(10,2),
cleaning\_cost\_per\_m2 numeric(10,2),
vegetation\_cost\_per\_m2 numeric(10,2),
json\_extras jsonb,
updated\_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE calibration\_baseline (
id uuid PRIMARY KEY DEFAULT gen\_random\_uuid(),
site\_id uuid REFERENCES site(id) ON DELETE CASCADE,
window\_start date NOT NULL,
window\_end date NOT NULL,
modeled\_mwh numeric(12,3),
observed\_mwh numeric(12,3),
scaling\_factor numeric(6,4),
created\_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE weather\_snapshot (
id uuid PRIMARY KEY DEFAULT gen\_random\_uuid(),
site\_id uuid REFERENCES site(id) ON DELETE CASCADE,
ts timestamptz NOT NULL,
source text,
ghi\_wm2 numeric(8,2),
temp\_c numeric(5,2),
wind\_ms numeric(5,2),
cloud\_okta numeric(3,1),
created\_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE qc\_flag (
id uuid PRIMARY KEY DEFAULT gen\_random\_uuid(),
artifact\_id uuid REFERENCES artifact(id) ON DELETE CASCADE,
code text,
severity text CHECK (severity IN ('info','warn','fail')),
notes text,
created\_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE crew (
id uuid PRIMARY KEY DEFAULT gen\_random\_uuid(),
org\_id uuid REFERENCES org(id) ON DELETE CASCADE,
name text,
home\_base geography(point, 4326),
created\_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx\_crew\_home ON crew USING gist(home\_base);

CREATE TABLE crew\_shift (
id uuid PRIMARY KEY DEFAULT gen\_random\_uuid(),
crew\_id uuid REFERENCES crew(id) ON DELETE CASCADE,
shift\_date date NOT NULL,
start\_time\_local time NOT NULL,
end\_time\_local time NOT NULL,
capacity\_hours numeric(6,2),
created\_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE route\_plan (
id uuid PRIMARY KEY DEFAULT gen\_random\_uuid(),
crew\_id uuid REFERENCES crew(id) ON DELETE CASCADE,
work\_order\_id uuid REFERENCES work\_order(id) ON DELETE CASCADE,
planned\_start timestamptz,
planned\_end timestamptz,
route\_geo geography(linestring, 4326),
created\_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx\_route\_geo ON route\_plan USING gist(route\_geo);
EOF

cat > db/migrations/002\_seed.sql <<'EOF'
INSERT INTO org (name, country\_code) VALUES ('Amplyfy Pilot Org','AU');

INSERT INTO user\_account (email, full\_name, password\_hash)
VALUES ('<ops@amplyfy.example>','Ops User','$2b$12$seedONLY');

INSERT INTO org\_user\_role (org\_id, user\_id, role)
SELECT o.id, u.id, 'owner'
FROM org o, user\_account u
WHERE o.name='Amplyfy Pilot Org' AND u.email='<ops@amplyfy.example>';

INSERT INTO site (org\_id, name, dc\_capacity\_mw, commissioning\_date, timezone, centroid, boundary, address\_line1, city, state\_region, country\_code)
SELECT o.id, 'Pilot C\&I Rooftop', 3.000, '2020-03-01', 'Australia/Sydney',
ST\_SetSRID(ST\_MakePoint(151.205, -33.870),4326)::geography,
ST\_GeogFromText('POLYGON((151.2045 -33.8696,151.2056 -33.8696,151.2056 -33.8704,151.2045 -33.8704,151.2045 -33.8696))'),
'123 George St','Sydney','NSW','AU'
FROM org o WHERE o.name='Amplyfy Pilot Org';

INSERT INTO equipment (site\_id, type, make\_model, serial\_number, name, location)
SELECT s.id, 'inverter', 'SMA STP', 'SMA-INV-001', 'INV-1', s.centroid
FROM site s WHERE s.name='Pilot C\&I Rooftop';

INSERT INTO settings\_roi (site\_id, currency, energy\_price\_per\_mwh, labor\_rate\_per\_hour, cleaning\_cost\_per\_m2, vegetation\_cost\_per\_m2, json\_extras)
SELECT s.id, 'AUD', 140.00, 85.00, 0.45, 0.35, '{}'
FROM site s WHERE s.name='Pilot C\&I Rooftop';

INSERT INTO artifact (site\_id, kind, storage\_uri, epsg, capture\_started\_at, capture\_ended\_at)
SELECT s.id, 'rgb\_ortho',
'<https://api.openaerialmap.org/tiles/{oam_item_id}/0/0/0.png>',
3857, now()-interval '10 days', now()-interval '10 days' + interval '30 minutes'
FROM site s WHERE s.name='Pilot C\&I Rooftop';

INSERT INTO artifact (site\_id, kind, storage\_uri, epsg, capture\_started\_at, capture\_ended\_at)
SELECT s.id, 'thermal\_ortho',
's3://your-bucket/thermal/pilot\_20240301\_orthomosaic.tif',
3857, now()-interval '10 days', now()-interval '10 days' + interval '30 minutes'
FROM site s WHERE s.name='Pilot C\&I Rooftop';

INSERT INTO capture\_metadata (artifact\_id, gsd\_cm, overlap\_front\_pct, overlap\_side\_pct, emissivity, irradiance\_wm2, wind\_ms, ambient\_c, notes, qc\_flags)
SELECT a.id, 2.50, 75.0, 70.0, 0.95, 800.0, 2.5, 24.0, 'Daytime flight; radiometric; panel under load', ARRAY\['OK']
FROM artifact a JOIN site s ON s.id=a.site\_id
WHERE s.name='Pilot C\&I Rooftop' AND a.kind='thermal\_ortho';

INSERT INTO weather\_snapshot (site\_id, ts, source, ghi\_wm2, temp\_c, wind\_ms, cloud\_okta)
SELECT s.id, now()-interval '10 days', 'NASA\_POWER', 780, 23.0, 2.0, 1.0
FROM site s WHERE s.name='Pilot C\&I Rooftop';

INSERT INTO inverter\_telemetry (site\_id, equipment\_id, ts, energy\_wh, power\_w, dc\_voltage\_v, dc\_current\_a, temperature\_c, source\_meta)
SELECT s.id, e.id, now()-interval '1 day', 1523400, 23000, 780.0, 30.5, 46.0, '{"source":"CSV\_UPLOAD"}'::jsonb
FROM site s JOIN equipment e ON e.site\_id=s.id
WHERE s.name='Pilot C\&I Rooftop' AND e.name='INV-1';
EOF

# ---------- ETL ----------

mkdir -p etl/utils data/raw data/processed

cat > etl/utils/db.py <<'EOF'
import os
import psycopg2
from psycopg2.extras import execute\_values

def get\_conn():
url = os.getenv("DATABASE\_URL")
if not url:
raise RuntimeError("DATABASE\_URL not set")
return psycopg2.connect(url)

def upsert\_inverter\_timeseries(rows):
sql = """
INSERT INTO inverter\_telemetry
(site\_id, equipment\_id, ts, energy\_wh, power\_w, dc\_voltage\_v, dc\_current\_a, temperature\_c, source\_meta)
VALUES %s
ON CONFLICT (site\_id, equipment\_id, ts)
DO UPDATE SET
energy\_wh=EXCLUDED.energy\_wh,
power\_w=EXCLUDED.power\_w,
dc\_voltage\_v=EXCLUDED.dc\_voltage\_v,
dc\_current\_a=EXCLUDED.dc\_current\_a,
temperature\_c=EXCLUDED.temperature\_c,
source\_meta=EXCLUDED.source\_meta;
"""
with get\_conn() as conn, conn.cursor() as cur:
vals = \[
(r\['site\_id'], r\['equipment\_id'], r\['ts'], r.get('energy\_wh'), r.get('power\_w'),
r.get('dc\_voltage\_v'), r.get('dc\_current\_a'), r.get('temperature\_c'), r.get('source\_meta'))
for r in rows
]
execute\_values(cur, sql, vals)

def register\_artifact(site\_id, kind, storage\_uri, epsg=None, capture\_started\_at=None, capture\_ended\_at=None):
sql = """
INSERT INTO artifact (site\_id, kind, storage\_uri, epsg, capture\_started\_at, capture\_ended\_at)
VALUES (%s, %s, %s, %s, %s, %s)
RETURNING id
"""
with get\_conn() as conn, conn.cursor() as cur:
cur.execute(sql, (site\_id, kind, storage\_uri, epsg, capture\_started\_at, capture\_ended\_at))
return cur.fetchone()\[0]

def get\_seed\_ids(site\_name\_env="SITE\_NAME"):
import os
site\_name = os.getenv(site\_name\_env, "Pilot C\&I Rooftop")
with get\_conn() as conn, conn.cursor() as cur:
cur.execute("SELECT id FROM site WHERE name=%s", (site\_name,))
site\_row = cur.fetchone()
if not site\_row:
raise RuntimeError("Seed site not found. Run migrations & seed.")
site\_id = site\_row\[0]
cur.execute("SELECT id FROM equipment WHERE site\_id=%s AND type='inverter' LIMIT 1", (site\_id,))
inv\_row = cur.fetchone()
if not inv\_row:
raise RuntimeError("Seed inverter not found.")
return site\_id, inv\_row\[0]
EOF

cat > etl/fetch\_pvdaq.py <<'EOF'
import os, boto3
from botocore import UNSIGNED
from botocore.config import Config

ROOT = "data/raw/pvdaq"
BUCKET = "oedi-data-lake"
PREFIX = "pvdaq/csv/"

def main():
os.makedirs(ROOT, exist\_ok=True)
s3 = boto3.client("s3", config=Config(signature\_version=UNSIGNED))
resp = s3.list\_objects\_v2(Bucket=BUCKET, Prefix=PREFIX, MaxKeys=100)
items = \[c\["Key"] for c in resp.get("Contents", \[]) if c\["Key"].endswith(".csv")]
if not items:
print("No PVDAQ CSV objects found"); return
key = items\[0]
out = os.path.join(ROOT, "sample\_timeseries.csv")
s3.download\_file(BUCKET, key, out)
print(f"Downloaded {key} -> {out}")

if **name** == "**main**":
main()
EOF

cat > etl/fetch\_pv\_iv\_el.py <<'EOF'
import os, requests

ROOT = "data/raw/pv\_iv\_el"

# If resource UUIDs change, open the landing page to refresh links (Data.gov).

EL\_URL = "<https://catalog.data.gov/dataset/photovoltaic-module-current-voltage-and-electroluminescence-image-data-pv-iv-el/resource/4b7f6b31-6e6d-4b5b-86b2-1a0e40dbd879/download/el-data.zip>"
IV\_URL = "<https://catalog.data.gov/dataset/photovoltaic-module-current-voltage-and-electroluminescence-image-data-pv-iv-el/resource/6d9e7f6e-6d3f-4dd2-9e0d-21ef1fe6b614/download/iv-data.zip>"

def fetch(url, out):
r = requests.get(url, timeout=180)
r.raise\_for\_status()
with open(out, "wb") as f:
f.write(r.content)
print(f"Saved: {out}")

def main():
os.makedirs(ROOT, exist\_ok=True)
fetch(EL\_URL, os.path.join(ROOT, "EL\_Data.zip"))
fetch(IV\_URL, os.path.join(ROOT, "IV\_Data.zip"))

if **name** == "**main**":
main()
EOF

cat > etl/fetch\_nasa\_power.py <<'EOF'
import os, requests, datetime as dt
from dotenv import load\_dotenv
load\_dotenv()

BASE = os.getenv("NASA\_POWER\_BASE", "<https://power.larc.nasa.gov>")
LAT = os.getenv("SITE\_LAT"); LON = os.getenv("SITE\_LON")
ROOT = "data/raw/nasa\_power"

def main():
if not LAT or not LON:
raise RuntimeError("SITE\_LAT and SITE\_LON must be set")
os.makedirs(ROOT, exist\_ok=True)
end = dt.date.today() - dt.timedelta(days=1)
start = end - dt.timedelta(days=7)
params = {
"latitude": LAT, "longitude": LON,
"start": start.strftime("%Y%m%d"),
"end": end.strftime("%Y%m%d"),
"parameters": "ALLSKY\_SFC\_SW\_DWN,T2M,WS10M",
"community": "RE",
"format": "CSV",
"temporal": "HOURLY"
}
url = f"{BASE}/api/temporal/hourly/point"
r = requests.get(url, params=params, timeout=120)
r.raise\_for\_status()
out = os.path.join(ROOT, "nasa\_power\_hourly.csv")
with open(out, "wb") as f:
f.write(r.content)
print(f"Saved: {out}")

if **name** == "**main**":
main()
EOF

cat > etl/fetch\_pvgis.py <<'EOF'
import os, requests
from dotenv import load\_dotenv
load\_dotenv()

BASE = os.getenv("PVGIS\_BASE", "<https://re.jrc.ec.europa.eu/api>")
LAT = os.getenv("SITE\_LAT"); LON = os.getenv("SITE\_LON")
ROOT = "data/raw/pvgis"

def main():
if not LAT or not LON:
raise RuntimeError("SITE\_LAT and SITE\_LON must be set")
os.makedirs(ROOT, exist\_ok=True)
url = f"{BASE}/hourly"
params = {"lat": LAT, "lon": LON, "startyear": 2020, "endyear": 2020, "components": 1, "format": "csv"}
r = requests.get(url, params=params, timeout=120)
r.raise\_for\_status()
out = os.path.join(ROOT, "pvgis\_hourly\_2020.csv")
with open(out, "wb") as f:
f.write(r.content)
print(f"Saved: {out}")

if **name** == "**main**":
main()
EOF

cat > etl/fetch\_nsrdb.py <<'EOF'
import os, requests
from dotenv import load\_dotenv
load\_dotenv()

API = "<https://developer.nrel.gov/api/nsrdb/v2/solar/nsrdb-GOES-aggregated-v4-0-0-download.csv>"
LAT = os.getenv("SITE\_LAT"); LON = os.getenv("SITE\_LON")
KEY = os.getenv("NREL\_API\_KEY")
EMAIL = os.getenv("NREL\_API\_EMAIL")
ROOT = "data/raw/nsrdb"

def main():
if not KEY or not EMAIL:
print("NSRDB skipped: set NREL\_API\_KEY and NREL\_API\_EMAIL in .env"); return
if not LAT or not LON:
raise RuntimeError("SITE\_LAT and SITE\_LON must be set")
os.makedirs(ROOT, exist\_ok=True)
params = {"wkt": f"POINT({LON} {LAT})", "names": 2020, "interval": 60, "api\_key": KEY, "email": EMAIL}
r = requests.get(API, params=params, timeout=180)
r.raise\_for\_status()
out = os.path.join(ROOT, "nsrdb\_2020\_hourly.csv")
with open(out, "wb") as f: f.write(r.content)
print(f"Saved: {out}")

if **name** == "**main**":
main()
EOF

cat > etl/fetch\_oam.py <<'EOF'
import os, requests, json
from dotenv import load\_dotenv
load\_dotenv()

OAM = os.getenv("OAM\_API\_BASE","<https://api.openaerialmap.org>")
LAT = float(os.getenv("SITE\_LAT")); LON = float(os.getenv("SITE\_LON"))
ROOT = "data/raw/oam"

def bbox(lat, lon, size\_deg=0.01):
return \[lon-size\_deg, lat-size\_deg, lon+size\_deg, lat+size\_deg]

def main():
os.makedirs(ROOT, exist\_ok=True)
bb = ",".join(map(str, bbox(LAT, LON)))
url = f"{OAM}/meta?bbox={bb}\&limit=1"
r = requests.get(url, timeout=120)
r.raise\_for\_status()
data = r.json()
if not data.get("results"):
print("No OAM imagery found near bbox; try increasing bbox size."); return
item = data\["results"]\[0]
\# Prefer GeoTIFF if available
out = os.path.join(ROOT, "sample\_rgb\_ortho.tif")
gti = None
for f in item.get("properties", {}).get("files", \[]):
if f.get("type","").lower() in ("geotiff","geotif","tif","tiff"):
gti = f.get("href"); break
if not gti:
gti = item\["properties"].get("thumbnail")
out = os.path.join(ROOT, "sample\_rgb\_ortho.jpg")
print(f"Downloading: {gti}")
r = requests.get(gti, timeout=300)
r.raise\_for\_status()
with open(out,"wb") as f: f.write(r.content)
print(f"Saved: {out}")

if **name** == "**main**":
main()
EOF

cat > etl/load\_inverter\_csv.py <<'EOF'
import sys, os, pandas as pd, json
from dotenv import load\_dotenv
from etl.utils.db import get\_seed\_ids, upsert\_inverter\_timeseries
load\_dotenv()

def main(path):
site\_id, inv\_id = get\_seed\_ids()
df = pd.read\_csv(path)
dt\_candidates = \[c for c in df.columns if c.lower() in ("datetime","time","timestamp","ts","date\_time")]
if not dt\_candidates:
raise RuntimeError("No datetime-like column found")
dt\_col = dt\_candidates\[0]
df\["ts"] = pd.to\_datetime(df\[dt\_col], utc=True, errors="coerce")
rows = \[]
for \_,r in df.iterrows():
if pd.isna(r\["ts"]): continue
rows.append({
"site\_id": site\_id,
"equipment\_id": inv\_id,
"ts": r\["ts"].to\_pydatetime(),
"energy\_wh": int(r.get("energy\_wh", 0)) if "energy\_wh" in df.columns else None,
"power\_w": int(r.get("power\_w", 0)) if "power\_w" in df.columns else None,
"dc\_voltage\_v": float(r.get("dc\_voltage\_v")) if "dc\_voltage\_v" in df.columns else None,
"dc\_current\_a": float(r.get("dc\_current\_a")) if "dc\_current\_a" in df.columns else None,
"temperature\_c": float(r.get("temperature\_c")) if "temperature\_c" in df.columns else None,
"source\_meta": json.dumps({"source\_path": path})
})
if rows:
upsert\_inverter\_timeseries(rows)
print(f"Upserted {len(rows)} rows from {path}")
else:
print("No rows parsed.")

if **name**=="**main**":
if len(sys.argv)<2:
print("Usage: load\_inverter\_csv.py \<path\_to\_csv>")
sys.exit(1)
main(sys.argv\[1])
EOF

cat > etl/load\_artifact.py <<'EOF'
import sys, os, datetime as dt
from dotenv import load\_dotenv
from etl.utils.db import get\_seed\_ids, register\_artifact
load\_dotenv()

def main(path, kind):
site\_id, \_ = get\_seed\_ids()
if not os.path.exists(path):
print(f"File not found: {path}"); return
aid = register\_artifact(site\_id, kind, os.path.abspath(path), epsg=3857,
capture\_started\_at=dt.datetime.utcnow(),
capture\_ended\_at=dt.datetime.utcnow())
print(f"Registered artifact {aid} kind={kind} uri={path}")

if **name**=="**main**":
if len(sys.argv)<3:
print("Usage: load\_artifact.py \<file\_path> <kind> (rgb\_ortho|thermal\_ortho|...)")
sys.exit(1)
main(sys.argv\[1], sys.argv\[2])
EOF
