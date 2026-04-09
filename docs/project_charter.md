# Healthcare Performance Benchmarking Dashboard (CMS)

---

## 1. Project Overview

This project builds a data-driven analytics system to evaluate and benchmark hospital performance across the United States using CMS datasets.

The system integrates multiple domains including cost, safety, outcomes, readmissions, and patient experience to create a unified hospital performance view.

The final solution includes:
- SQL-based data warehouse
- Benchmarking logic across domains
- Export-ready datasets for dashboarding in Power BI

---

## 2. Business Problem

Healthcare organizations and policymakers lack a unified view of hospital performance across multiple dimensions.

Key challenges include:
- Fragmented reporting across cost, safety, and experience
- Lack of standardized benchmarking across hospitals
- Difficulty identifying high-performing vs underperforming hospitals

This project addresses the need for a centralized benchmarking system that enables comparative analysis.

---

## 3. Objective

The objective is to:

- Integrate multiple CMS datasets into a unified model  
- Build standardized benchmarks across key performance domains  
- Classify hospitals into performance tiers  
- Enable downstream analytics and dashboarding  

---

## 4. Stakeholders

- Healthcare Administrators  
- Policy Makers  
- Hospital Operations Teams  
- Data Analysts  

---

## 5. Key Business Questions

- Which hospitals are top performers across multiple domains?  
- How does cost efficiency relate to quality outcomes?  
- Which hospitals have high readmission or infection risks?  
- How does patient satisfaction correlate with performance?  
- Do rural hospitals perform differently from urban hospitals?  

---

## 6. Key Metrics

- Average Spending Score  
- Infection Score (SIR-based)  
- Outcome Score  
- Readmission Score  
- HCAHPS Top-Box %  
- Star Rating  
- Composite Performance Tier  

---

## 7. Scope

### In Scope
- CMS datasets integration  
- SQL-based data modeling  
- Benchmark computation  
- Export datasets for BI tools  
- Multi-domain performance scoring  

### Out of Scope
- Real-time streaming  
- Predictive modeling  
- Patient-level data  

---

## 8. Assumptions

- Data is aggregated at hospital level  
- Not all hospitals have full coverage across datasets  
- Missing values reflect source limitations  

---

## 9. Success Criteria

- Clean, scalable data model  
- Accurate benchmark calculations  
- Reproducible SQL pipeline  
- Dashboard-ready outputs  
- Clear documentation  

---

## 10. Tools & Technologies

- SQL Server  
- DBeaver / SSMS  
- Power BI  
- GitHub  

---

## 11. Project Approach

1. Data ingestion into raw tables  
2. Data cleaning in staging layer  
3. Dimensional modeling (star schema)  
4. Fact table construction  
5. Benchmark view creation  
6. Final export generation  
7. Dashboard development  

---

## 12. Why This Project

This project demonstrates:

- End-to-end data engineering  
- Real-world healthcare analytics  
- SQL-based warehouse design  
- Business-driven benchmarking logic  