package com.studyflow.service;

import com.studyflow.dto.request.TaskCreateRequest;
import com.studyflow.dto.request.TaskUpdateRequest;
import com.studyflow.dto.response.TaskResponse;
import com.studyflow.entity.*;
import com.studyflow.exception.CourseNotFoundException;
import com.studyflow.exception.TaskNotFoundException;
import com.studyflow.exception.UserNotFoundException;
import com.studyflow.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TaskServiceTest {

    @Mock
    private TaskRepository taskRepository;

    @Mock
    private CourseRepository courseRepository;

    @Mock
    private SemesterRepository semesterRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private StudySessionRepository studySessionRepository;

    @InjectMocks
    private TaskService taskService;

    private User userA;
    private User userB;
    private Semester semesterA;
    private Semester semesterB;
    private Course courseA;
    private Course courseB;
    private Task taskA;

    @BeforeEach
    void setUp() {
        userA = User.builder().id(1L).email("userA@studyflow.com").name("User A").build();
        userB = User.builder().id(2L).email("userB@studyflow.com").name("User B").build();

        semesterA = Semester.builder().id(10L).user(userA).name("Fall 2026").active(true).build();
        semesterB = Semester.builder().id(20L).user(userB).name("Fall 2026").active(true).build();

        courseA = Course.builder().id(100L).semester(semesterA).name("Algorithms").code("CS301").color("#3525CD").creditHours(3).build();
        courseB = Course.builder().id(200L).semester(semesterB).name("Databases").code("CS302").color("#3525CD").creditHours(3).build();

        taskA = Task.builder()
                .id(500L)
                .title("Homework 1")
                .description("Initial description")
                .type(TaskType.ASSIGNMENT)
                .priority(TaskPriority.MEDIUM)
                .dueDate(LocalDate.of(2026, 10, 15))
                .estimatedHours(6)
                .completedHours(2)
                .status(TaskStatus.IN_PROGRESS)
                .course(courseA)
                .build();
    }

    @Test
    @DisplayName("Should successfully update task fields when requested by task owner")
    void updateTask_shouldSuccessfullyUpdateAllFields() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(userA));
        when(taskRepository.findById(500L)).thenReturn(Optional.of(taskA));
        when(taskRepository.save(any(Task.class))).thenAnswer(invocation -> invocation.getArgument(0));

        TaskUpdateRequest request = TaskUpdateRequest.builder()
                .title("Homework 1 - Revised")
                .description("Updated details")
                .type(TaskType.EXAM)
                .priority(TaskPriority.HIGH)
                .dueDate(LocalDate.of(2026, 10, 20))
                .estimatedHours(8)
                .completedHours(4)
                .status(TaskStatus.IN_PROGRESS)
                .courseId(100L)
                .build();

        TaskResponse response = taskService.updateTask(1L, 500L, request);

        assertNotNull(response);
        assertEquals("Homework 1 - Revised", response.getTitle());
        assertEquals("Updated details", response.getDescription());
        assertEquals(TaskType.EXAM, response.getType());
        assertEquals(TaskPriority.HIGH, response.getPriority());
        assertEquals(LocalDate.of(2026, 10, 20), response.getDueDate());
        assertEquals(8, response.getEstimatedHours());
        assertEquals(4, response.getCompletedHours());
        assertEquals(TaskStatus.IN_PROGRESS, response.getStatus());
        assertEquals(100L, response.getCourseId());

        verify(taskRepository).save(taskA);
    }

    @Test
    @DisplayName("Should deny update and throw IllegalArgumentException when User B tries to update User A's task")
    void updateTask_shouldThrowException_whenUserDoesNotOwnTask() {
        when(userRepository.findById(2L)).thenReturn(Optional.of(userB));
        when(taskRepository.findById(500L)).thenReturn(Optional.of(taskA));

        TaskUpdateRequest request = TaskUpdateRequest.builder()
                .title("Hacked Title")
                .type(TaskType.ASSIGNMENT)
                .priority(TaskPriority.LOW)
                .dueDate(LocalDate.of(2026, 10, 15))
                .estimatedHours(5)
                .courseId(100L)
                .build();

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () ->
                taskService.updateTask(2L, 500L, request)
        );

        assertEquals("You do not own this task", ex.getMessage());
        verify(taskRepository, never()).save(any());
    }

    @Test
    @DisplayName("Should deny reassigning task to a course belonging to another user")
    void updateTask_shouldThrowException_whenUserDoesNotOwnTargetCourse() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(userA));
        when(taskRepository.findById(500L)).thenReturn(Optional.of(taskA));
        when(courseRepository.findById(200L)).thenReturn(Optional.of(courseB));

        TaskUpdateRequest request = TaskUpdateRequest.builder()
                .title("Moving task")
                .type(TaskType.ASSIGNMENT)
                .priority(TaskPriority.LOW)
                .dueDate(LocalDate.of(2026, 10, 15))
                .estimatedHours(5)
                .courseId(200L)
                .build();

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () ->
                taskService.updateTask(1L, 500L, request)
        );

        assertEquals("You do not own the target course", ex.getMessage());
        verify(taskRepository, never()).save(any());
    }

    @Test
    @DisplayName("Should reject blank task title on update")
    void updateTask_shouldThrowException_whenTitleIsBlank() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(userA));
        when(taskRepository.findById(500L)).thenReturn(Optional.of(taskA));

        TaskUpdateRequest request = TaskUpdateRequest.builder()
                .title("   ")
                .type(TaskType.ASSIGNMENT)
                .priority(TaskPriority.LOW)
                .dueDate(LocalDate.of(2026, 10, 15))
                .estimatedHours(5)
                .courseId(100L)
                .build();

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () ->
                taskService.updateTask(1L, 500L, request)
        );

        assertTrue(ex.getMessage().contains("Task title cannot be blank"));
        verify(taskRepository, never()).save(any());
    }

    @Test
    @DisplayName("Should reject completed hours exceeding estimated hours on update")
    void updateTask_shouldThrowException_whenCompletedHoursExceedEstimatedHours() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(userA));
        when(taskRepository.findById(500L)).thenReturn(Optional.of(taskA));

        TaskUpdateRequest request = TaskUpdateRequest.builder()
                .title("Homework 1")
                .type(TaskType.ASSIGNMENT)
                .priority(TaskPriority.LOW)
                .dueDate(LocalDate.of(2026, 10, 15))
                .estimatedHours(4)
                .completedHours(6)
                .courseId(100L)
                .build();

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () ->
                taskService.updateTask(1L, 500L, request)
        );

        assertTrue(ex.getMessage().contains("Completed hours cannot exceed estimated hours"));
        verify(taskRepository, never()).save(any());
    }

    @Test
    @DisplayName("Should prune future planned sessions when due date is moved earlier")
    void updateTask_shouldPrunePlannedSessions_whenDueDateMovedEarlier() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(userA));
        when(taskRepository.findById(500L)).thenReturn(Optional.of(taskA));
        when(taskRepository.save(any(Task.class))).thenAnswer(invocation -> invocation.getArgument(0));

        LocalDate newEarlierDueDate = LocalDate.of(2026, 10, 10); // earlier than 2026-10-15
        TaskUpdateRequest request = TaskUpdateRequest.builder()
                .title("Homework 1")
                .type(TaskType.ASSIGNMENT)
                .priority(TaskPriority.MEDIUM)
                .dueDate(newEarlierDueDate)
                .estimatedHours(6)
                .completedHours(2)
                .status(TaskStatus.IN_PROGRESS)
                .courseId(100L)
                .build();

        taskService.updateTask(1L, 500L, request);

        // Verify planned sessions after new due date are pruned
        verify(studySessionRepository).deleteByTaskAndSessionDateAfterAndStatus(
                taskA,
                newEarlierDueDate,
                StudySessionStatus.PLANNED
        );
    }

    @Test
    @DisplayName("Should prune remaining planned sessions when task is marked COMPLETED")
    void updateTask_shouldPrunePlannedSessions_whenTaskMarkedCompleted() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(userA));
        when(taskRepository.findById(500L)).thenReturn(Optional.of(taskA));
        when(taskRepository.save(any(Task.class))).thenAnswer(invocation -> invocation.getArgument(0));

        TaskUpdateRequest request = TaskUpdateRequest.builder()
                .title("Homework 1")
                .type(TaskType.ASSIGNMENT)
                .priority(TaskPriority.MEDIUM)
                .dueDate(LocalDate.of(2026, 10, 15))
                .estimatedHours(6)
                .completedHours(6)
                .status(TaskStatus.COMPLETED)
                .courseId(100L)
                .build();

        taskService.updateTask(1L, 500L, request);

        verify(studySessionRepository).deleteByTaskAndStatus(taskA, StudySessionStatus.PLANNED);
    }

    @Test
    @DisplayName("Should delete study sessions first and then delete the task to preserve FK integrity")
    void deleteTask_shouldSuccessfullyDeleteTaskAndLinkedStudySessions() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(userA));
        when(taskRepository.findById(500L)).thenReturn(Optional.of(taskA));

        taskService.deleteTask(1L, 500L);

        // Verify sessions deleted and flushed before task deletion
        verify(studySessionRepository).deleteByTask(taskA);
        verify(studySessionRepository).flush();
        verify(taskRepository).delete(taskA);
    }

    @Test
    @DisplayName("Should deny delete when User B attempts to delete User A's task")
    void deleteTask_shouldThrowException_whenUserDoesNotOwnTask() {
        when(userRepository.findById(2L)).thenReturn(Optional.of(userB));
        when(taskRepository.findById(500L)).thenReturn(Optional.of(taskA));

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () ->
                taskService.deleteTask(2L, 500L)
        );

        assertEquals("You do not own this task", ex.getMessage());
        verify(studySessionRepository, never()).deleteByTask(any());
        verify(taskRepository, never()).delete(any());
    }

    @Test
    @DisplayName("Should throw TaskNotFoundException when deleting nonexistent task")
    void deleteTask_shouldThrowException_whenTaskNotFound() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(userA));
        when(taskRepository.findById(999L)).thenReturn(Optional.empty());

        assertThrows(TaskNotFoundException.class, () ->
                taskService.deleteTask(1L, 999L)
        );

        verify(studySessionRepository, never()).deleteByTask(any());
        verify(taskRepository, never()).delete(any());
    }

    @Test
    @DisplayName("Should successfully create task for all supported TaskType values including EXAM")
    void createTask_shouldSupportAllTaskTypes() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(userA));
        when(courseRepository.findById(100L)).thenReturn(Optional.of(courseA));
        when(taskRepository.save(any(Task.class))).thenAnswer(invocation -> invocation.getArgument(0));

        for (TaskType type : TaskType.values()) {
            TaskCreateRequest request = TaskCreateRequest.builder()
                    .title("Task of type " + type.name())
                    .description("Test description")
                    .type(type)
                    .priority(TaskPriority.HIGH)
                    .dueDate(LocalDate.of(2026, 11, 1))
                    .estimatedHours(3)
                    .courseId(100L)
                    .build();

            TaskResponse response = taskService.createTask(1L, request);
            assertNotNull(response);
            assertEquals(type, response.getType());
        }
    }
}
