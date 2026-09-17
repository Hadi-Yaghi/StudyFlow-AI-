package com.studyflow.scheduler;

import com.studyflow.entity.StudyPreferences;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

@Slf4j
@Component
public class TimeAllocator {

    public static final int MIN_SESSION_MINUTES = 15;

    public List<TimeBlock> allocate(
            LocalTime startTime,
            LocalTime endTime,
            StudyPreferences preferences
    ) {
        return allocate(startTime, endTime, preferences, null, List.of());
    }

    /**
     * Slices an availability window into valid study session blocks, strictly carving around
     * existing or same-generation occupied sessions and enforcing breakMinutes.
     *
     * @param windowStart       Beginning of availability window
     * @param windowEnd         End of availability window
     * @param preferences       User study preferences (maxSessionMinutes, breakMinutes)
     * @param date              Scheduling date (used to clamp past times if date is today)
     * @param occupiedIntervals Intervals already occupied on this date
     * @return List of conflict-free time blocks
     */
    public List<TimeBlock> allocate(
            LocalTime windowStart,
            LocalTime windowEnd,
            StudyPreferences preferences,
            LocalDate date,
            List<ScheduleConflictValidator.TimeInterval> occupiedIntervals
    ) {
        List<TimeBlock> blocks = new ArrayList<>();

        if (windowStart == null || windowEnd == null || !windowStart.isBefore(windowEnd)) {
            return blocks;
        }

        LocalTime effectiveStart = windowStart;

        // If scheduling for today, do not allocate slots that have already passed
        if (date != null && date.equals(LocalDate.now())) {
            LocalTime nowWithBuffer = LocalTime.now().plusMinutes(5);
            if (nowWithBuffer.isAfter(windowEnd)) {
                log.debug("Availability window [{}-{}] for today is completely in the past (nowWithBuffer={})",
                        windowStart, windowEnd, nowWithBuffer);
                return blocks;
            }
            if (nowWithBuffer.isAfter(effectiveStart)) {
                effectiveStart = nowWithBuffer;
            }
        }

        if (!effectiveStart.isBefore(windowEnd)) {
            return blocks;
        }

        int sessionMinutes = (preferences != null && preferences.getMaxSessionMinutes() != null)
                ? Math.max(preferences.getMaxSessionMinutes(), MIN_SESSION_MINUTES)
                : 60;
        int breakMinutes = (preferences != null && preferences.getBreakMinutes() != null)
                ? Math.max(preferences.getBreakMinutes(), 0)
                : 15;

        // 1. Build blocked zones by expanding occupied intervals by breakMinutes
        List<ScheduleConflictValidator.TimeInterval> rawBlocked = new ArrayList<>();
        if (occupiedIntervals != null) {
            for (ScheduleConflictValidator.TimeInterval occ : occupiedIntervals) {
                LocalTime bStart = subMinutesSafe(occ.start(), breakMinutes);
                LocalTime bEnd = addMinutesSafe(occ.end(), breakMinutes);

                // Intersect with [effectiveStart, windowEnd]
                LocalTime clampedStart = bStart.isBefore(effectiveStart) ? effectiveStart : bStart;
                LocalTime clampedEnd = bEnd.isAfter(windowEnd) ? windowEnd : bEnd;

                if (clampedStart.isBefore(clampedEnd)) {
                    rawBlocked.add(new ScheduleConflictValidator.TimeInterval(clampedStart, clampedEnd));
                }
            }
        }

        // 2. Sort and merge overlapping or adjacent blocked zones
        rawBlocked.sort(Comparator.comparing(ScheduleConflictValidator.TimeInterval::start));
        List<ScheduleConflictValidator.TimeInterval> mergedBlocked = new ArrayList<>();
        for (ScheduleConflictValidator.TimeInterval current : rawBlocked) {
            if (mergedBlocked.isEmpty()) {
                mergedBlocked.add(current);
            } else {
                ScheduleConflictValidator.TimeInterval prev = mergedBlocked.get(mergedBlocked.size() - 1);
                if (!current.start().isAfter(prev.end())) {
                    // Overlapping or adjacent: merge
                    LocalTime maxEnd = current.end().isAfter(prev.end()) ? current.end() : prev.end();
                    mergedBlocked.set(mergedBlocked.size() - 1, new ScheduleConflictValidator.TimeInterval(prev.start(), maxEnd));
                } else {
                    mergedBlocked.add(current);
                }
            }
        }

        // 3. Compute disjoint free intervals within [effectiveStart, windowEnd]
        List<ScheduleConflictValidator.TimeInterval> freeIntervals = new ArrayList<>();
        LocalTime cursor = effectiveStart;
        for (ScheduleConflictValidator.TimeInterval blocked : mergedBlocked) {
            if (cursor.isBefore(blocked.start())) {
                freeIntervals.add(new ScheduleConflictValidator.TimeInterval(cursor, blocked.start()));
            }
            if (blocked.end().isAfter(cursor)) {
                cursor = blocked.end();
            }
        }
        if (cursor.isBefore(windowEnd)) {
            freeIntervals.add(new ScheduleConflictValidator.TimeInterval(cursor, windowEnd));
        }

        // 4. Divide each free interval into study blocks of size <= sessionMinutes, separated by breakMinutes
        for (ScheduleConflictValidator.TimeInterval free : freeIntervals) {
            LocalTime current = free.start();
            LocalTime fEnd = free.end();

            while (true) {
                LocalTime candidateEnd = addMinutesSafe(current, sessionMinutes);
                if (candidateEnd.isBefore(fEnd) || candidateEnd.equals(fEnd)) {
                    blocks.add(new TimeBlock(current, candidateEnd));
                    current = addMinutesSafe(candidateEnd, breakMinutes);
                    if (!current.isBefore(fEnd)) {
                        break;
                    }
                } else {
                    // Remaining time is less than a full session
                    int remainingMin = (int) Duration.between(current, fEnd).toMinutes();
                    if (remainingMin >= MIN_SESSION_MINUTES) {
                        blocks.add(new TimeBlock(current, fEnd));
                    }
                    break;
                }
            }
        }

        return blocks;
    }

    private LocalTime addMinutesSafe(LocalTime time, int minutes) {
        if (minutes <= 0) return time;
        long totalSec = (long) time.toSecondOfDay() + (minutes * 60L);
        if (totalSec >= 86400) {
            return LocalTime.MAX;
        }
        return time.plusMinutes(minutes);
    }

    private LocalTime subMinutesSafe(LocalTime time, int minutes) {
        if (minutes <= 0) return time;
        long totalSec = (long) time.toSecondOfDay() - (minutes * 60L);
        if (totalSec <= 0) {
            return LocalTime.MIN;
        }
        return time.minusMinutes(minutes);
    }

    public record TimeBlock(
            LocalTime startTime,
            LocalTime endTime
    ) {
        public int getMinutes() {
            return (int) (
                    java.time.Duration.between(
                            startTime,
                            endTime
                    ).toMinutes()
            );
        }
    }
}