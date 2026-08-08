package com.studyflow.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalTime;

@Entity
@Table(name = "study_preferences")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StudyPreferences extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Integer maxSessionMinutes;

    @Column(nullable = false)
    private Integer breakMinutes;

    @Column(nullable = false)
    private Boolean allowWeekendStudy;

    @Column(nullable = false)
    private LocalTime preferredStudyStart;

    @Column(nullable = false)
    private LocalTime preferredStudyEnd;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;
}