package com.logisticfleet.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.io.IOException;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArraySet;

/**
 * One tenant's admin(s) may have the live-tracking dashboard open on
 * several devices/tabs at once, so sessions are grouped by tenant id and a
 * telemetry update is fanned out to every session in that group. A tenant
 * only ever receives its own fleet's data — the tenant id comes from the
 * verified JWT at handshake time (see {@link com.logisticfleet.config.JwtHandshakeInterceptor}),
 * never from anything the client sends afterwards.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class LiveTrackingWebSocketHandler extends TextWebSocketHandler {

    private final ObjectMapper objectMapper;
    private final Map<Long, Set<WebSocketSession>> sessionsByTenant = new ConcurrentHashMap<>();

    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        Long tenantId = (Long) session.getAttributes().get("tenantId");
        sessionsByTenant.computeIfAbsent(tenantId, k -> new CopyOnWriteArraySet<>()).add(session);
        log.info("Live-tracking socket connected for tenant {} ({} total)", tenantId,
                sessionsByTenant.get(tenantId).size());
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        Long tenantId = (Long) session.getAttributes().get("tenantId");
        Set<WebSocketSession> sessions = sessionsByTenant.get(tenantId);
        if (sessions != null) {
            sessions.remove(session);
        }
    }

    /** Sends a telemetry payload to every dashboard currently connected for the given tenant. */
    public void broadcast(Long tenantId, Object payload) {
        Set<WebSocketSession> sessions = sessionsByTenant.get(tenantId);
        if (sessions == null || sessions.isEmpty()) {
            return;
        }
        try {
            TextMessage message = new TextMessage(objectMapper.writeValueAsString(payload));
            for (WebSocketSession session : sessions) {
                if (session.isOpen()) {
                    try {
                        session.sendMessage(message);
                    } catch (IOException e) {
                        log.warn("Failed to push telemetry to a session for tenant {}: {}", tenantId, e.getMessage());
                    }
                }
            }
        } catch (IOException e) {
            log.error("Failed to serialize telemetry broadcast", e);
        }
    }
}
