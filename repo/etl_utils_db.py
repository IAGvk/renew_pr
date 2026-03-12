import os
import psycopg2
from psycopg2.extras import execute_values

def get_conn():
    url = os.getenv("DATABASE_URL")
    return psycopg2.connect(url)

def upsert_inverter_timeseries(rows):
    """
    rows: list of dict with keys:
      site_id, equipment_id, ts, energy_wh, power_w, dc_voltage_v, dc_current_a, temperature_c, source_meta
    """
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

def get_seed_ids():
    """Fetch Pilot site & inverter IDs seeded by 002_seed.sql"""
    with get_conn() as conn, conn.cursor() as cur:
        cur.execute("SELECT id FROM site WHERE name=%s", (os.getenv("SITE_NAME","Pilot C&I Rooftop"),))
        site_id = cur.fetchone()[0]
        cur.execute("SELECT id FROM equipment WHERE site_id=%s AND type='inverter' LIMIT 1", (site_id,))
        inv_id = cur.fetchone()[0]
        return site_id, inv_id