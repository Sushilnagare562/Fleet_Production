package com.logisticfleet.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/**
 * A physical GPS tracker installed in a vehicle. Rather than persist every
 * telemetry ping (which would grow without bound), this entity holds just
 * the latest known reading; each new MQTT message overwrites it and pushes
 * a live update over WebSocket. Add a time-series table later if trip
 * playback / history is ever needed.
 */
@Entity
@Table(name = "gps_devices")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GpsDevice {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tenant_id", nullable = false)
    private Tenant tenant;

    /** The identifier the physical hardware publishes under, e.g. its IMEI or serial. */
    @Column(name = "device_id", nullable = false, unique = true, length = 100)
    private String deviceId;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "vehicle_id")
    private Vehicle vehicle;

    @Column(name = "last_lat")
    private Double lastLat;

    @Column(name = "last_lng")
    private Double lastLng;

    @Column(name = "last_speed_kmh")
    private Double lastSpeedKmh;

    @Column(name = "last_fuel_percent")
    private Double lastFuelPercent;

    @Column(name = "ignition_on")
    private Boolean ignitionOn;

    @Column(name = "last_seen_at")
    private LocalDateTime lastSeenAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
}
