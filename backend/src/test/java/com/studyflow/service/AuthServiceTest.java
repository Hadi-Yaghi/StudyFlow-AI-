package com.studyflow.service;

import com.studyflow.dto.request.LoginRequest;
import com.studyflow.dto.request.RegisterRequest;
import com.studyflow.dto.response.AuthResponse;
import com.studyflow.entity.EmailVerificationToken;
import com.studyflow.entity.User;
import com.studyflow.exception.ResourceAlreadyExistsException;
import com.studyflow.repository.EmailVerificationTokenRepository;
import com.studyflow.repository.PasswordResetTokenRepository;
import com.studyflow.repository.UserRepository;
import com.studyflow.security.JwtService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtService jwtService;

    @Mock
    private EmailVerificationTokenRepository emailVerificationTokenRepository;

    @Mock
    private PasswordResetTokenRepository passwordResetTokenRepository;

    @Mock
    private EmailService emailService;

    @Mock
    private GoogleAuthService googleAuthService;

    private AuthService authService;

    @BeforeEach
    void setUp() {
        authService = new AuthService(
                userRepository,
                passwordEncoder,
                jwtService,
                emailVerificationTokenRepository,
                passwordResetTokenRepository,
                emailService,
                googleAuthService
        );
    }

    @Test
    void testRegister_Success() {
        RegisterRequest request = new RegisterRequest();
        request.setName("John Doe");
        request.setEmail("john.doe@university.edu");
        request.setPassword("Password123!");

        when(userRepository.existsByEmail("john.doe@university.edu")).thenReturn(false);
        when(passwordEncoder.encode("Password123!")).thenReturn("$2a$10$hashedPassword");

        User savedUser = User.builder()
                .id(1L)
                .name("John Doe")
                .email("john.doe@university.edu")
                .passwordHash("$2a$10$hashedPassword")
                .emailVerified(false)
                .build();

        when(userRepository.save(any(User.class))).thenReturn(savedUser);
        when(emailVerificationTokenRepository.save(any(EmailVerificationToken.class))).thenAnswer(i -> i.getArguments()[0]);

        AuthResponse response = authService.register(request);

        assertNotNull(response);
        assertEquals(1L, response.getUserId());
        assertEquals("John Doe", response.getName());
        assertEquals("john.doe@university.edu", response.getEmail());
        assertFalse(response.isEmailVerified());

        verify(userRepository).save(any(User.class));
        verify(emailVerificationTokenRepository).save(any(EmailVerificationToken.class));
        verify(emailService).sendVerificationEmail(eq("john.doe@university.edu"), eq("John Doe"), anyString());
    }

    @Test
    void testRegister_DuplicateEmail_ThrowsResourceAlreadyExistsException() {
        RegisterRequest request = new RegisterRequest();
        request.setName("Jane Doe");
        request.setEmail("duplicate@university.edu");
        request.setPassword("Password123!");

        when(userRepository.existsByEmail("duplicate@university.edu")).thenReturn(true);

        assertThrows(ResourceAlreadyExistsException.class, () -> {
            authService.register(request);
        });

        verify(userRepository, never()).save(any(User.class));
    }

    @Test
    void testLogin_Success() {
        LoginRequest request = new LoginRequest();
        request.setEmail("john.doe@university.edu");
        request.setPassword("Password123!");

        User existingUser = User.builder()
                .id(1L)
                .name("John Doe")
                .email("john.doe@university.edu")
                .passwordHash("$2a$10$hashedPassword")
                .emailVerified(true)
                .build();

        when(userRepository.findByEmail("john.doe@university.edu")).thenReturn(Optional.of(existingUser));
        when(passwordEncoder.matches("Password123!", "$2a$10$hashedPassword")).thenReturn(true);
        when(jwtService.generateToken("john.doe@university.edu")).thenReturn("mock-jwt-token-12345");

        AuthResponse response = authService.login(request);

        assertNotNull(response);
        assertEquals("mock-jwt-token-12345", response.getToken());
        assertEquals(1L, response.getUserId());
        assertEquals("John Doe", response.getName());
    }

    @Test
    void testLogin_Unverified_ThrowsException() {
        LoginRequest request = new LoginRequest();
        request.setEmail("john.doe@university.edu");
        request.setPassword("Password123!");

        User existingUser = User.builder()
                .id(1L)
                .name("John Doe")
                .email("john.doe@university.edu")
                .passwordHash("$2a$10$hashedPassword")
                .emailVerified(false)
                .build();

        when(userRepository.findByEmail("john.doe@university.edu")).thenReturn(Optional.of(existingUser));
        when(passwordEncoder.matches("Password123!", "$2a$10$hashedPassword")).thenReturn(true);

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> {
            authService.login(request);
        });
        assertTrue(ex.getMessage().contains("Account not verified"));
    }

    @Test
    void testLogin_WrongPassword_ThrowsException() {
        LoginRequest request = new LoginRequest();
        request.setEmail("john.doe@university.edu");
        request.setPassword("WrongPassword!");

        User existingUser = User.builder()
                .id(1L)
                .name("John Doe")
                .email("john.doe@university.edu")
                .passwordHash("$2a$10$hashedPassword")
                .emailVerified(true)
                .build();

        when(userRepository.findByEmail("john.doe@university.edu")).thenReturn(Optional.of(existingUser));
        when(passwordEncoder.matches("WrongPassword!", "$2a$10$hashedPassword")).thenReturn(false);

        assertThrows(IllegalArgumentException.class, () -> {
            authService.login(request);
        });
    }
}
