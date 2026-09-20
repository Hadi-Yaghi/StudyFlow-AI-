package com.studyflow.exception;

public class CourseNotFoundException extends RuntimeException {

    public CourseNotFoundException() {
        super("Course not found");
    }

    public CourseNotFoundException(String message) {
        super(message);
    }
}