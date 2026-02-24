-- ============================================================
-- Healthcare Analytics: Post-Operative Recovery Platform
-- Author: Antonio Augusto
-- Description: Schema + synthetic data for patient monitoring
-- ============================================================

-- ─────────────────────────────────────────
-- TABLES
-- ─────────────────────────────────────────

CREATE TABLE IF NOT EXISTS patients (
    patient_id      INTEGER PRIMARY KEY,
    age             INTEGER,
    gender          TEXT CHECK(gender IN ('M','F')),
    surgery_type    TEXT,
    surgery_date    DATE,
    clinic_id       INTEGER
);

CREATE TABLE IF NOT EXISTS clinics (
    clinic_id   INTEGER PRIMARY KEY,
    clinic_name TEXT,
    region      TEXT
);

CREATE TABLE IF NOT EXISTS doctors (
    doctor_id       INTEGER PRIMARY KEY,
    doctor_name     TEXT,
    specialization  TEXT,
    clinic_id       INTEGER
);

CREATE TABLE IF NOT EXISTS daily_checkins (
    checkin_id      INTEGER PRIMARY KEY,
    patient_id      INTEGER REFERENCES patients(patient_id),
    checkin_date    DATE,
    day_post_op     INTEGER,
    pain_level      INTEGER CHECK(pain_level BETWEEN 0 AND 10),
    temperature     REAL,
    wound_redness   INTEGER CHECK(wound_redness IN (0,1)),
    swelling        INTEGER CHECK(swelling IN (0,1)),
    discharge       INTEGER CHECK(discharge IN (0,1)),
    recovery_score  REAL  -- composite 0–100
);

CREATE TABLE IF NOT EXISTS medications (
    med_id          INTEGER PRIMARY KEY,
    patient_id      INTEGER REFERENCES patients(patient_id),
    med_name        TEXT,
    scheduled_time  TEXT,
    taken           INTEGER CHECK(taken IN (0,1)),
    taken_date      DATE
);

CREATE TABLE IF NOT EXISTS alerts (
    alert_id        INTEGER PRIMARY KEY,
    patient_id      INTEGER REFERENCES patients(patient_id),
    alert_date      DATE,
    alert_type      TEXT CHECK(alert_type IN ('Pain','Fever','Wound','Medication','General')),
    severity        TEXT CHECK(severity IN ('Low','Medium','High','Critical')),
    resolved        INTEGER CHECK(resolved IN (0,1))
);

-- ─────────────────────────────────────────
-- SEED DATA
-- ─────────────────────────────────────────

INSERT INTO clinics VALUES
(1,'Clínica CentroSaúde','Luanda Norte'),
(2,'Hospital São Lucas','Luanda Sul'),
(3,'MedClinic Talatona','Talatona');

INSERT INTO doctors VALUES
(1,'Dr. Manuel Costa','Cirurgia Geral',1),
(2,'Dr. Ana Ferreira','Ortopedia',2),
(3,'Dr. João Mendes','Cardiologia',3);

INSERT INTO patients VALUES
(1, 45,'M','Knee Replacement','2024-10-01',1),
(2, 62,'F','Hip Replacement','2024-10-05',1),
(3, 38,'M','Appendectomy','2024-10-10',2),
(4, 55,'F','Cardiac Bypass','2024-10-12',3),
(5, 29,'M','Appendectomy','2024-10-15',2),
(6, 70,'F','Hip Replacement','2024-10-18',3),
(7, 48,'M','Knee Replacement','2024-10-20',1),
(8, 34,'F','Appendectomy','2024-10-22',2),
(9, 59,'M','Cardiac Bypass','2024-10-25',3),
(10,43,'F','Knee Replacement','2024-10-28',1);

