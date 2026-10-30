package com.logisticfleet.service;

import com.logisticfleet.dto.EarningDtos.*;
import com.logisticfleet.entity.Earning;
import com.logisticfleet.entity.EarningStatus;
import com.logisticfleet.entity.Tenant;
import com.logisticfleet.entity.Trip;
import com.logisticfleet.entity.User;
import com.logisticfleet.exception.ResourceNotFoundException;
import com.logisticfleet.repository.EarningRepository;
import com.logisticfleet.repository.TenantRepository;
import com.logisticfleet.repository.TripRepository;
import com.logisticfleet.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.stream.Collectors;
@Slf4j
@Service
@RequiredArgsConstructor
public class EarningService {

    private final EarningRepository earningRepository;
    private final UserRepository userRepository;
    private final TripRepository tripRepository;
    private final TenantRepository tenantRepository;

    @Transactional(readOnly = true)
    public List<EarningResponse> getEarningsForDriver(Long driverId) {
        return earningRepository.findByDriverIdOrderByCreatedAtDesc(driverId)
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<EarningResponse> getAllEarnings(Long tenantId) {
        return earningRepository.findByTenantIdOrderByCreatedAtDesc(tenantId)
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public EarningsSummary getSummary(Long driverId) {
        List<Earning> earnings = earningRepository.findByDriverIdOrderByCreatedAtDesc(driverId);
        return buildSummary(earnings);
    }

    @Transactional
    public EarningResponse createEarning(Long tenantId, CreateEarningRequest req) {
        User driver = userRepository.findByIdAndTenantId(req.getDriverId(), tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Driver not found: " + req.getDriverId()));

        Tenant tenant = tenantRepository.findById(tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Tenant not found: " + tenantId));

        Trip trip = null;
        if (req.getTripId() != null) {
            trip = tripRepository.findByIdAndTenantId(req.getTripId(), tenantId)
                    .orElseThrow(() -> new ResourceNotFoundException("Trip not found: " + req.getTripId()));
        }

        BigDecimal bonus = req.getBonus() != null ? req.getBonus() : BigDecimal.ZERO;
        BigDecimal deduction = req.getDeduction() != null ? req.getDeduction() : BigDecimal.ZERO;
        BigDecimal total = req.getBaseAmount().add(bonus).subtract(deduction);

        Earning earning = Earning.builder()
                .tenant(tenant)
                .driver(driver)
                .trip(trip)
                .baseAmount(req.getBaseAmount())
                .bonus(bonus)
                .deduction(deduction)
                .totalAmount(total)
                .status(EarningStatus.PENDING)
                .periodStart(req.getPeriodStart())
                .periodEnd(req.getPeriodEnd())
                .build();

        return toResponse(earningRepository.save(earning));
    }

    @Transactional
    public EarningResponse updateStatus(Long tenantId, Long earningId, EarningStatusRequest req) {
        Earning earning = earningRepository.findById(earningId)
                .filter(e -> e.getTenant() != null && e.getTenant().getId().equals(tenantId))
                .orElseThrow(() -> new ResourceNotFoundException("Earning not found: " + earningId));
        earning.setStatus(req.getStatus());
        return toResponse(earningRepository.save(earning));
    }

    private EarningsSummary buildSummary(List<Earning> earnings) {
        BigDecimal totalEarned = earnings.stream()
                .map(Earning::getTotalAmount).reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalPending = earnings.stream()
                .filter(e -> e.getStatus() == EarningStatus.PENDING)
                .map(Earning::getTotalAmount).reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalPaid = earnings.stream()
                .filter(e -> e.getStatus() == EarningStatus.PAID)
                .map(Earning::getTotalAmount).reduce(BigDecimal.ZERO, BigDecimal::add);

        return new EarningsSummary(totalEarned, totalPending, totalPaid, earnings.size());
    }

    private EarningResponse toResponse(Earning e) {
        return new EarningResponse(
                e.getId(),
                e.getTrip() != null ? e.getTrip().getId() : null,
                e.getDriver().getId(),
                e.getDriver().getName(),
                e.getBaseAmount(),
                e.getBonus(),
                e.getDeduction(),
                e.getTotalAmount(),
                e.getStatus(),
                e.getPeriodStart(),
                e.getPeriodEnd()
        );
    }
}