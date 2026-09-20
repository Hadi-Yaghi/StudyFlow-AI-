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

    @GetMapping
    public java.util.List<TaskResponse> getUserTasks(
            @AuthenticationPrincipal UserPrincipal userPrincipal) {

        return taskService.getUserTasks(
                userPrincipal.getUser().getId()
        );
    }

    @GetMapping("/course/{courseId}")
    public java.util.List<TaskResponse> getCourseTasks(
            @PathVariable Long courseId,
            @AuthenticationPrincipal UserPrincipal userPrincipal) {

        return taskService.getCourseTasks(
                userPrincipal.getUser().getId(),
                courseId
        );
    }

    @GetMapping("/{taskId}")
    public TaskResponse getTaskById(
            @PathVariable Long taskId,
            @AuthenticationPrincipal UserPrincipal userPrincipal) {

        return taskService.getTaskById(
                userPrincipal.getUser().getId(),
                taskId
        );
    }

    @PatchMapping("/{taskId}/status")
    public TaskResponse updateTaskStatus(
            @PathVariable Long taskId,
            @RequestParam com.studyflow.entity.TaskStatus status,
            @AuthenticationPrincipal UserPrincipal userPrincipal) {

        return taskService.updateTaskStatus(
                userPrincipal.getUser().getId(),
                taskId,
                status
        );
    }

    @PutMapping("/{taskId}")
    public TaskResponse updateTask(
            @PathVariable Long taskId,
            @Valid @RequestBody com.studyflow.dto.request.TaskUpdateRequest request,
            @AuthenticationPrincipal UserPrincipal userPrincipal) {

        return taskService.updateTask(
                userPrincipal.getUser().getId(),
                taskId,
                request
        );
    }

    @DeleteMapping("/{taskId}")
    public org.springframework.http.ResponseEntity<java.util.Map<String, String>> deleteTask(
            @PathVariable Long taskId,
            @AuthenticationPrincipal UserPrincipal userPrincipal) {

        taskService.deleteTask(
                userPrincipal.getUser().getId(),
                taskId
        );

        return org.springframework.http.ResponseEntity.ok(
                java.util.Map.of("message", "Task deleted successfully")
        );
    }
}