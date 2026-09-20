package com.studyflow.controller;

import com.studyflow.scheduler.SchedulerResult;
import com.studyflow.scheduler.SchedulerService;
import com.studyflow.service.MissedSessionReschedulingService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/scheduler")
@RequiredArgsConstructor
public class SchedulerController {

    private final SchedulerService schedulerService;
    private final MissedSessionReschedulingService missedSessionReschedulingService;
    private final com.studyflow.service.ScheduleUsageService scheduleUsageService;
    private final com.studyflow.service.SubscriptionService subscriptionService;
    private final com.studyflow.repository.UserRepository userRepository;

    @PostMapping("/generate")
    public SchedulerResult generateSchedule(
            Authentication authentication
    ) {
        return schedulerService.generateSchedule(
                authentication.getName()
        );
    }

    @GetMapping("/usage")
    public org.springframework.http.ResponseEntity<com.studyflow.dto.response.ScheduleUsageResponse> getUsage(
            Authentication authentication
    ) {
        com.studyflow.entity.User user = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new com.studyflow.exception.UserNotFoundException("User not found: " + authentication.getName()));
        boolean isPro = subscriptionService.isPro(user);
        return org.springframework.http.ResponseEntity.ok(
                scheduleUsageService.getUsageSummary(user, isPro)
        );
    }


}