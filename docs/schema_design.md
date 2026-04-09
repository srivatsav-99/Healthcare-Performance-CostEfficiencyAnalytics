# Schema Design

## Core Modeling Approach
This project uses a multi-fact star schema for hospital benchmarking across cost, safety, outcomes, patient experience, and operational quality.

## Conformed Dimensions

### dim_hospital
Grain: 1 row per hospital in the benchmark universe  
Key: `facility_id_clean`

Includes:
- hospital attributes from CMS Hospital General Information
- rural/urban enrichment from HRSA ZIP-based rural lookup

Note:
8 ambiguous facility IDs were excluded because the same Facility ID mapped to multiple hospitals in the source hospital information table.

### dim_measure
Grain: 1 row per measure definition by source domain  
Includes:
- measure_id
- measure_name
- source_domain
- condition (for timely care where applicable)
- HCAHPS question / answer description where applicable

## Fact Tables

### fact_hcahps
Grain: hospital + HCAHPS measure row + reporting period

### fact_complications
Grain: hospital + measure + reporting period

### fact_infections
Grain: hospital + measure + reporting period

### fact_readmissions
Grain: hospital + measure + reporting period

### fact_spending
Grain: hospital + measure + reporting period

### fact_timely_care
Grain: hospital + measure + reporting period

## Data Quality Notes
- `Facility ID` was imported as numeric and standardized into `facility_id_clean` as text
- ZIP codes were standardized into 5-character text fields
- score fields were preserved as both `score_raw` and `score_num` where applicable
- some domains have partial facility coverage:
  - spending: 4621 hospitals
  - timely care: 4652 hospitals

## Layered Data Model

### Raw Layer
Contains source CMS and HRSA datasets loaded into SQL Server raw tables.

### Staging Layer
Cleans key fields such as Facility ID and ZIP Code, standardizes score fields, and prepares data for dimensional modeling.

### Warehouse Layer
Includes:
- dim_hospital
- dim_measure
- fact_hcahps
- fact_complications
- fact_infections
- fact_readmissions
- fact_spending
- fact_timely_care

### Analytical View Layer
Includes:
- vw_hospital_master
- vw_cost_benchmark
- vw_safety_benchmark
- vw_outcomes_benchmark
- vw_readmission_benchmark
- vw_patient_experience_benchmark
- vw_hospital_performance_summary
- vw_hospital_performance_export