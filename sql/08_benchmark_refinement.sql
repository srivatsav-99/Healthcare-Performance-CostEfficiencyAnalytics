-- Replace the overly broad benchmark views with cleaner ones

-- Spending benchmark
CREATE OR ALTER VIEW vw_cost_benchmark AS
SELECT
    s.facility_id_clean,
    AVG(s.score_num) AS avg_spending_score
FROM fact_spending s
WHERE s.score_num IS NOT NULL
GROUP BY s.facility_id_clean;

-- Outcomes benchmark
CREATE OR ALTER VIEW vw_outcomes_benchmark AS
SELECT
    c.facility_id_clean,
    AVG(c.score_num) AS avg_outcome_score
FROM fact_complications c
WHERE c.score_num IS NOT NULL
  AND c.score_raw <> 'Not Available'
GROUP BY c.facility_id_clean;

-- Readmission benchmark
CREATE OR ALTER VIEW vw_readmission_benchmark AS
SELECT
    r.facility_id_clean,
    AVG(r.score_num) AS avg_readmission_score
FROM fact_readmissions r
WHERE r.score_num IS NOT NULL
  AND r.score_raw <> 'Not Available'
GROUP BY r.facility_id_clean;

-- Infections benchmark 
-- First inspect the measure IDs:
SELECT DISTINCT measure_id, measure_name
FROM fact_infections
ORDER BY measure_id;

-- fix: Query the staging table instead
SELECT DISTINCT measure_id, measure_name
FROM stg_infections_clean
ORDER BY measure_id;

-- Replace vw_safety_benchmark
CREATE OR ALTER VIEW vw_safety_benchmark AS
SELECT
    i.facility_id_clean,
    AVG(i.score_num) AS avg_infection_score
FROM fact_infections i
WHERE i.score_num IS NOT NULL
  AND i.score_raw NOT IN ('Not Available', 'N/A')
  AND i.measure_id LIKE '%_SIR'
GROUP BY i.facility_id_clean;

-- Create vw_patient_experience_benchmark
CREATE OR ALTER VIEW vw_patient_experience_benchmark AS
SELECT
    h.facility_id_clean,
    AVG(CASE
            WHEN h.patient_survey_star_rating_num IS NOT NULL
            THEN h.patient_survey_star_rating_num
        END) AS avg_star_rating,
    AVG(CASE
            WHEN h.hcahps_answer_percent_num IS NOT NULL
            THEN h.hcahps_answer_percent_num
        END) AS avg_patient_satisfaction
FROM fact_hcahps h
GROUP BY h.facility_id_clean;

-- Rebuild vw_hospital_performance_summary
CREATE OR ALTER VIEW vw_hospital_performance_summary AS
SELECT
    m.facility_id_clean,
    m.facility_name,
    m.state,
    m.hospital_type,
    m.hospital_ownership,
    m.rural_flag,
    c.avg_spending_score,
    s.avg_infection_score,
    o.avg_outcome_score,
    r.avg_readmission_score,
    p.avg_star_rating,
    p.avg_patient_satisfaction
FROM vw_hospital_master m
LEFT JOIN vw_cost_benchmark c
    ON m.facility_id_clean = c.facility_id_clean
LEFT JOIN vw_safety_benchmark s
    ON m.facility_id_clean = s.facility_id_clean
LEFT JOIN vw_outcomes_benchmark o
    ON m.facility_id_clean = o.facility_id_clean
LEFT JOIN vw_readmission_benchmark r
    ON m.facility_id_clean = r.facility_id_clean
LEFT JOIN vw_patient_experience_benchmark p
    ON m.facility_id_clean = p.facility_id_clean;

-- Create the export-ready view
CREATE OR ALTER VIEW vw_hospital_performance_export AS
SELECT *,
    CASE
        WHEN avg_star_rating >= 4
             AND avg_infection_score < 1
             AND avg_spending_score < 1
        THEN 'Top Performer'
        WHEN avg_star_rating >= 3
        THEN 'Average Performer'
        ELSE 'Low Performer'
    END AS performance_tier
FROM vw_hospital_performance_summary;

