package com.logisticfleet.service;

import com.logisticfleet.dto.GpsDeviceDtos.AddDeviceRequest;
import com.logisticfleet.dto.GpsDeviceDtos.GpsDeviceResponse;
import com.logisticfleet.entity.GpsDevice;
import com.logisticfleet.entity.Tenant;
import com.logisticfleet.entity.Vehicle;
import com.logisticfleet.exception.ResourceNotFoundException;
import com.logisticfleet.repository.GpsDeviceRepository;
import com.logisticfleet.repository.TenantRepository;
import com.logisticfleet.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class GpsDeviceService {

    /** A device with no ping in the last 5 minutes is shown as offline on the dashboard. */
    private static final long ONLINE_THRESHOLD_MINUTES = 5;

    private final GpsDeviceRepository gpsDeviceRepository;
    private final VehicleRepository vehicleRepository;
    private final TenantRepository tenantRepository;

    @Transactional
    public GpsDeviceResponse addDevice(Long tenantId, AddDeviceRequest req) {
        if (gpsDeviceRepository.existsByDeviceId(req.getDeviceId())) {
            throw new ResponseStatusException(org.springframework.http.HttpStatus.CONFLICT,
                    "A device with this ID is already registered");
        }

        Vehicle vehicle = vehicleRepository.findByIdAndTenantId(req.getVehicleId(), tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Vehicle not found: " + req.getVehicleId()));

        gpsDeviceRepository.findByVehicleId(vehicle.getId()).ifPresent(existing -> {
            throw new ResponseStatusException(org.springframework.http.HttpStatus.CONFLICT,
                    "This vehicle already has a GPS device (" + existing.getDeviceId() + ") linked to it");
        });

        Tenant tenant = tenantRepository.findById(tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Tenant not found: " + tenantId));

        GpsDevice device = GpsDevice.builder()
                .tenant(tenant)
                .deviceId(req.getDeviceId().trim())
                .vehicle(vehicle)
                .build();

        log.info("GPS device {} linked to vehicle {}", device.getDeviceId(), vehicle.getVehicleNumber());
        return toResponse(gpsDeviceRepository.save(device));
    }

    @Transactional(readOnly = true)
    public List<GpsDeviceResponse> getAllDevices(Long tenantId) {
        return gpsDeviceRepository.findByTenantId(tenantId).stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Transactional
    public void removeDevice(Long tenantId, Long deviceId) {
        GpsDevice device = gpsDeviceRepository.findByIdAndTenantId(deviceId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Device not found: " + deviceId));
        gpsDeviceRepository.delete(device);
    }

    private GpsDeviceResponse toResponse(GpsDevice d) {
        boolean online = d.getLastSeenAt() != null
                && d.getLastSeenAt().isAfter(LocalDateTime.now().minus(ONLINE_THRESHOLD_MINUTES, ChronoUnit.MINUTES));

        return new GpsDeviceResponse(
                d.getId(),
                d.getDeviceId(),
                d.getVehicle() != null ? d.getVehicle().getId() : null,
                d.getVehicle() != null ? d.getVehicle().getVehicleNumber() : null,
                d.getVehicle() != null && d.getVehicle().getAssignedDriver() != null
                        ? d.getVehicle().getAssignedDriver().getName() : null,
                d.getLastLat(),
                d.getLastLng(),
                d.getLastSpeedKmh(),
                d.getLastFuelPercent(),
                d.getIgnitionOn(),
                d.getLastSeenAt(),
                online
        );
    }
}
