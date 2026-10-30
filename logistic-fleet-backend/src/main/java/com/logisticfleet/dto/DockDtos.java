package com.logisticfleet.dto;

import com.logisticfleet.entity.EventType;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class DockDtos {

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DockEventRequest {
        @NotNull
        private Long tripId;
        private Long routeStopId;
        @NotNull
        private EventType eventType;
        private String locationName;
        private BigDecimal latitude;
        private BigDecimal longitude;
        private String remarks;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DockEventResponse {
        private Long id;
        private Long tripId;
        private Long routeStopId;
        private EventType eventType;
        private String locationName;
        private BigDecimal latitude;
        private BigDecimal longitude;
        private LocalDateTime eventTime;
        private String remarks;
    }
}
