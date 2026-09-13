package com.studyflow.repository;

import com.studyflow.entity.StudySession;
import com.studyflow.entity.StudySessionStatus;
import com.studyflow.entity.Task;
import com.studyflow.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

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

    @Query("SELECT s FROM StudySession s " +
           "JOIN FETCH s.task t " +
           "JOIN FETCH t.course c " +
           "JOIN FETCH c.semester sem " +
           "WHERE sem.user = :user AND s.sessionDate = :sessionDate " +
           "ORDER BY s.startTime ASC")
    List<StudySession> findByUserAndSessionDateOrderByStartTime(
            @Param("user") User user,
            @Param("sessionDate") LocalDate sessionDate
    );

    @Query("SELECT DISTINCT s.sessionDate FROM StudySession s " +
           "JOIN s.task t " +
           "JOIN t.course c " +
           "JOIN c.semester sem " +
           "WHERE sem.user = :user " +
           "ORDER BY s.sessionDate ASC")
    List<LocalDate> findSessionDatesByUser(@Param("user") User user);

    void deleteByTaskInAndStatusNotIn(
            List<Task> tasks,
            List<StudySessionStatus> statuses
    );
    List<StudySession> findBySessionDateAndEndTimeBeforeAndStatus(
            LocalDate sessionDate,
            LocalTime endTime,
            StudySessionStatus status
    );
    List<StudySession> findByStatusAndRescheduledFalse(
            StudySessionStatus status
    );
}