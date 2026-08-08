package com.studyflow.service;

import com.studyflow.dto.availability.AvailabilityRequest;
import com.studyflow.dto.availability.AvailabilityResponse;

import java.util.List;

public interface AvailabilityService {

    AvailabilityResponse createAvailability(
            String email,
            AvailabilityRequest request
    );

    List<AvailabilityResponse> getUserAvailability(
            String email
    );
}