package com.studyflow.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AuthResponse {
    private String token;
    private long userId;
    private String name;
    private String email;
    private String major;
    private boolean emailVerified;

    public AuthResponse(String token, long userId, String name, String email) {
        this.token = token;
        this.userId = userId;
        this.name = name;
        this.email = email;
        this.major = null;
        this.emailVerified = true;
    }
}

