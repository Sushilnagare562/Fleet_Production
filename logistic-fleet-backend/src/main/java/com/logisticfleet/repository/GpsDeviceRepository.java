package com.logisticfleet.repository;

import com.logisticfleet.entity.GpsDevice;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface GpsDeviceRepository extends JpaRepository<GpsDevice, Long> {
    List<GpsDevice> findByTenantId(Long tenantId);
    Optional<GpsDevice> findByIdAndTenantId(Long id, Long tenantId);
    Optional<GpsDevice> findByDeviceId(String deviceId);
    boolean existsByDeviceId(String deviceId);
    Optional<GpsDevice> findByVehicleId(Long vehicleId);
}
