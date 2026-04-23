-- =============================================================================
-- Call Center AI Demo — Seed Data
-- =============================================================================
-- Populates reference tables with demo data:
--   • 8 customers (Diana Prince is the primary demo persona)
--   • 10 products
--   • 11 orders  (4 belong to Diana Prince)
--   • 14 order items
--   • 7 cases    (5 are headphone-defect cases for AI_SIMILARITY matching)
--
-- Prerequisites:
--   • 01_setup.sql has been executed.
--
-- Usage:
--   snow sql -f sql/02_seed_data.sql
-- =============================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE CALL_CENTER;
USE SCHEMA PUBLIC;

-- -----------------------------------------------------------------------------
-- 1. Customers
-- -----------------------------------------------------------------------------
INSERT INTO CUSTOMERS (NAME, EMAIL, PHONE, LOYALTY_TIER, ADDRESS) VALUES
    ('Diana Prince',     'diana.prince@gmail.com',     '8045551234', 'PLATINUM', '106 E Babcock St, Bozeman, MO 59715'),
    ('Jennifer Lee',     'jennifer.lee@yahoo.com',     '5551234567', 'GOLD',     '250 W Main St, Missoula, MT 59802'),
    ('Robert Kim',       'robert.kim@outlook.com',     '5559876543', 'SILVER',   '42 Oak Avenue, Portland, OR 97201'),
    ('Michael Chen',     'michael.chen@gmail.com',     '5554567890', 'PLATINUM', '789 Pine Street, Seattle, WA 98101'),
    ('Lisa Patel',       'lisa.patel@hotmail.com',     '5552345678', 'GOLD',     '123 Elm Drive, Denver, CO 80202'),
    ('Emily Rodriguez',  'emily.rodriguez@gmail.com',  '5553456789', 'SILVER',   '456 Maple Ln, Austin, TX 78701'),
    ('James Wilson',     'james.wilson@gmail.com',     '5558765432', 'GOLD',     '321 Cedar Rd, San Francisco, CA 94102'),
    ('Sarah Thompson',   'sarah.thompson@yahoo.com',   '5556543210', 'PLATINUM', '654 Birch Blvd, Chicago, IL 60601');

-- -----------------------------------------------------------------------------
-- 2. Products
-- -----------------------------------------------------------------------------
INSERT INTO PRODUCTS (NAME, CATEGORY, PRICE, SKU) VALUES
    ('Wireless Noise-Canceling Headphones', 'Electronics',  149.99, 'WH-NC100'),
    ('Smart Watch Pro',                     'Electronics',  299.99, 'SW-PRO200'),
    ('Running Shoes',                       'Footwear',     129.99, 'RS-AIR-10'),
    ('Coffee Maker Deluxe',                 'Kitchen',       89.99, 'CM-DLX50'),
    ('Laptop Backpack',                     'Accessories',   69.99, 'LB-TREK30'),
    ('Organic Cotton T-Shirt',              'Clothing',      34.99, 'OC-TEE01'),
    ('Yoga Mat Premium',                    'Fitness',       44.99, 'YM-PRE20'),
    ('Bluetooth Speaker',                   'Electronics',   79.99, 'BS-PORT300'),
    ('Stainless Steel Water Bottle',        'Accessories',   24.99, 'WB-SS500'),
    ('Portable Charger 20000mAh',           'Electronics',   39.99, 'PC-20K01');

-- -----------------------------------------------------------------------------
-- 3. Orders
-- -----------------------------------------------------------------------------
-- NOTE: Hybrid table AUTOINCREMENT IDs are non-deterministic.  The INSERT
-- order below matches the customer_id sequence so that foreign-key references
-- in ORDER_ITEMS (step 4) stay correct when the script is run on a fresh
-- database.  If you re-run on an existing database, drop & recreate first
-- (see 03_teardown.sql).
-- -----------------------------------------------------------------------------

-- Other customers' orders (one each)
INSERT INTO ORDERS (CUSTOMER_ID, ORDER_NUMBER, ORDER_DATE, STATUS, TOTAL, TRACKING_NUMBER) VALUES
    (2, 'ORD-2026-905', '2026-03-10', 'DELIVERED', 149.99, 'TRK-9905-A'),
    (3, 'ORD-2026-906', '2026-03-12', 'DELIVERED', 149.99, 'TRK-9906-A'),
    (4, 'ORD-2026-907', '2026-03-08', 'DELIVERED', 149.99, 'TRK-9907-A'),
    (5, 'ORD-2026-908', '2026-03-15', 'DELIVERED',  79.99, 'TRK-9908-A'),
    (6, 'ORD-2026-909', '2026-03-17', 'DELIVERED', 129.99, 'TRK-9909-A'),
    (7, 'ORD-2026-910', '2026-03-01', 'DELIVERED', 149.99, 'TRK-9910-A'),
    (8, 'ORD-2026-911', '2026-03-03', 'DELIVERED', 149.99, 'TRK-9911-A');

