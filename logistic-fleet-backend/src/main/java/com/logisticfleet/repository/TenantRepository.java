package com.logisticfleet.repository;

import com.logisticfleet.entity.Tenant;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface TenantRepository extends JpaRepository<Tenant, Long> {
    Optional<Tenant> findByCompanyNameIgnoreCase(String companyName);
    boolean existsByCompanyNameIgnoreCase(String companyName);
}
