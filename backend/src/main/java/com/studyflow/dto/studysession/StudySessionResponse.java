package com.studyflow.dto.studysession;

import com.studyflow.entity.StudySessionStatus;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StudySessionResponse {

    private Long id;

    private LocalDate sessionDate;

    private LocalTime startTime;

    private LocalTime endTime;

    private Integer plannedMinutes;

    private Integer completedMinutes;

    private StudySessionStatus status;

    private Long taskId;

    private String taskTitle;
}