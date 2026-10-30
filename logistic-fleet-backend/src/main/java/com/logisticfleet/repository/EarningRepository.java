package com.logisticfleet.repository;

import com.logisticfleet.entity.Earning;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;

public interface EarningRepository extends JpaRepository<Earning, Long> {
    List<Earning> findByDriverIdOrderByCreatedAtDesc(Long driverId);

    List<Earning> findByTenantIdOrderByCreatedAtDesc(Long tenantId);
    List<Earning> findByTenantIdAndPeriodStartBetween(Long tenantId, LocalDate from, LocalDate to);
}
