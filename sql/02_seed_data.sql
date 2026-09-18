-- ============================================================
-- Rutzfin: Banking Transaction Intelligence Platform
-- FILE: 02_seed_data.sql
-- PURPOSE: Seed data — branches, customers, accounts,
--          transactions, fraud alerts, loans, loan payments
-- PLATFORM: Azure SQL / T-SQL
-- ============================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

-- ============================================================
-- 1. BRANCHES  (5 GTA locations)
-- ============================================================
INSERT INTO branches (branch_name, city, province, address, phone, opened_date, is_active)
VALUES
    ('Downtown Toronto Main',   'Toronto',      'ON', '200 Bay Street, Suite 100',          '416-555-0100', '2010-03-15', 1),
    ('Scarborough East',        'Toronto',      'ON', '3850 Sheppard Ave E, Unit 201',       '416-555-0201', '2012-06-01', 1),
    ('Mississauga City Centre', 'Mississauga',  'ON', '100 City Centre Dr, Suite 500',       '905-555-0301', '2011-09-20', 1),
    ('Brampton Bramalea',       'Brampton',     'ON', '25 Peel Centre Dr, Unit 310',         '905-555-0401', '2013-04-10', 1),
    ('North York Yonge',        'Toronto',      'ON', '5000 Yonge Street, Suite 1800',       '416-555-0501', '2014-11-05', 1);
GO

-- ============================================================
-- 2. MERCHANT CATEGORIES  (10 MCC-style codes)
-- ============================================================
INSERT INTO merchant_categories (category_code, category_name)
VALUES
    ('GROC', 'Groceries'),
    ('TRANS','Transportation'),
    ('DINE', 'Dining'),
    ('UTIL', 'Utilities'),
    ('HLTH', 'Health'),
    ('ENTE', 'Entertainment'),
    ('RETL', 'Retail'),
    ('TRVL', 'Travel'),
    ('EDUC', 'Education'),
    ('MISC', 'Miscellaneous');
GO

-- ============================================================
-- 3. CUSTOMERS  (20 GTA residents)
-- ============================================================
INSERT INTO customers (first_name, last_name, email, phone, date_of_birth, credit_score, join_date, city, province, is_active)
VALUES
    -- Branch 1 – Downtown Toronto
    ('Michael',   'Chen',      'michael.chen@email.ca',      '416-555-1001', '1988-04-12', 810, '2015-02-10', 'Toronto',     'ON', 1),
    ('Sarah',     'Thompson',  'sarah.thompson@email.ca',    '416-555-1002', '1992-07-23', 755, '2016-08-14', 'Toronto',     'ON', 1),
    ('Amara',     'Okonkwo',   'amara.okonkwo@email.ca',     '416-555-1003', '1985-11-30', 690, '2013-05-20', 'Toronto',     'ON', 1),
    ('David',     'Patel',     'david.patel@email.ca',       '416-555-1004', '1979-03-08', 870, '2014-09-03', 'Toronto',     'ON', 1),
    -- Branch 2 – Scarborough
    ('Priya',     'Sharma',    'priya.sharma@email.ca',      '416-555-1005', '1995-06-17', 620, '2019-11-22', 'Toronto',     'ON', 1),
    ('James',     'Williams',  'james.williams@email.ca',    '416-555-1006', '1983-09-25', 740, '2015-04-07', 'Toronto',     'ON', 1),
    ('Fatima',    'Al-Rashid', 'fatima.alrashid@email.ca',   '416-555-1007', '1990-01-14', 680, '2018-07-30', 'Toronto',     'ON', 1),
    ('Kevin',     'Nguyen',    'kevin.nguyen@email.ca',      '416-555-1008', '1987-12-02', 795, '2016-03-18', 'Toronto',     'ON', 1),
    -- Branch 3 – Mississauga
    ('Aisha',     'Mohammed',  'aisha.mohammed@email.ca',    '905-555-1009', '1993-08-19', 580, '2020-06-15', 'Mississauga', 'ON', 1),
    ('Robert',    'MacDonald', 'robert.macdonald@email.ca',  '905-555-1010', '1975-02-28', 820, '2013-10-01', 'Mississauga', 'ON', 1),
    ('Mei',       'Zhang',     'mei.zhang@email.ca',         '905-555-1011', '1991-05-06', 760, '2017-01-25', 'Mississauga', 'ON', 1),
    ('Carlos',    'Rivera',    'carlos.rivera@email.ca',     '905-555-1012', '1986-10-11', 705, '2016-12-09', 'Mississauga', 'ON', 1),
    -- Branch 4 – Brampton
    ('Gurpreet',  'Singh',     'gurpreet.singh@email.ca',    '905-555-1013', '1989-03-22', 730, '2018-02-14', 'Brampton',    'ON', 1),
    ('Olivia',    'Brown',     'olivia.brown@email.ca',      '905-555-1014', '1997-07-09', 610, '2021-09-08', 'Brampton',    'ON', 1),
    ('Hassan',    'Ibrahim',   'hassan.ibrahim@email.ca',    '905-555-1015', '1982-04-16', 775, '2014-07-22', 'Brampton',    'ON', 1),
    -- Branch 5 – North York
    ('Jennifer',  'Park',      'jennifer.park@email.ca',     '416-555-1016', '1994-09-30', 860, '2017-06-11', 'Toronto',     'ON', 1),
    ('Raj',       'Krishnamurthy','raj.krishnamurthy@email.ca','416-555-1017','1980-12-05', 715, '2015-11-19', 'Toronto',     'ON', 1),
    ('Emily',     'Tremblay',  'emily.tremblay@email.ca',    '416-555-1018', '1998-02-14', 640, '2022-04-03', 'Toronto',     'ON', 1),
    ('Omar',      'Farouk',    'omar.farouk@email.ca',       '416-555-1019', '1976-06-27', 790, '2013-08-17', 'Toronto',     'ON', 1),
    ('Linda',     'Osei',      'linda.osei@email.ca',        '416-555-1020', '1988-11-08', 655, '2020-01-30', 'Toronto',     'ON', 1);
GO

