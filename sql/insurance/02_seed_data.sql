-- =============================================================================
-- Rental Insurance FNOL Demo — Seed Data
-- =============================================================================
-- Populates reference tables with demo data:
--   • 8 policyholders (Marcus Johnson is the primary demo persona)
--   • 10 vehicle classes
--   • 11 rental agreements (4 belong to Marcus Johnson)
--   • 14 rental items
--   • 7 claims (5 are collision claims for AI_SIMILARITY matching)
--
-- Prerequisites:
--   • 01_setup.sql has been executed.
--
-- Usage:
--   snow sql -f sql/insurance/02_seed_data.sql
-- =============================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE RENTAL_INSURANCE;
USE SCHEMA PUBLIC;

-- -----------------------------------------------------------------------------
-- 1. Policyholders
-- -----------------------------------------------------------------------------
INSERT INTO POLICYHOLDERS (NAME, EMAIL, PHONE, POLICY_TIER, POLICY_NUMBER, ADDRESS, DRIVERS_LICENSE) VALUES
    ('Marcus Johnson',   'marcus.johnson@gmail.com',   '5551001001', 'PREMIUM',  'POL-2026-1001', '742 Evergreen Terrace, Portland, OR 97201',  'DL-OR-88421'),
    ('Angela Torres',    'angela.torres@yahoo.com',    '5551002002', 'STANDARD', 'POL-2026-1002', '310 Oak Street, Seattle, WA 98101',          'DL-WA-55213'),
    ('David Park',       'david.park@outlook.com',     '5551003003', 'PREMIUM',  'POL-2026-1003', '88 Pine Avenue, Denver, CO 80202',           'DL-CO-77654'),
    ('Rachel Green',     'rachel.green@gmail.com',     '5551004004', 'BASIC',    'POL-2026-1004', '425 Elm Drive, Austin, TX 78701',            'DL-TX-33190'),
    ('James Mitchell',   'james.mitchell@hotmail.com', '5551005005', 'STANDARD', 'POL-2026-1005', '150 Maple Lane, San Francisco, CA 94102',    'DL-CA-91022'),
    ('Sofia Ramirez',    'sofia.ramirez@gmail.com',    '5551006006', 'PREMIUM',  'POL-2026-1006', '67 Birch Boulevard, Chicago, IL 60601',      'DL-IL-42876'),
    ('Kevin O''Brien',   'kevin.obrien@gmail.com',     '5551007007', 'STANDARD', 'POL-2026-1007', '203 Cedar Road, Bozeman, MT 59715',          'DL-MT-18543'),
    ('Nina Patel',       'nina.patel@yahoo.com',       '5551008008', 'BASIC',    'POL-2026-1008', '511 Walnut Street, Phoenix, AZ 85001',       'DL-AZ-66390');

-- -----------------------------------------------------------------------------
-- 2. Vehicle Classes
-- -----------------------------------------------------------------------------
INSERT INTO VEHICLES (CLASS_NAME, CATEGORY, DAILY_RATE, VEHICLE_CODE) VALUES
    ('Economy Sedan',            'Sedan',   39.99, 'ECON-SDN'),
    ('Standard Sedan',           'Sedan',   54.99, 'STD-SDN'),
    ('Full-Size Sedan',          'Sedan',   69.99, 'FS-SDN'),
    ('Compact SUV',              'SUV',     64.99, 'CMP-SUV'),
    ('Standard SUV',             'SUV',     84.99, 'STD-SUV'),
    ('Premium SUV',              'SUV',    109.99, 'PRM-SUV'),
    ('Luxury SUV',               'Luxury', 149.99, 'LUX-SUV'),
    ('Luxury Sedan',             'Luxury', 129.99, 'LUX-SDN'),
    ('Full-Size Pickup Truck',   'Truck',   79.99, 'FS-TRK'),
    ('Minivan',                  'Van',     74.99, 'MINIVAN');

