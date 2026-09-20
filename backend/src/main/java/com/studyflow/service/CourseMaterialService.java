package com.studyflow.service;

import com.studyflow.dto.response.CourseMaterialResponse;
import com.studyflow.entity.CourseMaterial;
import com.studyflow.entity.User;
import org.springframework.core.io.Resource;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

public interface CourseMaterialService {

    List<CourseMaterialResponse> getCourseMaterials(Long courseId, User user);

    CourseMaterialResponse uploadMaterial(Long courseId, MultipartFile file, User user);

    Resource downloadMaterial(Long materialId, User user);

    String getOriginalFilename(Long materialId, User user);

    void deleteMaterial(Long materialId, User user);

    CourseMaterial getMaterialForAi(Long materialId, User user);
}
