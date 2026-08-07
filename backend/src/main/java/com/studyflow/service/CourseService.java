package com.studyflow.service;

import com.studyflow.dto.request.CourseCreateRequest;
import com.studyflow.dto.response.CourseResponse;
import com.studyflow.entity.Course;
import com.studyflow.entity.Semester;
import com.studyflow.entity.User;
import com.studyflow.repository.CourseRepository;
import com.studyflow.repository.SemesterRepository;
import com.studyflow.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class CourseService {

    private final CourseRepository courseRepository;
    private final SemesterRepository semesterRepository;
    private final UserRepository userRepository;

    public CourseResponse createCourse(
            Long userId,
            CourseCreateRequest request) {

        User user = userRepository.findById(userId)
                .orElseThrow(() ->
                        new RuntimeException("User not found"));

        Semester semester = semesterRepository.findById(request.getSemesterId())
                .orElseThrow(() ->
                        new RuntimeException("Semester not found"));

        if (!semester.getUser().getId().equals(user.getId())) {
            throw new RuntimeException("You do not own this semester");
        }

        if (courseRepository.existsBySemesterAndNameIgnoreCase(
                semester,
                request.getName())) {

            throw new RuntimeException("Course already exists");
        }

        Course course = Course.builder()
                .name(request.getName())
                .code(request.getCode())
                .instructor(request.getInstructor())
                .creditHours(request.getCreditHours())
                .color(request.getColor())
                .semester(semester)
                .build();

        Course saved = courseRepository.save(course);

        return CourseResponse.builder()
                .id(saved.getId())
                .name(saved.getName())
                .code(saved.getCode())
                .instructor(saved.getInstructor())
                .creditHours(saved.getCreditHours())
                .color(saved.getColor())
                .semesterId(saved.getSemester().getId())
                .build();
    }
}