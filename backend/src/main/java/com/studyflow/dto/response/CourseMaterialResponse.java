package com.studyflow.dto.response;

import lombok.*;

import java.time.Instant;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CourseMaterialResponse {

    private Long id;

    private Long courseId;

    private String originalFilename;

    private String mimeType;

    private long fileSize;

    private Instant uploadedAt;

    private String processingStatus;
}
