package com.logisticfleet.dto;

import com.logisticfleet.entity.ExpenseCategory;
import com.logisticfleet.entity.ExpenseStatus;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;

public class ExpenseDtos {

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ExpenseRequest {
        private Long tripId;
        @NotNull
        private ExpenseCategory category;
        @NotNull
        private BigDecimal amount;
        private String description;
        private String receiptUrl;
        @NotNull
        private LocalDate expenseDate;
    }

    /**
     * Lets an admin log an expense on a driver's behalf (e.g. a fuel receipt
     * handed in on paper). Mirrors {@link ExpenseRequest} plus the target
     * driver, and is auto-approved since an admin is entering it directly.
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AdminExpenseRequest {
        @NotNull
        private Long driverId;
        private Long tripId;
        @NotNull
        private ExpenseCategory category;
        @NotNull
        private BigDecimal amount;
        private String description;
        private String receiptUrl;
        @NotNull
        private LocalDate expenseDate;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ExpenseStatusRequest {
        @NotNull
        private ExpenseStatus status;
        private String reviewNotes;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ExpenseResponse {
        private Long id;
        private Long tripId;
        private Long driverId;
        private String driverName;
        private ExpenseCategory category;
        private BigDecimal amount;
        private String description;
        private String receiptUrl;
        private LocalDate expenseDate;
        private ExpenseStatus status;
        private String reviewNotes;
    }
}
