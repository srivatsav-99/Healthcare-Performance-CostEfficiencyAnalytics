/*
File: 02_profiling_checks.sql
Purpose: Executes data quality and schema profiling on raw CMS datasets.
Author: Srivatsav
Project: Healthcare Performance & Cost Efficiency Analytics
*/

-- Investigate duplicate hospitals in raw_hospital_info
SELECT [Facility ID], COUNT(*) AS cnt
FROM raw_hospital_info
GROUP BY [Facility ID]
HAVING COUNT(*) > 1
ORDER BY cnt DESC, [Facility ID];

-- then inspecting duplicate rows
SELECT *
FROM raw_hospital_info
WHERE [Facility ID] IN (
    SELECT [Facility ID]
    FROM raw_hospital_info
    GROUP BY [Facility ID]
    HAVING COUNT(*) > 1
)
ORDER BY [Facility ID];

-- Check whether Facility ID and ZIP are stored as text or numeric
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'raw_hospital_info'
  AND COLUMN_NAME IN ('Facility ID', 'ZIP Code');

SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'raw_hcahps'
  AND COLUMN_NAME IN ('Facility ID', 'ZIP Code');

-- Check if Facility ID formatting is consistent across tables
SELECT TOP 20 [Facility ID]
FROM raw_hospital_info
ORDER BY [Facility ID];

SELECT TOP 20 [Facility ID]
FROM raw_hcahps
ORDER BY [Facility ID];

-- Check ZIP joinability to rural lookup
SELECT TOP 20 ZIP_CODE
FROM raw_rural_zip
ORDER BY ZIP_CODE;

SELECT TOP 20 [ZIP Code]
FROM raw_hospital_info
ORDER BY [ZIP Code];

-- Count overlap of hospitals between hospital master and each fact
SELECT COUNT(DISTINCT h.[Facility ID]) AS matched_facilities
FROM raw_hospital_info h
INNER JOIN raw_hcahps x
    ON h.[Facility ID] = x.[Facility ID];

SELECT COUNT(DISTINCT h.[Facility ID]) AS matched_facilities
FROM raw_hospital_info h
INNER JOIN raw_complications x
    ON h.[Facility ID] = x.[Facility ID];

SELECT COUNT(DISTINCT h.[Facility ID]) AS matched_facilities
FROM raw_hospital_info h
INNER JOIN raw_spending x
    ON h.[Facility ID] = x.[Facility ID];

SELECT COUNT(DISTINCT h.[Facility ID]) AS matched_facilities
FROM raw_hospital_info h
INNER JOIN raw_timely_care x
    ON h.[Facility ID] = x.[Facility ID];

-- Check measure cardinality in each fact table
SELECT COUNT(DISTINCT [HCAHPS Measure ID]) AS measure_cnt
FROM raw_hcahps;

SELECT COUNT(DISTINCT [Measure ID]) AS measure_cnt
FROM raw_complications;

SELECT COUNT(DISTINCT [Measure ID]) AS measure_cnt
FROM raw_infections;

SELECT COUNT(DISTINCT [Measure ID]) AS measure_cnt
FROM raw_readmissions;

SELECT COUNT(DISTINCT [Measure ID]) AS measure_cnt
FROM raw_spending;

SELECT COUNT(DISTINCT [Measure ID]) AS measure_cnt
FROM raw_timely_care;

-- Check score quality before transformation
SELECT TOP 50 [Score], COUNT(*) AS cnt
FROM raw_complications
GROUP BY [Score]
ORDER BY cnt DESC;

SELECT TOP 50 [Score], COUNT(*) AS cnt
FROM raw_infections
GROUP BY [Score]
ORDER BY cnt DESC;

SELECT TOP 50 [Score], COUNT(*) AS cnt
FROM raw_readmissions
GROUP BY [Score]
ORDER BY cnt DESC;

SELECT TOP 50 [Score], COUNT(*) AS cnt
FROM raw_spending
GROUP BY [Score]
ORDER BY cnt DESC;

SELECT TOP 50 [Score], COUNT(*) AS cnt
FROM raw_timely_care
GROUP BY [Score]
ORDER BY cnt DESC;
