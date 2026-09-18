-- ============================================================
-- Rutzfin: Banking Transaction Intelligence Platform
-- FILE: 01_schema.sql
-- PURPOSE: Core schema — PostgreSQL version
-- Run on your Raspberry Pi:
--   psql -U rutzfin_user -d rutzfin -f 01_schema.sql
-- ============================================================

CREATE TABLE branches (
    branch_id       SERIAL                          NOT NULL,
    branch_name     VARCHAR(100)                    NOT NULL,
    city            VARCHAR(100)                    NOT NULL,
    province        CHAR(2)         DEFAULT 'ON'    NOT NULL,
    address         VARCHAR(255),
    phone           VARCHAR(20),
    opened_date     DATE                            NOT NULL,
    is_active       BOOLEAN         DEFAULT TRUE    NOT NULL,
    CONSTRAINT pk_branches PRIMARY KEY (branch_id)
);

CREATE TABLE customers (
    customer_id     SERIAL                                  NOT NULL,
    first_name      VARCHAR(100)                            NOT NULL,
    last_name       VARCHAR(100)                            NOT NULL,
    email           VARCHAR(255)                            NOT NULL,
    phone           VARCHAR(20),
    date_of_birth   DATE                                    NOT NULL,
    credit_score    SMALLINT,
    join_date       DATE            DEFAULT CURRENT_DATE    NOT NULL,
    city            VARCHAR(100),
    province        CHAR(2)         DEFAULT 'ON',
    is_active       BOOLEAN         DEFAULT TRUE            NOT NULL,
    CONSTRAINT pk_customers         PRIMARY KEY (customer_id),
    CONSTRAINT uq_customers_email   UNIQUE (email),
    CONSTRAINT ck_customers_credit  CHECK (credit_score BETWEEN 300 AND 900)
);

CREATE TABLE merchant_categories (
    category_id     SERIAL          NOT NULL,
    category_code   VARCHAR(10)     NOT NULL,
    category_name   VARCHAR(100)    NOT NULL,
    CONSTRAINT pk_merchant_categories      PRIMARY KEY (category_id),
    CONSTRAINT uq_merchant_categories_code UNIQUE (category_code)
);

CREATE TABLE accounts (
    account_id      SERIAL                              NOT NULL,
    customer_id     INT                                 NOT NULL,
    branch_id       INT                                 NOT NULL,
    account_number  VARCHAR(20)                         NOT NULL,
    account_type    VARCHAR(10)                         NOT NULL,
    balance         DECIMAL(15,2)   DEFAULT 0.00        NOT NULL,
    interest_rate   DECIMAL(5,4)    DEFAULT 0.0000      NOT NULL,
    status          VARCHAR(10)     DEFAULT 'Active'    NOT NULL,
    opened_date     DATE            DEFAULT CURRENT_DATE NOT NULL,
    closed_date     DATE,
    CONSTRAINT pk_accounts          PRIMARY KEY (account_id),
    CONSTRAINT uq_accounts_number   UNIQUE (account_number),
    CONSTRAINT fk_accounts_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_accounts_branch   FOREIGN KEY (branch_id)   REFERENCES branches(branch_id),
    CONSTRAINT ck_accounts_type     CHECK (account_type IN ('Chequing','Savings','TFSA','RRSP')),
    CONSTRAINT ck_accounts_status   CHECK (status        IN ('Active','Frozen','Closed'))
);

