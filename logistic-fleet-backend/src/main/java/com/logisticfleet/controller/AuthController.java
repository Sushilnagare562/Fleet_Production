package com.logisticfleet.controller;

import com.logisticfleet.dto.AuthDtos.ForgotPasswordRequest;
import com.logisticfleet.dto.AuthDtos.LoginRequest;
import com.logisticfleet.dto.AuthDtos.LoginResponse;
import com.logisticfleet.dto.AuthDtos.MessageResponse;
import com.logisticfleet.dto.AuthDtos.RegisterRequest;
import com.logisticfleet.dto.AuthDtos.ResetPasswordRequest;
import com.logisticfleet.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
@Slf4j
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    public ResponseEntity<LoginResponse> register(@Valid @RequestBody RegisterRequest req) {
        return ResponseEntity.ok(authService.register(req));
    }

    @PostMapping("/login")
    public ResponseEntity<LoginResponse> login(@Valid @RequestBody LoginRequest req) {
        return ResponseEntity.ok(authService.login(req));
    }

    /** Step 1 of "forgot password": emails a one-time verification code to the account's email. */
    @PostMapping("/forgot-password")
    public ResponseEntity<MessageResponse> forgotPassword(@Valid @RequestBody ForgotPasswordRequest req) {
        return ResponseEntity.ok(authService.forgotPassword(req));
    }

    /** Step 2 of "forgot password": verifies the code and sets the new password. */
    @PostMapping("/reset-password")
    public ResponseEntity<MessageResponse> resetPassword(@Valid @RequestBody ResetPasswordRequest req) {
        return ResponseEntity.ok(authService.resetPassword(req));
    }
}
