package com.studyflow.service;

import com.studyflow.dto.response.ScheduleUsageResponse;
import com.studyflow.entity.ScheduleGenerationType;
import com.studyflow.entity.ScheduleGenerationUsage;
import com.studyflow.entity.User;
import com.studyflow.repository.ScheduleGenerationUsageRepository;
import com.studyflow.service.impl.ScheduleUsageServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.Instant;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ScheduleQuotaTest {

    @Mock
    private ScheduleGenerationUsageRepository usageRepository;

    @InjectMocks
    private ScheduleUsageServiceImpl scheduleUsageService;

    private User testUser;

    @BeforeEach
    void setUp() {
        testUser = User.builder()
                .id(10L)
                .email("freeuser@studyflow.com")
                .name("Free User")
                .build();

        ReflectionTestUtils.setField(scheduleUsageService, "configuredQuotaPeriod", "MONTHLY");
        ReflectionTestUtils.setField(scheduleUsageService, "freeGenerationLimit", 3);
    }

    @Test
    void canUserGenerate_shouldReturnTrue_whenFreeUserHasUsedZeroGenerations() {
        when(usageRepository.countByUserAndSuccessfulTrueAndTimestampAfter(eq(testUser), any(Instant.class)))
                .thenReturn(0L);

        boolean canGenerate = scheduleUsageService.canUserGenerate(testUser, false);

        assertTrue(canGenerate);
        assertEquals(3, scheduleUsageService.getRemainingFreeGenerations(testUser));
    }

    @Test
    void canUserGenerate_shouldReturnTrue_whenFreeUserHasUsedTwoGenerations() {
        when(usageRepository.countByUserAndSuccessfulTrueAndTimestampAfter(eq(testUser), any(Instant.class)))
                .thenReturn(2L);

        boolean canGenerate = scheduleUsageService.canUserGenerate(testUser, false);

        assertTrue(canGenerate);
        assertEquals(1, scheduleUsageService.getRemainingFreeGenerations(testUser));
    }

    @Test
    void canUserGenerate_shouldReturnFalse_whenFreeUserHasUsedThreeGenerations() {
        when(usageRepository.countByUserAndSuccessfulTrueAndTimestampAfter(eq(testUser), any(Instant.class)))
                .thenReturn(3L);

        boolean canGenerate = scheduleUsageService.canUserGenerate(testUser, false);

        assertFalse(canGenerate);
        assertEquals(0, scheduleUsageService.getRemainingFreeGenerations(testUser));
    }

    @Test
    void canUserGenerate_shouldReturnTrue_forProUserEvenIfUsageExceedsLimit() {
        // Even if recorded usage is 10
        boolean canGenerate = scheduleUsageService.canUserGenerate(testUser, true);

        assertTrue(canGenerate);
    }

    @Test
    void recordGenerationUsage_shouldPersistSuccessfulGeneration() {
        scheduleUsageService.recordGenerationUsage(testUser, ScheduleGenerationType.STANDARD, true, 4, "4 sessions");

        verify(usageRepository).save(argThat(usage ->
                usage.getUser().equals(testUser) &&
                        usage.isSuccessful() &&
                        usage.getGenerationType() == ScheduleGenerationType.STANDARD &&
                        usage.getGeneratedSessionsCount() == 4
        ));
    }

    @Test
    void recordGenerationUsage_shouldPersistFailedGenerationWithoutCountingAsSuccess() {
        scheduleUsageService.recordGenerationUsage(testUser, ScheduleGenerationType.STANDARD, false, 0, "No availability");

        verify(usageRepository).save(argThat(usage ->
                usage.getUser().equals(testUser) &&
                        !usage.isSuccessful() &&
                        usage.getGeneratedSessionsCount() == 0
        ));
    }

    @Test
    void getUsageSummary_shouldReportCorrectValuesForFreeUser() {
        when(usageRepository.countByUserAndSuccessfulTrueAndTimestampAfter(eq(testUser), any(Instant.class)))
                .thenReturn(1L);

        ScheduleUsageResponse summary = scheduleUsageService.getUsageSummary(testUser, false);

        assertFalse(summary.isPro());
        assertEquals(3, summary.getFreeGenerationLimit());
        assertEquals(1L, summary.getUsedFreeGenerations());
        assertEquals(2, summary.getRemainingFreeGenerations());
        assertEquals("MONTHLY", summary.getQuotaPeriod());
        assertTrue(summary.isCanGenerate());
    }
}
