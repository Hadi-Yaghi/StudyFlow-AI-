package com.studyflow.config;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@Slf4j
public class UserMigrationRunner implements CommandLineRunner {

    private final JdbcTemplate jdbcTemplate;

    @Override
    public void run(String... args) {
        try {
            // Ensure existing users are marked as verified so they are never locked out
            int updated = jdbcTemplate.update("UPDATE users SET email_verified = true WHERE email_verified IS NULL OR email_verified = false");
            if (updated > 0) {
                log.info("Initialized {} existing users as email verified.", updated);
            }
        } catch (Exception e) {
            log.debug("Note on email_verified init: {}", e.getMessage());
        }

        try {
            // Drop NOT NULL constraint on password_hash if present, to safely allow Google OAuth users
            jdbcTemplate.execute("ALTER TABLE users ALTER COLUMN password_hash DROP NOT NULL");
            log.info("Successfully ensured password_hash column is nullable for OAuth compatibility.");
        } catch (Exception e) {
            log.debug("password_hash constraint check: {}", e.getMessage());
        }
    }
}
