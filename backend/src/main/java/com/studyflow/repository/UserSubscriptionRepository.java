package com.studyflow.repository;

import com.studyflow.entity.User;
import com.studyflow.entity.UserSubscription;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserSubscriptionRepository extends JpaRepository<UserSubscription, Long> {

    Optional<UserSubscription> findByUser(User user);

    Optional<UserSubscription> findByUserId(Long userId);
}
