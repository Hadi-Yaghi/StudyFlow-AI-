package com.studyflow;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.studyflow.dto.request.RegisterRequest;
import com.studyflow.entity.*;
import com.studyflow.repository.*;
import com.studyflow.security.JwtService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;
import com.studyflow.scheduler.ScheduleConflictValidator;
import com.studyflow.service.MissedSessionService;
import com.studyflow.service.MissedSessionReschedulingService;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@Transactional
class SchedulerIntegrationTest {

    private MockMvc mockMvc;

    @Autowired
    private WebApplicationContext webApplicationContext;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private SemesterRepository semesterRepository;

    @Autowired
    private CourseRepository courseRepository;

    @Autowired
    private TaskRepository taskRepository;

    @Autowired
    private AvailabilityRepository availabilityRepository;

    @Autowired
    private StudyPreferencesRepository studyPreferencesRepository;

    @Autowired
    private StudySessionRepository studySessionRepository;

    @Autowired
    private JwtService jwtService;

    @Autowired
    private MissedSessionService missedSessionService;

    @Autowired
    private MissedSessionReschedulingService missedSessionReschedulingService;

    @Autowired
    private ScheduleConflictValidator scheduleConflictValidator;

    private final ObjectMapper objectMapper = new ObjectMapper();

    private User testUser;
    private String authToken;
    private Task testTask;

