package com.studyflow.dto.studypreferences;

import lombok.*;

import java.time.LocalTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StudyPreferencesResponse {

    private Long id;

    private Integer maxSessionMinutes;

    private Integer breakMinutes;

    private Boolean allowWeekendStudy;

    private LocalTime preferredStudyStart;

    private LocalTime preferredStudyEnd;
}