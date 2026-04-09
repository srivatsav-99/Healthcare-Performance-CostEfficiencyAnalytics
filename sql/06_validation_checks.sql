/*
File: 06_validation_checks.sql
Purpose: Validates record counts and referential integrity of the final model.
Author: Srivatsav
Project: Healthcare Performance & Cost Efficiency Analytics
*/

-- Validate all final tables
SELECT COUNT(*) FROM dim_hospital;
SELECT COUNT(DISTINCT facility_id_clean) FROM dim_hospital;

SELECT COUNT(*) FROM dim_measure;

SELECT COUNT(*) FROM fact_hcahps;
SELECT COUNT(*) FROM fact_complications;
SELECT COUNT(*) FROM fact_infections;
SELECT COUNT(*) FROM fact_readmissions;
SELECT COUNT(*) FROM fact_spending;
SELECT COUNT(*) FROM fact_timely_care;

SELECT COUNT(DISTINCT facility_id_clean) FROM fact_hcahps;
SELECT COUNT(DISTINCT facility_id_clean) FROM fact_complications;
SELECT COUNT(DISTINCT facility_id_clean) FROM fact_infections;
SELECT COUNT(DISTINCT facility_id_clean) FROM fact_readmissions;
SELECT COUNT(DISTINCT facility_id_clean) FROM fact_spending;
SELECT COUNT(DISTINCT facility_id_clean) FROM fact_timely_care;