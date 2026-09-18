package com.rutzfin.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
public class TransactionController {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @GetMapping("/api/transactions/{accountId}")
    public List<Map<String, Object>> transactions(
            @PathVariable int accountId,
            @RequestParam(defaultValue = "50") int limit) {

        int clamped = Math.max(1, Math.min(limit, 500));

        String sql = """
            SELECT
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
            ORDER BY t.transaction_date DESC
            LIMIT ?
            """;

        // accountId maps to first ?, clamped (LIMIT) maps to second ?
        return jdbcTemplate.queryForList(sql, accountId, clamped);
    }
}
