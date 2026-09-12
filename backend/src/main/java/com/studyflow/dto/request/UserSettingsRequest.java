package com.studyflow.dto.request;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UserSettingsRequest {

    private Boolean notificationsEnabled;
    private Boolean studyReminders;
    private Boolean taskDeadlines;
    private String theme;
    private String language;
}
