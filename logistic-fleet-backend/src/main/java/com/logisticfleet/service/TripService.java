package com.logisticfleet.service;

import com.logisticfleet.dto.TripDtos.*;
import com.logisticfleet.entity.RouteStop;
import com.logisticfleet.entity.Tenant;
import com.logisticfleet.entity.Trip;
import com.logisticfleet.entity.TripStatus;
import com.logisticfleet.entity.User;
import com.logisticfleet.entity.Vehicle;
import com.logisticfleet.entity.VehicleStatus;
import com.logisticfleet.exception.ResourceNotFoundException;
import com.logisticfleet.repository.TenantRepository;
import com.logisticfleet.repository.TripRepository;
import com.logisticfleet.repository.UserRepository;
import com.logisticfleet.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;
@Slf4j
@Service
@RequiredArgsConstructor
public class TripService {

    private final TripRepository tripRepository;
    private final UserRepository userRepository;
    private final TenantRepository tenantRepository;
    private final VehicleRepository vehicleRepository;
    private final NotificationService notificationService;

    /** Trip statuses that count as "in use" for double-booking checks. */
    private static final List<TripStatus> ACTIVE_TRIP_STATUSES = List.of(TripStatus.ASSIGNED, TripStatus.IN_PROGRESS);

    @Transactional
    public TripResponse assignTrip(Long tenantId, AssignTripRequest req) {
        User driver = userRepository.findByIdAndTenantId(req.getDriverId(), tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Driver not found: " + req.getDriverId()));

        Vehicle vehicle = vehicleRepository.findByIdAndTenantId(req.getVehicleId(), tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Vehicle not found: " + req.getVehicleId()));

        if (vehicle.getStatus() != VehicleStatus.ACTIVE) {
            throw new IllegalArgumentException(
                    "Vehicle " + vehicle.getVehicleNumber() + " is currently " +
                            vehicle.getStatus().name().toLowerCase() + " and can't be assigned to a trip");
        }
        if (tripRepository.existsByVehicleIdAndStatusIn(vehicle.getId(), ACTIVE_TRIP_STATUSES)) {
            throw new IllegalArgumentException(
                    "Vehicle " + vehicle.getVehicleNumber() + " is already assigned to another active trip");
        }

        Tenant tenant = tenantRepository.findById(tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Tenant not found: " + tenantId));

        Trip trip = Trip.builder()
                .tenant(tenant)
                .tripCode(generateTripCode())
                .driver(driver)
                .vehicle(vehicle)
                .origin(req.getOrigin())
                .destination(req.getDestination())
                .status(TripStatus.ASSIGNED)
                .scheduledStart(req.getScheduledStart())
                .scheduledEnd(req.getScheduledEnd())
                .distanceKm(req.getDistanceKm())
                .notes(req.getNotes())
                .build();

        if (req.getRouteStops() != null) {
            List<RouteStop> stops = req.getRouteStops().stream()
                    .map(s -> RouteStop.builder()
                            .trip(trip)
                            .sequenceNo(s.getSequenceNo())
                            .locationName(s.getLocationName())
                            .latitude(s.getLatitude())
                            .longitude(s.getLongitude())
                            .stopType(s.getStopType())
                            .plannedTime(s.getPlannedTime())
                            .build())
                    .collect(Collectors.toList());
            trip.setRouteStops(stops);
        }

        Trip saved = tripRepository.save(trip);

        notificationService.notifyTripAssigned(driver.getId(), saved.getTripCode(), saved.getOrigin(), saved.getDestination());

        log.info("Trip {} assigned (tenant={}, driver={}, vehicle={}, {} -> {})",
                saved.getTripCode(), tenantId, driver.getId(),
                vehicle != null ? vehicle.getId() : null, saved.getOrigin(), saved.getDestination());

        return toResponse(saved);
    }

    @Transactional(readOnly = true)
    public List<TripResponse> getTripsForDriver(Long driverId) {
        return tripRepository.findByDriverIdOrderByScheduledStartDesc(driverId)
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public TripResponse getTrip(Long tenantId, Long tripId) {
        return toResponse(findTripOrThrow(tenantId, tripId));
    }

    @Transactional
    public TripResponse updateStatus(Long tenantId, Long tripId, UpdateTripStatusRequest req) {
        Trip trip = findTripOrThrow(tenantId, tripId);
        trip.setStatus(req.getStatus());

        if (req.getStatus() == TripStatus.IN_PROGRESS && trip.getActualStart() == null) {
            trip.setActualStart(LocalDateTime.now());
        }
        if (req.getStatus() == TripStatus.COMPLETED) {
            trip.setActualEnd(LocalDateTime.now());
        }

        log.info("Trip {} status changed to {} (tenant={})", trip.getTripCode(), req.getStatus(), tenantId);

        return toResponse(tripRepository.save(trip));
    }

    @Transactional(readOnly = true)
    public List<TripResponse> getAllTrips(Long tenantId) {
        return tripRepository.findByTenantIdOrderByScheduledStartDesc(tenantId)
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    public TripStatusSummary getStatusSummary(Long tenantId) {
        List<Trip> allTrips = tripRepository.findByTenantIdOrderByScheduledStartDesc(tenantId);
        long assigned = allTrips.stream().filter(t -> t.getStatus() == TripStatus.ASSIGNED).count();
        long inProgress = allTrips.stream().filter(t -> t.getStatus() == TripStatus.IN_PROGRESS).count();
        long completed = allTrips.stream().filter(t -> t.getStatus() == TripStatus.COMPLETED).count();
        long cancelled = allTrips.stream().filter(t -> t.getStatus() == TripStatus.CANCELLED).count();
        return new TripStatusSummary(assigned, inProgress, completed, cancelled, allTrips.size());
    }

    private Trip findTripOrThrow(Long tenantId, Long tripId) {
        return tripRepository.findByIdAndTenantId(tripId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Trip not found: " + tripId));
    }

    private String generateTripCode() {
        String datePart = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyMMdd"));
        String randomPart = UUID.randomUUID().toString().substring(0, 5).toUpperCase();
        return "TRP-" + datePart + "-" + randomPart;
    }

    private TripResponse toResponse(Trip trip) {
        List<RouteStopDto> stops = trip.getRouteStops().stream()
                .map(s -> new RouteStopDto(s.getId(), s.getLocationName(), s.getLatitude(),
                        s.getLongitude(), s.getStopType(), s.getPlannedTime(), s.getSequenceNo()))
                .collect(Collectors.toList());

        return new TripResponse(
                trip.getId(),
                trip.getTripCode(),
                trip.getDriver() != null ? trip.getDriver().getId() : null,
                trip.getDriver() != null ? trip.getDriver().getName() : null,
                trip.getVehicle() != null ? trip.getVehicle().getId() : null,
                trip.getVehicle() != null ? trip.getVehicle().getVehicleNumber() : null,
                trip.getOrigin(),
                trip.getDestination(),
                trip.getStatus(),
                trip.getScheduledStart(),
                trip.getScheduledEnd(),
                trip.getActualStart(),
                trip.getActualEnd(),
                trip.getDistanceKm(),
                trip.getNotes(),
                stops
        );
    }
}