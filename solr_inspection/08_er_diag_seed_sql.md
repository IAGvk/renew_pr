An **ER diagram (Mermaid)**, **seed migration files (SQL)** you can run on PostgreSQL + PostGIS (+ optional TimescaleDB), and a **catalog of openly‑available web data sources** you can use to **pre‑seed and test** the pipelines **before** we touch a client dataset.

> **Why these sources?**
>
> *   **PVDAQ** gives real PV time‑series & metadata for many sites (incl. soiling signals). [\[catalog.data.gov\]](https://catalog.data.gov/dataset/photovoltaic-data-acquisition-pvdaq-public-datasets), [\[data.openei.org\]](https://data.openei.org/submissions/4568)
> *   **PV‑IV‑EL** gives IV curves + EL images at module level to validate our IV/EL ingestion. [\[catalog.data.gov\]](https://catalog.data.gov/dataset/photovoltaic-module-current-voltage-and-electroluminescence-image-data-pv-iv-el)
> *   **NSRDB / NASA POWER / PVGIS / ERA5** provide **open irradiance & weather** time‑series for normalization/QC. [\[developer.nlr.gov\]](https://developer.nlr.gov/docs/solar/nsrdb/), [\[nsrdb.nrel.gov\]](https://nsrdb.nrel.gov/), [\[power.larc.nasa.gov\]](https://power.larc.nasa.gov/data-access-viewer/), [\[joint-rese....europa.eu\]](https://joint-research-centre.ec.europa.eu/photovoltaic-geographical-information-system-pvgis_en), [\[cds.climat...ernicus.eu\]](https://cds.climate.copernicus.eu/datasets/reanalysis-era5-single-levels?tab=overview)
> *   **OpenAerialMap** provides free orthomosaics to smoke‑test image ingestion & geospatial plumbing (not always solar, but perfect for pipeline validation). [\[openaerialmap.org\]](https://openaerialmap.org/)
> *   LBNL **Utility‑Scale Solar 2025** offers plant‑level empirical datasets (hourly estimates & value) to test enrichment joins. [\[data.openei.org\]](https://data.openei.org/submissions/8541), [\[emp.lbl.gov\]](https://emp.lbl.gov/utility-scale-solar/)
> *   **Thermal/photogrammetry guidance** underpins our QC flags (irradiance, emissivity, overlap). [\[flir.custhelp.com\]](https://flir.custhelp.com/ci/fattach/get/119551/0/filename/SolarPanel-PV-Inspection-Radiometry.pdf), [\[enterprise...ts.dji.com\]](https://enterprise-insights.dji.com/blog/creating-digital-twins-with-dji-enterprise-drones)

***

## 1) ER Diagram (Mermaid)

> Scope = v1→v2 (future‑proofed for v3 “O\&M Twin‑Light”)\
> Spatial types assume **PostGIS**; time‑series table is compatible with **TimescaleDB** hypertables.



***

## 2) Seed Migration Files (SQL)

> **Assumptions**
>
> *   PostgreSQL 15+, `uuid-ossp` or `pgcrypto` for UUIDs (here I use `gen_random_uuid()` from `pgcrypto`).
> *   `postgis` installed.
> *   Optional: `timescaledb` (commented command shown).
> *   Storage is object‑store (S3/GCS); DB stores URIs + checksums.

### `001_init.sql` – Extensions & Core Tables

```sql
-- 001_init.sql
-- Run as a superuser or a role with CREATE EXTENSION privileges.

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
/* Optional: TimescaleDB for inverter_telemetry hypertable
CREATE EXTENSION IF NOT EXISTS timescaledb;
*/

-- === Orgs & Users ===
CREATE TABLE org (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name               text NOT NULL,
  country_code       char(2),
  created_at         timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE user_account (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email              citext UNIQUE NOT NULL,
  full_name          text,
  password_hash      text,
  created_at         timestamptz NOT NULL DEFAULT now(),
  is_active          boolean NOT NULL DEFAULT true
);

CREATE TABLE org_user_role (
  org_id             uuid REFERENCES org(id) ON DELETE CASCADE,
  user_id            uuid REFERENCES user_account(id) ON DELETE CASCADE,
  role               text CHECK (role IN ('owner','admin','editor','viewer')),
  PRIMARY KEY (org_id, user_id)
);

-- === Sites & Arrays ===
CREATE TABLE site (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id             uuid REFERENCES org(id) ON DELETE CASCADE,
  name               text NOT NULL,
  dc_capacity_mw     numeric(8,3) NOT NULL,
  commissioning_date date,
  timezone           text,
  centroid           geography(point, 4326),
  boundary           geography(polygon, 4326),
  address_line1      text,
  city               text,
  state_region       text,
  country_code       char(2),
  created_at         timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_site_geom ON site USING gist(boundary);

CREATE TABLE array (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id            uuid REFERENCES site(id) ON DELETE CASCADE,
  name               text,
  boundary           geography(polygon, 4326),
  tilt_deg           numeric(5,2),
  azimuth_deg        numeric(6,2),
  created_at         timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_array_geom ON array USING gist(boundary);

-- === Equipment ===
CREATE TABLE equipment (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id            uuid REFERENCES site(id) ON DELETE CASCADE,
  type               text CHECK (type IN ('inverter','combiner','tracker','transformer')),
  make_model         text,
  serial_number      text,
  name               text,
  location           geography(point, 4326),
  created_at         timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_equipment_loc ON equipment USING gist(location);

-- === Ingestion & Artifacts ===
CREATE TABLE ingestion_job (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id            uuid REFERENCES site(id) ON DELETE CASCADE,
  kind               text CHECK (kind IN ('rgb_ortho','thermal_ortho','pointcloud','report')),
  requested_by       uuid REFERENCES user_account(id),
  status             text CHECK (status IN ('queued','processing','complete','error')),
  message            text,
  created_at         timestamptz NOT NULL DEFAULT now(),
  completed_at       timestamptz
);

CREATE TABLE artifact (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id            uuid REFERENCES site(id) ON DELETE CASCADE,
  kind               text CHECK (kind IN ('rgb_ortho','thermal_ortho','flight_log','kml_worldfile','raw_frame_zip')),
  storage_uri        text NOT NULL,
  checksum_sha256    text,
  epsg               int,
  capture_started_at timestamptz,
  capture_ended_at   timestamptz,
  created_at         timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE artifact_version (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  artifact_id        uuid REFERENCES artifact(id) ON DELETE CASCADE,
  pipeline_version   text NOT NULL,
  derived_uri        text,
  metadata_json      jsonb,
  created_at         timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE capture_metadata (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  artifact_id        uuid REFERENCES artifact(id) ON DELETE CASCADE,
  gsd_cm             numeric(6,2),
  overlap_front_pct  numeric(5,2),
  overlap_side_pct   numeric(5,2),
  emissivity         numeric(4,3),
  irradiance_wm2     numeric(7,2),
  wind_ms            numeric(5,2),
  ambient_c          numeric(5,2),
  notes              text,
  qc_flags           text[]
);

-- === Detections, Impact & Priority ===
CREATE TABLE detection (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id            uuid REFERENCES site(id) ON DELETE CASCADE,
  artifact_id        uuid REFERENCES artifact(id) ON DELETE SET NULL,
  type               text CHECK (type IN ('SOILING','VEGETATION','HOTSPOT','CRACK','OTHER')),
  confidence         numeric(4,3) CHECK (confidence BETWEEN 0 AND 1),
  geom               geography(polygon, 4326),
  stats_json         jsonb,
  created_at         timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_detection_geom ON detection USING gist(geom);

CREATE TABLE detection_cluster (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id            uuid REFERENCES site(id) ON DELETE CASCADE,
  type               text CHECK (type IN ('SOILING','VEGETATION','HOTSPOT')),
  geom               geography(polygon, 4326),
  severity           text CHECK (severity IN ('low','med','high')),
  created_at         timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_detection_cluster_geom ON detection_cluster USING gist(geom);

CREATE TABLE impact_estimate (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id            uuid REFERENCES site(id) ON DELETE CASCADE,
  detection_id       uuid REFERENCES detection(id) ON DELETE CASCADE,
  method_version     text NOT NULL,
  delta_mwh_year     numeric(10,3) NOT NULL,
  delta_value_year   numeric(12,2) NOT NULL,
  payback_months     numeric(8,2),
  assumptions_json   jsonb,
  created_at         timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE priority_queue (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id            uuid REFERENCES site(id) ON DELETE CASCADE,
  detection_id       uuid REFERENCES detection(id) ON DELETE CASCADE,
  rank_score         numeric(6,3),
  rationale          text,
  status             text CHECK (status IN ('proposed','scheduled','in_progress','done','deferred')),
  created_at         timestamptz NOT NULL DEFAULT now(),
  updated_at         timestamptz
);

-- === Work Orders & Crews ===
CREATE TABLE work_order (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id            uuid REFERENCES site(id) ON DELETE CASCADE,
  title              text NOT NULL,
  description        text,
  status             text CHECK (status IN ('open','assigned','in_progress','complete','cancelled')),
  planned_start      timestamptz,
  planned_end        timestamptz,
  created_at         timestamptz NOT NULL DEFAULT now(),
  updated_at         timestamptz
);

CREATE TABLE work_order_item (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  work_order_id      uuid REFERENCES work_order(id) ON DELETE CASCADE,
  detection_id       uuid REFERENCES detection(id) ON DELETE SET NULL,
  action             text CHECK (action IN ('CLEAN','TRIM_VEGETATION','REPAIR_STRING','INSPECT_MANUAL','REPLACE_MODULE')),
  location           geography(point, 4326),
  estimate_hours     numeric(6,2),
  estimate_cost      numeric(12,2),
  created_at         timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_work_item_loc ON work_order_item USING gist(location);

-- === Time Series & IV ===
CREATE TABLE inverter_telemetry (
  site_id            uuid NOT NULL REFERENCES site(id) ON DELETE CASCADE,
  equipment_id       uuid NOT NULL REFERENCES equipment(id) ON DELETE CASCADE,
  ts                 timestamptz NOT NULL,
  energy_wh          bigint,
  power_w            bigint,
  dc_voltage_v       numeric(10,2),
  dc_current_a       numeric(10,2),
  temperature_c      numeric(6,2),
  source_meta        jsonb,
  PRIMARY KEY (site_id, equipment_id, ts)
);
CREATE INDEX IF NOT EXISTS idx_inv_ts ON inverter_telemetry (site_id, ts DESC);
/* Optional Timescale hypertable
SELECT create_hypertable('inverter_telemetry','ts', if_not_exists => TRUE);
*/

CREATE TABLE iv_curve (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id            uuid REFERENCES site(id) ON DELETE CASCADE,
  equipment_id       uuid REFERENCES equipment(id) ON DELETE SET NULL,
  ts                 timestamptz NOT NULL,
  method             text CHECK (method IN ('SMART_IV','FIELD_TRACER','LAB')),
  meta_json          jsonb,
  created_at         timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE iv_curve_point (
  iv_curve_id        uuid REFERENCES iv_curve(id) ON DELETE CASCADE,
  idx                int NOT NULL,
  voltage_v          numeric(10,3) NOT NULL,
  current_a          numeric(10,3) NOT NULL,
  PRIMARY KEY (iv_curve_id, idx)
);

-- === Settings, Calibration, Weather, QC ===
CREATE TABLE settings_roi (
  site_id            uuid PRIMARY KEY REFERENCES site(id) ON DELETE CASCADE,
  currency           text DEFAULT 'USD',
  energy_price_per_mwh numeric(10,2),
  labor_rate_per_hour  numeric(10,2),
  cleaning_cost_per_m2 numeric(10,2),
  vegetation_cost_per_m2 numeric(10,2),
  json_extras          jsonb,
  updated_at           timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE calibration_baseline (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id            uuid REFERENCES site(id) ON DELETE CASCADE,
  window_start       date NOT NULL,
  window_end         date NOT NULL,
  modeled_mwh        numeric(12,3),
  observed_mwh       numeric(12,3),
  scaling_factor     numeric(6,4),
  created_at         timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE weather_snapshot (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id            uuid REFERENCES site(id) ON DELETE CASCADE,
  ts                 timestamptz NOT NULL,
  source             text,
  ghi_wm2            numeric(8,2),
  temp_c             numeric(5,2),
  wind_ms            numeric(5,2),
  cloud_okta         numeric(3,1),
  created_at         timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE qc_flag (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  artifact_id        uuid REFERENCES artifact(id) ON DELETE CASCADE,
  code               text,
  severity           text CHECK (severity IN ('info','warn','fail')),
  notes              text,
  created_at         timestamptz NOT NULL DEFAULT now()
);

-- === Crews & Routes ===
CREATE TABLE crew (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id             uuid REFERENCES org(id) ON DELETE CASCADE,
  name               text,
  home_base          geography(point, 4326),
  created_at         timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_crew_home ON crew USING gist(home_base);

CREATE TABLE crew_shift (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  crew_id            uuid REFERENCES crew(id) ON DELETE CASCADE,
  shift_date         date NOT NULL,
  start_time_local   time NOT NULL,
  end_time_local     time NOT NULL,
  capacity_hours     numeric(6,2),
  created_at         timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE route_plan (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  crew_id            uuid REFERENCES crew(id) ON DELETE CASCADE,
  work_order_id      uuid REFERENCES work_order(id) ON DELETE CASCADE,
  planned_start      timestamptz,
  planned_end        timestamptz,
  route_geo          geography(linestring, 4326),
  created_at         timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_route_geo ON route_plan USING gist(route_geo);
```

***

### `002_seed.sql` – Minimal Seed + Public Test Links

> These inserts give you one **org/site**, a sample **inverter**, and a few **artifacts** that point to open datasets for pipeline smoke tests.

```sql
-- 002_seed.sql

-- Org & user
INSERT INTO org (name, country_code) VALUES ('Amplyfy Pilot Org','AU');

INSERT INTO user_account (email, full_name, password_hash)
VALUES ('ops@amplyfy.example','Ops User','$2b$12$seedONLY');

INSERT INTO org_user_role (org_id, user_id, role)
SELECT o.id, u.id, 'owner'
FROM org o, user_account u
WHERE o.name='Amplyfy Pilot Org' AND u.email='ops@amplyfy.example';

-- Site (dummy boundary around a test polygon in NSW)
INSERT INTO site (org_id, name, dc_capacity_mw, commissioning_date, timezone, centroid, boundary, address_line1, city, state_region, country_code)
SELECT o.id, 'Pilot C&I Rooftop', 3.000, '2020-03-01', 'Australia/Sydney',
       ST_SetSRID(ST_MakePoint(151.205, -33.870),4326)::geography,
       ST_GeogFromText('POLYGON((151.2045 -33.8696,151.2056 -33.8696,151.2056 -33.8704,151.2045 -33.8704,151.2045 -33.8696))'),
       '123 George St','Sydney','NSW','AU'
FROM org o WHERE o.name='Amplyfy Pilot Org';

-- Equipment (one inverter)
INSERT INTO equipment (site_id, type, make_model, serial_number, name, location)
SELECT s.id, 'inverter', 'SMA STP', 'SMA-INV-001', 'INV-1',
       s.centroid
FROM site s WHERE s.name='Pilot C&I Rooftop';

-- Settings
INSERT INTO settings_roi (site_id, currency, energy_price_per_mwh, labor_rate_per_hour, cleaning_cost_per_m2, vegetation_cost_per_m2, json_extras)
SELECT s.id, 'AUD', 140.00, 85.00, 0.45, 0.35, '{}'
FROM site s WHERE s.name='Pilot C&I Rooftop';

-- Artifacts (URIs to open data for testing ingestion plumbing)

-- RGB orthomosaic placeholder from OpenAerialMap (example URL; replace with a specific item you select)
INSERT INTO artifact (site_id, kind, storage_uri, epsg, capture_started_at, capture_ended_at)
SELECT s.id, 'rgb_ortho',
       'https://api.openaerialmap.org/tiles/{oam_item_id}/0/0/0.png',
       3857, now()-interval '10 days', now()-interval '10 days' + interval '30 minutes'
FROM site s WHERE s.name='Pilot C&I Rooftop';

-- Thermal guidance: we don’t have public solar thermal orthos; use this record as a stub for pipeline tests
INSERT INTO artifact (site_id, kind, storage_uri, epsg, capture_started_at, capture_ended_at)
SELECT s.id, 'thermal_ortho',
       's3://your-bucket/thermal/pilot_20240301_orthomosaic.tif', -- replace with your test asset
       3857, now()-interval '10 days', now()-interval '10 days' + interval '30 minutes'
FROM site s WHERE s.name='Pilot C&I Rooftop';

-- Link a capture metadata with QC flags (overlap, emissivity & irradiance)
INSERT INTO capture_metadata (artifact_id, gsd_cm, overlap_front_pct, overlap_side_pct, emissivity, irradiance_wm2, wind_ms, ambient_c, notes, qc_flags)
SELECT a.id, 2.50, 75.0, 70.0, 0.95, 800.0, 2.5, 24.0, 'Daytime flight; radiometric; panel under load', ARRAY['OK']
FROM artifact a
JOIN site s ON s.id=a.site_id
WHERE s.name='Pilot C&I Rooftop' AND a.kind='thermal_ortho';

-- Weather snapshots using open sources (seed a couple of rows; later we’ll backfill via ETL)
INSERT INTO weather_snapshot (site_id, ts, source, ghi_wm2, temp_c, wind_ms, cloud_okta)
SELECT s.id, now()-interval '10 days', 'NASA_POWER', 780, 23.0, 2.0, 1.0
FROM site s WHERE s.name='Pilot C&I Rooftop';

-- Inverter telemetry (stub)
INSERT INTO inverter_telemetry (site_id, equipment_id, ts, energy_wh, power_w, dc_voltage_v, dc_current_a, temperature_c, source_meta)
SELECT s.id, e.id, now()-interval '1 day', 1523400, 23000, 780.0, 30.5, 46.0, '{"source":"CSV_UPLOAD"}'::jsonb
FROM site s JOIN equipment e ON e.site_id=s.id
WHERE s.name='Pilot C&I Rooftop' AND e.name='INV-1';
```

> **Notes on imagery seeds:**
>
> *   You can pick any **OpenAerialMap item** and paste its tile/GeoTIFF URL for the RGB artifact to validate ingestion, georeferencing, and mask rendering without a client dataset. [\[openaerialmap.org\]](https://openaerialmap.org/)
> *   For **thermal**, there’s no high‑quality open PV thermal orthomosaic corpus; we’ll validate thermal ingestion with your own test export while using **industry QC rules** (irradiance, emissivity, overlap) drawn from FLIR and others. [\[flir.custhelp.com\]](https://flir.custhelp.com/ci/fattach/get/119551/0/filename/SolarPanel-PV-Inspection-Radiometry.pdf)

***

## 3) Open Web Data Sources (for pre‑client testing)

> Organized by the **inputs our product needs**. Each bullet contains a link and how we’ll use it.

### A) **PV Performance Time‑Series & Metadata**

*   **PVDAQ** – multi‑site PV performance time‑series, metadata & some environmental sensors; public S3 (CSV/Parquet) & docs. Use it to populate `inverter_telemetry` (site‑level or derived). [\[catalog.data.gov\]](https://catalog.data.gov/dataset/photovoltaic-data-acquisition-pvdaq-public-datasets), [\[data.openei.org\]](https://data.openei.org/submissions/4568)
*   **DuraMAT Hub (PVDAQ subsets & method datasets)** – labeled soiling signals, clipping datasets, synthetic PV performance, etc. Great for analytics unit tests. [\[datahub.duramat.org\]](https://datahub.duramat.org/dataset?vocab_institution=NREL\&organization=example-data)
*   **LBNL Utility‑Scale Solar 2025** – plant‑level hourly generation estimates & market value; good for enrichment & benchmarking. [\[data.openei.org\]](https://data.openei.org/submissions/8541), [\[emp.lbl.gov\]](https://emp.lbl.gov/utility-scale-solar/)

### B) **IV Curves & EL Images (module‑level)**

*   **PV‑IV‑EL (Sandia)** – 613 sets of paired IV curves + EL images across many modules (0–5 years outdoor exposure). Use to test `iv_curve*` ingestion & linkage to imagery. [\[catalog.data.gov\]](https://catalog.data.gov/dataset/photovoltaic-module-current-voltage-and-electroluminescence-image-data-pv-iv-el)
*   **EL image benchmarks** – Jülich/ZAE Bayern “ELPV” and multi‑source GitHub sets for segmentation training/tests. [\[data-legac...juelich.de\]](https://data-legacy.fz-juelich.de/dataset.xhtml?persistentId=doi:10.26165/JUELICH-DATA/GCBNMA), [\[github.com\]](https://github.com/TheMakiran/BenchmarkELimages)

### C) **Irradiance & Weather (QC, normalization, quick baselines)**

*   **NASA POWER** – global solar & met time‑series via REST (hourly/daily/monthly) & Data Access Viewer + SDKs. Use to backfill `weather_snapshot` & basic normalization. [\[power.larc.nasa.gov\]](https://power.larc.nasa.gov/data-access-viewer/), [\[registry.o...endata.aws\]](https://registry.opendata.aws/nasa-power/)
*   **NSRDB** – US (& growing international) irradiance time‑series, API & open buckets; multiple cadences (e.g., GOES 5‑min/10‑min). Use for high‑frequency irradiance where available. [\[developer.nlr.gov\]](https://developer.nlr.gov/docs/solar/nsrdb/), [\[registry.o...endata.aws\]](https://registry.opendata.aws/nrel-pds-nsrdb/)
*   **PVGIS** – global radiation & PV performance APIs, especially strong for EU; useful for cross‑checks & typical meteorological years. [\[joint-rese....europa.eu\]](https://joint-research-centre.ec.europa.eu/photovoltaic-geographical-information-system-pvgis_en)
*   **ERA5 (C3S/ECMWF)** – global hourly reanalysis; backfill wind, temperature; useful for QC when on‑site data absent. [\[cds.climat...ernicus.eu\]](https://cds.climate.copernicus.eu/datasets/reanalysis-era5-single-levels?tab=overview), [\[ecmwf.int\]](https://www.ecmwf.int/en/forecasts/dataset/ecmwf-reanalysis-v5)

### D) **Orthomosaics / Photogrammetry (pipeline smoke tests)**

*   **OpenAerialMap** – open orthomosaics & tiles (various sensors). Use to test `artifact` ingestion, tiling, CRS handling, and `detection` geometry writes (even if not solar). [\[openaerialmap.org\]](https://openaerialmap.org/)
*   **DJI Enterprise guidance** – best practices for overlap, mission planning for digital twin photogrammetry—supports our `capture_metadata` QC. [\[enterprise...ts.dji.com\]](https://enterprise-insights.dji.com/blog/creating-digital-twins-with-dji-enterprise-drones)

### E) **Thermal Inspection Guidance (QC rules for flags)**

*   **FLIR: “Using Thermal Imaging Drones for PV”** – irradiance, emissivity, under‑load conditions—our QC flags & flight checklist mirror these. [\[flir.custhelp.com\]](https://flir.custhelp.com/ci/fattach/get/119551/0/filename/SolarPanel-PV-Inspection-Radiometry.pdf)
*   **Raptor Maps flight guidelines** – overlap ratios, radiometric requirements (e.g., ≥600 W/m²), camera settings—useful to codify `qc_flag`. [\[pages.raptormaps.com\]](https://pages.raptormaps.com/raptor-maps-knowledge-hub/solar-pv-inspection-drone-flight-guidelines)
*   **PV‑Tech (Buerhop‑Lutz)** – drone thermography background & fault classes; good for annotating `stats_json` conventions. [\[pv-tech.org\]](https://www.pv-tech.org/wp-content/uploads/legacy-publication-pdfs/e572eda928-inspection-of-pv-plants-using-dronemounted-thermography.pdf)

***

## 4) How to Test the Ingestion Now (no client data)

1.  **Create DB & run migrations**
    *   `psql -f 001_init.sql`
    *   `psql -f 002_seed.sql`
2.  **Backfill weather** for the seed site using **NASA POWER** (hourly GHI/temp/wind); write to `weather_snapshot`. (POWER offers a web viewer & REST API.) [\[power.larc.nasa.gov\]](https://power.larc.nasa.gov/data-access-viewer/)
3.  **Load PVDAQ** sample time‑series (choose a system → CSV) → upsert into `inverter_telemetry` for a “mock” site to validate time‑series queries & ΔMWh calibration workflows. [\[data.openei.org\]](https://data.openei.org/submissions/4568)
4.  **Load IV/EL** from **PV‑IV‑EL** → populate `iv_curve*` and store EL image URIs as `artifact` rows (kind=`report` or `raw_frame_zip`) to validate pairing logic. [\[catalog.data.gov\]](https://catalog.data.gov/dataset/photovoltaic-module-current-voltage-and-electroluminescence-image-data-pv-iv-el)
5.  **Image pipeline smoke test**
    *   Use an **OpenAerialMap** RGB ortho (GeoTIFF/tile) → `artifact.kind='rgb_ortho'` → run the soiling/vegetation model stub to ensure `detection.geom` + `impact_estimate` writes are sound. [\[openaerialmap.org\]](https://openaerialmap.org/)
    *   For **thermal**, use any internal radiometric orthomosaic export to validate ingestion + QC flags (e.g., `LOW_IRRADIANCE`); the **FLIR** rules guide our QC expectations. [\[flir.custhelp.com\]](https://flir.custhelp.com/ci/fattach/get/119551/0/filename/SolarPanel-PV-Inspection-Radiometry.pdf)

***

## 5) Why this is enough to validate end‑to‑end (before first client)

*   **We can simulate** v1/v2 flows (ingest → detect → ΔMWh/$ → prioritize → WO) using **open PV time‑series** (PVDAQ), **open irradiance** (POWER/NSRDB/PVGIS/ERA5), **real IV+EL lab data** (PV‑IV‑EL), and **free orthomosaics** (OpenAerialMap) to test the geospatial & analytics stack—even though public **solar thermal orthos** are scarce. [\[data.openei.org\]](https://data.openei.org/submissions/4568), [\[power.larc.nasa.gov\]](https://power.larc.nasa.gov/data-access-viewer/), [\[catalog.data.gov\]](https://catalog.data.gov/dataset/photovoltaic-module-current-voltage-and-electroluminescence-image-data-pv-iv-el), [\[openaerialmap.org\]](https://openaerialmap.org/)
*   Our **image QC criteria** (overlap, emissivity, irradiance) are traceable to industry guidance, so any synthetic or non‑PV ortho still validates pipeline behavior & QC flagging. [\[flir.custhelp.com\]](https://flir.custhelp.com/ci/fattach/get/119551/0/filename/SolarPanel-PV-Inspection-Radiometry.pdf), [\[enterprise...ts.dji.com\]](https://enterprise-insights.dji.com/blog/creating-digital-twins-with-dji-enterprise-drones)

***

## 6) Optional: Make `inverter_telemetry` a hypertable (TimescaleDB)

```sql
-- 003_timescale.sql (optional)
SELECT create_hypertable('inverter_telemetry','ts', if_not_exists => TRUE);
CREATE INDEX IF NOT EXISTS idx_inv_ts_equipment ON inverter_telemetry (equipment_id, ts DESC);
```

***

###  Next Steps :

*   **Bundle these SQL files into a repo scaffold** with a minimal **ETL notebook** that pulls NASA POWER & PVDAQ for the seeded site, and a tiny **Python loader** to populate `weather_snapshot` and `inverter_telemetry` from those APIs. 
*   (POWER & NSRDB both provide REST endpoints/SDKs for rapid prototyping.) [\[power.larc.nasa.gov\]](https://power.larc.nasa.gov/data-access-viewer/), [\[developer.nlr.gov\]](https://developer.nlr.gov/docs/solar/nsrdb/)
