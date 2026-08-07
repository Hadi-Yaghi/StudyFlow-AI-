package com.studyflow.service;

import com.studyflow.dto.request.TaskCreateRequest;
import com.studyflow.dto.response.TaskResponse;
import com.studyflow.entity.Course;
import com.studyflow.entity.Task;
import com.studyflow.entity.User;
import com.studyflow.repository.CourseRepository;
import com.studyflow.repository.TaskRepository;
import com.studyflow.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class TaskService {

    private final TaskRepository taskRepository;
    private final CourseRepository courseRepository;
    private final UserRepository userRepository;

    public TaskResponse createTask(
            Long userId,
            TaskCreateRequest request) {

        User user = userRepository.findById(userId)
                .orElseThrow(() ->
                        new RuntimeException("User not found"));

        Course course = courseRepository.findById(request.getCourseId())
                .orElseThrow(() ->
                        new RuntimeException("Course not found"));

        if (!course.getSemester().getUser().getId().equals(user.getId())) {
            throw new RuntimeException("You do not own this course");
        }

        if (taskRepository.existsByCourseAndTitleIgnoreCase(
                course,
                request.getTitle())) {

            throw new RuntimeException("Task already exists");
        }

        Task task = Task.builder()
                .title(request.getTitle())
                .description(request.getDescription())
                .type(request.getType())
                .priority(request.getPriority())
                .dueDate(request.getDueDate())
                .estimatedHours(request.getEstimatedHours())
                .completed(false)
                .course(course)
                .build();

        Task saved = taskRepository.save(task);

        return TaskResponse.builder()
                .id(saved.getId())
                .title(saved.getTitle())
                .description(saved.getDescription())
                .type(saved.getType())
                .priority(saved.getPriority())
                .dueDate(saved.getDueDate())
                .estimatedHours(saved.getEstimatedHours())
                .completed(saved.isCompleted())
                .courseId(saved.getCourse().getId())
                .build();
    }
}