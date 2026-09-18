-- ============================================================
-- Rutzfin: Banking Transaction Intelligence Platform
-- FILE: 05_stored_procedures.sql
-- PURPOSE: Core transactional stored procedures
-- PLATFORM: Azure SQL / T-SQL
-- ============================================================

SET NOCOUNT ON;
GO

-- ============================================================
-- PROCEDURE 1: usp_TransferFunds
-- Atomically moves funds between two accounts.
-- Supports a -$500 overdraft limit for Chequing accounts.
-- Returns generated reference numbers for both legs via OUTPUT.
-- ============================================================
CREATE OR ALTER PROCEDURE usp_TransferFunds
    @from_account_id    INT,
    @to_account_id      INT,
    @amount             DECIMAL(15,2),
    @description        NVARCHAR(500)   = NULL,
    @new_reference_out  NVARCHAR(50)    OUTPUT,   -- Transfer_Out reference
    @new_reference_in   NVARCHAR(50)    OUTPUT    -- Transfer_In  reference
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- ---- Input validation ----------------------------------------
    IF @amount IS NULL OR @amount <= 0
        THROW 50001, 'Transfer amount must be a positive value.', 1;

    IF @from_account_id = @to_account_id
        THROW 50002, 'Source and destination accounts must be different.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Lock both rows in a consistent order to prevent deadlocks.
        -- Always acquire the lower account_id lock first.
        DECLARE @low_id  INT = CASE WHEN @from_account_id < @to_account_id
                                    THEN @from_account_id ELSE @to_account_id END;
        DECLARE @high_id INT = CASE WHEN @from_account_id < @to_account_id
                                    THEN @to_account_id   ELSE @from_account_id END;

        -- Acquire UPDLOCK on both rows
        DECLARE @from_balance    DECIMAL(15,2);
        DECLARE @from_type       NVARCHAR(10);
        DECLARE @from_status     NVARCHAR(10);
        DECLARE @to_status       NVARCHAR(10);

        SELECT @from_balance = a.balance,
               @from_type   = a.account_type,
               @from_status = a.status
        FROM   accounts a WITH (UPDLOCK, ROWLOCK)
        WHERE  a.account_id = @low_id;

        SELECT @to_status = a.status
        FROM   accounts a WITH (UPDLOCK, ROWLOCK)
        WHERE  a.account_id = @high_id;

        -- If source was the high_id, re-fetch correctly
        IF @from_account_id = @high_id
        BEGIN
            SELECT @from_balance = a.balance,
                   @from_type   = a.account_type,
                   @from_status = a.status
            FROM   accounts a
            WHERE  a.account_id = @from_account_id;

            SELECT @to_status = a.status
            FROM   accounts a
            WHERE  a.account_id = @to_account_id;
        END

        -- ---- Business rule validation ----------------------------
        IF @from_status <> 'Active'
            THROW 50003, 'Source account is not Active and cannot send funds.', 1;

        IF @to_status <> 'Active'
            THROW 50004, 'Destination account is not Active and cannot receive funds.', 1;

        -- Overdraft rule: Chequing allows -$500, all others require sufficient balance
        DECLARE @min_balance DECIMAL(15,2) = CASE WHEN @from_type = 'Chequing' THEN -500.00 ELSE 0.00 END;

        IF @from_balance - @amount < @min_balance
            THROW 50005, 'Insufficient funds — transfer would breach the minimum balance limit.', 1;

        -- ---- Generate unique reference numbers -------------------
        DECLARE @ts NVARCHAR(20) = REPLACE(REPLACE(REPLACE(
                    CONVERT(NVARCHAR(20), GETDATE(), 120), '-', ''), ' ', ''), ':', '');

        SET @new_reference_out = N'TRF-OUT-' + @ts + N'-' + CAST(@from_account_id AS NVARCHAR(10));
        SET @new_reference_in  = N'TRF-IN-'  + @ts + N'-' + CAST(@to_account_id   AS NVARCHAR(10));

        -- ---- Compute new balances --------------------------------
        DECLARE @from_balance_after DECIMAL(15,2) = @from_balance - @amount;

        DECLARE @to_balance_before  DECIMAL(15,2);
        SELECT @to_balance_before = balance FROM accounts WHERE account_id = @to_account_id;
        DECLARE @to_balance_after   DECIMAL(15,2) = @to_balance_before + @amount;

        -- ---- Insert Transfer_Out leg -----------------------------
        INSERT INTO transactions
            (account_id, transaction_type, amount, transaction_date,
             description, reference_number, balance_after, channel, is_flagged)
        VALUES
            (@from_account_id, 'Transfer_Out', @amount, GETDATE(),
             ISNULL(@description, N'Transfer to account ' + CAST(@to_account_id AS NVARCHAR)),
             @new_reference_out, @from_balance_after, 'Online', 0);

        -- ---- Insert Transfer_In leg ------------------------------
        INSERT INTO transactions
            (account_id, transaction_type, amount, transaction_date,
             description, reference_number, balance_after, channel, is_flagged)
        VALUES
            (@to_account_id, 'Transfer_In', @amount, GETDATE(),
             ISNULL(@description, N'Transfer from account ' + CAST(@from_account_id AS NVARCHAR)),
             @new_reference_in, @to_balance_after, 'Online', 0);

        -- ---- Update both account balances ------------------------
        UPDATE accounts
        SET    balance = @from_balance_after
        WHERE  account_id = @from_account_id;

        UPDATE accounts
        SET    balance = @to_balance_after
        WHERE  account_id = @to_account_id;

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        DECLARE @err_msg    NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @err_sev    INT            = ERROR_SEVERITY();
        DECLARE @err_state  INT            = ERROR_STATE();

        RAISERROR(@err_msg, @err_sev, @err_state);
    END CATCH;
