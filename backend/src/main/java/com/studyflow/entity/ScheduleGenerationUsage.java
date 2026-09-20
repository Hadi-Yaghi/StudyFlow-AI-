package com.studyflow.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;

@Entity
@Table(name = "schedule_generation_usages")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ScheduleGenerationUsage extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    @Builder.Default
    private Instant timestamp = Instant.now();

    @Enumerated(EnumType.STRING)
    @Column(name = "generation_type", nullable = false, length = 50)
    @Builder.Default
    private ScheduleGenerationType generationType = ScheduleGenerationType.STANDARD;

    @Column(nullable = false)
    @Builder.Default
    private boolean successful = false;

    @Column(name = "generated_sessions_count", nullable = false)
    @Builder.Default
    private int generatedSessionsCount = 0;

    @Column(length = 500)
    private String notes;
}
