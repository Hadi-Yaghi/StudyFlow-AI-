package com.studyflow.scheduler;

import com.studyflow.entity.StudySession;
import com.studyflow.entity.StudySessionStatus;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.time.LocalTime;
import java.util.Collection;
import java.util.List;
import java.util.Set;

/**
 * Centralized conflict and break validation engine for StudyFlow.
 * Enforces that two study sessions for the same user on the same date can NEVER overlap
 * and must always respect the required breakMinutes.
 */
@Slf4j
@Component
public class ScheduleConflictValidator {

    public static final Set<StudySessionStatus> TIME_OCCUPYING_STATUSES = Set.of(
            StudySessionStatus.PLANNED,
            StudySessionStatus.IN_PROGRESS,
            StudySessionStatus.COMPLETED
    );

    public record TimeInterval(LocalTime start, LocalTime end) {
        public TimeInterval {
            if (start == null || end == null) {
                throw new IllegalArgumentException("Start and end time cannot be null");
            }
            if (!start.isBefore(end)) {
                throw new IllegalArgumentException("Start time (" + start + ") must be before end time (" + end + ")");
            }
        }

        public int getMinutes() {
            return (int) java.time.Duration.between(start, end).toMinutes();
        }
    }

    /**
     * Checks if two time intervals conflict on the same day, considering breakMinutes.
     *
     * Two sessions conflict if they directly overlap OR if the gap between them is less than breakMinutes.
     * Rule:
     * - If start1 <= start2: conflict if start2 < end1 + breakMinutes
     * - If start2 < start1:  conflict if start1 < end2 + breakMinutes
     */
    public boolean hasConflict(
            LocalTime start1,
            LocalTime end1,
            LocalTime start2,
            LocalTime end2,
            int breakMinutes
    ) {
        if (breakMinutes < 0) {
            breakMinutes = 0;
        }

        // Exact same start time is always a conflict
        if (start1.equals(start2)) {
            return true;
        }

        if (start1.isBefore(start2)) {
            LocalTime threshold = addMinutesSafe(end1, breakMinutes);
            // If wrapped around midnight, any start2 on this day is before the threshold
            if (end1.isAfter(threshold) && breakMinutes > 0) {
                return true;
            }
            return start2.isBefore(threshold);
        } else {
            LocalTime threshold = addMinutesSafe(end2, breakMinutes);
            if (end2.isAfter(threshold) && breakMinutes > 0) {
                return true;
            }
            return start1.isBefore(threshold);
        }
    }

    /**
     * Checks if candidate interval [start, end] conflicts with any of the occupied intervals.
     */
    public boolean hasConflictWithAny(
            LocalTime candidateStart,
            LocalTime candidateEnd,
            Collection<TimeInterval> occupiedIntervals,
            int breakMinutes
    ) {
        if (occupiedIntervals == null || occupiedIntervals.isEmpty()) {
            return false;
        }

        for (TimeInterval occupied : occupiedIntervals) {
            if (hasConflict(candidateStart, candidateEnd, occupied.start(), occupied.end(), breakMinutes)) {
                log.debug("Conflict detected: candidate [{} - {}] conflicts with occupied [{} - {}] (break: {}m)",
                        candidateStart, candidateEnd, occupied.start(), occupied.end(), breakMinutes);
                return true;
            }
        }
        return false;
    }

    /**
     * Checks whether two sessions directly overlap without considering break.
     * newStart < existingEnd AND newEnd > existingStart
     */
    public boolean directlyOverlaps(
            LocalTime start1,
            LocalTime end1,
            LocalTime start2,
            LocalTime end2
    ) {
        return start1.isBefore(end2) && start2.isBefore(end1);
    }

    /**
     * Validates a candidate session against a list of existing sessions.
     */
    public boolean conflictsWithSessions(
            LocalTime candidateStart,
            LocalTime candidateEnd,
            List<StudySession> sessions,
            int breakMinutes,
            Long excludeSessionId
    ) {
        if (sessions == null || sessions.isEmpty()) {
            return false;
        }

        for (StudySession session : sessions) {
            if (excludeSessionId != null && session.getId() != null && session.getId().equals(excludeSessionId)) {
                continue;
            }
            if (!TIME_OCCUPYING_STATUSES.contains(session.getStatus())) {
                continue;
            }
            if (hasConflict(candidateStart, candidateEnd, session.getStartTime(), session.getEndTime(), breakMinutes)) {
                log.warn("Session conflict: candidate [{}-{}] conflicts with session ID={} [{}-{}] status={} (break: {}m)",
                        candidateStart, candidateEnd, session.getId(), session.getStartTime(), session.getEndTime(),
                        session.getStatus(), breakMinutes);
                return true;
            }
        }
        return false;
    }

    private LocalTime addMinutesSafe(LocalTime time, int minutes) {
        if (minutes <= 0) {
            return time;
        }
        // LocalTime.plusMinutes wraps on midnight; cap at 23:59:59 if it would wrap
        long totalSeconds = (long) time.toSecondOfDay() + (minutes * 60L);
        if (totalSeconds >= 86400) {
            return LocalTime.MAX;
        }
        return time.plusMinutes(minutes);
    }
}
