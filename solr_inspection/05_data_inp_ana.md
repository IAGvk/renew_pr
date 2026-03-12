A **deployment‑ready data plan** for **v1 (MVP)** and **v2 (Pro)** of the combined “O\&M Prioritization + C\&I/Rooftop Intelligence” product. 
It lists **primary & secondary data inputs**, **external/commercial dependencies**, and the **maximum feasible geographic coverage** we can serve using **open‑source** and/or **naturally available client data** (even for assets commissioned **5–7 years ago**).

> Legend:  
> **Primary** = required for core value; **Secondary** = boosts accuracy/automation; **Optional** = nice‑to‑have.

***

## 1) **v1 (MVP) — Data Inputs**

### A. **Image / Mapping Inputs (Detection & Geolocation)**

*   **RGB orthomosaics** (drone‑captured, standard exports): used for **soiling** and **vegetation** detection and to geolocate anomalies. Low‑cost RGB‑only soiling detection has been demonstrated by RMIT (SDS‑YOLO attention model) and is suitable for aerial imagery. [\[docs.nrel.gov\]](https://docs.nrel.gov/docs/fy24osti/85819.pdf)
*   **Thermal (radiometric) orthomosaics**: used for **hotspot** identification with best‑practice caveats (irradiance/emissivity); drone thermography is an established inspection method. [\[nlr.gov\]](https://www.nlr.gov/solar/market-research-analysis/solar-system-operations-maintenance-analysis)

**Acquisition reality (last 5–7 years):**  
Most C\&I/rooftop owners can procure a **once‑off** or **recurring** RGB/thermal flight from local drone providers; you remain **drone‑agnostic** (DJI/Autel/Parrot), which is feasible via neutral ops platforms like **VOTIX**. [\[linkedin.com\]](https://www.linkedin.com/feed/update/urn:li:activity:7343633866668081152/)

***

### B. **Site & Asset Metadata (Minimal)**

*   **Site DC size / commissioning year / rough layout** (strings/rows if known): used to scale ΔMWh/$ impact models when detailed electrical hierarchy is unavailable. Owners normally have basic site facts in handover packs—even for plants 5–7 years old. *No citation needed (operational practice).*

***

### C. **Performance Signals (Lightweight)**

*   **Daily/weekly energy CSVs** from inverter portals (SMA Sunny Portal, Huawei/Sungrow portals, etc.): used for sanity checks and **calibration** of predicted ΔMWh vs observed energy (optional in v1; becomes primary in v2). NREL’s PV Fleet & inverter‑availability studies confirm such **time‑series inverter data** is commonly available across large fleets. [\[docs.nrel.gov\]](https://docs.nrel.gov/docs/fy23osti/86721.pdf)

***

### D. **Environmental / Context Layers (Open Data)**

*   **Irradiance & weather reanalysis** (open datasets); used in v1 to set inspection QC flags and normalize hotspot confidence ranges; FLIR’s guidance stresses irradiance/operating status for accurate thermal inspections. [\[nlr.gov\]](https://www.nlr.gov/solar/market-research-analysis/solar-system-operations-maintenance-analysis)

***

### **v1 — External/Commercial Dependencies**

*   **Drone images**: Sourced via **local service partners** or client’s own pilot. You remain **agnostic**; integration with drone‑ops platforms (e.g., VOTIX) is optional but proves cross‑fleet feasibility. [\[linkedin.com\]](https://www.linkedin.com/feed/update/urn:li:activity:7343633866668081152/)
*   **No paid certificate markets or proprietary EL/PL** needed in v1 (intentionally avoided). *(EL/PL are constrained; DPL is proprietary to Lab360 Solar.)* [\[youtube.com\]](https://www.youtube.com/watch?v=qrlk_pzYAOw), [\[evmagazine.com\]](https://evmagazine.com/articles/wallbox-octopus-energy-partner-to-reduce-ev-charging-costs)

***

## 2) **v2 (Pro) — Incremental Data Inputs**

### A. **Richer Performance / Telemetry**

*   **Inverter logs / availability / alarms** (portal export, CSV/API; or Modbus gateway): used to improve **defect→impact linkage**, detect underperforming strings, and separate **SCADA comms loss vs true outages**. NREL PV Fleet analyses document inverter availability derived from time‑series fleet data; Sandia/VDE analyses differentiate central vs string availability, useful for modeling. [\[docs.nrel.gov\]](https://docs.nrel.gov/docs/fy23osti/86721.pdf), [\[energy.gov\]](https://www.energy.gov/sites/default/files/2024-05/operations-and-maintenance-roadmap-for-us-offshore-wind.5.17.24.pdf)
*   **IV curves**:
    *   **Online Smart‑IV** (e.g., Huawei Smart IV) widely deployed at utility scale (7 GW+), creating module/string‑level diagnostics. [\[docs.nrel.gov\]](https://docs.nrel.gov/docs/fy25osti/91775.pdf)
    *   **Portable/open IV tracers** exist (Raspberry‑Pi + programmable load, open source), enabling periodic scans even for mid‑scale sites. [\[atb.nrel.gov\]](https://atb.nrel.gov/electricity/2024/Land-Based_Wind)

### B. **Scheduling / Routing Context**

*   **Simple crew calendars & depot locations** (user input) for route optimization; in v2 the agent proposes **multi‑objective** schedules prioritizing ΔMWh/$ recapture.

### C. **Deeper Photogrammetry QA (Optional)**

*   While you still accept exports from common photogrammetry tools, you add **in‑app QC** on overlap/GSD to stabilize georegistration for repeated surveys; DJI enterprise guidance confirms **twin‑creation feasibility from drones alone**. [\[iea.org\]](https://www.iea.org/reports/renewables-2023)

***

### **v2 — External/Commercial Dependencies**

*   **OEM portals** (Huawei/Sungrow/SMA, etc.) for telemetry exports—start with **file upload** to avoid OEM API fragmentation; graduate to direct APIs later. Empirical fleet analyses (NREL/Sandia) confirm such data is commonly accessible. [\[docs.nrel.gov\]](https://docs.nrel.gov/docs/fy23osti/86721.pdf), [\[energy.gov\]](https://www.energy.gov/sites/default/files/2024-05/operations-and-maintenance-roadmap-for-us-offshore-wind.5.17.24.pdf)
*   **Optional scheduling partner** for drone dispatch (if you broker flights); still **vendor‑agnostic**. [\[linkedin.com\]](https://www.linkedin.com/feed/update/urn:li:activity:7343633866668081152/)

***

## 3) **Max Feasible Geographic Coverage (with Open / Naturally Available Data)**

### A. **What “naturally available” means here**

*   **Client’s own data** typically retained 5–7 years: site size, basic layout, inverter portal exports, O\&M reports, and the ability to commission a drone flight today (RGB/thermal). This alone is sufficient for v1 value (detection → ΔMWh/$ → prioritized work orders). [\[docs.nrel.gov\]](https://docs.nrel.gov/docs/fy24osti/85819.pdf), [\[nlr.gov\]](https://www.nlr.gov/solar/market-research-analysis/solar-system-operations-maintenance-analysis)

### B. **Coverage by Region (practical view)**

*   **India (C\&I + rooftop):**
    *   **Soiling is material** (1–7%) → strong ROI for low‑cost inspections. [\[osti.gov\]](https://www.osti.gov/biblio/2228955)
    *   Many sites (1–5 MW) use **string inverters** with accessible portals → inverter CSVs retrievable post‑hoc. [\[energy.gov\]](https://www.energy.gov/sites/default/files/2024-05/operations-and-maintenance-roadmap-for-us-offshore-wind.5.17.24.pdf)
    *   **Conclusion:** **High feasibility** for v1 + v2 using drone imagery + portal exports; no paid datasets required.
*   **Australia (C\&I + small utility):**
    *   Mature drone ecosystem and **thermal inspection practices**; irradiance/operating windows manageable. [\[nlr.gov\]](https://www.nlr.gov/solar/market-research-analysis/solar-system-operations-maintenance-analysis)
    *   **Conclusion:** **High feasibility** for v1 + v2 using client‑commissioned flights + inverter CSVs.
*   **SE Asia / LATAM / MEA (dusty climates):**
    *   Soiling and vegetation prevalent; drone vendors available; similar inverter portals.
    *   **Conclusion:** **High feasibility** for v1; v2 depends on portal access and language/regulatory nuance. *(Generalized from global inspection practices and thermal guidance.)* [\[nlr.gov\]](https://www.nlr.gov/solar/market-research-analysis/solar-system-operations-maintenance-analysis)
*   **US/EU (C\&I + utility):**
    *   Well‑established drone providers; access to inverter data common; fleet analyses and standards are abundant (NREL/Sandia). [\[docs.nrel.gov\]](https://docs.nrel.gov/docs/fy23osti/86721.pdf), [\[energy.gov\]](https://www.energy.gov/sites/default/files/2024-05/operations-and-maintenance-roadmap-for-us-offshore-wind.5.17.24.pdf)
    *   **Conclusion:** **High feasibility** for v1 + v2.

> **Bottom line:** With **RGB/thermal flights + inverter CSVs**, you can serve **most solar geographies** in **v1 + v2** without any paid third‑party datasets or proprietary sensors. Only specialized use‑cases (e.g., EL/PL diagnostics, DPL) require **closed vendors** (QE Labs/PVEL or Lab360), which we intentionally avoid for core value. [\[youtube.com\]](https://www.youtube.com/watch?v=qrlk_pzYAOw), [\[evmagazine.com\]](https://evmagazine.com/articles/wallbox-octopus-energy-partner-to-reduce-ev-charging-costs)

***

## 4) **Data Source Matrix (Quick Reference)**

| Layer                                    | v1 Role                     | v2 Role                            | Source Type                | Comments                                                                                                                                                                                                                       |
| ---------------------------------------- | --------------------------- | ---------------------------------- | -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| RGB orthomosaic                          | **Primary** (soiling/veg)   | Primary (time‑series change)       | Client/Drone partner       | Proven AI for RGB soiling (SDS‑YOLO). [\[docs.nrel.gov\]](https://docs.nrel.gov/docs/fy24osti/85819.pdf)                                                                                                                       |
| Thermal orthomosaic                      | **Primary** (hotspots)      | Primary                            | Client/Drone partner       | Follow FLIR best practices (irradiance, emissivity). [\[nlr.gov\]](https://www.nlr.gov/solar/market-research-analysis/solar-system-operations-maintenance-analysis)                                                            |
| Site basics (DC size/commissioning year) | **Primary**                 | Primary                            | Client handover docs       | Used to scale ΔMWh/$ models.                                                                                                                                                                                                   |
| Inverter energy CSV                      | **Secondary** (calibration) | **Primary** (analytics)            | Client portal exports      | NREL shows fleet‑level time‑series availability exists. [\[docs.nrel.gov\]](https://docs.nrel.gov/docs/fy23osti/86721.pdf)                                                                                                     |
| IV curves                                | Optional                    | **Secondary → Primary** (Smart‑IV) | OEM Smart‑IV, field tracer | Huawei Smart‑IV (7 GW+); Open IV tracer (Raspberry‑Pi). [\[docs.nrel.gov\]](https://docs.nrel.gov/docs/fy25osti/91775.pdf), [\[atb.nrel.gov\]](https://atb.nrel.gov/electricity/2024/Land-Based_Wind)                          |
| Weather/irradiance                       | **Secondary** (QC)          | Secondary                          | Open datasets              | Thermal QC per FLIR guidance. [\[nlr.gov\]](https://www.nlr.gov/solar/market-research-analysis/solar-system-operations-maintenance-analysis)                                                                                   |
| Drone ops orchestration                  | Optional                    | Optional                           | VOTIX/others               | Validates drone‑agnostic ops. [\[linkedin.com\]](https://www.linkedin.com/feed/update/urn:li:activity:7343633866668081152/)                                                                                                    |
| EL/PL datasets                           | **Out of scope**            | Out of scope                       | Proprietary vendors        | QE Labs/PVEL (EL), Lab360 (DPL) – not needed. [\[youtube.com\]](https://www.youtube.com/watch?v=qrlk_pzYAOw), [\[evmagazine.com\]](https://evmagazine.com/articles/wallbox-octopus-energy-partner-to-reduce-ev-charging-costs) |

***

## 5) **Dependencies & Risk Notes**

*   **Drone data dependency**: You rely on **local drone providers** or client pilots—ubiquitous in AU/IN/US/EU; set a **flight/imagery checklist** to stabilize model quality (overlap/GSD/irradiance). [\[nlr.gov\]](https://www.nlr.gov/solar/market-research-analysis/solar-system-operations-maintenance-analysis)
*   **Telemetry dependency**: For v2 accuracy and automation, secure **export credentials** to inverter portals; when not available, use **file‑drop** CSVs. Empirical fleet studies indicate availability is common for modern plants. [\[docs.nrel.gov\]](https://docs.nrel.gov/docs/fy23osti/86721.pdf), [\[energy.gov\]](https://www.energy.gov/sites/default/files/2024-05/operations-and-maintenance-roadmap-for-us-offshore-wind.5.17.24.pdf)
*   **No paid market data** required for v1/v2: You avoid certificate markets and closed imaging (EL/PL). Where clients request such deep diagnostics, **refer/partner** (not core to your value). [\[youtube.com\]](https://www.youtube.com/watch?v=qrlk_pzYAOw), [\[evmagazine.com\]](https://evmagazine.com/articles/wallbox-octopus-energy-partner-to-reduce-ev-charging-costs)

***

## 6) **What this enables immediately**

*   Launch **v1** anywhere a client can provide **(a)** RGB/thermal flights and **(b)** basic site info.
*   Upgrade to **v2** wherever **inverter CSVs** are accessible; results improve further with **Smart‑IV** or periodic IV tracing. [\[docs.nrel.gov\]](https://docs.nrel.gov/docs/fy25osti/91775.pdf), [\[atb.nrel.gov\]](https://atb.nrel.gov/electricity/2024/Land-Based_Wind)

## 7) **Next Steps** : 

* Pilot Data Intake checklist. 
* Partner Brief for drone partners/vendors.