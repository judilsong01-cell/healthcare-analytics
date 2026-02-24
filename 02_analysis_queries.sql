-- ============================================================
-- Healthcare Analytics: Advanced SQL Analysis
-- Author: Antonio Augusto
-- Description: 12 analytical queries for portfolio showcase
-- ============================================================

-- ─────────────────────────────────────────
-- QUERY 1: Recovery Progress by Surgery Type
-- Compares average recovery score at day 1 vs day 14
-- ─────────────────────────────────────────
SELECT
    p.surgery_type,
    ROUND(AVG(CASE WHEN c.day_post_op = 1  THEN c.recovery_score END), 1) AS avg_score_day1,
    ROUND(AVG(CASE WHEN c.day_post_op = 14 THEN c.recovery_score END), 1) AS avg_score_day14,
    ROUND(
        AVG(CASE WHEN c.day_post_op = 14 THEN c.recovery_score END) -
        AVG(CASE WHEN c.day_post_op = 1  THEN c.recovery_score END),
    1) AS improvement
FROM daily_checkins c
JOIN patients p ON c.patient_id = p.patient_id
GROUP BY p.surgery_type
ORDER BY improvement DESC;


-- ─────────────────────────────────────────
-- QUERY 2: Medication Adherence Rate per Patient
-- ─────────────────────────────────────────
SELECT
    p.patient_id,
    p.surgery_type,
    COUNT(m.med_id)                                         AS total_scheduled,
    SUM(m.taken)                                            AS total_taken,
    ROUND(100.0 * SUM(m.taken) / COUNT(m.med_id), 1)       AS adherence_pct
FROM patients p
LEFT JOIN medications m ON p.patient_id = m.patient_id
GROUP BY p.patient_id, p.surgery_type
HAVING total_scheduled > 0
ORDER BY adherence_pct ASC;


-- ─────────────────────────────────────────
-- QUERY 3: Alert Severity Distribution by Clinic
-- ─────────────────────────────────────────
SELECT
    cl.clinic_name,
    a.severity,
    COUNT(a.alert_id)                                       AS total_alerts,
    SUM(CASE WHEN a.resolved = 1 THEN 1 ELSE 0 END)        AS resolved,
    ROUND(100.0 * SUM(a.resolved) / COUNT(a.alert_id), 1)  AS resolution_rate_pct
FROM alerts a
JOIN patients p  ON a.patient_id = p.patient_id
JOIN clinics cl  ON p.clinic_id  = cl.clinic_id
GROUP BY cl.clinic_name, a.severity
ORDER BY cl.clinic_name, 
    CASE a.severity 
        WHEN 'Critical' THEN 1
        WHEN 'High'     THEN 2
        WHEN 'Medium'   THEN 3
        ELSE 4
    END;


-- ─────────────────────────────────────────
-- QUERY 4: Fever Trend — Avg Temperature by Day Post-Op
-- ─────────────────────────────────────────
SELECT
    day_post_op,
    ROUND(AVG(temperature), 2)  AS avg_temp,
    ROUND(MIN(temperature), 2)  AS min_temp,
    ROUND(MAX(temperature), 2)  AS max_temp,
    COUNT(*)                    AS patient_count
FROM daily_checkins
GROUP BY day_post_op
ORDER BY day_post_op;


-- ─────────────────────────────────────────
-- QUERY 5: Patients With Critical Unresolved Alerts
-- High-priority monitoring list for doctors
-- ─────────────────────────────────────────
SELECT
    p.patient_id,
    p.surgery_type,
    p.surgery_date,
    cl.clinic_name,
    COUNT(a.alert_id)           AS unresolved_critical_alerts,
    MAX(a.alert_date)           AS latest_alert_date
FROM patients p
JOIN alerts  a  ON p.patient_id = a.patient_id
JOIN clinics cl ON p.clinic_id  = cl.clinic_id
WHERE a.resolved = 0
  AND a.severity IN ('Critical','High')
GROUP BY p.patient_id, p.surgery_type, p.surgery_date, cl.clinic_name
ORDER BY unresolved_critical_alerts DESC, latest_alert_date DESC;


-- ─────────────────────────────────────────
-- QUERY 6: Recovery Score Percentile Ranking
-- Window function to rank patients within surgery type
-- ─────────────────────────────────────────
SELECT
    p.patient_id,
    p.surgery_type,
    p.age,
    c.day_post_op,
    c.recovery_score,
    ROUND(
        100.0 * RANK() OVER (
            PARTITION BY p.surgery_type, c.day_post_op
            ORDER BY c.recovery_score
        ) / COUNT(*) OVER (
            PARTITION BY p.surgery_type, c.day_post_op
        ),
    1) AS percentile_rank
FROM daily_checkins c
JOIN patients p ON c.patient_id = p.patient_id
WHERE c.day_post_op IN (1, 7, 14)
ORDER BY p.surgery_type, c.day_post_op, c.recovery_score DESC;


-- ─────────────────────────────────────────
-- QUERY 7: 7-Day Rolling Average Pain Level per Patient
-- Detects persistent pain trends
-- ─────────────────────────────────────────
SELECT
    patient_id,
    checkin_date,
    day_post_op,
    pain_level,
    ROUND(
        AVG(pain_level) OVER (
            PARTITION BY patient_id
            ORDER BY day_post_op
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
    2) AS rolling_3pt_avg_pain
FROM daily_checkins
ORDER BY patient_id, day_post_op;


-- ─────────────────────────────────────────
-- QUERY 8: Symptom Co-occurrence Analysis
-- How often do symptoms appear together?
-- ─────────────────────────────────────────
SELECT
    CASE 
        WHEN wound_redness = 1 AND swelling = 1 AND discharge = 1 THEN 'All 3 symptoms'
        WHEN wound_redness = 1 AND swelling = 1                   THEN 'Redness + Swelling'
        WHEN wound_redness = 1 AND discharge = 1                  THEN 'Redness + Discharge'
        WHEN swelling = 1       AND discharge = 1                 THEN 'Swelling + Discharge'
        WHEN wound_redness = 1                                    THEN 'Redness only'
        WHEN swelling = 1                                         THEN 'Swelling only'
        WHEN discharge = 1                                        THEN 'Discharge only'
        ELSE 'No symptoms'
    END AS symptom_pattern,
    COUNT(*)                                            AS occurrences,
    ROUND(AVG(pain_level), 1)                          AS avg_pain,
    ROUND(AVG(temperature), 2)                         AS avg_temp,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 1) AS pct_of_checkins