END;
GO

-- ============================================================
-- PROCEDURE 2: usp_GenerateMonthlyStatement
-- Returns 3 result sets for a given account and period:
--   RS1 – Account/customer header with opening balance and totals
--   RS2 – Transaction list with running balance (window function)
--   RS3 – Spending breakdown by category with pct_of_total
-- ============================================================
CREATE OR ALTER PROCEDURE usp_GenerateMonthlyStatement
    @account_id         INT,
    @statement_year     SMALLINT,
    @statement_month    TINYINT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- ---- Date range -----------------------------------------
        DECLARE @period_start DATETIME2 = CAST(DATEFROMPARTS(@statement_year, @statement_month, 1)     AS DATETIME2);
        DECLARE @period_end   DATETIME2 = CAST(DATEADD(MONTH, 1, DATEFROMPARTS(@statement_year, @statement_month, 1)) AS DATETIME2);

        -- ---- Validate account -----------------------------------
        IF NOT EXISTS (SELECT 1 FROM accounts WHERE account_id = @account_id)
            THROW 50010, 'Account not found.', 1;

        -- ---- RS1: Account / customer header ---------------------
        -- Opening balance = current balance minus net change in the period
        SELECT
            a.account_id,
            a.account_number,
            a.account_type,
            a.status,
            a.interest_rate,
            c.customer_id,
            c.first_name + N' ' + c.last_name          AS customer_name,
            c.email,
            b.branch_name,

            -- Period stats
            @period_start                               AS period_start,
            DATEADD(SECOND, -1, @period_end)            AS period_end,

            -- Net change during the period
            ISNULL(SUM(CASE WHEN t.transaction_type IN ('Deposit','Transfer_In','Interest')
                             THEN  t.amount
                             WHEN t.transaction_type IN ('Payment','Withdrawal','Fee','Transfer_Out')
                             THEN -t.amount
                             ELSE 0 END), 0)             AS period_net,

            -- Opening balance derived from current balance
            a.balance - ISNULL(SUM(CASE
                WHEN t.transaction_type IN ('Deposit','Transfer_In','Interest')    THEN  t.amount
                WHEN t.transaction_type IN ('Payment','Withdrawal','Fee','Transfer_Out') THEN -t.amount
                ELSE 0 END), 0)                          AS opening_balance,

            a.balance                                    AS closing_balance,

            -- Credit / debit totals
            ISNULL(SUM(CASE WHEN t.transaction_type IN ('Deposit','Transfer_In','Interest')
                             THEN t.amount ELSE 0 END), 0) AS total_credits,
            ISNULL(SUM(CASE WHEN t.transaction_type IN ('Payment','Withdrawal','Fee','Transfer_Out')
                             THEN t.amount ELSE 0 END), 0) AS total_debits,

            COUNT(t.transaction_id)                      AS transaction_count

        FROM   accounts     a
        JOIN   customers    c  ON c.customer_id = a.customer_id
        JOIN   branches     b  ON b.branch_id   = a.branch_id
        LEFT  JOIN transactions t
               ON t.account_id      = a.account_id
              AND t.transaction_date >= @period_start
              AND t.transaction_date <  @period_end
        WHERE  a.account_id = @account_id
        GROUP BY
            a.account_id, a.account_number, a.account_type,
            a.status, a.interest_rate, a.balance,
            c.customer_id, c.first_name, c.last_name, c.email,
            b.branch_name;

        -- ---- RS2: Transaction list with running balance ----------
        WITH period_txns AS (
            SELECT
                t.transaction_id,
                t.transaction_date,
                t.transaction_type,
                t.merchant_name,
                t.description,
                t.reference_number,
                t.channel,
                t.amount,
                t.is_flagged,
                mc.category_name,
                -- Net signed amount for running balance
                CASE
                    WHEN t.transaction_type IN ('Deposit','Transfer_In','Interest')    THEN  t.amount
                    WHEN t.transaction_type IN ('Payment','Withdrawal','Fee','Transfer_Out') THEN -t.amount
                    ELSE 0
                END AS net_amount
            FROM   transactions       t
            LEFT  JOIN merchant_categories mc ON mc.category_id = t.category_id
            WHERE  t.account_id      = @account_id
              AND  t.transaction_date >= @period_start
              AND  t.transaction_date <  @period_end
        )
        SELECT
            transaction_id,
            transaction_date,
            transaction_type,
            merchant_name,
            description,
            reference_number,
            channel,
            amount,
            net_amount,
            category_name,
            is_flagged,
            -- Compute opening balance first, then add running net
            (
                SELECT a.balance FROM accounts a WHERE a.account_id = @account_id
            )
            - (
                SELECT ISNULL(SUM(CASE
                    WHEN t2.transaction_type IN ('Deposit','Transfer_In','Interest')           THEN  t2.amount
                    WHEN t2.transaction_type IN ('Payment','Withdrawal','Fee','Transfer_Out')  THEN -t2.amount
                    ELSE 0 END), 0)
                FROM transactions t2
                WHERE t2.account_id      = @account_id
                  AND t2.transaction_date >= @period_start
                  AND t2.transaction_date <  @period_end
            )
            + SUM(net_amount) OVER (
                ORDER BY transaction_date ASC, transaction_id ASC
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            )                                           AS running_balance
        FROM   period_txns
        ORDER BY transaction_date ASC, transaction_id ASC;

        -- ---- RS3: Spending by category with pct_of_total --------
        SELECT
            ISNULL(mc.category_name, N'Uncategorised')  AS category_name,
            COUNT(*)                                     AS txn_count,
            SUM(t.amount)                                AS category_spend,
            -- Percentage of total spend in the period
            ROUND(
                100.0 * SUM(t.amount)
                      / NULLIF(SUM(SUM(t.amount)) OVER (), 0),
                2)                                       AS pct_of_total
        FROM   transactions        t
        LEFT  JOIN merchant_categories mc ON mc.category_id = t.category_id
        WHERE  t.account_id       = @account_id
          AND  t.transaction_date >= @period_start
          AND  t.transaction_date <  @period_end
          AND  t.transaction_type IN ('Payment','Withdrawal','Fee')
        GROUP BY mc.category_name
        ORDER BY category_spend DESC;

    END TRY
    BEGIN CATCH
        DECLARE @err_msg   NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @err_sev   INT            = ERROR_SEVERITY();
        DECLARE @err_state INT            = ERROR_STATE();
        RAISERROR(@err_msg, @err_sev, @err_state);
    END CATCH;
