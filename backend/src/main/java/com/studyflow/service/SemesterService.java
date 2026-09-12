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

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

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

        // Reuse existing semester if one exists with the same name (case-insensitive)
        Optional<Semester> existing = semesterRepository.findByUserAndNameIgnoreCase(
                user,
                request.getName());
        if (existing.isPresent()) {
            return mapToResponse(existing.get());
        }

        LocalDate today = LocalDate.now();

        if (request.getEndDate().isBefore(request.getStartDate()) ||
                request.getEndDate().isEqual(request.getStartDate())) {
            throw new IllegalArgumentException(
                    "End date must be after start date");
        }

        if (request.getEndDate().isBefore(today)) {
            throw new IllegalArgumentException(
                    "End date cannot be in the past");
        }

        // Active if today is within [startDate, endDate], or if user has no active semester
        boolean isCurrent = !request.getStartDate().isAfter(today) && !request.getEndDate().isBefore(today);
        Optional<Semester> currentActiveOpt = semesterRepository.findByUserAndActiveTrue(user);

        boolean active = currentActiveOpt.isEmpty() || isCurrent;

        if (active && currentActiveOpt.isPresent()) {
            Semester prevActive = currentActiveOpt.get();
            prevActive.setActive(false);
            semesterRepository.save(prevActive);
        }

        Semester semester = Semester.builder()
                .name(request.getName())
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .active(active)
                .user(user)
                .build();

        Semester saved = semesterRepository.save(semester);

        return mapToResponse(saved);
    }

    public java.util.List<SemesterResponse> getUserSemesters(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(UserNotFoundException::new);

        return semesterRepository.findByUser(user)
                .stream()
                .map(this::mapToResponse)
                .toList();
    }

    public SemesterResponse getActiveSemester(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(UserNotFoundException::new);

        return semesterRepository.findByUserAndActiveTrue(user)
                .map(this::mapToResponse)
                .orElse(null);
    }

    private SemesterResponse mapToResponse(Semester semester) {
        return SemesterResponse.builder()
                .id(semester.getId())
                .name(semester.getName())
                .startDate(semester.getStartDate())
                .endDate(semester.getEndDate())
                .active(semester.isActive())
                .build();
    }
}