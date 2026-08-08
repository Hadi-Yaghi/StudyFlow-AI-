package com.studyflow.repository;

import com.studyflow.entity.Course;
import com.studyflow.entity.Task;
import com.studyflow.entity.TaskStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;

public interface TaskRepository extends JpaRepository<Task, Long> {

    List<Task> findByCourse(Course course);

    List<Task> findByCourseAndStatusNot(
            Course course,
            TaskStatus status
    );

    List<Task> findByCourseOrderByDueDateAsc(Course course);

    List<Task> findByDueDateBeforeAndStatusNot(
            LocalDate date,
            TaskStatus status
    );

    boolean existsByCourseAndTitleIgnoreCase(
            Course course,
            String title
    );
    List<Task> findByCourseIn(List<Course> courses);
}