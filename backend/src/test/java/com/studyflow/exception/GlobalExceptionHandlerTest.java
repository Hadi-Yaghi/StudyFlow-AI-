package com.studyflow.exception;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.exc.InvalidFormatException;
import com.studyflow.dto.request.TaskCreateRequest;
import com.studyflow.entity.TaskType;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.mock.http.MockHttpInputMessage;
import org.springframework.mock.web.MockHttpServletRequest;

import static org.junit.jupiter.api.Assertions.*;

class GlobalExceptionHandlerTest {

    private final GlobalExceptionHandler handler = new GlobalExceptionHandler();
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    void shouldReturnClean400WithAllowedValues_whenTaskTypeIsInvalid() {
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setRequestURI("/api/tasks");

        InvalidFormatException ife = InvalidFormatException.from(
                null,
                "Cannot deserialize value",
                "INVALID_EXAM",
                TaskType.class
        );
        HttpMessageNotReadableException ex = new HttpMessageNotReadableException("Invalid JSON", ife, new MockHttpInputMessage(new byte[0]));

        ResponseEntity<ApiError> response = handler.handleHttpMessageNotReadable(ex, request);

        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals("Invalid task type", response.getBody().getMessage());
        assertNotNull(response.getBody().getAllowedValues());
        assertTrue(response.getBody().getAllowedValues().contains("EXAM"));
        assertTrue(response.getBody().getAllowedValues().contains("ASSIGNMENT"));
        assertEquals(TaskType.values().length, response.getBody().getAllowedValues().size());
        assertFalse(response.getBody().getMessage().contains("com.studyflow"));
    }

    @Test
    void shouldReturnCleanAiErrorMessage_whenAiProcessingFails() {
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setRequestURI("/api/courses/1/ai-study-plan");

        AiProcessingException ex = new AiProcessingException("models/gemini-1.5-flash is not found for API version v1beta");
        ResponseEntity<ApiError> response = handler.handleAiProcessing(ex, request);

        assertEquals(HttpStatus.INTERNAL_SERVER_ERROR, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals("AI study planning is temporarily unavailable. Please try again.", response.getBody().getMessage());
        assertFalse(response.getBody().getMessage().contains("gemini"));
    }

    @Test
    void shouldReturnCleanAiErrorMessage_whenAiProviderUnavailable() {
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setRequestURI("/api/courses/1/ai-study-plan");

        AiProviderUnavailableException ex = new AiProviderUnavailableException("Key missing");
        ResponseEntity<ApiError> response = handler.handleAiProviderUnavailable(ex, request);

        assertEquals(HttpStatus.SERVICE_UNAVAILABLE, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals("AI study planning is temporarily unavailable. Please try again.", response.getBody().getMessage());
    }

    @Test
    void shouldSuccessfullyDeserializeAllSupportedTaskTypes() throws Exception {
        for (TaskType type : TaskType.values()) {
            TaskType deserialized = objectMapper.readValue("\"" + type.name() + "\"", TaskType.class);
            assertNotNull(deserialized);
            assertEquals(type, deserialized);
        }
    }
}
