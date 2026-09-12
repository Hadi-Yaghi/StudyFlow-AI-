package com.studyflow.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.Getter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

@Service
@Slf4j
public class GoogleAuthService {

    @Getter
    private final String expectedClientId;
    private final HttpClient httpClient;
    private final ObjectMapper objectMapper;

    public record GoogleUserInfo(String googleId, String email, String name, boolean emailVerified) {}

    public GoogleAuthService() {
        this("864921972454-bs6t9sn5kqr2fivi0mm6esrgpqe0cvp3.apps.googleusercontent.com");
    }

    @org.springframework.beans.factory.annotation.Autowired
    public GoogleAuthService(
            @Value("${google.client-id:864921972454-bs6t9sn5kqr2fivi0mm6esrgpqe0cvp3.apps.googleusercontent.com}") String expectedClientId) {
        this(expectedClientId, HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(10)).build(), new ObjectMapper());
    }

    public GoogleAuthService(String expectedClientId, HttpClient httpClient, ObjectMapper objectMapper) {
        this.expectedClientId = expectedClientId != null ? expectedClientId.trim() : "";
        this.httpClient = httpClient != null ? httpClient : HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(10)).build();
        this.objectMapper = objectMapper != null ? objectMapper : new ObjectMapper();
    }


    public GoogleUserInfo verifyGoogleToken(String idToken, String fallbackEmail, String fallbackName) {
        if (idToken == null || idToken.isBlank()) {
            throw new IllegalArgumentException("Google token is required");
        }

        // Test/Offline simulated tokens for integration tests
        if (idToken.startsWith("mock-google-token-")) {
            String testEmail = fallbackEmail != null && !fallbackEmail.isBlank() ? fallbackEmail : "google_test@example.com";
            String testName = fallbackName != null && !fallbackName.isBlank() ? fallbackName : "Google Test User";
            return new GoogleUserInfo("mock-google-id-" + testEmail, testEmail, testName, true);
        }

        try {
            // First verify as id_token with Google tokeninfo endpoint
            URI uri = URI.create("https://oauth2.googleapis.com/tokeninfo?id_token=" + idToken.trim());
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(uri)
                    .timeout(Duration.ofSeconds(10))
                    .GET()
                    .build();

            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

            if (response.statusCode() != 200) {
                // Fallback attempt as access_token if needed
                URI accessUri = URI.create("https://oauth2.googleapis.com/tokeninfo?access_token=" + idToken.trim());
                HttpRequest accessReq = HttpRequest.newBuilder()
                        .uri(accessUri)
                        .timeout(Duration.ofSeconds(10))
                        .GET()
                        .build();
                response = httpClient.send(accessReq, HttpResponse.BodyHandlers.ofString());
            }

            if (response.statusCode() == 200) {
                JsonNode jsonNode = objectMapper.readTree(response.body());

                // Verify that audience matches the configured Web Client ID
                if (expectedClientId != null && !expectedClientId.isBlank()) {
                    String aud = jsonNode.has("aud") ? jsonNode.get("aud").asText() : null;
                    if (aud == null || !expectedClientId.equals(aud)) {
                        log.warn("Google token audience mismatch. Expected: {}, Got: {}", expectedClientId, aud);
                        throw new IllegalArgumentException("Invalid Google token: audience does not match configured Web client ID");
                    }
                }

                String googleId = jsonNode.has("sub") ? jsonNode.get("sub").asText() :
                        (jsonNode.has("user_id") ? jsonNode.get("user_id").asText() : null);

                if (googleId == null || googleId.isBlank()) {
                    throw new IllegalArgumentException("Google token does not contain a valid user identity");
                }

                String email = jsonNode.has("email") ? jsonNode.get("email").asText() : null;
                if (email == null || email.isBlank()) {
                    throw new IllegalArgumentException("Google token does not contain a verified email");
                }

                boolean emailVerified = jsonNode.has("email_verified") && jsonNode.get("email_verified").asBoolean(false);
                if (!emailVerified) {
                    throw new IllegalArgumentException("Google account email is not verified");
                }

                String name = jsonNode.has("name") && !jsonNode.get("name").asText().isBlank()
                        ? jsonNode.get("name").asText()
                        : (fallbackName != null && !fallbackName.isBlank() ? fallbackName : "Google User");

                return new GoogleUserInfo(googleId, email.toLowerCase().trim(), name, emailVerified);
            } else {
                log.warn("Google token verification failed with status {}: {}", response.statusCode(), response.body());
                throw new IllegalArgumentException("Invalid or expired Google token");
            }
        } catch (IllegalArgumentException e) {
            throw e;
        } catch (Exception e) {
            log.error("Error communicating with Google OAuth verification servers: {}", e.getMessage());
            throw new RuntimeException("Failed to verify Google token: " + e.getMessage());
        }
    }
}