-- ============================================================
-- 4. ACCOUNTS  (35 accounts across 20 customers)
--    customer_id map: Chen=1, Thompson=2, Okonkwo=3, Patel=4,
--    Sharma=5, Williams=6, Al-Rashid=7, Nguyen=8,
--    Mohammed=9, MacDonald=10, Zhang=11, Rivera=12,
--    Singh=13, Brown=14, Ibrahim=15, Park=16, Krishnamurthy=17,
--    Tremblay=18, Farouk=19, Osei=20
-- ============================================================
INSERT INTO accounts (customer_id, branch_id, account_number, account_type, balance, interest_rate, status, opened_date)
VALUES
    -- Michael Chen (1) – Downtown
    (1,  1, 'RZ-100-0001', 'Chequing', 18450.00, 0.0000, 'Active', '2015-02-10'),
    (1,  1, 'RZ-100-0002', 'TFSA',     52000.00, 0.0400, 'Active', '2015-02-10'),
    -- Sarah Thompson (2) – Downtown
    (2,  1, 'RZ-100-0003', 'Chequing',  6820.50, 0.0000, 'Active', '2016-08-14'),
    (2,  1, 'RZ-100-0004', 'Savings',  22150.00, 0.0350, 'Active', '2016-08-14'),
    -- Amara Okonkwo (3) – Downtown
    (3,  1, 'RZ-100-0005', 'Chequing',  3940.25, 0.0000, 'Active', '2013-05-20'),
    (3,  1, 'RZ-100-0006', 'RRSP',     41200.00, 0.0450, 'Active', '2013-05-20'),
    -- David Patel (4) – Downtown
    (4,  1, 'RZ-100-0007', 'Chequing', 28000.00, 0.0000, 'Active', '2014-09-03'),
    (4,  1, 'RZ-100-0008', 'RRSP',    135000.00, 0.0475, 'Active', '2014-09-03'),
    (4,  1, 'RZ-100-0009', 'TFSA',     41000.00, 0.0400, 'Active', '2018-01-02'),
    -- Priya Sharma (5) – Scarborough
    (5,  2, 'RZ-200-0010', 'Chequing',  1250.80, 0.0000, 'Active', '2019-11-22'),
    (5,  2, 'RZ-200-0011', 'Savings',   5800.00, 0.0350, 'Active', '2019-11-22'),
    -- James Williams (6) – Scarborough
    (6,  2, 'RZ-200-0012', 'Chequing',  9300.00, 0.0000, 'Active', '2015-04-07'),
    (6,  2, 'RZ-200-0013', 'RRSP',     67500.00, 0.0450, 'Active', '2015-04-07'),
    -- Fatima Al-Rashid (7) – Scarborough
    (7,  2, 'RZ-200-0014', 'Chequing',  4100.00, 0.0000, 'Active', '2018-07-30'),
    (7,  2, 'RZ-200-0015', 'Savings',  18000.00, 0.0350, 'Active', '2018-07-30'),
    -- Kevin Nguyen (8) – Scarborough
    (8,  2, 'RZ-200-0016', 'Chequing', 12750.00, 0.0000, 'Active', '2016-03-18'),
    (8,  2, 'RZ-200-0017', 'TFSA',     38500.00, 0.0400, 'Active', '2016-03-18'),
    -- Aisha Mohammed (9) – Mississauga
    (9,  3, 'RZ-300-0018', 'Chequing',    780.45, 0.0000, 'Active', '2020-06-15'),
    (9,  3, 'RZ-300-0019', 'Savings',    3200.00, 0.0325, 'Active', '2020-06-15'),
    -- Robert MacDonald (10) – Mississauga
    (10, 3, 'RZ-300-0020', 'Chequing', 31000.00, 0.0000, 'Active', '2013-10-01'),
    (10, 3, 'RZ-300-0021', 'RRSP',     98500.00, 0.0475, 'Active', '2013-10-01'),
    -- Mei Zhang (11) – Mississauga
    (11, 3, 'RZ-300-0022', 'Chequing',  7200.00, 0.0000, 'Active', '2017-01-25'),
    (11, 3, 'RZ-300-0023', 'Savings',  24000.00, 0.0350, 'Active', '2017-01-25'),
    -- Carlos Rivera (12) – Mississauga
    (12, 3, 'RZ-300-0024', 'Chequing',  5500.00, 0.0000, 'Active', '2016-12-09'),
    -- Gurpreet Singh (13) – Brampton
    (13, 4, 'RZ-400-0025', 'Chequing',  8900.00, 0.0000, 'Active', '2018-02-14'),
    (13, 4, 'RZ-400-0026', 'TFSA',     29000.00, 0.0400, 'Active', '2018-02-14'),
    -- Olivia Brown (14) – Brampton
    (14, 4, 'RZ-400-0027', 'Chequing',   960.00, 0.0000, 'Active', '2021-09-08'),
    -- Hassan Ibrahim (15) – Brampton
    (15, 4, 'RZ-400-0028', 'Chequing', 16200.00, 0.0000, 'Active', '2014-07-22'),
    (15, 4, 'RZ-400-0029', 'RRSP',     73000.00, 0.0450, 'Active', '2014-07-22'),
    -- Jennifer Park (16) – North York
    (16, 5, 'RZ-500-0030', 'Chequing', 22800.00, 0.0000, 'Active', '2017-06-11'),
    (16, 5, 'RZ-500-0031', 'TFSA',     61000.00, 0.0400, 'Active', '2017-06-11'),
    -- Raj Krishnamurthy (17) – North York
    (17, 5, 'RZ-500-0032', 'Chequing', 11500.00, 0.0000, 'Active', '2015-11-19'),
    (17, 5, 'RZ-500-0033', 'Savings',  34000.00, 0.0350, 'Active', '2015-11-19'),
    -- Emily Tremblay (18) – North York
    (18, 5, 'RZ-500-0034', 'Chequing',  2300.00, 0.0000, 'Active', '2022-04-03'),
    -- Omar Farouk (19) – North York
    (19, 5, 'RZ-500-0035', 'Chequing', 19700.00, 0.0000, 'Active', '2013-08-17');
GO

-- ============================================================
-- 5. TRANSACTIONS  (120 rows, Jan–May 2025)
--    Merchant category IDs: GROC=1, TRANS=2, DINE=3, UTIL=4,
--    HLTH=5, ENTE=6, RETL=7, TRVL=8, EDUC=9, MISC=10
-- ============================================================

