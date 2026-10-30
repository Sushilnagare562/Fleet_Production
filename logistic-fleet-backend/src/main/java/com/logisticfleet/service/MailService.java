package com.logisticfleet.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

/**
 * Thin wrapper around JavaMailSender for the one email Logistic Fleet currently
 * sends: the "forgot password" OTP.
 * <p>
 * When {@code logisticfleet.mail.enabled=false} (the default until SMTP
 * credentials are filled in), nothing is actually sent over the network -
 * the OTP is logged instead so forgot-password can still be exercised
 * end-to-end in local development. Flip the flag once
 * {@code spring.mail.username} / {@code spring.mail.password} point at a
 * real account.
 */
@Slf4j
@Service
public class MailService {

    private final JavaMailSender mailSender;

    @Value("${logisticfleet.mail.enabled:false}")
    private boolean mailEnabled;

    @Value("${logisticfleet.mail.from:no-reply@logisticfleet.app}")
    private String fromAddress;

    public MailService(JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }

    public void sendPasswordResetOtp(String toEmail, String otp, int expiryMinutes) {
        if (!mailEnabled) {
            log.warn("logisticfleet.mail.enabled=false — not sending a real email. " +
                    "Password reset OTP for {} is: {} (valid {} minutes)", toEmail, otp, expiryMinutes);
            return;
        }

        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(fromAddress);
        message.setTo(toEmail);
        message.setSubject("Your Logistic Fleet password reset code");
        message.setText(
                "Your Logistic Fleet password reset code is: " + otp + "\n\n" +
                        "This code expires in " + expiryMinutes + " minutes. " +
                        "If you didn't request this, you can safely ignore this email.");
        mailSender.send(message);
        log.info("Password reset OTP email sent to {}", toEmail);
    }
}
