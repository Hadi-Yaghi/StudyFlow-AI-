package com.studyflow.service.impl;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.studyflow.dto.response.SubscriptionResponse;
import com.studyflow.entity.SubscriptionStatus;
import com.studyflow.entity.User;
import com.studyflow.entity.UserSubscription;
import com.studyflow.repository.UserRepository;
import com.studyflow.repository.UserSubscriptionRepository;
import com.studyflow.service.ScheduleUsageService;
import com.studyflow.service.SubscriptionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestClient;

import java.time.Instant;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class SubscriptionServiceImpl implements SubscriptionService {

    private final UserSubscriptionRepository subscriptionRepository;
    private final UserRepository userRepository;
    private final ScheduleUsageService scheduleUsageService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Value("${studyflow.revenuecat.secret-key:}")
    private String revenueCatSecretKey;

    @Value("${studyflow.revenuecat.webhook-auth-key:}")
    private String revenueCatWebhookAuthKey;

    private static final String REVENUECAT_BASE_URL = "https://api.revenuecat.com/v1";
    private static final String PRO_ENTITLEMENT = "studyflow_pro";

    @Override
    @Transactional(readOnly = true)
    public boolean isPro(User user) {
        if (user == null) {
            return false;
        }
        return subscriptionRepository.findByUser(user)
                .map(UserSubscription::isProActive)
                .orElse(false);
    }

    @Override
    @Transactional
    public UserSubscription getOrCreateSubscription(User user) {
        return subscriptionRepository.findByUser(user)
                .orElseGet(() -> {
                    UserSubscription sub = UserSubscription.builder()
                            .user(user)
                            .entitlement(PRO_ENTITLEMENT)
                            .status(SubscriptionStatus.FREE)
                            .pro(false)
                            .lastVerifiedAt(Instant.now())
                            .build();
                    return subscriptionRepository.save(sub);
                });
    }

    @Override
    @Transactional(readOnly = true)
    public SubscriptionResponse getSubscriptionStatus(User user) {
        UserSubscription sub = getOrCreateSubscription(user);
        boolean proActive = sub.isProActive();
        int remainingGenerations = scheduleUsageService.getRemainingFreeGenerations(user);

        return SubscriptionResponse.builder()
                .pro(proActive)
                .status(sub.getStatus().name())
                .entitlement(sub.getEntitlement())
                .productId(sub.getProductId())
                .expiresAt(sub.getExpiresAt())
                .remainingFreeGenerations(proActive ? -1 : remainingGenerations)
                .freeGenerationLimit(ScheduleUsageService.FREE_SCHEDULE_GENERATION_LIMIT)
                .build();
    }

    @Override
    @Transactional
    public SubscriptionResponse syncSubscription(User user) {
        UserSubscription sub = getOrCreateSubscription(user);

        if (revenueCatSecretKey == null || revenueCatSecretKey.trim().isEmpty() || revenueCatSecretKey.startsWith("rcb_sb_YOUR_")) {
            log.info("RevenueCat secret key is not configured; preserving stored database subscription state for user ID {}", user.getId());
            return getSubscriptionStatus(user);
        }

        try {
            String appUserId = "studyflow_" + user.getId();
            RestClient client = RestClient.builder()
                    .baseUrl(REVENUECAT_BASE_URL)
                    .defaultHeader(HttpHeaders.AUTHORIZATION, "Bearer " + revenueCatSecretKey.trim())
                    .defaultHeader(HttpHeaders.ACCEPT, MediaType.APPLICATION_JSON_VALUE)
                    .build();

            String responseBody = client.get()
                    .uri("/subscribers/{appUserId}", appUserId)
                    .retrieve()
                    .body(String.class);

            if (responseBody != null) {
                JsonNode root = objectMapper.readTree(responseBody);
                JsonNode subscriberNode = root.path("subscriber");
                JsonNode entitlementsNode = subscriberNode.path("entitlements");
                JsonNode proNode = entitlementsNode.path(PRO_ENTITLEMENT);

                if (!proNode.isMissingNode()) {
                    String expiresDateStr = proNode.path("expires_date").asText(null);
                    String productId = proNode.path("product_identifier").asText(null);
                    String purchaseDateStr = proNode.path("purchase_date").asText(null);

                    Instant expiresAt = expiresDateStr != null ? Instant.parse(expiresDateStr) : null;
                    Instant purchaseDate = purchaseDateStr != null ? Instant.parse(purchaseDateStr) : null;

                    boolean isPro = expiresAt == null || expiresAt.isAfter(Instant.now());

                    sub.setPro(isPro);
                    sub.setStatus(isPro ? SubscriptionStatus.ACTIVE : SubscriptionStatus.EXPIRED);
                    sub.setProductId(productId);
                    sub.setExpiresAt(expiresAt);
                    sub.setOriginalPurchaseDate(purchaseDate);
                    sub.setLastVerifiedAt(Instant.now());

                    log.info("Successfully synced RevenueCat subscription for user {}: pro={}, product={}, expiresAt={}",
                            user.getEmail(), isPro, productId, expiresAt);
                } else {
                    sub.setPro(false);
                    sub.setStatus(SubscriptionStatus.FREE);
                    sub.setExpiresAt(null);
                    sub.setLastVerifiedAt(Instant.now());
                    log.info("User {} has no active '{}' entitlement in RevenueCat.", user.getEmail(), PRO_ENTITLEMENT);
                }
                subscriptionRepository.save(sub);
            }
        } catch (Exception e) {
            log.error("Failed to sync RevenueCat subscription for user {}: {}", user.getEmail(), e.getMessage());
        }

        return getSubscriptionStatus(user);
    }

    @Override
    @Transactional
    public void handleRevenueCatWebhook(String authHeader, Map<String, Object> payload) {
        if (revenueCatWebhookAuthKey != null && !revenueCatWebhookAuthKey.trim().isEmpty()) {
            if (authHeader == null || !authHeader.trim().equals("Bearer " + revenueCatWebhookAuthKey.trim())) {
                log.warn("Unauthorized RevenueCat webhook attempt with invalid auth header.");
                throw new IllegalArgumentException("Invalid webhook authorization");
            }
        }

        if (payload == null || !payload.containsKey("event")) {
            log.warn("Received empty or malformed RevenueCat webhook payload.");
            return;
        }

        @SuppressWarnings("unchecked")
        Map<String, Object> event = (Map<String, Object>) payload.get("event");
        String appUserId = (String) event.get("app_user_id");
        String type = (String) event.get("type");

        log.info("Received RevenueCat webhook event: type={}, app_user_id={}", type, appUserId);

        if (appUserId == null || !appUserId.startsWith("studyflow_")) {
            log.debug("Ignoring webhook event for non-StudyFlow user ID: {}", appUserId);
            return;
        }

        try {
            Long userId = Long.parseLong(appUserId.replace("studyflow_", ""));
            User user = userRepository.findById(userId).orElse(null);
            if (user == null) {
                log.warn("User with ID {} not found for RevenueCat webhook event.", userId);
                return;
            }

            // Trigger re-sync from RevenueCat server to ensure consistency
            syncSubscription(user);
        } catch (Exception e) {
            log.error("Error processing RevenueCat webhook for app_user_id {}: {}", appUserId, e.getMessage(), e);
        }
    }

    @Override
    @Transactional
    public void setProStatusForTesting(User user, boolean pro, String productId) {
        UserSubscription sub = getOrCreateSubscription(user);
        sub.setPro(pro);
        sub.setStatus(pro ? SubscriptionStatus.ACTIVE : SubscriptionStatus.FREE);
        sub.setProductId(productId);
        sub.setExpiresAt(pro ? Instant.now().plusSeconds(86400 * 30) : null);
        sub.setLastVerifiedAt(Instant.now());
        subscriptionRepository.save(sub);
        log.info("Set test subscription status for user {}: pro={}, product={}", user.getEmail(), pro, productId);
    }
}