-- ---- Michael Chen (account_id=1, Chequing RZ-100-0001) ----
INSERT INTO transactions (account_id, transaction_type, amount, transaction_date, merchant_name, category_id, description, reference_number, balance_after, channel, is_flagged)
VALUES
(1, 'Deposit',    7500.00, '2025-01-02 08:00:00', NULL,                  NULL, 'Monthly salary deposit',       'REF-001-0101', 25950.00, 'Online',  0),
(1, 'Payment',     220.00, '2025-01-05 10:15:00', 'Rogers Communications', 4,  'Monthly cell & internet',      'REF-001-0102', 25730.00, 'Online',  0),
(1, 'Payment',     185.50, '2025-01-08 12:30:00', 'Loblaws',              1,   'Grocery run',                  'REF-001-0103', 25544.50, 'POS',     0),
(1, 'Payment',    2200.00, '2025-01-15 09:00:00', 'Landlord Corp',        NULL,'January rent',                 'REF-001-0104', 23344.50, 'Online',  0),
(1, 'Withdrawal', 15000.00,'2025-01-22 01:03:00', NULL,                  NULL, 'Cash withdrawal',              'REF-001-0105',  8344.50, 'ATM',     1),  -- suspicious
(1, 'Deposit',    7500.00, '2025-02-03 08:00:00', NULL,                  NULL, 'Monthly salary deposit',       'REF-001-0201', 15844.50, 'Online',  0),
(1, 'Payment',     192.30, '2025-02-07 11:00:00', 'No Frills',            1,   'Grocery run',                  'REF-001-0202', 15652.20, 'POS',     0),
(1, 'Payment',    2200.00, '2025-02-15 09:00:00', 'Landlord Corp',        NULL,'February rent',                'REF-001-0203', 13452.20, 'Online',  0),
(1, 'Payment',      78.40, '2025-02-20 19:30:00', 'LCBO',                 3,   'Dining & beverages',           'REF-001-0204', 13373.80, 'POS',     0),
(1, 'Deposit',    7500.00, '2025-03-03 08:00:00', NULL,                  NULL, 'Monthly salary deposit',       'REF-001-0301', 20873.80, 'Online',  0),
(1, 'Payment',     210.00, '2025-03-05 10:00:00', 'Rogers Communications', 4,  'Monthly cell & internet',      'REF-001-0302', 20663.80, 'Online',  0),
(1, 'Payment',    2200.00, '2025-03-15 09:00:00', 'Landlord Corp',        NULL,'March rent',                   'REF-001-0303', 18463.80, 'Online',  0),
(1, 'Payment',     145.60, '2025-03-19 13:45:00', 'Loblaws',              1,   'Grocery run',                  'REF-001-0304', 18318.20, 'POS',     0),
(1, 'Deposit',    7500.00, '2025-04-02 08:00:00', NULL,                  NULL, 'Monthly salary deposit',       'REF-001-0401', 25818.20, 'Online',  0),
(1, 'Payment',    2200.00, '2025-04-15 09:00:00', 'Landlord Corp',        NULL,'April rent',                   'REF-001-0402', 23618.20, 'Online',  0),
(1, 'Payment',     330.00, '2025-04-22 20:00:00', 'Air Canada',           8,   'Flight TO-YVR',                'REF-001-0403', 23288.20, 'Online',  0),
(1, 'Deposit',    7500.00, '2025-05-02 08:00:00', NULL,                  NULL, 'Monthly salary deposit',       'REF-001-0501', 30788.20, 'Online',  0),
(1, 'Payment',     168.90, '2025-05-09 11:30:00', 'Metro Grocery',        1,   'Grocery run',                  'REF-001-0502', 30619.30, 'POS',     0),
(1, 'Payment',    2200.00, '2025-05-15 09:00:00', 'Landlord Corp',        NULL,'May rent',                     'REF-001-0503', 28419.30, 'Online',  0);
GO

-- ---- Sarah Thompson (account_id=3, Chequing RZ-100-0003) ----
INSERT INTO transactions (account_id, transaction_type, amount, transaction_date, merchant_name, category_id, description, reference_number, balance_after, channel, is_flagged)
VALUES
(3, 'Deposit',    5200.00, '2025-01-03 08:00:00', NULL,             NULL, 'Monthly salary deposit',    'REF-003-0101', 12020.50, 'Online', 0),
(3, 'Payment',    1800.00, '2025-01-15 09:00:00', 'Landlord Corp',  NULL, 'January rent',              'REF-003-0102', 10220.50, 'Online', 0),
(3, 'Payment',     145.20, '2025-01-20 12:00:00', 'Sobeys',         1,   'Grocery shopping',          'REF-003-0103', 10075.30, 'POS',    0),
(3, 'Payment',      62.50, '2025-01-25 18:30:00', 'Cineplex',       6,   'Movie night',               'REF-003-0104', 10012.80, 'Online', 0),
(3, 'Deposit',    5200.00, '2025-02-03 08:00:00', NULL,             NULL, 'Monthly salary deposit',    'REF-003-0201', 15212.80, 'Online', 0),
(3, 'Payment',    1800.00, '2025-02-15 09:00:00', 'Landlord Corp',  NULL, 'February rent',             'REF-003-0202', 13412.80, 'Online', 0),
(3, 'Payment',     112.80, '2025-02-22 14:00:00', 'Loblaws',        1,   'Grocery shopping',          'REF-003-0203', 13300.00, 'POS',    0),
(3, 'Deposit',    5200.00, '2025-03-03 08:00:00', NULL,             NULL, 'Monthly salary deposit',    'REF-003-0301', 18500.00, 'Online', 0),
(3, 'Payment',    1800.00, '2025-03-15 09:00:00', 'Landlord Corp',  NULL, 'March rent',               'REF-003-0302', 16700.00, 'Online', 0),
(3, 'Payment',     198.30, '2025-03-28 11:00:00', 'SportChek',      7,   'Running gear',              'REF-003-0303', 16501.70, 'POS',    0),
(3, 'Deposit',    5200.00, '2025-04-02 08:00:00', NULL,             NULL, 'Monthly salary deposit',    'REF-003-0401', 21701.70, 'Online', 0),
(3, 'Payment',    1800.00, '2025-04-15 09:00:00', 'Landlord Corp',  NULL, 'April rent',               'REF-003-0402', 19901.70, 'Online', 0),
(3, 'Deposit',    5200.00, '2025-05-02 08:00:00', NULL,             NULL, 'Monthly salary deposit',    'REF-003-0501', 25101.70, 'Online', 0),
(3, 'Payment',    1800.00, '2025-05-15 09:00:00', 'Landlord Corp',  NULL, 'May rent',                 'REF-003-0502', 23301.70, 'Online', 0);
GO

