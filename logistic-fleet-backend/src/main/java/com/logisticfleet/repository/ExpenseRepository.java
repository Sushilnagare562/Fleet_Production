package com.logisticfleet.repository;

import com.logisticfleet.entity.Expense;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;

public interface ExpenseRepository extends JpaRepository<Expense, Long> {
    List<Expense> findByDriverIdOrderByExpenseDateDesc(Long driverId);
    List<Expense> findByTripId(Long tripId);

    List<Expense> findByTenantIdOrderByExpenseDateDesc(Long tenantId);
    List<Expense> findByTenantIdAndExpenseDateBetween(Long tenantId, LocalDate from, LocalDate to);
}
