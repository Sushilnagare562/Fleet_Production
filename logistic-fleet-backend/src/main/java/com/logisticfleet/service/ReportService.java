package com.logisticfleet.service;

import com.logisticfleet.dto.ReportPeriod;
import com.logisticfleet.entity.Earning;
import com.logisticfleet.entity.Expense;
import com.logisticfleet.entity.Trip;
import com.logisticfleet.entity.Vehicle;
import com.logisticfleet.repository.EarningRepository;
import com.logisticfleet.repository.ExpenseRepository;
import com.logisticfleet.repository.TripRepository;
import com.logisticfleet.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.ss.util.CellRangeAddress;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Builds downloadable .xlsx workbooks for every admin dashboard (trips per
 * truck/driver, expenses, earnings, fleet/vehicle status), for the WEEKLY,
 * MONTHLY and YEARLY windows exposed by {@link ReportPeriod}.
 * <p>
 * Every query is scoped to the caller's tenant so one company can never
 * download another company's data — the same isolation rule the rest of
 * the app follows.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ReportService {

    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("dd-MMM-yyyy");
    private static final DateTimeFormatter DATETIME_FMT = DateTimeFormatter.ofPattern("dd-MMM-yyyy HH:mm");

    private final TripRepository tripRepository;
    private final ExpenseRepository expenseRepository;
    private final EarningRepository earningRepository;
    private final VehicleRepository vehicleRepository;

    @Transactional(readOnly = true)
    public byte[] buildTripsReport(Long tenantId, ReportPeriod period, LocalDate referenceDate) {
        ReportPeriod.DateRange range = period.resolveRange(referenceDate);
        List<Trip> trips = tripRepository.findByTenantIdAndScheduledStartBetween(
                tenantId, range.from().atStartOfDay(), range.to().atTime(23, 59, 59));

        // Best-effort trip -> vehicle mapping via the driver currently assigned
        // to a vehicle, since a Trip only records its driver directly.
        Map<Long, String> vehicleByDriverId = vehicleRepository.findByTenantId(tenantId).stream()
                .filter(v -> v.getAssignedDriver() != null)
                .collect(Collectors.toMap(v -> v.getAssignedDriver().getId(), Vehicle::getVehicleNumber, (a, b) -> a));

        try (Workbook wb = new XSSFWorkbook(); ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            CellStyle header = headerStyle(wb);
            CellStyle dateStyle = dateStyle(wb);
            CellStyle numberStyle = numberStyle(wb);

            Sheet sheet = wb.createSheet("Trips - " + period.name());
            writeTitle(wb, sheet, "Logistic Fleet — Trips per Truck/Driver Report", period, range);

            String[] columns = {"Trip Code", "Driver", "Vehicle No.", "Origin", "Destination", "Status",
                    "Scheduled Start", "Scheduled End", "Actual Start", "Actual End", "Distance (km)", "Notes"};
            int headerRow = 2;
            writeHeaderRow(sheet, headerRow, header, columns);

            int r = headerRow + 1;
            for (Trip t : trips) {
                Row row = sheet.createRow(r++);
                int c = 0;
                cell(row, c++, t.getTripCode());
                cell(row, c++, t.getDriver() != null ? t.getDriver().getName() : "-");
                cell(row, c++, t.getDriver() != null ? vehicleByDriverId.getOrDefault(t.getDriver().getId(), "-") : "-");
                cell(row, c++, t.getOrigin());
                cell(row, c++, t.getDestination());
                cell(row, c++, t.getStatus().name());
                cell(row, c++, fmt(t.getScheduledStart()));
                cell(row, c++, fmt(t.getScheduledEnd()));
                cell(row, c++, fmt(t.getActualStart()));
                cell(row, c++, fmt(t.getActualEnd()));
                numberCell(row, c++, t.getDistanceKm() != null ? t.getDistanceKm().doubleValue() : 0, numberStyle);
                cell(row, c, t.getNotes());
            }

            writeSummaryRow(wb, sheet, r, columns.length, "Total trips: " + trips.size(), header);
            autosize(sheet, columns.length);
            sheet.setAutoFilter(new CellRangeAddress(headerRow, headerRow, 0, columns.length - 1));
            sheet.createFreezePane(0, headerRow + 1);

            wb.write(out);
            log.info("Trips report generated for tenant {} ({} rows)", tenantId, trips.size());
            return out.toByteArray();
        } catch (IOException e) {
            throw new UncheckedIOException("Failed to generate trips report", e);
        }
    }

    @Transactional(readOnly = true)
    public byte[] buildExpensesReport(Long tenantId, ReportPeriod period, LocalDate referenceDate) {
        ReportPeriod.DateRange range = period.resolveRange(referenceDate);
        List<Expense> expenses = expenseRepository.findByTenantIdAndExpenseDateBetween(tenantId, range.from(), range.to());

        try (Workbook wb = new XSSFWorkbook(); ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            CellStyle header = headerStyle(wb);
            CellStyle currency = currencyStyle(wb);

            Sheet sheet = wb.createSheet("Expenses - " + period.name());
            writeTitle(wb, sheet, "Logistic Fleet — Expense Report", period, range);

            String[] columns = {"Date", "Driver", "Category", "Amount (₹)", "Description", "Status", "Review Notes"};
            int headerRow = 2;
            writeHeaderRow(sheet, headerRow, header, columns);

            int r = headerRow + 1;
            BigDecimal total = BigDecimal.ZERO;
            for (Expense e : expenses) {
                Row row = sheet.createRow(r++);
                int c = 0;
                cell(row, c++, fmt(e.getExpenseDate()));
                cell(row, c++, e.getDriver().getName());
                cell(row, c++, e.getCategory().name());
                numberCell(row, c++, e.getAmount().doubleValue(), currency);
                cell(row, c++, e.getDescription());
                cell(row, c++, e.getStatus().name());
                cell(row, c, e.getReviewNotes());
                total = total.add(e.getAmount());
            }

            writeSummaryRow(wb, sheet, r, columns.length,
                    "Total expenses: " + expenses.size() + "   |   Total amount: ₹" + total, header);
            autosize(sheet, columns.length);
            sheet.setAutoFilter(new CellRangeAddress(headerRow, headerRow, 0, columns.length - 1));
            sheet.createFreezePane(0, headerRow + 1);

            wb.write(out);
            log.info("Expenses report generated for tenant {} ({} rows)", tenantId, expenses.size());
            return out.toByteArray();
        } catch (IOException e) {
            throw new UncheckedIOException("Failed to generate expenses report", e);
        }
    }

    @Transactional(readOnly = true)
    public byte[] buildEarningsReport(Long tenantId, ReportPeriod period, LocalDate referenceDate) {
        ReportPeriod.DateRange range = period.resolveRange(referenceDate);
        List<Earning> earnings = earningRepository.findByTenantIdAndPeriodStartBetween(tenantId, range.from(), range.to());

        try (Workbook wb = new XSSFWorkbook(); ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            CellStyle header = headerStyle(wb);
            CellStyle currency = currencyStyle(wb);

            Sheet sheet = wb.createSheet("Earnings - " + period.name());
            writeTitle(wb, sheet, "Logistic Fleet — Driver Earnings Report", period, range);

            String[] columns = {"Driver", "Trip Code", "Base Amount (₹)", "Bonus (₹)", "Deduction (₹)",
                    "Total (₹)", "Status", "Period Start", "Period End"};
            int headerRow = 2;
            writeHeaderRow(sheet, headerRow, header, columns);

            int r = headerRow + 1;
            BigDecimal total = BigDecimal.ZERO;
            for (Earning e : earnings) {
                Row row = sheet.createRow(r++);
                int c = 0;
                cell(row, c++, e.getDriver().getName());
                cell(row, c++, e.getTrip() != null ? e.getTrip().getTripCode() : "-");
                numberCell(row, c++, e.getBaseAmount().doubleValue(), currency);
                numberCell(row, c++, e.getBonus().doubleValue(), currency);
                numberCell(row, c++, e.getDeduction().doubleValue(), currency);
                numberCell(row, c++, e.getTotalAmount().doubleValue(), currency);
                cell(row, c++, e.getStatus().name());
                cell(row, c++, fmt(e.getPeriodStart()));
                cell(row, c, fmt(e.getPeriodEnd()));
                total = total.add(e.getTotalAmount());
            }

            writeSummaryRow(wb, sheet, r, columns.length,
                    "Total records: " + earnings.size() + "   |   Total payout: ₹" + total, header);
            autosize(sheet, columns.length);
            sheet.setAutoFilter(new CellRangeAddress(headerRow, headerRow, 0, columns.length - 1));
            sheet.createFreezePane(0, headerRow + 1);

            wb.write(out);
            log.info("Earnings report generated for tenant {} ({} rows)", tenantId, earnings.size());
            return out.toByteArray();
        } catch (IOException e) {
            throw new UncheckedIOException("Failed to generate earnings report", e);
        }
    }

    /** Fleet/vehicle status is a point-in-time snapshot rather than a dated ledger, so no period filter applies. */
    @Transactional(readOnly = true)
    public byte[] buildVehiclesReport(Long tenantId) {
        List<Vehicle> vehicles = vehicleRepository.findByTenantId(tenantId);

        try (Workbook wb = new XSSFWorkbook(); ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            CellStyle header = headerStyle(wb);
            CellStyle numberStyle = numberStyle(wb);

            Sheet sheet = wb.createSheet("Fleet Status");
            Row title = sheet.createRow(0);
            title.createCell(0).setCellValue("Logistic Fleet — Fleet / Vehicle Status Snapshot  (generated "
                    + LocalDateTime.now().format(DATETIME_FMT) + ")");
            title.getCell(0).setCellStyle(titleStyle(wb));
            sheet.addMergedRegion(new CellRangeAddress(0, 0, 0, 6));

            String[] columns = {"Vehicle No.", "Type", "Model", "Capacity (kg)", "Status", "Assigned Driver"};
            int headerRow = 2;
            writeHeaderRow(sheet, headerRow, header, columns);

            int r = headerRow + 1;
            for (Vehicle v : vehicles) {
                Row row = sheet.createRow(r++);
                int c = 0;
                cell(row, c++, v.getVehicleNumber());
                cell(row, c++, v.getType().name());
                cell(row, c++, v.getModel());
                numberCell(row, c++, v.getCapacityKg() != null ? v.getCapacityKg() : 0, numberStyle);
                cell(row, c++, v.getStatus().name());
                cell(row, c, v.getAssignedDriver() != null ? v.getAssignedDriver().getName() : "Unassigned");
            }

            writeSummaryRow(wb, sheet, r, columns.length, "Total vehicles: " + vehicles.size(), header);
            autosize(sheet, columns.length);
            sheet.setAutoFilter(new CellRangeAddress(headerRow, headerRow, 0, columns.length - 1));
            sheet.createFreezePane(0, headerRow + 1);

            wb.write(out);
            log.info("Vehicles report generated for tenant {} ({} rows)", tenantId, vehicles.size());
            return out.toByteArray();
        } catch (IOException e) {
            throw new UncheckedIOException("Failed to generate vehicles report", e);
        }
    }

    // ---------------------------------------------------------------
    // Styling & layout helpers
    // ---------------------------------------------------------------

    private void writeTitle(Workbook wb, Sheet sheet, String title, ReportPeriod period, ReportPeriod.DateRange range) {
        Row row = sheet.createRow(0);
        row.createCell(0).setCellValue(title + "  —  " + period.name() + "  ("
                + range.from().format(DATE_FMT) + " to " + range.to().format(DATE_FMT) + ")");
        row.getCell(0).setCellStyle(titleStyle(wb));
        sheet.addMergedRegion(new CellRangeAddress(0, 0, 0, 8));
    }

    private void writeHeaderRow(Sheet sheet, int rowIdx, CellStyle style, String[] columns) {
        Row row = sheet.createRow(rowIdx);
        for (int i = 0; i < columns.length; i++) {
            Cell c = row.createCell(i);
            c.setCellValue(columns[i]);
            c.setCellStyle(style);
        }
    }

    private void writeSummaryRow(Workbook wb, Sheet sheet, int rowIdx, int columnCount, String text, CellStyle style) {
        Row row = sheet.createRow(rowIdx + 1);
        Cell c = row.createCell(0);
        c.setCellValue(text);
        CellStyle summaryStyle = wb.createCellStyle();
        summaryStyle.cloneStyleFrom(style);
        c.setCellStyle(summaryStyle);
        sheet.addMergedRegion(new CellRangeAddress(row.getRowNum(), row.getRowNum(), 0, Math.max(columnCount - 1, 1)));
    }

    private void autosize(Sheet sheet, int columnCount) {
        for (int i = 0; i < columnCount; i++) {
            sheet.autoSizeColumn(i);
            // autoSizeColumn under-measures header-only sheets sometimes; give every
            // column a sane floor so headers never render clipped.
            if (sheet.getColumnWidth(i) < 3000) {
                sheet.setColumnWidth(i, 3000);
            }
        }
    }

    private CellStyle titleStyle(Workbook wb) {
        Font font = wb.createFont();
        font.setBold(true);
        font.setFontHeightInPoints((short) 13);
        font.setColor(IndexedColors.WHITE.getIndex());
        CellStyle style = wb.createCellStyle();
        style.setFont(font);
        style.setFillForegroundColor(IndexedColors.DARK_TEAL.getIndex());
        style.setFillPattern(FillPatternType.SOLID_FOREGROUND);
        style.setVerticalAlignment(VerticalAlignment.CENTER);
        return style;
    }

    private CellStyle headerStyle(Workbook wb) {
        Font font = wb.createFont();
        font.setBold(true);
        font.setColor(IndexedColors.WHITE.getIndex());
        CellStyle style = wb.createCellStyle();
        style.setFont(font);
        style.setFillForegroundColor(IndexedColors.TEAL.getIndex());
        style.setFillPattern(FillPatternType.SOLID_FOREGROUND);
        style.setBorderBottom(BorderStyle.THIN);
        style.setAlignment(HorizontalAlignment.CENTER);
        return style;
    }

    private CellStyle dateStyle(Workbook wb) {
        CellStyle style = wb.createCellStyle();
        style.setDataFormat(wb.createDataFormat().getFormat("dd-mmm-yyyy"));
        return style;
    }

    private CellStyle numberStyle(Workbook wb) {
        CellStyle style = wb.createCellStyle();
        style.setDataFormat(wb.createDataFormat().getFormat("#,##0.00"));
        return style;
    }

    private CellStyle currencyStyle(Workbook wb) {
        CellStyle style = wb.createCellStyle();
        style.setDataFormat(wb.createDataFormat().getFormat("#,##0.00"));
        return style;
    }

    private void cell(Row row, int idx, String value) {
        row.createCell(idx).setCellValue(value != null ? value : "-");
    }

    private void numberCell(Row row, int idx, double value, CellStyle style) {
        Cell c = row.createCell(idx);
        c.setCellValue(value);
        c.setCellStyle(style);
    }

    private String fmt(LocalDateTime dt) {
        return dt != null ? dt.format(DATETIME_FMT) : "-";
    }

    private String fmt(LocalDate d) {
        return d != null ? d.format(DATE_FMT) : "-";
    }
}