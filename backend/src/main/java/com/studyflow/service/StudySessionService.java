package com.studyflow.service;

import com.studyflow.dto.studysession.StudySessionResponse;

import java.time.LocalDate;
import java.util.List;

public interface StudySessionService {

    List<StudySessionResponse> getSessionsByDate(
            String email,
            LocalDate date
    );

    List<StudySessionResponse> getTaskSessions(
            Long taskId
    );
}