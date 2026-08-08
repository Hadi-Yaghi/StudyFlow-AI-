package com.studyflow.scheduler;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SchedulerResult {

    private int generatedSessions;

    private int scheduledMinutes;

    private int unscheduledMinutes;
}