package com.studyflow.service.ai.impl;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.studyflow.dto.ai.AiTopicRecommendation;
import com.studyflow.entity.AiUsageLog;
import com.studyflow.entity.User;
import com.studyflow.exception.AiProcessingException;
import com.studyflow.exception.AiProviderUnavailableException;
import com.studyflow.repository.AiUsageLogRepository;
import com.studyflow.service.ai.AiClient;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Slf4j
@Component
@RequiredArgsConstructor
public class GeminiAiClientImpl implements AiClient {

    private final AiUsageLogRepository aiUsageLogRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Value("${studyflow.ai.gemini.api-key:}")
    private String geminiApiKey;

    @Value("${studyflow.ai.gemini.model:${gemini.model:gemini-3.8-flash}}")
    private String geminiModel;

    @PostConstruct
    public void logModelConfiguration() {
        log.info("Gemini model configured: {}", geminiModel);
    }

    private static final String GEMINI_API_BASE = "https://generativelanguage.googleapis.com/v1beta/models";

    @Override
    public AiAnalysisResult analyzeCourseContent(
            User user,
            String courseName,
            String courseCode,
            String extractedMaterialsText,
            List<String> existingTaskTitles
    ) {
        if (geminiApiKey == null || geminiApiKey.trim().isEmpty() || geminiApiKey.startsWith("AIzaSy_YOUR_")) {
            log.warn("Gemini AI API key is not configured.");
            throw new AiProviderUnavailableException(
                    "Google Gemini AI API key is not configured. Please configure GEMINI_API_KEY in the backend environment."
            );
        }

        String prompt = buildPrompt(courseName, courseCode, extractedMaterialsText, existingTaskTitles);

        Instant start = Instant.now();
        int promptTokens = 0;
        int completionTokens = 0;
        boolean success = false;
        String errorMessage = null;

        String effectiveModel = (geminiModel != null && !geminiModel.isBlank()) ? geminiModel : "gemini-3.8-flash";

        try {
            RestClient client = RestClient.builder()
                    .baseUrl(GEMINI_API_BASE)
                    .defaultHeader("Content-Type", MediaType.APPLICATION_JSON_VALUE)
                    .build();

            Map<String, Object> requestBody = Map.of(
                    "contents", List.of(
                            Map.of(
                                    "role", "user",
                                    "parts", List.of(
                                            Map.of("text", prompt)
                                    )
                                )
                    ),
                    "generationConfig", Map.of(
                            "temperature", 0.2,
                            "responseMimeType", "application/json"
                    )
            );

            String responseJson = null;

            try {
                responseJson = client.post()
                        .uri("/{model}:generateContent?key={key}", effectiveModel, geminiApiKey.trim())
                        .contentType(MediaType.APPLICATION_JSON)
                        .body(requestBody)
                        .retrieve()
                        .body(String.class);
            } catch (org.springframework.web.client.HttpStatusCodeException ex) {
                if (ex.getStatusCode().value() == 503 && !"gemini-3.5-flash".equals(effectiveModel)) {
                    log.warn("Gemini model {} returned 503 (high demand spike). Retrying with gemini-3.5-flash...", effectiveModel);
                    effectiveModel = "gemini-3.5-flash";
                    responseJson = client.post()
                            .uri("/{model}:generateContent?key={key}", effectiveModel, geminiApiKey.trim())
                            .contentType(MediaType.APPLICATION_JSON)
                            .body(requestBody)
                            .retrieve()
                            .body(String.class);
                } else {
                    throw ex;
                }
            }

            if (responseJson == null || responseJson.isBlank()) {
                throw new AiProcessingException("Received empty response from Gemini AI provider.");
            }

            JsonNode root = objectMapper.readTree(responseJson);

            // Extract token usage metadata if available
            JsonNode usageMetadata = root.path("usageMetadata");
            if (!usageMetadata.isMissingNode()) {
                promptTokens = usageMetadata.path("promptTokenCount").asInt(0);
                completionTokens = usageMetadata.path("candidatesTokenCount").asInt(0);
            }

            JsonNode candidates = root.path("candidates");
            if (!candidates.isArray() || candidates.isEmpty()) {
                throw new AiProcessingException("No AI candidates returned by Gemini.");
            }

            String contentText = candidates.get(0).path("content").path("parts").get(0).path("text").asText();
            if (contentText == null || contentText.isBlank()) {
                throw new AiProcessingException("No content text returned by Gemini candidate.");
            }

            // Parse structured JSON response
            JsonNode parsedJson = objectMapper.readTree(contentText);
            String summary = parsedJson.path("summary").asText("AI study plan generated based on course materials.");
            JsonNode topicsArray = parsedJson.path("topics");

            List<AiTopicRecommendation> topics = new ArrayList<>();
            if (topicsArray.isArray()) {
                LocalDate today = LocalDate.now();
                for (JsonNode topicNode : topicsArray) {
                    String title = topicNode.path("title").asText("Study Topic");
                    int estimatedMinutes = topicNode.path("estimatedMinutes").asInt(60);
                    String priority = topicNode.path("priority").asText("MEDIUM").toUpperCase();
                    int daysAhead = topicNode.path("suggestedDaysFromNow").asInt(3);
                    LocalDate deadline = today.plusDays(Math.max(daysAhead, 1));

                    List<String> keyConcepts = new ArrayList<>();
                    JsonNode conceptsNode = topicNode.path("keyConcepts");
                    if (conceptsNode.isArray()) {
                        conceptsNode.forEach(c -> keyConcepts.add(c.asText()));
                    }

                    topics.add(AiTopicRecommendation.builder()
                            .title(title)
                            .estimatedMinutes(Math.max(estimatedMinutes, 30))
                            .priority(priority)
                            .suggestedDeadline(deadline)
                            .keyConcepts(keyConcepts)
                            .build());
                }
            }

            success = true;
            log.info("Gemini AI successfully extracted {} study topics for course '{}'", topics.size(), courseName);

            return new AiAnalysisResult(summary, topics, promptTokens, completionTokens);

        } catch (AiProviderUnavailableException e) {
            throw e;
        } catch (Exception e) {
            log.error("Gemini AI processing failed for user {}: {}", user.getEmail(), e.getMessage(), e);
            errorMessage = e.getMessage();
            throw new AiProcessingException("AI study planning analysis failed: " + e.getMessage(), e);
        } finally {
            // Log server-side AI usage for analytics and cost auditing
            try {
                AiUsageLog logEntry = AiUsageLog.builder()
                        .user(user)
                        .timestamp(start)
                        .requestType("COURSE_STUDY_PLAN")
                        .provider("GEMINI")
                        .model(effectiveModel)
                        .promptTokens(promptTokens)
                        .completionTokens(completionTokens)
                        .totalTokens(promptTokens + completionTokens)
                        .successful(success)
                        .errorMessage(errorMessage)
                        .build();
                aiUsageLogRepository.save(logEntry);
            } catch (Exception logEx) {
                log.warn("Failed to persist AI usage log: {}", logEx.getMessage());
            }
        }
    }

