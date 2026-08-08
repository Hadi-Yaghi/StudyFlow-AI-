package com.studyflow.controller;

import com.studyflow.dto.studypreferences.StudyPreferencesRequest;
import com.studyflow.dto.studypreferences.StudyPreferencesResponse;
import com.studyflow.service.StudyPreferencesService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/study-preferences")
@RequiredArgsConstructor
public class StudyPreferencesController {

    private final StudyPreferencesService studyPreferencesService;

    @PostMapping
    public StudyPreferencesResponse createPreferences(
            Authentication authentication,
            @Valid @RequestBody StudyPreferencesRequest request
    ) {

        return studyPreferencesService.createPreferences(
                authentication.getName(),
                request
        );
    }

    @GetMapping
    public StudyPreferencesResponse getPreferences(
            Authentication authentication
    ) {

        return studyPreferencesService.getPreferences(
                authentication.getName()
        );
    }
}