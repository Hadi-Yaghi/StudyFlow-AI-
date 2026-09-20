package com.studyflow.dto.request;

import com.studyflow.entity.TaskPriority;
import com.studyflow.entity.TaskStatus;
import com.studyflow.entity.TaskType;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TaskUpdateRequest {

    @NotBlank(message = "Task title is required")
    private String title;

    private String description;

    @NotNull(message = "Task type is required")
    private TaskType type;

    @NotNull(message = "Task priority is required")
    private TaskPriority priority;

    @NotNull(message = "Due date is required")
    private LocalDate dueDate;

    @NotNull(message = "Estimated hours are required")
    @Min(value = 1, message = "Estimated hours must be at least 1")
    private Integer estimatedHours;

    @Min(value = 0, message = "Completed hours cannot be negative")
    private Integer completedHours;

    private TaskStatus status;

    @NotNull(message = "Course ID is required")
    private Long courseId;
}