-- -----------------------------------------------------------------------------
-- 3. Rental Agreements
-- -----------------------------------------------------------------------------
-- Other policyholders' agreements (one each)
INSERT INTO RENTAL_AGREEMENTS (POLICYHOLDER_ID, AGREEMENT_NUMBER, PICKUP_DATE, RETURN_DATE, STATUS, TOTAL, LOCATION) VALUES
    (2, 'AGR-2026-201', '2026-03-10', '2026-03-17', 'RETURNED',  384.93, 'Seattle Airport'),
    (3, 'AGR-2026-202', '2026-03-12', '2026-03-19', 'RETURNED',  594.93, 'Denver Downtown'),
    (4, 'AGR-2026-203', '2026-03-08', '2026-03-15', 'RETURNED',  279.93, 'Austin Airport'),
    (5, 'AGR-2026-204', '2026-03-15', '2026-03-22', 'ACTIVE',    454.93, 'San Francisco Airport'),
    (6, 'AGR-2026-205', '2026-03-17', '2026-03-24', 'ACTIVE',    769.93, 'Chicago O''Hare'),
    (7, 'AGR-2026-206', '2026-03-01', '2026-03-08', 'RETURNED',  384.93, 'Bozeman Airport'),
    (8, 'AGR-2026-207', '2026-03-03', '2026-03-10', 'RETURNED',  279.93, 'Phoenix Sky Harbor');

-- Marcus Johnson's 4 agreements
INSERT INTO RENTAL_AGREEMENTS (POLICYHOLDER_ID, AGREEMENT_NUMBER, PICKUP_DATE, RETURN_DATE, STATUS, TOTAL, LOCATION) VALUES
    (1, 'AGR-2026-101', '2026-03-05', '2026-03-20', 'ACTIVE',   1274.85, 'Portland Airport'),
    (1, 'AGR-2026-102', '2026-02-15', '2026-02-22', 'RETURNED',  594.93, 'Portland Downtown'),
    (1, 'AGR-2026-103', '2026-01-20', '2026-01-27', 'RETURNED',  384.93, 'Portland Airport'),
    (1, 'AGR-2026-104', '2026-04-01', '2026-04-08', 'RESERVED', 1049.93, 'Portland Airport');

-- -----------------------------------------------------------------------------
-- 4. Rental Items
-- -----------------------------------------------------------------------------
-- Other policyholders — each rented one vehicle
INSERT INTO RENTAL_ITEMS (AGREEMENT_ID, VEHICLE_ID, QUANTITY, DAILY_RATE)
SELECT a.AGREEMENT_ID, v.VEHICLE_ID, 1, v.DAILY_RATE
FROM RENTAL_AGREEMENTS a JOIN VEHICLES v ON TRUE
WHERE a.AGREEMENT_NUMBER = 'AGR-2026-201' AND v.VEHICLE_CODE = 'STD-SDN';

INSERT INTO RENTAL_ITEMS (AGREEMENT_ID, VEHICLE_ID, QUANTITY, DAILY_RATE)
SELECT a.AGREEMENT_ID, v.VEHICLE_ID, 1, v.DAILY_RATE
FROM RENTAL_AGREEMENTS a JOIN VEHICLES v ON TRUE
WHERE a.AGREEMENT_NUMBER = 'AGR-2026-202' AND v.VEHICLE_CODE = 'STD-SUV';

INSERT INTO RENTAL_ITEMS (AGREEMENT_ID, VEHICLE_ID, QUANTITY, DAILY_RATE)
SELECT a.AGREEMENT_ID, v.VEHICLE_ID, 1, v.DAILY_RATE
FROM RENTAL_AGREEMENTS a JOIN VEHICLES v ON TRUE
WHERE a.AGREEMENT_NUMBER = 'AGR-2026-203' AND v.VEHICLE_CODE = 'ECON-SDN';

INSERT INTO RENTAL_ITEMS (AGREEMENT_ID, VEHICLE_ID, QUANTITY, DAILY_RATE)
SELECT a.AGREEMENT_ID, v.VEHICLE_ID, 1, v.DAILY_RATE
FROM RENTAL_AGREEMENTS a JOIN VEHICLES v ON TRUE
WHERE a.AGREEMENT_NUMBER = 'AGR-2026-204' AND v.VEHICLE_CODE = 'CMP-SUV';