FROM daily_checkins
GROUP BY symptom_pattern
ORDER BY occurrences DESC;


-- ─────────────────────────────────────────
-- QUERY 9: Clinic Performance Scorecard
-- KPI summary per clinic
-- ─────────────────────────────────────────
SELECT
    cl.clinic_name,
    cl.region,
    COUNT(DISTINCT p.patient_id)                                   AS total_patients,
    ROUND(AVG(c.recovery_score), 1)                               AS avg_recovery_score,
    ROUND(AVG(c.pain_level), 1)                                   AS avg_pain_level,
    ROUND(AVG(c.temperature), 2)                                  AS avg_temperature,
    COUNT(a.alert_id)                                              AS total_alerts,
    ROUND(100.0 * SUM(a.resolved) / NULLIF(COUNT(a.alert_id),0),1) AS alert_resolution_pct
FROM clinics cl
JOIN patients      p  ON cl.clinic_id   = p.clinic_id
JOIN daily_checkins c ON p.patient_id   = c.patient_id
LEFT JOIN alerts   a  ON p.patient_id   = a.patient_id
GROUP BY cl.clinic_name, cl.region
ORDER BY avg_recovery_score DESC;


-- ─────────────────────────────────────────
-- QUERY 10: Age Group Recovery Analysis
-- ─────────────────────────────────────────
SELECT
    CASE
        WHEN p.age < 35         THEN '18–34'
        WHEN p.age BETWEEN 35 AND 49 THEN '35–49'
        WHEN p.age BETWEEN 50 AND 64 THEN '50–64'
        ELSE '65+'
    END AS age_group,
    COUNT(DISTINCT p.patient_id)                            AS patients,
    ROUND(AVG(c.recovery_score), 1)                        AS avg_recovery_score,
    ROUND(AVG(c.pain_level), 1)                            AS avg_pain,
    ROUND(AVG(c.temperature), 2)                           AS avg_temp
FROM patients p
JOIN daily_checkins c ON p.patient_id = c.patient_id
GROUP BY age_group
ORDER BY age_group;


-- ─────────────────────────────────────────
-- QUERY 11: Recovery Velocity (Score gain per day)
-- Identifies fast vs slow recoverers
-- ─────────────────────────────────────────
WITH day1 AS (
    SELECT patient_id, recovery_score AS score_day1
    FROM daily_checkins WHERE day_post_op = 1
),
day14 AS (
    SELECT patient_id, recovery_score AS score_day14
    FROM daily_checkins WHERE day_post_op = 14
)
SELECT
    p.patient_id,
    p.surgery_type,
    p.age,
    p.gender,
    d1.score_day1,
    d14.score_day14,
    ROUND((d14.score_day14 - d1.score_day1) / 13.0, 2) AS daily_improvement_rate,
    CASE
        WHEN (d14.score_day14 - d1.score_day1) / 13.0 >= 4 THEN 'Fast Recoverer'
        WHEN (d14.score_day14 - d1.score_day1) / 13.0 >= 2 THEN 'Normal Recovery'
        ELSE 'Slow Recoverer'
    END AS recovery_category
FROM patients p
JOIN day1  d1  ON p.patient_id = d1.patient_id
JOIN day14 d14 ON p.patient_id = d14.patient_id
ORDER BY daily_improvement_rate DESC;


-- ─────────────────────────────────────────
-- QUERY 12: Full Patient Summary View (Dashboard-ready)
-- One row per patient with all key KPIs
-- ─────────────────────────────────────────
CREATE VIEW IF NOT EXISTS vw_patient_summary AS
SELECT
    p.patient_id,
    p.surgery_type,
    p.surgery_date,
    p.age,
    p.gender,
    cl.clinic_name,
    ROUND(AVG(c.recovery_score), 1)                              AS avg_recovery_score,
    MAX(c.recovery_score)                                         AS peak_recovery_score,
    ROUND(AVG(c.pain_level), 1)                                  AS avg_pain,
    ROUND(AVG(c.temperature), 2)                                  AS avg_temp,
    SUM(c.wound_redness)                                          AS redness_days,
    COUNT(DISTINCT a.alert_id)                                    AS total_alerts,
    SUM(CASE WHEN a.severity = 'Critical' THEN 1 ELSE 0 END)     AS critical_alerts,
    ROUND(
        100.0 * SUM(m.taken) / NULLIF(COUNT(m.med_id), 0),
    1)                                                            AS medication_adherence_pct
FROM patients p
JOIN clinics       cl ON p.clinic_id   = cl.clinic_id
JOIN daily_checkins c ON p.patient_id  = c.patient_id
LEFT JOIN alerts   a  ON p.patient_id  = a.patient_id
LEFT JOIN medications m ON p.patient_id = m.patient_id
GROUP BY p.patient_id, p.surgery_type, p.surgery_date,
         p.age, p.gender, cl.clinic_name;

SELECT * FROM vw_patient_summary ORDER BY avg_recovery_score DESC;
