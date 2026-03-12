import sys, os, datetime as dt
from dotenv import load_dotenv
from etl.utils.db import get_seed_ids, register_artifact
load_dotenv()

def main(path, kind):
    site_id, _ = get_seed_ids()
    if not os.path.exists(path):
        print(f"File not found: {path}"); return
    # Store local path as storage_uri for dev; prod would be S3/GCS URI
    aid = register_artifact(site_id, kind, os.path.abspath(path), epsg=3857,
                            capture_started_at=dt.datetime.utcnow(),
                            capture_ended_at=dt.datetime.utcnow())
    print(f"Registered artifact {aid} kind={kind} uri={path}")

if __name__=="__main__":
    if len(sys.argv)<3:
        print("Usage: load_artifact.py <file_path> <kind> (rgb_ortho|thermal_ortho|...)")
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])