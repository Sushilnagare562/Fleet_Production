package com.logisticfleet.config;

import com.logisticfleet.service.LiveTrackingWebSocketHandler;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

/**
 * Plain (non-STOMP) WebSocket endpoint at /ws/live-tracking. A raw handler
 * is used instead of full STOMP since there's exactly one broadcast
 * "channel" per tenant and no client-to-server messaging beyond the
 * initial connect — STOMP's extra machinery isn't needed here.
 */
@Configuration
@EnableWebSocket
@RequiredArgsConstructor
public class WebSocketConfig implements WebSocketConfigurer {

    private final LiveTrackingWebSocketHandler liveTrackingWebSocketHandler;
    private final JwtHandshakeInterceptor jwtHandshakeInterceptor;

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(liveTrackingWebSocketHandler, "/ws/live-tracking")
                .addInterceptors(jwtHandshakeInterceptor)
                .setAllowedOriginPatterns("*");
    }
}
