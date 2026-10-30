package com.logisticfleet.controller;

import com.logisticfleet.dto.AuthDtos.ChangePasswordRequest;
import com.logisticfleet.dto.AuthDtos.MessageResponse;
import com.logisticfleet.dto.AuthDtos.ProfileResponse;
import com.logisticfleet.dto.AuthDtos.UpdateProfilePhotoRequest;
import com.logisticfleet.security.CurrentUserResolver;
import com.logisticfleet.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Authenticated "my account" endpoints — everything the Profile tab needs.
 * Not under /api/auth/** (which is permitAll) since all of this requires a
 * logged-in user; it falls under the default authenticated() rule instead.
 */
@Slf4j
@RestController
@RequestMapping("/api/profile")
@RequiredArgsConstructor
public class ProfileController {

    private final AuthService authService;
    private final CurrentUserResolver currentUserResolver;

    @GetMapping("/me")
    public ResponseEntity<ProfileResponse> getProfile() {
        Long userId = currentUserResolver.getCurrentUserId();
        return ResponseEntity.ok(authService.getProfile(userId));
    }

    @PostMapping("/change-password")
    public ResponseEntity<MessageResponse> changePassword(@Valid @RequestBody ChangePasswordRequest req) {
        Long userId = currentUserResolver.getCurrentUserId();
        log.info("Change-password requested for user {}", userId);
        return ResponseEntity.ok(authService.changePassword(userId, req));
    }

    @PutMapping("/photo")
    public ResponseEntity<ProfileResponse> updatePhoto(@Valid @RequestBody UpdateProfilePhotoRequest req) {
        Long userId = currentUserResolver.getCurrentUserId();
        log.info("Profile photo updated for user {}", userId);
        return ResponseEntity.ok(authService.updateProfilePhoto(userId, req.getPhotoBase64()));
    }
}
