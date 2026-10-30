package com.logisticfleet.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.logisticfleet.dto.GpsDeviceDtos.TelemetryUpdate;
import com.logisticfleet.entity.GpsDevice;
import com.logisticfleet.repository.GpsDeviceRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

/**
 * Handles one MQTT telemetry message end to end: parse -&gt; persist the
 * latest snapshot on the matching {@link GpsDevice} -&gt; push a live update
 * to that device's tenant over WebSocket.
 * <p>
 * Expected JSON payload (adjust field names here to match your hardware's
 * actual protocol if it differs):
 * <pre>{@code
 * {
 *   "deviceId": "TRK-104",
 *   "lat": 19.9975,
 *   "lng": 73.7898,
 *   "speedKmh": 42.5,
 *   "fuelPercent": 68.0,
 *   "ignitionOn": true,
 *   "timestamp": "2026-09-03T10:15:30"   // optional, ISO-8601; defaults to now()
 * }
 * }</pre>
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class TelemetryIngestService {

    private final GpsDeviceRepository gpsDeviceRepository;
    private final LiveTrackingWebSocketHandler webSocketHandler;
    private final ObjectMapper objectMapper;

    @Transactional
    public void ingest(String rawPayload) {
        JsonNode json;
        try {
            json = objectMapper.readTree(rawPayload);
        } catch (Exception e) {
            log.warn("Discarding malformed telemetry payload: {}", e.getMessage());
            return;
        }

        String deviceId = json.path("deviceId").asText(null);
        if (deviceId == null || deviceId.isBlank()) {
            log.warn("Discarding telemetry payload with no deviceId: {}", rawPayload);
            return;
        }

        GpsDevice device = gpsDeviceRepository.findByDeviceId(deviceId).orElse(null);
        if (device == null) {
            // Not an error - the device just hasn't been added in the admin
            // "Devices" screen yet, so there's no tenant/vehicle to attribute it to.
            log.debug("Ignoring telemetry for unregistered device '{}'", deviceId);
            return;
        }

        if (json.hasNonNull("lat")) device.setLastLat(json.get("lat").asDouble());
        if (json.hasNonNull("lng")) device.setLastLng(json.get("lng").asDouble());
        if (json.hasNonNull("speedKmh")) device.setLastSpeedKmh(json.get("speedKmh").asDouble());
        if (json.hasNonNull("fuelPercent")) device.setLastFuelPercent(json.get("fuelPercent").asDouble());
        if (json.hasNonNull("ignitionOn")) device.setIgnitionOn(json.get("ignitionOn").asBoolean());
        device.setLastSeenAt(LocalDateTime.now());

        gpsDeviceRepository.save(device);

        TelemetryUpdate update = new TelemetryUpdate(
                device.getDeviceId(),
                device.getVehicle() != null ? device.getVehicle().getId() : null,
                device.getVehicle() != null ? device.getVehicle().getVehicleNumber() : null,
                device.getLastLat(),
                device.getLastLng(),
                device.getLastSpeedKmh(),
                device.getLastFuelPercent(),
                device.getIgnitionOn(),
                device.getLastSeenAt()
        );

        webSocketHandler.broadcast(device.getTenant().getId(), update);
    }
}