-- ---- Amara Okonkwo (account_id=5, Chequing RZ-100-0005) — suspicious txn ----
INSERT INTO transactions (account_id, transaction_type, amount, transaction_date, merchant_name, category_id, description, reference_number, balance_after, channel, is_flagged)
VALUES
(5, 'Deposit',    4800.00, '2025-01-02 08:00:00', NULL,               NULL, 'Monthly salary deposit',    'REF-005-0101', 8740.25, 'Online', 0),
(5, 'Payment',    1500.00, '2025-01-15 09:00:00', 'Landlord Corp',    NULL, 'January rent',              'REF-005-0102', 7240.25, 'Online', 0),
(5, 'Payment',     178.60, '2025-01-19 13:00:00', 'No Frills',        1,   'Grocery shopping',          'REF-005-0103', 7061.65, 'POS',    0),
(5, 'Deposit',    4800.00, '2025-02-03 08:00:00', NULL,               NULL, 'Monthly salary deposit',    'REF-005-0201', 11861.65,'Online', 0),
(5, 'Payment',    1500.00, '2025-02-15 09:00:00', 'Landlord Corp',    NULL, 'February rent',             'REF-005-0202', 10361.65,'Online', 0),
(5, 'Payment',    4200.00, '2025-02-21 03:12:00', 'Unknown Vendor',  10,   'Unrecognized payment',      'REF-005-0203',  6161.65,'Online', 1),  -- suspicious: 3am large payment
(5, 'Deposit',    4800.00, '2025-03-03 08:00:00', NULL,               NULL, 'Monthly salary deposit',    'REF-005-0301', 10961.65,'Online', 0),
(5, 'Payment',    1500.00, '2025-03-15 09:00:00', 'Landlord Corp',    NULL, 'March rent',               'REF-005-0302',  9461.65,'Online', 0),
(5, 'Payment',     210.40, '2025-03-22 11:30:00', 'Shoppers Drug Mart',5,  'Prescriptions & health',   'REF-005-0303',  9251.25,'POS',    0),
(5, 'Deposit',    4800.00, '2025-04-02 08:00:00', NULL,               NULL, 'Monthly salary deposit',    'REF-005-0401', 14051.25,'Online', 0),
(5, 'Payment',    1500.00, '2025-04-15 09:00:00', 'Landlord Corp',    NULL, 'April rent',               'REF-005-0402', 12551.25,'Online', 0),
(5, 'Deposit',    4800.00, '2025-05-02 08:00:00', NULL,               NULL, 'Monthly salary deposit',    'REF-005-0501', 17351.25,'Online', 0),
(5, 'Payment',    1500.00, '2025-05-15 09:00:00', 'Landlord Corp',    NULL, 'May rent',                 'REF-005-0502', 15851.25,'Online', 0);
GO

-- ---- David Patel (account_id=7, Chequing RZ-100-0007) ----
INSERT INTO transactions (account_id, transaction_type, amount, transaction_date, merchant_name, category_id, description, reference_number, balance_after, channel, is_flagged)
VALUES
(7, 'Deposit',   18000.00, '2025-01-02 08:00:00', NULL,                  NULL, 'Monthly salary deposit',    'REF-007-0101', 46000.00, 'Online', 0),
(7, 'Payment',    3500.00, '2025-01-15 09:00:00', 'TD Mortgage Services',NULL, 'Mortgage payment',          'REF-007-0102', 42500.00, 'Online', 0),
(7, 'Payment',     450.00, '2025-01-18 14:00:00', 'Whole Foods',         1,   'Grocery & household',       'REF-007-0103', 42050.00, 'POS',    0),
(7, 'Withdrawal',  800.00, '2025-01-25 16:00:00', NULL,                  NULL, 'ATM withdrawal',            'REF-007-0104', 41250.00, 'ATM',    0),
(7, 'Deposit',   18000.00, '2025-02-03 08:00:00', NULL,                  NULL, 'Monthly salary deposit',    'REF-007-0201', 59250.00, 'Online', 0),
(7, 'Payment',    3500.00, '2025-02-15 09:00:00', 'TD Mortgage Services',NULL, 'Mortgage payment',          'REF-007-0202', 55750.00, 'Online', 0),
(7, 'Payment',     380.20, '2025-02-19 12:00:00', 'Loblaws',             1,   'Grocery run',               'REF-007-0203', 55369.80, 'POS',    0),
(7, 'Deposit',   18000.00, '2025-03-03 08:00:00', NULL,                  NULL, 'Monthly salary deposit',    'REF-007-0301', 73369.80, 'Online', 0),
(7, 'Payment',    3500.00, '2025-03-15 09:00:00', 'TD Mortgage Services',NULL, 'Mortgage payment',          'REF-007-0302', 69869.80, 'Online', 0),
(7, 'Payment',    1200.00, '2025-03-28 18:00:00', 'Four Seasons Hotel',  8,   'Weekend staycation',        'REF-007-0303', 68669.80, 'Online', 0),
(7, 'Deposit',   18000.00, '2025-04-02 08:00:00', NULL,                  NULL, 'Monthly salary deposit',    'REF-007-0401', 86669.80, 'Online', 0),
(7, 'Payment',    3500.00, '2025-04-15 09:00:00', 'TD Mortgage Services',NULL, 'Mortgage payment',          'REF-007-0402', 83169.80, 'Online', 0),
(7, 'Deposit',   18000.00, '2025-05-02 08:00:00', NULL,                  NULL, 'Monthly salary deposit',    'REF-007-0501', 101169.80,'Online', 0),
(7, 'Payment',    3500.00, '2025-05-15 09:00:00', 'TD Mortgage Services',NULL, 'Mortgage payment',          'REF-007-0502', 97669.80, 'Online', 0);
GO

