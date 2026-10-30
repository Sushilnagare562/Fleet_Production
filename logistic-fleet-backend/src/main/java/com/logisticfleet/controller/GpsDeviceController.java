package com.logisticfleet.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.logisticfleet.dto.GpsDeviceDtos.AddDeviceRequest;
import com.logisticfleet.dto.GpsDeviceDtos.GpsDeviceResponse;
import com.logisticfleet.security.CurrentUserResolver;
import com.logisticfleet.service.GpsDeviceService;
import com.logisticfleet.service.TelemetryIngestService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/admin/devices")
@RequiredArgsConstructor
public class GpsDeviceController {

    private final GpsDeviceService gpsDeviceService;
    private final CurrentUserResolver currentUserResolver;
    private final TelemetryIngestService telemetryIngestService;
    private final ObjectMapper objectMapper;

    @PostMapping
    public ResponseEntity<GpsDeviceResponse> addDevice(@Valid @RequestBody AddDeviceRequest req) {
        return ResponseEntity.ok(gpsDeviceService.addDevice(currentUserResolver.getCurrentTenantId(), req));
    }

    @GetMapping
    public ResponseEntity<List<GpsDeviceResponse>> getAllDevices() {
        return ResponseEntity.ok(gpsDeviceService.getAllDevices(currentUserResolver.getCurrentTenantId()));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> removeDevice(@PathVariable Long id) {
        gpsDeviceService.removeDevice(currentUserResolver.getCurrentTenantId(), id);
        return ResponseEntity.noContent().build();
    }

    /**
     * Pushes a single telemetry reading through the exact same ingestion
     * path a real MQTT message would take, so the live-tracking dashboard
     * can be tested end to end before the real broker/devices are wired up.
     * Body shape matches {@link TelemetryIngestService}'s documented payload.
     */
    @PostMapping("/simulate")
    public ResponseEntity<Void> simulateTelemetry(@RequestBody Map<String, Object> payload) throws Exception {
        telemetryIngestService.ingest(objectMapper.writeValueAsString(payload));
        return ResponseEntity.accepted().build();
    }
}
