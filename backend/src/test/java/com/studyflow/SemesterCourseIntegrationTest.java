package com.studyflow;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.studyflow.dto.request.CourseCreateRequest;
import com.studyflow.dto.request.RegisterRequest;
import com.studyflow.dto.request.SemesterCreateRequest;
import com.studyflow.entity.Course;
import com.studyflow.entity.User;
import com.studyflow.repository.CourseRepository;
import com.studyflow.repository.SemesterRepository;
import com.studyflow.repository.UserRepository;
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
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@Transactional
class SemesterCourseIntegrationTest {

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
    private com.studyflow.repository.TaskRepository taskRepository;

    @Autowired
    private com.studyflow.repository.StudySessionRepository studySessionRepository;

    @Autowired
    private com.studyflow.security.JwtService jwtService;

    private final ObjectMapper objectMapper = new ObjectMapper();

    private String authToken;

    @BeforeEach
    void setUp() throws Exception {
        mockMvc = MockMvcBuilders
                .webAppContextSetup(webApplicationContext)
                .apply(springSecurity())
                .build();

        String unique = UUID.randomUUID().toString().substring(0, 8);
        RegisterRequest regReq = new RegisterRequest();
        regReq.setName("Semester Test User");
        regReq.setEmail("sem_user_" + unique + "@example.com");
        regReq.setPassword("Password123!");

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(regReq)))
                .andExpect(status().isCreated());

        // Mark user verified and generate token for test
        User user = userRepository.findByEmail(regReq.getEmail()).orElseThrow();
        user.setEmailVerified(true);
        userRepository.save(user);

        authToken = jwtService.generateToken(regReq.getEmail());
    }

    @Test
    void testActiveSemesterAllowsPastStartDateAndReusesExistingSemester() throws Exception {
        // 1. Create Fall 2026 semester where startDate is in the past (e.g. 2026-09-01)
        // and endDate is in the future (2026-12-31)
        String createReqJson = """
                {
                  "name": "Fall 2026",
                  "startDate": "2026-09-01",
                  "endDate": "2026-12-31"
                }
                """;

        MvcResult createResult = mockMvc.perform(post("/api/semesters")
                        .header("Authorization", "Bearer " + authToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(createReqJson))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").isNotEmpty())
                .andExpect(jsonPath("$.name").value("Fall 2026"))
                .andExpect(jsonPath("$.active").value(true))
                .andReturn();

        JsonNode createdJson = objectMapper.readTree(createResult.getResponse().getContentAsString());
        Long semesterId = createdJson.get("id").asLong();
        assertTrue(semesterId > 0, "Semester ID should be valid");

        // 2. Calling createSemester AGAIN for Fall 2026 must reuse the existing semester
        MvcResult duplicateResult = mockMvc.perform(post("/api/semesters")
                        .header("Authorization", "Bearer " + authToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(createReqJson))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(semesterId))
                .andExpect(jsonPath("$.name").value("Fall 2026"))
                .andReturn();

        JsonNode duplicateJson = objectMapper.readTree(duplicateResult.getResponse().getContentAsString());
        assertEquals(semesterId, duplicateJson.get("id").asLong(), "Must reuse the existing semester ID");

        // 3. Create course for this semester
        String courseReqJson = """
                {
                  "name": "Software Engineering",
                  "code": "CS301",
                  "instructor": "Dr. Smith",
                  "creditHours": 3,
                  "color": "#3525CD",
                  "semesterId": %d
                }
                """.formatted(semesterId);

        MvcResult courseResult = mockMvc.perform(post("/api/courses")
                        .header("Authorization", "Bearer " + authToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(courseReqJson))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").isNotEmpty())
                .andExpect(jsonPath("$.name").value("Software Engineering"))
                .andExpect(jsonPath("$.code").value("CS301"))
                .andExpect(jsonPath("$.semesterId").value(semesterId))
                .andReturn();

        JsonNode courseJson = objectMapper.readTree(courseResult.getResponse().getContentAsString());
        Long courseId = courseJson.get("id").asLong();

        // 4. Verify in DB directly via CourseRepository
        Course savedCourse = courseRepository.findById(courseId).orElse(null);
        assertNotNull(savedCourse, "Course must be saved in the database");
        assertEquals("Software Engineering", savedCourse.getName());
        assertEquals(semesterId, savedCourse.getSemester().getId());

        // 5. Query user courses
        mockMvc.perform(get("/api/courses")
                        .header("Authorization", "Bearer " + authToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(courseId))
                .andExpect(jsonPath("$[0].name").value("Software Engineering"));
    }

    @Test
    void testSemesterCreationWithPastEndDateIsRejected() throws Exception {
        String pastReqJson = """
                {
                  "name": "Past Semester 2025",
                  "startDate": "2025-01-10",
                  "endDate": "2025-05-20"
                }
                """;

        mockMvc.perform(post("/api/semesters")
                        .header("Authorization", "Bearer " + authToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(pastReqJson))
                .andExpect(status().isBadRequest());
    }

    @Test
    void testCourseDetails_Tasks_StatusUpdate_AndSessions() throws Exception {
        // 1. Create semester
        String semJson = """
                {
                  "name": "Fall 2026",
                  "startDate": "2026-09-01",
                  "endDate": "2026-12-31"
                }
                """;
        MvcResult semRes = mockMvc.perform(post("/api/semesters")
                        .header("Authorization", "Bearer " + authToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(semJson))
                .andExpect(status().isOk())
                .andReturn();
        Long semesterId = objectMapper.readTree(semRes.getResponse().getContentAsString()).get("id").asLong();

        // 2. Create course
        String courseJson = """
                {
                  "name": "Algorithms & Data Structures",
                  "code": "CS202",
                  "instructor": "Prof. Turing",
                  "creditHours": 4,
                  "color": "#3525CD",
                  "semesterId": %d
                }
                """.formatted(semesterId);
        MvcResult courseRes = mockMvc.perform(post("/api/courses")
                        .header("Authorization", "Bearer " + authToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(courseJson))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.semesterName").value("Fall 2026"))
                .andReturn();
        Long courseId = objectMapper.readTree(courseRes.getResponse().getContentAsString()).get("id").asLong();

        // 3. Verify GET /api/courses/{courseId} returns semesterName
        mockMvc.perform(get("/api/courses/" + courseId)
                        .header("Authorization", "Bearer " + authToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(courseId))
                .andExpect(jsonPath("$.name").value("Algorithms & Data Structures"))
                .andExpect(jsonPath("$.semesterName").value("Fall 2026"));

        // 4. Create task for this course
        String taskJson = """
                {
                  "title": "Sorting Algorithms Assignment",
                  "description": "Implement MergeSort and QuickSort",
                  "type": "ASSIGNMENT",
                  "priority": "HIGH",
                  "dueDate": "2026-09-20",
                  "estimatedHours": 3,
                  "courseId": %d
                }
                """.formatted(courseId);
        MvcResult taskRes = mockMvc.perform(post("/api/tasks")
                        .header("Authorization", "Bearer " + authToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(taskJson))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("TODO"))
                .andReturn();
        Long taskId = objectMapper.readTree(taskRes.getResponse().getContentAsString()).get("id").asLong();

        // 5. Query course tasks via GET /api/tasks/course/{courseId}
        mockMvc.perform(get("/api/tasks/course/" + courseId)
                        .header("Authorization", "Bearer " + authToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(taskId))
                .andExpect(jsonPath("$[0].title").value("Sorting Algorithms Assignment"));

        // 6. Update task status via PATCH /api/tasks/{taskId}/status
        mockMvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch("/api/tasks/" + taskId + "/status")
                        .param("status", "COMPLETED")
                        .header("Authorization", "Bearer " + authToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(taskId))
                .andExpect(jsonPath("$.status").value("COMPLETED"));

        // 7. Verify course sessions endpoint GET /api/study-sessions/course/{courseId}
        mockMvc.perform(get("/api/study-sessions/course/" + courseId)
                        .header("Authorization", "Bearer " + authToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray());
    }
}