-- ---- Priya Sharma (account_id=10, Chequing RZ-200-0010) — suspicious ATM ----
INSERT INTO transactions (account_id, transaction_type, amount, transaction_date, merchant_name, category_id, description, reference_number, balance_after, channel, is_flagged)
VALUES
(10, 'Deposit',   2400.00, '2025-01-03 08:00:00', NULL,            NULL, 'Monthly salary deposit',   'REF-010-0101', 4050.80, 'Online', 0),
(10, 'Payment',    900.00, '2025-01-15 09:00:00', 'Landlord Corp', NULL, 'January rent',             'REF-010-0102', 3150.80, 'Online', 0),
(10, 'Payment',    112.40, '2025-01-20 12:30:00', 'No Frills',     1,   'Groceries',                'REF-010-0103', 3038.40, 'POS',    0),
(10, 'Deposit',   2400.00, '2025-02-03 08:00:00', NULL,            NULL, 'Monthly salary deposit',   'REF-010-0201', 5438.40, 'Online', 0),
(10, 'Payment',    900.00, '2025-02-15 09:00:00', 'Landlord Corp', NULL, 'February rent',            'REF-010-0202', 4538.40, 'Online', 0),
(10, 'Withdrawal',2800.00, '2025-02-18 02:48:00', NULL,            NULL, 'ATM cash withdrawal',      'REF-010-0203', 1738.40, 'ATM',    1),  -- suspicious: 2:48am
(10, 'Deposit',   2400.00, '2025-03-03 08:00:00', NULL,            NULL, 'Monthly salary deposit',   'REF-010-0301', 4138.40, 'Online', 0),
(10, 'Payment',    900.00, '2025-03-15 09:00:00', 'Landlord Corp', NULL, 'March rent',               'REF-010-0302', 3238.40, 'Online', 0),
(10, 'Payment',     88.60, '2025-03-21 14:00:00', 'Shoppers',      5,   'Pharmacy',                 'REF-010-0303', 3149.80, 'POS',    0),
(10, 'Deposit',   2400.00, '2025-04-02 08:00:00', NULL,            NULL, 'Monthly salary deposit',   'REF-010-0401', 5549.80, 'Online', 0),
(10, 'Payment',    900.00, '2025-04-15 09:00:00', 'Landlord Corp', NULL, 'April rent',               'REF-010-0402', 4649.80, 'Online', 0),
(10, 'Deposit',   2400.00, '2025-05-02 08:00:00', NULL,            NULL, 'Monthly salary deposit',   'REF-010-0501', 7049.80, 'Online', 0),
(10, 'Payment',    900.00, '2025-05-15 09:00:00', 'Landlord Corp', NULL, 'May rent',                 'REF-010-0502', 6149.80, 'Online', 0);
GO

-- ---- James Williams (account_id=12, Chequing RZ-200-0012) ----
INSERT INTO transactions (account_id, transaction_type, amount, transaction_date, merchant_name, category_id, description, reference_number, balance_after, channel, is_flagged)
VALUES
(12, 'Deposit',   6500.00, '2025-01-02 08:00:00', NULL,             NULL, 'Monthly salary deposit',   'REF-012-0101', 15800.00, 'Online', 0),
(12, 'Payment',   1600.00, '2025-01-15 09:00:00', 'Landlord Corp',  NULL, 'January rent',             'REF-012-0102', 14200.00, 'Online', 0),
(12, 'Payment',    235.60, '2025-01-22 13:00:00', 'Costco',         1,   'Bulk grocery',             'REF-012-0103', 13964.40, 'POS',    0),
(12, 'Deposit',   6500.00, '2025-02-03 08:00:00', NULL,             NULL, 'Monthly salary deposit',   'REF-012-0201', 20464.40, 'Online', 0),
(12, 'Payment',   1600.00, '2025-02-15 09:00:00', 'Landlord Corp',  NULL, 'February rent',            'REF-012-0202', 18864.40, 'Online', 0),
(12, 'Payment',     89.99, '2025-02-26 18:00:00', 'Netflix / Spotify',6, 'Streaming services',       'REF-012-0203', 18774.41, 'Online', 0),
(12, 'Deposit',   6500.00, '2025-03-03 08:00:00', NULL,             NULL, 'Monthly salary deposit',   'REF-012-0301', 25274.41, 'Online', 0),
(12, 'Payment',   1600.00, '2025-03-15 09:00:00', 'Landlord Corp',  NULL, 'March rent',               'REF-012-0302', 23674.41, 'Online', 0),
(12, 'Deposit',   6500.00, '2025-04-02 08:00:00', NULL,             NULL, 'Monthly salary deposit',   'REF-012-0401', 30174.41, 'Online', 0),
(12, 'Payment',   1600.00, '2025-04-15 09:00:00', 'Landlord Corp',  NULL, 'April rent',               'REF-012-0402', 28574.41, 'Online', 0),
(12, 'Deposit',   6500.00, '2025-05-02 08:00:00', NULL,             NULL, 'Monthly salary deposit',   'REF-012-0501', 35074.41, 'Online', 0),
(12, 'Payment',   1600.00, '2025-05-15 09:00:00', 'Landlord Corp',  NULL, 'May rent',                 'REF-012-0502', 33474.41, 'Online', 0);
GO