-- Diana Prince's 4 orders
INSERT INTO ORDERS (CUSTOMER_ID, ORDER_NUMBER, ORDER_DATE, STATUS, TOTAL, TRACKING_NUMBER) VALUES
    (1, 'ORD-2026-901', '2026-03-05', 'DELIVERED',   479.23, 'TRK-9901-A'),
    (1, 'ORD-2026-902', '2026-03-15', 'SHIPPED',     144.43, 'TRK-9902-B'),
    (1, 'ORD-2026-903', '2026-03-20', 'PROCESSING',  207.64, NULL),
    (1, 'ORD-2026-904', '2026-03-22', 'PENDING',     101.83, NULL);

-- -----------------------------------------------------------------------------
-- 4. Order Items
-- -----------------------------------------------------------------------------
-- Because hybrid-table autoincrement IDs may vary, we join on ORDER_NUMBER to
-- resolve the correct ORDER_ID at insert time.
-- -----------------------------------------------------------------------------

-- Other customers — each bought one product
INSERT INTO ORDER_ITEMS (ORDER_ID, PRODUCT_ID, QUANTITY, PRICE)
SELECT o.ORDER_ID, p.PRODUCT_ID, 1, p.PRICE
FROM ORDERS o JOIN PRODUCTS p ON TRUE
WHERE o.ORDER_NUMBER = 'ORD-2026-905' AND p.SKU = 'WH-NC100';

INSERT INTO ORDER_ITEMS (ORDER_ID, PRODUCT_ID, QUANTITY, PRICE)
SELECT o.ORDER_ID, p.PRODUCT_ID, 1, p.PRICE
FROM ORDERS o JOIN PRODUCTS p ON TRUE
WHERE o.ORDER_NUMBER = 'ORD-2026-906' AND p.SKU = 'WH-NC100';

INSERT INTO ORDER_ITEMS (ORDER_ID, PRODUCT_ID, QUANTITY, PRICE)
SELECT o.ORDER_ID, p.PRODUCT_ID, 1, p.PRICE
FROM ORDERS o JOIN PRODUCTS p ON TRUE
WHERE o.ORDER_NUMBER = 'ORD-2026-907' AND p.SKU = 'WH-NC100';

INSERT INTO ORDER_ITEMS (ORDER_ID, PRODUCT_ID, QUANTITY, PRICE)
SELECT o.ORDER_ID, p.PRODUCT_ID, 1, p.PRICE
FROM ORDERS o JOIN PRODUCTS p ON TRUE
WHERE o.ORDER_NUMBER = 'ORD-2026-908' AND p.SKU = 'BS-PORT300';

INSERT INTO ORDER_ITEMS (ORDER_ID, PRODUCT_ID, QUANTITY, PRICE)
SELECT o.ORDER_ID, p.PRODUCT_ID, 1, p.PRICE
FROM ORDERS o JOIN PRODUCTS p ON TRUE
WHERE o.ORDER_NUMBER = 'ORD-2026-909' AND p.SKU = 'RS-AIR-10';

INSERT INTO ORDER_ITEMS (ORDER_ID, PRODUCT_ID, QUANTITY, PRICE)
SELECT o.ORDER_ID, p.PRODUCT_ID, 1, p.PRICE
FROM ORDERS o JOIN PRODUCTS p ON TRUE
WHERE o.ORDER_NUMBER = 'ORD-2026-910' AND p.SKU = 'WH-NC100';

INSERT INTO ORDER_ITEMS (ORDER_ID, PRODUCT_ID, QUANTITY, PRICE)
SELECT o.ORDER_ID, p.PRODUCT_ID, 1, p.PRICE
FROM ORDERS o JOIN PRODUCTS p ON TRUE
WHERE o.ORDER_NUMBER = 'ORD-2026-911' AND p.SKU = 'WH-NC100';

-- Diana Prince — ORD-2026-901: Headphones + Smart Watch
INSERT INTO ORDER_ITEMS (ORDER_ID, PRODUCT_ID, QUANTITY, PRICE)
SELECT o.ORDER_ID, p.PRODUCT_ID, 1, 149.99
FROM ORDERS o JOIN PRODUCTS p ON TRUE
WHERE o.ORDER_NUMBER = 'ORD-2026-901' AND p.SKU = 'WH-NC100';

