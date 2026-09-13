package com.studyflow.service.impl;

import com.studyflow.dto.availability.AvailabilityRequest;
import com.studyflow.dto.availability.AvailabilityResponse;
import com.studyflow.entity.Availability;
import com.studyflow.entity.User;
import com.studyflow.exception.ResourceAlreadyExistsException;
import com.studyflow.exception.UserNotFoundException;
import com.studyflow.repository.AvailabilityRepository;
import com.studyflow.repository.UserRepository;
import com.studyflow.service.AvailabilityService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional
public class AvailabilityServiceImpl implements AvailabilityService {

    private final AvailabilityRepository availabilityRepository;
    private final UserRepository userRepository;

    @Override
    public AvailabilityResponse createAvailability(
            String email,
            AvailabilityRequest request
    ) {

        User user = userRepository.findByEmail(email)
                .orElseThrow(UserNotFoundException::new);

        Availability availability = availabilityRepository
                .findByUserAndDay(user, request.getDay())
                .orElseGet(() -> Availability.builder()
                        .user(user)
                        .day(request.getDay())
                        .build());

        availability.setStartTime(request.getStartTime());
        availability.setEndTime(request.getEndTime());
        availability.setEnabled(request.getEnabled());

        Availability saved = availabilityRepository.save(availability);

        return AvailabilityResponse.builder()
                .id(saved.getId())
                .day(saved.getDay())
                .startTime(saved.getStartTime())
                .endTime(saved.getEndTime())
                .enabled(saved.isEnabled())
                .build();
    }

    @Override
    public List<AvailabilityResponse> getUserAvailability(
            String email
    ) {

        User user = userRepository.findByEmail(email)
                .orElseThrow(UserNotFoundException::new);

        return availabilityRepository.findByUser(user)
                .stream()
                .map(a -> AvailabilityResponse.builder()
                        .id(a.getId())
                        .day(a.getDay())
                        .startTime(a.getStartTime())
                        .endTime(a.getEndTime())
                        .enabled(a.isEnabled())
                        .build())
                .toList();
    }
}