-- ---- Robert MacDonald (account_id=20, Chequing RZ-300-0020) ----
INSERT INTO transactions (account_id, transaction_type, amount, transaction_date, merchant_name, category_id, description, reference_number, balance_after, channel, is_flagged)
VALUES
(20, 'Deposit',   12000.00, '2025-01-02 08:00:00', NULL,                  NULL, 'Monthly salary deposit',   'REF-020-0101', 43000.00, 'Online', 0),
(20, 'Payment',    3200.00, '2025-01-15 09:00:00', 'CMHC Mortgage',       NULL, 'Mortgage payment',         'REF-020-0102', 39800.00, 'Online', 0),
(20, 'Payment',     395.00, '2025-01-21 11:00:00', 'Costco',              1,   'Grocery & household',      'REF-020-0103', 39405.00, 'POS',    0),
(20, 'Deposit',   12000.00, '2025-02-03 08:00:00', NULL,                  NULL, 'Monthly salary deposit',   'REF-020-0201', 51405.00, 'Online', 0),
(20, 'Payment',    3200.00, '2025-02-15 09:00:00', 'CMHC Mortgage',       NULL, 'Mortgage payment',         'REF-020-0202', 48205.00, 'Online', 0),
(20, 'Payment',     620.00, '2025-02-28 16:00:00', 'Canadian Tire',       7,   'Home improvement',         'REF-020-0203', 47585.00, 'POS',    0),
(20, 'Deposit',   12000.00, '2025-03-03 08:00:00', NULL,                  NULL, 'Monthly salary deposit',   'REF-020-0301', 59585.00, 'Online', 0),
(20, 'Payment',    3200.00, '2025-03-15 09:00:00', 'CMHC Mortgage',       NULL, 'Mortgage payment',         'REF-020-0302', 56385.00, 'Online', 0),
(20, 'Deposit',   12000.00, '2025-04-02 08:00:00', NULL,                  NULL, 'Monthly salary deposit',   'REF-020-0401', 68385.00, 'Online', 0),
(20, 'Payment',    3200.00, '2025-04-15 09:00:00', 'CMHC Mortgage',       NULL, 'Mortgage payment',         'REF-020-0402', 65185.00, 'Online', 0),
(20, 'Deposit',   12000.00, '2025-05-02 08:00:00', NULL,                  NULL, 'Monthly salary deposit',   'REF-020-0501', 77185.00, 'Online', 0),
(20, 'Payment',    3200.00, '2025-05-15 09:00:00', 'CMHC Mortgage',       NULL, 'Mortgage payment',         'REF-020-0502', 73985.00, 'Online', 0);
GO

-- ---- Jennifer Park (account_id=30, Chequing RZ-500-0030) ----
INSERT INTO transactions (account_id, transaction_type, amount, transaction_date, merchant_name, category_id, description, reference_number, balance_after, channel, is_flagged)
VALUES
(30, 'Deposit',    9500.00, '2025-01-02 08:00:00', NULL,              NULL, 'Monthly salary deposit',   'REF-030-0101', 32300.00, 'Online', 0),
(30, 'Payment',    2800.00, '2025-01-15 09:00:00', 'Condo Corp',      NULL, 'Condo mortgage payment',   'REF-030-0102', 29500.00, 'Online', 0),
(30, 'Payment',     280.40, '2025-01-19 12:00:00', 'Whole Foods',     1,   'Organic grocery',          'REF-030-0103', 29219.60, 'POS',    0),
(30, 'Payment',     175.00, '2025-01-30 20:00:00', 'Soul Yoga Studio',5,   'Monthly yoga membership',  'REF-030-0104', 29044.60, 'Online', 0),
(30, 'Deposit',    9500.00, '2025-02-03 08:00:00', NULL,              NULL, 'Monthly salary deposit',   'REF-030-0201', 38544.60, 'Online', 0),
(30, 'Payment',    2800.00, '2025-02-15 09:00:00', 'Condo Corp',      NULL, 'Condo mortgage payment',   'REF-030-0202', 35744.60, 'Online', 0),
(30, 'Payment',     312.80, '2025-02-24 14:00:00', 'Nordstrom',       7,   'Clothing purchase',        'REF-030-0203', 35431.80, 'POS',    0),
(30, 'Deposit',    9500.00, '2025-03-03 08:00:00', NULL,              NULL, 'Monthly salary deposit',   'REF-030-0301', 44931.80, 'Online', 0),
(30, 'Payment',    2800.00, '2025-03-15 09:00:00', 'Condo Corp',      NULL, 'Condo mortgage payment',   'REF-030-0302', 42131.80, 'Online', 0),
(30, 'Payment',     540.00, '2025-03-29 11:00:00', 'Ryerson CE',      9,   'Continuing education',     'REF-030-0303', 41591.80, 'Online', 0),
(30, 'Deposit',    9500.00, '2025-04-02 08:00:00', NULL,              NULL, 'Monthly salary deposit',   'REF-030-0401', 51091.80, 'Online', 0),
(30, 'Payment',    2800.00, '2025-04-15 09:00:00', 'Condo Corp',      NULL, 'Condo mortgage payment',   'REF-030-0402', 48291.80, 'Online', 0),
(30, 'Deposit',    9500.00, '2025-05-02 08:00:00', NULL,              NULL, 'Monthly salary deposit',   'REF-030-0501', 57791.80, 'Online', 0),
(30, 'Payment',    2800.00, '2025-05-15 09:00:00', 'Condo Corp',      NULL, 'Condo mortgage payment',   'REF-030-0502', 54991.80, 'Online', 0);
GO

-- ---- Gurpreet Singh (account_id=25, Chequing RZ-400-0025) ----
INSERT INTO transactions (account_id, transaction_type, amount, transaction_date, merchant_name, category_id, description, reference_number, balance_after, channel, is_flagged)
VALUES
(25, 'Deposit',   5500.00, '2025-01-02 08:00:00', NULL,             NULL, 'Monthly salary deposit',   'REF-025-0101', 14400.00, 'Online', 0),
(25, 'Payment',   1400.00, '2025-01-15 09:00:00', 'Landlord Corp',  NULL, 'January rent',             'REF-025-0102', 13000.00, 'Online', 0),
(25, 'Payment',    198.00, '2025-01-23 11:00:00', 'Chalo FreshCo',  1,   'Grocery run',              'REF-025-0103', 12802.00, 'POS',    0),
(25, 'Deposit',   5500.00, '2025-02-03 08:00:00', NULL,             NULL, 'Monthly salary deposit',   'REF-025-0201', 18302.00, 'Online', 0),
(25, 'Payment',   1400.00, '2025-02-15 09:00:00', 'Landlord Corp',  NULL, 'February rent',            'REF-025-0202', 16902.00, 'Online', 0),
(25, 'Payment',     95.00, '2025-02-28 17:00:00', 'GO Transit',     2,   'Monthly transit pass',     'REF-025-0203', 16807.00, 'POS',    0),
(25, 'Deposit',   5500.00, '2025-03-03 08:00:00', NULL,             NULL, 'Monthly salary deposit',   'REF-025-0301', 22307.00, 'Online', 0),
(25, 'Payment',   1400.00, '2025-03-15 09:00:00', 'Landlord Corp',  NULL, 'March rent',               'REF-025-0302', 20907.00, 'Online', 0),
(25, 'Deposit',   5500.00, '2025-04-02 08:00:00', NULL,             NULL, 'Monthly salary deposit',   'REF-025-0401', 26407.00, 'Online', 0),
(25, 'Payment',   1400.00, '2025-04-15 09:00:00', 'Landlord Corp',  NULL, 'April rent',               'REF-025-0402', 25007.00, 'Online', 0),
(25, 'Deposit',   5500.00, '2025-05-02 08:00:00', NULL,             NULL, 'Monthly salary deposit',   'REF-025-0501', 30507.00, 'Online', 0),
(25, 'Payment',   1400.00, '2025-05-15 09:00:00', 'Landlord Corp',  NULL, 'May rent',                 'REF-025-0502', 29107.00, 'Online', 0);
GO

