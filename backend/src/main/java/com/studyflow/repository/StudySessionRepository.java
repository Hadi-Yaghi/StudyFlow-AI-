package com.studyflow.repository;

import com.studyflow.entity.StudySession;
import com.studyflow.entity.Task;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;

public interface StudySessionRepository
        extends JpaRepository<StudySession, Long> {

    List<StudySession> findByTask(Task task);

    List<StudySession> findBySessionDate(LocalDate sessionDate);

    List<StudySession> findBySessionDateOrderByStartTime(
            LocalDate sessionDate
    );
}