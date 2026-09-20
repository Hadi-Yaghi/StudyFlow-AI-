package com.studyflow.repository;

import com.studyflow.entity.ScheduleGenerationType;
import com.studyflow.entity.ScheduleGenerationUsage;
import com.studyflow.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;

@Repository
public interface ScheduleGenerationUsageRepository extends JpaRepository<ScheduleGenerationUsage, Long> {

    long countByUserAndSuccessfulTrueAndTimestampAfter(User user, Instant timestamp);

    long countByUserAndSuccessfulTrueAndGenerationTypeAndTimestampAfter(
            User user,
            ScheduleGenerationType generationType,
            Instant timestamp
    );

    List<ScheduleGenerationUsage> findByUserOrderByTimestampDesc(User user);
}
