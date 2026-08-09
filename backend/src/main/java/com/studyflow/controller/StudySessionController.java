package com.studyflow.controller;

import com.studyflow.dto.studysession.StudySessionResponse;
import com.studyflow.dto.studysession.UpdateStudySessionRequest;
import com.studyflow.service.StudySessionService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/study-sessions")
@RequiredArgsConstructor
public class StudySessionController {

    private final StudySessionService studySessionService;

    @GetMapping
    public List<StudySessionResponse> getSessionsByDate(
            Authentication authentication,
            @RequestParam
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
            LocalDate date
    ) {

        return studySessionService.getSessionsByDate(
                authentication.getName(),
                date
        );
    }

    @GetMapping("/task/{taskId}")
    public List<StudySessionResponse> getTaskSessions(
            @PathVariable Long taskId
    ) {

        return studySessionService.getTaskSessions(taskId);
    }
    @PatchMapping("/{sessionId}/status")
    public StudySessionResponse updateStatus(
            Authentication authentication,
            @PathVariable Long sessionId,
            @RequestBody UpdateStudySessionRequest request
    ) {

        return studySessionService.updateStatus(
                authentication.getName(),
                sessionId,
                request
        );
    }
}