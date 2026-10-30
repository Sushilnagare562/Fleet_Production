package com.logisticfleet.repository;

import com.logisticfleet.entity.Trip;
import com.logisticfleet.entity.TripStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface TripRepository extends JpaRepository<Trip, Long> {
    List<Trip> findByDriverIdOrderByScheduledStartDesc(Long driverId);
    List<Trip> findByDriverIdAndStatus(Long driverId, TripStatus status);
    List<Trip> findByStatus(TripStatus status);
    Optional<Trip> findByTripCode(String tripCode);

    List<Trip> findByTenantIdOrderByScheduledStartDesc(Long tenantId);
    Optional<Trip> findByIdAndTenantId(Long id, Long tenantId);
    List<Trip> findByTenantIdAndScheduledStartBetween(Long tenantId, LocalDateTime from, LocalDateTime to);

    /** Used to stop a vehicle being double-booked onto two active trips at once. */
    boolean existsByVehicleIdAndStatusIn(Long vehicleId, List<TripStatus> statuses);
}
