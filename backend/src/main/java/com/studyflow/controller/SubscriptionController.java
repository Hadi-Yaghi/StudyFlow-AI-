package com.studyflow.controller;

import com.studyflow.dto.response.SubscriptionResponse;
import com.studyflow.entity.User;
import com.studyflow.exception.UserNotFoundException;
import com.studyflow.repository.UserRepository;
import com.studyflow.service.SubscriptionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class SubscriptionController {

    private final SubscriptionService subscriptionService;
    private final UserRepository userRepository;

    @GetMapping("/subscription/status")
    public ResponseEntity<SubscriptionResponse> getStatus(Authentication authentication) {
        User user = getUser(authentication);
        SubscriptionResponse response = subscriptionService.getSubscriptionStatus(user);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/subscription/sync")
    public ResponseEntity<SubscriptionResponse> syncSubscription(Authentication authentication) {
        User user = getUser(authentication);
        SubscriptionResponse response = subscriptionService.syncSubscription(user);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/webhooks/revenuecat")
    public ResponseEntity<Map<String, String>> handleWebhook(
            @RequestHeader(value = "Authorization", required = false) String authHeader,
            @RequestBody Map<String, Object> payload
    ) {
        subscriptionService.handleRevenueCatWebhook(authHeader, payload);
        return ResponseEntity.ok(Map.of("status", "ok"));
    }

    private User getUser(Authentication authentication) {
        return userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new UserNotFoundException("User not found: " + authentication.getName()));
    }
}
