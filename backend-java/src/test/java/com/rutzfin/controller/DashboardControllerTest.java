package com.rutzfin.controller;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;

import java.util.HashMap;
import java.util.Map;

import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(DashboardController.class)
class DashboardControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private JdbcTemplate jdbcTemplate;

    @Test
    void dashboardReturnsMetricsFromQuery() throws Exception {
        Map<String, Object> stats = new HashMap<>();
        stats.put("total_customers", 120);
        stats.put("total_accounts", 360);
        stats.put("total_deposits", 500000.0);
        stats.put("transactions_30d", 1500);
        stats.put("open_fraud_alerts", 9);
        stats.put("active_loans", 33);
        stats.put("total_loan_book", 250000.0);
        when(jdbcTemplate.queryForMap(anyString())).thenReturn(stats);

        mockMvc.perform(get("/api/dashboard"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.total_customers").value(120))
            .andExpect(jsonPath("$.total_accounts").value(360))
            .andExpect(jsonPath("$.open_fraud_alerts").value(9));
    }
}
