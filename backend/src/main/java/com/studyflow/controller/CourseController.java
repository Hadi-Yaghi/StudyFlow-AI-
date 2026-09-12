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

    @GetMapping
    public java.util.List<CourseResponse> getUserCourses(
            @AuthenticationPrincipal UserPrincipal userPrincipal) {

        return courseService.getUserCourses(
                userPrincipal.getUser().getId()
        );
    }

    @GetMapping("/semester/{semesterId}")
    public java.util.List<CourseResponse> getSemesterCourses(
            @PathVariable Long semesterId,
            @AuthenticationPrincipal UserPrincipal userPrincipal) {

        return courseService.getSemesterCourses(
                userPrincipal.getUser().getId(),
                semesterId
        );
    }

    @GetMapping("/{courseId}")
    public CourseResponse getCourseById(
            @PathVariable Long courseId,
            @AuthenticationPrincipal UserPrincipal userPrincipal) {

        return courseService.getCourseById(
                userPrincipal.getUser().getId(),
                courseId
        );
    }
}