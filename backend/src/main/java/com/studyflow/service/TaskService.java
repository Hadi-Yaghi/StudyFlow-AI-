package com.studyflow.service;

import com.studyflow.dto.request.TaskCreateRequest;
import com.studyflow.dto.response.TaskResponse;
import com.studyflow.entity.Course;
import com.studyflow.entity.Task;
import com.studyflow.entity.TaskStatus;
import com.studyflow.entity.User;
import com.studyflow.entity.Semester;
import com.studyflow.exception.CourseNotFoundException;
import com.studyflow.exception.UserNotFoundException;
import com.studyflow.repository.CourseRepository;
import com.studyflow.repository.SemesterRepository;
import com.studyflow.repository.TaskRepository;
import com.studyflow.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class TaskService {

    private final TaskRepository taskRepository;
    private final CourseRepository courseRepository;
    private final SemesterRepository semesterRepository;
    private final UserRepository userRepository;

    public TaskResponse createTask(
            Long userId,
            TaskCreateRequest request) {

        User user = userRepository.findById(userId)
                .orElseThrow(UserNotFoundException::new);

        Course course = courseRepository.findById(request.getCourseId())
                .orElseThrow(CourseNotFoundException::new);

        if (!course.getSemester().getUser().getId().equals(user.getId())) {
            throw new IllegalArgumentException(
                    "You do not own this course");
        }

        if (taskRepository.existsByCourseAndTitleIgnoreCase(
                course,
                request.getTitle())) {

            throw new IllegalArgumentException(
                    "Task already exists");
        }

        Task task = Task.builder()
                .title(request.getTitle())
                .description(request.getDescription())
                .type(request.getType())
                .priority(request.getPriority())
                .dueDate(request.getDueDate())
                .estimatedHours(request.getEstimatedHours())
                .completedHours(0)
                .status(TaskStatus.TODO)
                .course(course)
                .build();

        Task saved = taskRepository.save(task);

        return mapToResponse(saved);
    }

    public java.util.List<TaskResponse> getUserTasks(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(UserNotFoundException::new);

        java.util.List<Semester> semesters = semesterRepository.findByUser(user);
        if (semesters.isEmpty()) {
            return java.util.Collections.emptyList();
        }

        java.util.List<Course> courses = courseRepository.findBySemesterIn(semesters);
        if (courses.isEmpty()) {
            return java.util.Collections.emptyList();
        }

        return taskRepository.findByCourseIn(courses)
                .stream()
                .map(this::mapToResponse)
                .toList();
    }

    public java.util.List<TaskResponse> getCourseTasks(Long userId, Long courseId) {
        User user = userRepository.findById(userId)
                .orElseThrow(UserNotFoundException::new);

        Course course = courseRepository.findById(courseId)
                .orElseThrow(CourseNotFoundException::new);

        if (!course.getSemester().getUser().getId().equals(user.getId())) {
            throw new IllegalArgumentException(
                    "You do not own this course");
        }

        return taskRepository.findByCourse(course)
                .stream()
                .map(this::mapToResponse)
                .toList();
    }

    public TaskResponse getTaskById(Long userId, Long taskId) {
        User user = userRepository.findById(userId)
                .orElseThrow(UserNotFoundException::new);

        Task task = taskRepository.findById(taskId)
                .orElseThrow(() -> new RuntimeException("Task not found"));

        if (!task.getCourse().getSemester().getUser().getId().equals(user.getId())) {
            throw new IllegalArgumentException(
                    "You do not own this task");
        }

        return mapToResponse(task);
    }

    public TaskResponse updateTaskStatus(Long userId, Long taskId, TaskStatus status) {
        User user = userRepository.findById(userId)
                .orElseThrow(UserNotFoundException::new);

        Task task = taskRepository.findById(taskId)
                .orElseThrow(() -> new RuntimeException("Task not found"));

        if (!task.getCourse().getSemester().getUser().getId().equals(user.getId())) {
            throw new IllegalArgumentException(
                    "You do not own this task");
        }

        task.setStatus(status);
        Task updated = taskRepository.save(task);
        return mapToResponse(updated);
    }

    private TaskResponse mapToResponse(Task task) {
        return TaskResponse.builder()
                .id(task.getId())
                .title(task.getTitle())
                .description(task.getDescription())
                .type(task.getType())
                .priority(task.getPriority())
                .dueDate(task.getDueDate())
                .estimatedHours(task.getEstimatedHours())
                .completedHours(task.getCompletedHours())
                .status(task.getStatus())
                .courseId(task.getCourse().getId())
                .build();
    }
}