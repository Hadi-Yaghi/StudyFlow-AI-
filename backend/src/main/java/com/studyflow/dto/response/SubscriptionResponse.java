package com.studyflow.dto.response;

import lombok.*;

import java.time.Instant;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SubscriptionResponse {

    private boolean pro;

    private String status;

    private String entitlement;

    private String productId;

    private Instant expiresAt;

    private int remainingFreeGenerations;

    private int freeGenerationLimit;
}