    @BeforeEach
    void setUp() throws Exception {
        mockMvc = MockMvcBuilders
                .webAppContextSetup(webApplicationContext)
                .apply(springSecurity())
                .build();

        String uniqueSuffix = UUID.randomUUID().toString().substring(0, 8);
        String email = "sched_user_" + uniqueSuffix + "@example.com";

        RegisterRequest registerRequest = new RegisterRequest();
        registerRequest.setName("Scheduler User");
        registerRequest.setEmail(email);
        registerRequest.setPassword("Password123!");

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(registerRequest)))
                .andExpect(status().isCreated());

        testUser = userRepository.findByEmail(email).orElseThrow();
        testUser.setEmailVerified(true);
        userRepository.save(testUser);

        authToken = jwtService.generateToken(email);

        // Create study preferences
        StudyPreferences preferences = StudyPreferences.builder()
                .user(testUser)
                .maxSessionMinutes(60)
                .breakMinutes(15)
                .preferredStudyStart(LocalTime.of(9, 0))
                .preferredStudyEnd(LocalTime.of(17, 0))
                .allowWeekendStudy(true)
                .build();
        studyPreferencesRepository.save(preferences);

        // Create availability for all days of the week
        for (DayOfWeekEnum day : DayOfWeekEnum.values()) {
            Availability availability = Availability.builder()
                    .user(testUser)
                    .day(day)
                    .startTime(LocalTime.of(9, 0))
                    .endTime(LocalTime.of(17, 0))
                    .enabled(true)
                    .build();
            availabilityRepository.save(availability);
        }

        // Create semester
        Semester semester = Semester.builder()
                .user(testUser)
                .name("Fall 2026")
                .startDate(LocalDate.now().minusDays(10))
                .endDate(LocalDate.now().plusMonths(3))
                .active(true)
                .build();
        semesterRepository.save(semester);

        // Create course
        Course course = Course.builder()
                .semester(semester)
                .name("Software Architecture")
                .code("CS401")
                .instructor("Prof. Smith")
                .creditHours(3)
                .color("#3525CD")
                .build();
        courseRepository.save(course);

        // Create task
        Task task = Task.builder()
                .course(course)
                .title("Design Pattern Assignment")
                .description("Implement Observer and Factory patterns")
                .type(TaskType.ASSIGNMENT)
                .priority(TaskPriority.HIGH)
                .dueDate(LocalDate.now().plusDays(5))
                .estimatedHours(4)
                .completedHours(0)
                .status(TaskStatus.TODO)
                .build();
        testTask = taskRepository.save(task);
    }

    @Test
    void testScheduleGeneration_AndImmediateRetrieval() throws Exception {
        // 1. Generate schedule
        MvcResult generateResult = mockMvc.perform(post("/api/scheduler/generate")
                        .header("Authorization", "Bearer " + authToken))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode genJson = objectMapper.readTree(generateResult.getResponse().getContentAsString());
        int generatedSessions = genJson.get("generatedSessions").asInt();
        assertTrue(generatedSessions > 0, "Generated sessions count should be greater than 0");
        assertTrue(genJson.hasNonNull("firstSessionDate"), "Should return firstSessionDate");
        assertTrue(genJson.hasNonNull("sessionDates"), "Should return sessionDates list");
        String firstSessionDate = genJson.get("firstSessionDate").asText();

        // 2. Fetch sessions for firstSessionDate
        MvcResult getResult = mockMvc.perform(get("/api/study-sessions")
                        .param("date", firstSessionDate)
                        .header("Authorization", "Bearer " + authToken))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode sessionsJson = objectMapper.readTree(getResult.getResponse().getContentAsString());
        assertTrue(sessionsJson.isArray(), "Response should be an array of sessions");
        assertTrue(sessionsJson.size() > 0, "Should contain sessions for the generated date");

        // Verify task details are populated
        JsonNode firstSession = sessionsJson.get(0);
        assertEquals("Design Pattern Assignment", firstSession.get("taskTitle").asText());
        assertEquals("PLANNED", firstSession.get("status").asText());

        // 3. Fetch session dates
        MvcResult datesResult = mockMvc.perform(get("/api/study-sessions/dates")
                        .header("Authorization", "Bearer " + authToken))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode datesJson = objectMapper.readTree(datesResult.getResponse().getContentAsString());
        assertTrue(datesJson.isArray());
        assertTrue(datesJson.size() > 0);

        // 4. Test re-generation prevents duplicates
        MvcResult regenResult = mockMvc.perform(post("/api/scheduler/generate")
                        .header("Authorization", "Bearer " + authToken))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode regenJson = objectMapper.readTree(regenResult.getResponse().getContentAsString());
        assertEquals(generatedSessions, regenJson.get("generatedSessions").asInt(),
                "Re-generation should maintain same session count without creating duplicates");

        // 5. Test user isolation: another user querying the same date gets 0 sessions
        String otherToken = jwtService.generateToken("other_user@example.com");
        User otherUser = User.builder()
                .email("other_user@example.com")
                .name("Other User")
                .passwordHash("hash")
                .emailVerified(true)
                .build();
        userRepository.save(otherUser);

        MvcResult otherGetResult = mockMvc.perform(get("/api/study-sessions")
                        .param("date", firstSessionDate)
                        .header("Authorization", "Bearer " + otherToken))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode otherSessionsJson = objectMapper.readTree(otherGetResult.getResponse().getContentAsString());
        assertEquals(0, otherSessionsJson.size(), "Other user should see 0 sessions");
    }

    @Test
    void testKnownValidCase_AlgorithmsChapter3() throws Exception {
        String email = "algo_user_" + UUID.randomUUID().toString().substring(0, 8) + "@example.com";
        User user = User.builder()
                .name("Algo Student")
                .email(email)
                .passwordHash("hash")
                .emailVerified(true)
                .build();
        userRepository.save(user);
        String token = jwtService.generateToken(email);

        // Active semester covering today
        Semester semester = Semester.builder()
                .user(user)
                .name("Fall 2026")
                .startDate(LocalDate.now().minusDays(10))
                .endDate(LocalDate.now().plusMonths(3))
                .active(true)
                .build();
        semesterRepository.save(semester);

        // Course: Algorithms
        Course course = Course.builder()
                .semester(semester)
                .name("Algorithms")
                .code("CS301")
                .instructor("Prof. Cormen")
                .creditHours(3)
                .color("#3525CD")
                .build();
        courseRepository.save(course);

        // Task: Title: Chapter 3, Status: TODO, Due date: future date, Estimated time: 120 minutes, Completed time: 0
        Task task = Task.builder()
                .course(course)
                .title("Chapter 3")
                .description("Divide and conquer algorithms")
                .type(TaskType.ASSIGNMENT)
                .priority(TaskPriority.HIGH)
                .dueDate(LocalDate.now().plusDays(7))
                .estimatedHours(2)
                .completedHours(0)
                .status(TaskStatus.TODO)
                .build();
        taskRepository.save(task);

        // Preferences: max session = 60, break = 15, preferred range includes 18:00–21:00
        StudyPreferences preferences = StudyPreferences.builder()
                .user(user)
                .maxSessionMinutes(60)
                .breakMinutes(15)
                .preferredStudyStart(LocalTime.of(18, 0))
                .preferredStudyEnd(LocalTime.of(21, 0))
                .allowWeekendStudy(true)
                .build();
        studyPreferencesRepository.save(preferences);

        // Availability: Monday 18:00–21:00, enabled = true
        Availability availability = Availability.builder()
                .user(user)
                .day(DayOfWeekEnum.MONDAY)
                .startTime(LocalTime.of(18, 0))
                .endTime(LocalTime.of(21, 0))
                .enabled(true)
                .build();
        availabilityRepository.save(availability);

        // POST /api/scheduler/generate
        MvcResult generateResult = mockMvc.perform(post("/api/scheduler/generate")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode genJson = objectMapper.readTree(generateResult.getResponse().getContentAsString());
        int generatedSessions = genJson.get("generatedSessions").asInt();
        assertTrue(generatedSessions >= 1, "At least one StudySession should be generated");
        assertEquals("SUCCESS", genJson.get("status").asText());
        assertNotNull(genJson.get("firstSessionDate"));

        String scheduledDate = genJson.get("firstSessionDate").asText();

        // Verify through GET /api/study-sessions?date=YYYY-MM-DD
        MvcResult getResult = mockMvc.perform(get("/api/study-sessions")
                        .param("date", scheduledDate)
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode sessionsJson = objectMapper.readTree(getResult.getResponse().getContentAsString());
        assertTrue(sessionsJson.isArray());
        assertTrue(sessionsJson.size() >= 1);
        assertEquals("Chapter 3", sessionsJson.get(0).get("taskTitle").asText());
    }

    @Test
    void testNoAvailability_ReturnsDiagnosticStatus() throws Exception {
        String email = "no_avail_" + UUID.randomUUID().toString().substring(0, 8) + "@example.com";
        User user = User.builder()
                .name("No Avail Student")
                .email(email)
                .passwordHash("hash")
                .emailVerified(true)
                .build();
        userRepository.save(user);
        String token = jwtService.generateToken(email);

        Semester semester = Semester.builder()
                .user(user)
                .name("Fall 2026")
                .startDate(LocalDate.now().minusDays(10))
                .endDate(LocalDate.now().plusMonths(3))
                .active(true)
                .build();
        semesterRepository.save(semester);

        Course course = Course.builder()
                .semester(semester)
                .name("Algorithms")
                .code("CS301")
                .color("#3525CD")
                .creditHours(3)
                .build();
        courseRepository.save(course);

        Task task = Task.builder()
                .course(course)
                .title("Chapter 3")
                .type(TaskType.ASSIGNMENT)
                .priority(TaskPriority.HIGH)
                .dueDate(LocalDate.now().plusDays(5))
                .estimatedHours(2)
                .completedHours(0)
                .status(TaskStatus.TODO)
                .build();
        taskRepository.save(task);

        StudyPreferences preferences = StudyPreferences.builder()
                .user(user)
                .maxSessionMinutes(45)
                .breakMinutes(10)
                .preferredStudyStart(LocalTime.of(9, 0))
                .preferredStudyEnd(LocalTime.of(22, 0))
                .allowWeekendStudy(true)
                .build();
        studyPreferencesRepository.save(preferences);

        // Zero availability records in DB!
        MvcResult generateResult = mockMvc.perform(post("/api/scheduler/generate")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode genJson = objectMapper.readTree(generateResult.getResponse().getContentAsString());
        assertEquals(0, genJson.get("generatedSessions").asInt());
        assertEquals("NO_AVAILABILITY", genJson.get("status").asText());
        assertTrue(genJson.get("message").asText().contains("No study availability configured"));
    }

    @Test
    void testMultipleTasks_ZeroOverlaps_AndBreakEnforced() throws Exception {
        String email = "five_tasks_" + UUID.randomUUID().toString().substring(0, 8) + "@example.com";
        User user = User.builder()
                .name("Five Tasks Student")
                .email(email)
                .passwordHash("hash")
                .emailVerified(true)
                .build();
        userRepository.save(user);
        String token = jwtService.generateToken(email);

        Semester semester = Semester.builder()
                .user(user)
                .name("Fall 2026")
                .startDate(LocalDate.now().minusDays(5))
                .endDate(LocalDate.now().plusMonths(3))
                .active(true)
                .build();
        semesterRepository.save(semester);

        Course course = Course.builder()
                .semester(semester)
                .name("Distributed Systems")
                .code("CS501")
                .creditHours(4)
                .color("#3525CD")
                .build();
        courseRepository.save(course);

        // Create 5 tasks
        for (int i = 1; i <= 5; i++) {
            Task task = Task.builder()
                    .course(course)
                    .title("Assignment " + i)
                    .type(TaskType.ASSIGNMENT)
                    .priority(TaskPriority.HIGH)
                    .dueDate(LocalDate.now().plusDays(6))
                    .estimatedHours(2)
                    .completedHours(0)
                    .status(TaskStatus.TODO)
                    .build();
            taskRepository.save(task);
        }

        int breakMinutes = 15;
        StudyPreferences preferences = StudyPreferences.builder()
                .user(user)
                .maxSessionMinutes(60)
                .breakMinutes(breakMinutes)
                .preferredStudyStart(LocalTime.of(16, 0))
                .preferredStudyEnd(LocalTime.of(23, 0))
                .allowWeekendStudy(true)
                .build();
        studyPreferencesRepository.save(preferences);

        // Daily availability 16:00 to 23:00 for all days
        for (DayOfWeekEnum day : DayOfWeekEnum.values()) {
            Availability availability = Availability.builder()
                    .user(user)
                    .day(day)
                    .startTime(LocalTime.of(16, 0))
                    .endTime(LocalTime.of(23, 0))
                    .enabled(true)
                    .build();
            availabilityRepository.save(availability);
        }

        // Generate schedule
        MvcResult generateResult = mockMvc.perform(post("/api/scheduler/generate")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode genJson = objectMapper.readTree(generateResult.getResponse().getContentAsString());
        int generatedCount = genJson.get("generatedSessions").asInt();
        assertTrue(generatedCount >= 5, "Should generate multiple sessions for 5 tasks");

        // Fetch all generated sessions for the user from DB
        List<StudySession> allSessions = studySessionRepository.findFutureSessionsByUser(
                user,
                List.of(StudySessionStatus.PLANNED),
                LocalDate.now()
        );
        assertFalse(allSessions.isEmpty());

        // Group sessions by date and verify mathematical overlap and break rule
        Map<LocalDate, List<StudySession>> byDate = allSessions.stream()
                .collect(Collectors.groupingBy(StudySession::getSessionDate));

        for (Map.Entry<LocalDate, List<StudySession>> entry : byDate.entrySet()) {
            List<StudySession> daily = entry.getValue();
            daily.sort((a, b) -> a.getStartTime().compareTo(b.getStartTime()));

            for (int i = 0; i < daily.size(); i++) {
                for (int j = i + 1; j < daily.size(); j++) {
                    StudySession s1 = daily.get(i);
                    StudySession s2 = daily.get(j);

                    // Rule 1: No direct overlap (s1.start < s2.end && s2.start < s1.end)
                    boolean directOverlap = s1.getStartTime().isBefore(s2.getEndTime())
                            && s2.getStartTime().isBefore(s1.getEndTime());
                    assertFalse(directOverlap, "Sessions " + s1.getId() + " and " + s2.getId() +
                            " on " + entry.getKey() + " directly overlap!");

                    // Rule 2: Separation must be at least breakMinutes
                    boolean breakViolation = s2.getStartTime().isBefore(s1.getEndTime().plusMinutes(breakMinutes));
                    assertFalse(breakViolation, "Sessions " + s1.getId() + " (" + s1.getStartTime() + "-" + s1.getEndTime() +
                            ") and " + s2.getId() + " (" + s2.getStartTime() + "-" + s2.getEndTime() +
                            ") on " + entry.getKey() + " violate the required " + breakMinutes + "m break!");
                }
            }
        }
    }

    @Test
    void testGenerateSchedule_Twice_NoDuplicatesNoOverlaps() throws Exception {
        String email = "twice_" + UUID.randomUUID().toString().substring(0, 8) + "@example.com";
        User user = User.builder()
                .name("Twice Student")
                .email(email)
                .passwordHash("hash")
                .emailVerified(true)
                .build();
        userRepository.save(user);
        String token = jwtService.generateToken(email);

        Semester semester = Semester.builder()
                .user(user)
                .name("Fall 2026")
                .startDate(LocalDate.now().minusDays(5))
                .endDate(LocalDate.now().plusMonths(3))
                .active(true)
                .build();
        semesterRepository.save(semester);

        Course course = Course.builder()
                .semester(semester)
                .name("Databases")
                .code("CS302")
                .creditHours(3)
                .color("#3525CD")
                .build();
        courseRepository.save(course);

        Task task1 = Task.builder()
                .course(course)
                .title("SQL Project")
                .type(TaskType.PROJECT)
                .priority(TaskPriority.HIGH)
                .dueDate(LocalDate.now().plusDays(5))
                .estimatedHours(3)
                .completedHours(0)
                .status(TaskStatus.TODO)
                .build();
        taskRepository.save(task1);

        StudyPreferences preferences = StudyPreferences.builder()
                .user(user)
                .maxSessionMinutes(60)
                .breakMinutes(15)
                .preferredStudyStart(LocalTime.of(18, 0))
                .preferredStudyEnd(LocalTime.of(22, 0))
                .allowWeekendStudy(true)
                .build();
        studyPreferencesRepository.save(preferences);

        for (DayOfWeekEnum day : DayOfWeekEnum.values()) {
            Availability availability = Availability.builder()
                    .user(user)
                    .day(day)
                    .startTime(LocalTime.of(18, 0))
                    .endTime(LocalTime.of(22, 0))
                    .enabled(true)
                    .build();
            availabilityRepository.save(availability);
        }

        // Run 1
        MvcResult res1 = mockMvc.perform(post("/api/scheduler/generate")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andReturn();
        JsonNode json1 = objectMapper.readTree(res1.getResponse().getContentAsString());
        int count1 = json1.get("generatedSessions").asInt();
        assertTrue(count1 > 0);

        // Run 2 (immediate repeat)
        MvcResult res2 = mockMvc.perform(post("/api/scheduler/generate")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andReturn();
        JsonNode json2 = objectMapper.readTree(res2.getResponse().getContentAsString());
        int count2 = json2.get("generatedSessions").asInt();

        assertEquals(count1, count2, "Repeated generation must produce identical count, not duplicate");

        List<StudySession> totalInDb = studySessionRepository.findFutureSessionsByUser(
                user,
                List.of(StudySessionStatus.PLANNED),
                LocalDate.now()
        );
        assertEquals(count1, totalInDb.size(), "Total sessions in DB must equal count1, no duplicates created");
    }

    @Test
    void testMissedSessionDetection_EndTimePassed() {
        LocalDate today = LocalDate.now();
        LocalTime now = LocalTime.now();

        // 1. Session ended in past today -> must become MISSED
        StudySession pastSession = StudySession.builder()
                .sessionDate(today)
                .startTime(now.minusHours(2))
                .endTime(now.minusHours(1))
                .plannedMinutes(60)
                .completedMinutes(0)
                .status(StudySessionStatus.PLANNED)
                .task(testTask)
                .build();
        studySessionRepository.save(pastSession);

        // 2. Session currently ongoing / future today -> must remain PLANNED
        StudySession futureSession = StudySession.builder()
                .sessionDate(today)
                .startTime(now.plusMinutes(10))
                .endTime(now.plusMinutes(70))
                .plannedMinutes(60)
                .completedMinutes(0)
                .status(StudySessionStatus.PLANNED)
                .task(testTask)
                .build();
        studySessionRepository.save(futureSession);

        // Run detection
        missedSessionService.markMissedSessions();

        StudySession updatedPast = studySessionRepository.findById(pastSession.getId()).orElseThrow();
        assertEquals(StudySessionStatus.MISSED, updatedPast.getStatus(), "Session whose endTime passed must be MISSED");

        StudySession updatedFuture = studySessionRepository.findById(futureSession.getId()).orElseThrow();
        assertEquals(StudySessionStatus.PLANNED, updatedFuture.getStatus(), "Future session must remain PLANNED");
    }

    @Test
    void testMultipleMissedSessions_RescheduledIntoDistinctSlots() {
        testTask.setEstimatedHours(10);
        testTask.setCompletedHours(0);
        taskRepository.save(testTask);

        LocalDate yesterday = LocalDate.now().minusDays(1);

        // Create 2 missed sessions from yesterday
        StudySession missed1 = StudySession.builder()
                .sessionDate(yesterday)
                .startTime(LocalTime.of(10, 0))
                .endTime(LocalTime.of(11, 0))
                .plannedMinutes(60)
                .completedMinutes(0)
                .status(StudySessionStatus.MISSED)
                .rescheduled(false)
                .task(testTask)
                .build();
        studySessionRepository.save(missed1);

        StudySession missed2 = StudySession.builder()
                .sessionDate(yesterday)
                .startTime(LocalTime.of(14, 0))
                .endTime(LocalTime.of(15, 0))
                .plannedMinutes(60)
                .completedMinutes(0)
                .status(StudySessionStatus.MISSED)
                .rescheduled(false)
                .task(testTask)
                .build();
        studySessionRepository.save(missed2);

        // Run rescheduling
        missedSessionReschedulingService.rescheduleMissedSessions();

        StudySession updatedMissed1 = studySessionRepository.findById(missed1.getId()).orElseThrow();
        StudySession updatedMissed2 = studySessionRepository.findById(missed2.getId()).orElseThrow();

        assertTrue(updatedMissed1.isRescheduled(), "Missed 1 should be marked rescheduled");
        assertTrue(updatedMissed2.isRescheduled(), "Missed 2 should be marked rescheduled");

        List<StudySession> replacements = studySessionRepository.findByTask(testTask).stream()
                .filter(s -> s.getStatus() == StudySessionStatus.PLANNED)
                .toList();

        assertTrue(replacements.size() >= 2, "Both missed sessions should have replacements");

        // Verify replacements do not overlap each other
        for (int i = 0; i < replacements.size(); i++) {
            for (int j = i + 1; j < replacements.size(); j++) {
                StudySession r1 = replacements.get(i);
                StudySession r2 = replacements.get(j);
                if (r1.getSessionDate().equals(r2.getSessionDate())) {
                    boolean overlap = r1.getStartTime().isBefore(r2.getEndTime())
                            && r2.getStartTime().isBefore(r1.getEndTime());
                    assertFalse(overlap, "Replacements on " + r1.getSessionDate() + " must never overlap!");
                }
            }
        }
    }

    @Test
    void testNoAvailableSpace_RemainsMissedWithoutForcedOverlap() {
        String email = "full_avail_" + UUID.randomUUID().toString().substring(0, 8) + "@example.com";
        User user = User.builder()
                .name("No Space Student")
                .email(email)
                .passwordHash("hash")
                .emailVerified(true)
                .build();
        userRepository.save(user);

        Semester semester = Semester.builder()
                .user(user)
                .name("Fall 2026")
                .startDate(LocalDate.now().minusDays(5))
                .endDate(LocalDate.now().plusMonths(3))
                .active(true)
                .build();
        semesterRepository.save(semester);

        Course course = Course.builder()
                .semester(semester)
                .name("Full Course")
                .code("FC101")
                .creditHours(3)
                .color("#3525CD")
                .build();
        courseRepository.save(course);

        Task task = Task.builder()
                .course(course)
                .title("No Slot Task")
                .type(TaskType.ASSIGNMENT)
                .priority(TaskPriority.HIGH)
                .dueDate(LocalDate.now().plusDays(2))
                .estimatedHours(5)
                .completedHours(0)
                .status(TaskStatus.TODO)
                .build();
        taskRepository.save(task);

        StudyPreferences preferences = StudyPreferences.builder()
                .user(user)
                .maxSessionMinutes(60)
                .breakMinutes(15)
                .preferredStudyStart(LocalTime.of(18, 0))
                .preferredStudyEnd(LocalTime.of(19, 0))
                .allowWeekendStudy(true)
                .build();
        studyPreferencesRepository.save(preferences);

        // Only 1 hour available per day (18:00 to 19:00)
        for (DayOfWeekEnum day : DayOfWeekEnum.values()) {
            Availability availability = Availability.builder()
                    .user(user)
                    .day(day)
                    .startTime(LocalTime.of(18, 0))
                    .endTime(LocalTime.of(19, 0))
                    .enabled(true)
                    .build();
            availabilityRepository.save(availability);
        }

        // Fill all 7 candidate days at 18:00-19:00 with COMPLETED sessions
        for (int i = 0; i < 7; i++) {
            StudySession occupying = StudySession.builder()
                    .sessionDate(LocalDate.now().plusDays(i))
                    .startTime(LocalTime.of(18, 0))
                    .endTime(LocalTime.of(19, 0))
                    .plannedMinutes(60)
                    .completedMinutes(60)
                    .status(StudySessionStatus.COMPLETED)
                    .task(task)
                    .build();
            studySessionRepository.save(occupying);
        }

        // Now create a missed session that needs rescheduling
        StudySession missed = StudySession.builder()
                .sessionDate(LocalDate.now().minusDays(1))
                .startTime(LocalTime.of(18, 0))
                .endTime(LocalTime.of(19, 0))
                .plannedMinutes(60)
                .completedMinutes(0)
                .status(StudySessionStatus.MISSED)
                .rescheduled(false)
                .task(task)
                .build();
        studySessionRepository.save(missed);

        // Attempt rescheduling
        missedSessionReschedulingService.rescheduleMissedSessions();

        StudySession checkMissed = studySessionRepository.findById(missed.getId()).orElseThrow();
        assertEquals(StudySessionStatus.MISSED, checkMissed.getStatus(), "Status must remain MISSED");
        assertFalse(checkMissed.isRescheduled(), "Must NOT be marked rescheduled when no slot exists");

        // Verify no extra PLANNED sessions were forced
        long plannedCount = studySessionRepository.findByTask(task).stream()
                .filter(s -> s.getStatus() == StudySessionStatus.PLANNED)
                .count();
        assertEquals(0, plannedCount, "No overlapping sessions should be forced into full schedule");
    }
}
