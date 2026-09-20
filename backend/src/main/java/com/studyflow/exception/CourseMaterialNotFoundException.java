package com.studyflow.exception;

public class CourseMaterialNotFoundException extends RuntimeException {
    public CourseMaterialNotFoundException(String message) {
        super(message);
    }
}
