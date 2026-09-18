package com.rutzfin.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
public class FraudController {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @GetMapping("/api/fraud/alerts")
    public List<Map<String, Object>> fraudAlerts() {
        String sql = """
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
            """;
        return jdbcTemplate.queryForList(sql);
    }
}
