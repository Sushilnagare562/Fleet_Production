package com.logisticfleet.controller;

import com.logisticfleet.dto.ExpenseDtos.AdminExpenseRequest;
import com.logisticfleet.dto.ExpenseDtos.ExpenseResponse;
import com.logisticfleet.dto.ExpenseDtos.ExpenseStatusRequest;
import com.logisticfleet.security.CurrentUserResolver;
import com.logisticfleet.service.ExpenseService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** Admin-only expense review. Locked to ROLE_ADMIN via /api/admin/** in SecurityConfig. */
@Slf4j
@RestController
@RequestMapping("/api/admin/expenses")
@RequiredArgsConstructor
public class AdminExpenseController {

    private final ExpenseService expenseService;
    private final CurrentUserResolver currentUserResolver;

    /** Admin logs an expense on a driver's behalf (e.g. a paper receipt); saved as already approved. */
    @PostMapping
    public ResponseEntity<ExpenseResponse> createExpense(@Valid @RequestBody AdminExpenseRequest req) {
        return ResponseEntity.ok(expenseService.createExpenseByAdmin(currentUserResolver.getCurrentTenantId(), req));
    }

    @GetMapping
    public ResponseEntity<List<ExpenseResponse>> getAllExpenses() {
        return ResponseEntity.ok(expenseService.getAllExpenses(currentUserResolver.getCurrentTenantId()));
    }

    @PatchMapping("/{expenseId}/status")
    public ResponseEntity<ExpenseResponse> reviewExpense(@PathVariable Long expenseId,
                                                           @Valid @RequestBody ExpenseStatusRequest req) {
        return ResponseEntity.ok(
                expenseService.reviewExpense(currentUserResolver.getCurrentTenantId(), expenseId, req));

    }
}
