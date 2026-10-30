package com.logisticfleet.dto;

import com.logisticfleet.entity.DriverStatus;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

public class AdminDriverDtos {

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CreateDriverRequest {
        @NotBlank
        private String name;
        @Email
        @NotBlank
        private String email;
        @NotBlank
        @Pattern(regexp = "^[+]?[0-9 .-]{7,20}$", message = "Enter a valid mobile number")
        private String phone;
        @NotBlank
        @Pattern(regexp = AuthDtos.STRONG_PASSWORD_REGEX, message = AuthDtos.STRONG_PASSWORD_MESSAGE)
        private String temporaryPassword;
        private String vehicleNumber;
        private String licenseNumber;
    }

    /** Used by the 3-dot menu on the admin driver list to set ACTIVE / ON_LEAVE (DELETED goes through the dedicated delete endpoint instead). */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DriverStatusRequest {
        @NotNull(message = "Specify the new driver status")
        private DriverStatus status;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DriverResponse {
        private Long id;
        private String name;
        private String email;
        private String phone;
        private String vehicleNumber;
        private String licenseNumber;
        private boolean active;
        private DriverStatus driverStatus;
        private String role;
    }
}
