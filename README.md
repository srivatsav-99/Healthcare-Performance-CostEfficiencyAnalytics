\# Healthcare Performance \& Cost Efficiency Analytics



\## Business Problem

Which hospital characteristics and operational factors are associated with high performance across cost, safety, patient experience, and outcomes, and how can hospitals be benchmarked into actionable performance tiers?



\## Final Datasets

\- CMS Hospital General Information

\- CMS HCAHPS

\- CMS Complications and Deaths

\- CMS Timely and Effective Care

\- CMS Healthcare Associated Infections

\- CMS Unplanned Hospital Visits

\- CMS Medicare Spending per Patient

\- HRSA ZIP-based rural classification



\## Data Engineering Work Completed

\- Raw data ingestion into SQL Server

\- Profiling and key validation

\- Staging layer with cleaned Facility ID and ZIP Code

\- Conformed dimensions and fact tables

\- Analytical benchmark views

\- Processed CSV exports for dashboarding



\## Core SQL Objects

\### Dimensions

\- dim\_hospital

\- dim\_measure



\### Facts

\- fact\_hcahps

\- fact\_complications

\- fact\_infections

\- fact\_readmissions

\- fact\_spending

\- fact\_timely\_care



\### Analytical Views

\- vw\_hospital\_master

\- vw\_cost\_benchmark

\- vw\_safety\_benchmark

\- vw\_outcomes\_benchmark

\- vw\_readmission\_benchmark

\- vw\_patient\_experience\_benchmark

\- vw\_hospital\_performance\_summary

\- vw\_hospital\_performance\_export



\## Processed Outputs

\- data/processed/hospital\_performance\_export.csv

\- data/processed/hospital\_master.csv

\- data/processed/dim\_measure.csv



\## Reproducibility



This repository supports two usage paths:



\### 1. Dashboard-only path

Use the processed CSVs in `data/processed/`.



\### 2. Full SQL rebuild path

Set up SQL Server, import the raw files from `data/raw/`, and run the SQL scripts in order as described in `docs/setup\_guide.md`.

