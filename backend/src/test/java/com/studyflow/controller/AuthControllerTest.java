package com.studyflow.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.studyflow.dto.request.LoginRequest;
import com.studyflow.dto.request.RegisterRequest;
import com.studyflow.dto.response.AuthResponse;
import com.studyflow.exception.GlobalExceptionHandler;
import com.studyflow.exception.ResourceAlreadyExistsException;
import com.studyflow.service.AuthService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@ExtendWith(MockitoExtension.class)
class AuthControllerTest {

    private MockMvc mockMvc;

    @Mock
    private AuthService authService;

    @InjectMocks
    private AuthController authController;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(authController)
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
    }

    @Test
    void testRegister_Success_Returns201() throws Exception {
        RegisterRequest request = new RegisterRequest();
        request.setName("Alice Walker");
        request.setEmail("alice@university.edu");
        request.setPassword("SecurePass123!");

        AuthResponse authResponse = new AuthResponse("jwt-token-xyz", 42L, "Alice Walker", "alice@university.edu");
        when(authService.register(any(RegisterRequest.class))).thenReturn(authResponse);

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.token").value("jwt-token-xyz"))
                .andExpect(jsonPath("$.userId").value(42))
                .andExpect(jsonPath("$.name").value("Alice Walker"))
                .andExpect(jsonPath("$.email").value("alice@university.edu"));
    }

    @Test
    void testRegister_DuplicateEmail_Returns409() throws Exception {
        RegisterRequest request = new RegisterRequest();
        request.setName("Alice Walker");
        request.setEmail("alice@university.edu");
        request.setPassword("SecurePass123!");

        when(authService.register(any(RegisterRequest.class)))
                .thenThrow(new ResourceAlreadyExistsException("Email already exists: alice@university.edu"));

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.status").value(409))
                .andExpect(jsonPath("$.message").value("Email already exists: alice@university.edu"));
    }

    @Test
    void testRegister_InvalidBody_Returns400() throws Exception {
        RegisterRequest request = new RegisterRequest();
        request.setName(""); // Blank name
        request.setEmail("not-an-email"); // Invalid email
        request.setPassword("123"); // Short password

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400));
    }

    @Test
    void testLogin_Success_Returns200() throws Exception {
        LoginRequest request = new LoginRequest();
        request.setEmail("alice@university.edu");
        request.setPassword("SecurePass123!");

        AuthResponse authResponse = new AuthResponse("jwt-token-xyz", 42L, "Alice Walker", "alice@university.edu");
        when(authService.login(any(LoginRequest.class))).thenReturn(authResponse);

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").value("jwt-token-xyz"))
                .andExpect(jsonPath("$.userId").value(42));
    }
}
