package com.logisticfleet.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * A tenant represents one company / transport business using Logistic Fleet.
 * Every {@link User} (and, through the driver, every business record such as
 * trips, expenses, earnings and vehicles) belongs to exactly one tenant so
 * that data for one company is never visible to another as the platform
 * scales to multiple customers.
 */
@Entity
@Table(name = "tenants")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Tenant {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Public, URL/JWT-safe unique identifier for this tenant. */
    @Column(name = "tenant_uid", nullable = false, unique = true, updatable = false, length = 36)
    @Builder.Default
    private String tenantUid = UUID.randomUUID().toString();

    @Column(name = "company_name", nullable = false, length = 150)
    private String companyName;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private TenantStatus status = TenantStatus.ACTIVE;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
}
