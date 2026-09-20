package com.studyflow.service.impl;

import com.studyflow.dto.response.CourseMaterialResponse;
import com.studyflow.entity.*;
import com.studyflow.exception.*;
import com.studyflow.repository.CourseMaterialRepository;
import com.studyflow.repository.CourseRepository;
import com.studyflow.service.CourseMaterialService;
import com.studyflow.service.SubscriptionService;
import com.studyflow.service.ai.DocumentTextExtractionService;
import com.studyflow.service.storage.FileStorageService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.InputStream;
import java.time.Instant;
import java.util.List;
import java.util.Set;

@Slf4j
@Service
@RequiredArgsConstructor
public class CourseMaterialServiceImpl implements CourseMaterialService {

    private final CourseMaterialRepository materialRepository;
    private final CourseRepository courseRepository;
    private final SubscriptionService subscriptionService;
    private final FileStorageService fileStorageService;
    private final DocumentTextExtractionService textExtractionService;

    @Value("${studyflow.files.max-file-size-bytes:26214400}") // 25 MB
    private long maxFileSizeBytes;

    private static final Set<String> ALLOWED_EXTENSIONS = Set.of(
            "pdf", "docx", "pptx", "txt"
    );

    @Override
    @Transactional(readOnly = true)
    public List<CourseMaterialResponse> getCourseMaterials(Long courseId, User user) {
        Course course = getOwnedCourse(courseId, user);
        List<CourseMaterial> materials = materialRepository.findByCourseAndUserOrderByUploadedAtDesc(course, user);

        return materials.stream()
                .map(this::toResponse)
                .toList();
    }

    @Override
    @Transactional
    public CourseMaterialResponse uploadMaterial(Long courseId, MultipartFile file, User user) {
        String originalFilename = file != null && file.getOriginalFilename() != null
                ? StringUtils.cleanPath(file.getOriginalFilename())
                : "document";

        log.info("MATERIAL_UPLOAD_START userId={} courseId={} filename={}", user.getId(), courseId, originalFilename);

        // 1. Authoritative Backend Check: User MUST have active StudyFlow Pro entitlement
        if (!subscriptionService.isPro(user)) {
            log.warn("MATERIAL_UPLOAD_FAILED stage=PREMIUM_CHECK userId={} reason=NOT_PRO", user.getId());
            throw new PremiumRequiredException("Uploading course materials is a StudyFlow Pro feature. Upgrade to Pro to upload course files.");
        }
        log.info("MATERIAL_PREMIUM_VALIDATED userId={}", user.getId());

        // 2. Ownership verification: User must own the target course
        Course course = getOwnedCourse(courseId, user);

        // 3. Validation: file must not be empty
        if (file == null || file.isEmpty()) {
            log.warn("MATERIAL_UPLOAD_FAILED stage=FILE_VALIDATION reason=EMPTY_FILE");
            throw new IllegalArgumentException("Cannot upload an empty file.");
        }

        // 4. Validation: file size
        if (file.getSize() > maxFileSizeBytes) {
            long maxMb = maxFileSizeBytes / (1024 * 1024);
            log.warn("MATERIAL_UPLOAD_FAILED stage=FILE_SIZE_CHECK size={} max={}", file.getSize(), maxFileSizeBytes);
            throw new FileSizeLimitExceededException("File size exceeds the configured maximum limit of " + maxMb + " MB.");
        }

        // 5. Validation: file extension
        String extension = getExtension(originalFilename).toLowerCase();
        if (!ALLOWED_EXTENSIONS.contains(extension)) {
            log.warn("MATERIAL_UPLOAD_FAILED stage=FILE_TYPE_CHECK extension={}", extension);
            throw new UnsupportedFileTypeException("Unsupported file format: '" + extension + "'. Allowed formats: PDF, DOCX, PPTX, TXT.");
        }

        // 6. Safe physical storage (using UUID key)
        String storageKey;
        try {
            storageKey = fileStorageService.store(file, "course_" + courseId);
            log.info("MATERIAL_FILE_SAVED storageKey={}", storageKey);
        } catch (Exception e) {
            log.error("MATERIAL_UPLOAD_FAILED stage=PHYSICAL_STORAGE reason={}", e.getMessage());
            throw e;
        }

        // 7. Extract text content server-side for AI study planning
        String extractedText = "";
        MaterialProcessingStatus processingStatus = MaterialProcessingStatus.PROCESSED;
        String errorMessage = null;

        try {
            try (InputStream is = file.getInputStream()) {
                extractedText = textExtractionService.extractText(is, originalFilename, file.getContentType());
            } catch (Exception streamEx) {
                // Fallback to reading from the stored resource if MultipartFile stream is exhausted
                try (InputStream resourceStream = fileStorageService.loadAsResource(storageKey).getInputStream()) {
                    extractedText = textExtractionService.extractText(resourceStream, originalFilename, file.getContentType());
                }
            }
        } catch (Exception e) {
            log.error("MATERIAL_UPLOAD_FAILED stage=TEXT_EXTRACTION reason={}", e.getMessage());
            processingStatus = MaterialProcessingStatus.FAILED;
            errorMessage = e.getMessage();
        }

        // 8. Save entity metadata
        CourseMaterial material = CourseMaterial.builder()
                .course(course)
                .user(user)
                .originalFilename(originalFilename)
                .storageKey(storageKey)
                .mimeType(file.getContentType() != null ? file.getContentType() : "application/octet-stream")
                .fileSize(file.getSize())
                .uploadedAt(Instant.now())
                .extractedText(extractedText)
                .processingStatus(processingStatus)
                .errorMessage(errorMessage)
                .build();

        CourseMaterial saved;
        try {
            saved = materialRepository.save(material);
            log.info("MATERIAL_DB_SAVED materialId={}", saved.getId());
        } catch (Exception e) {
            log.error("MATERIAL_UPLOAD_FAILED stage=DATABASE_SAVE reason={}", e.getMessage());
            fileStorageService.delete(storageKey);
            throw e;
        }

        log.info("MATERIAL_UPLOAD_SUCCESS materialId={}", saved.getId());
        return toResponse(saved);
    }

