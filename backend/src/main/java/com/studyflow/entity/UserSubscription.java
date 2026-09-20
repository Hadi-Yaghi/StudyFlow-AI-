package com.studyflow.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;

@Entity
@Table(name = "user_subscriptions")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserSubscription extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Column(name = "entitlement", nullable = false, length = 100)
    @Builder.Default
    private String entitlement = "studyflow_pro";

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 50)
    @Builder.Default
    private SubscriptionStatus status = SubscriptionStatus.FREE;

    @Column(name = "product_id", length = 100)
    private String productId;

    @Column(name = "is_pro", nullable = false)
    @Builder.Default
    private boolean pro = false;

    @Column(name = "expires_at")
    private Instant expiresAt;

    @Column(name = "last_verified_at")
    private Instant lastVerifiedAt;

    @Column(name = "original_purchase_date")
    private Instant originalPurchaseDate;

    /**
     * Determines whether Pro entitlement is currently valid and active.
     */
    public boolean isProActive() {
        if (!pro) {
            return false;
        }
        // Lifetime subscriptions or non-expiring purchases have null expiresAt
        if (expiresAt == null) {
            return true;
        }
        return expiresAt.isAfter(Instant.now());
    }
}
