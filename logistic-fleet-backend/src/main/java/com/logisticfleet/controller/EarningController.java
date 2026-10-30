package com.logisticfleet.controller;

import com.logisticfleet.dto.EarningDtos.EarningResponse;
import com.logisticfleet.dto.EarningDtos.EarningsSummary;
import com.logisticfleet.security.CurrentUserResolver;
import com.logisticfleet.service.EarningService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
@Slf4j
@RestController
@RequestMapping("/api/earnings")
@RequiredArgsConstructor
public class EarningController {

    private final EarningService earningService;
    private final CurrentUserResolver currentUserResolver;

    @GetMapping("/my")
    public ResponseEntity<List<EarningResponse>> myEarnings() {
        Long driverId = currentUserResolver.getCurrentUserId();
        return ResponseEntity.ok(earningService.getEarningsForDriver(driverId));
    }

    @GetMapping("/my/summary")
    public ResponseEntity<EarningsSummary> mySummary() {
        Long driverId = currentUserResolver.getCurrentUserId();
        return ResponseEntity.ok(earningService.getSummary(driverId));
    }
}
