**Flow A first, but architected so Flow B drops in without redesigning the UI or data flow.**  

Below is a clean, high‑clarity **wireframe pack (text‑based + structured)** that Product + Engineering can use immediately. After your approval, I’ll generate **visual PNG wireframes** and optionally an **interactive HTML storyboard**.

***

# 🌞 **Flow A — MVP UX (C\&I / Rooftop Intelligence)**

**Designed to seamlessly expand into Flow B (Agentic O\&M Prioritization).**

This includes screens + layout structure + navigation + data elements + future‑proof anchors.

***

# 1) **Projects & Sites List**

### Purpose

Entry point → shows all sites, their health, ingest status, and quick links to detections/ROI.

### Wireframe (text form)

     ---------------------------------------------------------
    |  ✦ Amplyfy © 2026                [User: Vikesh ▾]       |
     ---------------------------------------------------------
    |  Projects      |  Sites     |  Upload     |  Settings   |
     ---------------------------------------------------------
    | Sites (N)                                       [ + Add Site ]  |
    | --------------------------------------------------------------- |
    | • Pilot C&I Rooftop                      •   Last ingest: ✓     |
    | Location: Sydney, NSW                      ΔMWh Found: 1.2      |
    | Capacity: 3.0 MW                            Status: Healthy     |
    | --------------------------------------------------------------- |
    | • Site B ...                                                    |
    | --------------------------------------------------------------- |

### Key data elements

*   Site name, lat/lon, capacity
*   Last ingest job status
*   ΔMWh detected (if any)
*   Health badge

### Flow B‑ready future hooks

*   “Work Orders open” count
*   “Priority score” pill
*   “Next recommended dispatch” indicator

***

# 2) **Upload / Ingest Screen (RGB, Thermal, Telemetry)**

### Purpose

Centralizing ingestion: drag/drop, metadata capture, QC flags, and async job status.

### Wireframe

     --------------------------------------------------------
    | Upload Data for: Pilot C&I Rooftop                     |
     --------------------------------------------------------
    | [Drag & Drop RGB Ortho]   [Drop Thermal Ortho]         |
    | [Drop Telemetry CSV]      [Drop Flight Logs (opt)]     |
     --------------------------------------------------------
    | Pending Uploads                                            |
    |  - rgb_ortho_2024_03_01.tif        Processing...          |
    |  - thermal_ortho_2024_03_01.tif    Awaiting metadata ▸    |
     --------------------------------------------------------
    | Required Metadata (auto-suggest if EXIF exists)            |
    |  [✓] Flight date/time: __                                   |
    |  [✓] Emissivity: __                                         |
    |  [✓] Wind: __ m/s                                           |
    |  [✓] Irradiance: __ W/m²                                    |
    |  [✓] GSD @ M2: __                                           |
    |  [🔍] Compute missing using NASA POWER                     |
     --------------------------------------------------------
    | QC Flag Summary                                             |
    |  ✓ Irradiance > 600 W/m²                                   |
    |  ✓ Overlap OK                                              |
    |  ⚠ Wind borderline                                         |
    |  ✓ Radiometric calibration OK                              |
     --------------------------------------------------------

### Flow B‑ready anchors

After processing completes:

*   “Send to prioritizer”
*   “Auto‑link telemetry & IV curves”
*   “Update digital twin layer”

***

# 3) **Detections Map + Panel List**

### Purpose

Visual overview of issues: soiling, vegetation, hotspots.

### Wireframe

     --------------------------------------------------------
    |  Detections for Pilot C&I Rooftop   [Survey ▾]          |
     --------------------------------------------------------
    |  Map (left two-thirds)                                   |
    |   - RGB / Thermal toggle                                  |
    |   - Cluster view (soiling, vegetation, hotspots)          |
    |   - Detection polygons                                    |
     --------------------------------------------------------
    |  Right panel                                              |
    |   Filters: [✓ Soiling] [✓ Vegetation] [✓ Hotspots]        |
    | Severity: [Low] [Med] [High]                               |
    | ---------------------------------------------------------- |
    | List                                                       |
    | • Hotspot #32   Conf: 0.94   Module: A3-R2                 |
    | ΔMWh est: 0.12                                             |
    | • Vegetation #88 Conf: 0.89   String: S12                  |
    | ΔMWh est: 0.05                                             |
    | • Soiling patch #14                                        |
    | ---------------------------------------------------------- |

