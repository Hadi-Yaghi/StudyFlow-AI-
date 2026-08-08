package com.studyflow.dto.studypreferences;

import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.time.LocalTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StudyPreferencesRequest {

    @NotNull(message = "Maximum session minutes is required")
    private Integer maxSessionMinutes;

    @NotNull(message = "Break minutes is required")
    private Integer breakMinutes;

    @NotNull(message = "Allow weekend study is required")
    private Boolean allowWeekendStudy;

    @NotNull(message = "Preferred study start is required")
    private LocalTime preferredStudyStart;

    @NotNull(message = "Preferred study end is required")
    private LocalTime preferredStudyEnd;
}