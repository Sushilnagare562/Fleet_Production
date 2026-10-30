package com.logisticfleet.controller;

import com.logisticfleet.dto.AdminDriverDtos.*;
import com.logisticfleet.security.CurrentUserResolver;
import com.logisticfleet.service.AdminDriverService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** Admin-only driver management. Locked to ROLE_ADMIN via /api/admin/** in SecurityConfig. */
@Slf4j
@RestController
@RequestMapping("/api/admin/drivers")
@RequiredArgsConstructor
public class AdminDriverController {

    private final AdminDriverService adminDriverService;
    private final CurrentUserResolver currentUserResolver;

    @PostMapping
    public ResponseEntity<DriverResponse> createDriver(@Valid @RequestBody CreateDriverRequest req) {
        return ResponseEntity.ok(adminDriverService.createDriver(currentUserResolver.getCurrentTenantId(), req));
    }

    @GetMapping
    public ResponseEntity<List<DriverResponse>> getAllDrivers() {
        return ResponseEntity.ok(adminDriverService.getAllDrivers(currentUserResolver.getCurrentTenantId()));
    }

    @PatchMapping("/{driverId}/status")
    public ResponseEntity<DriverResponse> updateStatus(@PathVariable Long driverId,
                                                         @Valid @RequestBody DriverStatusRequest req) {
        return ResponseEntity.ok(
                adminDriverService.updateStatus(currentUserResolver.getCurrentTenantId(), driverId, req));
    }

    /** Soft-deletes a driver: history is kept, but they drop off {@link #getAllDrivers} and can no longer log in. */
    @DeleteMapping("/{driverId}")
    public ResponseEntity<Void> deleteDriver(@PathVariable Long driverId) {
        adminDriverService.deleteDriver(currentUserResolver.getCurrentTenantId(), driverId);
        return ResponseEntity.noContent().build();
    }
}
