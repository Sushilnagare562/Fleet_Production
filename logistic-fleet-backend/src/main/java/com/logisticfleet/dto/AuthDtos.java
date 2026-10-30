package com.logisticfleet.dto;

import com.logisticfleet.entity.Role;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

public class AuthDtos {

    /**
     * Shared "strong password" rule used everywhere a password is set or
     * changed (register, reset password, change password, admin-created
     * drivers): at least 8 characters, with at least one letter, one digit,
     * and one special character. {@code \p{Punct}} covers the standard
     * ASCII punctuation set so callers don't need to hand-escape a custom
     * character class.
     */
    public static final String STRONG_PASSWORD_REGEX = "^(?=.*[A-Za-z])(?=.*[0-9])(?=.*\\p{Punct}).{8,}$";
    public static final String STRONG_PASSWORD_MESSAGE =
            "Password must be at least 8 characters and include a letter, a number, and a special character";

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class LoginRequest {
        /** The email OR the mobile number registered on the account. */
        @NotBlank(message = "Enter your email or mobile number")
        private String identifier;

        @NotBlank(message = "Enter your password")
        private String password;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class RegisterRequest {
        @NotBlank
        private String name;

        @Email
        @NotBlank
        private String email;

        @NotBlank
        @Pattern(regexp = "^[+]?[0-9 .-]{7,20}$", message = "Enter a valid mobile number")
        private String phone;

        @NotBlank
        @Pattern(regexp = STRONG_PASSWORD_REGEX, message = STRONG_PASSWORD_MESSAGE)
        private String password;

        /**
         * Company / transport name. If a tenant with this name already
         * exists, the new user joins it; otherwise a brand-new tenant is
         * created automatically. Case-insensitive match on company name.
         */
        @NotBlank
        private String companyName;

        /** ADMIN, DRIVER or COMPANY_EMPLOYEE — chosen via the two register-screen buttons. */
        @NotNull
        private Role role;

        private String vehicleNumber;
        private String licenseNumber;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class LoginResponse {
        private String token;
        private Long userId;
        private String name;
        private String email;
        private String phone;
        private String role;
        private Long tenantId;
        private String companyName;
    }

    /** Step 1 of "forgot password": user submits the email OR mobile number tied to their account. */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ForgotPasswordRequest {
        @NotBlank(message = "Enter your email or mobile number")
        private String identifier;
    }

    /** Step 2 of "forgot password": the OTP emailed in step 1, plus the new password. */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ResetPasswordRequest {
        /** Same email or mobile number submitted in step 1. */
        @NotBlank(message = "Enter your email or mobile number")
        private String identifier;

        @NotBlank(message = "Enter the verification code")
        @Pattern(regexp = "^[0-9]{6}$", message = "Enter the 6-digit verification code")
        private String otp;

        @NotBlank
        @Pattern(regexp = STRONG_PASSWORD_REGEX, message = STRONG_PASSWORD_MESSAGE)
        private String newPassword;
    }

    /** Used from the Profile screen by an already-logged-in user who knows their current password. */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ChangePasswordRequest {
        @NotBlank(message = "Enter your current password")
        private String currentPassword;

        @NotBlank
        @Pattern(regexp = STRONG_PASSWORD_REGEX, message = STRONG_PASSWORD_MESSAGE)
        private String newPassword;
    }

    /** Generic acknowledgement body for endpoints that just need to report success. */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class MessageResponse {
        private String message;
    }

    /** Full profile shown on the Profile tab. */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ProfileResponse {
        private Long userId;
        private String name;
        private String email;
        private String phone;
        private String role;
        private Long tenantId;
        private String companyName;
        /** Base64-encoded image data (no "data:image/..." prefix), or null if none uploaded yet. */
        private String profilePhoto;
    }

    /** Body for uploading/replacing the profile photo. */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UpdateProfilePhotoRequest {
        @NotBlank
        @Size(max = 8_000_000, message = "Image is too large")
        private String photoBase64;
    }
}
