-- =============================================================================
-- Healthcare Performance & Cost Efficiency Analytics
-- SQL Server / Power BI Analytical Layer
-- Database: healthcare_capacity
--
-- PREREQUISITES: The following tables must exist and have data:
--   raw_hospital_info, raw_hcahps, raw_complications, raw_infections,
--   raw_readmissions, raw_spending, raw_timely_care, raw_rural_zip
--
-- HOW TO RUN:
--   Run each section one at a time in DBeaver (select block, Ctrl+Enter)
--   Sections are clearly marked with === boundaries
-- =============================================================================
-- SECTION 1: STAGING TABLES
-- =============================================================================

IF OBJECT_ID('stg_facility_universe', 'U') IS NOT NULL DROP TABLE stg_facility_universe;
SELECT DISTINCT
    CASE
        WHEN [Facility ID] NOT LIKE '%[^0-9]%' -- Simplified Regex for numeric only
        THEN CAST(CAST([Facility ID] AS BIGINT) AS VARCHAR(50))
        ELSE [Facility ID]
    END AS [Facility ID]
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

IF OBJECT_ID('stg_hospital_info_clean', 'U') IS NOT NULL DROP TABLE stg_hospital_info_clean;
SELECT
    CASE
        WHEN [Facility ID] NOT LIKE '%[^0-9]%'
        THEN CAST(CAST([Facility ID] AS BIGINT) AS VARCHAR(50))
        ELSE [Facility ID]
    END                                                                          AS facility_id_clean,
    [Facility Name]                                                              AS facility_name,
    [Address]                                                                    AS address,
    [City/Town]                                                                  AS city_town,
    [State]                                                                      AS state,
    RIGHT('00000' + CAST(CAST([ZIP Code] AS BIGINT) AS VARCHAR(5)), 5)           AS zip_code_clean,
    [County/Parish]                                                              AS county_parish,
    [Telephone Number]                                                           AS telephone_number,
    [Hospital Type]                                                              AS hospital_type,
    [Hospital Ownership]                                                         AS hospital_ownership,
    [Emergency Services]                                                         AS emergency_services,
    [Meets criteria for birthing friendly designation]                           AS birthing_friendly_flag,
    [Hospital overall rating]                                                    AS hospital_overall_rating,
    [Hospital overall rating footnote]                                           AS hospital_overall_rating_footnote
INTO stg_hospital_info_clean
FROM raw_hospital_info;

IF OBJECT_ID('stg_rural_zip_clean', 'U') IS NOT NULL DROP TABLE stg_rural_zip_clean;
SELECT
    RIGHT('00000' + CAST(CAST(ZIP_CODE AS BIGINT) AS VARCHAR(5)), 5) AS zip_code_clean,
    FORHP_Rural_approximation                                        AS rural_flag
INTO stg_rural_zip_clean
FROM raw_rural_zip;

IF OBJECT_ID('stg_ambiguous_facilities', 'U') IS NOT NULL DROP TABLE stg_ambiguous_facilities;
SELECT
    CASE
        WHEN [Facility ID] NOT LIKE '%[^0-9]%'
        THEN CAST(CAST([Facility ID] AS BIGINT) AS VARCHAR(50))
        ELSE [Facility ID]
    END AS facility_id_clean
INTO stg_ambiguous_facilities
FROM raw_hospital_info
GROUP BY [Facility ID]
HAVING COUNT(*) > 1;

-- Macro-style Staging for Complications
IF OBJECT_ID('stg_complications_clean', 'U') IS NOT NULL DROP TABLE stg_complications_clean;
SELECT
    CASE WHEN [Facility ID] NOT LIKE '%[^0-9]%' THEN CAST(CAST([Facility ID] AS BIGINT) AS VARCHAR(50)) ELSE [Facility ID] END AS facility_id_clean,
    [Measure ID]           AS measure_id,
    [Measure Name]         AS measure_name,
    [Compared to National] AS compared_to_national,
    CASE WHEN ISNUMERIC([Denominator]) = 1 THEN CAST([Denominator] AS DECIMAL(18,4)) ELSE NULL END AS denominator_num,
    CASE WHEN ISNUMERIC([Score]) = 1       THEN CAST([Score]       AS DECIMAL(18,4)) ELSE NULL END AS score_num,
    CASE WHEN ISNUMERIC([Lower Estimate]) = 1 THEN CAST([Lower Estimate] AS DECIMAL(18,4)) ELSE NULL END AS lower_estimate_num,
    CASE WHEN ISNUMERIC([Higher Estimate]) = 1 THEN CAST([Higher Estimate] AS DECIMAL(18,4)) ELSE NULL END AS higher_estimate_num,
    [Score]    AS score_raw,
    [Footnote] AS footnote,
    TRY_CONVERT(DATE, [Start Date], 101) AS start_date,
    TRY_CONVERT(DATE, [End Date], 101)   AS end_date
INTO stg_complications_clean
FROM raw_complications;

-- Staging for Infections
IF OBJECT_ID('stg_infections_clean', 'U') IS NOT NULL DROP TABLE stg_infections_clean;
SELECT
    CASE WHEN [Facility ID] NOT LIKE '%[^0-9]%' THEN CAST(CAST([Facility ID] AS BIGINT) AS VARCHAR(50)) ELSE [Facility ID] END AS facility_id_clean,
    [Measure ID]           AS measure_id,
    [Measure Name]         AS measure_name,
    [Compared to National] AS compared_to_national,
    CASE WHEN ISNUMERIC([Score]) = 1 THEN CAST([Score] AS DECIMAL(18,4)) ELSE NULL END AS score_num,
    [Score]    AS score_raw,
    [Footnote] AS footnote,
    TRY_CONVERT(DATE, [Start Date], 101) AS start_date,
    TRY_CONVERT(DATE, [End Date], 101)   AS end_date
