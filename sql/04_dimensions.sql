/*
File: 04_dimensions.sql
Purpose: Creates conformed dimension tables for the CMS hospital benchmarking model.
Author: Srivatsav
Project: Healthcare Performance & Cost Efficiency Analytics
*/

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
