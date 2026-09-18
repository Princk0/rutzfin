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
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(BranchController.class)
class BranchControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private JdbcTemplate jdbcTemplate;

    @Test
    void branchesReturnsPerformanceRows() throws Exception {
        List<Map<String, Object>> rows = new ArrayList<>();
        Map<String, Object> downtown = new HashMap<>();
        downtown.put("branch_name", "Downtown");
        downtown.put("total_deposits_on_hand", 45000.0);
        Map<String, Object> uptown = new HashMap<>();
        uptown.put("branch_name", "Uptown");
        uptown.put("total_deposits_on_hand", 32000.0);
        rows.add(downtown);
        rows.add(uptown);
        when(jdbcTemplate.queryForList(anyString())).thenReturn(rows);

        mockMvc.perform(get("/api/branches"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$[0].branch_name").value("Downtown"))
            .andExpect(jsonPath("$[1].branch_name").value("Uptown"));
    }
}
