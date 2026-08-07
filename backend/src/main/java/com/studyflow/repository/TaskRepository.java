package com.studyflow.repository;

import com.studyflow.entity.Course;
import com.studyflow.entity.Task;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;

public interface TaskRepository extends JpaRepository<Task, Long> {

    List<Task> findByCourse(Course course);

    List<Task> findByCourseAndCompletedFalse(Course course);

    List<Task> findByCourseOrderByDueDateAsc(Course course);

    List<Task> findByDueDateBeforeAndCompletedFalse(LocalDate date);

    boolean existsByCourseAndTitleIgnoreCase(
            Course course,
            String title
    );
}