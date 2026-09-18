-- ============================================================
-- Rutzfin: Banking Transaction Intelligence Platform
-- FILE: 06_triggers.sql
-- PURPOSE: Automated business-rule enforcement via triggers
-- PLATFORM: Azure SQL / T-SQL
-- ============================================================

SET NOCOUNT ON;
GO

-- ============================================================
-- TRIGGER 1: trg_FraudDetection
-- Fires AFTER INSERT on transactions.
-- Evaluates three independent fraud rules against each newly
-- inserted transaction and inserts a fraud_alerts row for any
-- rule that fires. Also marks the transaction as is_flagged=1.
--
-- Rules:
--   (a) Statistical Anomaly  – amount > 3× 90-day avg AND
--       at least 5 prior transactions AND amount > $500
--   (b) After-Hours Activity – transaction between 00:00-03:59
--       AND amount > $1,000
--   (c) Large Transaction    – amount > $10,000 (always Critical)
-- ============================================================
CREATE OR ALTER TRIGGER trg_FraudDetection
ON transactions
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Build a CTE over the inserted rows enriched with 90-day stats
    ;WITH inserted_with_stats AS (
        SELECT
            i.transaction_id,
            i.account_id,
            i.amount,
            i.transaction_date,
            i.transaction_type,
            -- Historical average and count (excluding the current transaction)
            hist.avg_90d,
            hist.cnt_90d
        FROM inserted i
        CROSS APPLY (
            SELECT
                AVG(h.amount)   AS avg_90d,
                COUNT(*)        AS cnt_90d
            FROM   transactions h
            WHERE  h.account_id      = i.account_id
              AND  h.transaction_id  <> i.transaction_id
              AND  h.transaction_date >= DATEADD(DAY, -90, i.transaction_date)
        ) AS hist
    ),
    -- Evaluate each rule and produce one alert row per match
    alert_candidates AS (
        -- (a) Statistical Anomaly
        SELECT
            s.transaction_id,
            N'Statistical Anomaly'                              AS alert_type,
            N'Transaction amount ($' + CAST(s.amount AS NVARCHAR) +
            N') exceeds 3× the 90-day average ($' +
            CAST(ROUND(s.avg_90d, 2) AS NVARCHAR) +
            N') based on ' + CAST(s.cnt_90d AS NVARCHAR) +
            N' prior transactions.'                             AS alert_reason,
            N'High'                                             AS severity
        FROM   inserted_with_stats s
        WHERE  s.amount   > (3.0 * NULLIF(s.avg_90d, 0))
          AND  s.cnt_90d >= 5
          AND  s.amount   > 500.00

        UNION ALL

        -- (b) After-Hours Activity
        SELECT
            s.transaction_id,
            N'After-Hours Activity',
            N'Transaction of $' + CAST(s.amount AS NVARCHAR) +
            N' processed at ' +
            CONVERT(NVARCHAR(8), s.transaction_date, 108) +
            N' — falls within the 00:00–03:59 suspicious window.',
            N'Medium'
        FROM   inserted_with_stats s
        WHERE  DATEPART(HOUR, s.transaction_date) BETWEEN 0 AND 3
          AND  s.amount > 1000.00

        UNION ALL

        -- (c) Large Transaction
        SELECT
            s.transaction_id,
            N'Large Transaction',
            N'Transaction amount $' + CAST(s.amount AS NVARCHAR) +
            N' exceeds the $10,000 large-transaction reporting threshold.',
            N'Critical'
        FROM   inserted_with_stats s
        WHERE  s.amount > 10000.00
    )
    -- Insert fraud_alerts for every matched rule
    INSERT INTO fraud_alerts
        (transaction_id, alert_type, alert_reason, severity, created_at, is_resolved)
    SELECT
        ac.transaction_id,
        ac.alert_type,
        ac.alert_reason,
        ac.severity,
        GETDATE(),
        0
    FROM   alert_candidates ac;

    -- Mark all newly alerted transactions as is_flagged = 1
    UPDATE t
    SET    t.is_flagged = 1
    FROM   transactions t
    WHERE  t.transaction_id IN (
        SELECT DISTINCT fa.transaction_id
        FROM   fraud_alerts fa
        WHERE  fa.transaction_id IN (SELECT transaction_id FROM inserted)
          AND  fa.is_resolved = 0
    );
END;
GO

-- ============================================================
-- TRIGGER 2: trg_PreventSavingsOverdraft
-- Fires AFTER INSERT on transactions.
-- Rolls back any transaction that would drive a Savings, TFSA,
-- or RRSP account balance below $0. Chequing accounts are
-- excluded — their overdraft logic is handled in the transfer
-- procedure and at the application layer.
-- ============================================================
CREATE OR ALTER TRIGGER trg_PreventSavingsOverdraft
ON transactions
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Find accounts where the balance would have gone negative
    -- as a result of one of the inserted debit transactions
    IF EXISTS (
        SELECT 1
        FROM   inserted      i
        JOIN   accounts      a  ON a.account_id = i.account_id
        WHERE  a.account_type IN ('Savings', 'TFSA', 'RRSP')
          AND  i.transaction_type IN ('Payment', 'Withdrawal', 'Fee', 'Transfer_Out')
          AND  a.balance < 0.00  -- balance was already updated before trigger fires
    )
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR(
            N'Transaction rejected: Savings, TFSA, and RRSP accounts do not permit a negative balance.',
            16, 1
        );
    END
END;
GO

-- ============================================================
-- TRIGGER 3: trg_AccountStatusAudit
-- Fires AFTER UPDATE on accounts.
-- Creates the audit table if it does not already exist, then
-- records a row for every account whose status column changed.
-- ============================================================
CREATE OR ALTER TRIGGER trg_AccountStatusAudit
ON accounts
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Ensure the audit table exists (idempotent DDL inside trigger)
    IF OBJECT_ID(N'dbo.account_status_audit', N'U') IS NULL
    BEGIN
        CREATE TABLE dbo.account_status_audit (
            audit_id        INT             IDENTITY(1,1)           NOT NULL,
            account_id      INT                                     NOT NULL,
            account_number  NVARCHAR(20)                            NOT NULL,
            customer_id     INT                                     NOT NULL,
            old_status      NVARCHAR(10)                            NOT NULL,
            new_status      NVARCHAR(10)                            NOT NULL,
            changed_at      DATETIME2       DEFAULT GETDATE()       NOT NULL,
            changed_by      NVARCHAR(100)   DEFAULT SYSTEM_USER     NOT NULL,
            CONSTRAINT PK_account_status_audit PRIMARY KEY CLUSTERED (audit_id)
        );
    END

    -- Insert one audit row per account whose status actually changed
    INSERT INTO dbo.account_status_audit
        (account_id, account_number, customer_id, old_status, new_status, changed_at, changed_by)
    SELECT
        i.account_id,
        i.account_number,
        i.customer_id,
        d.status    AS old_status,
        i.status    AS new_status,
        GETDATE(),
        SYSTEM_USER
    FROM   inserted i
    JOIN   deleted  d  ON d.account_id = i.account_id
    WHERE  i.status <> d.status;   -- only record genuine status changes
END;
GO

PRINT N'Rutzfin: 3 triggers created successfully.';
GO
