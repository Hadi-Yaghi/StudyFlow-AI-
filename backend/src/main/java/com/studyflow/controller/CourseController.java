package com.studyflow.controller;

import com.studyflow.dto.request.CourseCreateRequest;
import com.studyflow.dto.response.CourseResponse;
import com.studyflow.security.UserPrincipal;
import com.studyflow.service.CourseService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/courses")
@RequiredArgsConstructor
public class CourseController {

    private final CourseService courseService;

    @PostMapping
    public CourseResponse createCourse(
            @Valid @RequestBody CourseCreateRequest request,
            @AuthenticationPrincipal UserPrincipal userPrincipal) {

        return courseService.createCourse(
                userPrincipal.getUser().getId(),
                request
        );
    }
}