package com.studyflow.service;

import com.studyflow.dto.studypreferences.StudyPreferencesRequest;
import com.studyflow.dto.studypreferences.StudyPreferencesResponse;

public interface StudyPreferencesService {

    StudyPreferencesResponse createPreferences(
            String email,
            StudyPreferencesRequest request
    );

    StudyPreferencesResponse getPreferences(
            String email
    );
}