package com.studyflow.repository;

import com.studyflow.entity.Course;
import com.studyflow.entity.CourseMaterial;
import com.studyflow.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CourseMaterialRepository extends JpaRepository<CourseMaterial, Long> {

    List<CourseMaterial> findByCourseAndUserOrderByUploadedAtDesc(Course course, User user);

    List<CourseMaterial> findByCourseIdAndUserIdOrderByUploadedAtDesc(Long courseId, Long userId);

    Optional<CourseMaterial> findByIdAndUser(Long id, User user);

    Optional<CourseMaterial> findByStorageKey(String storageKey);
}
