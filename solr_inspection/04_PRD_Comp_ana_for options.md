
0.  **Mergeability of Directions 1 & 2**
1.  **PRD – v1** (easily‑buildable, combined features of Directions 1 & 2)
2.  **PRD – v2** (the remaining features of Directions 1 & 2)
3.  **PRD – v3** (features of Direction 3: O\&M Digital‑Twin‑Light)
4.  **Competitive Landscape** (with links and citations)

***

**Mergeability of Directions 1 & 2**:
## Can Directions **1 (Agentic O\&M Prioritization Copilot)** and **2 (Low‑Cost C\&I/Rooftop O\&M Intelligence)** be merged?

**Yes — and they should be.** Direction 1 is the **decision intelligence layer** (prioritization, ROI, work orders). Direction 2 is the **lowest‑cost data ingestion and market packaging** for C\&I/rooftop (1–5 MW) where inspection and soiling/vegetation losses are material (1–7% in India; can exceed 25% in harsh regions), and drone inspections cut time/cost substantially (e.g., public cases report \~95% time savings). Combining them yields a single product that:

*   **Ingests low‑cost inspections** (RGB/thermal) from any drone or partner, **and**
*   **Outputs action & ROI**, not just detections — a gap incumbents don’t solve well today. [\[osti.gov\]](https://www.osti.gov/biblio/2228955), [\[woodmac.com\]](https://www.woodmac.com/reports/power-markets-oandm-economics-and-cost-data-for-onshore-wind-power-markets-2023-150161452/)

**No fundamental obstruction** exists:

*   **Data availability**: inverter logs/IV curves exist even without high‑end O\&M platforms; NREL and vendors document access patterns and Smart IV features. [\[docs.nrel.gov\]](https://docs.nrel.gov/docs/fy23osti/86721.pdf), [\[docs.nrel.gov\]](https://docs.nrel.gov/docs/fy25osti/91775.pdf)
*   **Drone‑agnostic ops**: mature platforms (VOTIX, OmniDock) and open protocols (MAVLink) show feasibility. [\[linkedin.com\]](https://www.linkedin.com/feed/update/urn:li:activity:7343633866668081152/), [\[energytag.org\]](https://energytag.org/wp-content/uploads/2025/09/PUBLIC-Flexidao-GC-Scheme-Protocol_Configuration-3.pdf), [\[datacenter...namics.com\]](https://www.datacenterdynamics.com/en/news/google-to-expand-247-clean-energy-matching-with-flexidao/)
*   **Differentiation**: Raptor Maps and others focus on detection + portfolio recordkeeping, not an agent that **prioritizes fixes by MWh/$ impact for SMB/C\&I**. (Raptor does asset management at scale but not the depth of prescriptive ROI scheduling we propose.) [\[octopus.energy\]](https://octopus.energy/blog/intelligent-octopus-go-charge-limit/)

***

# 1) PRD – v1 (MVP)

*(Combined, easily buildable features of Directions 1 & 2)*

## Product Name (working): **Amplyfy O\&M Copilot – C\&I Edition**

### 1. Problem Statement

Owners and O\&M firms of 1–5 MW and rooftop/C\&I solar assets lack low‑cost tools to:

*   detect **soiling/vegetation/hotspots**;
*   **quantify** the energy/$ impact; and
*   **prioritize** the exact set of actions to recapture yield with **ROI estimates**.  
    Soiling losses are material (1–7% in India; >25% in dusty environments), and low‑cost drone surveys can cut inspection time by \~95%, yet the market has mostly detection‑only offerings without prescriptive, prioritized work orders. [\[osti.gov\]](https://www.osti.gov/biblio/2228955), [\[woodmac.com\]](https://www.woodmac.com/reports/power-markets-oandm-economics-and-cost-data-for-onshore-wind-power-markets-2023-150161452/)

### 2. Target Users & ICP

*   **Primary**: C\&I asset owners (1–5 MW, campuses, factories, warehouses), small utility sites (≤20 MW), local O\&M providers.
*   **Secondary**: EPCs offering post‑COD O\&M.

### 3. Goals & KPIs

*   **Reduce avoidable losses**: estimated annual MWh recaptured per site.
*   **Actionability**: % of detected issues converted into scheduled work orders.
*   **Time‑to‑insight**: <48 hrs from image upload to prioritized plan.
*   **Unit economics**: inspection + analysis cost ≤US$0.35–0.60/kW per cycle (market dependent).

### 4. Scope – v1 Features

**4.1 Data ingestion (low‑friction)**

*   Upload RGB and thermal orthomosaics (common export formats).
*   Optional: inverter daily energy + basic telemetry CSV.
*   Drone‑agnostic ingestion (DJI/Autel/Parrot partners); no live flight control in v1. (Drone‑agnostic feasibility is well established.) [\[linkedin.com\]](https://www.linkedin.com/feed/update/urn:li:activity:7343633866668081152/)

**4.2 AI detections (pragmatic set)**

*   **Soiling zones** (RGB) leveraging attention‑based YOLO‑style models. [\[docs.nrel.gov\]](https://docs.nrel.gov/docs/fy24osti/85819.pdf)
*   **Vegetation encroachment** (RGB).
*   **Hotspot clusters** (thermal), with best‑practice caveats (irradiance, emissivity). [\[nlr.gov\]](https://www.nlr.gov/solar/market-research-analysis/solar-system-operations-maintenance-analysis)

**4.3 Impact & Prioritization**

*   **Baseline performance model** from site size, irradiance lookup (public data) and simple performance approximations.
*   Convert each anomaly into **ΔMWh/year** and **$ impact** estimates.
*   **Prioritized action list** (cleaning, trim vegetation, address hotspot strings) with **ROI & payback**.

**4.4 Work Orders & Reports**

*   Generate **actionable work orders** (location, panel IDs/row), export to PDF/CSV.
*   Road‑map integrations: Jira, ServiceNow (webhooks).

**4.5 Pricing (v1 hypothesis)**

*   **Per‑site subscription**: US$49–199/site/month depending on DC size, billed annually.
*   **Per‑inspection analysis**: US$0.10–0.25/kW (one‑off) for non‑subscribers.

### 5. Out of Scope (v1)

*   Full EL/PL; advanced IV curve scraping from hardware; dynamic crew routing; photogrammetry generation (assume the user/partner provides maps).

### 6. Risks & Mitigations

*   **Data quality variability** → Provide flight/imagery **checklist** (GSD, overlap, irradiance windows) and perform QC flags. [\[nlr.gov\]](https://www.nlr.gov/solar/market-research-analysis/solar-system-operations-maintenance-analysis)
*   **Ground truth** → v1 includes an adjustable calibration factor per site to align predicted ΔMWh with observed inverter energy.

### 7. Technical Architecture (high level)

*   **Ingestion** (S3‑like blob + metadata) → **CV pipelines** (RGB soiling/veg; thermal hotspots) → **Impact modeler** (ΔMWh/$) → **Prioritization engine** → **Work‑order generator** → **API/UI**.
*   Uses standard Python CV stack; no GPU at edge.

### 8. Validation Plan

*   Pilot 5–10 sites (AU/IN C\&I) via regional O\&M partners; measure **MWh recapture** and on‑site crew acceptance.

***

# 2) PRD – v2 (Remaining features of Directions 1 & 2)

## Product Name: **Amplyfy O\&M Copilot – Pro**

### 1. Problem Extension

Once v1 is adopted, users request deeper automation: **inverter/IV ingestion**, **crew routing**, **rules‑based scheduling**, and **semi‑autonomous data capture**.

### 2. Additional Scope – v2 Features

**2.1 Rich Data & Analytics**

*   **Inverter log ingestion** (via portal export/API or Modbus gateway). Availability/uptime analytics influenced by NREL fleet studies; detect mis‑tracking, underperforming strings, and startup “teething” effects. [\[docs.nrel.gov\]](https://docs.nrel.gov/docs/fy23osti/86721.pdf), [\[energy.gov\]](https://www.energy.gov/sites/default/files/2024-05/operations-and-maintenance-roadmap-for-us-offshore-wind.5.17.24.pdf)
*   **Smart IV curve import** (from Huawei Smart IV or field tracers). [\[docs.nrel.gov\]](https://docs.nrel.gov/docs/fy25osti/91775.pdf), [\[atb.nrel.gov\]](https://atb.nrel.gov/electricity/2024/Land-Based_Wind)
*   **Soiling index vs. energy**: correlate detections with measured energy to auto‑tune ROI models.

**2.2 Agentic Prioritization & Scheduling**

*   Multi‑objective optimizer: **maximize ΔMWh recapture**, **minimize travel time**, **respect crew hours**.
*   **Seasonal playbooks** (e.g., monsoon pre‑cleaning in India; summer vegetation in AU).

**2.3 “No-drone” routes for SMB**

*   Partnerships with local drone service networks; **one‑click dispatch** for a flight (we remain software‑only).
*   Drone‑agnostic RPA tie‑ins (VOTIX or local providers). [\[linkedin.com\]](https://www.linkedin.com/feed/update/urn:li:activity:7343633866668081152/)

**2.4 Basic Photogrammetry Assist**

*   We still accept exports but add **embedded tiling/preview** and **georegistration QA**.

**2.5 Integrations**

*   Work order sync: **Jira**, **ServiceNow**, **SAP PM** (webhooks or CSV bridges).
*   Data export to customer data lakes.

### 3. KPIs (incremental)

*   **% of prioritized actions completed** within SLA;
*   **MWh recapture vs. forecast**;
*   **Crew utilization** improvement.

### 4. Pricing (v2 hypothesis)

*   **Pro subscription**: US$199–499/site/month (includes scheduling & inverter analytics).
*   Volume discounts for >20 sites.

### 5. Risks & Mitigation

*   **Portal/API diversity** → Start with top 3 OEMs (Huawei/Sungrow/SMA) and “file drop” fallbacks; document mappings.
*   **Route/optimizer trust** → Always provide **explainability** (why these 20 items first).

***

# 3) PRD – v3 (Direction 3: O\&M Digital‑Twin‑Light)

## Product Name: **Amplyfy Twin – O\&M**

### 1. Problem Statement

Operators want a **visual, longitudinal map** of defects and work history. Full engineering twins require PVSyst/electrical hierarchies that are hard to obtain, but **drone‑only O\&M twins** are achievable with photogrammetry + IoT overlays. [\[iea.org\]](https://www.iea.org/reports/renewables-2023), [\[docs.nrel.gov\]](https://docs.nrel.gov/docs/fy23osti/83712.pdf)

### 2. Scope – v3 Features

**2.1 3D Site Model from Drone Imagery**

*   In‑app orchestration to external photogrammetry engines; QC for overlap, GSD, facade shots (per DJI/industry guidance). [\[iea.org\]](https://www.iea.org/reports/renewables-2023)

**2.2 Temporal Layers**

*   Time‑series overlays of soiling, vegetation, hotspots, and completed repairs.
*   Heatmaps of **recurring trouble areas**.

**2.3 Performance Overlay**

*   Optional: pull inverter energy and display basic **energy‑vs‑defect** correlation on the twin (no PVSyst).
*   Note: **Engineering‑grade** twin (module‑to‑inverter hierarchy, shading simulations) remains out of scope unless customers contribute design files (PVcase highlights those data needs). [\[granular-energy.com\]](https://www.granular-energy.com/insights/global-energytag-accreditation?category=news)

**2.4 Collaboration**

*   Annotations, pin‑drops, and **work‑order links** to Copilot‑Pro tasks.

### 3. KPIs

*   **Time‑to‑diagnosis** (visual confirmation),
*   **Repeat issue reduction** in previously hot‑spot zones,
*   **Stakeholder adoption** (O\&M, owner, lender).

### 4. Pricing

*   Add‑on: US$99–199/site/month or bundled with Pro tiers.

### 5. Risks & Mitigation

*   **Photogrammetry consistency** → Provide **mission templates**; partner with local drone firms.

***

# 4) Competitive Landscape (with links)

> **TL;DR** – We avoid the crowded “detection” space and own the **decision intelligence & SMB/C\&I** segment. We interoperate with detection providers.

## Direct & Adjacent Competitors

| Competitor             | Focus                                           | Strengths                                                              | Gaps We Exploit                                                                                          | Link                                                                                                                                                                                                                                                                                                   |
| ---------------------- | ----------------------------------------------- | ---------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Raptor Maps**        | Drone thermal/RGB analytics + asset management  | Large portfolio digitization, ML insights, workflows; $35M Series C    | Less emphasis on **ROI‑prioritized action sequencing** for SMB/C\&I; pricing tier may be high for 1–5 MW | [pv magazine USA article](https://octopus.energy/blog/intelligent-octopus-go-charge-limit/)                                                                                                                                                                                                            |
| **SkyVisor**           | AI‑driven drone inspections (wind + solar)      | In‑house drone + AI, European presence; €1.2M funding                  | Primarily detection/inspection; less focus on **agentic prioritization & SMB pricing**                   | [Tech Funding News](https://efiling.energy.ca.gov/GetDocument.aspx?tn=251918\&DocumentContentId=86918)                                                                                                                                                                                                 |
| **PVEL + QE Labs**     | **Drone‑EL** inspections for warranty/insurance | EL expertise and bankability for due diligence                         | Specialized/expensive; not scalable to SMB routine O\&M                                                  | [PV Tech](https://www.youtube.com/watch?v=qrlk_pzYAOw)                                                                                                                                                                                                                                                 |
| **Lab360 Solar**       | **Daylight PL (DPL)** via drones                | Unique IP; AU$3.96M ARENA grant; cell‑level in daylight                | Proprietary; premium; not designed for low‑cost SMB                                                      | [ARENA](https://evmagazine.com/articles/wallbox-octopus-energy-partner-to-reduce-ev-charging-costs), [pv magazine AU](https://ohme-ev.com/support/intelligent-octopus-go-6-hour-smart-charging-faqs/), [PV Tech](https://myenergi.info/intelligent-octopus-tariff-with-zappi-charging-con-t10420.html) |
| **OnSight Technology** | UGV robotics for solar inspection               | Long‑duration ground robot; high‑res thermal/RGB; strategic investment | Hardware‑heavy; less suited to low‑cost SMB                                                              | [Parsers VC profile](https://docs.gridmo.io/docs/templates/au_aemo_dmat/)                                                                                                                                                                                                                              |

## Enablers/Partners (not competitors)

| Company                   | Role                    | Why it matters                                    | Link                                                                                                                                                                                                                       |
| ------------------------- | ----------------------- | ------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **VOTIX**                 | Drone‑agnostic ops OS   | Proves drone‑agnostic orchestration feasibility   | [VOTIX](https://www.linkedin.com/feed/update/urn:li:activity:7343633866668081152/)                                                                                                                                         |
| **Counterdrone OmniDock** | Drone‑agnostic dock     | Hardware‑agnostic “drone‑in‑a‑box”                | [Counterdrone](https://energytag.org/wp-content/uploads/2025/09/PUBLIC-Flexidao-GC-Scheme-Protocol_Configuration-3.pdf)                                                                                                    |
| **DJI Enterprise**        | Photogrammetry guidance | Validates drone‑only digital twin creation        | [DJI insights](https://www.iea.org/reports/renewables-2023)                                                                                                                                                                |
| **NREL / Sandia**         | Benchmarks & datasets   | Inverter availability norms; performance datasets | [NREL inverter availability](https://docs.nrel.gov/docs/fy23osti/86721.pdf), [Sandia PVPMC poster](https://www.energy.gov/sites/default/files/2024-05/operations-and-maintenance-roadmap-for-us-offshore-wind.5.17.24.pdf) |
| **Huawei FusionSolar**    | Smart IV                | Large‑scale online IV scanning in the field       | [Huawei white paper](https://docs.nrel.gov/docs/fy25osti/91775.pdf)                                                                                                                                                        |

## Why We Win

*   **We don’t compete on capture**; we **optimize decisions** across **affordable** C\&I/rooftop markets in **AU/IN** first, where soiling and vegetation are major, documented drivers of loss. [\[osti.gov\]](https://www.osti.gov/biblio/2228955)
*   **Drone‑agnostic + data‑agnostic** = fastest GTM; we integrate with any local drone vendor & any inverter CSV. [\[linkedin.com\]](https://www.linkedin.com/feed/update/urn:li:activity:7343633866668081152/)
*   **Agentic ROI planning** (ΔMWh/$ prioritization) is a new category, unaddressed by detection‑centric incumbents.

***

## Next Steps :

*   **UX wireframes** for v1/v2 flows (ingest → detect → impact → prioritize → work order).
*   **Data schema** (site, arrays, images, detections, ΔMWh/$, tickets).
*   **Pilot plan** for AU/IN partners, including a field check‑list aligned with thermal/radiometric best practices(targets, success metrics, contracts). [\[nlr.gov\]](https://www.nlr.gov/solar/market-research-analysis/solar-system-operations-maintenance-analysis)
