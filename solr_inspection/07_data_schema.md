A **production‑ready data schema** for our combined product (v1 → v2), designed for PostgreSQL 15+ with **PostGIS** for geospatial fields and **TimescaleDB** (optional) for high‑volume time series (inverter/IV). I’ve annotated design choices that depend on real‑world constraints (e.g., radiometric thermography, inverter data patterns, RGB soiling feasibility) with citations to industry sources we already reviewed. Where helpful, I’ve provided **DDL snippets**; you can paste them into a migration file as a starting point.

***

## 0) Design Goals

*   **v1 (MVP)**: ingest **RGB/thermal orthomosaics** + minimal site metadata; run **soiling/vegetation/hotspot detections**; compute **ΔMWh/$** and create **prioritized work orders**.  
    *Why:* RGB soiling detection from UAV imagery is viable; thermal hotspot detection requires radiometric captures under appropriate irradiance/operating conditions. [\[docs.nrel.gov\]](https://docs.nrel.gov/docs/fy24osti/85819.pdf), [\[nlr.gov\]](https://www.nlr.gov/solar/market-research-analysis/solar-system-operations-maintenance-analysis)

*   **v2 (Pro)**: add **inverter energy time series**, **(Smart) IV curves**, **crew scheduling/route optimization**, and **deeper calibration** of predicted losses to observed production.  
    *Why:* Inverter time series are commonly available from plants and support availability/underperformance analytics; Smart‑IV scans are widely deployed and strengthen diagnostics. [\[docs.nrel.gov\]](https://docs.nrel.gov/docs/fy23osti/86721.pdf), [\[docs.nrel.gov\]](https://docs.nrel.gov/docs/fy25osti/91775.pdf)

*   **Forward compatibility to v3** (O\&M Digital‑Twin‑Light): 3D model references + temporal layers over drone‑derived maps without requiring PVSyst/CAD (engineering twins). Photogrammetry‑first twins are feasible from drone captures with controlled overlap/GSD. [\[iea.org\]](https://www.iea.org/reports/renewables-2023)

***

## 1) High‑Level Entity Map

**Organizations & Access**

*   `org`, `user_account`, `org_user_role`

**Assets & Topology**

*   `site` (plant), `array` (optional granularity), `equipment` (inverters/combiner/transformers)

**Data Ingestion & Artifacts**

*   `ingestion_job`, `artifact` (orthomosaics/point clouds), `artifact_version`, `capture_metadata` (GSD, overlap, emissivity, irradiance snapshot, etc.)

**Detections & Analytics**

*   `detection` (soiling/veg/hotspot), `detection_cluster`, `impact_estimate` (ΔMWh/$), `priority_queue` (ranked actions)

**Work Execution**

*   `work_order`, `work_order_item`, `crew`, `crew_shift`, `route_plan`

**Time Series & IV (v2)**

*   `inverter_telemetry` (energy/power/temperature), `iv_curve`, `iv_curve_point`

**Reference / Context**

*   `weather_snapshot` (at capture), `cost_model`, `settings_roi`, `qc_flag`

**Audit & Lineage**

*   `event_log`, `data_lineage`, `consent_record` (portal/API auth, if any)

***

## 2) Core DDL (v1 Minimal)

> Notes:  
> • Use **PostGIS** for `geometry` / `geography` fields.  
> • Use **uuid** primary keys.  
> • All files (imagery, reports) are stored in object storage (e.g., S3); DB keeps **URIs** + checksums.  
> • Time in UTC; store local timezone on `site` for reporting.

### 2.1 Organizations & Users

```sql
create extension if not exists postgis;

create table org (
  id                 uuid primary key default gen_random_uuid(),
  name               text not null,
  country_code       char(2),
  created_at         timestamptz not null default now()
);

create table user_account (
  id                 uuid primary key default gen_random_uuid(),
  email              citext unique not null,
  full_name          text,
  password_hash      text,
  created_at         timestamptz not null default now(),
  is_active          boolean not null default true
);

create table org_user_role (
  org_id             uuid references org(id) on delete cascade,
  user_id            uuid references user_account(id) on delete cascade,
  role               text check (role in ('owner','admin','editor','viewer')),
  primary key (org_id, user_id)
);
```

### 2.2 Sites & Arrays

```sql
create table site (
  id                 uuid primary key default gen_random_uuid(),
  org_id             uuid references org(id) on delete cascade,
  name               text not null,
  dc_capacity_mw     numeric(8,3) not null, -- MWdc
  commissioning_date date,
  timezone           text,                  -- e.g., "Australia/Sydney"
  centroid           geography(point, 4326),
  boundary           geography(polygon, 4326),
  address_line1      text,
  city               text,
  state_region       text,
  country_code       char(2),
  created_at         timestamptz not null default now()
);

create table array (
  id                 uuid primary key default gen_random_uuid(),
  site_id            uuid references site(id) on delete cascade,
  name               text,
  boundary           geography(polygon, 4326),
  tilt_deg           numeric(5,2),
  azimuth_deg        numeric(6,2),
  created_at         timestamptz not null default now()
);
```

### 2.3 Equipment (minimal for v1; expand in v2)

```sql
create table equipment (
  id                 uuid primary key default gen_random_uuid(),
  site_id            uuid references site(id) on delete cascade,
  type               text check (type in ('inverter','combiner','tracker','transformer')),
  make_model         text,
  serial_number      text,
  name               text,
  location           geography(point, 4326),
  created_at         timestamptz not null default now()
);
```

### 2.4 Ingestion, Artifacts & Capture Metadata

```sql
create table ingestion_job (
  id                 uuid primary key default gen_random_uuid(),
  site_id            uuid references site(id) on delete cascade,
  kind               text check (kind in ('rgb_ortho','thermal_ortho','pointcloud','report')),
  requested_by       uuid references user_account(id),
  status             text check (status in ('queued','processing','complete','error')),
  message            text,
  created_at         timestamptz not null default now(),
  completed_at       timestamptz
);

create table artifact (
  id                 uuid primary key default gen_random_uuid(),
  site_id            uuid references site(id) on delete cascade,
  kind               text check (kind in ('rgb_ortho','thermal_ortho','flight_log','kml_worldfile','raw_frame_zip')),
  storage_uri        text not null,
  checksum_sha256    text,
  epsg               int,
  capture_started_at timestamptz,
  capture_ended_at   timestamptz,
  created_at         timestamptz not null default now()
);

create table artifact_version ( -- for reprocessing without data loss
  id                 uuid primary key default gen_random_uuid(),
  artifact_id        uuid references artifact(id) on delete cascade,
  pipeline_version   text not null,
  derived_uri        text,            -- e.g., tiled cloud-optimized GeoTIFF
  metadata_json      jsonb,           -- camera model, firmware, etc.
  created_at         timestamptz not null default now()
);

create table capture_metadata (
  id                 uuid primary key default gen_random_uuid(),
  artifact_id        uuid references artifact(id) on delete cascade,
  gsd_cm             numeric(6,2),     -- ground sampling distance (RGB)
  overlap_front_pct  numeric(5,2),
  overlap_side_pct   numeric(5,2),
  emissivity         numeric(4,3),     -- thermal settings, if provided
  irradiance_wm2     numeric(7,2),     -- snapshot at capture (optional)
  wind_ms            numeric(5,2),
  ambient_c          numeric(5,2),
  notes              text,
  qc_flags           text[]            -- e.g., ['low_irradiance','motion_blur']
);
```

> **Why store emissivity/irradiance/wind?** Thermal inspection reliability depends on emissivity and on capturing when modules are under load with adequate irradiance; wind can reduce temperature deltas and hide hotspots. These are well‑documented field constraints. [\[nlr.gov\]](https://www.nlr.gov/solar/market-research-analysis/solar-system-operations-maintenance-analysis)

### 2.5 Detections & Impact

```sql
create table detection (
  id                 uuid primary key default gen_random_uuid(),
  site_id            uuid references site(id) on delete cascade,
  artifact_id        uuid references artifact(id) on delete set null,
  type               text check (type in ('SOILING','VEGETATION','HOTSPOT','CRACK','OTHER')),
  confidence         numeric(4,3) check (confidence between 0 and 1),
  geom               geography(polygon, 4326), -- mask or bbox
  stats_json         jsonb,  -- e.g., soiling index, thermal delta, area m2
  created_at         timestamptz not null default now()
);

create table detection_cluster (
  id                 uuid primary key default gen_random_uuid(),
  site_id            uuid references site(id) on delete cascade,
  type               text check (type in ('SOILING','VEGETATION','HOTSPOT')),
  geom               geography(polygon, 4326),
  severity           text check (severity in ('low','med','high')),
  created_at         timestamptz not null default now()
);

create table impact_estimate (
  id                 uuid primary key default gen_random_uuid(),
  site_id            uuid references site(id) on delete cascade,
  detection_id       uuid references detection(id) on delete cascade,
  method_version     text not null,       -- model version
  delta_mwh_year     numeric(10,3) not null,
  delta_value_year   numeric(12,2) not null, -- currency default at org/site level
  payback_months     numeric(8,2),
  assumptions_json   jsonb,               -- tariff, PR, baseline
  created_at         timestamptz not null default now()
);
```

> **Why SOILING via RGB?** Peer‑reviewed work shows UAV RGB imagery with attention‑based object detection can accurately identify dust/bird droppings and similar soiling classes at useful precision, making RGB a cost‑effective modality for C\&I. [\[docs.nrel.gov\]](https://docs.nrel.gov/docs/fy24osti/85819.pdf)

### 2.6 Priorities & Work Orders

```sql
create table priority_queue (
  id                 uuid primary key default gen_random_uuid(),
  site_id            uuid references site(id) on delete cascade,
  detection_id       uuid references detection(id) on delete cascade,
  rank_score         numeric(6,3),      -- composite of ΔMWh/$, urgency, clustering
  rationale          text,              -- model explanation
  status             text check (status in ('proposed','scheduled','in_progress','done','deferred')),
  created_at         timestamptz not null default now(),
  updated_at         timestamptz
);

create table work_order (
  id                 uuid primary key default gen_random_uuid(),
  site_id            uuid references site(id) on delete cascade,
  title              text not null,
  description        text,
  status             text check (status in ('open','assigned','in_progress','complete','cancelled')),
  planned_start      timestamptz,
  planned_end        timestamptz,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz
);

create table work_order_item (
  id                 uuid primary key default gen_random_uuid(),
  work_order_id      uuid references work_order(id) on delete cascade,
  detection_id       uuid references detection(id) on delete set null,
  action             text check (action in ('CLEAN','TRIM_VEGETATION','REPAIR_STRING','INSPECT_MANUAL','REPLACE_MODULE')),
  location           geography(point, 4326),
  estimate_hours     numeric(6,2),
  estimate_cost      numeric(12,2),
  created_at         timestamptz not null default now()
);
```

***

## 3) v2 Extensions (Time Series, IV, Crew, Calibration)

### 3.1 Inverter Telemetry (Timescale‑ready)

```sql
-- If using TimescaleDB:
-- select create_hypertable('inverter_telemetry', 'ts', chunk_time_interval => interval '7 days');

create table inverter_telemetry (
  site_id            uuid not null references site(id) on delete cascade,
  equipment_id       uuid not null references equipment(id) on delete cascade, -- inverter
  ts                 timestamptz not null,
  energy_wh          bigint,  -- cumulative or interval depending on source; store source in meta
  power_w            bigint,
  dc_voltage_v       numeric(10,2),
  dc_current_a       numeric(10,2),
  temperature_c      numeric(6,2),
  source_meta        jsonb,
  primary key (site_id, equipment_id, ts)
);
create index on inverter_telemetry (site_id, ts desc);
```

> **Why this matters:** inverter time‑series enable distinguishing **true outages vs SCADA gaps** and quantifying availability. Large fleet studies use similar derived metrics across 1000+ systems. [\[docs.nrel.gov\]](https://docs.nrel.gov/docs/fy23osti/86721.pdf)

### 3.2 IV Curves

```sql
create table iv_curve (
  id                 uuid primary key default gen_random_uuid(),
  site_id            uuid references site(id) on delete cascade,
  equipment_id       uuid references equipment(id) on delete set null,
  ts                 timestamptz not null,
  method             text check (method in ('SMART_IV','FIELD_TRACER','LAB')),
  meta_json          jsonb,  -- irradiance, module type, string id, etc.
  created_at         timestamptz not null default now()
);

create table iv_curve_point (
  iv_curve_id        uuid references iv_curve(id) on delete cascade,
  idx                int not null,
  voltage_v          numeric(10,3) not null,
  current_a          numeric(10,3) not null,
  primary key (iv_curve_id, idx)
);
```

> **Note:** Smart‑IV (e.g., Huawei) is already deployed at multi‑GW scale and provides automated diagnostics; we ingest summaries or full curves where available. [\[docs.nrel.gov\]](https://docs.nrel.gov/docs/fy25osti/91775.pdf)

### 3.3 Calibration & Model Settings

```sql
create table settings_roi (
  site_id            uuid primary key references site(id) on delete cascade,
  currency           text default 'USD',
  energy_price_per_mwh numeric(10,2),   -- blended or time-weighted in future
  labor_rate_per_hour  numeric(10,2),
  cleaning_cost_per_m2 numeric(10,2),
  vegetation_cost_per_m2 numeric(10,2),
  json_extras          jsonb,
  updated_at           timestamptz not null default now()
);

create table calibration_baseline (
  id                 uuid primary key default gen_random_uuid(),
  site_id            uuid references site(id) on delete cascade,
  window_start       date not null,
  window_end         date not null,
  modeled_mwh        numeric(12,3),
  observed_mwh       numeric(12,3),
  scaling_factor     numeric(6,4),       -- used to align model to plant behavior
  created_at         timestamptz not null default now()
);
```

### 3.4 Crew & Routing

```sql
create table crew (
  id                 uuid primary key default gen_random_uuid(),
  org_id             uuid references org(id) on delete cascade,
  name               text,
  home_base          geography(point, 4326),
  created_at         timestamptz not null default now()
);

create table crew_shift (
  id                 uuid primary key default gen_random_uuid(),
  crew_id            uuid references crew(id) on delete cascade,
  shift_date         date not null,
  start_time_local   time not null,
  end_time_local     time not null,
  capacity_hours     numeric(6,2),
  created_at         timestamptz not null default now()
);

create table route_plan (
  id                 uuid primary key default gen_random_uuid(),
  crew_id            uuid references crew(id) on delete cascade,
  work_order_id      uuid references work_order(id) on delete cascade,
  planned_start      timestamptz,
  planned_end        timestamptz,
  route_geo          geography(linestring, 4326),
  created_at         timestamptz not null default now()
);
```

***

## 4) Reference / QC / Weather (Capture‑Time Context)

```sql
create table weather_snapshot (
  id                 uuid primary key default gen_random_uuid(),
  site_id            uuid references site(id) on delete cascade,
  ts                 timestamptz not null,
  source             text,      -- e.g., on-site sensor, reanalysis
  ghi_wm2            numeric(8,2),    -- global horizontal irradiance
  temp_c             numeric(5,2),
  wind_ms            numeric(5,2),
  cloud_okta         numeric(3,1),
  created_at         timestamptz not null default now()
);

create table qc_flag (
  id                 uuid primary key default gen_random_uuid(),
  artifact_id        uuid references artifact(id) on delete cascade,
  code               text,   -- e.g., 'LOW_IRRADIANCE', 'MOTION_BLUR', 'BAD_GSD'
  severity           text check (severity in ('info','warn','fail')),
  notes              text,
  created_at         timestamptz not null default now()
);
```

> **Why:** we persist capture conditions (irradiance/load/wind) because thermal anomalies are sensitive to these parameters and re‑flights are expensive when QC fails. [\[nlr.gov\]](https://www.nlr.gov/solar/market-research-analysis/solar-system-operations-maintenance-analysis)

***

## 5) Indices, Partitioning & Retention

*   **Spatial**: GIST indexes on `boundary`, `geom`, `location`, `route_geo`.  
    `create index on detection using gist(geom);`
*   **Time series**: Partition or **TimescaleDB hypertables** for `inverter_telemetry`.
*   **Large blobs**: keep images in object storage; store **URIs + checksums** in `artifact`/`artifact_version`.
*   **Retention**: raw frames optional; keep orthomosaics + derived masks; maintain lineage via `artifact_version`.

***

## 6) Data Contracts (CSV/API) – Minimum v1/v2

### 6.1 Inverter CSV (v2)

    timestamp_utc, inverter_id, metric, value, unit
    2026-02-01T00:00:00Z, INV-1, ENERGY_WH, 154320, Wh
    2026-02-01T00:00:00Z, INV-1, POWER_W,  20450,  W
    ...

*   Allow **wide** format (one column per metric) or **long** format (above).
*   Metadata: inverter name ↔ `equipment` mapping.

### 6.2 IV Curve CSV (v2)

    timestamp_utc, string_id, point_index, voltage_v, current_a, ghi_wm2, cell_temp_c, method

### 6.3 Artifact Manifest (v1)

    artifact_kind, uri, epsg, capture_started_utc, capture_ended_utc, gsd_cm, frontlap_pct, sidelap_pct, emissivity, notes

***

## 7) How the Schema Delivers v1 → v2

*   **v1** needs only: `site`, `artifact`(+`capture_metadata`), `detection`, `impact_estimate`, `priority_queue`, `work_order` (+items).
*   **v2** activates: `inverter_telemetry`, `iv_curve*`, `settings_roi`, `calibration_baseline`, `crew*`, `route_plan`.

***

## 8) Why this schema is “right‑sized” for our constraints

*   We **avoid closed modalities** (EL/PL) for core value; customers rarely have drone‑EL or DPL capacity, and PL tech is proprietary. [\[youtube.com\]](https://www.youtube.com/watch?v=qrlk_pzYAOw), [\[evmagazine.com\]](https://evmagazine.com/articles/wallbox-octopus-energy-partner-to-reduce-ev-charging-costs)
*   We **embrace RGB/thermal** because:
    *   low‑cost RGB soiling detection is validated in literature, suitable for C\&I and rooftops;
    *   thermal hotspot detection is field‑proven when flown under correct conditions. [\[docs.nrel.gov\]](https://docs.nrel.gov/docs/fy24osti/85819.pdf), [\[nlr.gov\]](https://www.nlr.gov/solar/market-research-analysis/solar-system-operations-maintenance-analysis)
*   We **lean into inverter/IV** because they exist in plants without premium O\&M systems and support realistic availability and calibration workflows. [\[docs.nrel.gov\]](https://docs.nrel.gov/docs/fy23osti/86721.pdf), [\[docs.nrel.gov\]](https://docs.nrel.gov/docs/fy25osti/91775.pdf)
*   We’re **drone‑agnostic** by keeping only URIs + capture/QC; orchestration partners exist if needed (VOTIX). [\[linkedin.com\]](https://www.linkedin.com/feed/update/urn:li:activity:7343633866668081152/)
*   We keep a **clear path to v3** (O\&M digital twin) by storing geospatial boundaries and artifact lineage; drone‑based twins are feasible with good mission planning. [\[iea.org\]](https://www.iea.org/reports/renewables-2023)

***

## 9) Next Steps :

    1.  **ER diagram (Mermaid)** plus
    2.  **seed migration files** (SQL) and
    3.  the **UX wireframes** that bind ingest → detection → impact → work orders, followed by
    4.  a **5‑site pilot plan** (AU + IN) with success metrics.