INSERT INTO RENTAL_ITEMS (AGREEMENT_ID, VEHICLE_ID, QUANTITY, DAILY_RATE)
SELECT a.AGREEMENT_ID, v.VEHICLE_ID, 1, v.DAILY_RATE
FROM RENTAL_AGREEMENTS a JOIN VEHICLES v ON TRUE
WHERE a.AGREEMENT_NUMBER = 'AGR-2026-205' AND v.VEHICLE_CODE = 'LUX-SUV';

INSERT INTO RENTAL_ITEMS (AGREEMENT_ID, VEHICLE_ID, QUANTITY, DAILY_RATE)
SELECT a.AGREEMENT_ID, v.VEHICLE_ID, 1, v.DAILY_RATE
FROM RENTAL_AGREEMENTS a JOIN VEHICLES v ON TRUE
WHERE a.AGREEMENT_NUMBER = 'AGR-2026-206' AND v.VEHICLE_CODE = 'STD-SDN';

INSERT INTO RENTAL_ITEMS (AGREEMENT_ID, VEHICLE_ID, QUANTITY, DAILY_RATE)
SELECT a.AGREEMENT_ID, v.VEHICLE_ID, 1, v.DAILY_RATE
FROM RENTAL_AGREEMENTS a JOIN VEHICLES v ON TRUE
WHERE a.AGREEMENT_NUMBER = 'AGR-2026-207' AND v.VEHICLE_CODE = 'ECON-SDN';

-- Marcus Johnson — AGR-2026-101: Standard SUV (current active rental)
INSERT INTO RENTAL_ITEMS (AGREEMENT_ID, VEHICLE_ID, QUANTITY, DAILY_RATE)
SELECT a.AGREEMENT_ID, v.VEHICLE_ID, 1, 84.99
FROM RENTAL_AGREEMENTS a JOIN VEHICLES v ON TRUE
WHERE a.AGREEMENT_NUMBER = 'AGR-2026-101' AND v.VEHICLE_CODE = 'STD-SUV';

-- Marcus Johnson — AGR-2026-102: Full-Size Sedan
INSERT INTO RENTAL_ITEMS (AGREEMENT_ID, VEHICLE_ID, QUANTITY, DAILY_RATE)
SELECT a.AGREEMENT_ID, v.VEHICLE_ID, 1, 69.99
FROM RENTAL_AGREEMENTS a JOIN VEHICLES v ON TRUE
WHERE a.AGREEMENT_NUMBER = 'AGR-2026-102' AND v.VEHICLE_CODE = 'FS-SDN';

-- Marcus Johnson — AGR-2026-103: Standard Sedan
INSERT INTO RENTAL_ITEMS (AGREEMENT_ID, VEHICLE_ID, QUANTITY, DAILY_RATE)
SELECT a.AGREEMENT_ID, v.VEHICLE_ID, 1, 54.99
FROM RENTAL_AGREEMENTS a JOIN VEHICLES v ON TRUE
WHERE a.AGREEMENT_NUMBER = 'AGR-2026-103' AND v.VEHICLE_CODE = 'STD-SDN';

-- Marcus Johnson — AGR-2026-104: Luxury SUV + Premium SUV (future reservation)
INSERT INTO RENTAL_ITEMS (AGREEMENT_ID, VEHICLE_ID, QUANTITY, DAILY_RATE)
SELECT a.AGREEMENT_ID, v.VEHICLE_ID, 1, 149.99
FROM RENTAL_AGREEMENTS a JOIN VEHICLES v ON TRUE
WHERE a.AGREEMENT_NUMBER = 'AGR-2026-104' AND v.VEHICLE_CODE = 'LUX-SUV';

INSERT INTO RENTAL_ITEMS (AGREEMENT_ID, VEHICLE_ID, QUANTITY, DAILY_RATE)
SELECT a.AGREEMENT_ID, v.VEHICLE_ID, 1, 109.99
FROM RENTAL_AGREEMENTS a JOIN VEHICLES v ON TRUE
WHERE a.AGREEMENT_NUMBER = 'AGR-2026-104' AND v.VEHICLE_CODE = 'PRM-SUV';

