package com.logisticfleet.service;

import com.logisticfleet.dto.DockDtos.DockEventRequest;
import com.logisticfleet.dto.DockDtos.DockEventResponse;
import com.logisticfleet.entity.DockEvent;
import com.logisticfleet.entity.RouteStop;
import com.logisticfleet.entity.Trip;
import com.logisticfleet.entity.User;
import com.logisticfleet.exception.ResourceNotFoundException;
import com.logisticfleet.repository.DockEventRepository;
import com.logisticfleet.repository.RouteStopRepository;
import com.logisticfleet.repository.TripRepository;
import com.logisticfleet.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;
@Slf4j
@Service
@RequiredArgsConstructor
public class DockService {

    private final DockEventRepository dockEventRepository;
    private final TripRepository tripRepository;
    private final RouteStopRepository routeStopRepository;
    private final UserRepository userRepository;

    @Transactional
    public DockEventResponse recordEvent(Long driverId, DockEventRequest req) {
        Trip trip = tripRepository.findById(req.getTripId())
                .orElseThrow(() -> new ResourceNotFoundException("Trip not found: " + req.getTripId()));

        User driver = userRepository.findById(driverId)
                .orElseThrow(() -> new ResourceNotFoundException("Driver not found: " + driverId));

        RouteStop stop = null;
        if (req.getRouteStopId() != null) {
            stop = routeStopRepository.findById(req.getRouteStopId())
                    .orElseThrow(() -> new ResourceNotFoundException("Route stop not found: " + req.getRouteStopId()));
        }

        DockEvent event = DockEvent.builder()
                .trip(trip)
                .routeStop(stop)
                .driver(driver)
                .eventType(req.getEventType())
                .locationName(req.getLocationName())
                .latitude(req.getLatitude())
                .longitude(req.getLongitude())
                .remarks(req.getRemarks())
                .build();

        DockEvent saved = dockEventRepository.save(event);
        return toResponse(saved);
    }

    @Transactional(readOnly = true)
    public List<DockEventResponse> getEventsForTrip(Long tripId) {
        return dockEventRepository.findByTripIdOrderByEventTimeAsc(tripId)
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    private DockEventResponse toResponse(DockEvent e) {
        return new DockEventResponse(
                e.getId(),
                e.getTrip().getId(),
                e.getRouteStop() != null ? e.getRouteStop().getId() : null,
                e.getEventType(),
                e.getLocationName(),
                e.getLatitude(),
                e.getLongitude(),
                e.getEventTime(),
                e.getRemarks()
        );
    }
}