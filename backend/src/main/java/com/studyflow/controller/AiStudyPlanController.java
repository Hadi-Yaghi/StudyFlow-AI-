package com.studyflow.controller;

import com.studyflow.dto.ai.AiPlanRequest;
import com.studyflow.dto.ai.AiStudyPlanResponse;
import com.studyflow.entity.User;
import com.studyflow.exception.UserNotFoundException;
import com.studyflow.repository.UserRepository;
import com.studyflow.service.ai.AiStudyPlanningService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/ai")
@RequiredArgsConstructor
public class AiStudyPlanController {

    private final AiStudyPlanningService aiStudyPlanningService;
    private final UserRepository userRepository;

    @PostMapping("/courses/{courseId}/plan")
    public ResponseEntity<AiStudyPlanResponse> generatePlan(
            @PathVariable Long courseId,
            @RequestBody(required = false) AiPlanRequest request,
            Authentication authentication
    ) {
        User user = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new UserNotFoundException("User not found: " + authentication.getName()));

        List<Long> materialIds = request != null ? request.getMaterialIds() : null;
        AiStudyPlanResponse response = aiStudyPlanningService.generatePlanForCourse(courseId, materialIds, user);

        return ResponseEntity.ok(response);
    }
}
