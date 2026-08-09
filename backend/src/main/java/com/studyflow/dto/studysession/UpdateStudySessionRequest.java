package com.studyflow.dto.studysession;

import com.studyflow.entity.StudySessionStatus;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UpdateStudySessionRequest {

    private StudySessionStatus status;

    private Integer completedMinutes;
}