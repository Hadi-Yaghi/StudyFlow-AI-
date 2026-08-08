package com.studyflow.dto.response;

import com.studyflow.entity.TaskPriority;
import com.studyflow.entity.TaskStatus;
import com.studyflow.entity.TaskType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TaskResponse {

    private Long id;

    private String title;

    private String description;

    private TaskType type;

    private TaskPriority priority;

    private LocalDate dueDate;

    private Integer estimatedHours;

    private Integer completedHours;

    private TaskStatus status;

    private Long courseId;
}