package com.studyflow.service;

import com.studyflow.dto.response.CourseMaterialResponse;
import com.studyflow.entity.*;
import com.studyflow.exception.CourseNotFoundException;
import com.studyflow.exception.FileSizeLimitExceededException;
import com.studyflow.exception.PremiumRequiredException;
import com.studyflow.exception.UnsupportedFileTypeException;
import com.studyflow.repository.CourseMaterialRepository;
import com.studyflow.repository.CourseRepository;
import com.studyflow.service.ai.DocumentTextExtractionService;
import com.studyflow.service.impl.CourseMaterialServiceImpl;
import com.studyflow.service.storage.FileStorageService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.core.io.Resource;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.util.ReflectionTestUtils;

import java.io.InputStream;
import java.time.Instant;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CourseMaterialSecurityTest {

    @Mock
    private CourseMaterialRepository materialRepository;

    @Mock
    private CourseRepository courseRepository;

    @Mock
    private SubscriptionService subscriptionService;

    @Mock
    private FileStorageService fileStorageService;

    @Mock
    private DocumentTextExtractionService textExtractionService;

    @InjectMocks
    private CourseMaterialServiceImpl courseMaterialService;

    private User userA;
    private User userB;
    private Semester semesterA;
    private Semester semesterB;
    private Course courseA;
    private Course courseB;

    @BeforeEach
    void setUp() {
        userA = User.builder().id(1L).email("userA@studyflow.com").name("User A").build();
        userB = User.builder().id(2L).email("userB@studyflow.com").name("User B").build();

        semesterA = Semester.builder().id(10L).user(userA).name("Fall 2026").active(true).build();
        semesterB = Semester.builder().id(20L).user(userB).name("Fall 2026").active(true).build();

        courseA = Course.builder().id(100L).semester(semesterA).name("Algorithms").code("CS301").color("#3525CD").creditHours(3).build();
        courseB = Course.builder().id(200L).semester(semesterB).name("Databases").code("CS302").color("#3525CD").creditHours(3).build();

        ReflectionTestUtils.setField(courseMaterialService, "maxFileSizeBytes", 26214400L); // 25MB
    }

    @Test
    void uploadMaterial_shouldThrowPremiumRequired_whenUserIsNotPro() {
        when(subscriptionService.isPro(userA)).thenReturn(false);

        MockMultipartFile file = new MockMultipartFile(
                "file", "syllabus.pdf", "application/pdf", "PDF content".getBytes()
        );

        PremiumRequiredException ex = assertThrows(PremiumRequiredException.class, () ->
                courseMaterialService.uploadMaterial(100L, file, userA)
        );

        assertTrue(ex.getMessage().contains("StudyFlow Pro feature"));
        verify(fileStorageService, never()).store(any(), any());
    }

    @Test
    void uploadMaterial_shouldThrowException_whenUserTriesToUploadToAnotherUsersCourse() {
        when(subscriptionService.isPro(userA)).thenReturn(true);
        when(courseRepository.findById(200L)).thenReturn(Optional.of(courseB));

        MockMultipartFile file = new MockMultipartFile(
                "file", "syllabus.pdf", "application/pdf", "PDF content".getBytes()
        );

        assertThrows(CourseNotFoundException.class, () ->
                courseMaterialService.uploadMaterial(200L, file, userA)
        );

        verify(fileStorageService, never()).store(any(), any());
    }

    @Test
    void uploadMaterial_shouldRejectUnsupportedFileExtension() {
        when(subscriptionService.isPro(userA)).thenReturn(true);
        when(courseRepository.findById(100L)).thenReturn(Optional.of(courseA));

        MockMultipartFile file = new MockMultipartFile(
                "file", "malware.exe", "application/octet-stream", "executable".getBytes()
        );

        assertThrows(UnsupportedFileTypeException.class, () ->
                courseMaterialService.uploadMaterial(100L, file, userA)
        );

        verify(fileStorageService, never()).store(any(), any());
    }

    @Test
    void uploadMaterial_shouldRejectFilesExceedingSizeLimit() {
        when(subscriptionService.isPro(userA)).thenReturn(true);
        when(courseRepository.findById(100L)).thenReturn(Optional.of(courseA));

        // Create mock file claiming to be 30MB
        MockMultipartFile largeFile = new MockMultipartFile(
                "file", "huge_textbook.pdf", "application/pdf", new byte[10]
        ) {
            @Override
            public long getSize() {
                return 30L * 1024 * 1024; // 30 MB
            }
        };

        assertThrows(FileSizeLimitExceededException.class, () ->
                courseMaterialService.uploadMaterial(100L, largeFile, userA)
        );

        verify(fileStorageService, never()).store(any(), any());
    }

    @Test
    void uploadMaterial_shouldSucceed_whenUserIsProAndFileIsValid() {
        when(subscriptionService.isPro(userA)).thenReturn(true);
        when(courseRepository.findById(100L)).thenReturn(Optional.of(courseA));
        when(fileStorageService.store(any(), eq("course_100"))).thenReturn("course_100/uuid-syllabus.pdf");
        when(textExtractionService.extractText(any(InputStream.class), eq("syllabus.pdf"), any())).thenReturn("Course Outline");

        CourseMaterial savedEntity = CourseMaterial.builder()
                .id(50L)
                .course(courseA)
                .user(userA)
                .originalFilename("syllabus.pdf")
                .storageKey("course_100/uuid-syllabus.pdf")
                .mimeType("application/pdf")
                .fileSize(1024L)
                .uploadedAt(Instant.now())
                .extractedText("Course Outline")
                .processingStatus(MaterialProcessingStatus.PROCESSED)
                .build();

        when(materialRepository.save(any(CourseMaterial.class))).thenReturn(savedEntity);

        MockMultipartFile file = new MockMultipartFile(
                "file", "syllabus.pdf", "application/pdf", "Valid PDF data".getBytes()
        );

        CourseMaterialResponse response = courseMaterialService.uploadMaterial(100L, file, userA);

        assertNotNull(response);
        assertEquals(50L, response.getId());
        assertEquals("syllabus.pdf", response.getOriginalFilename());
        assertEquals(100L, response.getCourseId());
        verify(materialRepository).save(any(CourseMaterial.class));
    }

    @Test
    void downloadMaterial_shouldSucceed_forOwnerEvenIfSubscriptionExpired() {
        // User A's subscription has expired (or is Free), but they own this material
        CourseMaterial material = CourseMaterial.builder()
                .id(77L)
                .course(courseA)
                .user(userA)
                .originalFilename("notes.txt")
                .storageKey("course_100/uuid-notes.txt")
                .mimeType("text/plain")
                .fileSize(500L)
                .build();

        when(materialRepository.findById(77L)).thenReturn(Optional.of(material));
        when(fileStorageService.loadAsResource("course_100/uuid-notes.txt"))
                .thenReturn(new ByteArrayResource("My Notes".getBytes()));

        Resource resource = courseMaterialService.downloadMaterial(77L, userA);

        assertNotNull(resource);
        verify(fileStorageService).loadAsResource("course_100/uuid-notes.txt");
    }

    @Test
    void downloadMaterial_shouldDenyAccess_whenUserBAttemptsToDownloadUserAsFile() {
        CourseMaterial materialA = CourseMaterial.builder()
                .id(77L)
                .course(courseA)
                .user(userA)
                .originalFilename("notes.txt")
                .storageKey("course_100/uuid-notes.txt")
                .build();

        when(materialRepository.findById(77L)).thenReturn(Optional.of(materialA));

        // User B tries to download User A's file
        assertThrows(RuntimeException.class, () ->
                courseMaterialService.downloadMaterial(77L, userB)
        );

        verify(fileStorageService, never()).loadAsResource(any());
    }
}