INTO stg_infections_clean
FROM raw_infections;

-- Staging for Readmissions
IF OBJECT_ID('stg_readmissions_clean', 'U') IS NOT NULL DROP TABLE stg_readmissions_clean;
SELECT
    CASE WHEN [Facility ID] NOT LIKE '%[^0-9]%' THEN CAST(CAST([Facility ID] AS BIGINT) AS VARCHAR(50)) ELSE [Facility ID] END AS facility_id_clean,
    [Measure ID]           AS measure_id,
    [Measure Name]         AS measure_name,
    [Compared to National] AS compared_to_national,
    CASE WHEN ISNUMERIC([Denominator]) = 1 THEN CAST([Denominator] AS DECIMAL(18,4)) ELSE NULL END AS denominator_num,
    CASE WHEN ISNUMERIC([Score]) = 1       THEN CAST([Score]       AS DECIMAL(18,4)) ELSE NULL END AS score_num,
    CASE WHEN ISNUMERIC([Lower Estimate]) = 1 THEN CAST([Lower Estimate] AS DECIMAL(18,4)) ELSE NULL END AS lower_estimate_num,
    CASE WHEN ISNUMERIC([Higher Estimate]) = 1 THEN CAST([Higher Estimate] AS DECIMAL(18,4)) ELSE NULL END AS higher_estimate_num,
    [Score]    AS score_raw,
    [Footnote] AS footnote,
    TRY_CONVERT(DATE, [Start Date], 101) AS start_date,
    TRY_CONVERT(DATE, [End Date], 101)   AS end_date
INTO stg_readmissions_clean
FROM raw_readmissions;

-- Staging for Spending
IF OBJECT_ID('stg_spending_clean', 'U') IS NOT NULL DROP TABLE stg_spending_clean;
SELECT
    CASE WHEN [Facility ID] NOT LIKE '%[^0-9]%' THEN CAST(CAST([Facility ID] AS BIGINT) AS VARCHAR(50)) ELSE [Facility ID] END AS facility_id_clean,
    [Measure ID]   AS measure_id,
    [Measure Name] AS measure_name,
    CASE WHEN ISNUMERIC([Score]) = 1 THEN CAST([Score] AS DECIMAL(18,4)) ELSE NULL END AS score_num,
    [Score]    AS score_raw,
    [Footnote] AS footnote,
    TRY_CONVERT(DATE, [Start Date], 101) AS start_date,
    TRY_CONVERT(DATE, [End Date], 101)   AS end_date
INTO stg_spending_clean
FROM raw_spending;

-- Staging for Timely Care
IF OBJECT_ID('stg_timely_care_clean', 'U') IS NOT NULL DROP TABLE stg_timely_care_clean;
SELECT
    CASE WHEN [Facility ID] NOT LIKE '%[^0-9]%' THEN CAST(CAST([Facility ID] AS BIGINT) AS VARCHAR(50)) ELSE [Facility ID] END AS facility_id_clean,
    [Measure ID]   AS measure_id,
    [Measure Name] AS measure_name,
    [Condition]    AS condition_name,
    CASE WHEN ISNUMERIC([Score]) = 1 THEN CAST([Score] AS DECIMAL(18,4)) ELSE NULL END AS score_num,
    [Score]    AS score_raw,
    [Footnote] AS footnote,
    TRY_CONVERT(DATE, [Start Date], 101) AS start_date,
    TRY_CONVERT(DATE, [End Date], 101)   AS end_date
INTO stg_timely_care_clean
FROM raw_timely_care;

-- Staging for HCAHPS
IF OBJECT_ID('stg_hcahps_clean', 'U') IS NOT NULL DROP TABLE stg_hcahps_clean;
SELECT
    CASE WHEN [Facility ID] NOT LIKE '%[^0-9]%' THEN CAST(CAST([Facility ID] AS BIGINT) AS VARCHAR(50)) ELSE [Facility ID] END AS facility_id_clean,
    [HCAHPS Measure ID]                                                                    AS measure_id,
    [HCAHPS Question]                                                                      AS hcahps_question,
    [HCAHPS Answer Description]                                                            AS hcahps_answer_description,
    CASE WHEN ISNUMERIC([Patient Survey Star Rating]) = 1   THEN CAST([Patient Survey Star Rating]   AS DECIMAL(18,4)) ELSE NULL END AS patient_survey_star_rating_num,
    [Patient Survey Star Rating]                                                           AS patient_survey_star_rating_raw,
    CASE WHEN ISNUMERIC([HCAHPS Answer Percent]) = 1        THEN CAST([HCAHPS Answer Percent]        AS DECIMAL(18,4)) ELSE NULL END AS hcahps_answer_percent_num,
    [HCAHPS Answer Percent]                                                                AS hcahps_answer_percent_raw,
    CASE WHEN ISNUMERIC([HCAHPS Linear Mean Value]) = 1     THEN CAST([HCAHPS Linear Mean Value]     AS DECIMAL(18,4)) ELSE NULL END AS hcahps_linear_mean_value_num,
    CASE WHEN ISNUMERIC([Number of Completed Surveys]) = 1  THEN CAST([Number of Completed Surveys]  AS DECIMAL(18,4)) ELSE NULL END AS completed_surveys_num,
    CASE WHEN ISNUMERIC([Survey Response Rate Percent]) = 1 THEN CAST([Survey Response Rate Percent] AS DECIMAL(18,4)) ELSE NULL END AS survey_response_rate_percent_num,
    TRY_CONVERT(DATE, [Start Date], 101) AS start_date,
    TRY_CONVERT(DATE, [End Date], 101)   AS end_date
INTO stg_hcahps_clean
FROM raw_hcahps;


-- =============================================================================
-- SECTION 2: DIMENSIONS
-- =============================================================================

