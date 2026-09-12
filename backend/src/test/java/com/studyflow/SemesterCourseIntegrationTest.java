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
}
