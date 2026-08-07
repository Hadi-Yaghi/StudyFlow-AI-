package com.studyflow.controller;

import com.studyflow.dto.request.SemesterCreateRequest;
import com.studyflow.dto.response.SemesterResponse;
import com.studyflow.security.UserPrincipal;
import com.studyflow.service.SemesterService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/semesters")
@RequiredArgsConstructor
public class SemesterController {

    private final SemesterService semesterService;

    @PostMapping
    public SemesterResponse createSemester(
            @Valid @RequestBody SemesterCreateRequest request,
            @AuthenticationPrincipal UserPrincipal userPrincipal) {

        return semesterService.createSemester(
                userPrincipal.getUser().getId(),
                request
        );
    }
}