IF OBJECT_ID('dim_hospital', 'U') IS NOT NULL DROP TABLE dim_hospital;
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
    SELECT DISTINCT
        CASE
            WHEN [Facility ID] NOT LIKE '%[^0-9]%'
            THEN CAST(CAST([Facility ID] AS BIGINT) AS VARCHAR(50))
            ELSE [Facility ID]
        END AS facility_id_clean
    FROM stg_facility_universe
) u ON h.facility_id_clean = u.facility_id_clean
LEFT JOIN stg_rural_zip_clean r ON h.zip_code_clean = r.zip_code_clean
LEFT JOIN stg_ambiguous_facilities a ON h.facility_id_clean = a.facility_id_clean
WHERE a.facility_id_clean IS NULL;


-- =============================================================================
-- SECTION 3: FACT TABLES
-- =============================================================================

IF OBJECT_ID('fact_spending', 'U') IS NOT NULL DROP TABLE fact_spending;
SELECT s.facility_id_clean, s.measure_id, s.score_raw, s.score_num, s.footnote, s.start_date, s.end_date
INTO fact_spending FROM stg_spending_clean s
INNER JOIN dim_hospital h ON s.facility_id_clean = h.facility_id_clean;

IF OBJECT_ID('fact_complications', 'U') IS NOT NULL DROP TABLE fact_complications;
SELECT c.facility_id_clean, c.measure_id, c.compared_to_national, c.denominator_num, c.score_raw, c.score_num, c.lower_estimate_num, c.higher_estimate_num, c.footnote, c.start_date, c.end_date
INTO fact_complications FROM stg_complications_clean c
INNER JOIN dim_hospital h ON c.facility_id_clean = h.facility_id_clean;

IF OBJECT_ID('fact_infections', 'U') IS NOT NULL DROP TABLE fact_infections;
SELECT i.facility_id_clean, i.measure_id, i.compared_to_national, i.score_raw, i.score_num, i.footnote, i.start_date, i.end_date
INTO fact_infections FROM stg_infections_clean i
INNER JOIN dim_hospital h ON i.facility_id_clean = h.facility_id_clean;

IF OBJECT_ID('fact_readmissions', 'U') IS NOT NULL DROP TABLE fact_readmissions;
SELECT r.facility_id_clean, r.measure_id, r.compared_to_national, r.denominator_num, r.score_raw, r.score_num, r.lower_estimate_num, r.higher_estimate_num, r.footnote, r.start_date, r.end_date
INTO fact_readmissions FROM stg_readmissions_clean r
INNER JOIN dim_hospital h ON r.facility_id_clean = h.facility_id_clean;

IF OBJECT_ID('fact_timely_care', 'U') IS NOT NULL DROP TABLE fact_timely_care;
SELECT t.facility_id_clean, t.measure_id, t.condition_name, t.score_raw, t.score_num, t.footnote, t.start_date, t.end_date
INTO fact_timely_care FROM stg_timely_care_clean t
INNER JOIN dim_hospital h ON t.facility_id_clean = h.facility_id_clean;

IF OBJECT_ID('fact_hcahps', 'U') IS NOT NULL DROP TABLE fact_hcahps;
SELECT h.facility_id_clean, h.measure_id, h.hcahps_question, h.hcahps_answer_description, h.patient_survey_star_rating_raw, h.patient_survey_star_rating_num, h.hcahps_answer_percent_raw, h.hcahps_answer_percent_num, h.hcahps_linear_mean_value_num, h.completed_surveys_num, h.survey_response_rate_percent_num, h.start_date, h.end_date
INTO fact_hcahps FROM stg_hcahps_clean h
INNER JOIN dim_hospital d ON h.facility_id_clean = d.facility_id_clean;


-- =============================================================================
-- SECTION 4: ANALYTICAL VIEWS
-- =============================================================================

IF OBJECT_ID('vw_hospital_master', 'V') IS NOT NULL DROP VIEW vw_hospital_master;
GO
CREATE VIEW vw_hospital_master AS
SELECT facility_id_clean, facility_name, state, hospital_type, hospital_ownership, emergency_services, rural_flag, hospital_overall_rating
FROM dim_hospital;
GO

IF OBJECT_ID('vw_cost_benchmark', 'V') IS NOT NULL DROP VIEW vw_cost_benchmark;
GO
CREATE VIEW vw_cost_benchmark AS
SELECT facility_id_clean, AVG(score_num) AS avg_spending_score
FROM fact_spending
WHERE measure_id = 'MSPB_1' AND score_num IS NOT NULL
GROUP BY facility_id_clean;
GO

IF OBJECT_ID('vw_safety_benchmark', 'V') IS NOT NULL DROP VIEW vw_safety_benchmark;
GO
CREATE VIEW vw_safety_benchmark AS
SELECT facility_id_clean, AVG(score_num) AS avg_infection_score
FROM fact_infections
WHERE score_num IS NOT NULL
  AND score_raw NOT IN ('Not Available', 'N/A')
  AND measure_id IN ('HAI_1_SIR','HAI_2_SIR','HAI_3_SIR','HAI_4_SIR','HAI_5_SIR','HAI_6_SIR')
GROUP BY facility_id_clean;
GO

IF OBJECT_ID('vw_outcomes_benchmark', 'V') IS NOT NULL DROP VIEW vw_outcomes_benchmark;
GO
CREATE VIEW vw_outcomes_benchmark AS
SELECT facility_id_clean, AVG(score_num) AS avg_mortality_rate
FROM fact_complications
WHERE score_num IS NOT NULL
  AND score_raw NOT IN ('Not Available', 'N/A')
  AND measure_id LIKE 'MORT_%'
GROUP BY facility_id_clean;
GO

