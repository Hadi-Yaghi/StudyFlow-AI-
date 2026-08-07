package com.studyflow.controller;

import com.studyflow.dto.request.TaskCreateRequest;
import com.studyflow.dto.response.TaskResponse;
import com.studyflow.security.UserPrincipal;
import com.studyflow.service.TaskService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/tasks")
@RequiredArgsConstructor
public class TaskController {

    private final TaskService taskService;

    @PostMapping
    public TaskResponse createTask(
            @Valid @RequestBody TaskCreateRequest request,
            @AuthenticationPrincipal UserPrincipal userPrincipal) {

        return taskService.createTask(
                userPrincipal.getUser().getId(),
                request
        );
    }
}