package com.studyflow.exception;

public class FileSizeLimitExceededException extends RuntimeException {
    public FileSizeLimitExceededException(String message) {
        super(message);
    }
}
