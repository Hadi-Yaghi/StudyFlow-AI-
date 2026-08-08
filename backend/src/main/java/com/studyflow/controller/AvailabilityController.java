package com.studyflow.controller;

import com.studyflow.dto.availability.AvailabilityRequest;
import com.studyflow.dto.availability.AvailabilityResponse;
import com.studyflow.service.AvailabilityService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/availability")
@RequiredArgsConstructor
public class AvailabilityController {

    private final AvailabilityService availabilityService;

    @PostMapping
    public AvailabilityResponse createAvailability(
            Authentication authentication,
            @Valid @RequestBody AvailabilityRequest request
    ) {

        return availabilityService.createAvailability(
                authentication.getName(),
                request
        );
    }

    @GetMapping
    public List<AvailabilityResponse> getAvailability(
            Authentication authentication
    ) {

        return availabilityService.getUserAvailability(
                authentication.getName()
        );
    }
}