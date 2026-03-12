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

