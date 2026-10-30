package com.logisticfleet.controller;

import com.logisticfleet.dto.RouteOptimizationDtos.OptimizeRouteRequest;
import com.logisticfleet.dto.RouteOptimizationDtos.OptimizeRouteResponse;
import com.logisticfleet.dto.TripDtos.AssignTripRequest;
import com.logisticfleet.dto.TripDtos.TripResponse;
import com.logisticfleet.dto.TripDtos.TripStatusSummary;
import com.logisticfleet.security.CurrentUserResolver;
import com.logisticfleet.service.RouteOptimizationService;
import com.logisticfleet.service.TripService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Admin / dispatch-only endpoints. Locked down to ROLE_ADMIN in SecurityConfig.
 */
@Slf4j
@RestController
@RequestMapping("/api/dispatch")
@RequiredArgsConstructor
public class DispatchController {

    private final TripService tripService;
    private final RouteOptimizationService routeOptimizationService;
    private final CurrentUserResolver currentUserResolver;

    @PostMapping("/trips")
    public ResponseEntity<TripResponse> assignTrip(@Valid @RequestBody AssignTripRequest req) {
        return ResponseEntity.ok(tripService.assignTrip(currentUserResolver.getCurrentTenantId(), req));
    }

    @GetMapping("/trips")
    public ResponseEntity<List<TripResponse>> allTrips() {
        return ResponseEntity.ok(tripService.getAllTrips(currentUserResolver.getCurrentTenantId()));
    }

    @GetMapping("/trips/summary")
    public ResponseEntity<TripStatusSummary> tripSummary() {
        return ResponseEntity.ok(tripService.getStatusSummary(currentUserResolver.getCurrentTenantId()));
    }

    /**
     * Given a set of stops (and optionally a fixed starting point), returns the
     * shortest visiting order plus the resulting distance/ETA. This doesn't save
     * anything — the dispatcher reviews the suggested order in the app, then
     * assigns the trip normally via POST /trips with the reordered stops.
     */
    @PostMapping("/route-optimize")
    public ResponseEntity<OptimizeRouteResponse> optimizeRoute(@Valid @RequestBody OptimizeRouteRequest req) {
        log.info("Optimizing route with {} stop(s)", req.getStops() != null ? req.getStops().size() : 0);
        return ResponseEntity.ok(routeOptimizationService.optimize(req));
    }
}
