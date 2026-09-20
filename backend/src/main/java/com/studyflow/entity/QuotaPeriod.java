package com.studyflow.entity;

import java.time.DayOfWeek;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.temporal.TemporalAdjusters;

public enum QuotaPeriod {
    DAILY,
    WEEKLY,
    MONTHLY,
    LIFETIME;

    /**
     * Computes the beginning of the quota window for the given instant in the specified time zone.
     */
    public Instant getPeriodStart(Instant now, ZoneId zoneId) {
        if (now == null) {
            now = Instant.now();
        }
        if (zoneId == null) {
            zoneId = ZoneId.systemDefault();
        }

        LocalDate currentDate = now.atZone(zoneId).toLocalDate();

        return switch (this) {
            case DAILY -> currentDate.atStartOfDay(zoneId).toInstant();
            case WEEKLY -> currentDate.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
                    .atStartOfDay(zoneId).toInstant();
            case MONTHLY -> currentDate.with(TemporalAdjusters.firstDayOfMonth())
                    .atStartOfDay(zoneId).toInstant();
            case LIFETIME -> Instant.EPOCH;
        };
    }
}
