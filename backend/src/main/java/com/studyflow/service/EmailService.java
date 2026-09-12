package com.studyflow.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
@Slf4j
public class EmailService {

    @Autowired(required = false)
    private JavaMailSender mailSender;

    @Value("${spring.mail.username:noreply@studyflow.app}")
    private String fromEmail;

    public void sendVerificationEmail(String toEmail, String name, String code) {
        String subject = "StudyFlow - Verify your email address";
        String messageBody = String.format(
                "Hello %s,\n\n" +
                "Thank you for registering with StudyFlow!\n\n" +
                "Your email verification code is: %s\n\n" +
                "This code will expire in 15 minutes. Enter it in the app to activate your account.\n\n" +
                "Best regards,\n" +
                "The StudyFlow Team",
                name != null ? name : "Student", code
        );

        sendEmail(toEmail, subject, messageBody, code, "EMAIL VERIFICATION");
    }

    public void sendPasswordResetEmail(String toEmail, String name, String code) {
        String subject = "StudyFlow - Password reset request";
        String messageBody = String.format(
                "Hello %s,\n\n" +
                "We received a request to reset your StudyFlow password.\n\n" +
                "Your password reset code is: %s\n\n" +
                "This code will expire in 15 minutes. If you did not request this, please ignore this email.\n\n" +
                "Best regards,\n" +
                "The StudyFlow Team",
                name != null ? name : "Student", code
        );

        sendEmail(toEmail, subject, messageBody, code, "PASSWORD RESET");
    }

    private void sendEmail(String toEmail, String subject, String text, String code, String actionType) {
        log.info("================== STUDYFLOW {} ==================", actionType);
        log.info("To: {}", toEmail);
        log.info("Subject: {}", subject);
        log.info("Security Code: {}", code);
        log.info("======================================================");

        if (mailSender != null) {
            try {
                SimpleMailMessage message = new SimpleMailMessage();
                message.setFrom(fromEmail);
                message.setTo(toEmail);
                message.setSubject(subject);
                message.setText(text);
                mailSender.send(message);
                log.info("Email sent successfully via JavaMailSender to {}", toEmail);
            } catch (Exception e) {
                log.warn("Could not dispatch email via SMTP (using console fallback). Reason: {}", e.getMessage());
            }
        } else {
            log.info("JavaMailSender is not configured. Email logged to console above.");
        }
    }
}
