package com.studyflow.service.impl;

import com.studyflow.dto.studysession.StudySessionResponse;
import com.studyflow.dto.studysession.UpdateStudySessionRequest;
import com.studyflow.entity.*;
import com.studyflow.exception.UserNotFoundException;
import com.studyflow.repository.CourseRepository;
import com.studyflow.repository.StudySessionRepository;
import com.studyflow.repository.TaskRepository;
import com.studyflow.repository.UserRepository;
import com.studyflow.service.StudySessionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class StudySessionServiceImpl implements StudySessionService {

    private final StudySessionRepository studySessionRepository;
    private final UserRepository userRepository;
    private final TaskRepository taskRepository;
    private final CourseRepository courseRepository;

    @Override
    @Transactional(readOnly = true)
    public List<StudySessionResponse> getSessionsByDate(
            String email,
            LocalDate date
    ) {
        log.debug("Fetching sessions for user: {} on date: {}", email, date);

        User user = userRepository.findByEmail(email)
                .orElseThrow(UserNotFoundException::new);

        List<StudySessionResponse> responses = studySessionRepository.findByUserAndSessionDateOrderByStartTime(user, date)
                .stream()
                .map(this::mapToResponse)
                .toList();

        log.debug("Found {} sessions for user: {} on date: {}", responses.size(), email, date);
        return responses;
    }

    @Override
    @Transactional(readOnly = true)
    public List<LocalDate> getSessionDates(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(UserNotFoundException::new);

        return studySessionRepository.findSessionDatesByUser(user);
    }

    @Override
    @Transactional(readOnly = true)
    public List<StudySessionResponse> getTaskSessions(Long taskId) {

        Task task = taskRepository.findById(taskId)
                .orElseThrow(UserNotFoundException::new);

        return studySessionRepository.findByTask(task)
                .stream()
                .map(this::mapToResponse)
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public List<StudySessionResponse> getCourseSessions(String email, Long courseId) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(UserNotFoundException::new);

        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new RuntimeException("Course not found"));

        if (!course.getSemester().getUser().getId().equals(user.getId())) {
            throw new IllegalArgumentException("You do not own this course");
        }

        return studySessionRepository.findByUserAndCourseIdOrderByDateAndStartTime(user, courseId)
                .stream()
                .map(this::mapToResponse)
                .toList();
    }

    private StudySessionResponse mapToResponse(
            StudySession session
    ) {

        return StudySessionResponse.builder()
                .id(session.getId())
                .sessionDate(session.getSessionDate())
                .startTime(session.getStartTime())
                .endTime(session.getEndTime())
                .plannedMinutes(session.getPlannedMinutes())
                .completedMinutes(session.getCompletedMinutes())
                .status(session.getStatus())
                .taskId(session.getTask() != null ? session.getTask().getId() : null)
                .taskTitle(session.getTask() != null ? session.getTask().getTitle() : "")
                .build();
    }
    @Override
    public StudySessionResponse updateStatus(
            String email,
            Long sessionId,
            UpdateStudySessionRequest request
    ) {

        User user = userRepository.findByEmail(email)
                .orElseThrow(UserNotFoundException::new);

        StudySession session = studySessionRepository.findById(sessionId)
                .orElseThrow(() ->
                        new RuntimeException("Study session not found")
                );

        // Make sure the session belongs to the authenticated user
        if (!session.getTask()
                .getCourse()
                .getSemester()
                .getUser()
                .getId()
                .equals(user.getId())) {

            throw new RuntimeException("Unauthorized study session");
        }
        StudySessionStatus currentStatus = session.getStatus();
        StudySessionStatus newStatus = request.getStatus();

        if (currentStatus == StudySessionStatus.COMPLETED
                && newStatus != StudySessionStatus.COMPLETED) {

            throw new IllegalArgumentException(
                    "Completed sessions cannot change status"
            );
        }

        if (currentStatus == StudySessionStatus.PLANNED
                && newStatus == StudySessionStatus.COMPLETED) {

            throw new IllegalArgumentException(
                    "Session must be started before completing"
            );
        }
        Integer completedMinutes = request.getCompletedMinutes();

        // Validate completed minutes
        if (completedMinutes != null && completedMinutes < 0) {
            throw new IllegalArgumentException(
                    "Completed minutes cannot be negative"
            );
        }

        if (completedMinutes != null
                && completedMinutes > session.getPlannedMinutes()) {

            throw new IllegalArgumentException(
                    "Completed minutes cannot exceed planned minutes"
            );
        }

        // If completed, default to the full planned duration
        if (request.getStatus() == StudySessionStatus.COMPLETED
                && completedMinutes == null) {

            completedMinutes = session.getPlannedMinutes();
        }

        session.setStatus(request.getStatus());

        if (completedMinutes != null) {
            session.setCompletedMinutes(completedMinutes);
        }

        StudySession savedSession =
                studySessionRepository.save(session);

        if (request.getStatus() == StudySessionStatus.COMPLETED && session.getTask() != null) {
            Task task = session.getTask();
            List<StudySession> allSessions = studySessionRepository.findByTask(task);
            int totalCompletedMinutes = allSessions.stream()
                    .mapToInt(s -> (s.getId() != null && s.getId().equals(savedSession.getId()))
                            ? (savedSession.getCompletedMinutes() != null ? savedSession.getCompletedMinutes() : 0)
                            : (s.getCompletedMinutes() != null ? s.getCompletedMinutes() : 0))
                    .sum();
            int newCompletedHours = totalCompletedMinutes / 60;
            task.setCompletedHours(newCompletedHours);
            if (task.getEstimatedHours() != null && newCompletedHours >= task.getEstimatedHours()) {
                task.setStatus(TaskStatus.COMPLETED);
            }
            taskRepository.save(task);
        }

        return mapToResponse(savedSession);
    }
}