CREATE TABLE transactions (
    transaction_id      SERIAL                          NOT NULL,
    account_id          INT                             NOT NULL,
    transaction_type    VARCHAR(20)                     NOT NULL,
    amount              DECIMAL(15,2)                   NOT NULL,
    transaction_date    TIMESTAMP       DEFAULT NOW()   NOT NULL,
    merchant_name       VARCHAR(255),
    category_id         INT,
    description         VARCHAR(500),
    reference_number    VARCHAR(50)                     NOT NULL,
    balance_after       DECIMAL(15,2),
    channel             VARCHAR(10)     DEFAULT 'Online' NOT NULL,
    is_flagged          BOOLEAN         DEFAULT FALSE   NOT NULL,
    CONSTRAINT pk_transactions          PRIMARY KEY (transaction_id),
    CONSTRAINT uq_transactions_ref      UNIQUE (reference_number),
    CONSTRAINT fk_transactions_account  FOREIGN KEY (account_id)  REFERENCES accounts(account_id),
    CONSTRAINT fk_transactions_category FOREIGN KEY (category_id) REFERENCES merchant_categories(category_id),
    CONSTRAINT ck_transactions_type     CHECK (transaction_type IN (
                                            'Deposit','Withdrawal','Transfer_In',
                                            'Transfer_Out','Payment','Fee','Interest')),
    CONSTRAINT ck_transactions_amount   CHECK (amount > 0),
    CONSTRAINT ck_transactions_channel  CHECK (channel IN ('Online','ATM','Branch','Mobile','POS'))
);

CREATE TABLE fraud_alerts (
    alert_id        SERIAL                          NOT NULL,
    transaction_id  INT                             NOT NULL,
    alert_type      VARCHAR(100)                    NOT NULL,
    alert_reason    VARCHAR(500),
    severity        VARCHAR(10)     DEFAULT 'Medium' NOT NULL,
    created_at      TIMESTAMP       DEFAULT NOW()   NOT NULL,
    is_resolved     BOOLEAN         DEFAULT FALSE   NOT NULL,
    resolved_at     TIMESTAMP,
    resolved_by     VARCHAR(100),
    CONSTRAINT pk_fraud_alerts          PRIMARY KEY (alert_id),
    CONSTRAINT fk_fraud_alerts_txn      FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id),
    CONSTRAINT ck_fraud_alerts_severity CHECK (severity IN ('Low','Medium','High','Critical'))
);

CREATE TABLE loans (
    loan_id             SERIAL          NOT NULL,
    customer_id         INT             NOT NULL,
    branch_id           INT             NOT NULL,
    loan_type           VARCHAR(10)     NOT NULL,
    principal_amount    DECIMAL(15,2)   NOT NULL,
    interest_rate       DECIMAL(5,4)    NOT NULL,
    term_months         SMALLINT        NOT NULL,
    monthly_payment     DECIMAL(15,2)   NOT NULL,
    start_date          DATE            NOT NULL,
    end_date            DATE            NOT NULL,
    outstanding_balance DECIMAL(15,2)   NOT NULL,
    status              VARCHAR(12)     DEFAULT 'Active' NOT NULL,
    CONSTRAINT pk_loans             PRIMARY KEY (loan_id),
    CONSTRAINT fk_loans_customer    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_loans_branch      FOREIGN KEY (branch_id)   REFERENCES branches(branch_id),
    CONSTRAINT ck_loans_type        CHECK (loan_type   IN ('Personal','Mortgage','Auto','Student','Business')),
    CONSTRAINT ck_loans_status      CHECK (status      IN ('Active','Paid Off','Defaulted','Delinquent')),
    CONSTRAINT ck_loans_principal   CHECK (principal_amount > 0),
    CONSTRAINT ck_loans_term        CHECK (term_months > 0)
);

CREATE TABLE loan_payments (
    payment_id      SERIAL                          NOT NULL,
    loan_id         INT                             NOT NULL,
    payment_date    DATE                            NOT NULL,
    scheduled_date  DATE                            NOT NULL,
    amount_paid     DECIMAL(15,2)                   NOT NULL,
    principal_paid  DECIMAL(15,2)   DEFAULT 0.00    NOT NULL,
    interest_paid   DECIMAL(15,2)   DEFAULT 0.00    NOT NULL,
    balance_after   DECIMAL(15,2)                   NOT NULL,
    is_late         BOOLEAN         DEFAULT FALSE   NOT NULL,
    days_late       SMALLINT        DEFAULT 0       NOT NULL,
    CONSTRAINT pk_loan_payments      PRIMARY KEY (payment_id),
    CONSTRAINT fk_loan_payments_loan FOREIGN KEY (loan_id) REFERENCES loans(loan_id),
    CONSTRAINT ck_loan_payments_amt  CHECK (amount_paid > 0)
);
