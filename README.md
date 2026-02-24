# 🏥 Healthcare Analytics — Post-Operative Recovery Platform

**Portfolio Project | SQL + R | Data Analysis**

> Analyzing patient recovery patterns, medication adherence, and clinical performance metrics using a structured relational database and R visualizations.

---

## 📌 Project Overview

This project simulates a real-world data pipeline for a post-operative patient monitoring SaaS platform. It demonstrates end-to-end data analyst skills: schema design, advanced SQL querying, and production-quality R visualizations.

**Business Questions Answered:**
- Which surgery types have the fastest recovery trajectories?
- How does medication adherence correlate with recovery outcomes?
- Which clinics have the highest alert resolution rates?
- What symptom combinations predict longer recovery times?
- Which patients need immediate clinical attention?

---

## 🗂️ Project Structure

```
healthcare-analytics/
│
├── sql/
│   ├── 01_schema_and_data.sql    # Schema + synthetic seed data
│   └── 02_analysis_queries.sql   # 12 analytical SQL queries
│
├── r/
│   └── analysis.R                # R data analysis + 6 ggplot2 charts
│
├── output_plots/                 # Generated visualizations (PNG)
│   ├── 01_recovery_trajectory.png
│   ├── 02_pain_distribution.png
│   ├── 03_temperature_trend.png
│   ├── 04_alert_heatmap.png
│   ├── 05_adherence_vs_recovery.png
│   └── 06_clinic_scorecard.png
│
└── README.md
```

---

## 🗄️ Database Schema

| Table | Rows | Description |
|---|---|---|
| `patients` | 10 | Demographics, surgery type & date |
| `clinics` | 3 | Clinic name and region |
| `doctors` | 3 | Doctor specialization and clinic |
| `daily_checkins` | 35 | Daily vitals and recovery scores |
| `medications` | 12 | Scheduled meds and adherence records |
| `alerts` | 10 | Clinical alerts with severity and resolution |

---

## 🔍 SQL Highlights

| # | Query | Technique |
|---|---|---|
| 1 | Recovery progress by surgery type | Conditional aggregation |
| 2 | Medication adherence rate per patient | LEFT JOIN + ratio |
| 3 | Alert severity by clinic | Multi-level GROUP BY |
| 4 | Fever trend over days | Time-series aggregation |
| 5 | Critical unresolved alerts | Priority filtering |
| 6 | Recovery score percentile ranking | **Window function RANK()** |
| 7 | 7-day rolling average pain | **Window function ROWS BETWEEN** |
| 8 | Symptom co-occurrence analysis | CASE WHEN matrix |
| 9 | Clinic performance scorecard | KPI aggregation |
| 10 | Age group recovery analysis | Binning + aggregation |
| 11 | Recovery velocity classification | CTE + derived metrics |
| 12 | Full patient summary view | CREATE VIEW |

---

## 📊 R Visualizations

| Chart | Type | Insight |
|---|---|---|
| Recovery Trajectory | Line + ribbon (SE) | Which surgeries recover fastest |
| Pain Distribution | Ridge plot (ggridges) | Pain profile by surgery type |
| Temperature Trend | Area + threshold line | Fever risk across recovery days |
| Alert Heatmap | Tile / heatmap | Clinic risk matrix |
| Adherence vs Recovery | Scatter + regression | Adherence impact on outcomes |
| Clinic Scorecard | Faceted bar | KPI comparison across clinics |

---

## ▶️ How to Run

### SQL (SQLite)
```bash
sqlite3 healthcare.db < sql/01_schema_and_data.sql
sqlite3 healthcare.db < sql/02_analysis_queries.sql
```

### R
```r
# Install dependencies (first run only)
install.packages(c("DBI","RSQLite","dplyr","tidyr","ggplot2",
                   "scales","patchwork","lubridate","viridis","ggridges"))

# Run full analysis
Rscript r/analysis.R
```

---

## 🛠️ Tech Stack

| Tool | Purpose |
|---|---|
| SQLite | Relational database engine |
| SQL | Schema design, aggregations, window functions, CTEs, views |
| R | Statistical analysis and visualization |
| ggplot2 | Publication-quality charts |
| ggridges | Ridge/density plots |
| dplyr / tidyr | Data wrangling |
| DBI + RSQLite | R ↔ SQLite connection |

---

## 👤 Author

**Antonio Augusto**  
Data Analyst | Process & Simulation Engineer  
📧 augustojudilson@gmail.com  
🔗 [linkedin.com/in/antonioaugustodata](https://linkedin.com/in/antonioaugustodata)

---

*This project is part of a data analytics portfolio demonstrating SQL, R, and domain knowledge in healthcare data.*
