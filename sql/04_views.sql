-- ============================================================
-- Rutzfin: Banking Transaction Intelligence Platform
-- FILE: 04_views.sql
-- PURPOSE: Analytical views for dashboard and reporting layers
-- PLATFORM: Azure SQL / T-SQL
-- ============================================================

SET NOCOUNT ON;
GO

-- ============================================================
-- VIEW 1: vw_CustomerAccountSummary
-- Full customer-account picture with last transaction details,
-- MTD outflow, and lifetime deposit/withdrawal totals.
-- Used by: customer list page, account detail screens.
-- ============================================================
CREATE OR ALTER VIEW vw_CustomerAccountSummary
AS
SELECT
    -- Customer columns
    c.customer_id,
    c.first_name,
    c.last_name,
    c.first_name + N' ' + c.last_name   AS customer_name,
    c.email,
    c.phone                              AS customer_phone,
    c.credit_score,
    c.join_date,
    c.city                               AS customer_city,
    c.province                           AS customer_province,

    -- Account columns
    a.account_id,
    a.account_number,
    a.account_type,
    a.balance                            AS current_balance,
    a.interest_rate,
    a.status                             AS account_status,
    a.opened_date                        AS account_opened_date,

    -- Branch columns
    b.branch_id,
    b.branch_name,
    b.city                               AS branch_city,

    -- Most recent transaction (OUTER APPLY = NULL-safe if no transactions)
    last_txn.transaction_id              AS last_txn_id,
    last_txn.transaction_type            AS last_txn_type,
    last_txn.amount                      AS last_txn_amount,
    last_txn.transaction_date            AS last_txn_date,
    last_txn.merchant_name               AS last_txn_merchant,
    last_txn.channel                     AS last_txn_channel,

    -- Month-to-date outflow (Payments + Withdrawals + Fees + Transfer_Out)
    ISNULL(mtd.mtd_outflow, 0.00)        AS mtd_outflow,
    ISNULL(mtd.mtd_txn_count, 0)         AS mtd_txn_count,

    -- Lifetime totals
    ISNULL(life.lifetime_deposits, 0.00)     AS lifetime_deposits,
    ISNULL(life.lifetime_withdrawals, 0.00)  AS lifetime_withdrawals

FROM accounts           a
JOIN customers          c  ON c.customer_id = a.customer_id
JOIN branches           b  ON b.branch_id   = a.branch_id

-- Last transaction per account
OUTER APPLY (
    SELECT TOP 1
        t.transaction_id,
        t.transaction_type,
        t.amount,
        t.transaction_date,
        t.merchant_name,
        t.channel
    FROM   transactions t
    WHERE  t.account_id = a.account_id
    ORDER  BY t.transaction_date DESC
) AS last_txn

-- Month-to-date outflow
OUTER APPLY (
    SELECT
        SUM(CASE WHEN t.transaction_type IN ('Payment','Withdrawal','Fee','Transfer_Out')
                 THEN t.amount ELSE 0 END)      AS mtd_outflow,
        COUNT(*)                                AS mtd_txn_count
    FROM   transactions t
    WHERE  t.account_id     = a.account_id
      AND  t.transaction_date >= DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
      AND  t.transaction_date <  DATEADD(MONTH, 1,
               DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1))
) AS mtd

-- Lifetime totals
OUTER APPLY (
    SELECT
        SUM(CASE WHEN t.transaction_type IN ('Deposit','Transfer_In','Interest')
                 THEN t.amount ELSE 0 END)      AS lifetime_deposits,
        SUM(CASE WHEN t.transaction_type IN ('Payment','Withdrawal','Fee','Transfer_Out')
                 THEN t.amount ELSE 0 END)      AS lifetime_withdrawals
    FROM   transactions t
    WHERE  t.account_id = a.account_id
) AS life

WHERE  c.is_active = 1
  AND  a.status    = 'Active';
GO

