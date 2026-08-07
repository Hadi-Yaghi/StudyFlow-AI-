package com.studyflow.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CourseResponse {

    private Long id;

    private String name;

    private String code;

    private String instructor;

    private Integer creditHours;

    private String color;

    private Long semesterId;
}