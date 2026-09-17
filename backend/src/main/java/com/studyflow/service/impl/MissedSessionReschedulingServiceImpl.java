package com.studyflow.service.impl;

import com.studyflow.entity.*;
import com.studyflow.repository.AvailabilityRepository;
import com.studyflow.repository.StudyPreferencesRepository;
import com.studyflow.repository.StudySessionRepository;
import com.studyflow.scheduler.ScheduleConflictValidator;
import com.studyflow.scheduler.TimeAllocator;
import com.studyflow.service.MissedSessionReschedulingService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class MissedSessionReschedulingServiceImpl
        implements MissedSessionReschedulingService {

    private final StudySessionRepository studySessionRepository;
    private final AvailabilityRepository availabilityRepository;
    private final StudyPreferencesRepository studyPreferencesRepository;
    private final TimeAllocator timeAllocator;
    private final ScheduleConflictValidator scheduleConflictValidator;

    @Override
    @Transactional
    @Scheduled(fixedRate = 60000)
    public void rescheduleMissedSessions() {
        List<StudySession> unrescheduledMissed =
                studySessionRepository.findByStatusAndRescheduledFalse(
                        StudySessionStatus.MISSED
                );

        if (unrescheduledMissed.isEmpty()) {
            return;
        }

        log.info("Found {} unrescheduled missed sessions to process", unrescheduledMissed.size());

        // Group by user for strict isolation
        Map<User, List<StudySession>> sessionsByUser = unrescheduledMissed.stream()
                .filter(s -> s.getTask() != null
                        && s.getTask().getCourse() != null
                        && s.getTask().getCourse().getSemester() != null
                        && s.getTask().getCourse().getSemester().getUser() != null)
                .collect(Collectors.groupingBy(s -> s.getTask().getCourse().getSemester().getUser()));

        LocalDate today = LocalDate.now();

        for (Map.Entry<User, List<StudySession>> entry : sessionsByUser.entrySet()) {
            User user = entry.getKey();
            List<StudySession> userMissedSessions = entry.getValue();

            StudyPreferences preferences = studyPreferencesRepository.findByUser(user).orElse(null);
            if (preferences == null) {
                log.warn("Cannot reschedule missed sessions for user {}: No study preferences found", user.getEmail());
                continue;
            }

            int breakMinutes = preferences.getBreakMinutes() != null ? Math.max(preferences.getBreakMinutes(), 0) : 15;
            List<Availability> availabilities = availabilityRepository.findByUser(user);
            if (availabilities.isEmpty() || availabilities.stream().noneMatch(Availability::isEnabled)) {
                log.warn("Cannot reschedule missed sessions for user {}: No enabled availability found", user.getEmail());
                continue;
            }

            // Maintain occupied intervals per date for this user during this rescheduling run
            Map<LocalDate, List<ScheduleConflictValidator.TimeInterval>> occupiedMap = new HashMap<>();

            for (StudySession missedSession : userMissedSessions) {
                Task task = missedSession.getTask();

                if (task == null || task.getStatus() == TaskStatus.COMPLETED) {
                    log.info("Missed session ID={} task is already completed or null. Marking rescheduled=true.", missedSession.getId());
                    missedSession.setRescheduled(true);
                    studySessionRepository.save(missedSession);
                    continue;
                }

                // Check task due date
                if (task.getDueDate() != null && task.getDueDate().isBefore(today)) {
                    log.warn("Missed session ID={} task '{}' due date ({}) has already passed. Cannot reschedule.",
                            missedSession.getId(), task.getTitle(), task.getDueDate());
                    continue;
                }

                // Calculate actual remaining required study minutes for this task (Part N)
                int estimatedMinutes = task.getEstimatedHours() != null ? task.getEstimatedHours() * 60 : 0;
                int completedMinutes = task.getCompletedHours() != null ? task.getCompletedHours() * 60 : 0;

                List<StudySession> allTaskSessions = studySessionRepository.findByTask(task);
                int activePlannedMinutes = allTaskSessions.stream()
                        .filter(s -> s.getStatus() == StudySessionStatus.PLANNED && !s.getId().equals(missedSession.getId()))
                        .mapToInt(StudySession::getPlannedMinutes)
                        .sum();

                int actualRemainingTaskMinutes = Math.max(estimatedMinutes - (completedMinutes + activePlannedMinutes), 0);
                int plannedForThisSession = missedSession.getPlannedMinutes() != null ? missedSession.getPlannedMinutes() : 60;
                int alreadyDoneInThisSession = missedSession.getCompletedMinutes() != null ? missedSession.getCompletedMinutes() : 0;
                int neededForThisSession = Math.min(plannedForThisSession - alreadyDoneInThisSession, actualRemainingTaskMinutes);

                if (neededForThisSession <= 0) {
                    log.info("Task '{}' requires no additional study time (remaining={}). Marking missed session ID={} as rescheduled.",
                            task.getTitle(), actualRemainingTaskMinutes, missedSession.getId());
                    missedSession.setRescheduled(true);
                    studySessionRepository.save(missedSession);
                    continue;
                }

                // Search for a valid, non-conflicting slot in the next 7 days
                boolean rescheduled = false;

                for (int i = 0; i < 7; i++) {
                    LocalDate candidateDate = today.plusDays(i);
                    DayOfWeek dayOfWeek = candidateDate.getDayOfWeek();

                    // Weekend preference check
                    if (!preferences.getAllowWeekendStudy()
                            && (dayOfWeek == DayOfWeek.SATURDAY || dayOfWeek == DayOfWeek.SUNDAY)) {
                        continue;
                    }

                    // Deadline check
                    if (task.getDueDate() != null && candidateDate.isAfter(task.getDueDate())) {
                        break; // Past due date, cannot schedule further
                    }

                    // Semester boundary check
                    Semester semester = task.getCourse().getSemester();
                    if (semester.getEndDate() != null && candidateDate.isAfter(semester.getEndDate())) {
                        break;
                    }

                    List<Availability> dailyAvailability = availabilities.stream()
                            .filter(a -> a.isEnabled() && a.getDay().name().equals(dayOfWeek.name()))
                            .toList();

                    if (dailyAvailability.isEmpty()) {
                        continue;
                    }

                    // Ensure occupied list is loaded for this candidate date
                    List<ScheduleConflictValidator.TimeInterval> occupiedList = occupiedMap.computeIfAbsent(candidateDate, d -> {
                        List<StudySession> dbSessions = studySessionRepository
                                .findByUserAndSessionDateAndStatusInOrderByStartTime(
                                        user,
                                        d,
                                        ScheduleConflictValidator.TIME_OCCUPYING_STATUSES
                                );
                        List<ScheduleConflictValidator.TimeInterval> intervals = new ArrayList<>();
                        for (StudySession s : dbSessions) {
                            intervals.add(new ScheduleConflictValidator.TimeInterval(s.getStartTime(), s.getEndTime()));
                        }
                        return intervals;
                    });

                    for (Availability availability : dailyAvailability) {
                        LocalTime slotStart = availability.getStartTime();
                        LocalTime slotEnd = availability.getEndTime();

                        // Intersect with preferred study hours if configured
                        if (preferences.getPreferredStudyStart() != null && preferences.getPreferredStudyEnd() != null) {
                            LocalTime prefStart = preferences.getPreferredStudyStart();
                            LocalTime prefEnd = preferences.getPreferredStudyEnd();

                            LocalTime effectiveStart = slotStart.isBefore(prefStart) ? prefStart : slotStart;
                            LocalTime effectiveEnd = slotEnd.isAfter(prefEnd) ? prefEnd : slotEnd;

                            if (!effectiveStart.isBefore(effectiveEnd)) {
                                continue;
                            }

                            slotStart = effectiveStart;
                            slotEnd = effectiveEnd;
                        }

                        List<TimeAllocator.TimeBlock> blocks = timeAllocator.allocate(
                                slotStart,
                                slotEnd,
                                preferences,
                                candidateDate,
                                occupiedList
                        );

                        for (TimeAllocator.TimeBlock block : blocks) {
                            if (block.getMinutes() < TimeAllocator.MIN_SESSION_MINUTES) {
                                continue;
                            }

                            int scheduledMinutes = Math.min(neededForThisSession, block.getMinutes());
                            LocalTime sessionStart = block.startTime();
                            LocalTime sessionEnd = sessionStart.plusMinutes(scheduledMinutes);

                            // Strict conflict check against current occupied timeline
                            if (scheduleConflictValidator.hasConflictWithAny(sessionStart, sessionEnd, occupiedList, breakMinutes)) {
                                continue;
                            }

                            // Valid slot found! Create replacement session
                            StudySession replacement = StudySession.builder()
                                    .sessionDate(candidateDate)
                                    .startTime(sessionStart)
                                    .endTime(sessionEnd)
                                    .plannedMinutes(scheduledMinutes)
                                    .completedMinutes(0)
                                    .status(StudySessionStatus.PLANNED)
                                    .task(task)
                                    .rescheduled(false)
                                    .build();

                            studySessionRepository.save(replacement);

                            // Crucial: Update occupied timeline immediately so subsequent missed sessions don't collide
                            occupiedList.add(new ScheduleConflictValidator.TimeInterval(sessionStart, sessionEnd));

                            // Mark original missed session as rescheduled
                            missedSession.setRescheduled(true);
                            studySessionRepository.save(missedSession);

                            log.info("RESCHEDULED missedSessionId={} -> replacementSessionId={} taskTitle='{}' date={} start={} end={} ({} min)",
                                    missedSession.getId(), replacement.getId(), task.getTitle(),
                                    candidateDate, sessionStart, sessionEnd, scheduledMinutes);

                            rescheduled = true;
                            break;
                        }

                        if (rescheduled) {
                            break;
                        }
                    }

                    if (rescheduled) {
                        break;
                    }
                }

                if (!rescheduled) {
                    log.warn("NO_VALID_SLOT: Could not reschedule missedSessionId={} taskTitle='{}' (needed {}m) without conflicts in candidate horizon",
                            missedSession.getId(), task.getTitle(), neededForThisSession);
                    // Leave rescheduled = false, status = MISSED
                }
            }
        }
    }
}