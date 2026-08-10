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

    @PostMapping("/generate")
    public SchedulerResult generateSchedule(
            Authentication authentication
    ) {

        return schedulerService.generateSchedule(
                authentication.getName()
        );
    }


}