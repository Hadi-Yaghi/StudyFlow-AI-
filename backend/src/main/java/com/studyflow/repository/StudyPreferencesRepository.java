package com.studyflow.repository;

import com.studyflow.entity.StudyPreferences;
import com.studyflow.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface StudyPreferencesRepository
        extends JpaRepository<StudyPreferences, Long> {

    Optional<StudyPreferences> findByUser(User user);
}