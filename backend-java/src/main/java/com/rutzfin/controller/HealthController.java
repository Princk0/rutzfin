package com.rutzfin.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.Map;

@RestController
public class HealthController {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @GetMapping("/health")
    public Map<String, String> health() {
        String dbStatus;
        try {
            jdbcTemplate.queryForObject("SELECT 1", Integer.class);
            dbStatus = "connected";
        } catch (Exception e) {
            dbStatus = "error: " + e.getMessage();
        }
        Map<String, String> result = new LinkedHashMap<>();
        result.put("status", "ok");
        result.put("service", "rutzfin-api");
        result.put("database", dbStatus);
        return result;
    }
}
