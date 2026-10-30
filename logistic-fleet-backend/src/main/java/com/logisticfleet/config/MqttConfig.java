package com.logisticfleet.config;

import com.logisticfleet.service.TelemetryIngestService;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.eclipse.paho.client.mqttv3.*;
import org.eclipse.paho.client.mqttv3.persist.MemoryPersistence;
import org.springframework.stereotype.Component;

import java.util.UUID;

/**
 * Subscribes to the fleet telemetry topic on startup and forwards every
 * message to {@link TelemetryIngestService}. Controlled by
 * {@code mqtt.enabled} so the app still starts cleanly with no broker
 * configured (e.g. a fresh dev machine) - it just logs that live tracking
 * is off instead of failing the whole boot.
 * <p>
 * Auto-reconnects on drop; if the broker is simply unreachable, connection
 * is retried in the background rather than blocking startup.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class MqttConfig {

    private final MqttProperties properties;
    private final TelemetryIngestService telemetryIngestService;

    private MqttAsyncClient client;

    @PostConstruct
    public void connect() {
        if (!properties.isEnabled()) {
            log.info("MQTT live tracking is disabled (mqtt.enabled=false) - skipping broker connection");
            return;
        }
        if (properties.getBrokerUrl() == null || properties.getBrokerUrl().isBlank()) {
            log.warn("MQTT enabled but mqtt.broker-url is not set - live tracking will not receive data");
            return;
        }

        try {
            String clientId = (properties.getClientId() != null ? properties.getClientId() : "logisticfleet-backend")
                    + "-" + UUID.randomUUID();
            client = new MqttAsyncClient(properties.getBrokerUrl(), clientId, new MemoryPersistence());

            MqttConnectOptions options = new MqttConnectOptions();
            options.setAutomaticReconnect(true);
            options.setCleanSession(true);
            options.setConnectionTimeout(10);
            if (properties.getUsername() != null && !properties.getUsername().isBlank()) {
                options.setUserName(properties.getUsername());
                options.setPassword(properties.getPassword() != null ? properties.getPassword().toCharArray() : new char[0]);
            }

            client.setCallback(new MqttCallback() {
                @Override
                public void connectionLost(Throwable cause) {
                    log.warn("MQTT connection lost: {}. Auto-reconnect is enabled.", cause.getMessage());
                }

                @Override
                public void messageArrived(String topic, MqttMessage message) {
                    telemetryIngestService.ingest(new String(message.getPayload()));
                }

                @Override
                public void deliveryComplete(IMqttDeliveryToken token) {
                    // not used - this service only subscribes, never publishes
                }
            });

            client.connect(options, null, new IMqttActionListener() {
                @Override
                public void onSuccess(IMqttToken asyncActionToken) {
                    subscribe();
                }

                @Override
                public void onFailure(IMqttToken asyncActionToken, Throwable exception) {
                    log.error("Could not connect to MQTT broker at {}: {}. Will retry via automatic reconnect.",
                            properties.getBrokerUrl(), exception.getMessage());
                }
            });
        } catch (MqttException e) {
            log.error("Failed to initialize MQTT client - live tracking will not receive data", e);
        }
    }

    private void subscribe() {
        try {
            String topic = properties.getTopicPattern() != null ? properties.getTopicPattern() : "fleet/+/telemetry";
            client.subscribe(topic, 1);
            log.info("MQTT connected - subscribed to '{}' on {}", topic, properties.getBrokerUrl());
        } catch (MqttException e) {
            log.error("Failed to subscribe to MQTT topic", e);
        }
    }

    @PreDestroy
    public void disconnect() {
        if (client != null && client.isConnected()) {
            try {
                client.disconnect();
            } catch (MqttException e) {
                log.warn("Error disconnecting MQTT client: {}", e.getMessage());
            }
        }
    }
}
