package com.studyflow.repository;

import com.studyflow.entity.Course;
import com.studyflow.entity.Semester;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface CourseRepository extends JpaRepository<Course, Long> {

    List<Course> findBySemester(Semester semester);

    Optional<Course> findBySemesterAndNameIgnoreCase(
            Semester semester,
            String name
    );

    boolean existsBySemesterAndNameIgnoreCase(
            Semester semester,
            String name
    );
}