package com.logisticfleet.dto;

import com.logisticfleet.entity.StopType;
import com.logisticfleet.entity.TripStatus;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public class TripDtos {

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class RouteStopDto {
        private Long id;
        @NotBlank
        private String locationName;
        private BigDecimal latitude;
        private BigDecimal longitude;
        @NotNull
        private StopType stopType;
        private LocalDateTime plannedTime;
        private Integer sequenceNo;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class TripResponse {
        private Long id;
        private String tripCode;
        private Long driverId;
        private String driverName;
        private Long vehicleId;
        private String vehicleNumber;
        private String origin;
        private String destination;
        private TripStatus status;
        private LocalDateTime scheduledStart;
        private LocalDateTime scheduledEnd;
        private LocalDateTime actualStart;
        private LocalDateTime actualEnd;
        private BigDecimal distanceKm;
        private String notes;
        private List<RouteStopDto> routeStops;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AssignTripRequest {
        @NotNull
        private Long driverId;
        @NotNull(message = "Select a vehicle for this trip")
        private Long vehicleId;
        @NotBlank
        private String origin;
        @NotBlank
        private String destination;
        private LocalDateTime scheduledStart;
        private LocalDateTime scheduledEnd;
        private BigDecimal distanceKm;
        private String notes;
        private List<RouteStopDto> routeStops;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UpdateTripStatusRequest {
        @NotNull
        private TripStatus status;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class TripStatusSummary {
        private long assigned;
        private long inProgress;
        private long completed;
        private long cancelled;
        private long total;
    }
}
