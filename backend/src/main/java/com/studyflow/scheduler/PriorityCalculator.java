package com.studyflow.scheduler;

import com.studyflow.entity.Task;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;

import org.springframework.stereotype.Component;

@Component
public class PriorityCalculator {

    public double calculateScore(Task task) {

        if (task.getStatus() == null ||
                task.getStatus().name().equals("COMPLETED")) {
            return 0;
        }

        int estimatedHours = task.getEstimatedHours() != null
                ? task.getEstimatedHours()
                : 0;

        int completedHours = task.getCompletedHours() != null
                ? task.getCompletedHours()
                : 0;

        int remainingHours = Math.max(
                estimatedHours - completedHours,
                0
        );

        long daysUntilDue = ChronoUnit.DAYS.between(
                LocalDate.now(),
                task.getDueDate()
        );

        double urgencyScore;

        if (daysUntilDue <= 0) {
            urgencyScore = 100;
        } else {
            urgencyScore = Math.max(
                    0,
                    100.0 / daysUntilDue
            );
        }

        double workloadScore = Math.min(
                remainingHours * 5,
                50
        );

        double priorityScore = switch (task.getPriority()) {
            case LOW -> 10;
            case MEDIUM -> 30;
            case HIGH -> 60;
            case CRITICAL -> 100;
        };

        return priorityScore
                + urgencyScore
                + workloadScore;
    }
}