-- central table for Power BI

CREATE VIEW vw_hospital_master AS
SELECT
    h.facility_id_clean,
    h.facility_name,
    h.state,
    h.hospital_type,
    h.hospital_ownership,
    h.emergency_services,
    h.rural_flag,
    h.hospital_overall_rating
FROM dim_hospital h;

-- COST BENCHMARK
CREATE VIEW vw_cost_benchmark AS
SELECT
    s.facility_id_clean,
    AVG(s.score_num) AS avg_spending_score
FROM fact_spending s
WHERE s.score_num IS NOT NULL
GROUP BY s.facility_id_clean;

-- SAFETY BENCHMARK
CREATE VIEW vw_safety_benchmark AS
SELECT
    i.facility_id_clean,
    AVG(i.score_num) AS avg_infection_score
FROM fact_infections i
WHERE i.score_num IS NOT NULL
GROUP BY i.facility_id_clean;

-- OUTCOMES BENCHMARK
CREATE VIEW vw_outcomes_benchmark AS
SELECT
    c.facility_id_clean,
    AVG(c.score_num) AS avg_outcome_score
FROM fact_complications c
WHERE c.score_num IS NOT NULL
GROUP BY c.facility_id_clean;

-- READMISSION / UTILIZATION
CREATE VIEW vw_readmission_benchmark AS
SELECT
    r.facility_id_clean,
    AVG(r.score_num) AS avg_readmission_score
FROM fact_readmissions r
WHERE r.score_num IS NOT NULL
GROUP BY r.facility_id_clean;

-- PATIENT EXPERIENCE
CREATE VIEW vw_patient_experience_benchmark AS
SELECT
    h.facility_id_clean,
    AVG(h.patient_survey_star_rating_num) AS avg_star_rating,
    AVG(h.hcahps_answer_percent_num) AS avg_patient_satisfaction
FROM fact_hcahps h
WHERE h.patient_survey_star_rating_num IS NOT NULL
GROUP BY h.facility_id_clean;

-- vw_hospital_performance_summary
CREATE VIEW vw_hospital_performance_summary AS
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

--PERFORMANCE TIERS
SELECT *,
CASE 
    WHEN avg_star_rating >= 4 
         AND avg_infection_score < 1 
         AND avg_spending_score < 1 THEN 'Top Performer'

    WHEN avg_star_rating >= 3 THEN 'Average Performer'

    ELSE 'Low Performer'
END AS performance_tier

FROM vw_hospital_performance_summary;

-- sample output
SELECT TOP 20 * FROM vw_hospital_performance_summary;