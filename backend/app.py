"""
Rutzfin: Banking Transaction Intelligence Platform
FILE: app.py
PURPOSE: Flask REST API — bridges the Azure SQL database and the
         React front-end (Vite build served from /static).
RUNTIME: Python 3.11+  |  Flask 3.0  |  pyodbc 5.1
"""

import os
import pyodbc
from flask import Flask, request, jsonify, send_from_directory

app = Flask(__name__, static_folder="static", static_url_path="")


# ============================================================
# Database helpers
# ============================================================

def get_connection() -> pyodbc.Connection:
    """
    Return a pyodbc connection to Azure SQL using environment
    variables.  Raise a clear RuntimeError if any variable is
    missing so the misconfiguration is immediately obvious.
    """
    server   = os.environ.get("AZURE_SQL_SERVER")
    database = os.environ.get("AZURE_SQL_DATABASE")
    username = os.environ.get("AZURE_SQL_USERNAME")
    password = os.environ.get("AZURE_SQL_PASSWORD")

    missing = [v for v, k in [
        ("AZURE_SQL_SERVER",   server),
        ("AZURE_SQL_DATABASE", database),
        ("AZURE_SQL_USERNAME", username),
        ("AZURE_SQL_PASSWORD", password),
    ] if k is None]

    if missing:
        raise RuntimeError(f"Missing required environment variables: {', '.join(missing)}")

    connection_string = (
        f"DRIVER={{ODBC Driver 18 for SQL Server}};"
        f"SERVER={server};"
        f"DATABASE={database};"
        f"UID={username};"
        f"PWD={password};"
        f"Encrypt=yes;"
        f"TrustServerCertificate=no;"
        f"Connection Timeout=30;"
    )
    return pyodbc.connect(connection_string)


def query_db(sql: str, params: tuple = (), fetchone: bool = False):
    """
    Execute a SELECT query and return:
      - A single dict if fetchone=True (or None if no rows).
      - A list of dicts if fetchone=False.

    Each dict maps column names to Python values.
    """
    conn = get_connection()
    try:
        cursor = conn.cursor()
        cursor.execute(sql, params)
        columns = [col[0] for col in cursor.description]
        if fetchone:
            row = cursor.fetchone()
            return dict(zip(columns, row)) if row else None
        return [dict(zip(columns, row)) for row in cursor.fetchall()]
    finally:
        conn.close()


# ============================================================
# Health check
# ============================================================

@app.route("/health")
def health():
    """Simple liveness probe — also validates DB connectivity."""
    try:
        conn = get_connection()
        conn.close()
        db_status = "connected"
    except Exception as exc:
        db_status = f"error: {exc}"

    return jsonify({
        "status": "ok",
        "service": "rutzfin-api",
        "database": db_status,
    })


# ============================================================
# Dashboard
# ============================================================

@app.route("/api/dashboard")
def dashboard():
    """
    Single-query executive dashboard metrics.
    Returns totals for customers, accounts, deposits,
    recent transactions, fraud alerts, and loan portfolio.
    """
    sql = """
        SELECT
            (SELECT COUNT(*)          FROM customers    WHERE is_active = 1)           AS total_customers,
            (SELECT COUNT(*)          FROM accounts     WHERE status    = 'Active')     AS total_accounts,
            (SELECT ISNULL(SUM(balance), 0)
                                      FROM accounts     WHERE status    = 'Active')     AS total_deposits,
            (SELECT COUNT(*)          FROM transactions
                                      WHERE transaction_date >= DATEADD(DAY, -30, GETDATE()))
                                                                                        AS transactions_30d,
            (SELECT COUNT(*)          FROM fraud_alerts WHERE is_resolved = 0)          AS open_fraud_alerts,
            (SELECT COUNT(*)          FROM loans        WHERE status      = 'Active')   AS active_loans,
            (SELECT ISNULL(SUM(outstanding_balance), 0)
                                      FROM loans        WHERE status      = 'Active')   AS total_loan_book;
    """
    data = query_db(sql, fetchone=True)
    return jsonify(data)


# ============================================================
# Branches
# ============================================================

@app.route("/api/branches")
def branches():
    """Branch performance KPIs from vw_BranchPerformance."""
    sql = """
        SELECT *
        FROM   vw_BranchPerformance
        ORDER BY total_deposits_on_hand DESC;
    """
    return jsonify(query_db(sql))


# ============================================================
# Customers
# ============================================================

