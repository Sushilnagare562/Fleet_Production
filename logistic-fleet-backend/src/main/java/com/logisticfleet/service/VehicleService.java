package com.logisticfleet.service;

import com.logisticfleet.dto.VehicleDtos.*;
import com.logisticfleet.entity.Tenant;
import com.logisticfleet.entity.User;
import com.logisticfleet.entity.Vehicle;
import com.logisticfleet.exception.ResourceNotFoundException;
import com.logisticfleet.repository.TenantRepository;
import com.logisticfleet.repository.UserRepository;
import com.logisticfleet.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;
@Slf4j
@Service
@RequiredArgsConstructor
public class VehicleService {

    private final VehicleRepository vehicleRepository;
    private final UserRepository userRepository;
    private final TenantRepository tenantRepository;

    @Transactional
    public VehicleResponse createVehicle(Long tenantId, VehicleRequest req) {
        User driver = null;
        if (req.getAssignedDriverId() != null) {
            driver = userRepository.findByIdAndTenantId(req.getAssignedDriverId(), tenantId)
                    .orElseThrow(() -> new ResourceNotFoundException("Driver not found: " + req.getAssignedDriverId()));
        }

        Tenant tenant = tenantRepository.findById(tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Tenant not found: " + tenantId));

        Vehicle vehicle = Vehicle.builder()
                .tenant(tenant)
                .vehicleNumber(req.getVehicleNumber())
                .type(req.getType())
                .model(req.getModel())
                .capacityKg(req.getCapacityKg())
                .assignedDriver(driver)
                .build();

        Vehicle saved = vehicleRepository.save(vehicle);
        log.info("Vehicle {} created (id={}, tenant={}, type={})",
                saved.getVehicleNumber(), saved.getId(), tenantId, saved.getType());
        return toResponse(saved);
    }

    @Transactional(readOnly = true)
    public List<VehicleResponse> getAllVehicles(Long tenantId) {
        return vehicleRepository.findByTenantId(tenantId).stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Transactional
    public VehicleResponse updateStatus(Long tenantId, Long vehicleId, VehicleStatusRequest req) {
        Vehicle vehicle = findOrThrow(tenantId, vehicleId);
        vehicle.setStatus(req.getStatus());
        log.info("Vehicle {} status changed to {} (tenant={})", vehicle.getVehicleNumber(), req.getStatus(), tenantId);
        return toResponse(vehicleRepository.save(vehicle));
    }

    @Transactional
    public VehicleResponse assignDriver(Long tenantId, Long vehicleId, AssignDriverRequest req) {
        Vehicle vehicle = findOrThrow(tenantId, vehicleId);

        if (req.getDriverId() == null) {
            vehicle.setAssignedDriver(null);
        } else {
            User driver = userRepository.findByIdAndTenantId(req.getDriverId(), tenantId)
                    .orElseThrow(() -> new ResourceNotFoundException("Driver not found: " + req.getDriverId()));
            vehicle.setAssignedDriver(driver);
        }

        return toResponse(vehicleRepository.save(vehicle));
    }

    @Transactional
    public void deleteVehicle(Long tenantId, Long vehicleId) {
        Vehicle vehicle = findOrThrow(tenantId, vehicleId);
        vehicleRepository.delete(vehicle);
    }

    private Vehicle findOrThrow(Long tenantId, Long id) {
        return vehicleRepository.findByIdAndTenantId(id, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Vehicle not found: " + id));
    }

    private VehicleResponse toResponse(Vehicle v) {
        return new VehicleResponse(
                v.getId(),
                v.getVehicleNumber(),
                v.getType(),
                v.getModel(),
                v.getCapacityKg(),
                v.getStatus(),
                v.getAssignedDriver() != null ? v.getAssignedDriver().getId() : null,
                v.getAssignedDriver() != null ? v.getAssignedDriver().getName() : null
        );
    }
}