package com.studyflow.scheduler;

import lombok.*;

import java.time.LocalDate;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SchedulerResult {

    private int generatedSessions;

    private int scheduledMinutes;

    private int unscheduledMinutes;

    private LocalDate firstSessionDate;

    private List<LocalDate> sessionDates;

    private String status;

    private String message;

    private String failureReason;
}