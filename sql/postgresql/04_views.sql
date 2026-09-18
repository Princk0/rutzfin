-- ============================================================
-- Rutzfin: Banking Transaction Intelligence Platform
-- FILE: 04_views.sql  (PostgreSQL version)
-- Key conversions from T-SQL:
--   • OUTER APPLY (SELECT TOP 1 ...) → LEFT JOIN LATERAL (... LIMIT 1) ON TRUE
--   • CROSS APPLY (...)              → CROSS JOIN LATERAL (...) AS alias
--   • ISNULL(x, y)                   → COALESCE(x, y)
--   • GETDATE()                      → NOW()
--   • DATEFROMPARTS(Y,M,1)           → DATE_TRUNC('month', NOW())
--   • DATEADD(DAY, -N, x)            → x - INTERVAL 'N days'
--   • YEAR(x) / MONTH(x)             → EXTRACT(YEAR/MONTH FROM x)::INT
--   • x + N' ' + y  (concat)         → x || ' ' || y
--   • CAST(bit AS INT)               → bit::INT
--   • DATEDIFF(MONTH, today, end)    → year/month arithmetic
--   • CREATE OR ALTER VIEW           → CREATE OR REPLACE VIEW
--   • is_active = 1 / is_resolved = 0 / is_late = 1 → TRUE / FALSE
-- ============================================================

-- ============================================================
-- VIEW 1: vw_CustomerAccountSummary
-- ============================================================
CREATE OR REPLACE VIEW vw_CustomerAccountSummary AS
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.first_name || ' ' || c.last_name      AS customer_name,
    c.email,
    c.phone                                  AS customer_phone,
    c.credit_score,
    c.join_date,
    c.city                                   AS customer_city,
    c.province                               AS customer_province,

    a.account_id,
    a.account_number,
    a.account_type,
    a.balance                                AS current_balance,
    a.interest_rate,
    a.status                                 AS account_status,
    a.opened_date                            AS account_opened_date,

    b.branch_id,
    b.branch_name,
    b.city                                   AS branch_city,

    last_txn.transaction_id                  AS last_txn_id,
    last_txn.transaction_type                AS last_txn_type,
    last_txn.amount                          AS last_txn_amount,
    last_txn.transaction_date                AS last_txn_date,
    last_txn.merchant_name                   AS last_txn_merchant,
    last_txn.channel                         AS last_txn_channel,

    COALESCE(mtd.mtd_outflow,    0.00)       AS mtd_outflow,
    COALESCE(mtd.mtd_txn_count,  0)          AS mtd_txn_count,

    COALESCE(life.lifetime_deposits,     0.00) AS lifetime_deposits,
    COALESCE(life.lifetime_withdrawals,  0.00) AS lifetime_withdrawals

FROM accounts       a
JOIN customers      c   ON c.customer_id = a.customer_id
JOIN branches       b   ON b.branch_id   = a.branch_id

-- Last transaction per account
LEFT JOIN LATERAL (
    SELECT t.transaction_id, t.transaction_type, t.amount,
           t.transaction_date, t.merchant_name, t.channel
    FROM   transactions t
    WHERE  t.account_id = a.account_id
    ORDER  BY t.transaction_date DESC
    LIMIT  1
) AS last_txn ON TRUE

-- Month-to-date outflow
LEFT JOIN LATERAL (
    SELECT
        SUM(CASE WHEN t.transaction_type IN ('Payment','Withdrawal','Fee','Transfer_Out')
                 THEN t.amount ELSE 0 END)  AS mtd_outflow,
        COUNT(*)                            AS mtd_txn_count
    FROM   transactions t
    WHERE  t.account_id      = a.account_id
      AND  t.transaction_date >= DATE_TRUNC('month', NOW())
      AND  t.transaction_date <  DATE_TRUNC('month', NOW()) + INTERVAL '1 month'
) AS mtd ON TRUE

-- Lifetime totals
LEFT JOIN LATERAL (
    SELECT
        SUM(CASE WHEN t.transaction_type IN ('Deposit','Transfer_In','Interest')
                 THEN t.amount ELSE 0 END)  AS lifetime_deposits,
        SUM(CASE WHEN t.transaction_type IN ('Payment','Withdrawal','Fee','Transfer_Out')
                 THEN t.amount ELSE 0 END)  AS lifetime_withdrawals
    FROM   transactions t
    WHERE  t.account_id = a.account_id
) AS life ON TRUE

