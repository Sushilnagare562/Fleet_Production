package com.logisticfleet.controller;

import com.logisticfleet.dto.EarningDtos.CreateEarningRequest;
import com.logisticfleet.dto.EarningDtos.EarningResponse;
import com.logisticfleet.dto.EarningDtos.EarningStatusRequest;
import com.logisticfleet.security.CurrentUserResolver;
import com.logisticfleet.service.EarningService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** Admin-only earnings management. Locked to ROLE_ADMIN via /api/admin/** in SecurityConfig. */
@Slf4j
@RestController
@RequestMapping("/api/admin/earnings")
@RequiredArgsConstructor
public class AdminEarningController {

    private final EarningService earningService;
    private final CurrentUserResolver currentUserResolver;

    @PostMapping
    public ResponseEntity<EarningResponse> createEarning(@Valid @RequestBody CreateEarningRequest req) {
        return ResponseEntity.ok(earningService.createEarning(currentUserResolver.getCurrentTenantId(), req));
    }

    @GetMapping
    public ResponseEntity<List<EarningResponse>> getAllEarnings() {
        return ResponseEntity.ok(earningService.getAllEarnings(currentUserResolver.getCurrentTenantId()));
    }

    @PatchMapping("/{earningId}/status")
    public ResponseEntity<EarningResponse> updateStatus(@PathVariable Long earningId,
                                                          @Valid @RequestBody EarningStatusRequest req) {
        return ResponseEntity.ok(
                earningService.updateStatus(currentUserResolver.getCurrentTenantId(), earningId, req));
    }
}
