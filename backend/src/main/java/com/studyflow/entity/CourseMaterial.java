package com.studyflow.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;

@Entity
@Table(name = "course_materials")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CourseMaterial extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "course_id", nullable = false)
    private Course course;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "original_filename", nullable = false, length = 255)
    private String originalFilename;

    @Column(name = "storage_key", nullable = false, unique = true, length = 255)
    private String storageKey;

    @Column(name = "mime_type", nullable = false, length = 100)
    private String mimeType;

    @Column(name = "file_size", nullable = false)
    private long fileSize;

    @Column(name = "uploaded_at", nullable = false)
    @Builder.Default
    private Instant uploadedAt = Instant.now();

    @Column(name = "extracted_text", columnDefinition = "TEXT")
    private String extractedText;

    @Enumerated(EnumType.STRING)
    @Column(name = "processing_status", nullable = false, length = 50)
    @Builder.Default
    private MaterialProcessingStatus processingStatus = MaterialProcessingStatus.PENDING;

    @Column(name = "error_message", length = 500)
    private String errorMessage;
}
