package com.studyflow.service.impl;

import com.studyflow.dto.response.ScheduleUsageResponse;
import com.studyflow.entity.QuotaPeriod;
import com.studyflow.entity.ScheduleGenerationType;
import com.studyflow.entity.ScheduleGenerationUsage;
import com.studyflow.entity.User;
import com.studyflow.repository.ScheduleGenerationUsageRepository;
import com.studyflow.service.ScheduleUsageService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.ZoneId;

@Slf4j
@Service
@RequiredArgsConstructor
public class ScheduleUsageServiceImpl implements ScheduleUsageService {

    private final ScheduleGenerationUsageRepository usageRepository;

    @Value("${studyflow.schedule.quota-period:MONTHLY}")
    private String configuredQuotaPeriod;

    @Value("${studyflow.schedule.free-generation-limit:3}")
    private int freeGenerationLimit;

    private QuotaPeriod resolveQuotaPeriod() {
        try {
            return QuotaPeriod.valueOf(configuredQuotaPeriod.trim().toUpperCase());
        } catch (Exception e) {
            log.warn("Invalid quota period configured: '{}'. Defaulting to MONTHLY.", configuredQuotaPeriod);
            return QuotaPeriod.MONTHLY;
        }
    }

    private Instant getWindowStart() {
        QuotaPeriod period = resolveQuotaPeriod();
        return period.getPeriodStart(Instant.now(), ZoneId.systemDefault());
    }

    @Override
    @Transactional(readOnly = true)
    public long getUsedFreeGenerationsInCurrentPeriod(User user) {
        Instant start = getWindowStart();
        // Only successful generations consume quota
        return usageRepository.countByUserAndSuccessfulTrueAndTimestampAfter(user, start);
    }

    @Override
    @Transactional(readOnly = true)
    public int getRemainingFreeGenerations(User user) {
        long used = getUsedFreeGenerationsInCurrentPeriod(user);
        int remaining = (int) (freeGenerationLimit - used);
        return Math.max(0, remaining);
    }

    @Override
    @Transactional(readOnly = true)
    public boolean canUserGenerate(User user, boolean isPro) {
        if (isPro) {
            return true;
        }
        return getRemainingFreeGenerations(user) > 0;
    }

    @Override
    @Transactional
    public void recordGenerationUsage(
            User user,
            ScheduleGenerationType type,
            boolean success,
            int sessionsCount,
            String notes
    ) {
        ScheduleGenerationUsage usage = ScheduleGenerationUsage.builder()
                .user(user)
                .timestamp(Instant.now())
                .generationType(type)
                .successful(success)
                .generatedSessionsCount(sessionsCount)
                .notes(notes)
                .build();

        usageRepository.save(usage);
        log.info("Recorded generation usage for user [{}]: type={}, success={}, sessions={}",
                user.getEmail(), type, success, sessionsCount);
    }

    @Override
    @Transactional(readOnly = true)
    public ScheduleUsageResponse getUsageSummary(User user, boolean isPro) {
        long used = getUsedFreeGenerationsInCurrentPeriod(user);
        int remaining = isPro ? Integer.MAX_VALUE : (int) Math.max(0, freeGenerationLimit - used);

        return ScheduleUsageResponse.builder()
                .pro(isPro)
                .freeGenerationLimit(freeGenerationLimit)
                .usedFreeGenerations(used)
                .remainingFreeGenerations(isPro ? -1 : remaining)
                .quotaPeriod(resolveQuotaPeriod().name())
                .periodStart(getWindowStart())
                .canGenerate(isPro || remaining > 0)
                .build();
    }
}
