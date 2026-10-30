package com.logisticfleet.repository;

import com.logisticfleet.entity.Vehicle;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface VehicleRepository extends JpaRepository<Vehicle, Long> {
    List<Vehicle> findByAssignedDriverId(Long driverId);

    List<Vehicle> findByTenantId(Long tenantId);
    Optional<Vehicle> findByIdAndTenantId(Long id, Long tenantId);
}