IF OBJECT_ID('vw_readmission_benchmark', 'V') IS NOT NULL DROP VIEW vw_readmission_benchmark;
GO
CREATE VIEW vw_readmission_benchmark AS
SELECT
    facility_id_clean,
    AVG(CASE WHEN measure_id LIKE 'READM_%' THEN score_num END) AS avg_readmission_rate,
    AVG(CASE WHEN measure_id LIKE 'EDAC_%'  THEN score_num END) AS avg_edac_days
FROM fact_readmissions
WHERE score_num IS NOT NULL
  AND score_raw NOT IN ('Not Available', 'N/A')
GROUP BY facility_id_clean;
GO

IF OBJECT_ID('vw_patient_experience_benchmark', 'V') IS NOT NULL DROP VIEW vw_patient_experience_benchmark;
GO
CREATE VIEW vw_patient_experience_benchmark AS
SELECT
    facility_id_clean,
    AVG(CASE WHEN measure_id = 'H_STAR_RATING' THEN patient_survey_star_rating_num END) AS avg_star_rating,
    AVG(CASE
            WHEN measure_id IN ('H_COMP_1_A_P','H_COMP_2_A_P','H_COMP_5_A_P',
                                'H_CLEAN_HSP_A_P','H_QUIET_HSP_A_P',
                                'H_HSP_RATING_9_10','H_RECMND_DY')
            THEN hcahps_answer_percent_num
        END) AS avg_top_box_percent
FROM fact_hcahps
GROUP BY facility_id_clean;
GO

IF OBJECT_ID('vw_infection_conditions', 'V') IS NOT NULL DROP VIEW vw_infection_conditions;
GO
CREATE VIEW vw_infection_conditions AS
SELECT
    i.facility_id_clean,
    h.facility_name, h.state, h.hospital_type, h.rural_flag,
    MAX(CASE WHEN i.measure_id = 'HAI_1_SIR' AND i.score_raw NOT IN ('Not Available','N/A') THEN i.score_num END) AS sir_clabsi,
    MAX(CASE WHEN i.measure_id = 'HAI_2_SIR' AND i.score_raw NOT IN ('Not Available','N/A') THEN i.score_num END) AS sir_cauti,
    MAX(CASE WHEN i.measure_id = 'HAI_3_SIR' AND i.score_raw NOT IN ('Not Available','N/A') THEN i.score_num END) AS sir_ssi_colon,
    MAX(CASE WHEN i.measure_id = 'HAI_4_SIR' AND i.score_raw NOT IN ('Not Available','N/A') THEN i.score_num END) AS sir_ssi_hysterectomy,
    MAX(CASE WHEN i.measure_id = 'HAI_5_SIR' AND i.score_raw NOT IN ('Not Available','N/A') THEN i.score_num END) AS sir_mrsa,
    MAX(CASE WHEN i.measure_id = 'HAI_6_SIR' AND i.score_raw NOT IN ('Not Available','N/A') THEN i.score_num END) AS sir_cdiff,
    MAX(CASE WHEN i.measure_id = 'HAI_1_SIR' THEN i.compared_to_national END) AS nat_clabsi,
    MAX(CASE WHEN i.measure_id = 'HAI_2_SIR' THEN i.compared_to_national END) AS nat_cauti,
    MAX(CASE WHEN i.measure_id = 'HAI_3_SIR' THEN i.compared_to_national END) AS nat_ssi_colon,
    MAX(CASE WHEN i.measure_id = 'HAI_4_SIR' THEN i.compared_to_national END) AS nat_ssi_hysterectomy,
    MAX(CASE WHEN i.measure_id = 'HAI_5_SIR' THEN i.compared_to_national END) AS nat_mrsa,
    MAX(CASE WHEN i.measure_id = 'HAI_6_SIR' THEN i.compared_to_national END) AS nat_cdiff,
    SUM(CASE
            WHEN i.measure_id IN ('HAI_1_SIR','HAI_2_SIR','HAI_3_SIR','HAI_4_SIR','HAI_5_SIR','HAI_6_SIR')
             AND i.compared_to_national = 'Worse than the National Benchmark'
            THEN 1 ELSE 0
        END) AS hai_types_worse_count
FROM fact_infections i
JOIN dim_hospital h ON i.facility_id_clean = h.facility_id_clean
GROUP BY i.facility_id_clean, h.facility_name, h.state, h.hospital_type, h.rural_flag;
GO

