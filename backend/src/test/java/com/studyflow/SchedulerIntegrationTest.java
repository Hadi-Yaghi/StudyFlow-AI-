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
import java.util.UUID;

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

    private final ObjectMapper objectMapper = new ObjectMapper();

    private User testUser;
    private String authToken;

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
        taskRepository.save(task);
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
}
