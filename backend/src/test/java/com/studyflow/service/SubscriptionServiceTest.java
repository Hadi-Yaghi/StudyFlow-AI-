package com.studyflow.service;

import com.studyflow.dto.response.SubscriptionResponse;
import com.studyflow.entity.SubscriptionStatus;
import com.studyflow.entity.User;
import com.studyflow.entity.UserSubscription;
import com.studyflow.repository.UserRepository;
import com.studyflow.repository.UserSubscriptionRepository;
import com.studyflow.service.impl.SubscriptionServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class SubscriptionServiceTest {

    @Mock
    private UserSubscriptionRepository subscriptionRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private ScheduleUsageService scheduleUsageService;

    @InjectMocks
    private SubscriptionServiceImpl subscriptionService;

    private User testUser;

    @BeforeEach
    void setUp() {
        testUser = User.builder()
                .id(1L)
                .email("student@studyflow.com")
                .name("Student User")
                .build();
    }

    @Test
    void isPro_shouldReturnFalse_whenNoSubscriptionRecordExists() {
        when(subscriptionRepository.findByUser(testUser)).thenReturn(Optional.empty());

        boolean result = subscriptionService.isPro(testUser);

        assertFalse(result);
    }

    @Test
    void isPro_shouldReturnTrue_whenProAndNotExpired() {
        UserSubscription activeSub = UserSubscription.builder()
                .user(testUser)
                .pro(true)
                .status(SubscriptionStatus.ACTIVE)
                .expiresAt(Instant.now().plusSeconds(86400))
                .build();

        when(subscriptionRepository.findByUser(testUser)).thenReturn(Optional.of(activeSub));

        boolean result = subscriptionService.isPro(testUser);

        assertTrue(result);
    }

    @Test
    void isPro_shouldReturnTrue_whenProLifetimeWithNullExpiration() {
        UserSubscription lifetimeSub = UserSubscription.builder()
                .user(testUser)
                .pro(true)
                .status(SubscriptionStatus.ACTIVE)
                .productId("lifetime")
                .expiresAt(null)
                .build();

        when(subscriptionRepository.findByUser(testUser)).thenReturn(Optional.of(lifetimeSub));

        boolean result = subscriptionService.isPro(testUser);

        assertTrue(result);
    }

    @Test
    void isPro_shouldReturnFalse_whenProExpired() {
        UserSubscription expiredSub = UserSubscription.builder()
                .user(testUser)
                .pro(true)
                .status(SubscriptionStatus.EXPIRED)
                .expiresAt(Instant.now().minusSeconds(3600))
                .build();

        when(subscriptionRepository.findByUser(testUser)).thenReturn(Optional.of(expiredSub));

        boolean result = subscriptionService.isPro(testUser);

        assertFalse(result);
    }

    @Test
    void getSubscriptionStatus_shouldReturnCorrectResponse() {
        UserSubscription activeSub = UserSubscription.builder()
                .user(testUser)
                .pro(true)
                .status(SubscriptionStatus.ACTIVE)
                .entitlement("studyflow_pro")
                .productId("monthly")
                .expiresAt(Instant.now().plusSeconds(86400))
                .build();

        when(subscriptionRepository.findByUser(testUser)).thenReturn(Optional.of(activeSub));
        when(scheduleUsageService.getRemainingFreeGenerations(testUser)).thenReturn(3);

        SubscriptionResponse response = subscriptionService.getSubscriptionStatus(testUser);

        assertTrue(response.isPro());
        assertEquals("ACTIVE", response.getStatus());
        assertEquals("studyflow_pro", response.getEntitlement());
        assertEquals("monthly", response.getProductId());
        assertEquals(-1, response.getRemainingFreeGenerations()); // unlimited for Pro
    }

    @Test
    void setProStatusForTesting_shouldPersistActiveSubscription() {
        when(subscriptionRepository.findByUser(testUser)).thenReturn(Optional.empty());
        when(subscriptionRepository.save(any(UserSubscription.class))).thenAnswer(i -> i.getArgument(0));

        subscriptionService.setProStatusForTesting(testUser, true, "yearly");

        verify(subscriptionRepository, atLeastOnce()).save(argThat(sub ->
                sub.isPro() && "yearly".equals(sub.getProductId()) && sub.getExpiresAt() != null
        ));
    }
}