END;
GO

-- ============================================================
-- PROCEDURE 3: usp_ProcessLoanPayment
-- Records a loan payment, splits it into principal/interest,
-- updates outstanding balance, and transitions loan status.
-- Returns new payment_id via OUTPUT parameter.
-- ============================================================
CREATE OR ALTER PROCEDURE usp_ProcessLoanPayment
    @loan_id            INT,
    @payment_amount     DECIMAL(15,2),
    @payment_date       DATE,
    @scheduled_date     DATE,
    @payment_id_out     INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @payment_amount IS NULL OR @payment_amount <= 0
        THROW 50020, 'Payment amount must be a positive value.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- ---- Fetch loan details with update lock ----------------
        DECLARE @outstanding    DECIMAL(15,2);
        DECLARE @rate           DECIMAL(5,4);
        DECLARE @loan_status    NVARCHAR(12);
        DECLARE @term_months    SMALLINT;

        SELECT
            @outstanding  = l.outstanding_balance,
            @rate         = l.interest_rate,
            @loan_status  = l.status,
            @term_months  = l.term_months
        FROM   loans l WITH (UPDLOCK, ROWLOCK)
        WHERE  l.loan_id = @loan_id;

        IF @outstanding IS NULL
            THROW 50021, 'Loan not found.', 1;

        IF @loan_status IN ('Paid Off', 'Defaulted')
            THROW 50022, 'Cannot process payment on a Paid Off or Defaulted loan.', 1;

        -- ---- Interest/principal split (simple monthly interest) -
        DECLARE @interest_portion  DECIMAL(15,2) = ROUND(@outstanding * (@rate / 12.0), 2);
        DECLARE @principal_portion DECIMAL(15,2);

        -- If payment does not cover full interest, all goes to interest
        IF @payment_amount <= @interest_portion
        BEGIN
            SET @interest_portion  = @payment_amount;
            SET @principal_portion = 0.00;
        END
        ELSE
        BEGIN
            SET @principal_portion = @payment_amount - @interest_portion;
        END

        -- ---- New outstanding balance -----------------------------
        DECLARE @new_balance DECIMAL(15,2) = @outstanding - @principal_portion;
        IF @new_balance < 0 SET @new_balance = 0.00;

        -- ---- Determine lateness ---------------------------------
        DECLARE @days_late SMALLINT = 0;
        DECLARE @is_late   BIT      = 0;

        IF @payment_date > @scheduled_date
        BEGIN
            SET @days_late = CAST(DATEDIFF(DAY, @scheduled_date, @payment_date) AS SMALLINT);
            SET @is_late   = 1;
        END

        -- ---- Insert payment record ------------------------------
        INSERT INTO loan_payments
            (loan_id, payment_date, scheduled_date, amount_paid,
             principal_paid, interest_paid, balance_after, is_late, days_late)
        VALUES
            (@loan_id, @payment_date, @scheduled_date, @payment_amount,
             @principal_portion, @interest_portion, @new_balance, @is_late, @days_late);

        SET @payment_id_out = SCOPE_IDENTITY();

        -- ---- Update loan status and balance ---------------------
        DECLARE @new_status NVARCHAR(12);

        IF @new_balance <= 0
            SET @new_status = 'Paid Off';
        ELSE IF @days_late > 30
            SET @new_status = 'Delinquent';
        ELSE
            SET @new_status = 'Active';

        UPDATE loans
        SET    outstanding_balance = @new_balance,
               status              = @new_status
        WHERE  loan_id = @loan_id;

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        DECLARE @err_msg   NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @err_sev   INT            = ERROR_SEVERITY();
        DECLARE @err_state INT            = ERROR_STATE();
        RAISERROR(@err_msg, @err_sev, @err_state);
    END CATCH;
