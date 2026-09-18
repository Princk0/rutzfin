package com.rutzfin.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataAccessException;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.Map;

@RestController
public class TransferController {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @PostMapping("/api/transfer")
    public ResponseEntity<Map<String, Object>> transfer(@RequestBody(required = false) Map<String, Object> body) {
        if (body == null) {
            return badRequest("Request body must be JSON.");
        }

        Object fromIdObj   = body.get("from_account_id");
        Object toIdObj     = body.get("to_account_id");
        Object amountObj   = body.get("amount");
        String description = body.getOrDefault("description", "").toString();

        if (fromIdObj == null || toIdObj == null || amountObj == null) {
            return badRequest("from_account_id, to_account_id, and amount are required.");
        }

        int fromId, toId;
        BigDecimal amount;
        try {
            fromId = ((Number) fromIdObj).intValue();
            toId   = ((Number) toIdObj).intValue();
            amount = new BigDecimal(amountObj.toString());
        } catch (Exception e) {
            return badRequest("amount must be a numeric value.");
        }

        try {
            Map<String, Object> row = jdbcTemplate.queryForMap(
                "SELECT new_reference_out, new_reference_in FROM fn_transfer_funds(?, ?, ?, ?)",
                fromId, toId, amount, description
            );
            Map<String, Object> result = new LinkedHashMap<>();
            result.put("success", true);
            result.put("reference_out", row.get("new_reference_out"));
            result.put("reference_in",  row.get("new_reference_in"));
            return ResponseEntity.ok(result);
        } catch (DataAccessException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMostSpecificCause().getMessage()));
        }
    }

    private ResponseEntity<Map<String, Object>> badRequest(String message) {
        return ResponseEntity.badRequest().body(Map.of("error", message));
    }
}
