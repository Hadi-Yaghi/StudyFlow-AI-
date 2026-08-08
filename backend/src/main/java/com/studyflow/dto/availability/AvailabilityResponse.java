package com.studyflow.dto.availability;

import com.studyflow.entity.DayOfWeekEnum;
import lombok.*;

import java.time.LocalTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AvailabilityResponse {

    private Long id;

    private DayOfWeekEnum day;

    private LocalTime startTime;

    private LocalTime endTime;

    private Boolean enabled;
}