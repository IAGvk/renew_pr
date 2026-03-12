CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS citext;

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
