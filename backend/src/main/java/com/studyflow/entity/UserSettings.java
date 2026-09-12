package com.studyflow.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "user_settings")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserSettings {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Column(name = "notifications_enabled", nullable = false)
    @Builder.Default
    private boolean notificationsEnabled = true;

    @Column(name = "study_reminders", nullable = false)
    @Builder.Default
    private boolean studyReminders = true;

    @Column(name = "task_deadlines", nullable = false)
    @Builder.Default
    private boolean taskDeadlines = true;

    @Column(nullable = false, length = 20)
    @Builder.Default
    private String theme = "system"; // system, light, dark

    @Column(nullable = false, length = 10)
    @Builder.Default
    private String language = "en"; // en, ar
}
