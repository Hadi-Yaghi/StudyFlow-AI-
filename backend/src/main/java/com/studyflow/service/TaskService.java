package com.studyflow.service;

import com.studyflow.dto.request.TaskCreateRequest;
import com.studyflow.dto.request.TaskUpdateRequest;
import com.studyflow.dto.response.TaskResponse;
import com.studyflow.entity.*;
import com.studyflow.exception.CourseNotFoundException;
import com.studyflow.exception.TaskNotFoundException;
import com.studyflow.exception.UserNotFoundException;
import com.studyflow.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class TaskService {

    private final TaskRepository taskRepository;
    private final CourseRepository courseRepository;
    private final SemesterRepository semesterRepository;
    private final UserRepository userRepository;
    private final StudySessionRepository studySessionRepository;

    @Transactional
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
                .orElseThrow(TaskNotFoundException::new);

        if (!task.getCourse().getSemester().getUser().getId().equals(user.getId())) {
            throw new IllegalArgumentException(
                    "You do not own this task");
        }

        return mapToResponse(task);
    }

    @Transactional
    public TaskResponse updateTaskStatus(Long userId, Long taskId, TaskStatus status) {
        User user = userRepository.findById(userId)
                .orElseThrow(UserNotFoundException::new);

        Task task = taskRepository.findById(taskId)
                .orElseThrow(TaskNotFoundException::new);

        if (!task.getCourse().getSemester().getUser().getId().equals(user.getId())) {
            throw new IllegalArgumentException(
                    "You do not own this task");
        }

        if (status == TaskStatus.COMPLETED && task.getStatus() != TaskStatus.COMPLETED) {
            // Remove remaining PLANNED study sessions
            studySessionRepository.deleteByTaskAndStatus(task, StudySessionStatus.PLANNED);
        }

        task.setStatus(status);
        Task updated = taskRepository.save(task);
        return mapToResponse(updated);
    }

    @Transactional
    public TaskResponse updateTask(
            Long userId,
            Long taskId,
            TaskUpdateRequest request) {

        User user = userRepository.findById(userId)
                .orElseThrow(UserNotFoundException::new);

        Task task = taskRepository.findById(taskId)
                .orElseThrow(TaskNotFoundException::new);

        if (!task.getCourse().getSemester().getUser().getId().equals(user.getId())) {
            throw new IllegalArgumentException("You do not own this task");
        }

        if (request.getTitle() == null || request.getTitle().trim().isEmpty()) {
            throw new IllegalArgumentException("Task title cannot be blank");
        }

        Course targetCourse = task.getCourse();
        if (request.getCourseId() != null && !request.getCourseId().equals(task.getCourse().getId())) {
            targetCourse = courseRepository.findById(request.getCourseId())
                    .orElseThrow(CourseNotFoundException::new);

            if (!targetCourse.getSemester().getUser().getId().equals(user.getId())) {
                throw new IllegalArgumentException("You do not own the target course");
            }
            task.setCourse(targetCourse);
        }

        boolean titleChanged = !task.getTitle().equalsIgnoreCase(request.getTitle().trim());
        boolean courseChanged = !targetCourse.getId().equals(task.getCourse().getId());
        if ((titleChanged || courseChanged) &&
                taskRepository.existsByCourseAndTitleIgnoreCase(targetCourse, request.getTitle().trim())) {
            throw new IllegalArgumentException("A task with this title already exists in this course");
        }

        if (request.getEstimatedHours() == null || request.getEstimatedHours() <= 0) {
            throw new IllegalArgumentException("Estimated hours must be at least 1");
        }

        int completedHours = request.getCompletedHours() != null ? request.getCompletedHours() : task.getCompletedHours();
        if (completedHours < 0) {
            throw new IllegalArgumentException("Completed hours cannot be negative");
        }
        if (completedHours > request.getEstimatedHours()) {
            throw new IllegalArgumentException("Completed hours cannot exceed estimated hours");
        }

        if (request.getDueDate() == null) {
            throw new IllegalArgumentException("Due date is required");
        }

        TaskStatus newStatus = request.getStatus() != null ? request.getStatus() : task.getStatus();

        // Reconcile PLANNED study sessions if new due date is earlier
        java.time.LocalDate oldDueDate = task.getDueDate();
        java.time.LocalDate newDueDate = request.getDueDate();
        if (oldDueDate != null && newDueDate.isBefore(oldDueDate)) {
            studySessionRepository.deleteByTaskAndSessionDateAfterAndStatus(
                    task,
                    newDueDate,
                    StudySessionStatus.PLANNED
            );
        }

        // If marked COMPLETED, remove remaining PLANNED sessions
        if (newStatus == TaskStatus.COMPLETED && task.getStatus() != TaskStatus.COMPLETED) {
            studySessionRepository.deleteByTaskAndStatus(
                    task,
                    StudySessionStatus.PLANNED
            );
        }

        task.setTitle(request.getTitle().trim());
        task.setDescription(request.getDescription() != null ? request.getDescription().trim() : "");
        task.setType(request.getType());
        task.setPriority(request.getPriority());
        task.setDueDate(newDueDate);
        task.setEstimatedHours(request.getEstimatedHours());
        task.setCompletedHours(completedHours);
        task.setStatus(newStatus);

        Task saved = taskRepository.save(task);
        return mapToResponse(saved);
    }

    @Transactional
    public void deleteTask(Long userId, Long taskId) {
        User user = userRepository.findById(userId)
                .orElseThrow(UserNotFoundException::new);

        Task task = taskRepository.findById(taskId)
                .orElseThrow(TaskNotFoundException::new);

        if (!task.getCourse().getSemester().getUser().getId().equals(user.getId())) {
            throw new IllegalArgumentException("You do not own this task");
        }

        // Remove linked study sessions to maintain referential integrity
        studySessionRepository.deleteByTask(task);
        studySessionRepository.flush();

        taskRepository.delete(task);
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