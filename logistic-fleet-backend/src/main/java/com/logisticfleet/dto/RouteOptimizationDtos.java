package com.logisticfleet.dto;

import com.logisticfleet.dto.TripDtos.RouteStopDto;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

public class RouteOptimizationDtos {

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class OptimizeRouteRequest {
        /**
         * Optional fixed starting point (e.g. the depot, or the driver's current
         * location). When present, the route always starts here and only the
         * remaining stops get reordered around it.
         */
        private BigDecimal originLat;
        private BigDecimal originLng;
        private String originLabel;

        @NotEmpty(message = "Add at least two stops to optimize a route")
        @Valid
        private List<RouteStopDto> stops;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class OptimizedStop {
        private RouteStopDto stop;
        private Integer sequenceNo;
        /** Distance from the previous stop (or the origin, for the first stop). Null if either end is missing coordinates. */
        private BigDecimal legDistanceKm;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class OptimizeRouteResponse {
        private List<OptimizedStop> orderedStops;
        private BigDecimal totalDistanceKm;
        private Integer estimatedDurationMinutes;
    }
}
