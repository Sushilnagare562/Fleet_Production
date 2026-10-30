package com.logisticfleet.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Data
@Component
@ConfigurationProperties(prefix = "mqtt")
public class MqttProperties {
    private boolean enabled;
    private String brokerUrl;
    private String clientId;
    private String username;
    private String password;
    /** Single-level wildcard topic, e.g. "fleet/+/telemetry" matches every device. */
    private String topicPattern;
}
