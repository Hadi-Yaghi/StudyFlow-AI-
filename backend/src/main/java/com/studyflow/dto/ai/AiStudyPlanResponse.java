package com.studyflow.dto.ai;

import lombok.*;

import java.util.ArrayList;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AiStudyPlanResponse {

    private Long courseId;

    private String courseName;

    private String summary;

    @Builder.Default
    private List<AiTopicRecommendation> topics = new ArrayList<>();

    private int generatedSessionsCount;

    private int scheduledMinutes;

    @Builder.Default
    private List<String> sessionDates = new ArrayList<>();

    private boolean successful;

    private String message;
}
