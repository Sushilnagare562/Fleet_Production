package com.logisticfleet.service;

import com.logisticfleet.dto.AdminDriverDtos.*;
import com.logisticfleet.entity.DriverStatus;
import com.logisticfleet.entity.Role;
import com.logisticfleet.entity.Tenant;
import com.logisticfleet.entity.User;
import com.logisticfleet.exception.ResourceNotFoundException;
import com.logisticfleet.repository.TenantRepository;
import com.logisticfleet.repository.UserRepository;
import com.logisticfleet.util.ContactNormalizer;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;
@Slf4j
@Service
@RequiredArgsConstructor
public class AdminDriverService {

    private final UserRepository userRepository;
    private final TenantRepository tenantRepository;
    private final PasswordEncoder passwordEncoder;

    @Transactional
    public DriverResponse createDriver(Long tenantId, CreateDriverRequest req) {
        String email = ContactNormalizer.normalizeEmail(req.getEmail());
        String phone = ContactNormalizer.normalizePhone(req.getPhone());

        if (!ContactNormalizer.isValidPhoneDigits(phone)) {
            throw new IllegalArgumentException("Enter a valid mobile number");
        }
        if (userRepository.existsByEmail(email)) {
            throw new IllegalArgumentException("Email already registered");
        }
        userRepository.findByPhone(phone).ifPresent(existing -> {
            throw new IllegalArgumentException("Mobile number already registered");
        });

        Tenant tenant = tenantRepository.findById(tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Tenant not found: " + tenantId));

        User driver = User.builder()
                .tenant(tenant)
                .name(req.getName().trim())
                .email(email)
                .phone(phone)
                .passwordHash(passwordEncoder.encode(req.getTemporaryPassword()))
                .role(Role.DRIVER)
                .vehicleNumber(req.getVehicleNumber())
                .licenseNumber(req.getLicenseNumber())
                .active(true)
                .driverStatus(DriverStatus.ACTIVE)
                .build();

        return toResponse(userRepository.save(driver));
    }

    public List<DriverResponse> getAllDrivers(Long tenantId) {
        return userRepository.findByTenantIdAndRoleAndDriverStatusNot(tenantId, Role.DRIVER, DriverStatus.DELETED)
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    /**
     * Sets a driver's lifecycle state from the admin driver list's 3-dot
     * menu. ACTIVE re-enables login; ON_LEAVE disables login without
     * touching any history. (DELETED goes through {@link #deleteDriver}
     * instead, which has its own "already deleted" guard.)
     */
    @Transactional
    public DriverResponse updateStatus(Long tenantId, Long driverId, DriverStatusRequest req) {
        User driver = userRepository.findByIdAndTenantId(driverId, tenantId)
                .filter(u -> u.getDriverStatus() != DriverStatus.DELETED)
                .orElseThrow(() -> new ResourceNotFoundException("Driver not found: " + driverId));

        DriverStatus newStatus = req.getStatus();
        if (newStatus == DriverStatus.DELETED) {
            throw new IllegalArgumentException("Use the delete action to remove a driver");
        }

        driver.setDriverStatus(newStatus);
        // ON_LEAVE also blocks login, same as an inactive account; ACTIVE restores it.
        driver.setActive(newStatus == DriverStatus.ACTIVE);
        log.info("Driver {} status set to {}", driverId, newStatus);
        return toResponse(userRepository.save(driver));
    }

    /**
     * Soft-deletes a driver: the row (and every trip/expense/earning that
     * references it) is kept for history, but the driver disappears from
     * {@link #getAllDrivers} and can no longer log in.
     */
    @Transactional
    public void deleteDriver(Long tenantId, Long driverId) {
        User driver = userRepository.findByIdAndTenantId(driverId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Driver not found: " + driverId));

        if (driver.getDriverStatus() == DriverStatus.DELETED) {
            throw new IllegalArgumentException("This driver has already been deleted");
        }

        driver.setDriverStatus(DriverStatus.DELETED);
        driver.setActive(false);
        userRepository.save(driver);
        log.info("Driver {} deleted (soft)", driverId);
    }

    private DriverResponse toResponse(User u) {
        return new DriverResponse(
                u.getId(), u.getName(), u.getEmail(), u.getPhone(),
                u.getVehicleNumber(), u.getLicenseNumber(), u.isActive(), u.getDriverStatus(), u.getRole().name()
        );
    }
}
