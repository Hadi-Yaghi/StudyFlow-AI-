package com.studyflow.service;

import com.studyflow.dto.request.SemesterCreateRequest;
import com.studyflow.dto.response.SemesterResponse;
import com.studyflow.entity.Semester;
import com.studyflow.entity.User;
import com.studyflow.exception.UserNotFoundException;
import com.studyflow.repository.SemesterRepository;
import com.studyflow.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class SemesterService {

    private final SemesterRepository semesterRepository;
    private final UserRepository userRepository;

    public SemesterResponse createSemester(
            Long userId,
            SemesterCreateRequest request) {

        User user = userRepository.findById(userId)
                .orElseThrow(UserNotFoundException::new);

        if (semesterRepository.existsByUserAndNameIgnoreCase(
                user,
                request.getName())) {

            throw new IllegalArgumentException(
                    "Semester already exists");
        }

        if (request.getEndDate()
                .isBefore(request.getStartDate())) {
            throw new IllegalArgumentException(
                    "End date must be after start date");
        }

        boolean active =
                semesterRepository.findByUserAndActiveTrue(user)
                        .isEmpty();

        Semester semester = Semester.builder()
                .name(request.getName())
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .active(active)
                .user(user)
                .build();

        Semester saved =
                semesterRepository.save(semester);

        return SemesterResponse.builder()
                .id(saved.getId())
                .name(saved.getName())
                .startDate(saved.getStartDate())
                .endDate(saved.getEndDate())
                .active(saved.isActive())
                .build();
    }
}