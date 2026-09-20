package com.studyflow.scheduler;

import com.studyflow.entity.*;
import com.studyflow.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.*;

@Slf4j
@Service
@RequiredArgsConstructor
public class SchedulerServiceImpl implements SchedulerService {

    private final UserRepository userRepository;
    private final SemesterRepository semesterRepository;
    private final CourseRepository courseRepository;
    private final TaskRepository taskRepository;
    private final AvailabilityRepository availabilityRepository;
    private final StudyPreferencesRepository studyPreferencesRepository;
    private final StudySessionRepository studySessionRepository;

    private final TimeAllocator timeAllocator;
    private final SessionGenerator sessionGenerator;
    private final ScheduleConflictValidator scheduleConflictValidator;

    private final com.studyflow.service.SubscriptionService subscriptionService;
    private final com.studyflow.service.ScheduleUsageService scheduleUsageService;

    @Override
    @Transactional
    public SchedulerResult generateSchedule(String email) {
        log.info("==================================================");
        log.info("STARTING SCHEDULE GENERATION FOR: {}", email);
        log.info("==================================================");

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found: " + email));

        log.info("Authenticated user ID: {}", user.getId());

        boolean isPro = subscriptionService.isPro(user);
        log.info("User {} Pro status: {}", email, isPro);

        if (!isPro) {
            boolean canGenerate = scheduleUsageService.canUserGenerate(user, false);
            if (!canGenerate) {
                log.warn("User {} has used all free schedule generations for current period.", email);
                throw new com.studyflow.exception.ScheduleLimitReachedException(
                        "You've used your free schedule generations."
                );
            }
            log.info("Free quota check passed for user {}. Remaining: {}", email, scheduleUsageService.getRemainingFreeGenerations(user));
        } else {
            log.info("Pro user {} bypassing free schedule generation quota.", email);
        }

        LocalDate today = LocalDate.now();
        log.info("Current scheduling date (today): {}", today);

        // 1. Semester Checks
        List<Semester> allSemesters = semesterRepository.findByUser(user);
        log.info("Total semesters found: {}", allSemesters.size());

        List<Semester> activeSemesters = allSemesters.stream()
                .filter(s -> {
                    boolean activeFlag = s.isActive();
                    boolean started = s.getStartDate() == null || !today.isBefore(s.getStartDate());
                    boolean notEnded = s.getEndDate() == null || !today.isAfter(s.getEndDate());
                    return activeFlag && started && notEnded;
                })
                .toList();

        if (activeSemesters.isEmpty()) {
            List<Semester> flaggedActive = allSemesters.stream().filter(Semester::isActive).toList();
            if (!flaggedActive.isEmpty()) {
                activeSemesters = flaggedActive;
                log.info("Using active semester(s) with lenient date matching: count={}", activeSemesters.size());
            } else if (!allSemesters.isEmpty()) {
                activeSemesters = allSemesters;
                log.info("No active semester flag set; falling back to all user semesters: count={}", activeSemesters.size());
            } else {
                log.warn("No semesters found for user ID: {}. Schedule generation aborted.", user.getId());
                return buildFailureResult("NO_ACTIVE_SEMESTER", "No active semester found. Please create or activate a semester.", user, isPro);
            }
        }

        for (Semester s : activeSemesters) {
            log.info("Active semester: ID={}, name='{}', startDate={}, endDate={}, active={}",
                    s.getId(), s.getName(), s.getStartDate(), s.getEndDate(), s.isActive());
        }

        // 2. Course Checks
        List<Course> courses = courseRepository.findBySemesterIn(activeSemesters);
        log.info("Courses found: {}", courses.size());
        for (Course c : courses) {
            log.info("Course: ID={}, name='{}', code='{}', semesterID={}",
                    c.getId(), c.getName(), c.getCode(), c.getSemester() != null ? c.getSemester().getId() : null);
        }

        if (courses.isEmpty()) {
            log.warn("No courses found for user ID: {}. Schedule generation aborted.", user.getId());
            return buildFailureResult("NO_ACTIVE_TASKS", "No courses found in your active semester. Please add courses first.", user, isPro);
        }

        // 3. Task Checks & Eligibility
        List<Task> allTasks = taskRepository.findByCourseIn(courses);
        log.info("Tasks found: {}", allTasks.size());

        List<Task> eligibleTasks = new ArrayList<>();
        int completedCount = 0;
        int zeroRemainingCount = 0;
        int pastDueCount = 0;

        for (Task task : allTasks) {
            int estimatedHours = task.getEstimatedHours() != null ? task.getEstimatedHours() : 0;
            int completedHours = task.getCompletedHours() != null ? task.getCompletedHours() : 0;
            int remainingMinutes = Math.max((estimatedHours - completedHours) * 60, 0);

            if (task.getStatus() == TaskStatus.COMPLETED) {
                log.warn("Task [id={}, title='{}'] REJECTED: status == COMPLETED", task.getId(), task.getTitle());
                completedCount++;
                continue;
            }
            if (task.getDueDate() == null) {
                log.warn("Task [id={}, title='{}'] REJECTED: dueDate is null", task.getId(), task.getTitle());
                continue;
            }
            if (task.getDueDate().isBefore(today)) {
                log.warn("Task [id={}, title='{}'] REJECTED: dueDate = {} is before currentDate = {}",
                        task.getId(), task.getTitle(), task.getDueDate(), today);
                pastDueCount++;
                continue;
            }
            if (estimatedHours <= 0) {
                log.warn("Task [id={}, title='{}'] REJECTED: estimatedHours = 0", task.getId(), task.getTitle());
                continue;
            }
            if (remainingMinutes <= 0) {
                log.warn("Task [id={}, title='{}'] REJECTED: remainingMinutes = 0 (estimatedHours={}, completedHours={})",
                        task.getId(), task.getTitle(), estimatedHours, completedHours);
                zeroRemainingCount++;
                continue;
            }

            log.info("Task [id={}, title='{}', status={}, dueDate={}, estimatedHours={}, completedHours={}, remainingMinutes={}] ELIGIBLE",
                    task.getId(), task.getTitle(), task.getStatus(), task.getDueDate(), estimatedHours, completedHours, remainingMinutes);
            eligibleTasks.add(task);
        }

        log.info("Eligible tasks: {}", eligibleTasks.size());

        if (eligibleTasks.isEmpty()) {
            if (allTasks.isEmpty()) {
                return buildFailureResult("NO_ACTIVE_TASKS", "No tasks found for your courses. Please add tasks to generate a schedule.", user, isPro);
            }
            if (completedCount == allTasks.size() || (completedCount + zeroRemainingCount) == allTasks.size()) {
                return buildFailureResult("NO_REMAINING_TASK_TIME", "All tasks are already completed or have no remaining time.", user, isPro);
            }
            if (pastDueCount > 0) {
                return buildFailureResult("TASKS_OUTSIDE_DATE_RANGE", "All existing tasks have due dates that have already passed.", user, isPro);
            }
            return buildFailureResult("NO_ACTIVE_TASKS", "No eligible tasks found. Please verify your task due dates and estimated hours.", user, isPro);
        }

        // 4. Study Preferences Check
        StudyPreferences preferences = studyPreferencesRepository.findByUser(user)
                .orElseThrow(() -> new RuntimeException("Study preferences not found for user: " + email));

        int breakMinutes = preferences.getBreakMinutes() != null ? Math.max(preferences.getBreakMinutes(), 0) : 15;

        log.info("Study preferences: maxSessionMinutes={}, breakMinutes={}, allowWeekendStudy={}, preferredStart={}, preferredEnd={}",
                preferences.getMaxSessionMinutes(), breakMinutes,
                preferences.getAllowWeekendStudy(), preferences.getPreferredStudyStart(), preferences.getPreferredStudyEnd());

        // 5. Availability Retrieval
        List<Availability> availabilities = availabilityRepository.findByUser(user);
        log.info("Availability entries: {}", availabilities.size());
        for (Availability a : availabilities) {
            log.info("Availability: day={}, enabled={}, startTime={}, endTime={}",
                    a.getDay(), a.isEnabled(), a.getStartTime(), a.getEndTime());
        }

        if (availabilities.isEmpty()) {
            log.warn("Zero availability entries configured for user ID: {}. Returning NO_AVAILABILITY.", user.getId());
            return buildFailureResult("NO_AVAILABILITY", "No study availability configured. Please set your weekly study availability in Profile > Availability.", user, isPro);
        }

        boolean anyEnabled = availabilities.stream().anyMatch(Availability::isEnabled);
        if (!anyEnabled) {
            log.warn("All availability entries are disabled for user ID: {}. Returning NO_AVAILABLE_TIME.", user.getId());
            return buildFailureResult("NO_AVAILABLE_TIME", "All study availability days are disabled. Please enable study days in Profile > Availability.", user, isPro);
        }

        // Remove previously generated PLANNED sessions for these tasks before re-generating
        studySessionRepository.deleteByTaskInAndStatusNotIn(
                eligibleTasks,
                List.of(
                        StudySessionStatus.COMPLETED,
                        StudySessionStatus.MISSED
                )
        );
        studySessionRepository.flush();

        // 6. Scheduling Loop across 7 candidate days
        List<StudySession> generatedSessions = new ArrayList<>();
        Map<Long, Integer> remainingMinutesMap = new HashMap<>();
        for (Task t : eligibleTasks) {
            int est = t.getEstimatedHours() != null ? t.getEstimatedHours() : 0;
            int comp = t.getCompletedHours() != null ? t.getCompletedHours() : 0;
            remainingMinutesMap.put(t.getId(), Math.max((est - comp) * 60, 0));
        }

        int totalAvailableMinutesAcrossHorizon = 0;

        // Maintain occupied intervals per candidate date to avoid conflicts across tasks/slots
        Map<LocalDate, List<ScheduleConflictValidator.TimeInterval>> dailyOccupiedMap = new HashMap<>();

        for (int i = 0; i < 7; i++) {
            LocalDate date = today.plusDays(i);
            DayOfWeek dayOfWeek = date.getDayOfWeek();

            // Check weekend preference
            if (!preferences.getAllowWeekendStudy()
                    && (dayOfWeek == DayOfWeek.SATURDAY || dayOfWeek == DayOfWeek.SUNDAY)) {
                log.info("Date {}: Skipping weekend day ({}) because allowWeekendStudy is false", date, dayOfWeek);
                continue;
            }

            // Find matching availability for this day of week
            List<Availability> dailyAvailability = availabilities.stream()
                    .filter(availability ->
                            availability.isEnabled()
                                    && availability.getDay().name().equals(dayOfWeek.name()))
                    .toList();

            if (dailyAvailability.isEmpty()) {
                log.info("Date {} ({}): No enabled availability record found", date, dayOfWeek);
                continue;
            }

            // Load existing active sessions from database for this user on this date
            List<StudySession> existingDbSessions = studySessionRepository
                    .findByUserAndSessionDateAndStatusInOrderByStartTime(
                            user,
                            date,
                            ScheduleConflictValidator.TIME_OCCUPYING_STATUSES
                    );

            List<ScheduleConflictValidator.TimeInterval> occupiedList = dailyOccupiedMap.computeIfAbsent(date, d -> new ArrayList<>());
            for (StudySession existing : existingDbSessions) {
                occupiedList.add(new ScheduleConflictValidator.TimeInterval(existing.getStartTime(), existing.getEndTime()));
            }

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
                        log.warn("Date {} ({}): Availability slot {}-{} has NO INTERSECTION with preferred window {}-{} (0 minutes)",
                                date, dayOfWeek, slotStart, slotEnd, prefStart, prefEnd);
                        continue;
                    }

                    slotStart = effectiveStart;
                    slotEnd = effectiveEnd;
                }

