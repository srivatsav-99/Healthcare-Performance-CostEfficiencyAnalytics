# Setup Guide

## Option 1 — Fast Start (CSV for Dashboarding)
Use the processed files in `data/processed/`:

- `hospital_performance_export.csv`
- `hospital_master.csv`
- `dim_measure.csv`

This option is intended for teammates who want to build dashboards without setting up SQL Server.

---

## Option 2 — Full SQL Server Rebuild

### Requirements
- SQL Server
- DBeaver or SSMS
- Power BI Desktop

### Step 1 — Create Database
Create a SQL Server database named:

`healthcare_capacity`

### Step 2 — Place Source Files
Put the raw source files in:

`data/raw/`

### Step 3 — Run SQL Scripts in Order
Run the SQL files in the following order:

1. `sql/01_raw_ingestion.sql`
2. `sql/02_profiling_checks.sql`
3. `sql/03_staging_tables.sql`
4. `sql/04_dimensions.sql`
5. `sql/05_fact_tables.sql`
6. `sql/06_validation_checks.sql`
7. `sql/07_analytical_views.sql`
8. `sql/08_benchmark_refinement.sql`

### Step 4 — Connect Power BI
Connect Power BI to SQL Server and use:
- `vw_hospital_performance_export`
- `vw_hospital_master`
- `dim_measure`

---

## Notes
- Eight ambiguous facility IDs were excluded intentionally.
- Null values are expected in some benchmark columns because source coverage differs by hospital and measure domain.
- Rural classification is derived from HRSA ZIP-based rural lookup data.