-- ============================================================
-- VIEW 2: vw_BranchPerformance
-- Branch-level KPIs: account mix, deposits on hand, transaction
-- volume, loan book, and open fraud alert count.
-- Used by: branch performance dashboard, regional reporting.
-- ============================================================
CREATE OR ALTER VIEW vw_BranchPerformance
AS
SELECT
    br.branch_id,
    br.branch_name,
    br.city,
    br.province,
    br.is_active,

    -- Account counts
    COUNT(DISTINCT a.account_id)                                           AS total_accounts,
    COUNT(DISTINCT a.customer_id)                                          AS total_customers,

    -- Deposits on hand (sum of active balances)
    ISNULL(SUM(CASE WHEN a.status = 'Active' THEN a.balance ELSE 0 END), 0)
                                                                           AS total_deposits_on_hand,

    -- Balance by product type
    ISNULL(SUM(CASE WHEN a.account_type = 'Chequing' AND a.status = 'Active'
                    THEN a.balance ELSE 0 END), 0)                         AS chequing_balance,
    ISNULL(SUM(CASE WHEN a.account_type = 'Savings'  AND a.status = 'Active'
                    THEN a.balance ELSE 0 END), 0)                         AS savings_balance,
    ISNULL(SUM(CASE WHEN a.account_type = 'TFSA'     AND a.status = 'Active'
                    THEN a.balance ELSE 0 END), 0)                         AS tfsa_balance,
    ISNULL(SUM(CASE WHEN a.account_type = 'RRSP'     AND a.status = 'Active'
                    THEN a.balance ELSE 0 END), 0)                         AS rrsp_balance,

    -- Transaction activity
    COUNT(DISTINCT t.transaction_id)                                       AS total_transactions,
    ISNULL(SUM(CASE WHEN t.transaction_type IN ('Deposit','Transfer_In','Interest')
                    THEN t.amount ELSE 0 END), 0)                          AS total_inflows,
    ISNULL(SUM(CASE WHEN t.transaction_type IN ('Payment','Withdrawal','Fee','Transfer_Out')
                    THEN t.amount ELSE 0 END), 0)                          AS total_outflows,

    -- Loan portfolio
    COUNT(DISTINCT CASE WHEN l.status = 'Active' THEN l.loan_id END)      AS active_loans,
    ISNULL(SUM(CASE WHEN l.status = 'Active' THEN l.outstanding_balance
                    ELSE 0 END), 0)                                        AS total_loan_balance,

    -- Fraud queue
    COUNT(DISTINCT CASE WHEN fa.is_resolved = 0 THEN fa.alert_id END)     AS open_fraud_alerts

FROM   branches        br
LEFT  JOIN accounts    a   ON a.branch_id      = br.branch_id
LEFT  JOIN transactions t  ON t.account_id     = a.account_id
LEFT  JOIN loans        l  ON l.branch_id      = br.branch_id
LEFT  JOIN fraud_alerts fa ON fa.transaction_id = t.transaction_id

GROUP BY
    br.branch_id,
    br.branch_name,
    br.city,
    br.province,
    br.is_active;
GO

-- ============================================================
-- VIEW 3: vw_FraudAlertQueue
-- Unresolved fraud alerts enriched with full transaction and
-- customer context, plus a ratio of the flagged amount vs the
-- customer's average transaction on that account.
-- Used by: fraud operations queue, analyst dashboard.
-- ============================================================
CREATE OR ALTER VIEW vw_FraudAlertQueue
AS
SELECT
    fa.alert_id,
    fa.alert_type,
    fa.alert_reason,
    fa.severity,
    fa.created_at,

    -- Transaction detail
    t.transaction_id,
    t.transaction_type,
    t.amount                             AS flagged_amount,
    t.transaction_date,
    t.merchant_name,
    t.channel,
    t.reference_number,
    t.balance_after,

    -- Account detail
    a.account_id,
    a.account_number,
    a.account_type,
    a.balance                            AS current_balance,

    -- Customer detail
    c.customer_id,
    c.first_name + N' ' + c.last_name   AS customer_name,
    c.email,
    c.credit_score,

    -- Branch detail
    b.branch_id,
    b.branch_name,
    b.city                               AS branch_city,

    -- Average transaction context for this account
    avg_txn.avg_transaction_amount,
    avg_txn.transaction_count_90d,

    -- How many multiples of the average is the flagged amount?
    ROUND(t.amount / NULLIF(avg_txn.avg_transaction_amount, 0), 2)
                                         AS amount_vs_avg_ratio

FROM   fraud_alerts    fa
JOIN   transactions    t   ON t.transaction_id  = fa.transaction_id
JOIN   accounts        a   ON a.account_id      = t.account_id
JOIN   customers       c   ON c.customer_id     = a.customer_id
JOIN   branches        b   ON b.branch_id       = a.branch_id

-- 90-day average for the flagged account
CROSS APPLY (
    SELECT
        ROUND(AVG(h.amount), 2)  AS avg_transaction_amount,
        COUNT(*)                 AS transaction_count_90d
    FROM   transactions h
    WHERE  h.account_id      = t.account_id
      AND  h.transaction_date >= DATEADD(DAY, -90, t.transaction_date)
      AND  h.transaction_id  <> t.transaction_id   -- exclude the flagged txn itself
) AS avg_txn