                // Allocate conflict-free time blocks that carve around currently occupied sessions
                List<TimeAllocator.TimeBlock> blocks =
                        timeAllocator.allocate(slotStart, slotEnd, preferences, date, occupiedList);

                int slotMinutes = blocks.stream().mapToInt(TimeAllocator.TimeBlock::getMinutes).sum();
                totalAvailableMinutesAcrossHorizon += slotMinutes;

                log.info("Date {} ({}): Allocated {} time blocks ({} minutes) within window {}-{}",
                        date, dayOfWeek, blocks.size(), slotMinutes, slotStart, slotEnd);

                List<StudySession> candidateSessions =
                        sessionGenerator.generate(
                                new ArrayList<>(eligibleTasks),
                                blocks,
                                date,
                                remainingMinutesMap,
                                breakMinutes
                        );

                for (StudySession candidate : candidateSessions) {
                    // Strict pre-save validation against occupied timeline
                    boolean conflict = scheduleConflictValidator.hasConflictWithAny(
                            candidate.getStartTime(),
                            candidate.getEndTime(),
                            occupiedList,
                            breakMinutes
                    );

                    if (conflict) {
                        log.warn("REJECTED candidate taskId={} date={} candidate={}-{} reason=OVERLAPS_OCCUPIED_TIME",
                                candidate.getTask().getId(), date, candidate.getStartTime(), candidate.getEndTime());
                        continue;
                    }

                    // Register candidate in occupied timeline immediately
                    occupiedList.add(new ScheduleConflictValidator.TimeInterval(candidate.getStartTime(), candidate.getEndTime()));
                    generatedSessions.add(candidate);

                    log.info("ACCEPTED taskId={} taskTitle='{}' date={} start={} end={} ({} min)",
                            candidate.getTask().getId(), candidate.getTask().getTitle(),
                            candidate.getSessionDate(), candidate.getStartTime(), candidate.getEndTime(),
                            candidate.getPlannedMinutes());
                }
            }
        }

        // Save generated sessions
        if (!generatedSessions.isEmpty()) {
            studySessionRepository.saveAll(generatedSessions);
            studySessionRepository.flush();
        }

        int scheduledMinutes = generatedSessions.stream()
                .mapToInt(StudySession::getPlannedMinutes)
                .sum();

        int totalInitialRemaining = eligibleTasks.stream()
                .mapToInt(task -> {
                    int est = task.getEstimatedHours() != null ? task.getEstimatedHours() : 0;
                    int comp = task.getCompletedHours() != null ? task.getCompletedHours() : 0;
                    return Math.max((est - comp) * 60, 0);
                })
                .sum();

        int unscheduledMinutes = Math.max(totalInitialRemaining - scheduledMinutes, 0);

        LocalDate firstSessionDate = generatedSessions.stream()
                .map(StudySession::getSessionDate)
                .min(LocalDate::compareTo)
                .orElse(null);

        List<LocalDate> sessionDates = generatedSessions.stream()
                .map(StudySession::getSessionDate)
                .distinct()
                .sorted()
                .toList();

        log.info("Generated sessions: {}", generatedSessions.size());
        log.info("Total scheduled minutes: {}, unscheduled minutes: {}", scheduledMinutes, unscheduledMinutes);
        log.info("First session date: {}, session dates: {}", firstSessionDate, sessionDates);
        log.info("==================================================");

        if (generatedSessions.isEmpty()) {
            if (totalAvailableMinutesAcrossHorizon == 0) {
                return buildFailureResult("NO_AVAILABLE_TIME", "No available study time found within your preferred hours and availability window.", user, isPro);
            }
            return buildFailureResult("TASKS_OUTSIDE_DATE_RANGE", "No sessions could be scheduled. Your tasks may be due before the next available study slot.", user, isPro);
        }

        // Record usage ONLY if actual generation succeeds
        scheduleUsageService.recordGenerationUsage(
                user,
                ScheduleGenerationType.STANDARD,
                true,
                generatedSessions.size(),
                "Successfully scheduled " + generatedSessions.size() + " study sessions"
        );

        int remaining = isPro ? -1 : scheduleUsageService.getRemainingFreeGenerations(user);
        int used = (int) scheduleUsageService.getUsedFreeGenerationsInCurrentPeriod(user);

        return SchedulerResult.builder()
                .generatedSessions(generatedSessions.size())
                .scheduledMinutes(scheduledMinutes)
                .unscheduledMinutes(unscheduledMinutes)
                .firstSessionDate(firstSessionDate)
                .sessionDates(sessionDates)
                .status("SUCCESS")
                .message("Successfully scheduled " + generatedSessions.size() + " study sessions.")
                .failureReason(null)
                .remainingFreeGenerations(remaining)
                .generatedCount(used)
                .pro(isPro)
                .build();
    }

    private SchedulerResult buildFailureResult(String status, String message, User user, boolean isPro) {
        int remaining = (user != null && !isPro) ? scheduleUsageService.getRemainingFreeGenerations(user) : -1;
        int used = (user != null) ? (int) scheduleUsageService.getUsedFreeGenerationsInCurrentPeriod(user) : 0;

        return SchedulerResult.builder()
                .generatedSessions(0)
                .scheduledMinutes(0)
                .unscheduledMinutes(0)
                .firstSessionDate(null)
                .sessionDates(List.of())
                .status(status)
                .message(message)
                .failureReason(status)
                .remainingFreeGenerations(remaining)
                .generatedCount(used)
                .pro(isPro)
                .build();
    }
}