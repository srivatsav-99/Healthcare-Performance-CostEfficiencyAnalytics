/*
File: 03_staging_tables.sql
Purpose: Cleans and casts raw data into standardized staging tables.
Author: Srivatsav
Project: Healthcare Performance & Cost Efficiency Analytics
*/

-- Create a master facility universe
SELECT DISTINCT [Facility ID]
INTO stg_facility_universe
FROM (
    SELECT [Facility ID] FROM raw_hcahps
    UNION
    SELECT [Facility ID] FROM raw_complications
    UNION
    SELECT [Facility ID] FROM raw_infections
    UNION
    SELECT [Facility ID] FROM raw_readmissions
    UNION
    SELECT [Facility ID] FROM raw_spending
    UNION
    SELECT [Facility ID] FROM raw_timely_care
) u;

-- countcheck
SELECT COUNT(*) AS facility_universe_count
FROM stg_facility_universe;

-- Check which universe facilities have multiple hospital_info matches
SELECT u.[Facility ID], COUNT(*) AS hospital_info_rows
FROM stg_facility_universe u
JOIN raw_hospital_info h
    ON u.[Facility ID] = h.[Facility ID]
GROUP BY u.[Facility ID]
HAVING COUNT(*) > 1
ORDER BY hospital_info_rows DESC, u.[Facility ID];


SELECT
    CAST(CAST([Facility ID] AS INT) AS VARCHAR(10)) AS facility_id_clean,
    [Facility Name] AS facility_name,
    [Address] AS address,
    [City/Town] AS city_town,
    [State] AS state,
    RIGHT('00000' + CAST([ZIP Code] AS VARCHAR(5)), 5) AS zip_code_clean,
    [County/Parish] AS county_parish,
    [Telephone Number] AS telephone_number,
    [Hospital Type] AS hospital_type,
    [Hospital Ownership] AS hospital_ownership,
    [Emergency Services] AS emergency_services,
    [Meets criteria for birthing friendly designation] AS birthing_friendly_flag,
    [Hospital overall rating] AS hospital_overall_rating,
    [Hospital overall rating footnote] AS hospital_overall_rating_footnote
INTO stg_hospital_info_clean
FROM raw_hospital_info;

-- Cleaning the rural zip table
SELECT
    RIGHT('00000' + CAST(ZIP_CODE AS VARCHAR(5)), 5) AS zip_code_clean,
    FORHP_Rural_approximation AS rural_flag
INTO stg_rural_zip_clean
FROM raw_rural_zip;

-- validate
SELECT TOP 20 *
FROM stg_rural_zip_clean
ORDER BY zip_code_clean;

-- Check ZIP join coverage
SELECT 
    COUNT(DISTINCT h.zip_code_clean) AS hospital_zip_count,
    COUNT(DISTINCT r.zip_code_clean) AS matched_rural_zip_count
FROM stg_hospital_info_clean h
LEFT JOIN stg_rural_zip_clean r
    ON h.zip_code_clean = r.zip_code_clean
WHERE r.zip_code_clean IS NOT NULL;

SELECT 
    COUNT(*) AS hospital_rows,
    SUM(CASE WHEN r.zip_code_clean IS NOT NULL THEN 1 ELSE 0 END) AS matched_rows,
    SUM(CASE WHEN r.zip_code_clean IS NULL THEN 1 ELSE 0 END) AS unmatched_rows
FROM stg_hospital_info_clean h
LEFT JOIN stg_rural_zip_clean r
    ON h.zip_code_clean = r.zip_code_clean;

