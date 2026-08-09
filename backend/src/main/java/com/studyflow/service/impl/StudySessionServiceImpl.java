package com.studyflow.service.impl;

import com.studyflow.dto.studysession.StudySessionResponse;
import com.studyflow.dto.studysession.UpdateStudySessionRequest;
import com.studyflow.entity.StudySession;
import com.studyflow.entity.StudySessionStatus;
import com.studyflow.entity.Task;
import com.studyflow.entity.User;
import com.studyflow.exception.UserNotFoundException;
import com.studyflow.repository.StudySessionRepository;
import com.studyflow.repository.TaskRepository;
import com.studyflow.repository.UserRepository;
import com.studyflow.service.StudySessionService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;

@Service
@RequiredArgsConstructor
public class StudySessionServiceImpl implements StudySessionService {

    private final StudySessionRepository studySessionRepository;
    private final UserRepository userRepository;
    private final TaskRepository taskRepository;

    @Override
    public List<StudySessionResponse> getSessionsByDate(
            String email,
            LocalDate date
    ) {

        User user = userRepository.findByEmail(email)
                .orElseThrow(UserNotFoundException::new);

        return studySessionRepository.findBySessionDateOrderByStartTime(date)
                .stream()
                .filter(session ->
                        session.getTask()
                                .getCourse()
                                .getSemester()
                                .getUser()
                                .getId()
                                .equals(user.getId()))
                .map(this::mapToResponse)
                .toList();
    }

    @Override
    public List<StudySessionResponse> getTaskSessions(Long taskId) {

        Task task = taskRepository.findById(taskId)
                .orElseThrow(UserNotFoundException::new);

        return studySessionRepository.findByTask(task)
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
                .taskId(session.getTask().getId())
                .taskTitle(session.getTask().getTitle())
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

        return mapToResponse(savedSession);
    }
}