@app.route("/api/customers")
def customers():
    """
    Customer list with account summary.
    Uses DISTINCT on customer_id from vw_CustomerAccountSummary
    and window functions to aggregate across multiple accounts.
    """
    sql = """
        WITH ranked AS (
            SELECT
                customer_id,
                customer_name,
                email,
                customer_phone,
                credit_score,
                join_date,
                customer_city,
                customer_province,
                branch_name,
                current_balance,
                account_type,
                account_status,
                last_txn_date,
                last_txn_type,
                lifetime_deposits,
                lifetime_withdrawals,
                -- Total balance across all active accounts per customer
                SUM(current_balance) OVER (PARTITION BY customer_id)   AS total_balance,
                COUNT(account_id)    OVER (PARTITION BY customer_id)   AS account_count,
                ROW_NUMBER()         OVER (
                    PARTITION BY customer_id
                    ORDER BY     current_balance DESC
                )                                                       AS rn
            FROM   vw_CustomerAccountSummary
        )
        SELECT
            customer_id,
            customer_name,
            email,
            customer_phone,
            credit_score,
            join_date,
            customer_city,
            customer_province,
            branch_name,
            total_balance,
            account_count,
            last_txn_date,
            last_txn_type,
            lifetime_deposits,
            lifetime_withdrawals
        FROM   ranked
        WHERE  rn = 1
        ORDER BY total_balance DESC;
    """
    return jsonify(query_db(sql))


@app.route("/api/customers/<int:customer_id>")
def customer_detail(customer_id: int):
    """
    Full account summary for a single customer (all accounts).
    """
    sql = """
        SELECT *
        FROM   vw_CustomerAccountSummary
        WHERE  customer_id = ?
        ORDER BY current_balance DESC;
    """
    rows = query_db(sql, params=(customer_id,))
    if not rows:
        return jsonify({"error": "Customer not found or has no active accounts."}), 404
    return jsonify(rows)


# ============================================================
# Transactions
# ============================================================

@app.route("/api/transactions/<int:account_id>")
def transactions(account_id: int):
    """
    Recent transactions for a given account.
    Accepts an optional ?limit=N query parameter (default 50).
    """
    try:
        limit = int(request.args.get("limit", 50))
        limit = max(1, min(limit, 500))  # clamp between 1 and 500
    except (TypeError, ValueError):
        limit = 50

    sql = """
        SELECT TOP (?)
            t.transaction_id,
            t.transaction_type,
            t.amount,
            t.transaction_date,
            t.merchant_name,
            t.description,
            t.reference_number,
            t.balance_after,
            t.channel,
            t.is_flagged,
            mc.category_name
        FROM   transactions        t
        LEFT  JOIN merchant_categories mc ON mc.category_id = t.category_id
        WHERE  t.account_id = ?
        ORDER BY t.transaction_date DESC;
    """
    return jsonify(query_db(sql, params=(limit, account_id)))


# ============================================================
# Fraud
# ============================================================

@app.route("/api/fraud/alerts")
def fraud_alerts():
    """
    Open fraud alert queue ordered by severity (Critical first)
    then by creation time (newest first).
    """
    sql = """
        SELECT *
        FROM   vw_FraudAlertQueue
        ORDER BY
            CASE severity
                WHEN 'Critical' THEN 1
                WHEN 'High'     THEN 2
                WHEN 'Medium'   THEN 3
                ELSE                 4
            END ASC,
            created_at DESC;
    """
    return jsonify(query_db(sql))


# ============================================================
# Loans
# ============================================================

@app.route("/api/loans/health")
def loan_health():
    """Loan health dashboard ordered by risk severity."""
    sql = """
        SELECT *
        FROM   vw_LoanHealthDashboard
        ORDER BY
            CASE risk_rating
                WHEN 'Critical' THEN 1
                WHEN 'High'     THEN 2
                WHEN 'Medium'   THEN 3
                ELSE                 4
            END ASC,
            outstanding_balance DESC;
    """
    return jsonify(query_db(sql))


# ============================================================
# Analytics
# ============================================================

@app.route("/api/analytics/monthly-trends")
def monthly_trends():
    """
    Monthly transaction summary aggregated across all accounts,
    grouped by calendar month for trend charts.
    """
    sql = """
        SELECT
            txn_year,
            txn_month,
            month_start,
            SUM(transaction_count)  AS transaction_count,
            SUM(total_volume)       AS total_volume,
            ROUND(AVG(avg_transaction), 2) AS avg_transaction,
            SUM(total_inflow)       AS total_inflow,
            SUM(total_outflow)      AS total_outflow,
            SUM(flagged_count)      AS flagged_count
        FROM   vw_MonthlyTransactionSummary
        GROUP BY txn_year, txn_month, month_start
        ORDER BY month_start ASC;
    """
    return jsonify(query_db(sql))


