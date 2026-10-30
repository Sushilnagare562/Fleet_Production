package com.logisticfleet.repository;

import com.logisticfleet.entity.RouteStop;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface RouteStopRepository extends JpaRepository<RouteStop, Long> {
    List<RouteStop> findByTripIdOrderBySequenceNoAsc(Long tripId);
}
