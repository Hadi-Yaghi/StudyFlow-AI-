package com.studyflow.repository;

import com.studyflow.entity.Semester;
import com.studyflow.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SemesterRepository extends JpaRepository<Semester, Long> {

    List<Semester> findByUser(User user);

    Optional<Semester> findByUserAndActiveTrue(User user);

    boolean existsByUserAndNameIgnoreCase(User user, String name);
}