-- Misc transactions to reach ~120 total: Kevin Nguyen (16), Mei Zhang (22), Omar Farouk (35)
INSERT INTO transactions (account_id, transaction_type, amount, transaction_date, merchant_name, category_id, description, reference_number, balance_after, channel, is_flagged)
VALUES
(16, 'Deposit',   6200.00, '2025-01-02 08:00:00', NULL,              NULL, 'Monthly salary deposit',   'REF-016-0101', 18950.00, 'Online', 0),
(16, 'Payment',   1750.00, '2025-01-15 09:00:00', 'Landlord Corp',   NULL, 'January rent',             'REF-016-0102', 17200.00, 'Online', 0),
(16, 'Payment',    220.10, '2025-01-25 14:00:00', 'Sobeys',          1,   'Grocery run',              'REF-016-0103', 16979.90, 'POS',    0),
(16, 'Deposit',   6200.00, '2025-02-03 08:00:00', NULL,              NULL, 'Monthly salary deposit',   'REF-016-0201', 23179.90, 'Online', 0),
(16, 'Payment',   1750.00, '2025-02-15 09:00:00', 'Landlord Corp',   NULL, 'February rent',            'REF-016-0202', 21429.90, 'Online', 0),
(16, 'Deposit',   6200.00, '2025-03-03 08:00:00', NULL,              NULL, 'Monthly salary deposit',   'REF-016-0301', 27629.90, 'Online', 0),
(16, 'Payment',   1750.00, '2025-03-15 09:00:00', 'Landlord Corp',   NULL, 'March rent',               'REF-016-0302', 25879.90, 'Online', 0),
(22, 'Deposit',   5800.00, '2025-01-03 08:00:00', NULL,              NULL, 'Monthly salary deposit',   'REF-022-0101', 13000.00, 'Online', 0),
(22, 'Payment',   1600.00, '2025-01-15 09:00:00', 'Landlord Corp',   NULL, 'January rent',             'REF-022-0102', 11400.00, 'Online', 0),
(22, 'Payment',    145.80, '2025-01-22 12:00:00', 'T&T Supermarket', 1,   'Grocery shopping',         'REF-022-0103', 11254.20, 'POS',    0),
(22, 'Deposit',   5800.00, '2025-02-03 08:00:00', NULL,              NULL, 'Monthly salary deposit',   'REF-022-0201', 17054.20, 'Online', 0),
(22, 'Payment',   1600.00, '2025-02-15 09:00:00', 'Landlord Corp',   NULL, 'February rent',            'REF-022-0202', 15454.20, 'Online', 0),
(22, 'Deposit',   5800.00, '2025-03-03 08:00:00', NULL,              NULL, 'Monthly salary deposit',   'REF-022-0301', 21254.20, 'Online', 0),
(22, 'Payment',   1600.00, '2025-03-15 09:00:00', 'Landlord Corp',   NULL, 'March rent',               'REF-022-0302', 19654.20, 'Online', 0),
(35, 'Deposit',   8800.00, '2025-01-02 08:00:00', NULL,              NULL, 'Monthly salary deposit',   'REF-035-0101', 28500.00, 'Online', 0),
(35, 'Payment',   2100.00, '2025-01-15 09:00:00', 'Landlord Corp',   NULL, 'January rent',             'REF-035-0102', 26400.00, 'Online', 0),
(35, 'Payment',    340.00, '2025-01-27 15:00:00', 'Esso',            2,   'Gas fill-up',              'REF-035-0103', 26060.00, 'POS',    0),
(35, 'Deposit',   8800.00, '2025-02-03 08:00:00', NULL,              NULL, 'Monthly salary deposit',   'REF-035-0201', 34860.00, 'Online', 0),
(35, 'Payment',   2100.00, '2025-02-15 09:00:00', 'Landlord Corp',   NULL, 'February rent',            'REF-035-0202', 32760.00, 'Online', 0),
(35, 'Payment',    185.50, '2025-02-22 11:30:00', 'Farm Boy',        1,   'Grocery run',              'REF-035-0203', 32574.50, 'POS',    0),
(35, 'Deposit',   8800.00, '2025-03-03 08:00:00', NULL,              NULL, 'Monthly salary deposit',   'REF-035-0301', 41374.50, 'Online', 0),
(35, 'Payment',   2100.00, '2025-03-15 09:00:00', 'Landlord Corp',   NULL, 'March rent',               'REF-035-0302', 39274.50, 'Online', 0),
(35, 'Payment',    225.00, '2025-03-30 14:00:00', 'Best Buy',        7,   'Electronics',              'REF-035-0303', 39049.50, 'POS',    0),
(35, 'Deposit',   8800.00, '2025-04-02 08:00:00', NULL,              NULL, 'Monthly salary deposit',   'REF-035-0401', 47849.50, 'Online', 0),
(35, 'Payment',   2100.00, '2025-04-15 09:00:00', 'Landlord Corp',   NULL, 'April rent',               'REF-035-0402', 45749.50, 'Online', 0),
(35, 'Deposit',   8800.00, '2025-05-02 08:00:00', NULL,              NULL, 'Monthly salary deposit',   'REF-035-0501', 54549.50, 'Online', 0),
(35, 'Payment',   2100.00, '2025-05-15 09:00:00', 'Landlord Corp',   NULL, 'May rent',                 'REF-035-0502', 52449.50, 'Online', 0);
GO

