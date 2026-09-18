package com.rutzfin.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
public class BranchController {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @GetMapping("/api/branches")
    public List<Map<String, Object>> branches() {
        return jdbcTemplate.queryForList(
            "SELECT * FROM vw_BranchPerformance ORDER BY total_deposits_on_hand DESC;"
        );
    }
}
