package com.logisticfleet.service;

import com.logisticfleet.dto.ExpenseDtos.AdminExpenseRequest;
import com.logisticfleet.dto.ExpenseDtos.ExpenseRequest;
import com.logisticfleet.dto.ExpenseDtos.ExpenseResponse;
import com.logisticfleet.dto.ExpenseDtos.ExpenseStatusRequest;
import com.logisticfleet.entity.Expense;
import com.logisticfleet.entity.ExpenseStatus;
import com.logisticfleet.entity.Tenant;
import com.logisticfleet.entity.Trip;
import com.logisticfleet.entity.User;
import com.logisticfleet.exception.ResourceNotFoundException;
import com.logisticfleet.repository.ExpenseRepository;
import com.logisticfleet.repository.TenantRepository;
import com.logisticfleet.repository.TripRepository;
import com.logisticfleet.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;
@Slf4j
@Service
@RequiredArgsConstructor
public class ExpenseService {

    private final ExpenseRepository expenseRepository;
    private final TripRepository tripRepository;
    private final UserRepository userRepository;
    private final TenantRepository tenantRepository;
    private final NotificationService notificationService;

    @Transactional
    public ExpenseResponse addExpense(Long tenantId, Long driverId, ExpenseRequest req) {
        User driver = userRepository.findByIdAndTenantId(driverId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Driver not found: " + driverId));

        Tenant tenant = tenantRepository.findById(tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Tenant not found: " + tenantId));

        Trip trip = null;
        if (req.getTripId() != null) {
            trip = tripRepository.findByIdAndTenantId(req.getTripId(), tenantId)
                    .orElseThrow(() -> new ResourceNotFoundException("Trip not found: " + req.getTripId()));
        }

        Expense expense = Expense.builder()
                .tenant(tenant)
                .driver(driver)
                .trip(trip)
                .category(req.getCategory())
                .amount(req.getAmount())
                .description(req.getDescription())
                .receiptUrl(req.getReceiptUrl())
                .expenseDate(req.getExpenseDate())
                .build();

        Expense saved = expenseRepository.save(expense);

        notificationService.notifyExpenseSubmitted(tenantId, driver.getName(),
                req.getCategory().name(), req.getAmount().toString());

        return toResponse(saved);
    }

    /**
     * Admin-entered expense on behalf of a driver (e.g. a paper receipt
     * handed in). Saved as APPROVED immediately since the admin is the one
     * recording it, so it shows straight away in both the driver's expense
     * list and the approvals summary.
     */
    @Transactional
    public ExpenseResponse createExpenseByAdmin(Long tenantId, AdminExpenseRequest req) {
        User driver = userRepository.findByIdAndTenantId(req.getDriverId(), tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Driver not found: " + req.getDriverId()));

        Tenant tenant = tenantRepository.findById(tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Tenant not found: " + tenantId));

        Trip trip = null;
        if (req.getTripId() != null) {
            trip = tripRepository.findByIdAndTenantId(req.getTripId(), tenantId)
                    .orElseThrow(() -> new ResourceNotFoundException("Trip not found: " + req.getTripId()));
        }

        Expense expense = Expense.builder()
                .tenant(tenant)
                .driver(driver)
                .trip(trip)
                .category(req.getCategory())
                .amount(req.getAmount())
                .description(req.getDescription())
                .receiptUrl(req.getReceiptUrl())
                .expenseDate(req.getExpenseDate())
                .status(ExpenseStatus.APPROVED)
                .reviewNotes("Added by admin")
                .build();

        return toResponse(expenseRepository.save(expense));
    }

    @Transactional(readOnly = true)
    public List<ExpenseResponse> getExpensesForDriver(Long driverId) {
        return expenseRepository.findByDriverIdOrderByExpenseDateDesc(driverId)
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<ExpenseResponse> getAllExpenses(Long tenantId) {
        return expenseRepository.findByTenantIdOrderByExpenseDateDesc(tenantId)
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Transactional
    public ExpenseResponse reviewExpense(Long tenantId, Long expenseId, ExpenseStatusRequest req) {
        Expense expense = expenseRepository.findById(expenseId)
                .filter(e -> e.getTenant() != null && e.getTenant().getId().equals(tenantId))
                .orElseThrow(() -> new ResourceNotFoundException("Expense not found: " + expenseId));
        expense.setStatus(req.getStatus());
        if (req.getReviewNotes() != null) {
            expense.setReviewNotes(req.getReviewNotes());
        }
        return toResponse(expenseRepository.save(expense));
    }

    private ExpenseResponse toResponse(Expense e) {
        return new ExpenseResponse(
                e.getId(),
                e.getTrip() != null ? e.getTrip().getId() : null,
                e.getDriver().getId(),
                e.getDriver().getName(),
                e.getCategory(),
                e.getAmount(),
                e.getDescription(),
                e.getReceiptUrl(),
                e.getExpenseDate(),
                e.getStatus(),
                e.getReviewNotes()
        );
    }
}