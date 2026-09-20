package com.studyflow.dto.response;

import lombok.*;

import java.time.Instant;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ScheduleUsageResponse {

    private boolean pro;

    private int freeGenerationLimit;

    private long usedFreeGenerations;

    private int remainingFreeGenerations;

    private String quotaPeriod;

    private Instant periodStart;

    private boolean canGenerate;
}
