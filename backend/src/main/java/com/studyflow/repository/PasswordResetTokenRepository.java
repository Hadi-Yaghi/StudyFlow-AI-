package com.studyflow.repository;

import com.studyflow.entity.PasswordResetToken;
import com.studyflow.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface PasswordResetTokenRepository extends JpaRepository<PasswordResetToken, Long> {

    Optional<PasswordResetToken> findByUserAndCodeAndUsedFalse(User user, String code);
}
