package com.studyflow.dto.ai;

import lombok.*;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AiTopicRecommendation {

    private String title;

    private int estimatedMinutes;

    private String priority; // HIGH, MEDIUM, LOW

    private LocalDate suggestedDeadline;

    private Long sourceMaterialId;

    @Builder.Default
    private List<String> keyConcepts = new ArrayList<>();
}