IF OBJECT_ID('vw_mortality_conditions', 'V') IS NOT NULL DROP VIEW vw_mortality_conditions;
GO
CREATE VIEW vw_mortality_conditions AS
SELECT
    c.facility_id_clean,
    h.facility_name, h.state, h.hospital_type, h.rural_flag,
    MAX(CASE WHEN c.measure_id = 'MORT_30_AMI'  AND c.score_raw NOT IN ('Not Available','N/A') THEN c.score_num END) AS mort_rate_ami,
    MAX(CASE WHEN c.measure_id = 'MORT_30_HF'   AND c.score_raw NOT IN ('Not Available','N/A') THEN c.score_num END) AS mort_rate_hf,
    MAX(CASE WHEN c.measure_id = 'MORT_30_PN'   AND c.score_raw NOT IN ('Not Available','N/A') THEN c.score_num END) AS mort_rate_pn,
    MAX(CASE WHEN c.measure_id = 'MORT_30_COPD' AND c.score_raw NOT IN ('Not Available','N/A') THEN c.score_num END) AS mort_rate_copd,
    MAX(CASE WHEN c.measure_id = 'MORT_30_CABG' AND c.score_raw NOT IN ('Not Available','N/A') THEN c.score_num END) AS mort_rate_cabg,
    MAX(CASE WHEN c.measure_id = 'MORT_30_STK'  AND c.score_raw NOT IN ('Not Available','N/A') THEN c.score_num END) AS mort_rate_stk,
    MAX(CASE WHEN c.measure_id = 'Hybrid_HWM'   AND c.score_raw NOT IN ('Not Available','N/A') THEN c.score_num END) AS mort_rate_hospital_wide,
    MAX(CASE WHEN c.measure_id = 'MORT_30_AMI'  THEN c.compared_to_national END) AS mort_nat_ami,
    MAX(CASE WHEN c.measure_id = 'MORT_30_HF'   THEN c.compared_to_national END) AS mort_nat_hf,
    MAX(CASE WHEN c.measure_id = 'MORT_30_PN'   THEN c.compared_to_national END) AS mort_nat_pn,
    MAX(CASE WHEN c.measure_id = 'MORT_30_COPD' THEN c.compared_to_national END) AS mort_nat_copd,
    MAX(CASE WHEN c.measure_id = 'MORT_30_CABG' THEN c.compared_to_national END) AS mort_nat_cabg,
    MAX(CASE WHEN c.measure_id = 'MORT_30_STK'  THEN c.compared_to_national END) AS mort_nat_stk,
    SUM(CASE
            WHEN c.measure_id IN ('MORT_30_AMI','MORT_30_HF','MORT_30_PN',
                                  'MORT_30_COPD','MORT_30_CABG','MORT_30_STK')
             AND c.compared_to_national = 'Worse than the National Rate'
            THEN 1 ELSE 0
        END) AS mort_conditions_worse_count,
    MAX(CASE WHEN c.measure_id = 'PSI_90'        AND c.score_raw NOT IN ('Not Available','N/A') THEN c.score_num END) AS psi90_composite_sir,
    MAX(CASE WHEN c.measure_id = 'COMP_HIP_KNEE' AND c.score_raw NOT IN ('Not Available','N/A') THEN c.score_num END) AS comp_hip_knee_rate_pct,
    MAX(CASE WHEN c.measure_id = 'PSI_03' AND c.score_raw NOT IN ('Not Available','N/A') THEN c.score_num END) AS psi03_pressure_ulcer_sir,
    MAX(CASE WHEN c.measure_id = 'PSI_06' AND c.score_raw NOT IN ('Not Available','N/A') THEN c.score_num END) AS psi06_collapsed_lung_sir,
    MAX(CASE WHEN c.measure_id = 'PSI_09' AND c.score_raw NOT IN ('Not Available','N/A') THEN c.score_num END) AS psi09_hemorrhage_sir,
    MAX(CASE WHEN c.measure_id = 'PSI_11' AND c.score_raw NOT IN ('Not Available','N/A') THEN c.score_num END) AS psi11_resp_failure_sir,
    MAX(CASE WHEN c.measure_id = 'PSI_12' AND c.score_raw NOT IN ('Not Available','N/A') THEN c.score_num END) AS psi12_blood_clots_sir,
    MAX(CASE WHEN c.measure_id = 'PSI_13' AND c.score_raw NOT IN ('Not Available','N/A') THEN c.score_num END) AS psi13_sepsis_sir,
    MAX(CASE WHEN c.measure_id = 'PSI_15' AND c.score_raw NOT IN ('Not Available','N/A') THEN c.score_num END) AS psi15_accidental_laceration_sir
FROM fact_complications c
JOIN dim_hospital h ON c.facility_id_clean = h.facility_id_clean
GROUP BY c.facility_id_clean, h.facility_name, h.state, h.hospital_type, h.rural_flag;
GO

IF OBJECT_ID('vw_readmission_conditions', 'V') IS NOT NULL DROP VIEW vw_readmission_conditions;
GO
CREATE VIEW vw_readmission_conditions AS
SELECT
    r.facility_id_clean,
    h.facility_name, h.state, h.hospital_type, h.rural_flag,
    MAX(CASE WHEN r.measure_id = 'READM_30_AMI'      AND r.score_raw NOT IN ('Not Available','N/A') THEN r.score_num END) AS readm_rate_ami,
    MAX(CASE WHEN r.measure_id = 'READM_30_HF'       AND r.score_raw NOT IN ('Not Available','N/A') THEN r.score_num END) AS readm_rate_hf,
    MAX(CASE WHEN r.measure_id = 'READM_30_PN'       AND r.score_raw NOT IN ('Not Available','N/A') THEN r.score_num END) AS readm_rate_pn,
    MAX(CASE WHEN r.measure_id = 'READM_30_COPD'     AND r.score_raw NOT IN ('Not Available','N/A') THEN r.score_num END) AS readm_rate_copd,
    MAX(CASE WHEN r.measure_id = 'READM_30_HIP_KNEE' AND r.score_raw NOT IN ('Not Available','N/A') THEN r.score_num END) AS readm_rate_hipknee,
    MAX(CASE WHEN r.measure_id = 'READM_30_CABG'     AND r.score_raw NOT IN ('Not Available','N/A') THEN r.score_num END) AS readm_rate_cabg,
    MAX(CASE WHEN r.measure_id = 'Hybrid_HWR'        AND r.score_raw NOT IN ('Not Available','N/A') THEN r.score_num END) AS readm_rate_hospital_wide,
    MAX(CASE WHEN r.measure_id = 'READM_30_AMI'      THEN r.compared_to_national END) AS readm_nat_ami,
    MAX(CASE WHEN r.measure_id = 'READM_30_HF'       THEN r.compared_to_national END) AS readm_nat_hf,
    MAX(CASE WHEN r.measure_id = 'READM_30_PN'       THEN r.compared_to_national END) AS readm_nat_pn,
    MAX(CASE WHEN r.measure_id = 'READM_30_COPD'     THEN r.compared_to_national END) AS readm_nat_copd,
    MAX(CASE WHEN r.measure_id = 'READM_30_HIP_KNEE' THEN r.compared_to_national END) AS readm_nat_hipknee,
    MAX(CASE WHEN r.measure_id = 'READM_30_CABG'     THEN r.compared_to_national END) AS readm_nat_cabg,
    SUM(CASE
            WHEN r.measure_id IN ('READM_30_AMI','READM_30_HF','READM_30_PN',
                                  'READM_30_COPD','READM_30_HIP_KNEE','READM_30_CABG')
             AND r.compared_to_national = 'Worse than the National Rate'
            THEN 1 ELSE 0
        END) AS readm_conditions_worse_count,
    MAX(CASE WHEN r.measure_id = 'EDAC_30_AMI' AND r.score_raw NOT IN ('Not Available','N/A') THEN r.score_num END) AS edac_days_ami,
    MAX(CASE WHEN r.measure_id = 'EDAC_30_HF'  AND r.score_raw NOT IN ('Not Available','N/A') THEN r.score_num END) AS edac_days_hf,
    MAX(CASE WHEN r.measure_id = 'EDAC_30_PN'  AND r.score_raw NOT IN ('Not Available','N/A') THEN r.score_num END) AS edac_days_pn,
    MAX(CASE WHEN r.measure_id = 'OP_36' AND r.score_raw NOT IN ('Not Available','N/A') THEN r.score_num END) AS op36_surgery_visit_ratio,
    MAX(CASE WHEN r.measure_id = 'OP_32' AND r.score_raw NOT IN ('Not Available','N/A') THEN r.score_num END) AS op32_colonoscopy_per1000