-- ============================================================
-- 6. FRAUD ALERTS  (for the 3 suspicious transactions)
--    Suspicious transaction_ids: REF-001-0105 (~txn 5),
--    REF-005-0203 (~txn 32), REF-010-0203 (~txn 46)
--    We reference by matching reference_number subquery.
-- ============================================================
INSERT INTO fraud_alerts (transaction_id, alert_type, alert_reason, severity, created_at, is_resolved)
SELECT transaction_id,
       'Large Transaction',
       'ATM cash withdrawal of $15,000 at 1:03 AM — amount exceeds 3x account 90-day average and is classified as a large transaction.',
       'Critical',
       '2025-01-22 01:03:45',
       0
FROM   transactions WHERE reference_number = 'REF-001-0105';

INSERT INTO fraud_alerts (transaction_id, alert_type, alert_reason, severity, created_at, is_resolved)
SELECT transaction_id,
       'After-Hours Activity',
       'Payment of $4,200 to Unknown Vendor processed at 3:12 AM — unrecognised payee combined with after-hours timing triggers medium-severity alert.',
       'High',
       '2025-02-21 03:12:30',
       0
FROM   transactions WHERE reference_number = 'REF-005-0203';

INSERT INTO fraud_alerts (transaction_id, alert_type, alert_reason, severity, created_at, is_resolved)
SELECT transaction_id,
       'After-Hours Activity',
       'ATM withdrawal of $2,800 at 2:48 AM — after-hours large ATM withdrawal significantly above customer average.',
       'Medium',
       '2025-02-18 02:48:15',
       0
FROM   transactions WHERE reference_number = 'REF-010-0203';
GO

-- ============================================================
-- 7. LOANS  (8 loans across various customers)
-- ============================================================
INSERT INTO loans (customer_id, branch_id, loan_type, principal_amount, interest_rate, term_months, monthly_payment, start_date, end_date, outstanding_balance, status)
VALUES
    -- Mortgage – David Patel (4), Branch 1
    (4,  1, 'Mortgage',   650000.00, 0.0545, 300,  3942.00, '2020-09-01', '2045-09-01', 598400.00, 'Active'),
    -- Mortgage – Robert MacDonald (10), Branch 3
    (10, 3, 'Mortgage',   520000.00, 0.0499, 300,  2995.00, '2018-06-01', '2043-06-01', 454200.00, 'Active'),
    -- Auto – Michael Chen (1), Branch 1
    (1,  1, 'Auto',        35000.00, 0.0699, 60,     691.00, '2023-01-15', '2028-01-15',  25800.00, 'Active'),
    -- Auto – Gurpreet Singh (13), Branch 4
    (13, 4, 'Auto',        28000.00, 0.0749, 60,     561.00, '2022-08-01', '2027-08-01',  17640.00, 'Active'),
    -- Personal – Amara Okonkwo (3), Branch 1
    (3,  1, 'Personal',    15000.00, 0.0999, 48,     380.00, '2023-06-01', '2027-06-01',  10920.00, 'Active'),
    -- Personal – Priya Sharma (5), Branch 2
    (5,  2, 'Personal',     8000.00, 0.1199, 36,     266.00, '2024-01-01', '2027-01-01',   6650.00, 'Active'),
    -- Student – Emily Tremblay (18), Branch 5
    (18, 5, 'Student',     22000.00, 0.0550, 120,    238.00, '2022-09-01', '2032-09-01',  18240.00, 'Active'),
    -- Personal – Aisha Mohammed (9), Branch 3 – Delinquent
    (9,  3, 'Personal',     5000.00, 0.1299, 24,     238.00, '2023-10-01', '2025-10-01',   2860.00, 'Delinquent');
GO

-- ============================================================
-- 8. LOAN PAYMENTS  (15 payments, 3 late)
-- ============================================================
INSERT INTO loan_payments (loan_id, payment_date, scheduled_date, amount_paid, principal_paid, interest_paid, balance_after, is_late, days_late)
VALUES
    -- Loan 1 (Patel Mortgage) – 3 on-time payments
    (1, '2025-01-02', '2025-01-01',  3942.00, 646.85, 3295.15, 597753.15, 0,  0),
    (1, '2025-02-03', '2025-02-01',  3942.00, 650.44, 3291.56, 597102.71, 0,  0),
    (1, '2025-03-03', '2025-03-01',  3942.00, 654.05, 3287.95, 596448.66, 0,  0),
    -- Loan 2 (MacDonald Mortgage) – 2 on-time
    (2, '2025-01-02', '2025-01-01',  2995.00, 809.58, 2185.42, 453390.42, 0,  0),
    (2, '2025-02-03', '2025-02-01',  2995.00, 813.36, 2181.64, 452577.06, 0,  0),
    -- Loan 3 (Chen Auto) – on-time
    (3, '2025-01-15', '2025-01-15',   691.00, 541.98,  149.02,  25258.02, 0,  0),
    (3, '2025-02-15', '2025-02-15',   691.00, 545.16,  145.84,  24712.86, 0,  0),
    -- Loan 4 (Singh Auto) – on-time then late
    (4, '2025-01-01', '2025-01-01',   561.00, 385.92,  175.08,  17254.08, 0,  0),
    (4, '2025-02-14', '2025-02-01',   561.00, 388.33,  172.67,  16865.75, 1, 13),  -- 13 days late
    -- Loan 5 (Okonkwo Personal) – on-time
    (5, '2025-01-01', '2025-01-01',   380.00, 254.05,  125.95,  10665.95, 0,  0),
    (5, '2025-02-01', '2025-02-01',   380.00, 256.58,  123.42,  10409.37, 0,  0),
    -- Loan 6 (Sharma Personal) – late payment
    (6, '2025-01-22', '2025-01-01',   266.00, 199.67,   66.33,   6450.33, 1, 21),  -- 21 days late
    -- Loan 7 (Tremblay Student) – on-time
    (7, '2025-01-01', '2025-01-01',   238.00, 154.50,   83.50,  18085.50, 0,  0),
    -- Loan 8 (Mohammed Personal Delinquent) – severely late
    (8, '2025-01-01', '2024-11-01',   238.00, 163.30,   74.70,   2696.70, 1, 61),  -- 61 days late
    (8, '2025-02-15', '2025-01-01',   238.00, 165.34,   72.66,   2531.36, 1, 45);  -- 45 days late
GO

PRINT N'Rutzfin seed data loaded successfully.';
GO
