package com.rutzfin.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
public class CustomerController {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @GetMapping("/api/customers")
    public List<Map<String, Object>> customers() {
        String sql = """
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
            """;
        return jdbcTemplate.queryForList(sql);
    }

    @GetMapping("/api/customers/{customerId}")
    public ResponseEntity<?> customerDetail(@PathVariable int customerId) {
        String sql = """
            SELECT *
            FROM   vw_CustomerAccountSummary
            WHERE  customer_id = ?
            ORDER BY current_balance DESC;
            """;
        List<Map<String, Object>> rows = jdbcTemplate.queryForList(sql, customerId);
        if (rows.isEmpty()) {
            return ResponseEntity.status(404)
                .body(Map.of("error", "Customer not found or has no active accounts."));
        }
        return ResponseEntity.ok(rows);
    }
}
