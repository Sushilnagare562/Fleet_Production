package com.logisticfleet.config;

import com.logisticfleet.security.JwtUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.server.ServerHttpRequest;
import org.springframework.http.server.ServerHttpResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.server.HandshakeInterceptor;
import org.springframework.web.util.UriComponentsBuilder;

import java.util.Map;

/**
 * Native browser/mobile WebSocket clients can't attach an Authorization
 * header to the upgrade request, so the live-tracking socket is
 * authenticated via a "token" query parameter instead:
 * {@code wss://host/ws/live-tracking?token=<jwt>}. The resolved tenant id
 * is stashed as a session attribute so {@link com.logisticfleet.service.LiveTrackingWebSocketHandler}
 * only ever broadcasts a tenant's data to that tenant's own connections.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class JwtHandshakeInterceptor implements HandshakeInterceptor {

    private final JwtUtil jwtUtil;

    @Override
    public boolean beforeHandshake(ServerHttpRequest request, ServerHttpResponse response,
                                    WebSocketHandler wsHandler, Map<String, Object> attributes) {
        String token = UriComponentsBuilder.fromUri(request.getURI())
                .build()
                .getQueryParams()
                .getFirst("token");

        if (token == null) {
            log.warn("Live-tracking socket rejected: no token query param");
            response.setStatusCode(org.springframework.http.HttpStatus.UNAUTHORIZED);
            return false;
        }

        try {
            Long tenantId = jwtUtil.extractTenantId(token);
            String email = jwtUtil.extractEmail(token);
            if (tenantId == null || !jwtUtil.isTokenValid(token, email)) {
                response.setStatusCode(org.springframework.http.HttpStatus.UNAUTHORIZED);
                return false;
            }
            attributes.put("tenantId", tenantId);
            return true;
        } catch (Exception e) {
            log.warn("Live-tracking socket rejected: invalid token ({})", e.getMessage());
            response.setStatusCode(org.springframework.http.HttpStatus.UNAUTHORIZED);
            return false;
        }
    }

    @Override
    public void afterHandshake(ServerHttpRequest request, ServerHttpResponse response,
                                WebSocketHandler wsHandler, Exception exception) {
        // no-op
    }
}
