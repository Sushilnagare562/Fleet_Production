package com.logisticfleet.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;
import org.springframework.stereotype.Component;

/**
 * Initializes the Firebase Admin SDK for push notifications. Controlled by
 * {@code logisticfleet.firebase.enabled} so the app starts cleanly with push
 * notifications simply switched off until a service-account key is added -
 * see application.properties for setup instructions.
 */
@Slf4j
@Component
public class FirebaseConfig {

    @Value("${logisticfleet.firebase.enabled:false}")
    private boolean enabled;

    @Value("${logisticfleet.firebase.credentials-path:classpath:firebase-service-account.json}")
    private String credentialsPath;

    private final ResourceLoader resourceLoader;

    public FirebaseConfig(ResourceLoader resourceLoader) {
        this.resourceLoader = resourceLoader;
    }

    @PostConstruct
    public void init() {
        if (!enabled) {
            log.info("Firebase push notifications are disabled (logisticfleet.firebase.enabled=false)");
            return;
        }

        try {
            Resource resource = resourceLoader.getResource(credentialsPath);
            if (!resource.exists()) {
                log.warn("Firebase enabled but no credentials file found at {} - push notifications will not be sent",
                        credentialsPath);
                return;
            }

            if (FirebaseApp.getApps().isEmpty()) {
                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.fromStream(resource.getInputStream()))
                        .build();
                FirebaseApp.initializeApp(options);
                log.info("Firebase Admin SDK initialized - push notifications are live");
            }
        } catch (Exception e) {
            log.error("Failed to initialize Firebase Admin SDK - push notifications will not be sent", e);
        }
    }
}