### Flow B‑ready

Each detection has:

*   Checkboxes → feed into bulk job creation
*   “Add to Work Order”
*   “AI Priority Score” (Flow B)

***

# 4) **ROI / Impact Screen (ΔMWh, ΔValue, Payback)**

### Purpose

Convert detections → business impact per site.

### Wireframe

     -----------------------------------------------------------
    | ROI Summary for Pilot C&I Rooftop    [Assumptions ▸]      |
     -----------------------------------------------------------
    |  ▶ Estimated Annual Loss:   1.37 MWh                       |
    |  ▶ Value at Risk:          AUD $192                        |
    | ▶ Quick Wins:             3 actions |
    | ----------------------------------- |
    | Breakdown by Issue                  |
    | Soiling (2)          ▮▮▮ 0.82 MWh   |
    | Vegetation (1)       ▮▮  0.34 MWh   |
    | Hotspots (3)         ▮    0.21 MWh  |
     -----------------------------------------------------------
    | Suggested ROI-positive actions                               |
    |  1) Clean array A       Payback: 1.2 months                 |
    |  2) Trim vegetation S12 Payback: 0.7 months                 |

### Flow B‑ready

This screen feeds into the **Prioritizer**:

*   Each action already contains ΔMWh, Δ$.
*   Add: “Send all to Agentic Prioritizer”.

***

# 5) **Prioritized Actions List (MVP)**

### Purpose

Ranked actionable list generated from detections & ROI.

### Wireframe

     ----------------------------------------------------------
    | Prioritized Actions                                      |
     ----------------------------------------------------------
    | [ # ] [Action]              [Impact]   [Cost]  [Rank] |
    | ----------------------------------------------------- |
    | 1     Trim vegetation S12   +0.34 MWh   $32     ★9.7  |
    | 2     Clean array A         +0.82 MWh   $46     ★9.3  |
    | 3     Inspect hotspot #32   +0.12 MWh   $15     ★8.9  |
     ----------------------------------------------------------
    |  [Create Work Order]    [Export CSV]    [Send to Crew ▸]  |

### Flow B‑ready

Flow B will add:

*   Multi‑objective score explanation
*   Drive‑time cost
*   Dispatch constraints
*   Crew assignment UI

***

# 6) **Work Order Creation Screen (simple)**

### Purpose

Package prioritized actions into a work plan.

### Wireframe

     ----------------------------------------------------------
    | Create Work Order                                         |
     ----------------------------------------------------------
    | Title: ____________________________________               |
    | Description: __________________________________________   |
    | Actions Included (3)                                      |
    |   ✓ Trim vegetation S12                                   |
    |   ✓ Clean array A                                         |
    |   ✓ Inspect hotspot #32                                   |
     ----------------------------------------------------------
    |  Estimated Total Cost: $93                                |
    |  Estimated Energy Gain: 1.28 MWh                          |
     ----------------------------------------------------------
    |  [Create Work Order]         [Cancel]                     |

### Flow B‑ready

Future:

*   Add Crew Selector
*   Add Route Optimization
*   Add Auto‑Scheduling

***

# 🌱 **How Flow A sets up Flow B**

Flow A already defines:

### **Detections → ΔMWh → Action items → Work Orders**

Flow B simply extends the graph:

    Detections
       → Impact estimate (ΔMWh, Δ$)
          → Priority score (Flow B)
              → Work orders & Crew routing

The **database schema** you implemented (priority\_queue, work\_order, crew\_shift, route\_plan) is 100% aligned with this progression.

***

# 🔥 Ready for the next step: Visual wireframes?

Next steps:

1.  **Generate PNG wireframes (low-fi)**
2.  **Generate HTML click-through prototype**
3.  **Generate Figma‑style layout (PNG + spacing tokens + color styles)**
4.  **All of the above**

If you choose visual wireframes, also decide:

*   **Color theme preference**: dark, light, or neutral
*   **Density**: compact (data-heavy), standard, or roomy (user‑friendly)
*   **Sidebar**: left vs top navigation