-- Daily check-ins: 10 patients × 14 days = 140 rows (sample)
INSERT INTO daily_checkins VALUES
-- Patient 1 (Knee, improving well)
(1,1,'2024-10-02',1,7,37.8,1,1,0,35.0),
(2,1,'2024-10-05',4,5,37.2,1,0,0,52.0),
(3,1,'2024-10-09',8,3,36.9,0,0,0,68.0),
(4,1,'2024-10-15',14,2,36.7,0,0,0,80.0),
-- Patient 2 (Hip, slow recovery)
(5,2,'2024-10-06',1,8,38.1,1,1,1,25.0),
(6,2,'2024-10-09',4,7,38.0,1,1,0,32.0),
(7,2,'2024-10-13',8,6,37.5,1,0,0,45.0),
(8,2,'2024-10-19',14,5,37.2,0,0,0,58.0),
-- Patient 3 (Appendectomy, fast recovery)
(9,3,'2024-10-11',1,5,37.5,0,1,0,48.0),
(10,3,'2024-10-14',4,3,36.9,0,0,0,70.0),
(11,3,'2024-10-18',8,1,36.6,0,0,0,88.0),
(12,3,'2024-10-24',14,0,36.5,0,0,0,96.0),
-- Patient 4 (Cardiac, critical start)
(13,4,'2024-10-13',1,9,38.5,1,1,1,18.0),
(14,4,'2024-10-16',4,7,38.2,1,1,0,30.0),
(15,4,'2024-10-20',8,5,37.8,1,0,0,50.0),
(16,4,'2024-10-26',14,4,37.3,0,0,0,65.0),
-- Patient 5 (Appendectomy, very fast)
(17,5,'2024-10-16',1,4,37.1,0,0,0,55.0),
(18,5,'2024-10-19',4,2,36.8,0,0,0,78.0),
(19,5,'2024-10-23',8,1,36.5,0,0,0,92.0),
(20,5,'2024-10-29',14,0,36.5,0,0,0,99.0),
-- Patients 6–10 (various)
(21,6,'2024-10-19',1,8,38.3,1,1,1,20.0),
(22,6,'2024-10-25',7,6,37.6,1,0,0,44.0),
(23,6,'2024-11-01',14,4,37.1,0,0,0,62.0),
(24,7,'2024-10-21',1,6,37.6,1,1,0,40.0),
(25,7,'2024-10-27',7,4,37.0,0,0,0,65.0),
(26,7,'2024-11-03',14,2,36.7,0,0,0,82.0),
(27,8,'2024-10-23',1,4,37.0,0,1,0,52.0),
(28,8,'2024-10-29',7,2,36.7,0,0,0,76.0),
(29,8,'2024-11-05',14,0,36.5,0,0,0,97.0),
(30,9,'2024-10-26',1,9,38.6,1,1,1,15.0),
(31,9,'2024-11-01',7,6,38.0,1,0,0,42.0),
(32,9,'2024-11-08',14,4,37.2,0,0,0,64.0),
(33,10,'2024-10-29',1,5,37.3,1,0,0,50.0),
(34,10,'2024-11-04',7,3,36.9,0,0,0,72.0),
(35,10,'2024-11-11',14,2,36.7,0,0,0,85.0);

INSERT INTO medications VALUES
(1,1,'Ibuprofeno 400mg','08:00',1,'2024-10-09'),
(2,1,'Paracetamol 500mg','20:00',1,'2024-10-09'),
(3,2,'Morfina 10mg','08:00',1,'2024-10-13'),
(4,2,'Ibuprofeno 400mg','14:00',0,'2024-10-13'),
(5,3,'Paracetamol 500mg','08:00',1,'2024-10-18'),
(6,4,'Aspirina 100mg','08:00',1,'2024-10-20'),
(7,4,'Metoprolol 50mg','20:00',1,'2024-10-20'),
(8,5,'Ibuprofeno 400mg','12:00',1,'2024-10-23'),
(9,6,'Morfina 10mg','08:00',0,'2024-10-25'),
(10,7,'Ibuprofeno 400mg','08:00',1,'2024-10-27'),
(11,9,'Aspirina 100mg','08:00',1,'2024-11-01'),
(12,9,'Atorvastatina 20mg','20:00',0,'2024-11-01');

INSERT INTO alerts VALUES
(1,2,'2024-10-07','Fever','High',1),
(2,2,'2024-10-08','Wound','Medium',1),
(3,4,'2024-10-14','Fever','Critical',0),
(4,4,'2024-10-14','Pain','High',0),
(5,6,'2024-10-20','Wound','High',1),
(6,9,'2024-10-27','Fever','Critical',0),
(7,9,'2024-10-28','Medication','Medium',0),
(8,1,'2024-10-03','Pain','Low',1),
(9,3,'2024-10-11','Wound','Low',1),
(10,7,'2024-10-21','Pain','Medium',1);