    private String buildPrompt(
            String courseName,
            String courseCode,
            String extractedMaterialsText,
            List<String> existingTaskTitles
    ) {
        return """
                You are an expert academic study strategist for StudyFlow.
                Analyze the following course material content and extract structured study planning topics.
                
                Course: %s (%s)
                Existing Planned Tasks: %s
                
                Course Material Content:
                %s
                
                INSTRUCTIONS:
                1. Identify the essential chapters, modules, topics, and exam/assignment preparations.
                2. Do NOT duplicate existing tasks if they already cover a topic.
                3. For each recommended study topic, estimate a realistic study duration in minutes (between 30 and 180 minutes).
                4. Set priority to 'HIGH', 'MEDIUM', or 'LOW'.
                5. Set 'suggestedDaysFromNow' (between 1 and 14) indicating when this topic should ideally be completed.
                6. Extract 2-4 key concepts for each topic.
                7. Return a JSON object with this exact schema:
                {
                  "summary": "Brief 1-2 sentence overview of the study strategy",
                  "topics": [
                    {
                      "title": "Topic title (e.g. Chapter 3: Dynamic Programming)",
                      "estimatedMinutes": 90,
                      "priority": "HIGH",
                      "suggestedDaysFromNow": 3,
                      "keyConcepts": ["Memoization", "Tabulation", "Optimal Substructure"]
                    }
                  ]
                }
                """.formatted(
                courseName,
                courseCode != null ? courseCode : "",
                existingTaskTitles != null ? String.join(", ", existingTaskTitles) : "None",
                extractedMaterialsText
        );
    }
}