FROM fact_readmissions r
JOIN dim_hospital h ON r.facility_id_clean = h.facility_id_clean
GROUP BY r.facility_id_clean, h.facility_name, h.state, h.hospital_type, h.rural_flag;
GO

IF OBJECT_ID('vw_data_completeness', 'V') IS NOT NULL DROP VIEW vw_data_completeness;
GO
CREATE VIEW vw_data_completeness AS
SELECT
    h.facility_id_clean,
    h.facility_name,
    h.state,
    h.hospital_type,
    h.rural_flag,
    CASE WHEN sp.avg_spending_score IS NOT NULL THEN 1 ELSE 0 END AS has_spending,
    CASE WHEN inf.sir_clabsi IS NOT NULL OR inf.sir_cauti IS NOT NULL OR inf.sir_mrsa IS NOT NULL THEN 1 ELSE 0 END AS has_infections,
    CASE WHEN mo.mort_rate_ami IS NOT NULL OR mo.mort_rate_hf IS NOT NULL OR mo.mort_rate_pn IS NOT NULL THEN 1 ELSE 0 END AS has_mortality,
    CASE WHEN re.readm_rate_ami IS NOT NULL OR re.readm_rate_hf IS NOT NULL OR re.readm_rate_pn IS NOT NULL THEN 1 ELSE 0 END AS has_readmissions,
    CASE WHEN ex.avg_top_box_percent IS NOT NULL THEN 1 ELSE 0 END AS has_experience,
    CASE WHEN re.edac_days_ami IS NOT NULL OR re.edac_days_hf IS NOT NULL OR re.edac_days_pn IS NOT NULL THEN 1 ELSE 0 END AS has_edac,
    (
        CASE WHEN sp.avg_spending_score IS NOT NULL THEN 1 ELSE 0 END
      + CASE WHEN (inf.sir_clabsi IS NOT NULL OR inf.sir_cauti IS NOT NULL OR inf.sir_mrsa IS NOT NULL) THEN 1 ELSE 0 END
      + CASE WHEN (mo.mort_rate_ami IS NOT NULL OR mo.mort_rate_hf IS NOT NULL OR mo.mort_rate_pn IS NOT NULL) THEN 1 ELSE 0 END
      + CASE WHEN (re.readm_rate_ami IS NOT NULL OR re.readm_rate_hf IS NOT NULL OR re.readm_rate_pn IS NOT NULL) THEN 1 ELSE 0 END
      + CASE WHEN ex.avg_top_box_percent IS NOT NULL THEN 1 ELSE 0 END
      + CASE WHEN (re.edac_days_ami IS NOT NULL OR re.edac_days_hf IS NOT NULL OR re.edac_days_pn IS NOT NULL) THEN 1 ELSE 0 END
    ) AS completeness_score,
    CASE WHEN (
        CASE WHEN sp.avg_spending_score IS NOT NULL THEN 1 ELSE 0 END
      + CASE WHEN (inf.sir_clabsi IS NOT NULL OR inf.sir_cauti IS NOT NULL OR inf.sir_mrsa IS NOT NULL) THEN 1 ELSE 0 END
      + CASE WHEN (mo.mort_rate_ami IS NOT NULL OR mo.mort_rate_hf IS NOT NULL OR mo.mort_rate_pn IS NOT NULL) THEN 1 ELSE 0 END
      + CASE WHEN (re.readm_rate_ami IS NOT NULL OR re.readm_rate_hf IS NOT NULL OR re.readm_rate_pn IS NOT NULL) THEN 1 ELSE 0 END
      + CASE WHEN ex.avg_top_box_percent IS NOT NULL THEN 1 ELSE 0 END
      + CASE WHEN (re.edac_days_ami IS NOT NULL OR re.edac_days_hf IS NOT NULL OR re.edac_days_pn IS NOT NULL) THEN 1 ELSE 0 END
    ) = 6 THEN 1 ELSE 0 END AS data_complete_flag,
    CASE WHEN (
        CASE WHEN sp.avg_spending_score IS NOT NULL THEN 1 ELSE 0 END
      + CASE WHEN (inf.sir_clabsi IS NOT NULL OR inf.sir_cauti IS NOT NULL OR inf.sir_mrsa IS NOT NULL) THEN 1 ELSE 0 END
      + CASE WHEN (mo.mort_rate_ami IS NOT NULL OR mo.mort_rate_hf IS NOT NULL OR mo.mort_rate_pn IS NOT NULL) THEN 1 ELSE 0 END
      + CASE WHEN (re.readm_rate_ami IS NOT NULL OR re.readm_rate_hf IS NOT NULL OR re.readm_rate_pn IS NOT NULL) THEN 1 ELSE 0 END
      + CASE WHEN ex.avg_top_box_percent IS NOT NULL THEN 1 ELSE 0 END
      + CASE WHEN (re.edac_days_ami IS NOT NULL OR re.edac_days_hf IS NOT NULL OR re.edac_days_pn IS NOT NULL) THEN 1 ELSE 0 END
    ) >= 4 THEN 1 ELSE 0 END AS data_majority_flag,
    CASE
        WHEN (
            CASE WHEN sp.avg_spending_score IS NOT NULL THEN 1 ELSE 0 END
          + CASE WHEN (inf.sir_clabsi IS NOT NULL OR inf.sir_cauti IS NOT NULL OR inf.sir_mrsa IS NOT NULL) THEN 1 ELSE 0 END
          + CASE WHEN (mo.mort_rate_ami IS NOT NULL OR mo.mort_rate_hf IS NOT NULL OR mo.mort_rate_pn IS NOT NULL) THEN 1 ELSE 0 END
          + CASE WHEN (re.readm_rate_ami IS NOT NULL OR re.readm_rate_hf IS NOT NULL OR re.readm_rate_pn IS NOT NULL) THEN 1 ELSE 0 END
          + CASE WHEN ex.avg_top_box_percent IS NOT NULL THEN 1 ELSE 0 END
          + CASE WHEN (re.edac_days_ami IS NOT NULL OR re.edac_days_hf IS NOT NULL OR re.edac_days_pn IS NOT NULL) THEN 1 ELSE 0 END
        ) = 6 THEN 'Full Coverage (6/6)'
        WHEN (
            CASE WHEN sp.avg_spending_score IS NOT NULL THEN 1 ELSE 0 END
          + CASE WHEN (inf.sir_clabsi IS NOT NULL OR inf.sir_cauti IS NOT NULL OR inf.sir_mrsa IS NOT NULL) THEN 1 ELSE 0 END
          + CASE WHEN (mo.mort_rate_ami IS NOT NULL OR mo.mort_rate_hf IS NOT NULL OR mo.mort_rate_pn IS NOT NULL) THEN 1 ELSE 0 END
          + CASE WHEN (re.readm_rate_ami IS NOT NULL OR re.readm_rate_hf IS NOT NULL OR re.readm_rate_pn IS NOT NULL) THEN 1 ELSE 0 END
          + CASE WHEN ex.avg_top_box_percent IS NOT NULL THEN 1 ELSE 0 END
          + CASE WHEN (re.edac_days_ami IS NOT NULL OR re.edac_days_hf IS NOT NULL OR re.edac_days_pn IS NOT NULL) THEN 1 ELSE 0 END
        ) >= 4 THEN 'Majority Coverage (4-5/6)'
        WHEN (
            CASE WHEN sp.avg_spending_score IS NOT NULL THEN 1 ELSE 0 END
          + CASE WHEN (inf.sir_clabsi IS NOT NULL OR inf.sir_cauti IS NOT NULL OR inf.sir_mrsa IS NOT NULL) THEN 1 ELSE 0 END
          + CASE WHEN (mo.mort_rate_ami IS NOT NULL OR mo.mort_rate_hf IS NOT NULL OR mo.mort_rate_pn IS NOT NULL) THEN 1 ELSE 0 END
          + CASE WHEN (re.readm_rate_ami IS NOT NULL OR re.readm_rate_hf IS NOT NULL OR re.readm_rate_pn IS NOT NULL) THEN 1 ELSE 0 END
          + CASE WHEN ex.avg_top_box_percent IS NOT NULL THEN 1 ELSE 0 END
          + CASE WHEN (re.edac_days_ami IS NOT NULL OR re.edac_days_hf IS NOT NULL OR re.edac_days_pn IS NOT NULL) THEN 1 ELSE 0 END
        ) >= 1 THEN 'Partial Coverage (1-3/6)'
        ELSE 'No Usable Data (0/6)'
    END AS completeness_label
