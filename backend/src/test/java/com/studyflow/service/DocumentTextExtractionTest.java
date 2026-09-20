package com.studyflow.service;

import com.studyflow.service.ai.DocumentTextExtractionService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;

import static org.junit.jupiter.api.Assertions.*;

class DocumentTextExtractionTest {

    private DocumentTextExtractionService extractionService;

    @BeforeEach
    void setUp() {
        extractionService = new DocumentTextExtractionService();
    }

    @Test
    void extractPlainText_shouldReadAndNormalizeText() {
        String input = "Chapter 1: Intro\r\n\r\n\r\n\r\nTopic 1: Complexity\n";
        ByteArrayInputStream is = new ByteArrayInputStream(input.getBytes(StandardCharsets.UTF_8));

        String result = extractionService.extractText(is, "syllabus.txt", "text/plain");

        assertNotNull(result);
        assertTrue(result.contains("Chapter 1: Intro"));
        assertTrue(result.contains("Topic 1: Complexity"));
        assertFalse(result.contains("\r"));
    }

    @Test
    void cleanAndNormalizeText_shouldChunkExtremelyLargeContent() {
        StringBuilder largeText = new StringBuilder();
        for (int i = 0; i < 1000; i++) {
            largeText.append("Paragraph ").append(i).append(": Essential study content for academic planning.\n");
        }

        assertTrue(largeText.length() > DocumentTextExtractionService.MAX_TEXT_LENGTH_FOR_AI);

        String normalized = extractionService.cleanAndNormalizeText(largeText.toString());

        assertNotNull(normalized);
        assertTrue(normalized.contains("[... content truncated for AI processing ...]"));
        assertTrue(normalized.length() <= DocumentTextExtractionService.MAX_TEXT_LENGTH_FOR_AI + 100);
    }
}
