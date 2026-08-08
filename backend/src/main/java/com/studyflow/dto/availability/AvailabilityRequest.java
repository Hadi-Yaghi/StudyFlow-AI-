package com.studyflow.dto.availability;

import com.studyflow.entity.DayOfWeekEnum;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.time.LocalTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AvailabilityRequest {

    @NotNull(message = "Day is required")
    private DayOfWeekEnum day;

    @NotNull(message = "Start time is required")
    private LocalTime startTime;

    @NotNull(message = "End time is required")
    private LocalTime endTime;

    @NotNull(message = "Enabled is required")
    private Boolean enabled;
}