INSERT INTO ORDER_ITEMS (ORDER_ID, PRODUCT_ID, QUANTITY, PRICE)
SELECT o.ORDER_ID, p.PRODUCT_ID, 1, 299.99
FROM ORDERS o JOIN PRODUCTS p ON TRUE
WHERE o.ORDER_NUMBER = 'ORD-2026-901' AND p.SKU = 'SW-PRO200';

-- Diana Prince — ORD-2026-902: Running Shoes
INSERT INTO ORDER_ITEMS (ORDER_ID, PRODUCT_ID, QUANTITY, PRICE)
SELECT o.ORDER_ID, p.PRODUCT_ID, 1, 129.99
FROM ORDERS o JOIN PRODUCTS p ON TRUE
WHERE o.ORDER_NUMBER = 'ORD-2026-902' AND p.SKU = 'RS-AIR-10';

-- Diana Prince — ORD-2026-903: Backpack + 2x T-Shirt + Yoga Mat
INSERT INTO ORDER_ITEMS (ORDER_ID, PRODUCT_ID, QUANTITY, PRICE)
SELECT o.ORDER_ID, p.PRODUCT_ID, 1, 69.99
FROM ORDERS o JOIN PRODUCTS p ON TRUE
WHERE o.ORDER_NUMBER = 'ORD-2026-903' AND p.SKU = 'LB-TREK30';

INSERT INTO ORDER_ITEMS (ORDER_ID, PRODUCT_ID, QUANTITY, PRICE)
SELECT o.ORDER_ID, p.PRODUCT_ID, 2, 69.98
FROM ORDERS o JOIN PRODUCTS p ON TRUE
WHERE o.ORDER_NUMBER = 'ORD-2026-903' AND p.SKU = 'OC-TEE01';

INSERT INTO ORDER_ITEMS (ORDER_ID, PRODUCT_ID, QUANTITY, PRICE)
SELECT o.ORDER_ID, p.PRODUCT_ID, 1, 44.99
FROM ORDERS o JOIN PRODUCTS p ON TRUE
WHERE o.ORDER_NUMBER = 'ORD-2026-903' AND p.SKU = 'YM-PRE20';

-- Diana Prince — ORD-2026-904: Coffee Maker
INSERT INTO ORDER_ITEMS (ORDER_ID, PRODUCT_ID, QUANTITY, PRICE)
SELECT o.ORDER_ID, p.PRODUCT_ID, 1, 89.99
FROM ORDERS o JOIN PRODUCTS p ON TRUE
WHERE o.ORDER_NUMBER = 'ORD-2026-904' AND p.SKU = 'CM-DLX50';

-- -----------------------------------------------------------------------------
-- 5. Cases (support tickets — 5 headphone defects for AI_SIMILARITY matching)
-- -----------------------------------------------------------------------------
INSERT INTO CASES (CASE_NUMBER, CUSTOMER_ID, CUSTOMER_NAME, PRODUCT_ID, PRODUCT_NAME,
                   CASE_TYPE, STATUS, PRIORITY, ISSUE_DESCRIPTION, RESOLUTION, OPENED_DATE)
SELECT 'CASE-2026-002', c.CUSTOMER_ID, c.NAME, p.PRODUCT_ID,
       'Wireless Noise-Canceling Headphones (WH-NC100)',
       'DEFECT', 'CLOSED', 'HIGH',
       'Left earcup audio dropping randomly. Audio in the left ear keeps cutting in and out. Started after a week of use. No physical damage.',
       'Replacement sent. Engineering team investigating batch.',
       '2026-03-14'
FROM CUSTOMERS c, PRODUCTS p
WHERE c.NAME = 'Michael Chen' AND p.SKU = 'WH-NC100';

INSERT INTO CASES (CASE_NUMBER, CUSTOMER_ID, CUSTOMER_NAME, PRODUCT_ID, PRODUCT_NAME,
                   CASE_TYPE, STATUS, PRIORITY, ISSUE_DESCRIPTION, RESOLUTION, OPENED_DATE)
SELECT 'CASE-2026-003', c.CUSTOMER_ID, c.NAME, p.PRODUCT_ID,
       'Wireless Noise-Canceling Headphones (WH-NC100)',
       'DEFECT', 'OPEN', 'HIGH',
       'Left earphone audio failure. Left side goes silent after about 15-20 min. Noise canceling still works but no audio. Firmware is up to date.',
       NULL,
       '2026-03-18'
FROM CUSTOMERS c, PRODUCTS p
WHERE c.NAME = 'Jennifer Lee' AND p.SKU = 'WH-NC100';

INSERT INTO CASES (CASE_NUMBER, CUSTOMER_ID, CUSTOMER_NAME, PRODUCT_ID, PRODUCT_NAME,
                   CASE_TYPE, STATUS, PRIORITY, ISSUE_DESCRIPTION, RESOLUTION, OPENED_DATE)
