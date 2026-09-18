-- ============================================================
-- Rutzfin: Banking Transaction Intelligence Platform
-- FILE: 01_schema.sql
-- PURPOSE: Core schema definition for all platform tables
-- PLATFORM: Azure SQL / T-SQL
-- ============================================================

SET NOCOUNT ON;
GO

-- ============================================================
-- TABLE: branches
-- Stores physical branch locations across the GTA network
-- ============================================================
CREATE TABLE branches (
    branch_id       INT             IDENTITY(1,1)       NOT NULL,
    branch_name     NVARCHAR(100)                       NOT NULL,
    city            NVARCHAR(100)                       NOT NULL,
    province        NCHAR(2)        DEFAULT 'ON'        NOT NULL,
    address         NVARCHAR(255)                           NULL,
    phone           NVARCHAR(20)                            NULL,
    opened_date     DATE                                NOT NULL,
    is_active       BIT             DEFAULT 1           NOT NULL,
    CONSTRAINT PK_branches PRIMARY KEY CLUSTERED (branch_id)
);
GO

-- ============================================================
-- TABLE: customers
-- Core customer identity and profile information
-- ============================================================
CREATE TABLE customers (
    customer_id     INT             IDENTITY(1,1)               NOT NULL,
    first_name      NVARCHAR(100)                               NOT NULL,
    last_name       NVARCHAR(100)                               NOT NULL,
    email           NVARCHAR(255)                               NOT NULL,
    phone           NVARCHAR(20)                                    NULL,
    date_of_birth   DATE                                        NOT NULL,
    credit_score    SMALLINT                                        NULL,
    join_date       DATE            DEFAULT CAST(GETDATE() AS DATE) NOT NULL,
    city            NVARCHAR(100)                                   NULL,
    province        NCHAR(2)        DEFAULT 'ON'                    NULL,
    is_active       BIT             DEFAULT 1                   NOT NULL,
    CONSTRAINT PK_customers         PRIMARY KEY CLUSTERED (customer_id),
    CONSTRAINT UQ_customers_email   UNIQUE (email),
    CONSTRAINT CK_customers_credit  CHECK (credit_score BETWEEN 300 AND 900)
);
GO

-- ============================================================
-- TABLE: merchant_categories
-- MCC-style lookup table for transaction categorisation
-- ============================================================
CREATE TABLE merchant_categories (
    category_id     INT             IDENTITY(1,1)   NOT NULL,
    category_code   NVARCHAR(10)                    NOT NULL,
    category_name   NVARCHAR(100)                   NOT NULL,
    CONSTRAINT PK_merchant_categories       PRIMARY KEY CLUSTERED (category_id),
    CONSTRAINT UQ_merchant_categories_code  UNIQUE (category_code)
);
GO

-- ============================================================
-- TABLE: accounts
-- Customer deposit/investment accounts with balance tracking
-- ============================================================
CREATE TABLE accounts (
    account_id      INT             IDENTITY(1,1)                   NOT NULL,
    customer_id     INT                                             NOT NULL,
    branch_id       INT                                             NOT NULL,
    account_number  NVARCHAR(20)                                    NOT NULL,
    account_type    NVARCHAR(10)                                    NOT NULL,
    balance         DECIMAL(15,2)   DEFAULT 0.00                   NOT NULL,
    interest_rate   DECIMAL(5,4)    DEFAULT 0.0000                 NOT NULL,
    status          NVARCHAR(10)    DEFAULT 'Active'               NOT NULL,
    opened_date     DATE            DEFAULT CAST(GETDATE() AS DATE) NOT NULL,
    closed_date     DATE                                                NULL,
    CONSTRAINT PK_accounts          PRIMARY KEY CLUSTERED (account_id),
    CONSTRAINT UQ_accounts_number   UNIQUE (account_number),
    CONSTRAINT FK_accounts_customer FOREIGN KEY (customer_id)   REFERENCES customers(customer_id),
    CONSTRAINT FK_accounts_branch   FOREIGN KEY (branch_id)     REFERENCES branches(branch_id),
    CONSTRAINT CK_accounts_type     CHECK (account_type IN ('Chequing', 'Savings', 'TFSA', 'RRSP')),
    CONSTRAINT CK_accounts_status   CHECK (status        IN ('Active', 'Frozen', 'Closed'))
);
GO

