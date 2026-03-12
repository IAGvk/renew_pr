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
