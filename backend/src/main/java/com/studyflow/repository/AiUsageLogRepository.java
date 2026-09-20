package com.studyflow.repository;

import com.studyflow.entity.AiUsageLog;
import com.studyflow.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;

@Repository
public interface AiUsageLogRepository extends JpaRepository<AiUsageLog, Long> {

    List<AiUsageLog> findByUserOrderByTimestampDesc(User user);

    long countByUserAndSuccessfulTrueAndTimestampAfter(User user, Instant timestamp);
}
