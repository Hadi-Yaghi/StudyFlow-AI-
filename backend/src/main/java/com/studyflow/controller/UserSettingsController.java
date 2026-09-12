package com.studyflow.controller;

import com.studyflow.dto.request.UserSettingsRequest;
import com.studyflow.dto.response.UserSettingsResponse;
import com.studyflow.service.UserSettingsService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/user-settings")
@RequiredArgsConstructor
public class UserSettingsController {

    private final UserSettingsService userSettingsService;

    @GetMapping
    public ResponseEntity<UserSettingsResponse> getSettings(Authentication authentication) {
        return ResponseEntity.ok(userSettingsService.getSettings(authentication.getName()));
    }

    @PutMapping
    public ResponseEntity<UserSettingsResponse> updateSettings(
            Authentication authentication,
            @RequestBody UserSettingsRequest request) {
        return ResponseEntity.ok(userSettingsService.updateSettings(authentication.getName(), request));
    }
}
