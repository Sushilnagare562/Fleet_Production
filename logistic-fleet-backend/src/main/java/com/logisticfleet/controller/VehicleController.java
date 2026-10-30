package com.logisticfleet.controller;

import com.logisticfleet.dto.VehicleDtos.*;
import com.logisticfleet.security.CurrentUserResolver;
import com.logisticfleet.service.VehicleService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** Admin-only fleet/vehicle management. Locked to ROLE_ADMIN via /api/admin/** in SecurityConfig. */
@Slf4j
@RestController
@RequestMapping("/api/admin/vehicles")
@RequiredArgsConstructor
public class VehicleController {

    private final VehicleService vehicleService;
    private final CurrentUserResolver currentUserResolver;

    @PostMapping
    public ResponseEntity<VehicleResponse> createVehicle(@Valid @RequestBody VehicleRequest req) {
        return ResponseEntity.ok(vehicleService.createVehicle(currentUserResolver.getCurrentTenantId(), req));
    }

    @GetMapping
    public ResponseEntity<List<VehicleResponse>> getAllVehicles() {
        return ResponseEntity.ok(vehicleService.getAllVehicles(currentUserResolver.getCurrentTenantId()));
    }

    @PatchMapping("/{vehicleId}/status")
    public ResponseEntity<VehicleResponse> updateStatus(@PathVariable Long vehicleId,
                                                          @Valid @RequestBody VehicleStatusRequest req) {
        return ResponseEntity.ok(
                vehicleService.updateStatus(currentUserResolver.getCurrentTenantId(), vehicleId, req));
    }

    @PatchMapping("/{vehicleId}/assign-driver")
    public ResponseEntity<VehicleResponse> assignDriver(@PathVariable Long vehicleId,
                                                          @RequestBody AssignDriverRequest req) {
        return ResponseEntity.ok(
                vehicleService.assignDriver(currentUserResolver.getCurrentTenantId(), vehicleId, req));
    }

    @DeleteMapping("/{vehicleId}")
    public ResponseEntity<Void> deleteVehicle(@PathVariable Long vehicleId) {
        vehicleService.deleteVehicle(currentUserResolver.getCurrentTenantId(), vehicleId);
        return ResponseEntity.noContent().build();
    }
}
