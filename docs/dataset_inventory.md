# Dataset Inventory — Healthcare Performance Benchmarking (CMS)

---

## Overview

This project uses publicly available CMS (Centers for Medicare & Medicaid Services) datasets to benchmark hospital performance across cost, safety, outcomes, readmissions, and patient experience.

The datasets are integrated at the **hospital level (Facility ID)** and standardized into a unified analytical model.

---

## 1. Hospital General Information

**Source:** CMS Hospital General Information  
**Grain:** 1 row per hospital  

### Key Columns
- facility_id
- facility_name
- state
- hospital_type
- hospital_ownership
- emergency_services
- hospital_overall_rating

### Purpose
- Master reference for hospital attributes  
- Forms the base of `dim_hospital`

---

## 2. Medicare Spending per Patient

**Source:** CMS MSPB Dataset  
**Grain:** hospital + measure + reporting period  

### Key Columns
- facility_id
- measure_id
- score

### Purpose
- Measures cost efficiency  
- Used to build **cost benchmark**

### Role
- FACT TABLE → `fact_spending`

---

## 3. Healthcare-Associated Infections (HAI)

**Source:** CMS Infections Dataset  
**Grain:** hospital + measure + reporting period  

### Key Columns
- facility_id
- measure_id
- score (SIR values)

### Purpose
- Measures patient safety via infection rates  
- Only SIR-based measures used for benchmarking

### Role
- FACT TABLE → `fact_infections`

---

## 4. Complications and Deaths

**Source:** CMS Complications & Deaths Dataset  
**Grain:** hospital + measure + reporting period  

### Key Columns
- facility_id
- measure_id
- score

### Purpose
- Measures adverse outcomes  
- Used in **outcomes benchmark**

### Role
- FACT TABLE → `fact_complications`

---

## 5. Unplanned Hospital Visits (Readmissions)

**Source:** CMS Readmissions Dataset  
**Grain:** hospital + measure + reporting period  

### Key Columns
- facility_id
- measure_id
- score

### Purpose
- Measures readmission rates  
- Used in **readmission benchmark**

### Role
- FACT TABLE → `fact_readmissions`

---

## 6. Timely and Effective Care

**Source:** CMS Timely Care Dataset  
**Grain:** hospital + measure + reporting period  

### Key Columns
- facility_id
- measure_id
- condition
- score

### Purpose
- Measures process efficiency and treatment timeliness  

### Role
- FACT TABLE → `fact_timely_care`

---

## 7. HCAHPS (Patient Experience)

**Source:** CMS HCAHPS Survey Data  
**Grain:** hospital + question + answer category  

### Key Columns
- facility_id
- hcahps_question
- hcahps_answer_description
- score

### Purpose
- Measures patient satisfaction  
- Used to compute:
  - Top-box % (positive responses)
  - Star ratings

### Role
- FACT TABLE → `fact_hcahps`

---

## 8. Rural ZIP Classification (HRSA)

**Source:** HRSA ZIP Code Rural Classification  
**Grain:** ZIP code  

### Key Columns
- zip_code
- rural_flag

### Purpose
- Enrich hospitals with rural/urban classification  

### Role
- Used to derive `rural_flag` in `dim_hospital`

---

## Conformed Dimensions

### dim_hospital
- facility_id_clean (PK)
- facility_name
- state
- hospital_type
- ownership
- rural_flag

### dim_measure
- measure_id
- measure_name
- source_domain
- condition (optional)
- hcahps_question (optional)
- hcahps_answer_description (optional)

---

## Key Relationships

- All fact tables join on:
  - `facility_id_clean`

- Measures join via:
  - `measure_id` → `dim_measure`

- Hospital attributes join via:
  - `facility_id_clean` → `dim_hospital`

---

## Notes

- Not all hospitals have data in all domains → NULLs are expected  
- Infection benchmark uses **SIR measures only**  
- HCAHPS uses **top-box methodology**  
- Rural classification is derived via ZIP-based join  