END;
GO

-- ============================================================
-- PROCEDURE 4: usp_ResolveFraudAlert
-- Marks a fraud alert as resolved. Optionally clears the
-- is_flagged flag on the underlying transaction.
-- ============================================================
CREATE OR ALTER PROCEDURE usp_ResolveFraudAlert
    @alert_id       INT,
    @resolved_by    NVARCHAR(100),
    @clear_flag     BIT = 0        -- 1 = also clear is_flagged on the transaction
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @resolved_by IS NULL OR LEN(LTRIM(RTRIM(@resolved_by))) = 0
        THROW 50030, '@resolved_by cannot be empty.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- ---- Validate alert exists and is open ------------------
        DECLARE @txn_id     INT;
        DECLARE @is_resolved BIT;

        SELECT @txn_id      = fa.transaction_id,
               @is_resolved = fa.is_resolved
        FROM   fraud_alerts fa WITH (UPDLOCK, ROWLOCK)
        WHERE  fa.alert_id = @alert_id;

        IF @txn_id IS NULL
            THROW 50031, 'Fraud alert not found.', 1;

        IF @is_resolved = 1
            THROW 50032, 'Fraud alert is already resolved.', 1;

        -- ---- Resolve the alert ----------------------------------
        UPDATE fraud_alerts
        SET    is_resolved = 1,
               resolved_at = GETDATE(),
               resolved_by = @resolved_by
        WHERE  alert_id = @alert_id;

        -- ---- Optionally clear the transaction flag --------------
        IF @clear_flag = 1
        BEGIN
            UPDATE transactions
            SET    is_flagged = 0
            WHERE  transaction_id = @txn_id;
        END

        COMMIT TRANSACTION;

        -- Return confirmation row
        SELECT
            fa.alert_id,
            fa.alert_type,
            fa.severity,
            fa.resolved_at,
            fa.resolved_by,
            t.transaction_id,
            t.is_flagged     AS transaction_flag_cleared
        FROM   fraud_alerts fa
        JOIN   transactions t ON t.transaction_id = fa.transaction_id
        WHERE  fa.alert_id = @alert_id;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        DECLARE @err_msg   NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @err_sev   INT            = ERROR_SEVERITY();
        DECLARE @err_state INT            = ERROR_STATE();
        RAISERROR(@err_msg, @err_sev, @err_state);
    END CATCH;
END;
GO

PRINT N'Rutzfin: 4 stored procedures created successfully.';
GO
