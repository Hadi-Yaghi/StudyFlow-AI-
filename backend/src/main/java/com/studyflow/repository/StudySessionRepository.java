package com.studyflow.repository;

import com.studyflow.entity.StudySession;
import com.studyflow.entity.StudySessionStatus;
import com.studyflow.entity.Task;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

public interface StudySessionRepository
        extends JpaRepository<StudySession, Long> {

    List<StudySession> findByTask(Task task);

    List<StudySession> findBySessionDate(LocalDate sessionDate);

    List<StudySession> findBySessionDateOrderByStartTime(
            LocalDate sessionDate
    );
    void deleteByTaskInAndStatusNotIn(
            List<Task> tasks,
            List<StudySessionStatus> statuses
    );
    List<StudySession> findBySessionDateAndEndTimeBeforeAndStatus(
            LocalDate sessionDate,
            LocalTime endTime,
            StudySessionStatus status
    );
}