-- ============================================================
-- TABLE: transactions
-- Every financial movement against an account
-- ============================================================
CREATE TABLE transactions (
    transaction_id      INT             IDENTITY(1,1)       NOT NULL,
    account_id          INT                                 NOT NULL,
    transaction_type    NVARCHAR(20)                        NOT NULL,
    amount              DECIMAL(15,2)                       NOT NULL,
    transaction_date    DATETIME2       DEFAULT GETDATE()   NOT NULL,
    merchant_name       NVARCHAR(255)                           NULL,
    category_id         INT                                     NULL,
    description         NVARCHAR(500)                           NULL,
    reference_number    NVARCHAR(50)                        NOT NULL,
    balance_after       DECIMAL(15,2)                           NULL,
    channel             NVARCHAR(10)    DEFAULT 'Online'    NOT NULL,
    is_flagged          BIT             DEFAULT 0           NOT NULL,
    CONSTRAINT PK_transactions              PRIMARY KEY CLUSTERED (transaction_id),
    CONSTRAINT UQ_transactions_ref          UNIQUE (reference_number),
    CONSTRAINT FK_transactions_account      FOREIGN KEY (account_id)    REFERENCES accounts(account_id),
    CONSTRAINT FK_transactions_category     FOREIGN KEY (category_id)   REFERENCES merchant_categories(category_id),
    CONSTRAINT CK_transactions_type         CHECK (transaction_type IN (
                                                'Deposit', 'Withdrawal', 'Transfer_In',
                                                'Transfer_Out', 'Payment', 'Fee', 'Interest')),
    CONSTRAINT CK_transactions_amount       CHECK (amount > 0),
    CONSTRAINT CK_transactions_channel      CHECK (channel IN ('Online', 'ATM', 'Branch', 'Mobile', 'POS'))
);
GO

-- ============================================================
-- TABLE: fraud_alerts
-- Automated and manual fraud detection records
-- ============================================================
CREATE TABLE fraud_alerts (
    alert_id        INT             IDENTITY(1,1)           NOT NULL,
    transaction_id  INT                                     NOT NULL,
    alert_type      NVARCHAR(100)                           NOT NULL,
    alert_reason    NVARCHAR(500)                               NULL,
    severity        NVARCHAR(10)    DEFAULT 'Medium'        NOT NULL,
    created_at      DATETIME2       DEFAULT GETDATE()       NOT NULL,
    is_resolved     BIT             DEFAULT 0               NOT NULL,
    resolved_at     DATETIME2                                   NULL,
    resolved_by     NVARCHAR(100)                               NULL,
    CONSTRAINT PK_fraud_alerts          PRIMARY KEY CLUSTERED (alert_id),
    CONSTRAINT FK_fraud_alerts_txn      FOREIGN KEY (transaction_id)    REFERENCES transactions(transaction_id),
    CONSTRAINT CK_fraud_alerts_severity CHECK (severity IN ('Low', 'Medium', 'High', 'Critical'))
);
GO

-- ============================================================
-- TABLE: loans
-- Customer loan products with full lifecycle tracking
-- ============================================================
CREATE TABLE loans (
    loan_id             INT             IDENTITY(1,1)   NOT NULL,
    customer_id         INT                             NOT NULL,
    branch_id           INT                             NOT NULL,
    loan_type           NVARCHAR(10)                    NOT NULL,
    principal_amount    DECIMAL(15,2)                   NOT NULL,
    interest_rate       DECIMAL(5,4)                    NOT NULL,
    term_months         SMALLINT                        NOT NULL,
    monthly_payment     DECIMAL(15,2)                   NOT NULL,
    start_date          DATE                            NOT NULL,
    end_date            DATE                            NOT NULL,
    outstanding_balance DECIMAL(15,2)                   NOT NULL,
    status              NVARCHAR(12)    DEFAULT 'Active' NOT NULL,
    CONSTRAINT PK_loans             PRIMARY KEY CLUSTERED (loan_id),
    CONSTRAINT FK_loans_customer    FOREIGN KEY (customer_id)   REFERENCES customers(customer_id),
    CONSTRAINT FK_loans_branch      FOREIGN KEY (branch_id)     REFERENCES branches(branch_id),
    CONSTRAINT CK_loans_type        CHECK (loan_type        IN ('Personal', 'Mortgage', 'Auto', 'Student', 'Business')),
    CONSTRAINT CK_loans_status      CHECK (status           IN ('Active', 'Paid Off', 'Defaulted', 'Delinquent')),
    CONSTRAINT CK_loans_principal   CHECK (principal_amount > 0),
    CONSTRAINT CK_loans_term        CHECK (term_months      > 0)
);
GO

-- ============================================================
-- TABLE: loan_payments
-- Individual payment records against a loan
-- ============================================================
CREATE TABLE loan_payments (
    payment_id      INT             IDENTITY(1,1)   NOT NULL,
    loan_id         INT                             NOT NULL,
    payment_date    DATE                            NOT NULL,
    scheduled_date  DATE                            NOT NULL,
    amount_paid     DECIMAL(15,2)                   NOT NULL,
    principal_paid  DECIMAL(15,2)   DEFAULT 0.00    NOT NULL,
    interest_paid   DECIMAL(15,2)   DEFAULT 0.00    NOT NULL,
    balance_after   DECIMAL(15,2)                   NOT NULL,
    is_late         BIT             DEFAULT 0       NOT NULL,
    days_late       SMALLINT        DEFAULT 0       NOT NULL,
    CONSTRAINT PK_loan_payments         PRIMARY KEY CLUSTERED (payment_id),
    CONSTRAINT FK_loan_payments_loan    FOREIGN KEY (loan_id)   REFERENCES loans(loan_id),
    CONSTRAINT CK_loan_payments_amount  CHECK (amount_paid > 0)
);
GO

PRINT N'Rutzfin schema created successfully — 8 tables.';
GO
