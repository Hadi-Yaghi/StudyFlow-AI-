package com.studyflow.repository;

import com.studyflow.entity.Availability;
import com.studyflow.entity.DayOfWeekEnum;
import com.studyflow.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface AvailabilityRepository extends JpaRepository<Availability, Long> {

    List<Availability> findByUser(User user);

    Optional<Availability> findByUserAndDay(User user, DayOfWeekEnum day);
}