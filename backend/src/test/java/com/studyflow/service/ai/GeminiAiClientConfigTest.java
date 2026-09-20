package com.studyflow.service.ai;

import com.studyflow.repository.AiUsageLogRepository;
import com.studyflow.service.ai.impl.GeminiAiClientImpl;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.jupiter.api.Assertions.assertEquals;

@ExtendWith(MockitoExtension.class)
class GeminiAiClientConfigTest {

    @Mock
    private AiUsageLogRepository aiUsageLogRepository;

    @Test
    void testGeminiModelConfiguration() {
        GeminiAiClientImpl client = new GeminiAiClientImpl(aiUsageLogRepository);
        ReflectionTestUtils.setField(client, "geminiModel", "gemini-3.8-flash");
        ReflectionTestUtils.setField(client, "geminiApiKey", "test-key");

        client.logModelConfiguration();

        Object configuredModel = ReflectionTestUtils.getField(client, "geminiModel");
        assertEquals("gemini-3.8-flash", configuredModel);
    }
}