@app.route("/api/analytics/customer-segments")
def customer_segments():
    """
    Customer value segmentation using NTILE(4) quartiles.
    Returns each customer's tier (Platinum/Gold/Silver/Standard)
    and their share of total portfolio deposits.
    """
    sql = """
        WITH customer_totals AS (
            SELECT
                c.customer_id,
                c.first_name + N' ' + c.last_name   AS customer_name,
                c.credit_score,
                c.join_date,
                SUM(a.balance)                       AS total_balance,
                COUNT(DISTINCT a.account_id)         AS account_count
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
            total_balance,
            account_count,
            RANK() OVER (ORDER BY total_balance DESC)       AS balance_rank,
            NTILE(4) OVER (ORDER BY total_balance ASC)      AS value_quartile,
            CASE NTILE(4) OVER (ORDER BY total_balance ASC)
                WHEN 4 THEN 'Platinum'
                WHEN 3 THEN 'Gold'
                WHEN 2 THEN 'Silver'
                ELSE        'Standard'
            END                                             AS customer_tier,
            ROUND(
                100.0 * total_balance
                      / NULLIF(SUM(total_balance) OVER (), 0),
                4
            )                                               AS pct_of_portfolio
        FROM   customer_totals
        ORDER BY total_balance DESC;
    """
    return jsonify(query_db(sql))


# ============================================================
# Transfers
# ============================================================

@app.route("/api/transfer", methods=["POST"])
def transfer():
    """
    Execute a fund transfer between two accounts.

    Request JSON body:
        {
            "from_account_id": 1,
            "to_account_id":   3,
            "amount":          500.00,
            "description":     "Rent payment"   (optional)
        }

    Returns the two generated reference numbers on success.
    """
    body = request.get_json(silent=True)
    if not body:
        return jsonify({"error": "Request body must be JSON."}), 400

    from_id     = body.get("from_account_id")
    to_id       = body.get("to_account_id")
    amount      = body.get("amount")
    description = body.get("description", "")

    if None in (from_id, to_id, amount):
        return jsonify({"error": "from_account_id, to_account_id, and amount are required."}), 400

    try:
        amount = float(amount)
    except (TypeError, ValueError):
        return jsonify({"error": "amount must be a numeric value."}), 400

    conn = get_connection()
    try:
        cursor = conn.cursor()
        cursor.execute(
            "{CALL usp_TransferFunds(?, ?, ?, ?, ?, ?)}",
            (from_id, to_id, amount, description, "", ""),
        )
        # Fetch OUTPUT parameters — pyodbc returns them as an additional row
        # when using the CALL syntax with OUTPUT params represented as empty strings.
        # A more robust pattern uses named params via a direct EXEC statement.
        cursor.execute(
            """
            DECLARE @ref_out NVARCHAR(50), @ref_in NVARCHAR(50);
            EXEC usp_TransferFunds
                @from_account_id   = ?,
                @to_account_id     = ?,
                @amount            = ?,
                @description       = ?,
                @new_reference_out = @ref_out OUTPUT,
                @new_reference_in  = @ref_in  OUTPUT;
            SELECT @ref_out AS reference_out, @ref_in AS reference_in;
            """,
            (from_id, to_id, amount, description),
        )
        row = cursor.fetchone()
        conn.commit()
        return jsonify({
            "success": True,
            "reference_out": row[0] if row else None,
            "reference_in":  row[1] if row else None,
        })
    except pyodbc.Error as exc:
        conn.rollback()
        error_msg = str(exc)
        # Surface the inner RAISERROR message to the caller
        if exc.args and len(exc.args) > 1:
            error_msg = exc.args[1]
        return jsonify({"error": error_msg}), 400
    finally:
        conn.close()


# ============================================================
# React SPA fallback — serve Vite build from /static
# ============================================================

@app.route("/")
def serve_index():
    """Serve the React application index page."""
    return send_from_directory(app.static_folder, "index.html")


@app.route("/<path:path>")
def serve_static(path: str):
    """
    Serve static assets (JS, CSS, images) from the Vite build
    output directory.  If the file does not exist, fall back to
    index.html so that client-side routing works correctly.
    """
    static_path = os.path.join(app.static_folder, path)
    if os.path.exists(static_path):
        return send_from_directory(app.static_folder, path)
    return send_from_directory(app.static_folder, "index.html")


# ============================================================
# Entry point
# ============================================================

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8000))
    debug = os.environ.get("FLASK_DEBUG", "false").lower() == "true"
    app.run(host="0.0.0.0", port=port, debug=debug)