FROM dim_hospital h
LEFT JOIN vw_cost_benchmark               sp  ON h.facility_id_clean = sp.facility_id_clean
LEFT JOIN vw_infection_conditions         inf ON h.facility_id_clean = inf.facility_id_clean
LEFT JOIN vw_mortality_conditions         mo  ON h.facility_id_clean = mo.facility_id_clean
LEFT JOIN vw_readmission_conditions       re  ON h.facility_id_clean = re.facility_id_clean
LEFT JOIN vw_patient_experience_benchmark ex  ON h.facility_id_clean = ex.facility_id_clean;
GO

IF OBJECT_ID('vw_hospital_performance_wide', 'V') IS NOT NULL DROP VIEW vw_hospital_performance_wide;
GO
CREATE VIEW vw_hospital_performance_wide AS
SELECT
    h.facility_id_clean, h.facility_name, h.state, h.hospital_type, h.hospital_ownership, h.rural_flag, h.emergency_services, h.hospital_overall_rating,
    dc.completeness_score, dc.data_complete_flag, dc.data_majority_flag, dc.completeness_label, dc.has_spending, dc.has_infections, dc.has_mortality, dc.has_readmissions, dc.has_experience, dc.has_edac,
    mo.mort_rate_ami, mo.mort_rate_hf, mo.mort_rate_pn, mo.mort_rate_copd, mo.mort_rate_cabg, mo.mort_rate_stk, mo.mort_rate_hospital_wide, mo.mort_nat_ami, mo.mort_nat_hf, mo.mort_nat_pn, mo.mort_nat_copd, mo.mort_nat_cabg, mo.mort_nat_stk, mo.mort_conditions_worse_count, mo.psi90_composite_sir, mo.comp_hip_knee_rate_pct,
    re.readm_rate_ami, re.readm_rate_hf, re.readm_rate_pn, re.readm_rate_copd, re.readm_rate_hipknee, re.readm_rate_cabg, re.readm_rate_hospital_wide, re.readm_nat_ami, re.readm_nat_hf, re.readm_nat_pn, re.readm_nat_copd, re.readm_nat_hipknee, re.readm_nat_cabg, re.readm_conditions_worse_count, re.edac_days_ami, re.edac_days_hf, re.edac_days_pn, re.op36_surgery_visit_ratio, re.op32_colonoscopy_per1000,
    inf.sir_clabsi, inf.sir_cauti, inf.sir_ssi_colon, inf.sir_ssi_hysterectomy, inf.sir_mrsa, inf.sir_cdiff, inf.nat_clabsi, inf.nat_cauti, inf.nat_mrsa, inf.nat_cdiff, inf.hai_types_worse_count,
    ex.avg_star_rating, ex.avg_top_box_percent, sp.avg_spending_score,
    (COALESCE(mo.mort_rate_ami, 0) + COALESCE(mo.mort_rate_hf, 0) + COALESCE(mo.mort_rate_pn, 0) + COALESCE(mo.mort_rate_copd, 0) + COALESCE(mo.mort_rate_cabg, 0) + COALESCE(mo.mort_rate_stk, 0)) / 
    NULLIF( (CASE WHEN mo.mort_rate_ami IS NOT NULL THEN 1 ELSE 0 END + CASE WHEN mo.mort_rate_hf IS NOT NULL THEN 1 ELSE 0 END + CASE WHEN mo.mort_rate_pn IS NOT NULL THEN 1 ELSE 0 END + CASE WHEN mo.mort_rate_copd IS NOT NULL THEN 1 ELSE 0 END + CASE WHEN mo.mort_rate_cabg IS NOT NULL THEN 1 ELSE 0 END + CASE WHEN mo.mort_rate_stk IS NOT NULL THEN 1 ELSE 0 END), 0) AS avg_mortality_rate,
    (COALESCE(re.readm_rate_ami, 0) + COALESCE(re.readm_rate_hf, 0) + COALESCE(re.readm_rate_pn, 0) + COALESCE(re.readm_rate_copd, 0) + COALESCE(re.readm_rate_hipknee, 0) + COALESCE(re.readm_rate_cabg, 0)) / 
    NULLIF( (CASE WHEN re.readm_rate_ami IS NOT NULL THEN 1 ELSE 0 END + CASE WHEN re.readm_rate_hf IS NOT NULL THEN 1 ELSE 0 END + CASE WHEN re.readm_rate_pn IS NOT NULL THEN 1 ELSE 0 END + CASE WHEN re.readm_rate_copd IS NOT NULL THEN 1 ELSE 0 END + CASE WHEN re.readm_rate_hipknee IS NOT NULL THEN 1 ELSE 0 END + CASE WHEN re.readm_rate_cabg IS NOT NULL THEN 1 ELSE 0 END), 0) AS avg_readmission_rate,
    (COALESCE(inf.sir_clabsi, 0) + COALESCE(inf.sir_cauti, 0) + COALESCE(inf.sir_ssi_colon, 0) + COALESCE(inf.sir_ssi_hysterectomy, 0) + COALESCE(inf.sir_mrsa, 0) + COALESCE(inf.sir_cdiff, 0)) / 
    NULLIF( (CASE WHEN inf.sir_clabsi IS NOT NULL THEN 1 ELSE 0 END + CASE WHEN inf.sir_cauti IS NOT NULL THEN 1 ELSE 0 END + CASE WHEN inf.sir_ssi_colon IS NOT NULL THEN 1 ELSE 0 END + CASE WHEN inf.sir_ssi_hysterectomy IS NOT NULL THEN 1 ELSE 0 END + CASE WHEN inf.sir_mrsa IS NOT NULL THEN 1 ELSE 0 END + CASE WHEN inf.sir_cdiff IS NOT NULL THEN 1 ELSE 0 END), 0) AS avg_infection_score,
    CASE
        WHEN dc.completeness_score = 0 THEN 'Insufficient Data'
        WHEN ex.avg_star_rating >= 4 AND inf.hai_types_worse_count = 0 AND sp.avg_spending_score < 1.0 AND mo.mort_conditions_worse_count = 0 AND re.readm_conditions_worse_count = 0 AND dc.data_majority_flag = 1
        THEN 'Top Performer'
        WHEN ex.avg_star_rating >= 3 OR ex.avg_top_box_percent >= 70 THEN 'Average Performer'
        ELSE 'Low Performer'
    END AS performance_tier
FROM dim_hospital h
LEFT JOIN vw_data_completeness            dc  ON h.facility_id_clean = dc.facility_id_clean
LEFT JOIN vw_mortality_conditions         mo  ON h.facility_id_clean = mo.facility_id_clean
LEFT JOIN vw_readmission_conditions       re  ON h.facility_id_clean = re.facility_id_clean
LEFT JOIN vw_infection_conditions         inf ON h.facility_id_clean = inf.facility_id_clean
LEFT JOIN vw_patient_experience_benchmark ex  ON h.facility_id_clean = ex.facility_id_clean
LEFT JOIN vw_cost_benchmark               sp  ON h.facility_id_clean = sp.facility_id_clean;
GO

-- =============================================================================
-- SECTION 5: EXPORT FINAL DATASET
-- =============================================================================

SELECT * FROM vw_hospital_performance_wide;