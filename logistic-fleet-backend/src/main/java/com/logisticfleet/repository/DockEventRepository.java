package com.logisticfleet.repository;

import com.logisticfleet.entity.DockEvent;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface DockEventRepository extends JpaRepository<DockEvent, Long> {
    List<DockEvent> findByTripIdOrderByEventTimeAsc(Long tripId);
}
