package com.studyflow.service;

import com.studyflow.dto.response.ScheduleUsageResponse;
import com.studyflow.entity.ScheduleGenerationType;
import com.studyflow.entity.User;

public interface ScheduleUsageService {

    int FREE_SCHEDULE_GENERATION_LIMIT = 3;

    long getUsedFreeGenerationsInCurrentPeriod(User user);

    int getRemainingFreeGenerations(User user);

    boolean canUserGenerate(User user, boolean isPro);

    void recordGenerationUsage(
            User user,
            ScheduleGenerationType type,
            boolean success,
            int sessionsCount,
            String notes
    );

    ScheduleUsageResponse getUsageSummary(User user, boolean isPro);
}
