/*
File: 05_fact_tables.sql
Purpose: Finalizes numeric fact tables for the analytics layer.
Author: Srivatsav
Project: Healthcare Performance & Cost Efficiency Analytics
*/

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
