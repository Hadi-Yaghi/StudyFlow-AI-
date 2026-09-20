package com.studyflow.controller;

import com.studyflow.dto.response.CourseMaterialResponse;
import com.studyflow.entity.User;
import com.studyflow.exception.UserNotFoundException;
import com.studyflow.repository.UserRepository;
import com.studyflow.service.CourseMaterialService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class CourseMaterialController {

    private final CourseMaterialService materialService;
    private final UserRepository userRepository;

    @GetMapping("/courses/{courseId}/materials")
    public ResponseEntity<List<CourseMaterialResponse>> getMaterials(
            @PathVariable Long courseId,
            Authentication authentication
    ) {
        User user = getUser(authentication);
        List<CourseMaterialResponse> list = materialService.getCourseMaterials(courseId, user);
        return ResponseEntity.ok(list);
    }

    @PostMapping(value = "/courses/{courseId}/materials", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<CourseMaterialResponse> uploadMaterial(
            @PathVariable Long courseId,
            @RequestParam("file") MultipartFile file,
            Authentication authentication
    ) {
        User user = getUser(authentication);
        log.info("MATERIAL_UPLOAD_REQUEST userId={} courseId={} filename={} size={}",
                user.getId(), courseId,
                file != null ? file.getOriginalFilename() : "null",
                file != null ? file.getSize() : 0);
        CourseMaterialResponse response = materialService.uploadMaterial(courseId, file, user);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/materials/{materialId}/download")
    public ResponseEntity<Resource> downloadMaterial(
            @PathVariable Long materialId,
            Authentication authentication
    ) {
        User user = getUser(authentication);
        Resource resource = materialService.downloadMaterial(materialId, user);
        String filename = materialService.getOriginalFilename(materialId, user);

        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_OCTET_STREAM)
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .body(resource);
    }

    @DeleteMapping("/materials/{materialId}")
    public ResponseEntity<Void> deleteMaterial(
            @PathVariable Long materialId,
            Authentication authentication
    ) {
        User user = getUser(authentication);
        materialService.deleteMaterial(materialId, user);
        return ResponseEntity.noContent().build();
    }

    private User getUser(Authentication authentication) {
        return userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new UserNotFoundException("User not found: " + authentication.getName()));
    }
}
