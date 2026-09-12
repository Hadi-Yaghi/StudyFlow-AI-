package com.studyflow;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.studyflow.dto.request.LoginRequest;
import com.studyflow.dto.request.RegisterRequest;
import com.studyflow.entity.User;
import com.studyflow.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@Transactional
class AuthIntegrationTest {

    private MockMvc mockMvc;

    @Autowired
    private WebApplicationContext webApplicationContext;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders
                .webAppContextSetup(webApplicationContext)
                .apply(springSecurity())
                .build();
    }

    @Test
    void testEndToEndRegistrationAndLoginFlow() throws Exception {
        String uniqueSuffix = UUID.randomUUID().toString().substring(0, 8);
        String testEmail = "testuser_" + uniqueSuffix + "@university.edu";
        String rawPassword = "TestPassword123!";

        // 1. Register new user
        RegisterRequest registerReq = new RegisterRequest();
        registerReq.setName("Test Student");
        registerReq.setEmail(testEmail);
        registerReq.setPassword(rawPassword);

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(registerReq)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.emailVerified").value(false))
                .andExpect(jsonPath("$.name").value("Test Student"))
                .andExpect(jsonPath("$.email").value(testEmail));

        // 2. Verify User in Database and BCrypt Hashing
        User savedUser = userRepository.findByEmail(testEmail).orElse(null);
        assertNotNull(savedUser, "User should be saved in database");
        assertEquals("Test Student", savedUser.getName());
        assertTrue(passwordEncoder.matches(rawPassword, savedUser.getPasswordHash()), "Password hash must match raw password via BCrypt");
        assertNotEquals(rawPassword, savedUser.getPasswordHash(), "Password must not be stored in plain text");

        // Mark verified so login step can proceed
        savedUser.setEmailVerified(true);
        userRepository.save(savedUser);

        // 3. Duplicate Registration should return 409 Conflict
        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(registerReq)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.status").value(409));

        // 4. Login with newly created credentials
        LoginRequest loginReq = new LoginRequest();
        loginReq.setEmail(testEmail);
        loginReq.setPassword(rawPassword);

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isNotEmpty())
                .andExpect(jsonPath("$.email").value(testEmail));
    }
}
