package com.logisticfleet.dto;

import com.logisticfleet.entity.VehicleStatus;
import com.logisticfleet.entity.VehicleType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

public class VehicleDtos {

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class VehicleRequest {
        @NotBlank
        private String vehicleNumber;
        @NotNull
        private VehicleType type;
        private String model;
        private Double capacityKg;
        private Long assignedDriverId;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class VehicleStatusRequest {
        @NotNull
        private VehicleStatus status;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AssignDriverRequest {
        private Long driverId; // null to unassign
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class VehicleResponse {
        private Long id;
        private String vehicleNumber;
        private VehicleType type;
        private String model;
        private Double capacityKg;
        private VehicleStatus status;
        private Long assignedDriverId;
        private String assignedDriverName;
    }
}
