package com.studyflow.service;

import com.studyflow.dto.response.SubscriptionResponse;
import com.studyflow.entity.User;
import com.studyflow.entity.UserSubscription;

import java.util.Map;

public interface SubscriptionService {

    boolean isPro(User user);

    UserSubscription getOrCreateSubscription(User user);

    SubscriptionResponse getSubscriptionStatus(User user);

    SubscriptionResponse syncSubscription(User user);

    void handleRevenueCatWebhook(String authHeader, Map<String, Object> payload);

    void setProStatusForTesting(User user, boolean pro, String productId);
}
