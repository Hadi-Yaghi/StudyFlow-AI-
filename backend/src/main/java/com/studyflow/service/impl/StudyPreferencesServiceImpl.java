package com.studyflow.service.impl;

import com.studyflow.dto.studypreferences.StudyPreferencesRequest;
import com.studyflow.dto.studypreferences.StudyPreferencesResponse;
import com.studyflow.entity.StudyPreferences;
import com.studyflow.entity.User;
import com.studyflow.exception.ResourceAlreadyExistsException;
import com.studyflow.exception.UserNotFoundException;
import com.studyflow.repository.StudyPreferencesRepository;
import com.studyflow.repository.UserRepository;
import com.studyflow.service.StudyPreferencesService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class StudyPreferencesServiceImpl implements StudyPreferencesService {

    private final StudyPreferencesRepository studyPreferencesRepository;
    private final UserRepository userRepository;

    @Override
    public StudyPreferencesResponse createPreferences(
            String email,
            StudyPreferencesRequest request
    ) {

        User user = userRepository.findByEmail(email)
                .orElseThrow(UserNotFoundException::new);

        studyPreferencesRepository.findByUser(user)
                .ifPresent(p -> {
                    throw new ResourceAlreadyExistsException(
                            "Study preferences already exist"
                    );
                });

        StudyPreferences preferences = StudyPreferences.builder()
                .maxSessionMinutes(request.getMaxSessionMinutes())
                .breakMinutes(request.getBreakMinutes())
                .allowWeekendStudy(request.getAllowWeekendStudy())
                .preferredStudyStart(request.getPreferredStudyStart())
                .preferredStudyEnd(request.getPreferredStudyEnd())
                .user(user)
                .build();

        StudyPreferences saved = studyPreferencesRepository.save(preferences);

        return StudyPreferencesResponse.builder()
                .id(saved.getId())
                .maxSessionMinutes(saved.getMaxSessionMinutes())
                .breakMinutes(saved.getBreakMinutes())
                .allowWeekendStudy(saved.getAllowWeekendStudy())
                .preferredStudyStart(saved.getPreferredStudyStart())
                .preferredStudyEnd(saved.getPreferredStudyEnd())
                .build();
    }

    @Override
    public StudyPreferencesResponse getPreferences(String email) {

        User user = userRepository.findByEmail(email)
                .orElseThrow(UserNotFoundException::new);

        StudyPreferences preferences = studyPreferencesRepository
                .findByUser(user)
                .orElseThrow(() ->
                        new UserNotFoundException("Study preferences not found"));

        return StudyPreferencesResponse.builder()
                .id(preferences.getId())
                .maxSessionMinutes(preferences.getMaxSessionMinutes())
                .breakMinutes(preferences.getBreakMinutes())
                .allowWeekendStudy(preferences.getAllowWeekendStudy())
                .preferredStudyStart(preferences.getPreferredStudyStart())
                .preferredStudyEnd(preferences.getPreferredStudyEnd())
                .build();
    }
}