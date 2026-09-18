-- ============================================================
-- Rutzfin: Banking Transaction Intelligence Platform
-- FILE: 03_indexes.sql  (PostgreSQL version)
-- Changes from T-SQL original:
--   • Removed NONCLUSTERED keyword (all PG indexes are non-clustered)
--   • WHERE is_flagged = 1  → WHERE is_flagged = TRUE
--   • WHERE is_resolved = 0 → WHERE is_resolved = FALSE
--   • WHERE is_late = 1     → WHERE is_late = TRUE
--   • Removed SET NOCOUNT ON / GO / PRINT statements
-- INCLUDE clause requires PostgreSQL 11+
-- ============================================================

-- Transactions: primary query pattern (account + date)
CREATE INDEX ix_transactions_account_date
ON transactions (account_id ASC, transaction_date DESC)
INCLUDE (transaction_type, amount, merchant_name, category_id, is_flagged);

-- Transactions: filtered index for flagged rows only
CREATE INDEX ix_transactions_flagged
ON transactions (transaction_date DESC)
INCLUDE (transaction_id, account_id, amount)
WHERE is_flagged = TRUE;

-- Transactions: category + date for spending analysis
CREATE INDEX ix_transactions_category_date
ON transactions (category_id ASC, transaction_date ASC)
INCLUDE (account_id, amount);

-- Transactions: type + date for inflow/outflow aggregations
CREATE INDEX ix_transactions_type_date
ON transactions (transaction_type ASC, transaction_date DESC)
INCLUDE (account_id, amount, reference_number);

-- Accounts: customer lookup
CREATE INDEX ix_accounts_customer
ON accounts (customer_id ASC, status ASC)
INCLUDE (account_number, account_type, balance, branch_id);

-- Accounts: branch aggregation
CREATE INDEX ix_accounts_branch
ON accounts (branch_id ASC, account_type ASC, status ASC)
INCLUDE (customer_id, balance);

-- Loans: customer + status
CREATE INDEX ix_loans_customer_status
ON loans (customer_id ASC, status ASC)
INCLUDE (loan_type, outstanding_balance, monthly_payment, end_date);

-- Loan payments: filtered index for late payments only
CREATE INDEX ix_loan_payments_late
ON loan_payments (payment_date DESC)
INCLUDE (loan_id, days_late)
WHERE is_late = TRUE;

-- Fraud alerts: filtered index for unresolved alerts
CREATE INDEX ix_fraud_alerts_unresolved
ON fraud_alerts (severity ASC, created_at DESC)
WHERE is_resolved = FALSE;

-- Customers: geographic segmentation
CREATE INDEX ix_customers_location
ON customers (province ASC, city ASC)
INCLUDE (customer_id, first_name, last_name, credit_score);
