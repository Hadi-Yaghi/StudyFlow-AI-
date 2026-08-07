package com.studyflow.dto.request;

import com.studyflow.entity.TaskPriority;
import com.studyflow.entity.TaskType;
import jakarta.validation.constraints.FutureOrPresent;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

@Getter
@Setter
public class TaskCreateRequest {

    @NotBlank(message = "Task title is required")
    private String title;

    private String description;

    @NotNull(message = "Task type is required")
    private TaskType type;

    @NotNull(message = "Task priority is required")
    private TaskPriority priority;

    @FutureOrPresent(message = "Due date cannot be in the past")
    private LocalDate dueDate;

    @NotNull(message = "Estimated hours are required")
    @Min(value = 1, message = "Estimated hours must be at least 1")
    private Integer estimatedHours;

    @NotNull(message = "Course ID is required")
    private Long courseId;
}