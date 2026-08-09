package com.studyflow.scheduler;

import com.studyflow.entity.*;
import com.studyflow.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

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

    @Override
    @Transactional
    public SchedulerResult generateSchedule(String email) {

        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new RuntimeException("User not found"));

        StudyPreferences preferences =
                studyPreferencesRepository.findByUser(user)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Study preferences not found"
                                ));

        List<Availability> availabilities =
                availabilityRepository.findByUser(user);

        // Get the user's semesters
        List<Semester> semesters =
                semesterRepository.findByUser(user);

        // Get all courses belonging to those semesters
        List<Course> courses =
                courseRepository.findBySemesterIn(semesters);

        // Get all tasks belonging to those courses
        List<Task> tasks =
                taskRepository.findByCourseIn(courses);
        // Remove previously generated sessions for these tasks
        studySessionRepository.deleteByTaskInAndStatusNotIn(
                tasks,
                List.of(
                        StudySessionStatus.COMPLETED,
                        StudySessionStatus.MISSED
                )
        );
        List<StudySession> generatedSessions =
                new ArrayList<>();

        LocalDate today = LocalDate.now();

        for (int i = 0; i < 7; i++) {

            LocalDate date = today.plusDays(i);

            DayOfWeek dayOfWeek = date.getDayOfWeek();
            System.out.println(
                    "Checking: " + date + " (" + dayOfWeek + ")"
            );
            // Skip weekends if the user doesn't allow weekend study
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
                                            .equals(dayOfWeek.name()))
                            .toList();

            for (Availability availability : dailyAvailability) {

                List<TimeAllocator.TimeBlock> blocks =
                        timeAllocator.allocate(
                                availability.getStartTime(),
                                availability.getEndTime(),
                                preferences
                        );

                List<StudySession> sessions =
                        sessionGenerator.generate(
                                new ArrayList<>(tasks),
                                blocks,
                                date
                        );

                generatedSessions.addAll(sessions);
            }
        }

        studySessionRepository.saveAll(generatedSessions);

        int scheduledMinutes =
                generatedSessions.stream()
                        .mapToInt(StudySession::getPlannedMinutes)
                        .sum();

        int totalRemainingMinutes =
                tasks.stream()
                        .mapToInt(task -> {

                            int estimatedHours =
                                    task.getEstimatedHours() != null
                                            ? task.getEstimatedHours()
                                            : 0;

                            int completedHours =
                                    task.getCompletedHours() != null
                                            ? task.getCompletedHours()
                                            : 0;

                            return Math.max(
                                    (estimatedHours - completedHours) * 60,
                                    0
                            );
                        })
                        .sum();

        int unscheduledMinutes =
                Math.max(
                        totalRemainingMinutes - scheduledMinutes,
                        0
                );

        return SchedulerResult.builder()
                .generatedSessions(generatedSessions.size())
                .scheduledMinutes(scheduledMinutes)
                .unscheduledMinutes(unscheduledMinutes)
                .build();
    }

}