    @Override
    @Transactional(readOnly = true)
    public Resource downloadMaterial(Long materialId, User user) {
        CourseMaterial material = getOwnedMaterial(materialId, user);
        return fileStorageService.loadAsResource(material.getStorageKey());
    }

    @Override
    @Transactional(readOnly = true)
    public String getOriginalFilename(Long materialId, User user) {
        CourseMaterial material = getOwnedMaterial(materialId, user);
        return material.getOriginalFilename();
    }

    @Override
    @Transactional
    public void deleteMaterial(Long materialId, User user) {
        CourseMaterial material = getOwnedMaterial(materialId, user);
        fileStorageService.delete(material.getStorageKey());
        materialRepository.delete(material);
        log.info("Deleted course material [id={}] by owner user [{}]", materialId, user.getEmail());
    }

    @Override
    @Transactional(readOnly = true)
    public CourseMaterial getMaterialForAi(Long materialId, User user) {
        // Pro entitlement required to use materials for AI analysis
        if (!subscriptionService.isPro(user)) {
            throw new PremiumRequiredException("AI study planning is a StudyFlow Pro feature. Upgrade to Pro to use AI.");
        }
        return getOwnedMaterial(materialId, user);
    }

    private Course getOwnedCourse(Long courseId, User user) {
        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new CourseNotFoundException("Course not found with id: " + courseId));

        if (course.getSemester() == null ||
                course.getSemester().getUser() == null ||
                !course.getSemester().getUser().getId().equals(user.getId())) {
            log.warn("Access denied: User {} tried to access course {} owned by another user", user.getId(), courseId);
            throw new CourseNotFoundException("Course not found with id: " + courseId);
        }
        return course;
    }

    private CourseMaterial getOwnedMaterial(Long materialId, User user) {
        CourseMaterial material = materialRepository.findById(materialId)
                .orElseThrow(() -> new CourseMaterialNotFoundException("Course material not found with id: " + materialId));

        if (!material.getUser().getId().equals(user.getId())) {
            log.warn("Access denied: User {} tried to access course material {} owned by user {}",
                    user.getId(), materialId, material.getUser().getId());
            throw new CourseMaterialNotFoundException("Course material not found with id: " + materialId);
        }
        return material;
    }

    private String getExtension(String filename) {
        int dot = filename.lastIndexOf('.');
        if (dot >= 0 && dot < filename.length() - 1) {
            return filename.substring(dot + 1);
        }
        return "";
    }

    private CourseMaterialResponse toResponse(CourseMaterial material) {
        return CourseMaterialResponse.builder()
                .id(material.getId())
                .courseId(material.getCourse().getId())
                .originalFilename(material.getOriginalFilename())
                .mimeType(material.getMimeType())
                .fileSize(material.getFileSize())
                .uploadedAt(material.getUploadedAt())
                .processingStatus(material.getProcessingStatus().name())
                .build();
    }
}