-- build score aware staging for each fact
SELECT
    CAST(CAST([Facility ID] AS INT) AS VARCHAR(10)) AS facility_id_clean,
    [Measure ID] AS measure_id,
    [Measure Name] AS measure_name,
    [Compared to National] AS compared_to_national,
    TRY_CAST([Denominator] AS FLOAT) AS denominator_num,
    TRY_CAST([Score] AS FLOAT) AS score_num,
    TRY_CAST([Lower Estimate] AS FLOAT) AS lower_estimate_num,
    TRY_CAST([Higher Estimate] AS FLOAT) AS higher_estimate_num,
    [Score] AS score_raw,
    [Footnote] AS footnote,
    TRY_CAST([Start Date] AS DATE) AS start_date,
    TRY_CAST([End Date] AS DATE) AS end_date
INTO stg_complications_clean
FROM raw_complications;

SELECT 
    CAST(CAST([Facility ID] AS INT) AS VARCHAR(10)) AS facility_id_clean,
    [Measure ID] AS measure_id,
    [Measure Name] AS measure_name,
    [Compared to National] AS compared_to_national,
    TRY_CAST([Score] AS FLOAT) AS score_num,
    [Score] AS score_raw,
    [Footnote] AS footnote,
    TRY_CAST([Start Date] AS DATE) AS start_date,
    TRY_CAST([End Date] AS DATE) AS end_date
INTO stg_infections_clean
FROM raw_infections;

SELECT 
    CAST(CAST([Facility ID] AS INT) AS VARCHAR(10)) AS facility_id_clean,
    [Measure ID] AS measure_id,
    [Measure Name] AS measure_name,
    [Compared to National] AS compared_to_national,
    TRY_CAST([Denominator] AS FLOAT) AS denominator_num,
    TRY_CAST([Score] AS FLOAT) AS score_num,
    TRY_CAST([Lower Estimate] AS FLOAT) AS lower_estimate_num,
    TRY_CAST([Higher Estimate] AS FLOAT) AS higher_estimate_num,
    [Score] AS score_raw,
    [Footnote] AS footnote,
    TRY_CAST([Start Date] AS DATE) AS start_date,
    TRY_CAST([End Date] AS DATE) AS end_date
INTO stg_readmissions_clean
FROM raw_readmissions;

SELECT 
    CAST(CAST([Facility ID] AS INT) AS VARCHAR(10)) AS facility_id_clean,
    [Measure ID] AS measure_id,
    [Measure Name] AS measure_name,
    TRY_CAST([Score] AS FLOAT) AS score_num,
    [Score] AS score_raw,
    [Footnote] AS footnote,
    TRY_CAST([Start Date] AS DATE) AS start_date,
    TRY_CAST([End Date] AS DATE) AS end_date
INTO stg_spending_clean
FROM raw_spending;

SELECT 
    CAST(CAST([Facility ID] AS INT) AS VARCHAR(10)) AS facility_id_clean,
    [Measure ID] AS measure_id,
    [Measure Name] AS measure_name,
    [Condition] AS condition,
    TRY_CAST([Score] AS FLOAT) AS score_num, -- Minutes or percentages
    [Score] AS score_raw,                    -- Categorical values
    [Footnote] AS footnote,
    TRY_CAST([Start Date] AS DATE) AS start_date,
    TRY_CAST([End Date] AS DATE) AS end_date
INTO stg_timely_care_clean
FROM raw_timely_care;

SELECT 
    'Infections' AS Source, 
    COUNT(*) AS Total, 
    COUNT(score_num) AS Numeric_Scores,
    SUM(CASE WHEN score_num IS NULL AND score_raw IS NOT NULL THEN 1 ELSE 0 END) AS Nullified_Strings
FROM stg_infections_clean;

SELECT TOP 20 *
FROM stg_hospital_info_clean;

-- Create a table of ambiguous facility IDs
SELECT DISTINCT CAST(CAST([Facility ID] AS INT) AS VARCHAR(10)) AS facility_id_clean
INTO stg_ambiguous_facilities
FROM raw_hospital_info
GROUP BY [Facility ID]
HAVING COUNT(*) > 1;

SELECT *
FROM stg_ambiguous_facilities
ORDER BY facility_id_clean;