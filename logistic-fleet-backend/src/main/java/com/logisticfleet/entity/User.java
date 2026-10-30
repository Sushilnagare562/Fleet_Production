package com.logisticfleet.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * The company this user belongs to. Every query that lists "all" records
     * (drivers, trips, expenses, vehicles, earnings) is scoped to this tenant
     * so one company can never see another company's data.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tenant_id", nullable = false)
    private Tenant tenant;

    @Column(nullable = false, length = 120)
    private String name;

    @Column(nullable = false, unique = true, length = 150)
    private String email;

    @Column(nullable = false, unique = true, length = 20)
    private String phone;

    @Column(name = "password_hash", nullable = false)
    private String passwordHash;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private Role role = Role.DRIVER;

    @Column(name = "vehicle_number", length = 30)
    private String vehicleNumber;

    @Column(name = "license_number", length = 40)
    private String licenseNumber;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private boolean active = true;

    /**
     * Admin-facing lifecycle state, meaningful for DRIVER-role users
     * (see {@link AdminDriverService}). Defaults to ACTIVE for every user;
     * ON_LEAVE and DELETED are set explicitly from the admin driver list.
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "driver_status", nullable = false, length = 20)
    @Builder.Default
    private DriverStatus driverStatus = DriverStatus.ACTIVE;

    /**
     * Base64-encoded profile photo (data only, no "data:image/..." prefix).
     * Stored directly in the row rather than an external bucket since the
     * app has no object storage configured; fine for avatar-sized images.
     */
    @Column(name = "profile_photo", columnDefinition = "TEXT")
    private String profilePhoto;

    /** BCrypt hash of the current "forgot password" OTP, if one was requested and not yet used. */
    @Column(name = "reset_otp_hash")
    private String resetOtpHash;

    /** When the current OTP (above) stops being valid. */
    @Column(name = "reset_otp_expiry")
    private LocalDateTime resetOtpExpiry;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at", nullable = false)
    @Builder.Default
    private LocalDateTime updatedAt = LocalDateTime.now();

    @PreUpdate
    public void preUpdate() {
        this.updatedAt = LocalDateTime.now();
    }
}
