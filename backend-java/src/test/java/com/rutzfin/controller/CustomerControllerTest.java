package com.rutzfin.controller;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(CustomerController.class)
class CustomerControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private JdbcTemplate jdbcTemplate;

    @Test
    void customersReturnsCustomerRows() throws Exception {
        List<Map<String, Object>> rows = new ArrayList<>();
        Map<String, Object> row = new HashMap<>();
        row.put("customer_id", 42);
        row.put("customer_name", "Alice");
        row.put("total_balance", 5000.0);
        rows.add(row);
        when(jdbcTemplate.queryForList(anyString())).thenReturn(rows);

        mockMvc.perform(get("/api/customers"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$[0].customer_id").value(42))
            .andExpect(jsonPath("$[0].customer_name").value("Alice"));
    }

    @Test
    void customerDetailReturnsCustomerRowsWhenCustomerExists() throws Exception {
        List<Map<String, Object>> rows = new ArrayList<>();
        Map<String, Object> row = new HashMap<>();
        row.put("customer_id", 42);
        row.put("customer_name", "Alice");
        row.put("current_balance", 2500.0);
        rows.add(row);
        when(jdbcTemplate.queryForList(anyString(), eq(42))).thenReturn(rows);

        mockMvc.perform(get("/api/customers/{customerId}", 42))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$[0].customer_id").value(42))
            .andExpect(jsonPath("$[0].customer_name").value("Alice"));
    }

    @Test
    void customerDetailReturnsNotFoundWhenCustomerHasNoAccounts() throws Exception {
        when(jdbcTemplate.queryForList(anyString(), eq(99))).thenReturn(List.of());

        mockMvc.perform(get("/api/customers/{customerId}", 99))
            .andExpect(status().isNotFound())
            .andExpect(jsonPath("$.error").value("Customer not found or has no active accounts."));
    }
}
