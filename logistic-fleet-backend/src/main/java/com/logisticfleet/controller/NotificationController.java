package com.logisticfleet.controller;

import com.logisticfleet.security.CurrentUserResolver;
import com.logisticfleet.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;
    private final CurrentUserResolver currentUserResolver;

    /** Body: { "fcmToken": "...", "platform": "android" | "ios" | "web" } */
    @PostMapping("/register-token")
    public ResponseEntity<Void> registerToken(@RequestBody Map<String, String> body) {
        notificationService.registerToken(
                currentUserResolver.getCurrentUserId(),
                body.get("fcmToken"),
                body.getOrDefault("platform", "unknown"));
        return ResponseEntity.ok().build();
    }

    /** Call on logout so a signed-out device stops receiving this user's notifications. */
    @DeleteMapping("/register-token")
    public ResponseEntity<Void> unregisterToken(@RequestParam String fcmToken) {
        notificationService.unregisterToken(fcmToken);
        return ResponseEntity.noContent().build();
    }
}