WHERE  c.is_active = TRUE
  AND  a.status    = 'Active';

-- ============================================================
-- VIEW 2: vw_BranchPerformance
-- ============================================================
CREATE OR REPLACE VIEW vw_BranchPerformance AS
SELECT
    br.branch_id,
    br.branch_name,
    br.city,
    br.province,
    br.is_active,

    COUNT(DISTINCT a.account_id)                                             AS total_accounts,
    COUNT(DISTINCT a.customer_id)                                            AS total_customers,

    COALESCE(SUM(CASE WHEN a.status = 'Active' THEN a.balance ELSE 0 END), 0)
                                                                             AS total_deposits_on_hand,

    COALESCE(SUM(CASE WHEN a.account_type = 'Chequing' AND a.status = 'Active'
                      THEN a.balance ELSE 0 END), 0)                         AS chequing_balance,
    COALESCE(SUM(CASE WHEN a.account_type = 'Savings'  AND a.status = 'Active'
                      THEN a.balance ELSE 0 END), 0)                         AS savings_balance,
    COALESCE(SUM(CASE WHEN a.account_type = 'TFSA'     AND a.status = 'Active'
                      THEN a.balance ELSE 0 END), 0)                         AS tfsa_balance,
    COALESCE(SUM(CASE WHEN a.account_type = 'RRSP'     AND a.status = 'Active'
                      THEN a.balance ELSE 0 END), 0)                         AS rrsp_balance,

    COUNT(DISTINCT t.transaction_id)                                         AS total_transactions,
    COALESCE(SUM(CASE WHEN t.transaction_type IN ('Deposit','Transfer_In','Interest')
                      THEN t.amount ELSE 0 END), 0)                          AS total_inflows,
    COALESCE(SUM(CASE WHEN t.transaction_type IN ('Payment','Withdrawal','Fee','Transfer_Out')
                      THEN t.amount ELSE 0 END), 0)                          AS total_outflows,

    COUNT(DISTINCT CASE WHEN l.status = 'Active' THEN l.loan_id END)        AS active_loans,
    COALESCE(SUM(CASE WHEN l.status = 'Active' THEN l.outstanding_balance
                      ELSE 0 END), 0)                                        AS total_loan_balance,

    COUNT(DISTINCT CASE WHEN NOT fa.is_resolved THEN fa.alert_id END)       AS open_fraud_alerts

FROM   branches        br
LEFT  JOIN accounts    a   ON a.branch_id      = br.branch_id
LEFT  JOIN transactions t  ON t.account_id     = a.account_id
LEFT  JOIN loans        l  ON l.branch_id      = br.branch_id
LEFT  JOIN fraud_alerts fa ON fa.transaction_id = t.transaction_id

GROUP BY
    br.branch_id, br.branch_name, br.city, br.province, br.is_active;

-- ============================================================
-- VIEW 3: vw_FraudAlertQueue
-- ============================================================
CREATE OR REPLACE VIEW vw_FraudAlertQueue AS
SELECT
    fa.alert_id,
    fa.alert_type,
    fa.alert_reason,
    fa.severity,
    fa.created_at,

    t.transaction_id,
    t.transaction_type,
    t.amount                                AS flagged_amount,
    t.transaction_date,
    t.merchant_name,
    t.channel,
    t.reference_number,
    t.balance_after,

    a.account_id,
    a.account_number,
    a.account_type,
    a.balance                               AS current_balance,

    c.customer_id,
    c.first_name || ' ' || c.last_name      AS customer_name,
    c.email,
    c.credit_score,

    b.branch_id,
    b.branch_name,
    b.city                                  AS branch_city,

    avg_txn.avg_transaction_amount,
    avg_txn.transaction_count_90d,

    ROUND((t.amount / NULLIF(avg_txn.avg_transaction_amount, 0))::NUMERIC, 2)
                                            AS amount_vs_avg_ratio

FROM   fraud_alerts    fa
JOIN   transactions    t   ON t.transaction_id  = fa.transaction_id
JOIN   accounts        a   ON a.account_id      = t.account_id
JOIN   customers       c   ON c.customer_id     = a.customer_id
JOIN   branches        b   ON b.branch_id       = a.branch_id

CROSS JOIN LATERAL (
    SELECT
        ROUND(AVG(h.amount)::NUMERIC, 2)  AS avg_transaction_amount,
        COUNT(*)                           AS transaction_count_90d
    FROM   transactions h
    WHERE  h.account_id      = t.account_id
      AND  h.transaction_date >= t.transaction_date - INTERVAL '90 days'
      AND  h.transaction_id  <> t.transaction_id
) AS avg_txn

