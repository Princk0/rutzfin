-- ============================================================
-- Rutzfin: Banking Transaction Intelligence Platform
-- FILE: 03_indexes.sql
-- PURPOSE: Strategic non-clustered indexes for query performance
-- PLATFORM: Azure SQL / T-SQL
-- ============================================================
-- Design principles:
--   1. Covering indexes reduce key lookups by including frequently-projected
--      columns in the INCLUDE clause rather than the key.
--   2. Filtered indexes reduce index size and improve selectivity for
--      sparse predicate conditions (is_flagged = 1, is_late = 1, etc.).
--   3. DESC ordering on date columns aligns with the dominant "newest first"
--      sort direction across dashboard and report queries, eliminating a sort
--      operator.
--   4. Key columns are chosen to match WHERE / JOIN predicates; INCLUDE
--      columns satisfy the SELECT list without widening the index key.
-- ============================================================

SET NOCOUNT ON;
GO

-- ============================================================
-- TRANSACTIONS TABLE INDEXES
-- ============================================================

-- ------------------------------------------------------------
-- IX_transactions_account_date
-- Purpose: The single most critical index for the platform.
--   Satisfies the dominant query pattern: "show all transactions
--   for account X ordered by date descending" — used by account
--   detail pages, statement generation (usp_GenerateMonthlyStatement),
--   running-balance calculations, and vw_MonthlyTransactionSummary.
--   DESC on transaction_date aligns with the default newest-first
--   sort so the engine avoids a sort operator. INCLUDE columns
--   cover the full SELECT list for those queries without a key lookup.
-- ------------------------------------------------------------
CREATE NONCLUSTERED INDEX IX_transactions_account_date
ON transactions (account_id ASC, transaction_date DESC)
INCLUDE (transaction_type, amount, merchant_name, category_id, is_flagged);
GO

-- ------------------------------------------------------------
-- IX_transactions_flagged
-- Purpose: Filtered index exclusively for flagged (suspicious)
--   transactions. Because is_flagged = 1 is a tiny fraction of
--   total rows, the filtered index is dramatically smaller than a
--   full index and the engine uses it for all fraud dashboard and
--   alert queue queries (vw_FraudAlertQueue). Ordered DESC on
--   transaction_date so fraud analysts see the newest events first
--   without an additional sort operation.
-- ------------------------------------------------------------
CREATE NONCLUSTERED INDEX IX_transactions_flagged
ON transactions (is_flagged ASC, transaction_date DESC)
INCLUDE (transaction_id, account_id, amount)
WHERE is_flagged = 1;
GO

-- ------------------------------------------------------------
-- IX_transactions_category_date
-- Purpose: Supports spending-by-category analytical queries —
--   e.g. "what did customers spend on Groceries this month?"
--   Used by the category spending breakdown in
--   usp_GenerateMonthlyStatement (result set 3), the category
--   heatmap in 07_advanced_queries.sql, and any merchant-category
--   aggregation. ASC on transaction_date works well for bounded
--   date range scans.
-- ------------------------------------------------------------
CREATE NONCLUSTERED INDEX IX_transactions_category_date
ON transactions (category_id ASC, transaction_date ASC)
INCLUDE (account_id, amount);
GO

-- ------------------------------------------------------------
-- IX_transactions_type_date
-- Purpose: Enables fast aggregation of specific transaction types
--   across all accounts — e.g. "total deposits this month", "all
--   withdrawals in Q1". Used by branch performance aggregation
--   (vw_BranchPerformance), inflow/outflow totals, and the
--   month-over-month spending analysis in 07_advanced_queries.sql.
--   reference_number is included for deduplication and
--   reconciliation queries.
-- ------------------------------------------------------------
CREATE NONCLUSTERED INDEX IX_transactions_type_date
ON transactions (transaction_type ASC, transaction_date DESC)
INCLUDE (account_id, amount, reference_number);
GO

-- ============================================================
-- ACCOUNTS TABLE INDEXES
-- ============================================================

-- ------------------------------------------------------------
-- IX_accounts_customer
-- Purpose: Primary navigation path from a customer to their
--   accounts. Almost every customer-facing screen filters first
--   by customer_id, then by status (Active / Frozen / Closed).
--   INCLUDE columns avoid a key lookup when rendering the account
--   list or calculating per-customer balance totals. Used by
--   vw_CustomerAccountSummary and fund-transfer validation in
--   usp_TransferFunds.
-- ------------------------------------------------------------
CREATE NONCLUSTERED INDEX IX_accounts_customer
ON accounts (customer_id ASC, status ASC)
INCLUDE (account_number, account_type, balance, branch_id);
GO

