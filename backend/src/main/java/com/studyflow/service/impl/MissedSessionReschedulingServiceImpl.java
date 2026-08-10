package com.studyflow.service.impl;

import com.studyflow.entity.Availability;
import com.studyflow.entity.StudyPreferences;
import com.studyflow.entity.StudySession;
import com.studyflow.entity.StudySessionStatus;
import com.studyflow.entity.User;
import com.studyflow.repository.AvailabilityRepository;
import com.studyflow.repository.StudyPreferencesRepository;
import com.studyflow.repository.StudySessionRepository;
import com.studyflow.scheduler.TimeAllocator;
import com.studyflow.service.MissedSessionReschedulingService;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Comparator;
@Service
@RequiredArgsConstructor
public class MissedSessionReschedulingServiceImpl
        implements MissedSessionReschedulingService {

    private final StudySessionRepository studySessionRepository;
    private final AvailabilityRepository availabilityRepository;
    private final StudyPreferencesRepository studyPreferencesRepository;
    private final TimeAllocator timeAllocator;

    @Override
    @Transactional
    @Scheduled(fixedRate = 60000)
    public void rescheduleMissedSessions() {

        List<StudySession> missedSessions =
                studySessionRepository.findByStatusAndRescheduledFalse(
                        StudySessionStatus.MISSED
                );

        for (StudySession missedSession : missedSessions) {

            int remainingMinutes =
                    missedSession.getPlannedMinutes()
                            - missedSession.getCompletedMinutes();

            if (remainingMinutes <= 0) {
                missedSession.setRescheduled(true);
                studySessionRepository.save(missedSession);
                continue;
            }

            User user = missedSession.getTask()
                    .getCourse()
                    .getSemester()
                    .getUser();

            StudyPreferences preferences =
                    studyPreferencesRepository.findByUser(user)
                            .orElseThrow(() ->
                                    new RuntimeException(
                                            "Study preferences not found"
                                    ));

            List<AvailableBlock> availableBlocks =
                    getFutureAvailableBlocks(
                            user,
                            preferences,
                            missedSession.getSessionDate()
                    );

            availableBlocks =
                    removeConflictingBlocks(
                            availableBlocks,
                            user
                    );

            availableBlocks = availableBlocks.stream()
                    .sorted(
                            Comparator
                                    .comparing(AvailableBlock::date)
                                    .thenComparing(
                                            AvailableBlock::startTime
                                    )
                    )
                    .toList();

            // Check whether there is enough future capacity
            int totalAvailableMinutes =
                    availableBlocks.stream()
                            .mapToInt(AvailableBlock::getMinutes)
                            .sum();

            if (totalAvailableMinutes < remainingMinutes) {

                System.out.println(
                        "Not enough availability to reschedule session "
                                + missedSession.getId()
                                + ". Required: "
                                + remainingMinutes
                                + " minutes, available: "
                                + totalAvailableMinutes
                );

                continue;
            }

            List<StudySession> replacementSessions =
                    new ArrayList<>();

            int remainingToSchedule = remainingMinutes;

            for (AvailableBlock block : availableBlocks) {

                if (remainingToSchedule <= 0) {
                    break;
                }

                int scheduledMinutes =
                        Math.min(
                                remainingToSchedule,
                                block.getMinutes()
                        );

                StudySession replacement =
                        StudySession.builder()
                                .sessionDate(block.date())
                                .startTime(block.startTime())
                                .endTime(
                                        block.startTime()
                                                .plusMinutes(
                                                        scheduledMinutes
                                                )
                                )
                                .plannedMinutes(scheduledMinutes)
                                .completedMinutes(0)
                                .status(StudySessionStatus.PLANNED)
                                .rescheduled(false)
                                .task(missedSession.getTask())
                                .build();

                replacementSessions.add(replacement);

                remainingToSchedule -= scheduledMinutes;
            }

            studySessionRepository.saveAll(
                    replacementSessions
            );

            missedSession.setRescheduled(true);

            studySessionRepository.save(
                    missedSession
            );

            System.out.println(
                    "Rescheduled missed session "
                            + missedSession.getId()
                            + " into "
                            + replacementSessions.size()
                            + " new session(s)."
            );
        }
    }

    /**
     * Represents a free study block on a specific date.
     */
    private record AvailableBlock(
            LocalDate date,
            LocalTime startTime,
            LocalTime endTime
    ) {

        public int getMinutes() {
            return (int) java.time.Duration.between(
                    startTime,
                    endTime
            ).toMinutes();
        }
    }

    /**
     * Gets the user's available study blocks
     * for the next 7 days.
     */
    private List<AvailableBlock> getFutureAvailableBlocks(
            User user,
            StudyPreferences preferences,
            LocalDate startDate
    ) {

        List<Availability> availabilities =
                availabilityRepository.findByUser(user);

        List<AvailableBlock> blocks =
                new ArrayList<>();

        for (int i = 1; i <= 7; i++) {

            LocalDate date =
                    startDate.plusDays(i);

            DayOfWeek dayOfWeek =
                    date.getDayOfWeek();

            // Skip weekends if the user doesn't allow
            // weekend studying.
            if (!preferences.getAllowWeekendStudy()
                    && (dayOfWeek == DayOfWeek.SATURDAY
                    || dayOfWeek == DayOfWeek.SUNDAY)) {

                continue;
            }

            List<Availability> dailyAvailability =
                    availabilities.stream()
                            .filter(availability ->
                                    availability.isEnabled()
                                            && availability.getDay()
                                            .name()
                                            .equals(dayOfWeek.name())
                            )
                            .toList();

            for (Availability availability :
                    dailyAvailability) {

                List<TimeAllocator.TimeBlock> timeBlocks =
                        timeAllocator.allocate(
                                availability.getStartTime(),
                                availability.getEndTime(),
                                preferences
                        );

                for (TimeAllocator.TimeBlock block :
                        timeBlocks) {

                    blocks.add(
                            new AvailableBlock(
                                    date,
                                    block.startTime(),
                                    block.endTime()
                            )
                    );
                }
            }
        }

        return blocks;
    }

    /**
     * Removes availability blocks that overlap
     * with existing study sessions belonging to the user.
     */
    private List<AvailableBlock> removeConflictingBlocks(
            List<AvailableBlock> blocks,
            User user
    ) {

        List<StudySession> existingSessions =
                studySessionRepository.findAll()
                        .stream()
                        .filter(session ->
                                session.getTask()
                                        .getCourse()
                                        .getSemester()
                                        .getUser()
                                        .getId()
                                        .equals(user.getId())
                        )
                        .toList();

        return blocks.stream()
                .filter(block ->
                        existingSessions.stream()
                                .noneMatch(session ->
                                        session.getSessionDate()
                                                .equals(block.date())
                                                && timesOverlap(
                                                block.startTime(),
                                                block.endTime(),
                                                session.getStartTime(),
                                                session.getEndTime()
                                        )
                                )
                )
                .toList();
    }

    /**
     * Checks whether two time ranges overlap.
     */
    private boolean timesOverlap(
            LocalTime start1,
            LocalTime end1,
            LocalTime start2,
            LocalTime end2
    ) {

        return start1.isBefore(end2)
                && start2.isBefore(end1);
    }
}