-- Marcus Johnson extra: GPS add-on line on AGR-2026-101
INSERT INTO RENTAL_ITEMS (AGREEMENT_ID, VEHICLE_ID, QUANTITY, DAILY_RATE)
SELECT a.AGREEMENT_ID, v.VEHICLE_ID, 1, 84.99
FROM RENTAL_AGREEMENTS a JOIN VEHICLES v ON TRUE
WHERE a.AGREEMENT_NUMBER = 'AGR-2026-101' AND v.VEHICLE_CODE = 'STD-SUV';

-- -----------------------------------------------------------------------------
-- 5. Claims (5 collision claims for AI_SIMILARITY matching)
-- -----------------------------------------------------------------------------
INSERT INTO CLAIMS (CLAIM_NUMBER, POLICYHOLDER_ID, POLICYHOLDER_NAME, VEHICLE_ID, VEHICLE_NAME,
                    CLAIM_TYPE, STATUS, PRIORITY, LOSS_DESCRIPTION, CLAIM_RESOLUTION, INCIDENT_DATE)
SELECT 'CLM-2026-002', p.POLICYHOLDER_ID, p.NAME, v.VEHICLE_ID,
       'Standard SUV (STD-SUV)',
       'COLLISION', 'CLOSED', 'HIGH',
       'Rear-ended at a stop light. Damage to rear bumper and trunk. Other driver cited for following too closely. Vehicle not drivable.',
       'Replacement vehicle provided within 24 hours. Upgraded to Premium SUV per PREMIUM tier. Subrogation filed against at-fault driver.',
       '2026-03-14'
FROM POLICYHOLDERS p, VEHICLES v
WHERE p.NAME = 'David Park' AND v.VEHICLE_CODE = 'STD-SUV';

INSERT INTO CLAIMS (CLAIM_NUMBER, POLICYHOLDER_ID, POLICYHOLDER_NAME, VEHICLE_ID, VEHICLE_NAME,
                    CLAIM_TYPE, STATUS, PRIORITY, LOSS_DESCRIPTION, CLAIM_RESOLUTION, INCIDENT_DATE)
SELECT 'CLM-2026-003', p.POLICYHOLDER_ID, p.NAME, v.VEHICLE_ID,
       'Standard Sedan (STD-SDN)',
       'COLLISION', 'OPEN', 'HIGH',
       'T-boned at intersection. Other driver ran red light. Significant driver side door damage. Minor injuries reported. Police report filed.',
       NULL,
       '2026-03-18'
FROM POLICYHOLDERS p, VEHICLES v
WHERE p.NAME = 'Angela Torres' AND v.VEHICLE_CODE = 'STD-SDN';

INSERT INTO CLAIMS (CLAIM_NUMBER, POLICYHOLDER_ID, POLICYHOLDER_NAME, VEHICLE_ID, VEHICLE_NAME,
                    CLAIM_TYPE, STATUS, PRIORITY, LOSS_DESCRIPTION, CLAIM_RESOLUTION, INCIDENT_DATE)
SELECT 'CLM-2026-004', p.POLICYHOLDER_ID, p.NAME, v.VEHICLE_ID,
       'Compact SUV (CMP-SUV)',
       'COLLISION', 'OPEN', 'CRITICAL',
       'Rear-ended on highway during sudden stop. Extensive rear damage including bumper, trunk, and tail lights. Vehicle totaled. Neck and back pain reported. Other driver uninsured.',
       NULL,
       '2026-03-21'
FROM POLICYHOLDERS p, VEHICLES v
WHERE p.NAME = 'James Mitchell' AND v.VEHICLE_CODE = 'CMP-SUV';

INSERT INTO CLAIMS (CLAIM_NUMBER, POLICYHOLDER_ID, POLICYHOLDER_NAME, VEHICLE_ID, VEHICLE_NAME,
                    CLAIM_TYPE, STATUS, PRIORITY, LOSS_DESCRIPTION, CLAIM_RESOLUTION, INCIDENT_DATE)
