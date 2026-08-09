package com.studyflow.service.impl;

import com.studyflow.entity.StudySession;
import com.studyflow.entity.StudySessionStatus;
import com.studyflow.repository.StudySessionRepository;
import com.studyflow.service.MissedSessionService;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class MissedSessionServiceImpl implements MissedSessionService {

    private final StudySessionRepository studySessionRepository;

    @Override
    @Transactional

    @Scheduled(fixedRate = 60000)

    public void markMissedSessions() {

        LocalDate today = LocalDate.now();
        LocalTime now = LocalTime.now();

        List<StudySession> expiredSessions =
                studySessionRepository
                        .findBySessionDateAndEndTimeBeforeAndStatus(
                                today,
                                now,
                                StudySessionStatus.PLANNED
                        );

        for (StudySession session : expiredSessions) {
            session.setStatus(StudySessionStatus.MISSED);
        }

        studySessionRepository.saveAll(expiredSessions);
    }
}