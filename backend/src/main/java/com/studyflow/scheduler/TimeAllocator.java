package com.studyflow.scheduler;

import com.studyflow.entity.StudyPreferences;
import org.springframework.stereotype.Component;

import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;

@Component
public class TimeAllocator {

    public List<TimeBlock> allocate(
            LocalTime startTime,
            LocalTime endTime,
            StudyPreferences preferences
    ) {

        List<TimeBlock> blocks = new ArrayList<>();

        int sessionMinutes = preferences.getMaxSessionMinutes();
        int breakMinutes = preferences.getBreakMinutes();

        LocalTime current = startTime;

        while (current.plusMinutes(sessionMinutes).isBefore(endTime)
                || current.plusMinutes(sessionMinutes).equals(endTime)) {

            LocalTime sessionEnd =
                    current.plusMinutes(sessionMinutes);

            blocks.add(new TimeBlock(
                    current,
                    sessionEnd
            ));

            current = sessionEnd.plusMinutes(breakMinutes);
        }

        // Handle remaining time that is shorter than a full session.
        if (current.isBefore(endTime)) {

            blocks.add(new TimeBlock(
                    current,
                    endTime
            ));
        }

        return blocks;
    }

    public record TimeBlock(
            LocalTime startTime,
            LocalTime endTime
    ) {
        public int getMinutes() {
            return (int) (
                    java.time.Duration.between(
                            startTime,
                            endTime
                    ).toMinutes()
            );
        }
    }
}