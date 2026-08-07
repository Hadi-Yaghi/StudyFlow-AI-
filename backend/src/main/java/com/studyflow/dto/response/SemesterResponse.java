package com.studyflow.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SemesterResponse {

    private Long id;

    private String name;

    private LocalDate startDate;

    private LocalDate endDate;

    private boolean active;
}