package com.studyflow.dto.request;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CourseCreateRequest {

    @NotBlank(message = "Course name is required")
    private String name;

    @NotBlank(message = "Course code is required")
    private String code;

    @NotBlank(message = "Instructor name is required")
    private String instructor;

    @NotNull(message = "Credit hours are required")
    @Min(value = 1, message = "Credit hours must be at least 1")
    private Integer creditHours;

    @NotBlank(message = "Course color is required")
    private String color;

    @NotNull(message = "Semester ID is required")
    private Long semesterId;
}