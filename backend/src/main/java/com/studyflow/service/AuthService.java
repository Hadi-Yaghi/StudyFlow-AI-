package com.studyflow.service;

import com.studyflow.dto.request.*;
import com.studyflow.dto.response.AuthResponse;
import com.studyflow.entity.EmailVerificationToken;
import com.studyflow.entity.PasswordResetToken;
import com.studyflow.entity.User;
import com.studyflow.exception.ResourceAlreadyExistsException;
import com.studyflow.repository.EmailVerificationTokenRepository;
import com.studyflow.repository.PasswordResetTokenRepository;
import com.studyflow.repository.UserRepository;
import com.studyflow.security.JwtService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final EmailVerificationTokenRepository emailVerificationTokenRepository;
    private final PasswordResetTokenRepository passwordResetTokenRepository;
    private final EmailService emailService;
    private final GoogleAuthService googleAuthService;

    private final SecureRandom secureRandom = new SecureRandom();

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        String email = request.getEmail().trim().toLowerCase();
        if (userRepository.existsByEmail(email)) {
            throw new ResourceAlreadyExistsException("Email already exists: " + email);
        }

        User user = User.builder()
                .name(request.getName().trim())
                .email(email)
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .emailVerified(false)
                .build();

        User savedUser = userRepository.save(user);

        // Generate 6-digit verification code
        String code = generateNumericCode();
        EmailVerificationToken token = EmailVerificationToken.builder()
                .user(savedUser)
                .code(code)
                .expiryDate(LocalDateTime.now().plusMinutes(15))
                .used(false)
                .createdAt(LocalDateTime.now())
                .build();
        emailVerificationTokenRepository.save(token);

        emailService.sendVerificationEmail(email, savedUser.getName(), code);

        // Return response indicating registration succeeded but verification required
        return AuthResponse.builder()
                .token("")
                .userId(savedUser.getId())
                .name(savedUser.getName())
                .email(savedUser.getEmail())
                .major(savedUser.getMajor())
                .emailVerified(false)
                .build();
    }

    @Transactional
    public AuthResponse verifyEmail(VerifyEmailRequest request) {
        String email = request.getEmail().trim().toLowerCase();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("User not found with email: " + email));

        if (user.isEmailVerified()) {
            String token = jwtService.generateToken(email);
            return AuthResponse.builder()
                    .token(token)
                    .userId(user.getId())
                    .name(user.getName())
                    .email(user.getEmail())
                    .major(user.getMajor())
                    .emailVerified(true)
                    .build();
        }

        EmailVerificationToken token = emailVerificationTokenRepository
                .findByUserAndCodeAndUsedFalse(user, request.getCode().trim())
                .orElseThrow(() -> new IllegalArgumentException("Invalid verification code. Please check and try again."));

        if (token.isExpired()) {
            throw new IllegalArgumentException("Verification code has expired. Please request a new one.");
        }

        token.setUsed(true);
        emailVerificationTokenRepository.save(token);

        user.setEmailVerified(true);
        userRepository.save(user);

        String jwt = jwtService.generateToken(email);
        return AuthResponse.builder()
                .token(jwt)
                .userId(user.getId())
                .name(user.getName())
                .email(user.getEmail())
                .major(user.getMajor())
                .emailVerified(true)
                .build();
    }

    @Transactional
    public void resendVerification(ResendVerificationRequest request) {
        String email = request.getEmail().trim().toLowerCase();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("User not found with email: " + email));

        if (user.isEmailVerified()) {
            throw new IllegalArgumentException("Your account is already verified. You can log in directly.");
        }

        // Check cooldown (60 seconds)
        Optional<EmailVerificationToken> latest = emailVerificationTokenRepository
                .findTopByUserAndUsedFalseOrderByCreatedAtDesc(user);
        if (latest.isPresent() && latest.get().getCreatedAt().isAfter(LocalDateTime.now().minusSeconds(60))) {
            throw new IllegalArgumentException("Please wait 60 seconds before requesting another code.");
        }

        // Invalidate old tokens
        latest.ifPresent(t -> {
            t.setUsed(true);
            emailVerificationTokenRepository.save(t);
        });

        String code = generateNumericCode();
        EmailVerificationToken token = EmailVerificationToken.builder()
                .user(user)
                .code(code)
                .expiryDate(LocalDateTime.now().plusMinutes(15))
                .used(false)
                .createdAt(LocalDateTime.now())
                .build();
        emailVerificationTokenRepository.save(token);

        emailService.sendVerificationEmail(email, user.getName(), code);
    }

    public AuthResponse login(LoginRequest request) {
        String email = request.getEmail().trim().toLowerCase();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("Invalid email or password"));

        if (user.getPasswordHash() == null || !passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new IllegalArgumentException("Invalid email or password");
        }

        if (!user.isEmailVerified()) {
            throw new IllegalArgumentException("Account not verified. Please verify your email before logging in.");
        }

        String token = jwtService.generateToken(email);
        return AuthResponse.builder()
                .token(token)
                .userId(user.getId())
                .name(user.getName())
                .email(user.getEmail())
                .major(user.getMajor())
                .emailVerified(user.isEmailVerified())
                .build();
    }

    @Transactional
    public AuthResponse loginWithGoogle(GoogleLoginRequest request) {
        GoogleAuthService.GoogleUserInfo googleUser = googleAuthService.verifyGoogleToken(
                request.getIdToken(),
                request.getEmail(),
                request.getName()
        );

        String email = googleUser.email().trim().toLowerCase();
        Optional<User> existingUserOpt = userRepository.findByEmail(email);

        User user;
        if (existingUserOpt.isPresent()) {
            user = existingUserOpt.get();
            if (user.getGoogleId() == null) {
                user.setGoogleId(googleUser.googleId());
            }
            // Google verified accounts are automatically email-verified
            user.setEmailVerified(true);
            user = userRepository.save(user);
        } else {
            // Create a new user with Google OAuth identity
            user = User.builder()
                    .name(googleUser.name() != null && !googleUser.name().isBlank() ? googleUser.name() : "Google Student")
                    .email(email)
                    .googleId(googleUser.googleId())
                    .emailVerified(true)
                    .passwordHash(passwordEncoder.encode(UUID.randomUUID().toString())) // Random strong hash so NOT NULL constraint is satisfied
                    .build();
            user = userRepository.save(user);
        }

        String token = jwtService.generateToken(email);
        return AuthResponse.builder()
                .token(token)
                .userId(user.getId())
                .name(user.getName())
                .email(user.getEmail())
                .major(user.getMajor())
                .emailVerified(user.isEmailVerified())
                .build();
    }

    @Transactional
    public void forgotPassword(ForgotPasswordRequest request) {
        String email = request.getEmail().trim().toLowerCase();
        Optional<User> userOpt = userRepository.findByEmail(email);

        if (userOpt.isPresent()) {
            User user = userOpt.get();
            String code = generateNumericCode();

            PasswordResetToken resetToken = PasswordResetToken.builder()
                    .user(user)
                    .code(code)
                    .expiryDate(LocalDateTime.now().plusMinutes(15))
                    .used(false)
                    .createdAt(LocalDateTime.now())
                    .build();
            passwordResetTokenRepository.save(resetToken);

            emailService.sendPasswordResetEmail(email, user.getName(), code);
        }
    }

    @Transactional
    public void resetPassword(ResetPasswordRequest request) {
        String email = request.getEmail().trim().toLowerCase();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("Invalid password reset request."));

        PasswordResetToken token = passwordResetTokenRepository
                .findByUserAndCodeAndUsedFalse(user, request.getCode().trim())
                .orElseThrow(() -> new IllegalArgumentException("Invalid or expired password reset code."));

        if (token.isExpired()) {
            throw new IllegalArgumentException("Password reset code has expired. Please request a new code.");
        }

        if (request.getNewPassword().length() < 6) {
            throw new IllegalArgumentException("New password must be at least 6 characters.");
        }

        token.setUsed(true);
        passwordResetTokenRepository.save(token);

        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        // Resetting password verifies the email as well
        user.setEmailVerified(true);
        userRepository.save(user);
    }

    private String generateNumericCode() {
        return String.format("%06d", secureRandom.nextInt(1_000_000));
    }
}