SELECT 'CLM-2026-005', p.POLICYHOLDER_ID, p.NAME, v.VEHICLE_ID,
       'Economy Sedan (ECON-SDN)',
       'COLLISION', 'OPEN', 'HIGH',
       'Rear-ended while stopped at intersection. Rear bumper cracked, trunk misaligned, one tail light broken. Other driver admitted fault. No injuries but shaken up.',
       NULL,
       '2026-03-19'
FROM POLICYHOLDERS p, VEHICLES v
WHERE p.NAME = 'Kevin O''Brien' AND v.VEHICLE_CODE = 'ECON-SDN';

INSERT INTO CLAIMS (CLAIM_NUMBER, POLICYHOLDER_ID, POLICYHOLDER_NAME, VEHICLE_ID, VEHICLE_NAME,
                    CLAIM_TYPE, STATUS, PRIORITY, LOSS_DESCRIPTION, CLAIM_RESOLUTION, INCIDENT_DATE)
SELECT 'CLM-2026-006', p.POLICYHOLDER_ID, p.NAME, v.VEHICLE_ID,
       'Full-Size Sedan (FS-SDN)',
       'WEATHER', 'OPEN', 'MEDIUM',
       'Hail damage during severe thunderstorm. Multiple dents on hood and roof. Windshield cracked. Vehicle parked in open lot at hotel.',
       NULL,
       '2026-03-17'
FROM POLICYHOLDERS p, VEHICLES v
WHERE p.NAME = 'Rachel Green' AND v.VEHICLE_CODE = 'FS-SDN';

INSERT INTO CLAIMS (CLAIM_NUMBER, POLICYHOLDER_ID, POLICYHOLDER_NAME, VEHICLE_ID, VEHICLE_NAME,
                    CLAIM_TYPE, STATUS, PRIORITY, LOSS_DESCRIPTION, CLAIM_RESOLUTION, INCIDENT_DATE)
SELECT 'CLM-2026-007', p.POLICYHOLDER_ID, p.NAME, v.VEHICLE_ID,
       'Luxury SUV (LUX-SUV)',
       'COLLISION', 'OPEN', 'HIGH',
       'Side-swiped in parking garage. Deep scratches and dent on passenger side. Mirror broken. Other vehicle left scene. Security camera footage obtained.',
       NULL,
       '2026-03-20'
FROM POLICYHOLDERS p, VEHICLES v
WHERE p.NAME = 'Sofia Ramirez' AND v.VEHICLE_CODE = 'LUX-SUV';

INSERT INTO CLAIMS (CLAIM_NUMBER, POLICYHOLDER_ID, POLICYHOLDER_NAME, VEHICLE_ID, VEHICLE_NAME,
                    CLAIM_TYPE, STATUS, PRIORITY, LOSS_DESCRIPTION, CLAIM_RESOLUTION, INCIDENT_DATE)
SELECT 'CLM-2026-008', p.POLICYHOLDER_ID, p.NAME, v.VEHICLE_ID,
       'Economy Sedan (ECON-SDN)',
       'THEFT', 'CLOSED', 'LOW',
       'Personal items stolen from unlocked vehicle in hotel parking lot. No vehicle damage. Filed police report.',
       'Personal belongings claim processed. Reminded customer about vehicle security. No vehicle repair needed.',
       '2026-03-19'
FROM POLICYHOLDERS p, VEHICLES v
WHERE p.NAME = 'Nina Patel' AND v.VEHICLE_CODE = 'ECON-SDN';

-- -----------------------------------------------------------------------------
-- 6. Verification
-- -----------------------------------------------------------------------------
SELECT 'POLICYHOLDERS'      AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM POLICYHOLDERS
UNION ALL SELECT 'VEHICLES',          COUNT(*) FROM VEHICLES
UNION ALL SELECT 'RENTAL_AGREEMENTS', COUNT(*) FROM RENTAL_AGREEMENTS
UNION ALL SELECT 'RENTAL_ITEMS',      COUNT(*) FROM RENTAL_ITEMS
UNION ALL SELECT 'CLAIMS',            COUNT(*) FROM CLAIMS
ORDER BY TABLE_NAME;