WHERE  fa.is_resolved = 0;
GO

-- ============================================================
-- VIEW 4: vw_LoanHealthDashboard
-- Loan portfolio with payment history stats and a computed
-- risk rating based on delinquency depth.
-- Used by: risk management, collections, exec dashboard.
-- ============================================================
CREATE OR ALTER VIEW vw_LoanHealthDashboard
AS
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
    l.status                             AS loan_status,

    -- Customer
    c.customer_id,
    c.first_name + N' ' + c.last_name   AS customer_name,
    c.credit_score,

    -- Branch
    b.branch_id,
    b.branch_name,

    -- Payment history stats
    pmts.total_payments,
    pmts.late_payments,
    pmts.max_days_late,
    pmts.total_interest_paid,

    -- Derived risk metrics
    CASE
        WHEN pmts.late_payments  = 0                            THEN 'Low'
        WHEN pmts.max_days_late BETWEEN 1  AND 14              THEN 'Medium'
        WHEN pmts.max_days_late BETWEEN 15 AND 30              THEN 'High'
        WHEN pmts.max_days_late >  30                          THEN 'Critical'
        ELSE 'Low'
    END                                  AS risk_rating,

    -- Percent of principal repaid
    ROUND(
        100.0 * (l.principal_amount - l.outstanding_balance)
              /  NULLIF(l.principal_amount, 0),
        2)                               AS pct_paid_off,

    -- Months remaining based on end_date vs today
    DATEDIFF(MONTH, CAST(GETDATE() AS DATE), l.end_date)
                                         AS months_remaining

FROM   loans       l
JOIN   customers   c  ON c.customer_id = l.customer_id
JOIN   branches    b  ON b.branch_id   = l.branch_id

OUTER APPLY (
    SELECT
        COUNT(*)                                   AS total_payments,
        SUM(CASE WHEN lp.is_late = 1 THEN 1 ELSE 0 END)
                                                   AS late_payments,
        ISNULL(MAX(lp.days_late), 0)               AS max_days_late,
        ISNULL(SUM(lp.interest_paid), 0.00)        AS total_interest_paid
    FROM   loan_payments lp
    WHERE  lp.loan_id = l.loan_id
) AS pmts;
GO

-- ============================================================
-- VIEW 5: vw_MonthlyTransactionSummary
-- Monthly aggregates per account with inflow/outflow split,
-- volume, and flagged transaction counts.
-- Used by: trend analysis, customer statements, BI layer.
-- ============================================================
CREATE OR ALTER VIEW vw_MonthlyTransactionSummary
AS
SELECT
    -- Dimension keys
    a.account_id,
    a.account_number,
    a.account_type,
    c.customer_id,
    c.first_name + N' ' + c.last_name   AS customer_name,
    b.branch_id,
    b.branch_name,

    -- Time dimensions
    YEAR(t.transaction_date)             AS txn_year,
    MONTH(t.transaction_date)            AS txn_month,
    DATEFROMPARTS(
        YEAR(t.transaction_date),
        MONTH(t.transaction_date),
        1)                               AS month_start,

    -- Volume metrics
    COUNT(*)                             AS transaction_count,
    SUM(t.amount)                        AS total_volume,
    ROUND(AVG(t.amount), 2)             AS avg_transaction,

    -- Inflow: Deposits, Transfer_In, Interest
    SUM(CASE WHEN t.transaction_type IN ('Deposit','Transfer_In','Interest')
             THEN t.amount ELSE 0 END)   AS total_inflow,

    -- Outflow: Payments, Withdrawals, Fees, Transfer_Out
    SUM(CASE WHEN t.transaction_type IN ('Payment','Withdrawal','Fee','Transfer_Out')
             THEN t.amount ELSE 0 END)   AS total_outflow,

    -- Fraud
    SUM(CAST(t.is_flagged AS INT))       AS flagged_count

FROM   transactions   t
JOIN   accounts       a  ON a.account_id   = t.account_id
JOIN   customers      c  ON c.customer_id  = a.customer_id
JOIN   branches       b  ON b.branch_id    = a.branch_id

GROUP BY
    a.account_id,
    a.account_number,
    a.account_type,
    c.customer_id,
    c.first_name + N' ' + c.last_name,
    b.branch_id,
    b.branch_name,
    YEAR(t.transaction_date),
    MONTH(t.transaction_date),
    DATEFROMPARTS(
        YEAR(t.transaction_date),
        MONTH(t.transaction_date),
        1);
GO

PRINT N'Rutzfin: 5 analytical views created successfully.';
GO
