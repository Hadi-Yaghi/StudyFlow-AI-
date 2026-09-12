package com.studyflow;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.studyflow.entity.EmailVerificationToken;
import com.studyflow.entity.PasswordResetToken;
import com.studyflow.entity.User;
import com.studyflow.repository.EmailVerificationTokenRepository;
import com.studyflow.repository.PasswordResetTokenRepository;
import com.studyflow.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@Transactional
class AuthAndAccountIntegrationTest {

    private MockMvc mockMvc;

    @Autowired
    private WebApplicationContext webApplicationContext;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private EmailVerificationTokenRepository emailVerificationTokenRepository;

    @Autowired
    private PasswordResetTokenRepository passwordResetTokenRepository;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders
                .webAppContextSetup(webApplicationContext)
                .apply(springSecurity())
                .build();
    }

    @Test
    void testRegistrationVerificationAndLoginFlow() throws Exception {
        String unique = UUID.randomUUID().toString().substring(0, 8);
        String email = "verify_test_" + unique + "@example.com";
        String password = "Password123!";

        // 1. Register new user
        String registerJson = """
                {
                  "name": "Alex Student",
                  "email": "%s",
                  "password": "%s"
                }
                """.formatted(email, password);

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(registerJson))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.email").value(email))
                .andExpect(jsonPath("$.emailVerified").value(false));

        User user = userRepository.findByEmail(email).orElse(null);
        assertNotNull(user);
        assertFalse(user.isEmailVerified(), "New user should be unverified initially");

        // 2. Attempting to log in before verification should fail
        String loginJson = """
                {
                  "email": "%s",
                  "password": "%s"
                }
                """.formatted(email, password);

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(loginJson))
                .andExpect(status().isBadRequest());

        // 3. Retrieve generated verification token
        EmailVerificationToken token = emailVerificationTokenRepository
                .findTopByUserAndUsedFalseOrderByCreatedAtDesc(user)
                .orElse(null);
        assertNotNull(token, "Verification token should have been created");
        String code = token.getCode();

        // 4. Verify email with code
        String verifyJson = """
                {
                  "email": "%s",
                  "code": "%s"
                }
                """.formatted(email, code);

        MvcResult verifyResult = mockMvc.perform(post("/api/auth/verify-email")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(verifyJson))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isNotEmpty())
                .andExpect(jsonPath("$.emailVerified").value(true))
                .andReturn();

        JsonNode verifyNode = objectMapper.readTree(verifyResult.getResponse().getContentAsString());
        String jwtToken = verifyNode.get("token").asText();

        // 5. Login now succeeds
        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(loginJson))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isNotEmpty());

        // 6. Test Profile Retrieval (/api/users/me)
        mockMvc.perform(get("/api/users/me")
                        .header("Authorization", "Bearer " + jwtToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Alex Student"))
                .andExpect(jsonPath("$.email").value(email))
                .andExpect(jsonPath("$.emailVerified").value(true));

        // 7. Update Profile (/api/users/me)
        String updateProfileJson = """
                {
                  "name": "Alex Johnson",
                  "major": "Computer Science"
                }
                """;

        mockMvc.perform(put("/api/users/me")
                        .header("Authorization", "Bearer " + jwtToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(updateProfileJson))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Alex Johnson"))
                .andExpect(jsonPath("$.major").value("Computer Science"));

        // 8. Change Password (/api/users/me/password)
        String changePwdJson = """
                {
                  "currentPassword": "%s",
                  "newPassword": "NewStrongPassword456!"
                }
                """.formatted(password);

        mockMvc.perform(put("/api/users/me/password")
                        .header("Authorization", "Bearer " + jwtToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(changePwdJson))
                .andExpect(status().isOk());

        // 9. Login with new password succeeds
        String newLoginJson = """
                {
                  "email": "%s",
                  "password": "NewStrongPassword456!"
                }
                """.formatted(email);

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(newLoginJson))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isNotEmpty());

        // 10. User Settings (/api/user-settings)
        String updateSettingsJson = """
                {
                  "notificationsEnabled": true,
                  "studyReminders": true,
                  "taskDeadlines": false,
                  "theme": "dark",
                  "language": "ar"
                }
                """;

        mockMvc.perform(put("/api/user-settings")
                        .header("Authorization", "Bearer " + jwtToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(updateSettingsJson))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.theme").value("dark"))
                .andExpect(jsonPath("$.language").value("ar"))
                .andExpect(jsonPath("$.taskDeadlines").value(false));

        mockMvc.perform(get("/api/user-settings")
                        .header("Authorization", "Bearer " + jwtToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.theme").value("dark"))
                .andExpect(jsonPath("$.language").value("ar"));
    }

    @Test
    void testGoogleSignInFlow() throws Exception {
        String unique = UUID.randomUUID().toString().substring(0, 8);
        String googleEmail = "google_" + unique + "@gmail.com";

        String googleLoginJson = """
                {
                  "idToken": "mock-google-token-%s",
                  "email": "%s",
                  "name": "Google User"
                }
                """.formatted(unique, googleEmail);

        MvcResult result = mockMvc.perform(post("/api/auth/google")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(googleLoginJson))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isNotEmpty())
                .andExpect(jsonPath("$.email").value(googleEmail))
                .andExpect(jsonPath("$.emailVerified").value(true))
                .andReturn();

        JsonNode node = objectMapper.readTree(result.getResponse().getContentAsString());
        String token = node.get("token").asText();

        // Calling Google login AGAIN should reuse/login to existing account
        mockMvc.perform(post("/api/auth/google")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(googleLoginJson))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value(googleEmail));

        // Authenticated profile call works with Google user token
        mockMvc.perform(get("/api/users/me")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value(googleEmail));
    }

    @Test
    void testGoogleSignIn_LinksWithExistingPasswordUser() throws Exception {
        String unique = UUID.randomUUID().toString().substring(0, 8);
        String existingEmail = "passuser_" + unique + "@example.com";

        // Create standard user with password
        User existingUser = userRepository.save(User.builder()
                .name("Password User")
                .email(existingEmail)
                .passwordHash("$2a$10$hashedpasswordsample1234567890abcdef")
                .emailVerified(false)
                .build());

        Long originalUserId = existingUser.getId();

        // Sign in with Google using the same email
        String googleLoginJson = """
                {
                  "idToken": "mock-google-token-%s",
                  "email": "%s",
                  "name": "Google Updated Name"
                }
                """.formatted(unique, existingEmail);

        mockMvc.perform(post("/api/auth/google")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(googleLoginJson))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.userId").value(originalUserId))
                .andExpect(jsonPath("$.email").value(existingEmail))
                .andExpect(jsonPath("$.emailVerified").value(true));

        // Verify the existing user record was updated with googleId and emailVerified
        User updated = userRepository.findById(originalUserId).orElseThrow();
        assertNotNull(updated.getGoogleId());
        assertTrue(updated.isEmailVerified());
    }

    @Test
    void testGoogleSignIn_BlankToken_Returns400BadRequest() throws Exception {
        String invalidJson = """
                {
                  "idToken": ""
                }
                """;

        mockMvc.perform(post("/api/auth/google")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(invalidJson))
                .andExpect(status().isBadRequest());
    }


    @Test
    void testForgotPasswordFlow() throws Exception {
        String unique = UUID.randomUUID().toString().substring(0, 8);
        String email = "reset_" + unique + "@example.com";

        // Create verified user
        User user = User.builder()
                .name("Reset User")
                .email(email)
                .passwordHash("$2a$10$7EqJtq98hPqEX7fNZaFWoO.88Zz1234567890abcdefghijklm")
                .emailVerified(true)
                .build();
        userRepository.save(user);

        // 1. Request forgot password
        String forgotJson = """
                {
                  "email": "%s"
                }
                """.formatted(email);

        mockMvc.perform(post("/api/auth/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(forgotJson))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").isNotEmpty());

        // 2. Retrieve reset token
        PasswordResetToken resetToken = passwordResetTokenRepository
                .findByUserAndCodeAndUsedFalse(user, null)
                .orElse(null);

        // Find token from DB
        var tokens = passwordResetTokenRepository.findAll();
        var myToken = tokens.stream()
                .filter(t -> t.getUser().getId().equals(user.getId()) && !t.isUsed())
                .findFirst()
                .orElse(null);
        assertNotNull(myToken, "Reset token should have been generated");

        // 3. Reset password with token
        String resetJson = """
                {
                  "email": "%s",
                  "code": "%s",
                  "newPassword": "BrandNewPassword999!"
                }
                """.formatted(email, myToken.getCode());

        mockMvc.perform(post("/api/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(resetJson))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").isNotEmpty());

        // 4. Login with brand new password
        String loginJson = """
                {
                  "email": "%s",
                  "password": "BrandNewPassword999!"
                }
                """.formatted(email);

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(loginJson))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isNotEmpty());
    }
}
