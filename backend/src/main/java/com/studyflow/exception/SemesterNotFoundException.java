package com.studyflow.exception;

public class SemesterNotFoundException extends RuntimeException {

    public SemesterNotFoundException() {
        super("Semester not found");
    }
}