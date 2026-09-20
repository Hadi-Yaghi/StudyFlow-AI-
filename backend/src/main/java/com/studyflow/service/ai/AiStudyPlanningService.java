package com.studyflow.service.ai;

import com.studyflow.dto.ai.AiStudyPlanResponse;
import com.studyflow.entity.User;

import java.util.List;

public interface AiStudyPlanningService {

    AiStudyPlanResponse generatePlanForCourse(Long courseId, List<Long> materialIds, User user);
}
