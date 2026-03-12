
1.  **Pilot Data Intake Checklist** (for prospects/customers)
2.  **Partner Brief for Drone Vendors** (to standardize capture quality & deliverables)

They incorporate industry best practices for solar thermography and drone photogrammetry, and reflect what we’ll need to power v1/v2 of the product. Citations are provided inline.

***

## 1) Pilot Data Intake Checklist (Customer‑facing)

> **Purpose:** Ensure we receive sufficient, clean data to run the v1 (MVP) and v2 (Pro) analytics: **detect → quantify ΔMWh/$ → prioritize work orders** (v1) and **correlate with inverter/IV data & schedule crews** (v2).  
> **Scope:** 1–5 MW and rooftop/C\&I sites; data from assets commissioned up to **5–7 years ago** is acceptable.

### A. Site & Contact Metadata (required)

*   **Site name & address**; lat/long (if handy).
*   **DC capacity (MWdc)** and **commissioning year**.
*   **Owner/O\&M contact** (name, email, phone).
*   **Access notes:** roof access, safety induction, any airspace constraints.

*(We use these to size the ΔMWh/$ model and route tasks to crews.)*

***

### B. Imagery Inputs (required for v1; drone‑agnostic)

**B1. RGB Orthomosaic** (GeoTIFF preferred)

