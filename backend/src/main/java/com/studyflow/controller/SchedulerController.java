package com.studyflow.controller;

import com.studyflow.scheduler.SchedulerResult;
import com.studyflow.scheduler.SchedulerService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/scheduler")
@RequiredArgsConstructor
public class SchedulerController {

    private final SchedulerService schedulerService;

    @PostMapping("/generate")
    public SchedulerResult generateSchedule(
            Authentication authentication
    ) {

        return schedulerService.generateSchedule(
                authentication.getName()
        );
    }
}