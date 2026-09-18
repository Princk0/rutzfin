package com.rutzfin.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
public class AnalyticsController {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @GetMapping("/api/analytics/monthly-trends")
    public List<Map<String, Object>> monthlyTrends() {
        String sql = """
            SELECT
                txn_year,
                txn_month,
                month_start,
                SUM(transaction_count)         AS transaction_count,
                SUM(total_volume)              AS total_volume,
                ROUND(AVG(avg_transaction), 2) AS avg_transaction,
                SUM(total_inflow)              AS total_inflow,
                SUM(total_outflow)             AS total_outflow,
                SUM(flagged_count)             AS flagged_count
            FROM   vw_MonthlyTransactionSummary
            GROUP BY txn_year, txn_month, month_start
            ORDER BY month_start ASC;
            """;
        return jdbcTemplate.queryForList(sql);
    }

    @GetMapping("/api/analytics/customer-segments")
    public List<Map<String, Object>> customerSegments() {
        String sql = """
            WITH customer_totals AS (
                SELECT
                    c.customer_id,
                    c.first_name || ' ' || c.last_name   AS customer_name,
                    c.credit_score,
                    c.join_date,
                    SUM(a.balance)                       AS total_balance,
                    COUNT(DISTINCT a.account_id)         AS account_count
                FROM   customers  c
                JOIN   accounts   a  ON a.customer_id = c.customer_id
                                     AND a.status = 'Active'
                WHERE  c.is_active = TRUE
                GROUP BY c.customer_id, c.first_name, c.last_name, c.credit_score, c.join_date
            )
            SELECT
                customer_id,
                customer_name,
                credit_score,
                join_date,
                total_balance,
                account_count,
                RANK()  OVER (ORDER BY total_balance DESC)  AS balance_rank,
                NTILE(4) OVER (ORDER BY total_balance ASC)  AS value_quartile,
                CASE NTILE(4) OVER (ORDER BY total_balance ASC)
                    WHEN 4 THEN 'Platinum'
                    WHEN 3 THEN 'Gold'
                    WHEN 2 THEN 'Silver'
                    ELSE        'Standard'
                END                                         AS customer_tier,
                ROUND(
                    100.0 * total_balance
                          / NULLIF(SUM(total_balance) OVER (), 0),
                    4
                )                                           AS pct_of_portfolio
            FROM   customer_totals
            ORDER BY total_balance DESC;
            """;
        return jdbcTemplate.queryForList(sql);
    }
}
