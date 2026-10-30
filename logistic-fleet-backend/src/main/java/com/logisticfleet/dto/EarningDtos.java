package com.logisticfleet.dto;

import com.logisticfleet.entity.EarningStatus;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;

public class EarningDtos {

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CreateEarningRequest {
        @NotNull
        private Long driverId;
        private Long tripId;
        @NotNull
        private BigDecimal baseAmount;
        private BigDecimal bonus;
        private BigDecimal deduction;
        private LocalDate periodStart;
        private LocalDate periodEnd;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class EarningStatusRequest {
        @NotNull
        private EarningStatus status;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class EarningResponse {
        private Long id;
        private Long tripId;
        private Long driverId;
        private String driverName;
        private BigDecimal baseAmount;
        private BigDecimal bonus;
        private BigDecimal deduction;
        private BigDecimal totalAmount;
        private EarningStatus status;
        private LocalDate periodStart;
        private LocalDate periodEnd;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class EarningsSummary {
        private BigDecimal totalEarned;
        private BigDecimal totalPending;
        private BigDecimal totalPaid;
        private int tripCount;
    }
}
