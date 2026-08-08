package com.studyflow.scheduler;

import com.studyflow.entity.StudySession;
import com.studyflow.entity.StudySessionStatus;
import com.studyflow.entity.Task;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Component
public class SessionGenerator {

    private final PriorityCalculator priorityCalculator;

    public SessionGenerator(PriorityCalculator priorityCalculator) {
        this.priorityCalculator = priorityCalculator;
    }

    public List<StudySession> generate(
            List<Task> tasks,
            List<TimeAllocator.TimeBlock> timeBlocks,
            LocalDate date
    ) {

        List<Task> sortedTasks = tasks.stream()
                .filter(task ->
                        task.getStatus() != null &&
                                !task.getStatus().name().equals("COMPLETED")
                )
                .sorted((task1, task2) ->
                        Double.compare(
                                priorityCalculator.calculateScore(task2),
                                priorityCalculator.calculateScore(task1)
                        )
                )
                .toList();

        List<StudySession> sessions = new ArrayList<>();

        int taskIndex = 0;
        int remainingTaskMinutes = 0;

        while (taskIndex < sortedTasks.size()
                && !timeBlocks.isEmpty()) {

            Task task = sortedTasks.get(taskIndex);

            if (remainingTaskMinutes <= 0) {
                remainingTaskMinutes = getRemainingMinutes(task);

                if (remainingTaskMinutes <= 0) {
                    taskIndex++;
                    continue;
                }
            }

            TimeAllocator.TimeBlock block =
                    timeBlocks.remove(0);

            int blockMinutes = block.getMinutes();

            int scheduledMinutes = Math.min(
                    remainingTaskMinutes,
                    blockMinutes
            );

            StudySession session = StudySession.builder()
                    .sessionDate(date)
                    .startTime(block.startTime())
                    .endTime(
                            block.startTime()
                                    .plusMinutes(scheduledMinutes)
                    )
                    .plannedMinutes(scheduledMinutes)
                    .completedMinutes(0)
                    .status(StudySessionStatus.PLANNED)
                    .task(task)
                    .build();

            sessions.add(session);

            remainingTaskMinutes -= scheduledMinutes;

            if (remainingTaskMinutes <= 0) {
                taskIndex++;
            }
        }

        return sessions;
    }

    private int getRemainingMinutes(Task task) {

        int estimatedHours = task.getEstimatedHours() != null
                ? task.getEstimatedHours()
                : 0;

        int completedHours = task.getCompletedHours() != null
                ? task.getCompletedHours()
                : 0;

        return Math.max(
                (estimatedHours - completedHours) * 60,
                0
        );
    }
}