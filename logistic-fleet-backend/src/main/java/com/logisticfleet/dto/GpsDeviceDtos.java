package com.logisticfleet.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

public class GpsDeviceDtos {

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AddDeviceRequest {
        @NotBlank
        private String deviceId;
        @NotNull
        private Long vehicleId;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class GpsDeviceResponse {
        private Long id;
        private String deviceId;
        private Long vehicleId;
        private String vehicleNumber;
        private String driverName;
        private Double lastLat;
        private Double lastLng;
        private Double lastSpeedKmh;
        private Double lastFuelPercent;
        private Boolean ignitionOn;
        private LocalDateTime lastSeenAt;
        /** true if a telemetry ping arrived within the last 5 minutes. */
        private boolean online;
    }

    /** Payload broadcast to connected dashboards over /ws/live-tracking on every MQTT update. */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class TelemetryUpdate {
        private String deviceId;
        private Long vehicleId;
        private String vehicleNumber;
        private Double lat;
        private Double lng;
        private Double speedKmh;
        private Double fuelPercent;
        private Boolean ignitionOn;
        private LocalDateTime timestamp;
    }
}
