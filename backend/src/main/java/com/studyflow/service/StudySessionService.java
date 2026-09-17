package com.studyflow.service;

import com.studyflow.dto.studysession.StudySessionResponse;
import com.studyflow.dto.studysession.UpdateStudySessionRequest;

import java.time.LocalDate;
import java.util.List;

public interface StudySessionService {

    List<StudySessionResponse> getSessionsByDate(
            String email,
            LocalDate date
    );

    List<LocalDate> getSessionDates(
            String email
    );

    List<StudySessionResponse> getTaskSessions(
            Long taskId
    );

    List<StudySessionResponse> getCourseSessions(
            String email,
            Long courseId
    );

    StudySessionResponse updateStatus(
            String email,
            Long sessionId,
            UpdateStudySessionRequest request
    );
}