package com.rutzfin.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
public class LoanController {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @GetMapping("/api/loans/health")
    public List<Map<String, Object>> loanHealth() {
        String sql = """
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
            """;
        return jdbcTemplate.queryForList(sql);
    }
}
