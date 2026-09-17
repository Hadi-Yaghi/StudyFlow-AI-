package com.studyflow.service.impl;

import com.studyflow.entity.StudySession;
import com.studyflow.entity.StudySessionStatus;
import com.studyflow.repository.StudySessionRepository;
import com.studyflow.service.MissedSessionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

@Slf4j
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
                studySessionRepository.findExpiredSessions(
                        today,
                        now,
                        StudySessionStatus.PLANNED
                );

        if (!expiredSessions.isEmpty()) {
            for (StudySession session : expiredSessions) {
                session.setStatus(StudySessionStatus.MISSED);
                log.info("MISSED sessionId={} taskTitle='{}' date={} time={}-{}",
                        session.getId(),
                        session.getTask() != null ? session.getTask().getTitle() : "",
                        session.getSessionDate(),
                        session.getStartTime(),
                        session.getEndTime());
            }

            studySessionRepository.saveAll(expiredSessions);
            studySessionRepository.flush();
        }
    }
}