-- Validate the refreshed output
SELECT TOP 30 *
FROM vw_hospital_performance_export;

SELECT
    MIN(avg_infection_score) AS min_infection_score,
    MAX(avg_infection_score) AS max_infection_score,
    AVG(avg_infection_score) AS avg_infection_score_overall
FROM vw_hospital_performance_summary;

SELECT
    COUNT(*) AS hospitals_total,
    COUNT(avg_patient_satisfaction) AS hospitals_with_patient_satisfaction,
    COUNT(avg_star_rating) AS hospitals_with_star_rating,
    COUNT(avg_infection_score) AS hospitals_with_infection_score
FROM vw_hospital_performance_summary;

-- Inspect HCAHPS answer descriptions
SELECT DISTINCT hcahps_answer_description
FROM fact_hcahps
ORDER BY hcahps_answer_description;

-- Replace vw_patient_experience_benchmark
CREATE OR ALTER VIEW vw_patient_experience_benchmark AS
SELECT
    h.facility_id_clean,
    AVG(CASE
            WHEN h.patient_survey_star_rating_num IS NOT NULL
            THEN h.patient_survey_star_rating_num
        END) AS avg_star_rating,
    AVG(CASE
            WHEN h.hcahps_answer_percent_num IS NOT NULL
             AND (
                    LOWER(h.hcahps_answer_description) LIKE '%"always"%'
                 OR LOWER(h.hcahps_answer_description) LIKE '"yes", patients would definitely recommend%'
                 OR LOWER(h.hcahps_answer_description) LIKE 'yes, staff "did"%'
                 OR LOWER(h.hcahps_answer_description) LIKE '%rating of "9" or "10" (high)%'
                 )
            THEN h.hcahps_answer_percent_num
        END) AS avg_top_box_percent
FROM fact_hcahps h
GROUP BY h.facility_id_clean;

-- Rebuild vw_hospital_performance_summary
CREATE OR ALTER VIEW vw_hospital_performance_summary AS
SELECT
    m.facility_id_clean,
    m.facility_name,
    m.state,
    m.hospital_type,
    m.hospital_ownership,
    m.rural_flag,
    c.avg_spending_score,
    s.avg_infection_score,
    o.avg_outcome_score,
    r.avg_readmission_score,
    p.avg_star_rating,
    p.avg_top_box_percent
FROM vw_hospital_master m
LEFT JOIN vw_cost_benchmark c
    ON m.facility_id_clean = c.facility_id_clean
LEFT JOIN vw_safety_benchmark s
    ON m.facility_id_clean = s.facility_id_clean
LEFT JOIN vw_outcomes_benchmark o
    ON m.facility_id_clean = o.facility_id_clean
LEFT JOIN vw_readmission_benchmark r
    ON m.facility_id_clean = r.facility_id_clean
LEFT JOIN vw_patient_experience_benchmark p
    ON m.facility_id_clean = p.facility_id_clean;

-- Rebuild vw_hospital_performance_export
CREATE OR ALTER VIEW vw_hospital_performance_export AS
SELECT *,
    CASE
        WHEN avg_star_rating >= 4
             AND avg_infection_score < 1
             AND avg_spending_score < 1
        THEN 'Top Performer'
        WHEN avg_star_rating >= 3
        THEN 'Average Performer'
        ELSE 'Low Performer'
    END AS performance_tier
FROM vw_hospital_performance_summary;

-- validate
SELECT TOP 30 *
FROM vw_hospital_performance_export;

SELECT
    MIN(avg_top_box_percent) AS min_top_box_percent,
    MAX(avg_top_box_percent) AS max_top_box_percent,
    AVG(avg_top_box_percent) AS avg_top_box_percent_overall
FROM vw_hospital_performance_summary;

SELECT
    COUNT(*) AS hospitals_total,
    COUNT(avg_top_box_percent) AS hospitals_with_top_box_percent,
    COUNT(avg_star_rating) AS hospitals_with_star_rating,
    COUNT(avg_infection_score) AS hospitals_with_infection_score
FROM vw_hospital_performance_summary;
