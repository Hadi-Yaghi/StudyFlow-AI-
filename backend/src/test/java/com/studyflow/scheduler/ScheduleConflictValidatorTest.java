package com.studyflow.scheduler;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.LocalTime;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class ScheduleConflictValidatorTest {

    private ScheduleConflictValidator validator;

    @BeforeEach
    void setUp() {
        validator = new ScheduleConflictValidator();
    }

    @Test
    void testExactSameTime_Conflicts() {
        // Task A: 20:45 -> 21:45, Task B: 20:45 -> 21:45
        boolean conflict = validator.hasConflict(
                LocalTime.of(20, 45), LocalTime.of(21, 45),
                LocalTime.of(20, 45), LocalTime.of(21, 45),
                0
        );
        assertTrue(conflict, "Exact same start and end time must conflict");
    }

    @Test
    void testPartialOverlap_EndInside_Conflicts() {
        // Existing: 20:45 -> 21:45, Candidate: 20:30 -> 21:00
        boolean conflict = validator.hasConflict(
                LocalTime.of(20, 45), LocalTime.of(21, 45),
                LocalTime.of(20, 30), LocalTime.of(21, 0),
                0
        );
        assertTrue(conflict, "Candidate ending after existing start must conflict");
    }

    @Test
    void testPartialOverlap_StartInside_Conflicts() {
        // Existing: 20:45 -> 21:45, Candidate: 21:15 -> 22:00
        boolean conflict = validator.hasConflict(
                LocalTime.of(20, 45), LocalTime.of(21, 45),
                LocalTime.of(21, 15), LocalTime.of(22, 0),
                0
        );
        assertTrue(conflict, "Candidate starting before existing end must conflict");
    }

    @Test
    void testEnclosingSession_Conflicts() {
        // Existing: 20:45 -> 21:45, Candidate: 20:30 -> 22:00
        boolean conflict = validator.hasConflict(
                LocalTime.of(20, 45), LocalTime.of(21, 45),
                LocalTime.of(20, 30), LocalTime.of(22, 0),
                0
        );
        assertTrue(conflict, "Enclosing interval must conflict");
    }

    @Test
    void testContainedSession_Conflicts() {
        // Existing: 20:45 -> 21:45, Candidate: 20:50 -> 21:30
        boolean conflict = validator.hasConflict(
                LocalTime.of(20, 45), LocalTime.of(21, 45),
                LocalTime.of(20, 50), LocalTime.of(21, 30),
                0
        );
        assertTrue(conflict, "Sub-interval must conflict");
    }

    @Test
    void testBackToBack_BreakZero_Allowed() {
        // Session 1: 19:45 -> 20:45, Session 2: 20:45 -> 21:45 with break=0
        boolean conflict = validator.hasConflict(
                LocalTime.of(19, 45), LocalTime.of(20, 45),
                LocalTime.of(20, 45), LocalTime.of(21, 45),
                0
        );
        assertFalse(conflict, "Touching boundary with break=0 should be allowed");
    }

    @Test
    void testBackToBack_WithRequiredBreak_Conflicts() {
        // Session 1: 20:00 -> 21:00, Session 2: 21:05 -> 22:00, break = 15 min
        // Next session cannot start before 21:15!
        boolean conflict = validator.hasConflict(
                LocalTime.of(20, 0), LocalTime.of(21, 0),
                LocalTime.of(21, 5), LocalTime.of(22, 0),
                15
        );
        assertTrue(conflict, "Session starting at 21:05 when previous ended at 21:00 with 15m break must conflict");
    }

    @Test
    void testRespectingBreak_Allowed() {
        // Session 1: 20:00 -> 21:00, Session 2: 21:15 -> 22:00, break = 15 min
        boolean conflict = validator.hasConflict(
                LocalTime.of(20, 0), LocalTime.of(21, 0),
                LocalTime.of(21, 15), LocalTime.of(22, 0),
                15
        );
        assertFalse(conflict, "Session starting at 21:15 after 21:00 with 15m break must be allowed");
    }

    @Test
    void testPrecedingSession_ViolatingBreak_Conflicts() {
        // Session 1 (candidate): 19:00 -> 20:00, Session 2 (existing): 20:00 -> 21:00, break = 15 min
        // Candidate ends at 20:00, but existing starts at 20:00, so break is 0 min < 15 min
        boolean conflict = validator.hasConflict(
                LocalTime.of(19, 0), LocalTime.of(20, 0),
                LocalTime.of(20, 0), LocalTime.of(21, 0),
                15
        );
        assertTrue(conflict, "Preceding session touching existing session must violate required break");
    }

    @Test
    void testPrecedingSession_RespectingBreak_Allowed() {
        // Session 1 (candidate): 18:45 -> 19:45, Session 2 (existing): 20:00 -> 21:00, break = 15 min
        // Gap is 15 min -> exactly break
        boolean conflict = validator.hasConflict(
                LocalTime.of(18, 45), LocalTime.of(19, 45),
                LocalTime.of(20, 0), LocalTime.of(21, 0),
                15
        );
        assertFalse(conflict, "Preceding session ending 15m before existing session start must be allowed");
    }

    @Test
    void testConflictWithAnyOccupiedInterval() {
        List<ScheduleConflictValidator.TimeInterval> occupied = List.of(
                new ScheduleConflictValidator.TimeInterval(LocalTime.of(10, 0), LocalTime.of(11, 0)),
                new ScheduleConflictValidator.TimeInterval(LocalTime.of(14, 0), LocalTime.of(15, 0))
        );

        // Candidate 1: 10:45 -> 11:45 (conflicts with 10:00-11:00)
        assertTrue(validator.hasConflictWithAny(LocalTime.of(10, 45), LocalTime.of(11, 45), occupied, 15));

        // Candidate 2: 12:00 -> 13:00 (free slot, break respected)
        assertFalse(validator.hasConflictWithAny(LocalTime.of(12, 0), LocalTime.of(13, 0), occupied, 15));

        // Candidate 3: 13:50 -> 14:30 (conflicts with 14:00-15:00)
        assertTrue(validator.hasConflictWithAny(LocalTime.of(13, 50), LocalTime.of(14, 30), occupied, 15));

        // Candidate 4: 13:45 -> 14:00 (break violation with 14:00)
        assertTrue(validator.hasConflictWithAny(LocalTime.of(13, 0), LocalTime.of(13, 50), occupied, 15));
    }
}
