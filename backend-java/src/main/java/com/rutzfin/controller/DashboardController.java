package com.rutzfin.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class DashboardController {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @GetMapping("/api/dashboard")
    public Map<String, Object> dashboard() {
        String sql = """
            SELECT
                (SELECT COUNT(*)                    FROM customers   WHERE is_active = TRUE)               AS total_customers,
                (SELECT COUNT(*)                    FROM accounts    WHERE status    = 'Active')            AS total_accounts,
                (SELECT COALESCE(SUM(balance), 0)   FROM accounts    WHERE status    = 'Active')            AS total_deposits,
                (SELECT COUNT(*)                    FROM transactions
                                                    WHERE transaction_date >= NOW() - INTERVAL '30 days')   AS transactions_30d,
                (SELECT COUNT(*)                    FROM fraud_alerts WHERE is_resolved = FALSE)            AS open_fraud_alerts,
                (SELECT COUNT(*)                    FROM loans        WHERE status     = 'Active')          AS active_loans,
                (SELECT COALESCE(SUM(outstanding_balance), 0)
                                                    FROM loans        WHERE status     = 'Active')          AS total_loan_book
            """;
        return jdbcTemplate.queryForMap(sql);
    }
}
