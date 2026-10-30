package com.logisticfleet.controller;

import com.logisticfleet.dto.ReportPeriod;
import com.logisticfleet.security.CurrentUserResolver;
import com.logisticfleet.service.ReportService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.nio.charset.StandardCharsets;
import java.time.LocalDate;

/**
 * Admin-only Excel export endpoints, one per dashboard (trips, expenses,
 * earnings, fleet/vehicles). Locked to ROLE_ADMIN via /api/admin/** in
 * SecurityConfig — no extra security wiring needed here.
 * <p>
 * Every report is generated on the fly (nothing is cached or stored on
 * disk) and scoped to the caller's tenant via {@link CurrentUserResolver}.
 */
@Slf4j
@RestController
@RequestMapping("/api/admin/reports")
@RequiredArgsConstructor
public class ReportController {

    private static final MediaType XLSX =
            MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");

    private final ReportService reportService;
    private final CurrentUserResolver currentUserResolver;

    /** Trips per truck/driver — who drove where, when, and how far. */
    @GetMapping("/trips")
    public ResponseEntity<byte[]> tripsReport(
            @RequestParam ReportPeriod period,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        byte[] bytes = reportService.buildTripsReport(currentUserResolver.getCurrentTenantId(), period, date);
        return download(bytes, fileName("trips", period));
    }

    /** Driver expense ledger with per-category breakdown and totals. */
    @GetMapping("/expenses")
    public ResponseEntity<byte[]> expensesReport(
            @RequestParam ReportPeriod period,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        byte[] bytes = reportService.buildExpensesReport(currentUserResolver.getCurrentTenantId(), period, date);
        return download(bytes, fileName("expenses", period));
    }

    /** Driver earnings / payouts ledger. */
    @GetMapping("/earnings")
    public ResponseEntity<byte[]> earningsReport(
            @RequestParam ReportPeriod period,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        byte[] bytes = reportService.buildEarningsReport(currentUserResolver.getCurrentTenantId(), period, date);
        return download(bytes, fileName("earnings", period));
    }

    /** Point-in-time fleet/vehicle status snapshot — not period scoped. */
    @GetMapping("/vehicles")
    public ResponseEntity<byte[]> vehiclesReport() {
        byte[] bytes = reportService.buildVehiclesReport(currentUserResolver.getCurrentTenantId());
        return download(bytes, "logisticfleet-fleet-status-" + LocalDate.now() + ".xlsx");
    }

    private ResponseEntity<byte[]> download(byte[] bytes, String fileName) {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentDisposition(
                ContentDisposition.attachment().filename(fileName, StandardCharsets.UTF_8).build());
        return ResponseEntity.ok()
                .headers(headers)
                .contentType(XLSX)
                .contentLength(bytes.length)
                .body(bytes);
    }

    private String fileName(String type, ReportPeriod period) {
        return "logisticfleet-" + type + "-" + period.name().toLowerCase() + "-" + LocalDate.now() + ".xlsx";
    }
}
