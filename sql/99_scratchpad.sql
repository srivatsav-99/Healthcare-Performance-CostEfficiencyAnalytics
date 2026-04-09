
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

-- Create a clean conformed hospital dimension
SELECT
    h.facility_id_clean,
    h.facility_name,
    h.address,
    h.city_town,
    h.state,
    h.zip_code_clean,
    h.county_parish,
    h.telephone_number,
    h.hospital_type,
    h.hospital_ownership,
    h.emergency_services,
    h.birthing_friendly_flag,
    h.hospital_overall_rating,
    h.hospital_overall_rating_footnote,
    r.rural_flag
INTO dim_hospital
FROM stg_hospital_info_clean h
INNER JOIN (
    SELECT DISTINCT CAST(CAST([Facility ID] AS INT) AS VARCHAR(10)) AS facility_id_clean
    FROM stg_facility_universe
) u
    ON h.facility_id_clean = u.facility_id_clean
LEFT JOIN stg_rural_zip_clean r
    ON h.zip_code_clean = r.zip_code_clean
LEFT JOIN stg_ambiguous_facilities a
    ON h.facility_id_clean = a.facility_id_clean
WHERE a.facility_id_clean IS NULL;

SELECT COUNT(*) AS dim_hospital_rows
FROM dim_hospital;

SELECT COUNT(DISTINCT facility_id_clean) AS distinct_facilities
FROM dim_hospital;

-- Build a conformed measure dimension
SELECT DISTINCT
    measure_id,
    measure_name,
    source_domain,
    condition,
    hcahps_question,
    hcahps_answer_description
INTO dim_measure
FROM (
    SELECT
        measure_id,
        measure_name,
        'Complications' AS source_domain,
        CAST(NULL AS VARCHAR(255)) AS condition,
        CAST(NULL AS VARCHAR(500)) AS hcahps_question,
        CAST(NULL AS VARCHAR(500)) AS hcahps_answer_description
    FROM stg_complications_clean

    UNION

    SELECT
        measure_id,
        measure_name,
        'Infections' AS source_domain,
        CAST(NULL AS VARCHAR(255)) AS condition,
        CAST(NULL AS VARCHAR(500)) AS hcahps_question,
        CAST(NULL AS VARCHAR(500)) AS hcahps_answer_description
    FROM stg_infections_clean

    UNION

    SELECT
        measure_id,
        measure_name,
        'Readmissions' AS source_domain,
        CAST(NULL AS VARCHAR(255)) AS condition,
        CAST(NULL AS VARCHAR(500)) AS hcahps_question,
        CAST(NULL AS VARCHAR(500)) AS hcahps_answer_description
    FROM stg_readmissions_clean

    UNION

    SELECT
        measure_id,
        measure_name,
        'Spending' AS source_domain,
        CAST(NULL AS VARCHAR(255)) AS condition,
        CAST(NULL AS VARCHAR(500)) AS hcahps_question,
        CAST(NULL AS VARCHAR(500)) AS hcahps_answer_description
    FROM stg_spending_clean

    UNION

    SELECT
        measure_id,
        measure_name,
        'Timely Care' AS source_domain,
        condition,
        CAST(NULL AS VARCHAR(500)) AS hcahps_question,
        CAST(NULL AS VARCHAR(500)) AS hcahps_answer_description
    FROM stg_timely_care_clean

    UNION

    SELECT
        [HCAHPS Measure ID] AS measure_id,
        [HCAHPS Answer Description] AS measure_name,
        'HCAHPS' AS source_domain,
        CAST(NULL AS VARCHAR(255)) AS condition,
        [HCAHPS Question] AS hcahps_question,
        [HCAHPS Answer Description] AS hcahps_answer_description
    FROM raw_hcahps
) x;

SELECT source_domain, COUNT(*) AS measure_count
FROM dim_measure
GROUP BY source_domain
ORDER BY source_domain;

-- Create clean fact tables
SELECT
    s.facility_id_clean,
    s.measure_id,
    s.score_raw,
    s.score_num,
    s.footnote,
    s.start_date,
    s.end_date
INTO fact_spending
FROM stg_spending_clean s
INNER JOIN dim_hospital h
    ON s.facility_id_clean = h.facility_id_clean;

SELECT
    c.facility_id_clean,
    c.measure_id,
    c.compared_to_national,
    c.denominator_num,
    c.score_raw,
    c.score_num,
    c.lower_estimate_num,
    c.higher_estimate_num,
    c.footnote,
    c.start_date,
    c.end_date
INTO fact_complications
FROM stg_complications_clean c
INNER JOIN dim_hospital h
    ON c.facility_id_clean = h.facility_id_clean;

SELECT
    i.facility_id_clean,
    i.measure_id,
    i.compared_to_national,
    i.score_raw,
    i.score_num,
    i.footnote,
    i.start_date,
    i.end_date
INTO fact_infections
FROM stg_infections_clean i
INNER JOIN dim_hospital h
    ON i.facility_id_clean = h.facility_id_clean;

SELECT
    r.facility_id_clean,
    r.measure_id,
    r.compared_to_national,
    r.denominator_num,
    r.score_raw,
    r.score_num,
    r.lower_estimate_num,
    r.higher_estimate_num,
    r.footnote,
    r.start_date,
    r.end_date
INTO fact_readmissions
FROM stg_readmissions_clean r
INNER JOIN dim_hospital h
    ON r.facility_id_clean = h.facility_id_clean;

SELECT
    t.facility_id_clean,
    t.measure_id,
    t.condition,
    t.score_raw,
    t.score_num,
    t.footnote,
    t.start_date,
    t.end_date
INTO fact_timely_care
FROM stg_timely_care_clean t
INNER JOIN dim_hospital h
    ON t.facility_id_clean = h.facility_id_clean;

SELECT
    CAST(CAST([Facility ID] AS INT) AS VARCHAR(10)) AS facility_id_clean,
    [HCAHPS Measure ID] AS measure_id,
    [HCAHPS Question] AS hcahps_question,
    [HCAHPS Answer Description] AS hcahps_answer_description,
    TRY_CAST([Patient Survey Star Rating] AS FLOAT) AS patient_survey_star_rating_num,
    [Patient Survey Star Rating] AS patient_survey_star_rating_raw,
    TRY_CAST([HCAHPS Answer Percent] AS FLOAT) AS hcahps_answer_percent_num,
    [HCAHPS Answer Percent] AS hcahps_answer_percent_raw,
    TRY_CAST([HCAHPS Linear Mean Value] AS FLOAT) AS hcahps_linear_mean_value_num,
    TRY_CAST([Number of Completed Surveys] AS FLOAT) AS completed_surveys_num,
    TRY_CAST([Survey Response Rate Percent] AS FLOAT) AS survey_response_rate_percent_num,
    TRY_CAST([Start Date] AS DATE) AS start_date,
    TRY_CAST([End Date] AS DATE) AS end_date
INTO stg_hcahps_clean
FROM raw_hcahps;

SELECT
    h.facility_id_clean,
    h.measure_id,
    h.hcahps_question,
    h.hcahps_answer_description,
    h.patient_survey_star_rating_raw,
    h.patient_survey_star_rating_num,
    h.hcahps_answer_percent_raw,
    h.hcahps_answer_percent_num,
    h.hcahps_linear_mean_value_num,
    h.completed_surveys_num,
    h.survey_response_rate_percent_num,
    h.start_date,
    h.end_date
INTO fact_hcahps
FROM stg_hcahps_clean h
INNER JOIN dim_hospital d
    ON h.facility_id_clean = d.facility_id_clean;

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