*   Resolution target: **≤2–3 cm GSD** for rooftop/C\&I.
*   Overlap: **≥75% frontlap / ≥70% sidelap** for photogrammetry‑grade outputs; flight pattern suited to array geometry.
*   Export: orthomosaic GeoTIFF + flight report (metadata).
*   Why: RGB enables **soiling** and **vegetation** detection at low cost. Academic work shows robust UAV‑RGB soiling detection using attention‑based YOLO variants (SDS‑YOLO). [\[docs.nrel.gov\]](https://docs.nrel.gov/docs/fy24osti/85819.pdf)

**B2. Thermal Orthomosaic** (radiometric)

*   **Radiometric** thermal imagery required (R-JPEG/TIFF; final orthomosaic GeoTIFF).
*   Capture under **suitable irradiance & operating conditions** (modules under load, stable sun), following thermography best practices to avoid false positives. Provide camera model, emissivity setting, and weather notes. Industry guidance stresses irradiance / operating status / emissivity and other environment factors for accurate thermal inspections. [\[nlr.gov\]](https://www.nlr.gov/solar/market-research-analysis/solar-system-operations-maintenance-analysis)

> **Tip:** Our team can share a one‑page flight checklist to minimize re‑flights. DJI enterprise workflows confirm that high‑quality drone capture enables robust mapping / twin generation when overlap and exposure are controlled. [\[iea.org\]](https://www.iea.org/reports/renewables-2023)

***

### C. Performance & Telemetry (v1 optional; v2 recommended)

**C1. Inverter energy export (CSV)**

*   Daily (or 15‑min/hourly) energy for **last 90 days** (more is welcome).
*   Portal exports from common OEMs are fine (SMA/Huawei/Sungrow/etc.).
*   Why: Used to **calibrate ΔMWh predictions vs observed energy** and to compute availability trendlines; large fleet studies show such time‑series inverter data is commonly available. [\[docs.nrel.gov\]](https://docs.nrel.gov/docs/fy23osti/86721.pdf)

**C2. IV curves (if available)**

*   **Smart‑IV** scan results (e.g., Huawei FusionSolar) or field tracer outputs; CSVs or PDFs accepted. Huawei’s Smart IV has been validated at multi‑GW scale and supports online diagnostics. [\[docs.nrel.gov\]](https://docs.nrel.gov/docs/fy25osti/91775.pdf)
*   Open‑source/portable tracers are also acceptable for ad‑hoc checks. [\[atb.nrel.gov\]](https://atb.nrel.gov/electricity/2024/Land-Based_Wind)

***

### D. Legacy/Reference Files (nice‑to‑have)

*   As‑built single‑line diagram (SLD) / string map (PDF/image).
*   Historic O\&M reports or past drone surveys (if any).

***

### E. Data Transfer

*   **Preferred:** secure cloud link (S3, GDrive, OneDrive, Dropbox).
*   Provide **one folder per site**; inside: `RGB/`, `Thermal/`, `Inverter/`, `IV/`, `Reference/`.

***

### F. Acceptance Checklist (quick)

*   [ ] RGB orthomosaic (GeoTIFF) with ≥ 75/70 overlap. [\[iea.org\]](https://www.iea.org/reports/renewables-2023)
*   [ ] Thermal **radiometric** orthomosaic (GeoTIFF + R‑JPEGs if available), with notes on emissivity/irradiance. [\[nlr.gov\]](https://www.nlr.gov/solar/market-research-analysis/solar-system-operations-maintenance-analysis)
*   [ ] Site DC size & commissioning year.
*   [ ] 90‑day inverter energy CSV (v2). [\[docs.nrel.gov\]](https://docs.nrel.gov/docs/fy23osti/86721.pdf)
*   [ ] IV curves (optional) from Smart‑IV or tracer. [\[docs.nrel.gov\]](https://docs.nrel.gov/docs/fy25osti/91775.pdf), [\[atb.nrel.gov\]](https://atb.nrel.gov/electricity/2024/Land-Based_Wind)

***

## 2) Partner Brief for Drone Vendors (AU/IN C\&I & Rooftop)

> **Purpose:** Ensure image capture meets analytics requirements for **soiling, vegetation, hotspot detection**, geolocation fidelity, and repeatability.  
> **Hardware:** DJI/Autel/Parrot acceptable; radiometric thermal payload required for thermal. Platform choice is **drone‑agnostic**; orchestration via neutral platforms such as **VOTIX** is possible where remote ops / multi‑fleet coordination is needed. [\[linkedin.com\]](https://www.linkedin.com/feed/update/urn:li:activity:7343633866668081152/)

### A. Mission Planning & Flight Parameters

**A1. RGB mapping (soiling/vegetation)**

*   **GSD:** target ≤2–3 cm for rooftops/C\&I; ≤5 cm for ground‑mount.
*   **Overlap:** ≥75% frontlap / ≥70% sidelap; ensure constant altitude (AGL).
*   **Lighting:** avoid harsh shadows if possible; keep consistent exposure.
*   **Deliverables:** orthomosaic (GeoTIFF), flight report, KML/World files.
*   Rationale: Ensures photogrammetry‑grade maps for detection and 3D localization; consistent with enterprise photogrammetry practice. [\[iea.org\]](https://www.iea.org/reports/renewables-2023)

**A2. Thermal mapping (hotspots)**

*   **Radiometric thermal camera** required (export R‑JPEG/TIFF).
*   **Irradiance & operating conditions:** modules must be **under load** with adequate irradiance; note time, ambient temp, wind; set emissivity appropriately; avoid rain/rapidly changing cloud. Thermal inspection guidance stresses these constraints for reliable anomaly detection. [\[nlr.gov\]](https://www.nlr.gov/solar/market-research-analysis/solar-system-operations-maintenance-analysis)
*   **Flight speed & altitude:** maintain consistent speed to minimize blur; typical altitudes 20–60 m AGL depending on array geometry and payload FOV; confirm ground sampling of thermal pixels.
*   **Deliverables:** radiometric orthomosaic (GeoTIFF), raw radiometric frames if available, metadata.

**A3. Airspace & safety**

*   Confirm local permissions, NOTAMs, roof access rules, tether lines where required; standard CASA/DCGA/DGCA compliance (AU/IN).

***

### B. Image Quality & QC

*   **Coverage:** 100% of PV fields/rooftops; include inverter pads if possible.
*   **No motion blur; no blown highlights; stable exposure across rows.**
*   **Thermal QC:** verify operating conditions (sun & load) and note emissivity; include a few reference close‑ups of known good & suspect strings for confidence checks. Industry guidance lists irradiance, emissivity, and operating status as key factors for reliable thermography. [\[nlr.gov\]](https://www.nlr.gov/solar/market-research-analysis/solar-system-operations-maintenance-analysis)

***

### C. File Packaging & Naming

    /<SiteName>_<YYYYMMDD>/
      /RGB/
        orthomosaic_rgb.tif
        flight_report.pdf
      /Thermal/
        orthomosaic_thermal_radiometric.tif
        raw_rjpeg_frames/ (optional)
        thermal_metadata.txt
      /KML_WorldFiles/
      /Notes/
        weather_notes.txt
        safety_log.pdf

***

### D. Turnaround & SLAs

*   **Standard:** 72 hours after flight completion (upload link provided).
*   **Rush:** 24 hours (surcharge).
*   **Re‑flight policy:** We’ll flag QC issues within 48 hours; if overlap or thermal conditions are not met, a short corrective sortie may be requested.

***

### E. Optional Enhancements (for v2)

*   **Time‑synced inverter data snapshot** on inspection day (CSV export). NREL fleet analyses indicate time‑series inverter data is widely used to assess availability and correlate anomalies. [\[docs.nrel.gov\]](https://docs.nrel.gov/docs/fy23osti/86721.pdf)
*   **Smart‑IV scans** if the client has Huawei FusionSolar (export results). Large‑scale Smart‑IV deployments exist and strengthen diagnostics. [\[docs.nrel.gov\]](https://docs.nrel.gov/docs/fy25osti/91775.pdf)

***

### F. Why this standard matters (customer value story you can tell)

*   Proper RGB/thermal capture **reduces revisit risk** and enables **actionable repairs** with **quantified ΔMWh/$**.
*   For public sector examples, drone thermography has shown **order‑of‑magnitude inspection time reductions** when executed with prescribed overlap/conditions and modern analytics. [\[woodmac.com\]](https://www.woodmac.com/reports/power-markets-oandm-economics-and-cost-data-for-onshore-wind-power-markets-2023-150161452/)

***

## What’s Next

1.  **UX wireframes** (ingest → detect → impact → prioritize → work order),
2.  **Core data schema** (sites, images, detections, ΔMWh, tickets, telemetry), and
3.  A **5‑site pilot plan** (AU + IN), including success metrics and cadence.