SELECT 'CASE-2026-004', c.CUSTOMER_ID, c.NAME, p.PRODUCT_ID,
       'Wireless Noise-Canceling Headphones (WH-NC100)',
       'DEFECT', 'OPEN', 'CRITICAL',
       'Headphones left channel dead after 2 weeks. Left channel completely stopped working. Tried factory reset, different devices, wired connection — nothing fixes it. Clearly a hardware defect.',
       NULL,
       '2026-03-21'
FROM CUSTOMERS c, PRODUCTS p
WHERE c.NAME = 'Robert Kim' AND p.SKU = 'WH-NC100';

INSERT INTO CASES (CASE_NUMBER, CUSTOMER_ID, CUSTOMER_NAME, PRODUCT_ID, PRODUCT_NAME,
                   CASE_TYPE, STATUS, PRIORITY, ISSUE_DESCRIPTION, RESOLUTION, OPENED_DATE)
SELECT 'CASE-2026-005', c.CUSTOMER_ID, c.NAME, p.PRODUCT_ID,
       'Wireless Noise-Canceling Headphones (WH-NC100)',
       'DEFECT', 'OPEN', 'HIGH',
       'Audio cuts out in left ear intermittently. The left ear audio keeps dropping for 2-3 seconds then comes back. Happens multiple times per hour. Very frustrating during calls.',
       NULL,
       '2026-03-19'
FROM CUSTOMERS c, PRODUCTS p
WHERE c.NAME = 'James Wilson' AND p.SKU = 'WH-NC100';

INSERT INTO CASES (CASE_NUMBER, CUSTOMER_ID, CUSTOMER_NAME, PRODUCT_ID, PRODUCT_NAME,
                   CASE_TYPE, STATUS, PRIORITY, ISSUE_DESCRIPTION, RESOLUTION, OPENED_DATE)
SELECT 'CASE-2026-006', c.CUSTOMER_ID, c.NAME, p.PRODUCT_ID,
       'Running Shoes (RS-AIR-10)',
       'RETURN', 'OPEN', 'MEDIUM',
       'Running shoes wrong size. Received size 10 but ordered size 11. Need exchange.',
       NULL,
       '2026-03-17'
FROM CUSTOMERS c, PRODUCTS p
WHERE c.NAME = 'Emily Rodriguez' AND p.SKU = 'RS-AIR-10';

INSERT INTO CASES (CASE_NUMBER, CUSTOMER_ID, CUSTOMER_NAME, PRODUCT_ID, PRODUCT_NAME,
                   CASE_TYPE, STATUS, PRIORITY, ISSUE_DESCRIPTION, RESOLUTION, OPENED_DATE)
SELECT 'CASE-2026-007', c.CUSTOMER_ID, c.NAME, p.PRODUCT_ID,
       'Wireless Noise-Canceling Headphones (WH-NC100)',
       'DEFECT', 'OPEN', 'HIGH',
       'Left ear audio intermittent failure. Left ear sound keeps cutting out during music playback. Started happening after firmware update. Right ear works fine.',
       NULL,
       '2026-03-20'
FROM CUSTOMERS c, PRODUCTS p
WHERE c.NAME = 'Sarah Thompson' AND p.SKU = 'WH-NC100';

INSERT INTO CASES (CASE_NUMBER, CUSTOMER_ID, CUSTOMER_NAME, PRODUCT_ID, PRODUCT_NAME,
                   CASE_TYPE, STATUS, PRIORITY, ISSUE_DESCRIPTION, RESOLUTION, OPENED_DATE)
SELECT 'CASE-2026-008', c.CUSTOMER_ID, c.NAME, p.PRODUCT_ID,
       'Bluetooth Speaker (BS-PORT300)',
       'INQUIRY', 'CLOSED', 'LOW',
       'Bluetooth speaker pairing question. Customer needed help pairing speaker with smart TV. Not a defect.',
       'Walked customer through pairing process. Resolved.',
       '2026-03-19'
FROM CUSTOMERS c, PRODUCTS p
WHERE c.NAME = 'Lisa Patel' AND p.SKU = 'BS-PORT300';

-- -----------------------------------------------------------------------------
-- 6. Verification
-- -----------------------------------------------------------------------------
SELECT 'CUSTOMERS'    AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM CUSTOMERS
UNION ALL SELECT 'PRODUCTS',     COUNT(*) FROM PRODUCTS
UNION ALL SELECT 'ORDERS',       COUNT(*) FROM ORDERS
UNION ALL SELECT 'ORDER_ITEMS',  COUNT(*) FROM ORDER_ITEMS
UNION ALL SELECT 'CASES',        COUNT(*) FROM CASES
ORDER BY TABLE_NAME;
