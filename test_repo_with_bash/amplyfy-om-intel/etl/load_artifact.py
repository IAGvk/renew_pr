import sys
import os
from datetime import datetime, timezone
from dotenv import load_dotenv
from etl.utils.db import get_seed_ids, register_artifact

load_dotenv()


def main(path, kind):
    site_id, _ = get_seed_ids()
    if not os.path.exists(path):
        print(f"File not found: {path}")
        return
    aid = register_artifact(
        site_id,
        kind,
        os.path.abspath(path),
        epsg=3857,
        capture_started_at=datetime.now(timezone.utc),
        capture_ended_at=datetime.now(timezone.utc),
    )
    print(f"Registered artifact {aid} kind={kind} uri={path}")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: load_artifact.py <file_path> <kind> (rgb_ortho|thermal_ortho|...)")
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])
