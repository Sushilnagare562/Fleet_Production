package com.logisticfleet.controller;

import com.logisticfleet.dto.DockDtos.DockEventRequest;
import com.logisticfleet.dto.DockDtos.DockEventResponse;
import com.logisticfleet.security.CurrentUserResolver;
import com.logisticfleet.service.DockService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
@Slf4j
@RestController
@RequestMapping("/api/dock-events")
@RequiredArgsConstructor
public class DockController {

    private final DockService dockService;
    private final CurrentUserResolver currentUserResolver;

    /** Record a dock-in or dock-out event for the logged-in driver. */
    @PostMapping
    public ResponseEntity<DockEventResponse> recordEvent(@Valid @RequestBody DockEventRequest req) {
        Long driverId = currentUserResolver.getCurrentUserId();
        return ResponseEntity.ok(dockService.recordEvent(driverId, req));
    }

    @GetMapping("/trip/{tripId}")
    public ResponseEntity<List<DockEventResponse>> forTrip(@PathVariable Long tripId) {
        return ResponseEntity.ok(dockService.getEventsForTrip(tripId));
    }
}
