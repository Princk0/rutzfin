-- ============================================================
-- Rutzfin: Banking Transaction Intelligence Platform
-- FILE: 05_functions.sql  (PostgreSQL version)
-- Replaces usp_TransferFunds T-SQL stored procedure with a
-- PL/pgSQL function.  Caller syntax:
--   SELECT new_reference_out, new_reference_in
--   FROM fn_transfer_funds(<from_id>, <to_id>, <amount>, <desc>);
-- ============================================================

CREATE OR REPLACE FUNCTION fn_transfer_funds(
    p_from_account_id   INT,
    p_to_account_id     INT,
    p_amount            DECIMAL(15,2),
    p_description       TEXT DEFAULT NULL,
    OUT new_reference_out VARCHAR(50),
    OUT new_reference_in  VARCHAR(50)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_low_id          INT;
    v_high_id         INT;
    v_from_balance    DECIMAL(15,2);
    v_from_type       VARCHAR(10);
    v_from_status     VARCHAR(10);
    v_to_balance      DECIMAL(15,2);
    v_to_status       VARCHAR(10);
    v_min_balance     DECIMAL(15,2);
    v_ts              TEXT;
    v_from_new_bal    DECIMAL(15,2);
    v_to_new_bal      DECIMAL(15,2);
BEGIN
    -- Input validation
    IF p_amount IS NULL OR p_amount <= 0 THEN
        RAISE EXCEPTION 'Transfer amount must be a positive value.';
    END IF;

    IF p_from_account_id = p_to_account_id THEN
        RAISE EXCEPTION 'Source and destination accounts must be different.';
    END IF;

    -- Deadlock prevention: always lock the lower account_id first
    v_low_id  := LEAST(p_from_account_id, p_to_account_id);
    v_high_id := GREATEST(p_from_account_id, p_to_account_id);

    PERFORM account_id FROM accounts WHERE account_id = v_low_id  FOR UPDATE;
    PERFORM account_id FROM accounts WHERE account_id = v_high_id FOR UPDATE;

    -- Fetch source account (already locked above)
    SELECT balance, account_type, status
    INTO   v_from_balance, v_from_type, v_from_status
    FROM   accounts
    WHERE  account_id = p_from_account_id;

    -- Fetch destination account
    SELECT balance, status
    INTO   v_to_balance, v_to_status
    FROM   accounts
    WHERE  account_id = p_to_account_id;

    -- Business rule validation
    IF v_from_status <> 'Active' THEN
        RAISE EXCEPTION 'Source account is not Active and cannot send funds.';
    END IF;

    IF v_to_status <> 'Active' THEN
        RAISE EXCEPTION 'Destination account is not Active and cannot receive funds.';
    END IF;

    -- Overdraft rule: Chequing allows -$500, all others require positive balance
    v_min_balance := CASE WHEN v_from_type = 'Chequing' THEN -500.00 ELSE 0.00 END;

    IF v_from_balance - p_amount < v_min_balance THEN
        RAISE EXCEPTION 'Insufficient funds — transfer would breach the minimum balance limit.';
    END IF;

    -- Generate unique reference numbers
    v_ts := TO_CHAR(NOW(), 'YYYYMMDDHH24MISS');
    new_reference_out := 'TRF-OUT-' || v_ts || '-' || p_from_account_id::TEXT;
    new_reference_in  := 'TRF-IN-'  || v_ts || '-' || p_to_account_id::TEXT;

    -- Compute new balances
    v_from_new_bal := v_from_balance - p_amount;
    v_to_new_bal   := v_to_balance   + p_amount;

    -- Insert Transfer_Out leg
    INSERT INTO transactions
        (account_id, transaction_type, amount, transaction_date,
         description, reference_number, balance_after, channel, is_flagged)
    VALUES
        (p_from_account_id, 'Transfer_Out', p_amount, NOW(),
         COALESCE(p_description, 'Transfer to account ' || p_to_account_id::TEXT),
         new_reference_out, v_from_new_bal, 'Online', FALSE);

    -- Insert Transfer_In leg
    INSERT INTO transactions
        (account_id, transaction_type, amount, transaction_date,
         description, reference_number, balance_after, channel, is_flagged)
    VALUES
        (p_to_account_id, 'Transfer_In', p_amount, NOW(),
         COALESCE(p_description, 'Transfer from account ' || p_from_account_id::TEXT),
         new_reference_in, v_to_new_bal, 'Online', FALSE);

    -- Update both account balances
    UPDATE accounts SET balance = v_from_new_bal WHERE account_id = p_from_account_id;
    UPDATE accounts SET balance = v_to_new_bal   WHERE account_id = p_to_account_id;
END;
$$;
