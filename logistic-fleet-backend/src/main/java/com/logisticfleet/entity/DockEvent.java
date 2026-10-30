package com.logisticfleet.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "dock_events")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DockEvent {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "trip_id", nullable = false)
    private Trip trip;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "route_stop_id")
    private RouteStop routeStop;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "driver_id", nullable = false)
    private User driver;

    @Enumerated(EnumType.STRING)
    @Column(name = "event_type", nullable = false, length = 20)
    private EventType eventType;

    @Column(name = "location_name", length = 200)
    private String locationName;

    private BigDecimal latitude;

    private BigDecimal longitude;

    @Column(name = "event_time", nullable = false)
    @Builder.Default
    private LocalDateTime eventTime = LocalDateTime.now();

    @Column(length = 300)
    private String remarks;
}
