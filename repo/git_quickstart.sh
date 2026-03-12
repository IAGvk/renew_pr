---

## 1) Git Quickstart & Smoke Test

```bash
# From inside the repo folder amplyfy-om-intel/
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
# edit .env to set your DATABASE_URL (Postgres + PostGIS), and optionally NSRDB key/email

# Create schema + seed pilot site
make db.migrate
make db.seed

# Pull open datasets
make fetch.all          # PVDAQ, PV‑IV‑EL, NASA POWER, PVGIS, OAM
make fetch.nsrdb        # only if NREL key/email set (optional)

# Load one time‑series & register a sample RGB ortho
make load.sample