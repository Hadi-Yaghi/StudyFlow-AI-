package com.studyflow.service;

import com.studyflow.dto.ai.AiStudyPlanResponse;
import com.studyflow.dto.ai.AiTopicRecommendation;
import com.studyflow.entity.*;
import com.studyflow.exception.PremiumRequiredException;
import com.studyflow.repository.CourseMaterialRepository;
import com.studyflow.repository.CourseRepository;
import com.studyflow.repository.TaskRepository;
import com.studyflow.scheduler.SchedulerResult;
import com.studyflow.scheduler.SchedulerService;
import com.studyflow.service.ai.AiClient;
import com.studyflow.service.ai.impl.AiStudyPlanningServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AiStudyPlanningIntegrationTest {

    @Mock
    private CourseRepository courseRepository;

    @Mock
    private CourseMaterialRepository materialRepository;

    @Mock
    private TaskRepository taskRepository;

    @Mock
    private SubscriptionService subscriptionService;

    @Mock
    private ScheduleUsageService scheduleUsageService;

    @Mock
    private SchedulerService schedulerService;

    @Mock
    private AiClient aiClient;

    @InjectMocks
    private AiStudyPlanningServiceImpl aiStudyPlanningService;

    private User testUser;
    private Course testCourse;
    private CourseMaterial testMaterial;

    @BeforeEach
    void setUp() {
        testUser = User.builder()
                .id(1L)
                .email("pro@studyflow.com")
                .name("Pro Student")
                .build();

        Semester semester = Semester.builder()
                .id(10L)
                .user(testUser)
                .name("Fall 2026")
                .active(true)
                .build();

        testCourse = Course.builder()
                .id(100L)
                .semester(semester)
                .name("Algorithms")
                .code("CS301")
                .color("#3525CD")
                .creditHours(3)
                .build();

        testMaterial = CourseMaterial.builder()
                .id(50L)
                .course(testCourse)
                .user(testUser)
                .originalFilename("syllabus.pdf")
                .extractedText("Chapter 1: Intro to Divide & Conquer. Chapter 2: Dynamic Programming.")
                .build();
    }

    @Test
    void generatePlanForCourse_shouldThrowPremiumRequired_whenUserIsNotPro() {
        when(subscriptionService.isPro(testUser)).thenReturn(false);

        assertThrows(PremiumRequiredException.class, () ->
                aiStudyPlanningService.generatePlanForCourse(100L, null, testUser)
        );

        verify(aiClient, never()).analyzeCourseContent(any(), any(), any(), any(), any());
    }

    @Test
    void generatePlanForCourse_shouldTranslateTopicsIntoTasksAndTriggerScheduler() {
        when(subscriptionService.isPro(testUser)).thenReturn(true);
        when(courseRepository.findById(100L)).thenReturn(Optional.of(testCourse));
        when(materialRepository.findByCourseAndUserOrderByUploadedAtDesc(testCourse, testUser))
                .thenReturn(List.of(testMaterial));
        when(taskRepository.findByCourse(testCourse)).thenReturn(List.of());

        List<AiTopicRecommendation> topics = List.of(
                AiTopicRecommendation.builder()
                        .title("Divide and Conquer")
                        .estimatedMinutes(90)
                        .priority("HIGH")
                        .suggestedDeadline(LocalDate.now().plusDays(3))
                        .keyConcepts(List.of("MergeSort", "Master Theorem"))
                        .build(),
                AiTopicRecommendation.builder()
                        .title("Dynamic Programming")
                        .estimatedMinutes(120)
                        .priority("HIGH")
                        .suggestedDeadline(LocalDate.now().plusDays(5))
                        .keyConcepts(List.of("Memoization", "Tabulation"))
                        .build()
        );

        AiClient.AiAnalysisResult aiResult = new AiClient.AiAnalysisResult(
                "Focus on core algorithmic paradigms.",
                topics,
                150,
                80
        );

        when(aiClient.analyzeCourseContent(eq(testUser), eq("Algorithms"), eq("CS301"), anyString(), anyList()))
                .thenReturn(aiResult);

        when(taskRepository.save(any(Task.class))).thenAnswer(i -> {
            Task t = i.getArgument(0);
            t.setId(99L);
            return t;
        });

        SchedulerResult schedulerResult = SchedulerResult.builder()
                .generatedSessions(4)
                .scheduledMinutes(210)
                .sessionDates(List.of(LocalDate.now().plusDays(1), LocalDate.now().plusDays(2)))
                .status("SUCCESS")
                .message("4 sessions scheduled")
                .build();

        when(schedulerService.generateSchedule(testUser.getEmail())).thenReturn(schedulerResult);

        AiStudyPlanResponse response = aiStudyPlanningService.generatePlanForCourse(100L, null, testUser);

        assertNotNull(response);
        assertTrue(response.isSuccessful());
        assertEquals(2, response.getTopics().size());
        assertEquals(4, response.getGeneratedSessionsCount());
        assertEquals(210, response.getScheduledMinutes());

        // Verify task creation
        verify(taskRepository, times(2)).save(any(Task.class));
        // Verify deterministic scheduler was called
        verify(schedulerService).generateSchedule(testUser.getEmail());
        // Verify usage recorded
        verify(scheduleUsageService).recordGenerationUsage(eq(testUser), eq(ScheduleGenerationType.AI), eq(true), eq(4), anyString());
    }
}
