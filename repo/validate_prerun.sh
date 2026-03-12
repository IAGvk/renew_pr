#!/usr/bin/env bash
# Pre-run validator v1.2 (Python 3.12+ compatible; no distutils)
# Run: bash ./validate_prerun.sh  (DO NOT 'source' it)

set -u

REPO_DIR="amplyfy-om-intel"
MIN_FREE_GB=1
REQUIRED_CMDS=(bash git python3 psql curl)
OPTIONAL_CMDS=(jq)

# Use sys.version_info to avoid distutils
python_ver_ok () {
  python3 - "$@" <<'PY'
import sys
major, minor = sys.version_info[:2]
# require >= 3.9
sys.exit(0 if (major > 3 or (major==3 and minor>=9)) else 1)
PY
}

# URLs for light network probes
NASA_POWER_URL="https://power.larc.nasa.gov/api/temporal/hourly/point?latitude=0&longitude=0&parameters=T2M&community=RE&format=JSON&start=20200101&end=20200102"
PVGIS_URL="https://re.jrc.ec.europa.eu/api/hourly?lat=0&lon=0&startyear=2020&endyear=2020&components=1&format=json"
OAM_PING="https://api.openaerialmap.org/meta?limit=1"
NSRDB_BASE="https://developer.nrel.gov/api/nsrdb/v2/solar/nsrdb-GOES-aggregated-v4-0-0-download.csv"

DATABASE_URL_DEFAULT=${DATABASE_URL:-}
NREL_API_KEY_DEFAULT=${NREL_API_KEY:-}
NREL_API_EMAIL_DEFAULT=${NREL_API_EMAIL:-}

ERRS=0; WARN=0
red(){ printf "\033[31m%s\033[0m\n" "$*"; }
grn(){ printf "\033[32m%s\033[0m\n" "$*"; }
ylw(){ printf "\033[33m%s\033[0m\n" "$*"; }
pass(){ grn "✔ $*"; }
fail(){ red "✖ $*"; ERRS=$((ERRS+1)); }
warn(){ ylw "▲ $*"; WARN=$((WARN+1)); }

ask () { # $1 varname, $2 prompt, $3 default (optional)
  local v="$1" p="$2" d="${3:-}" ans=""
  if [ -n "${!v-}" ]; then export "$v=${!v}"; return 0; fi
  if [ -n "$d" ]; then read -r -p "$p [$d]: " ans || true; [ -z "$ans" ] && ans="$d"
  else read -r -p "$p: " ans || true
  fi
  export "$v=$ans"
}

echo "== Amplyfy O&M Intelligence – pre-run validator =="

# repo dir
[ -e "$REPO_DIR" ] && fail "Directory '$REPO_DIR' already exists here." || pass "No existing '$REPO_DIR' directory — safe to create."

# commands
missing=(); for c in "${REQUIRED_CMDS[@]}"; do command -v "$c" >/dev/null 2>&1 || missing+=("$c"); done
[ ${#missing[@]} -gt 0 ] && fail "Missing required commands: ${missing[*]}" || pass "Required commands found: ${REQUIRED_CMDS[*]}"
opt_missing=(); for c in "${OPTIONAL_CMDS[@]}"; do command -v "$c" >/dev/null 2>&1 || opt_missing+=("$c"); done
[ ${#opt_missing[@]} -gt 0 ] && warn "Optional tools not found: ${opt_missing[*]}" || pass "Optional tools present: ${OPTIONAL_CMDS[*]}"

# python version (>=3.9)
pv=$(python3 -c 'import sys; print(".".join(map(str,sys.version_info[:3])))' 2>/dev/null || echo "0.0.0")
if python_ver_ok; then pass "Python version $pv ≥ 3.9.0"; else fail "Python version $pv < 3.9.0 (upgrade or use a venv ≥3.9)"; fi

# disk
avail=$(df -Pk . | awk 'NR==2 {printf "%.0f", $4/1024/1024}')
[ -n "$avail" ] && { [ "$avail" -ge "$MIN_FREE_GB" ] && pass "Free disk space: ${avail} GB (≥ ${MIN_FREE_GB} GB)" || fail "Only ${avail} GB free (< ${MIN_FREE_GB} GB)"; } || warn "Could not determine free disk space."

# network
curl -fsSL --max-time 20 "$NASA_POWER_URL" >/dev/null 2>&1 && pass "Network OK: NASA POWER reachable" || warn "NASA POWER not reachable"
curl -fsSL --max-time 20 "$PVGIS_URL" >/dev/null 2>&1 && pass "Network OK: PVGIS reachable" || warn "PVGIS not reachable."
curl -fsSL --max-time 20 "$OAM_PING" >/dev/null 2>&1 && pass "Network OK: OpenAerialMap reachable" || warn "OpenAerialMap not reachable."

# database + postgis
ask DATABASE_URL "Enter DATABASE_URL for Postgres (with PostGIS enabled)" "$DATABASE_URL_DEFAULT"
if ! psql "$DATABASE_URL" -c "SELECT version();" >/dev/null 2>&1; then
  fail "Cannot connect to database via DATABASE_URL (psql failed)."
else
  pass "Database connection OK."
  if psql "$DATABASE_URL" -c "SELECT postgis_full_version();" >/dev/null 2>&1; then
    pass "PostGIS present."
  else
    # try to enable (if superuser)
    if psql "$DATABASE_URL" -c "CREATE EXTENSION IF NOT EXISTS postgis;" >/dev/null 2>&1 \
       && psql "$DATABASE_URL" -c "SELECT postgis_full_version();" >/dev/null 2>&1; then
      pass "PostGIS enabled."
    else
      fail "PostGIS not installed or insufficient privileges to CREATE EXTENSION."
    fi
  fi
fi

# NSRDB (optional)
ask NREL_API_KEY  "Enter NREL API key (optional)" "${NREL_API_KEY_DEFAULT}"
ask NREL_API_EMAIL "Enter email for NREL API (optional)" "${NREL_API_EMAIL_DEFAULT}"
if [ -n "${NREL_API_KEY}" ] && [ -n "${NREL_API_EMAIL}" ]; then
  test_url="${NSRDB_BASE}?names=2020&interval=60&api_key=${NREL_API_KEY}&email=${NREL_API_EMAIL}&wkt=POINT(-105%2040)"
  if curl -fsSL --max-time 25 "$test_url" | head -n 1 | grep -qiE 'timestamp|year|date'; then
    pass "NSRDB key/email appear valid."
  else
    warn "NSRDB key test failed (optional)."
  fi
else
  warn "NSRDB key/email not provided — optional."
fi

echo
if [ $ERRS -eq 0 ]; then
  grn "==========================================="
  grn "Pre-run validation: ALL CRITICAL CHECKS PASS"
  grn "Run next:  bash bootstrap_repo.sh"
  grn "==========================================="
  [ $WARN -gt 0 ] && ylw "Warnings: $WARN (non-blocking)"
  exit 0
else
  red "==========================================="
  red "Pre-run validation FAILED ($ERRS critical error[s])"
  red "Fix the issues above, then re-run this validator."
  red "==========================================="
  exit 1
fi
``