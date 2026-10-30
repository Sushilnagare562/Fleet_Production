package com.logisticfleet.dto;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.temporal.TemporalAdjusters;

/**
 * The three report windows admins can download for any dashboard
 * (trips, expenses, earnings, vehicle utilization). Every period is
 * resolved relative to a reference date so "this week / this month /
 * this year" and arbitrary historical periods both work from the same
 * enum.
 */
public enum ReportPeriod {
    WEEKLY,
    MONTHLY,
    YEARLY;

    /** Inclusive [from, to] date range containing {@code referenceDate}. */
    public DateRange resolveRange(LocalDate referenceDate) {
        LocalDate ref = referenceDate != null ? referenceDate : LocalDate.now();
        return switch (this) {
            case WEEKLY -> new DateRange(
                    ref.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY)),
                    ref.with(TemporalAdjusters.nextOrSame(DayOfWeek.SUNDAY)));
            case MONTHLY -> new DateRange(
                    ref.with(TemporalAdjusters.firstDayOfMonth()),
                    ref.with(TemporalAdjusters.lastDayOfMonth()));
            case YEARLY -> new DateRange(
                    ref.with(TemporalAdjusters.firstDayOfYear()),
                    ref.with(TemporalAdjusters.lastDayOfYear()));
        };
    }

    public record DateRange(LocalDate from, LocalDate to) {
    }
}