WHERE NOT fa.is_resolved;

-- ============================================================
-- VIEW 4: vw_LoanHealthDashboard
-- ============================================================
CREATE OR REPLACE VIEW vw_LoanHealthDashboard AS
SELECT
    l.loan_id,
    l.loan_type,
    l.principal_amount,
    l.interest_rate,
    l.term_months,
    l.monthly_payment,
    l.start_date,
    l.end_date,
    l.outstanding_balance,
    l.status                                AS loan_status,

    c.customer_id,
    c.first_name || ' ' || c.last_name      AS customer_name,
    c.credit_score,

    b.branch_id,
    b.branch_name,

    pmts.total_payments,
    pmts.late_payments,
    pmts.max_days_late,
    pmts.total_interest_paid,

    CASE
        WHEN pmts.late_payments  = 0                   THEN 'Low'
        WHEN pmts.max_days_late BETWEEN 1  AND 14      THEN 'Medium'
        WHEN pmts.max_days_late BETWEEN 15 AND 30      THEN 'High'
        WHEN pmts.max_days_late >  30                  THEN 'Critical'
        ELSE 'Low'
    END                                     AS risk_rating,

    ROUND(
        (100.0 * (l.principal_amount - l.outstanding_balance)
               / NULLIF(l.principal_amount, 0))::NUMERIC,
        2)                                  AS pct_paid_off,

    -- Months remaining: (end_year - today_year)*12 + (end_month - today_month)
    (
        (EXTRACT(YEAR  FROM l.end_date) - EXTRACT(YEAR  FROM CURRENT_DATE))::INT * 12 +
        (EXTRACT(MONTH FROM l.end_date) - EXTRACT(MONTH FROM CURRENT_DATE))::INT
    )                                       AS months_remaining

FROM   loans       l
JOIN   customers   c  ON c.customer_id = l.customer_id
JOIN   branches    b  ON b.branch_id   = l.branch_id

LEFT JOIN LATERAL (
    SELECT
        COUNT(*)                                              AS total_payments,
        SUM(CASE WHEN lp.is_late THEN 1 ELSE 0 END)          AS late_payments,
        COALESCE(MAX(lp.days_late), 0)                        AS max_days_late,
        COALESCE(SUM(lp.interest_paid), 0.00)                 AS total_interest_paid
    FROM   loan_payments lp
    WHERE  lp.loan_id = l.loan_id
) AS pmts ON TRUE;

-- ============================================================
-- VIEW 5: vw_MonthlyTransactionSummary
-- ============================================================
CREATE OR REPLACE VIEW vw_MonthlyTransactionSummary AS
SELECT
    a.account_id,
    a.account_number,
    a.account_type,
    c.customer_id,
    c.first_name || ' ' || c.last_name      AS customer_name,
    b.branch_id,
    b.branch_name,

    EXTRACT(YEAR  FROM t.transaction_date)::INT  AS txn_year,
    EXTRACT(MONTH FROM t.transaction_date)::INT  AS txn_month,
    DATE_TRUNC('month', t.transaction_date)::DATE AS month_start,

    COUNT(*)                                     AS transaction_count,
    SUM(t.amount)                                AS total_volume,
    ROUND(AVG(t.amount)::NUMERIC, 2)             AS avg_transaction,

    SUM(CASE WHEN t.transaction_type IN ('Deposit','Transfer_In','Interest')
             THEN t.amount ELSE 0 END)           AS total_inflow,

    SUM(CASE WHEN t.transaction_type IN ('Payment','Withdrawal','Fee','Transfer_Out')
             THEN t.amount ELSE 0 END)           AS total_outflow,

    SUM(t.is_flagged::INT)                       AS flagged_count

FROM   transactions   t
JOIN   accounts       a  ON a.account_id  = t.account_id
JOIN   customers      c  ON c.customer_id = a.customer_id
JOIN   branches       b  ON b.branch_id   = a.branch_id

GROUP BY
    a.account_id,
    a.account_number,
    a.account_type,
    c.customer_id,
    c.first_name || ' ' || c.last_name,
    b.branch_id,
    b.branch_name,
    EXTRACT(YEAR  FROM t.transaction_date)::INT,
    EXTRACT(MONTH FROM t.transaction_date)::INT,
    DATE_TRUNC('month', t.transaction_date)::DATE;
