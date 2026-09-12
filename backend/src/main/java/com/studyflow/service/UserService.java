package com.studyflow.service;

import com.studyflow.dto.request.ChangePasswordRequest;
import com.studyflow.dto.request.UpdateProfileRequest;
import com.studyflow.dto.response.UserProfileResponse;
import com.studyflow.entity.User;
import com.studyflow.exception.UserNotFoundException;
import com.studyflow.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public UserProfileResponse getProfile(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(UserNotFoundException::new);

        boolean hasPassword = user.getPasswordHash() != null && !user.getPasswordHash().isBlank();

        return UserProfileResponse.builder()
                .id(user.getId())
                .name(user.getName())
                .email(user.getEmail())
                .major(user.getMajor())
                .emailVerified(user.isEmailVerified())
                .hasPassword(hasPassword)
                .build();
    }

    @Transactional
    public UserProfileResponse updateProfile(String email, UpdateProfileRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(UserNotFoundException::new);

        user.setName(request.getName().trim());
        if (request.getMajor() != null) {
            user.setMajor(request.getMajor().trim());
        }

        User saved = userRepository.save(user);

        boolean hasPassword = saved.getPasswordHash() != null && !saved.getPasswordHash().isBlank();

        return UserProfileResponse.builder()
                .id(saved.getId())
                .name(saved.getName())
                .email(saved.getEmail())
                .major(saved.getMajor())
                .emailVerified(saved.isEmailVerified())
                .hasPassword(hasPassword)
                .build();
    }

    @Transactional
    public void changePassword(String email, ChangePasswordRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(UserNotFoundException::new);

        // If user already has a password and is not a google-only user setting password for first time
        if (user.getPasswordHash() != null && user.getGoogleId() == null) {
            if (request.getCurrentPassword() == null || request.getCurrentPassword().isBlank()) {
                throw new IllegalArgumentException("Current password is required");
            }
            if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPasswordHash())) {
                throw new IllegalArgumentException("Incorrect current password");
            }
        }

        if (request.getNewPassword().length() < 6) {
            throw new IllegalArgumentException("New password must be at least 6 characters");
        }

        if (request.getCurrentPassword() != null && request.getCurrentPassword().equals(request.getNewPassword())) {
            throw new IllegalArgumentException("New password cannot be the same as the current password");
        }

        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);
    }
}
