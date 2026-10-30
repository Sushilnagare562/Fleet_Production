package com.logisticfleet.controller;

import com.logisticfleet.dto.ExpenseDtos.ExpenseRequest;
import com.logisticfleet.dto.ExpenseDtos.ExpenseResponse;
import com.logisticfleet.security.CurrentUserResolver;
import com.logisticfleet.service.ExpenseService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
@Slf4j
@RestController
@RequestMapping("/api/expenses")
@RequiredArgsConstructor
public class ExpenseController {

    private final ExpenseService expenseService;
    private final CurrentUserResolver currentUserResolver;

    @PostMapping
    public ResponseEntity<ExpenseResponse> addExpense(@Valid @RequestBody ExpenseRequest req) {
        Long driverId = currentUserResolver.getCurrentUserId();
        Long tenantId = currentUserResolver.getCurrentTenantId();
        return ResponseEntity.ok(expenseService.addExpense(tenantId, driverId, req));
    }

    @GetMapping("/my")
    public ResponseEntity<List<ExpenseResponse>> myExpenses() {
        Long driverId = currentUserResolver.getCurrentUserId();
        return ResponseEntity.ok(expenseService.getExpensesForDriver(driverId));
    }
}
