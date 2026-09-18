-- ============================================================
-- Rutzfin: Banking Transaction Intelligence Platform
-- FILE: 07_advanced_queries.sql
-- PURPOSE: 10 showcase analytical queries demonstrating
--          advanced T-SQL window functions, CTEs, and
--          statistical techniques for banking intelligence.
-- PLATFORM: Azure SQL / T-SQL
-- ============================================================

SET NOCOUNT ON;
GO

-- ============================================================
-- QUERY 1: Running Balance Per Account
-- Business purpose: Reconstruct the full transaction ledger for
-- any account, showing the exact balance after each event.
-- Useful for statement reconciliation, audit trails, and
-- detecting balance discrepancies against stored balance_after.
-- ============================================================
SELECT
    a.account_id,
    a.account_number,
    a.account_type,
    c.first_name + N' ' + c.last_name          AS customer_name,
    t.transaction_date,
    t.transaction_type,
    t.amount,
    t.merchant_name,
    t.reference_number,
    -- Signed net amount for running balance calculation
    CASE
        WHEN t.transaction_type IN ('Deposit','Transfer_In','Interest')         THEN  t.amount
        WHEN t.transaction_type IN ('Payment','Withdrawal','Fee','Transfer_Out') THEN -t.amount
        ELSE 0
    END                                                     AS net_amount,
    -- Running balance using cumulative SUM window function
    SUM(
        CASE
            WHEN t.transaction_type IN ('Deposit','Transfer_In','Interest')         THEN  t.amount
            WHEN t.transaction_type IN ('Payment','Withdrawal','Fee','Transfer_Out') THEN -t.amount
            ELSE 0
        END
    ) OVER (
        PARTITION BY a.account_id
        ORDER BY     t.transaction_date ASC, t.transaction_id ASC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                                       AS running_balance,
    -- Variance between stored balance_after and computed running balance
    t.balance_after                                         AS stored_balance_after
FROM   transactions   t
JOIN   accounts       a  ON a.account_id  = t.account_id
JOIN   customers      c  ON c.customer_id = a.customer_id
ORDER BY
    a.account_id      ASC,
    t.transaction_date ASC,
    t.transaction_id   ASC;
GO

-- ============================================================
-- QUERY 2: Month-over-Month Spending with LAG and 3-Month Rolling Average
-- Business purpose: Track customer spending velocity over time.
-- Identifies seasonal patterns and detects sudden spend spikes
-- that may warrant proactive customer outreach or fraud review.
-- ============================================================
WITH monthly_spend AS (
    SELECT
        c.customer_id,
        c.first_name + N' ' + c.last_name              AS customer_name,
        YEAR(t.transaction_date)                         AS txn_year,
        MONTH(t.transaction_date)                        AS txn_month,
        DATEFROMPARTS(YEAR(t.transaction_date), MONTH(t.transaction_date), 1)
                                                         AS month_start,
        SUM(t.amount)                                    AS monthly_spend
    FROM   transactions   t
    JOIN   accounts       a  ON a.account_id  = t.account_id
    JOIN   customers      c  ON c.customer_id = a.customer_id
    WHERE  t.transaction_type IN ('Payment','Withdrawal','Fee')
    GROUP BY
        c.customer_id,
        c.first_name + N' ' + c.last_name,
        YEAR(t.transaction_date),
        MONTH(t.transaction_date),
        DATEFROMPARTS(YEAR(t.transaction_date), MONTH(t.transaction_date), 1)
)
SELECT
    customer_id,
    customer_name,
    txn_year,
    txn_month,
    month_start,
    monthly_spend,
    -- Previous month's spend
    LAG(monthly_spend, 1) OVER (
        PARTITION BY customer_id
        ORDER BY month_start
    )                                                   AS prev_month_spend,
    -- Month-over-month change
    monthly_spend
    - LAG(monthly_spend, 1) OVER (
        PARTITION BY customer_id
        ORDER BY month_start
    )                                                   AS mom_change,
    -- Month-over-month % change
    ROUND(
        100.0 * (monthly_spend
                 - LAG(monthly_spend, 1) OVER (
                       PARTITION BY customer_id ORDER BY month_start))
             / NULLIF(LAG(monthly_spend, 1) OVER (
                       PARTITION BY customer_id ORDER BY month_start), 0),
        2
    )                                                   AS mom_pct_change,
    -- 3-month rolling average (current + 2 prior months)
    ROUND(
        AVG(monthly_spend) OVER (
            PARTITION BY customer_id
            ORDER BY month_start
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    )                                                   AS rolling_3m_avg
FROM   monthly_spend
ORDER BY
    customer_id ASC,
    month_start  ASC;
GO

-- ============================================================
-- QUERY 3: Customer Value Segmentation (NTILE Quartiles)
-- Business purpose: Rank all customers into Platinum/Gold/
-- Silver/Standard tiers by total deposits, then compute their
-- position within the overall portfolio and cumulative deposit
-- concentration — key for relationship pricing and targeting.
-- ============================================================
WITH customer_totals AS (
    SELECT
        c.customer_id,
        c.first_name + N' ' + c.last_name              AS customer_name,
        c.credit_score,
        c.join_date,
        SUM(a.balance)                                  AS total_balance,
        COUNT(DISTINCT a.account_id)                    AS account_count,
        SUM(CASE WHEN a.account_type = 'Chequing' THEN a.balance ELSE 0 END) AS chequing_balance,
        SUM(CASE WHEN a.account_type = 'Savings'  THEN a.balance ELSE 0 END) AS savings_balance,
        SUM(CASE WHEN a.account_type = 'TFSA'     THEN a.balance ELSE 0 END) AS tfsa_balance,
        SUM(CASE WHEN a.account_type = 'RRSP'     THEN a.balance ELSE 0 END) AS rrsp_balance
    FROM   customers  c
    JOIN   accounts   a  ON a.customer_id = c.customer_id
                         AND a.status = 'Active'
    WHERE  c.is_active = 1
    GROUP BY c.customer_id, c.first_name, c.last_name, c.credit_score, c.join_date
)
SELECT
    customer_id,
    customer_name,
    credit_score,
    join_date,
    account_count,
    total_balance,
    chequing_balance,
    savings_balance,
    tfsa_balance,
    rrsp_balance,
    -- Overall rank by total balance (1 = highest depositor)
    RANK() OVER (ORDER BY total_balance DESC)           AS balance_rank,
    -- Quartile: 4 = top 25%, 1 = bottom 25%
    NTILE(4) OVER (ORDER BY total_balance ASC)          AS value_quartile,
    -- Tier label
    CASE NTILE(4) OVER (ORDER BY total_balance ASC)
        WHEN 4 THEN N'Platinum'
        WHEN 3 THEN N'Gold'
        WHEN 2 THEN N'Silver'
        ELSE        N'Standard'
    END                                                 AS customer_tier,
    -- Share of total portfolio
    ROUND(
        100.0 * total_balance
              / NULLIF(SUM(total_balance) OVER (), 0),
        4
    )                                                   AS pct_of_portfolio,
    -- Cumulative share ordered by balance descending (Pareto view)
    ROUND(
        100.0 * SUM(total_balance) OVER (
            ORDER BY total_balance DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) / NULLIF(SUM(total_balance) OVER (), 0),
        4
    )                                                   AS cumulative_pct
FROM   customer_totals
ORDER BY total_balance DESC;
GO

-- ============================================================
-- QUERY 4: Spending by Category per Customer
-- Business purpose: Show each customer's top spending categories
-- within the period. RANK() within customer partition reveals
-- their primary spending habits; pct_of_total drives the
-- personalised insights feature on the mobile app.
-- ============================================================
WITH category_spend AS (
    SELECT
        c.customer_id,
        c.first_name + N' ' + c.last_name              AS customer_name,
        ISNULL(mc.category_name, N'Uncategorised')      AS category_name,
        COUNT(*)                                         AS txn_count,
        SUM(t.amount)                                    AS category_spend
    FROM   transactions        t
    JOIN   accounts            a   ON a.account_id   = t.account_id
    JOIN   customers           c   ON c.customer_id  = a.customer_id
    LEFT  JOIN merchant_categories mc ON mc.category_id = t.category_id
    WHERE  t.transaction_type IN ('Payment','Withdrawal','Fee')
    GROUP BY
        c.customer_id,
        c.first_name + N' ' + c.last_name,
        ISNULL(mc.category_name, N'Uncategorised')
)
SELECT
    customer_id,
    customer_name,
    category_name,
    txn_count,
    category_spend,
    -- Rank within each customer (1 = highest spend category)
    RANK() OVER (
        PARTITION BY customer_id
        ORDER BY     category_spend DESC
    )                                                   AS category_rank,
    -- Percentage of that customer's total spend
    ROUND(
        100.0 * category_spend
              / NULLIF(SUM(category_spend) OVER (PARTITION BY customer_id), 0),
        2
    )                                                   AS pct_of_total_spend
FROM   category_spend
ORDER BY
    customer_id    ASC,
    category_spend DESC;
GO

-- ============================================================
-- QUERY 5: Z-Score Fraud Detection
-- Business purpose: Statistical outlier detection using Z-scores.
-- Transactions with a Z-score ≥ 2 are 2+ standard deviations
-- above the account mean — a strong signal for unusual activity
-- that complements the rule-based trigger approach.
-- ============================================================
WITH account_stats AS (
    SELECT
        t.account_id,
        AVG(t.amount)                                   AS mean_amount,
        -- Population standard deviation = SQRT(E[X²] - E[X]²)
        SQRT(
            NULLIF(
                AVG(t.amount * t.amount) - AVG(t.amount) * AVG(t.amount),
                0
            )
        )                                               AS stddev_amount,
        COUNT(*)                                        AS sample_count
    FROM   transactions t
    GROUP BY t.account_id
),
scored AS (
    SELECT
        t.transaction_id,
        t.account_id,
        t.transaction_date,
        t.transaction_type,
        t.amount,
        t.merchant_name,
        t.reference_number,
        t.is_flagged,
        s.mean_amount,
        s.stddev_amount,
        s.sample_count,
        -- Z-score: how many standard deviations above the mean?
        ROUND(
            (t.amount - s.mean_amount) / NULLIF(s.stddev_amount, 0),
            3
        )                                               AS z_score
    FROM   transactions    t
    JOIN   account_stats   s  ON s.account_id = t.account_id
    WHERE  s.sample_count >= 5   -- need at least 5 transactions for meaningful stats
)
SELECT
    sc.transaction_id,
    sc.account_id,
    a.account_number,
    c.first_name + N' ' + c.last_name          AS customer_name,
    sc.transaction_date,
    sc.transaction_type,
    sc.amount,
    sc.merchant_name,
    sc.reference_number,
    ROUND(sc.mean_amount,    2)                 AS account_avg_txn,
    ROUND(sc.stddev_amount,  2)                 AS account_stddev,
    sc.z_score,
    sc.is_flagged                               AS already_flagged,
    CASE WHEN sc.z_score >= 3 THEN N'Extreme'
         WHEN sc.z_score >= 2 THEN N'High'
         ELSE                       N'Normal'
    END                                         AS anomaly_label
FROM   scored        sc
JOIN   accounts      a  ON a.account_id  = sc.account_id
JOIN   customers     c  ON c.customer_id = a.customer_id
WHERE  sc.z_score >= 2
ORDER BY sc.z_score DESC;
GO

-- ============================================================
-- QUERY 6: Customer Cohort Analysis by Join Month
-- Business purpose: Understand when customer acquisition was
-- strongest and track cumulative portfolio growth. Useful for
-- evaluating the impact of historical marketing campaigns.
-- ============================================================
WITH monthly_cohort AS (
    SELECT
        DATEFROMPARTS(YEAR(c.join_date), MONTH(c.join_date), 1)  AS cohort_month,
        COUNT(c.customer_id)                                       AS new_customers,
        AVG(CAST(c.credit_score AS DECIMAL(5,1)))                 AS avg_credit_score
    FROM   customers c
    WHERE  c.is_active = 1
    GROUP BY DATEFROMPARTS(YEAR(c.join_date), MONTH(c.join_date), 1)
)
SELECT
    cohort_month,
    new_customers,
    ROUND(avg_credit_score, 1)                          AS avg_credit_score,
    -- Cumulative customer count across all cohorts
    SUM(new_customers) OVER (
        ORDER BY cohort_month ASC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                                   AS cumulative_customers,
    -- Running share of total customer base
    ROUND(
        100.0 * SUM(new_customers) OVER (
            ORDER BY cohort_month ASC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) / NULLIF(SUM(new_customers) OVER (), 0),
        2
    )                                                   AS cumulative_pct
FROM   monthly_cohort
ORDER BY cohort_month ASC;
GO

-- ============================================================
-- QUERY 7: Branch Performance Leaderboard
-- Business purpose: Rank branches across three KPI dimensions
-- (deposit book, transaction throughput, loan book) and combine
-- into a weighted composite score for executive reporting.
-- ============================================================
WITH branch_kpis AS (
    SELECT
        br.branch_id,
        br.branch_name,
        br.city,
        -- Total deposits on hand
        ISNULL(SUM(a.balance), 0)                               AS total_deposits,
        -- Total transaction count
        COUNT(DISTINCT t.transaction_id)                        AS total_transactions,
        -- Active loan book
        ISNULL(SUM(CASE WHEN l.status = 'Active' THEN l.outstanding_balance ELSE 0 END), 0)
                                                                AS total_loan_book
    FROM   branches     br
    LEFT  JOIN accounts a   ON a.branch_id = br.branch_id AND a.status = 'Active'
    LEFT  JOIN transactions t ON t.account_id = a.account_id
    LEFT  JOIN loans    l   ON l.branch_id = br.branch_id
    GROUP BY br.branch_id, br.branch_name, br.city
)
SELECT
    branch_id,
    branch_name,
    city,
    total_deposits,
    total_transactions,
    total_loan_book,
    -- Individual dimension ranks (1 = best)
    DENSE_RANK() OVER (ORDER BY total_deposits     DESC)    AS deposit_rank,
    DENSE_RANK() OVER (ORDER BY total_transactions DESC)    AS transaction_rank,
    DENSE_RANK() OVER (ORDER BY total_loan_book    DESC)    AS loan_book_rank,
    -- Composite score: lower is better (equal weighting)
    DENSE_RANK() OVER (ORDER BY total_deposits     DESC)
    + DENSE_RANK() OVER (ORDER BY total_transactions DESC)
    + DENSE_RANK() OVER (ORDER BY total_loan_book  DESC)   AS composite_score,
    -- Overall branch leaderboard rank by composite score
    DENSE_RANK() OVER (
        ORDER BY (
            DENSE_RANK() OVER (ORDER BY total_deposits     DESC)
          + DENSE_RANK() OVER (ORDER BY total_transactions DESC)
          + DENSE_RANK() OVER (ORDER BY total_loan_book    DESC)
        ) ASC
    )                                                       AS overall_rank
FROM   branch_kpis
ORDER BY composite_score ASC;
GO

-- ============================================================
-- QUERY 8: Recursive CTE Loan Amortization Schedule
-- Business purpose: Project the full payment schedule for a
-- loan (loan_id = 1), showing principal/interest split,
-- remaining balance, cumulative interest paid, and percent of
-- loan paid off at each payment. Essential for loan disclosures
-- and customer-facing amortization tables.
-- ============================================================
WITH amortization AS (
    -- Anchor: month 0 = loan origination
    SELECT
        l.loan_id,
        l.interest_rate,
        l.monthly_payment,
        l.term_months,
        CAST(0 AS INT)                  AS payment_number,
        l.principal_amount              AS remaining_balance,
        CAST(0.00 AS DECIMAL(15,2))     AS interest_paid,
        CAST(0.00 AS DECIMAL(15,2))     AS principal_paid,
        CAST(0.00 AS DECIMAL(15,2))     AS cumulative_interest
    FROM   loans l
    WHERE  l.loan_id = 1

    UNION ALL

    -- Recursive: each subsequent payment
    SELECT
        a.loan_id,
        a.interest_rate,
        a.monthly_payment,
        a.term_months,
        a.payment_number + 1,
        -- New remaining balance
        ROUND(a.remaining_balance
              - (a.monthly_payment - ROUND(a.remaining_balance * (a.interest_rate / 12.0), 2)),
              2),
        -- Interest portion this period
        ROUND(a.remaining_balance * (a.interest_rate / 12.0), 2),
        -- Principal portion this period
        ROUND(a.monthly_payment - ROUND(a.remaining_balance * (a.interest_rate / 12.0), 2), 2),
        -- Cumulative interest
        a.cumulative_interest + ROUND(a.remaining_balance * (a.interest_rate / 12.0), 2)
    FROM   amortization a
    WHERE  a.payment_number < a.term_months
      AND  a.remaining_balance > 0
)
SELECT
    payment_number,
    ROUND(remaining_balance, 2)                             AS remaining_balance,
    interest_paid                                           AS interest_this_payment,
    principal_paid                                          AS principal_this_payment,
    monthly_payment,
    ROUND(cumulative_interest, 2)                           AS cumulative_interest_paid,
    -- Percent of loan paid off = principal repaid / original principal
    ROUND(
        100.0 * (
            (SELECT principal_amount FROM loans WHERE loan_id = 1) - remaining_balance
        ) / NULLIF((SELECT principal_amount FROM loans WHERE loan_id = 1), 0),
        2
    )                                                       AS pct_paid_off
FROM   amortization
ORDER BY payment_number ASC
OPTION (MAXRECURSION 500);
GO

-- ============================================================
-- QUERY 9: Dormant Customer Detection
-- Business purpose: Identify customers who have gone silent —
-- either they never transacted, have been inactive for 6+
-- months, or are showing early warning (90–180 days no activity).
-- Drives re-engagement campaigns and dormancy fee assessments.
-- ============================================================
WITH last_activity AS (
    SELECT
        c.customer_id,
        c.first_name + N' ' + c.last_name              AS customer_name,
        c.email,
        c.join_date,
        c.credit_score,
        MAX(t.transaction_date)                         AS last_transaction_date,
        COUNT(t.transaction_id)                         AS total_transactions
    FROM   customers   c
    LEFT  JOIN accounts      a  ON a.customer_id  = c.customer_id
    LEFT  JOIN transactions  t  ON t.account_id   = a.account_id
    WHERE  c.is_active = 1
    GROUP BY
        c.customer_id,
        c.first_name + N' ' + c.last_name,
        c.email,
        c.join_date,
        c.credit_score
)
SELECT
    customer_id,
    customer_name,
    email,
    join_date,
    credit_score,
    last_transaction_date,
    total_transactions,
    -- Days since last transaction (NULL = never transacted)
    DATEDIFF(DAY, last_transaction_date, GETDATE())     AS days_since_last_txn,
    -- Dormancy category
    CASE
        WHEN last_transaction_date IS NULL
             THEN N'Never Active'
        WHEN DATEDIFF(DAY, last_transaction_date, GETDATE()) > 180
             THEN N'Dormant 6+ Months'
        WHEN DATEDIFF(DAY, last_transaction_date, GETDATE()) > 90
             THEN N'At Risk 90+ Days'
        ELSE      N'Active'
    END                                                 AS dormancy_status
FROM   last_activity
WHERE  last_transaction_date IS NULL
    OR DATEDIFF(DAY, last_transaction_date, GETDATE()) > 90
ORDER BY days_since_last_txn DESC;
GO

-- ============================================================
-- QUERY 10: Top 5 Transactions Per Account by Amount
-- Business purpose: Surface the highest-value transactions for
-- each account — useful for fraud review spot-checks, premium
-- customer recognition, and AML high-value transaction reports.
-- ============================================================
WITH ranked_txns AS (
    SELECT
        t.transaction_id,
        t.account_id,
        a.account_number,
        a.account_type,
        c.customer_id,
        c.first_name + N' ' + c.last_name              AS customer_name,
        b.branch_name,
        t.transaction_date,
        t.transaction_type,
        t.amount,
        t.merchant_name,
        t.reference_number,
        t.channel,
        t.is_flagged,
        -- Rank within each account, highest amount first
        ROW_NUMBER() OVER (
            PARTITION BY t.account_id
            ORDER BY     t.amount DESC, t.transaction_date DESC
        )                                               AS amount_rank
    FROM   transactions   t
    JOIN   accounts       a  ON a.account_id  = t.account_id
    JOIN   customers      c  ON c.customer_id = a.customer_id
    JOIN   branches       b  ON b.branch_id   = a.branch_id
)
SELECT
    account_id,
    account_number,
    account_type,
    customer_id,
    customer_name,
    branch_name,
    amount_rank,
    transaction_id,
    transaction_date,
    transaction_type,
    amount,
    merchant_name,
    reference_number,
    channel,
    is_flagged
FROM   ranked_txns
WHERE  amount_rank <= 5
ORDER BY
    account_id   ASC,
    amount_rank  ASC;
GO

PRINT N'Rutzfin: 10 advanced showcase queries complete.';
GO
