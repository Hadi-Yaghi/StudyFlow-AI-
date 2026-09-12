package com.studyflow.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserSettingsResponse {

    private boolean notificationsEnabled;
    private boolean studyReminders;
    private boolean taskDeadlines;
    private String theme;
    private String language;
}
