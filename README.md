# Healthcare Performance & Cost Efficiency Analytics

## Project Overview

This project analyzes hospital performance across the United States using publicly available CMS and HRSA datasets. The goal is to identify what drives hospital quality and cost efficiency across clinical outcomes, readmissions, patient experience, safety, spending, and rural/urban differences.

The project was built as an end-to-end analytics solution using:

- SQL Server for data cleaning, transformation, dimensional modeling, and analytical views
- Power BI for dashboard development and business analysis
- GitHub for version control and documentation

The final dashboard answers six business questions related to hospital underperformance, Medicare spending, readmission drivers, patient experience, rural/urban patterns, and hospitals with strong safety but weak satisfaction.

---

## Business Problem

Healthcare performance is multi-dimensional. A hospital may perform well in one area, such as infection safety, but underperform in patient satisfaction, readmissions, or mortality outcomes.

This project addresses the question:

**What drives quality and cost efficiency in US hospitals, and which hospitals consistently underperform across key healthcare metrics?**

---

## Key Business Questions

1. Which hospitals are consistently underperforming across mortality, readmission, and patient experience?
2. Is there a meaningful relationship between Medicare spending per patient and overall hospital quality?
3. Which conditions drive the highest readmission rates, and which hospitals are most affected?
4. How does patient-reported experience correlate with clinical outcome scores?
5. Are there geographic patterns in hospital performance between rural and urban facilities?
6. Which hospitals have high safety scores but low patient satisfaction?

---

## Final Datasets Used

The project uses CMS hospital-level public datasets and HRSA rural classification data.

| Dataset | Purpose |
|---|---|
| Hospital General Information | Hospital attributes, type, ownership, location, overall rating |
| HCAHPS Patient Survey | Patient experience, top-box satisfaction, star ratings |
| Complications and Deaths | Mortality and patient safety outcome measures |
| Healthcare Associated Infections | Infection safety measures using SIR metrics |
| Unplanned Hospital Visits | Readmissions, EDAC days, and return visit measures |
| Medicare Spending per Beneficiary | Cost efficiency benchmark |
| Timely and Effective Care | Process and care delivery measures |
| HRSA Rural ZIP Lookup | Rural vs urban classification enrichment |

---

## Architecture

```text
CMS / HRSA Raw Files
        |
        v
SQL Server Raw Tables
        |
        v
Staging Layer
- Facility ID cleaning
- ZIP code cleaning
- Date conversion
- Numeric score standardization
- Ambiguous facility handling
        |
        v
Warehouse Layer
- dim_hospital
- fact_hcahps
- fact_complications
- fact_infections
- fact_readmissions
- fact_spending
- fact_timely_care
        |
        v
Analytical Views
- benchmark views
- condition-level views
- data completeness view
- final wide Power BI view
        |
        v
Power BI Dashboard
```

---

## Data Modeling Approach

The SQL layer follows a staged warehouse-style design.

### Raw Layer

Raw CMS and HRSA files are imported into SQL Server as source tables.

### Staging Layer

The staging layer standardizes core fields:

Facility ID converted into facility_id_clean
ZIP codes padded to five characters
score fields converted into numeric columns where possible
original raw score values preserved
reporting dates converted into SQL date fields
ambiguous hospital identifiers identified and excluded

### Warehouse Layer

The model contains one hospital dimension and multiple fact tables:

dim_hospital
fact_hcahps
fact_complications
fact_infections
fact_readmissions
fact_spending
fact_timely_care

### Analytical Layer

The analytical layer creates Power BI-ready views, including:

vw_cost_benchmark
vw_safety_benchmark
vw_outcomes_benchmark
vw_readmission_benchmark
vw_patient_experience_benchmark
vw_infection_conditions
vw_mortality_conditions
vw_readmission_conditions
vw_data_completeness
vw_hospital_performance_wide

The final dashboard connects to:
vw_hospital_performance_wide

---

## Key Data Quality Decisions

- Eight ambiguous Facility IDs were excluded because the same identifier mapped to multiple hospitals.
- HRSA ZIP-based rural classification was joined using cleaned five-character ZIP codes.
- Infection benchmarking uses only SIR-based HAI measures.
- HCAHPS patient experience uses top-box favorable response logic.
- Data completeness was explicitly modeled because not all hospitals report every CMS metric.
- Null values are preserved when hospitals do not report certain measures.

---

## Key Findings

- Hospital performance is multi-dimensional. Patient experience, mortality, readmissions, safety, and spending do not always move together.
- Higher Medicare spending does not show a strong positive relationship with overall hospital quality. The dashboard observed a weak negative spending-rating correlation.
- Rural hospitals do not universally underperform. Rural and urban patterns vary depending on whether the metric is satisfaction, readmission, mortality, or spending.
- Some hospitals show strong safety indicators but weak patient satisfaction, suggesting that operational communication and patient experience may require attention even when clinical safety is acceptable.
- Data completeness is an important analytical constraint. Hospitals with partial reporting can distort comparisons if not handled carefully.

---

## Dashboard Pages

The final Power BI dashboard includes five analytical pages:

1. Underperforming Hospitals Across Key Metrics
2. Relationship Between Medicare Spending and Hospital Quality
3. Patient Experience and Clinical Outcomes
4. Rural vs Urban Geographic Performance Patterns
5. Strong Safety but Weak Satisfaction

---

## Repository Structure

Healthcare-Performance-CostEfficiencyAnalytics/
├── assets/
│   └── screenshots/
├── data/
│   ├── raw/
│   └── processed/
├── docs/
│   ├── dataset_inventory.md
│   ├── object_inventory.md
│   ├── project_charter.md
│   ├── schema_design.md
│   ├── data_quality_notes.md
│   ├── setup_guide.md
│   └── hospital_variable_map.md
├── powerbi/
│   └── Group Project_Final.pbix
├── sql/
│   ├── 00_database_setup.sql
│   ├── 01_raw_ingestion.sql
│   ├── 02_profiling_checks.sql
│   ├── 03_staging_tables.sql
│   ├── 04_dimensions.sql
│   ├── 05_fact_tables.sql
│   ├── 06_validation_checks.sql
│   ├── 07_analytical_views.sql
│   ├── 08_benchmark_refinement.sql
│   └── 09_final_sqlserver_analytical_layer.sql
└── README.md

---

## How to Reproduce

### Option 1: Dashboard-Only Use

Use the processed export files in:

data/processed/

These files can be loaded directly into Power BI, Excel, or Python.

### Option 2: Full SQL Server Rebuild

1. Create a SQL Server database named:
healthcare_capacity

2. Import the raw CMS and HRSA datasets into the expected raw tables.

3. Run the SQL scripts from the sql/ folder in order.

4. Connect Power BI to SQL Server and use:
vw_hospital_performance_wide

---

## Tools Used

- SQL Server
- DBeaver
- Power BI Desktop
- GitHub
- CMS public datasets
- HRSA rural ZIP classification data

---

## Skills Demonstrated

- SQL data cleaning and transformation
- Dimensional modeling
- Multi-source data integration
- Healthcare KPI development
- Data quality and completeness checks
- Analytical view creation
- Power BI dashboard design
- Business-question-driven storytelling