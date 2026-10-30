package com.logisticfleet.service;

import com.logisticfleet.entity.DeviceToken;
import com.logisticfleet.entity.Role;
import com.logisticfleet.entity.User;
import com.logisticfleet.repository.DeviceTokenRepository;
import com.logisticfleet.repository.UserRepository;
import com.google.firebase.FirebaseApp;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.MessagingErrorCode;
import com.google.firebase.messaging.Notification;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

/**
 * Sends push notifications via Firebase Cloud Messaging. Every send is
 * best-effort: a failure here (network blip, Firebase not configured, a
 * stale token) never blocks or rolls back the trip/expense action that
 * triggered it - the notification is a side effect, not part of the
 * business transaction.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class NotificationService {

    private final DeviceTokenRepository deviceTokenRepository;
    private final UserRepository userRepository;

    @Transactional
    public void registerToken(Long userId, String fcmToken, String platform) {
        if (deviceTokenRepository.findByFcmToken(fcmToken).isPresent()) {
            return; // already registered (e.g. re-login on the same device)
        }
        User user = userRepository.findById(userId).orElse(null);
        if (user == null) return;

        deviceTokenRepository.save(DeviceToken.builder()
                .user(user)
                .fcmToken(fcmToken)
                .platform(platform)
                .build());
        log.info("Registered FCM token for user {}", userId);
    }

    @Transactional
    public void unregisterToken(String fcmToken) {
        deviceTokenRepository.deleteByFcmToken(fcmToken);
    }

    /** Trip assigned -> notify the driver it was assigned to. */
    public void notifyTripAssigned(Long driverId, String tripCode, String origin, String destination) {
        sendToUser(driverId, "New trip assigned",
                tripCode + ": " + origin + " → " + destination,
                Map.of("type", "TRIP_ASSIGNED", "tripCode", tripCode));
    }

    /** Expense submitted -> notify every admin in the driver's company. */
    public void notifyExpenseSubmitted(Long tenantId, String driverName, String category, String amount) {
        List<User> admins = userRepository.findByTenantIdAndRole(tenantId, Role.ADMIN);
        for (User admin : admins) {
            sendToUser(admin.getId(), "New expense submitted",
                    driverName + " submitted a " + category + " expense of ₹" + amount,
                    Map.of("type", "EXPENSE_SUBMITTED"));
        }
    }

    private void sendToUser(Long userId, String title, String body, Map<String, String> data) {
        if (FirebaseApp.getApps().isEmpty()) {
            log.debug("Firebase not initialized - skipping notification '{}' to user {}", title, userId);
            return;
        }

        List<DeviceToken> tokens = deviceTokenRepository.findByUserId(userId);
        for (DeviceToken deviceToken : tokens) {
            try {
                Message message = Message.builder()
                        .setToken(deviceToken.getFcmToken())
                        .setNotification(Notification.builder().setTitle(title).setBody(body).build())
                        .putAllData(data)
                        .build();
                FirebaseMessaging.getInstance().send(message);
            } catch (FirebaseMessagingException e) {
                if (e.getMessagingErrorCode() == MessagingErrorCode.UNREGISTERED
                        || e.getMessagingErrorCode() == MessagingErrorCode.INVALID_ARGUMENT) {
                    // Token is stale (app uninstalled, token rotated) - clean it up.
                    deviceTokenRepository.deleteByFcmToken(deviceToken.getFcmToken());
                } else {
                    log.warn("Failed to send push notification to user {}: {}", userId, e.getMessage());
                }
            }
        }
    }
}
