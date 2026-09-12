package com.studyflow.service;

import com.studyflow.dto.request.CourseCreateRequest;
import com.studyflow.dto.response.CourseResponse;
import com.studyflow.entity.Course;
import com.studyflow.entity.Semester;
import com.studyflow.entity.User;
import com.studyflow.exception.SemesterNotFoundException;
import com.studyflow.exception.UserNotFoundException;
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
                .orElseThrow(UserNotFoundException::new);

        Semester semester = semesterRepository.findById(request.getSemesterId())
                .orElseThrow(SemesterNotFoundException::new);

        if (!semester.getUser().getId().equals(user.getId())) {
            throw new RuntimeException("You do not own this semester");
        }

        if (courseRepository.existsBySemesterAndNameIgnoreCase(
                semester,
                request.getName())) {

            throw new IllegalArgumentException(
                    "Course already exists");
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

    public java.util.List<CourseResponse> getUserCourses(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(UserNotFoundException::new);

        java.util.List<Semester> semesters = semesterRepository.findByUser(user);
        if (semesters.isEmpty()) {
            return java.util.Collections.emptyList();
        }

        return courseRepository.findBySemesterIn(semesters)
                .stream()
                .map(this::mapToResponse)
                .toList();
    }

    public java.util.List<CourseResponse> getSemesterCourses(Long userId, Long semesterId) {
        User user = userRepository.findById(userId)
                .orElseThrow(UserNotFoundException::new);

        Semester semester = semesterRepository.findById(semesterId)
                .orElseThrow(SemesterNotFoundException::new);

        if (!semester.getUser().getId().equals(user.getId())) {
            throw new RuntimeException("You do not own this semester");
        }

        return courseRepository.findBySemester(semester)
                .stream()
                .map(this::mapToResponse)
                .toList();
    }

    public CourseResponse getCourseById(Long userId, Long courseId) {
        User user = userRepository.findById(userId)
                .orElseThrow(UserNotFoundException::new);

        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new RuntimeException("Course not found"));

        if (!course.getSemester().getUser().getId().equals(user.getId())) {
            throw new RuntimeException("You do not own this course");
        }

        return mapToResponse(course);
    }

    private CourseResponse mapToResponse(Course course) {
        return CourseResponse.builder()
                .id(course.getId())
                .name(course.getName())
                .code(course.getCode())
                .instructor(course.getInstructor())
                .creditHours(course.getCreditHours())
                .color(course.getColor())
                .semesterId(course.getSemester().getId())
                .build();
    }
}