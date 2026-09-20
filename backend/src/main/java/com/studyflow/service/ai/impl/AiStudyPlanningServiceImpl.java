package com.studyflow.service.ai.impl;

import com.studyflow.dto.ai.AiStudyPlanResponse;
import com.studyflow.dto.ai.AiTopicRecommendation;
import com.studyflow.entity.*;
import com.studyflow.exception.CourseNotFoundException;
import com.studyflow.exception.PremiumRequiredException;
import com.studyflow.repository.CourseMaterialRepository;
import com.studyflow.repository.CourseRepository;
import com.studyflow.repository.TaskRepository;
import com.studyflow.scheduler.SchedulerResult;
import com.studyflow.scheduler.SchedulerService;
import com.studyflow.service.ScheduleUsageService;
import com.studyflow.service.SubscriptionService;
import com.studyflow.service.ai.AiClient;
import com.studyflow.service.ai.AiStudyPlanningService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class AiStudyPlanningServiceImpl implements AiStudyPlanningService {

    private final CourseRepository courseRepository;
    private final CourseMaterialRepository materialRepository;
    private final TaskRepository taskRepository;
    private final SubscriptionService subscriptionService;
    private final ScheduleUsageService scheduleUsageService;
    private final SchedulerService schedulerService;
    private final AiClient aiClient;

    @Override
    @Transactional
    public AiStudyPlanResponse generatePlanForCourse(Long courseId, List<Long> materialIds, User user) {
        log.info("Starting AI study plan generation for course {} by user {}", courseId, user.getEmail());

        // 1. Authoritative Backend Check: User MUST have active StudyFlow Pro entitlement
        if (!subscriptionService.isPro(user)) {
            log.warn("Unauthorized AI study plan attempt by non-Pro user: {}", user.getEmail());
            throw new PremiumRequiredException(
                    "AI Study Planning is a StudyFlow Pro feature. Upgrade to Pro to use AI study planning."
            );
        }

        // 2. Course Ownership Verification
        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new CourseNotFoundException("Course not found with id: " + courseId));

        if (course.getSemester() == null ||
                course.getSemester().getUser() == null ||
                !course.getSemester().getUser().getId().equals(user.getId())) {
            log.warn("Access denied: User {} tried to generate AI plan for course {} owned by another user",
                    user.getId(), courseId);
            throw new CourseNotFoundException("Course not found with id: " + courseId);
        }

        // 3. Gather Course Materials
        List<CourseMaterial> materials;
        if (materialIds != null && !materialIds.isEmpty()) {
            materials = new ArrayList<>();
            for (Long mId : materialIds) {
                materialRepository.findByIdAndUser(mId, user).ifPresent(materials::add);
            }
        } else {
            materials = materialRepository.findByCourseAndUserOrderByUploadedAtDesc(course, user);
        }

        if (materials.isEmpty()) {
            throw new IllegalArgumentException(
                    "No course materials found for this course. Please upload a course syllabus, notes, or slides first."
            );
        }

        // 4. Combine Extracted Text Content
        StringBuilder combinedText = new StringBuilder();
        for (CourseMaterial material : materials) {
            String text = material.getExtractedText();
            if (text != null && !text.isBlank()) {
                combinedText.append("=== Material: ").append(material.getOriginalFilename()).append(" ===\n");
                combinedText.append(text).append("\n\n");
            }
        }

        if (combinedText.toString().isBlank()) {
            throw new IllegalArgumentException(
                    "The selected course materials do not contain readable text. Please upload PDF, DOCX, PPTX, or TXT documents."
            );
        }

        // 5. Gather Existing Course Tasks
        List<Task> existingTasks = taskRepository.findByCourse(course);
        List<String> existingTaskTitles = existingTasks.stream()
                .map(Task::getTitle)
                .toList();

        // 6. Call AI Provider for Structured Topic Recommendations
        AiClient.AiAnalysisResult aiResult = aiClient.analyzeCourseContent(
                user,
                course.getName(),
                course.getCode(),
                combinedText.toString(),
                existingTaskTitles
        );

        List<AiTopicRecommendation> topics = aiResult.topics();

        // 7. Translate Recommendations into Tasks and feed into Deterministic Scheduler
        LocalDate today = LocalDate.now();
        List<Task> createdTasks = new ArrayList<>();

        for (AiTopicRecommendation rec : topics) {
            TaskPriority priority;
            try {
                priority = TaskPriority.valueOf(rec.getPriority());
            } catch (Exception e) {
                priority = TaskPriority.MEDIUM;
            }

            LocalDate deadline = rec.getSuggestedDeadline() != null && !rec.getSuggestedDeadline().isBefore(today)
                    ? rec.getSuggestedDeadline()
                    : today.plusDays(7);

            int estHours = Math.max(1, (int) Math.ceil(rec.getEstimatedMinutes() / 60.0));

            Task task = Task.builder()
                    .course(course)
                    .title(rec.getTitle())
                    .description("AI Topic. Key concepts: " + String.join(", ", rec.getKeyConcepts()))
                    .type(TaskType.READING)
                    .priority(priority)
                    .dueDate(deadline)
                    .estimatedHours(estHours)
                    .completedHours(0)
                    .status(TaskStatus.TODO)
                    .build();

            Task saved = taskRepository.save(task);
            createdTasks.add(saved);
        }

        taskRepository.flush();
        log.info("Created {} new tasks from AI recommendations for course '{}'", createdTasks.size(), course.getName());

        // 8. Run Deterministic Scheduler to schedule study sessions respecting ALL constraints
        SchedulerResult schedulerResult = schedulerService.generateSchedule(user.getEmail());

        // 9. Record AI Generation Usage
        scheduleUsageService.recordGenerationUsage(
                user,
                ScheduleGenerationType.AI,
                true,
                schedulerResult.getGeneratedSessions(),
                "AI Study Plan for " + course.getName() + " (" + topics.size() + " topics)"
        );

        List<String> sessionDates = schedulerResult.getSessionDates() != null
                ? schedulerResult.getSessionDates().stream().map(LocalDate::toString).toList()
                : List.of();

        return AiStudyPlanResponse.builder()
                .courseId(courseId)
                .courseName(course.getName())
                .summary(aiResult.summary())
                .topics(topics)
                .generatedSessionsCount(schedulerResult.getGeneratedSessions())
                .scheduledMinutes(schedulerResult.getScheduledMinutes())
                .sessionDates(sessionDates)
                .successful(true)
                .message("Successfully generated AI study plan with " + topics.size() + " topics and " +
                        schedulerResult.getGeneratedSessions() + " scheduled sessions.")
                .build();
    }
}
