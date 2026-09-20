package com.studyflow.exception;

public class ScheduleLimitReachedException extends RuntimeException {
    public ScheduleLimitReachedException(String message) {
        super(message);
    }
}
