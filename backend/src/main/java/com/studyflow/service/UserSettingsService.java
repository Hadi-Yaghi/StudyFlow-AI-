package com.studyflow.service;

import com.studyflow.dto.request.UserSettingsRequest;
import com.studyflow.dto.response.UserSettingsResponse;
import com.studyflow.entity.User;
import com.studyflow.entity.UserSettings;
import com.studyflow.exception.UserNotFoundException;
import com.studyflow.repository.UserRepository;
import com.studyflow.repository.UserSettingsRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class UserSettingsService {

    private final UserSettingsRepository userSettingsRepository;
    private final UserRepository userRepository;

    public UserSettingsResponse getSettings(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(UserNotFoundException::new);

        UserSettings settings = userSettingsRepository.findByUser(user)
                .orElseGet(() -> createDefaultSettings(user));

        return mapToResponse(settings);
    }

    @Transactional
    public UserSettingsResponse updateSettings(String email, UserSettingsRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(UserNotFoundException::new);

        UserSettings settings = userSettingsRepository.findByUser(user)
                .orElseGet(() -> createDefaultSettings(user));

        if (request.getNotificationsEnabled() != null) {
            settings.setNotificationsEnabled(request.getNotificationsEnabled());
        }
        if (request.getStudyReminders() != null) {
            settings.setStudyReminders(request.getStudyReminders());
        }
        if (request.getTaskDeadlines() != null) {
            settings.setTaskDeadlines(request.getTaskDeadlines());
        }
        if (request.getTheme() != null && !request.getTheme().isBlank()) {
            settings.setTheme(request.getTheme().toLowerCase().trim());
        }
        if (request.getLanguage() != null && !request.getLanguage().isBlank()) {
            settings.setLanguage(request.getLanguage().toLowerCase().trim());
        }

        UserSettings saved = userSettingsRepository.save(settings);
        return mapToResponse(saved);
    }

    private UserSettings createDefaultSettings(User user) {
        UserSettings defaultSettings = UserSettings.builder()
                .user(user)
                .notificationsEnabled(true)
                .studyReminders(true)
                .taskDeadlines(true)
                .theme("system")
                .language("en")
                .build();
        return userSettingsRepository.save(defaultSettings);
    }

    private UserSettingsResponse mapToResponse(UserSettings settings) {
        return UserSettingsResponse.builder()
                .notificationsEnabled(settings.isNotificationsEnabled())
                .studyReminders(settings.isStudyReminders())
                .taskDeadlines(settings.isTaskDeadlines())
                .theme(settings.getTheme())
                .language(settings.getLanguage())
                .build();
    }
}
