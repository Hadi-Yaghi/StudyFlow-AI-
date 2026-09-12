package com.studyflow.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.io.IOException;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class GoogleAuthServiceTest {

    private static final String CONFIGURED_CLIENT_ID = "864921972454-bs6t9sn5kqr2fivi0mm6esrgpqe0cvp3.apps.googleusercontent.com";

    @Mock
    private HttpClient httpClient;

    @Mock
    private HttpResponse<String> httpResponse;

    private GoogleAuthService googleAuthService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @BeforeEach
    void setUp() {
        googleAuthService = new GoogleAuthService(CONFIGURED_CLIENT_ID, httpClient, objectMapper);
    }

    @Test
    void testVerifyMockToken_ReturnsSimulatedUserInfo() {
        GoogleAuthService.GoogleUserInfo userInfo = googleAuthService.verifyGoogleToken(
                "mock-google-token-12345",
                "student@studyflow.app",
                "Student Name"
        );

        assertNotNull(userInfo);
        assertEquals("student@studyflow.app", userInfo.email());
        assertEquals("Student Name", userInfo.name());
        assertTrue(userInfo.emailVerified());
        assertEquals("mock-google-id-student@studyflow.app", userInfo.googleId());
    }

    @Test
    void testVerifyToken_NullOrBlank_ThrowsException() {
        assertThrows(IllegalArgumentException.class, () ->
                googleAuthService.verifyGoogleToken(null, "test@test.com", "Name")
        );

        assertThrows(IllegalArgumentException.class, () ->
                googleAuthService.verifyGoogleToken("   ", "test@test.com", "Name")
        );
    }

    @Test
    void testVerifyToken_AudienceMismatch_ThrowsException() throws IOException, InterruptedException {
        String jsonPayload = """
                {
                    "sub": "google-sub-123",
                    "aud": "wrong-client-id.apps.googleusercontent.com",
                    "email": "user@gmail.com",
                    "email_verified": true,
                    "name": "Google User"
                }
                """;

        when(httpResponse.statusCode()).thenReturn(200);
        when(httpResponse.body()).thenReturn(jsonPayload);
        when(httpClient.send(any(HttpRequest.class), any(HttpResponse.BodyHandler.class)))
                .thenReturn(httpResponse);

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () ->
                googleAuthService.verifyGoogleToken("real-sample-id-token", null, null)
        );

        assertTrue(ex.getMessage().contains("audience does not match"));
    }

    @Test
    void testVerifyToken_MatchingAudience_Success() throws IOException, InterruptedException {
        String jsonPayload = """
                {
                    "sub": "google-sub-9999",
                    "aud": "%s",
                    "email": "valid.user@gmail.com",
                    "email_verified": true,
                    "name": "Valid Google User"
                }
                """.formatted(CONFIGURED_CLIENT_ID);

        when(httpResponse.statusCode()).thenReturn(200);
        when(httpResponse.body()).thenReturn(jsonPayload);
        when(httpClient.send(any(HttpRequest.class), any(HttpResponse.BodyHandler.class)))
                .thenReturn(httpResponse);

        GoogleAuthService.GoogleUserInfo userInfo = googleAuthService.verifyGoogleToken(
                "real-sample-id-token",
                null,
                null
        );

        assertNotNull(userInfo);
        assertEquals("google-sub-9999", userInfo.googleId());
        assertEquals("valid.user@gmail.com", userInfo.email());
        assertEquals("Valid Google User", userInfo.name());
        assertTrue(userInfo.emailVerified());
    }

    @Test
    void testVerifyToken_UnverifiedEmail_ThrowsException() throws IOException, InterruptedException {
        String jsonPayload = """
                {
                    "sub": "google-sub-9999",
                    "aud": "%s",
                    "email": "unverified@gmail.com",
                    "email_verified": false,
                    "name": "Unverified User"
                }
                """.formatted(CONFIGURED_CLIENT_ID);

        when(httpResponse.statusCode()).thenReturn(200);
        when(httpResponse.body()).thenReturn(jsonPayload);
        when(httpClient.send(any(HttpRequest.class), any(HttpResponse.BodyHandler.class)))
                .thenReturn(httpResponse);

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () ->
                googleAuthService.verifyGoogleToken("real-sample-id-token", null, null)
        );

        assertTrue(ex.getMessage().contains("not verified"));
    }

    @Test
    void testVerifyToken_GoogleEndpointError_ThrowsException() throws IOException, InterruptedException {
        when(httpResponse.statusCode()).thenReturn(400);
        when(httpResponse.body()).thenReturn("{\"error_description\": \"Invalid Value\"}");
        when(httpClient.send(any(HttpRequest.class), any(HttpResponse.BodyHandler.class)))
                .thenReturn(httpResponse);

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () ->
                googleAuthService.verifyGoogleToken("invalid-id-token", null, null)
        );

        assertTrue(ex.getMessage().contains("Invalid or expired Google token"));
    }
}
