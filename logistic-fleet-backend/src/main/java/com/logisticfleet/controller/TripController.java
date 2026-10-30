package com.logisticfleet.controller;

import com.logisticfleet.dto.TripDtos.TripResponse;
import com.logisticfleet.dto.TripDtos.UpdateTripStatusRequest;
import com.logisticfleet.security.CurrentUserResolver;
import com.logisticfleet.service.TripService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
@Slf4j
@RestController
@RequestMapping("/api/trips")
@RequiredArgsConstructor
public class TripController {

    private final TripService tripService;
    private final CurrentUserResolver currentUserResolver;

    /** Trips assigned to the logged-in driver. */
    @GetMapping("/my")
    public ResponseEntity<List<TripResponse>> myTrips() {
        Long driverId = currentUserResolver.getCurrentUserId();
        return ResponseEntity.ok(tripService.getTripsForDriver(driverId));
    }

    @GetMapping("/{tripId}")
    public ResponseEntity<TripResponse> getTrip(@PathVariable Long tripId) {
        return ResponseEntity.ok(tripService.getTrip(currentUserResolver.getCurrentTenantId(), tripId));
    }

    @PatchMapping("/{tripId}/status")
    public ResponseEntity<TripResponse> updateStatus(@PathVariable Long tripId,
                                                       @Valid @RequestBody UpdateTripStatusRequest req) {
        return ResponseEntity.ok(
                tripService.updateStatus(currentUserResolver.getCurrentTenantId(), tripId, req));
    }
}
