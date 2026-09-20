package com.studyflow.service.ai;

import com.studyflow.dto.ai.AiTopicRecommendation;
import com.studyflow.entity.User;

import java.util.List;

public interface AiClient {

    record AiAnalysisResult(
            String summary,
            List<AiTopicRecommendation> topics,
            int promptTokens,
            int completionTokens
    ) {}

    AiAnalysisResult analyzeCourseContent(
            User user,
            String courseName,
            String courseCode,
            String extractedMaterialsText,
            List<String> existingTaskTitles
    );
}
