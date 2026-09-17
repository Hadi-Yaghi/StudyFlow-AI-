package com.studyflow.scheduler;

import com.studyflow.entity.StudySession;
import com.studyflow.entity.StudySessionStatus;
import com.studyflow.entity.Task;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Slf4j
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
        return generate(tasks, timeBlocks, date, null, 15);
    }

    public List<StudySession> generate(
            List<Task> tasks,
            List<TimeAllocator.TimeBlock> timeBlocks,
            LocalDate date,
            Map<Long, Integer> remainingMinutesMap
    ) {
        return generate(tasks, timeBlocks, date, remainingMinutesMap, 15);
    }

    public List<StudySession> generate(
            List<Task> tasks,
            List<TimeAllocator.TimeBlock> timeBlocks,
            LocalDate date,
            Map<Long, Integer> remainingMinutesMap,
            int breakMinutes
    ) {
        List<Task> sortedTasks = tasks.stream()
                .filter(task ->
                        task.getStatus() != null &&
                                !task.getStatus().name().equals("COMPLETED")
                                && (task.getDueDate() == null || !date.isAfter(task.getDueDate()))
                                && (remainingMinutesMap == null || remainingMinutesMap.getOrDefault(task.getId(), getRemainingMinutes(task)) > 0)
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

        while (taskIndex < sortedTasks.size() && !timeBlocks.isEmpty()) {
            Task task = sortedTasks.get(taskIndex);

            int currentRemaining = remainingMinutesMap != null
                    ? remainingMinutesMap.getOrDefault(task.getId(), getRemainingMinutes(task))
                    : getRemainingMinutes(task);

            if (currentRemaining <= 0) {
                taskIndex++;
                continue;
            }

            TimeAllocator.TimeBlock block = timeBlocks.remove(0);
            int blockMinutes = block.getMinutes();

            int scheduledMinutes = Math.min(currentRemaining, blockMinutes);
            if (scheduledMinutes <= 0) {
                taskIndex++;
                continue;
            }

            StudySession session = StudySession.builder()
                    .sessionDate(date)
                    .startTime(block.startTime())
                    .endTime(block.startTime().plusMinutes(scheduledMinutes))
                    .plannedMinutes(scheduledMinutes)
                    .completedMinutes(0)
                    .status(StudySessionStatus.PLANNED)
                    .task(task)
                    .rescheduled(false)
                    .build();

            sessions.add(session);

            int updatedRemaining = currentRemaining - scheduledMinutes;
            if (remainingMinutesMap != null) {
                remainingMinutesMap.put(task.getId(), updatedRemaining);
            }

            if (updatedRemaining <= 0) {
                taskIndex++;
            }

            // If a block has substantial leftover time, return the remainder after break to timeBlocks
            int leftoverMinutes = blockMinutes - scheduledMinutes;
            if (leftoverMinutes >= breakMinutes + TimeAllocator.MIN_SESSION_MINUTES) {
                var nextStart = block.startTime().plusMinutes(scheduledMinutes + breakMinutes);
                timeBlocks.add(0, new TimeAllocator.TimeBlock(nextStart, block.endTime()));
            }
        }

        return sessions;
    }

    public int getRemainingMinutes(Task task) {
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