-- ------------------------------------------------------------
-- IX_accounts_branch
-- Purpose: Supports branch-level aggregation queries.
--   vw_BranchPerformance groups by branch_id and pivots on
--   account_type and status. Having (branch_id, account_type,
--   status) as the composite key lets the engine satisfy the
--   GROUP BY with an index scan rather than a table scan + sort.
--   customer_id and balance are included for the aggregate
--   projection columns.
-- ------------------------------------------------------------
CREATE NONCLUSTERED INDEX IX_accounts_branch
ON accounts (branch_id ASC, account_type ASC, status ASC)
INCLUDE (customer_id, balance);
GO

-- ============================================================
-- LOANS TABLE INDEXES
-- ============================================================

-- ------------------------------------------------------------
-- IX_loans_customer_status
-- Purpose: Drives the loan health dashboard and any "show my
--   loans" customer feature. Filters first by customer_id, then
--   by status (Active / Delinquent / Paid Off). INCLUDE columns
--   cover the full projection needed by vw_LoanHealthDashboard
--   and usp_ProcessLoanPayment validation without a key lookup.
-- ------------------------------------------------------------
CREATE NONCLUSTERED INDEX IX_loans_customer_status
ON loans (customer_id ASC, status ASC)
INCLUDE (loan_type, outstanding_balance, monthly_payment, end_date);
GO

-- ============================================================
-- LOAN_PAYMENTS TABLE INDEXES
-- ============================================================

-- ------------------------------------------------------------
-- IX_loan_payments_late
-- Purpose: Filtered index on late payments only (is_late = 1).
--   Late payments are a minority of rows but are constantly
--   queried by the risk and collections teams and the
--   risk_rating calculation in vw_LoanHealthDashboard.
--   Filtering eliminates on-time payments from the index
--   entirely, keeping it compact and highly selective. Ordered
--   DESC on payment_date so the most recent delinquency
--   surfaces first. loan_id and days_late are included to
--   support the OUTER APPLY aggregation.
-- ------------------------------------------------------------
CREATE NONCLUSTERED INDEX IX_loan_payments_late
ON loan_payments (is_late ASC, payment_date DESC)
INCLUDE (loan_id, days_late)
WHERE is_late = 1;
GO

-- ============================================================
-- FRAUD_ALERTS TABLE INDEXES
-- ============================================================

-- ------------------------------------------------------------
-- IX_fraud_alerts_unresolved
-- Purpose: Filtered index for the fraud operations queue —
--   only unresolved alerts (is_resolved = 0). Analysts work
--   through the queue in order of severity (Critical → High →
--   Medium → Low) and then by recency (newest first). Because
--   the filtered predicate already restricts to open alerts,
--   the index is small and the composite sort on
--   (severity, created_at DESC) matches the working order,
--   eliminating a sort operator. Used exclusively by
--   vw_FraudAlertQueue and usp_ResolveFraudAlert lookups.
-- ------------------------------------------------------------
CREATE NONCLUSTERED INDEX IX_fraud_alerts_unresolved
ON fraud_alerts (is_resolved ASC, severity ASC, created_at DESC)
WHERE is_resolved = 0;
GO

-- ============================================================
-- CUSTOMERS TABLE INDEXES
-- ============================================================

-- ------------------------------------------------------------
-- IX_customers_location
-- Purpose: Supports geographic segmentation and branch-catchment
--   analysis — e.g. "all customers in Mississauga, ON" or
--   "credit score distribution across cities in Ontario". Used
--   by the cohort analysis and dormant customer detection
--   queries in 07_advanced_queries.sql, and by any marketing
--   filter on province + city. first_name, last_name, and
--   credit_score are included so the customer list page can
--   render without a secondary key lookup.
-- ------------------------------------------------------------
CREATE NONCLUSTERED INDEX IX_customers_location
ON customers (province ASC, city ASC)
INCLUDE (customer_id, first_name, last_name, credit_score);
GO

PRINT N'Rutzfin: 10 strategic indexes created successfully.';
GO
