package com.logisticfleet.util;

import java.util.regex.Pattern;

/**
 * Single source of truth for how emails and phone numbers are normalized
 * and validated across the app. Used by registration, login,
 * forgot/reset-password, and admin-created drivers so the same phone
 * number typed two different ways ("+91 98765-43210" vs "919876543210")
 * always resolves to the same stored value and the same DB lookup.
 */
public final class ContactNormalizer {

    private ContactNormalizer() {
    }

    // Deliberately a bit stricter than the bare minimum jakarta @Email check
    // (which happily accepts things like "a@b") since this also doubles as
    // the "does this identifier look like an email vs a phone number" test
    // used by login / forgot-password.
    private static final Pattern EMAIL_PATTERN =
            Pattern.compile("^[A-Za-z0-9+_.-]+@[A-Za-z0-9-]+(\\.[A-Za-z0-9-]+)*\\.[A-Za-z]{2,}$");

    // E.164 phone numbers are at most 15 digits; 7 is a generous lower bound
    // that still rejects obviously-truncated input.
    private static final Pattern PHONE_DIGITS_PATTERN = Pattern.compile("^[0-9]{7,15}$");

    public static String normalizeEmail(String rawEmail) {
        return rawEmail == null ? null : rawEmail.trim().toLowerCase();
    }

    /** Strips everything but digits, e.g. {@code "+91 98765-43210"} -> {@code "919876543210"}. */
    public static String normalizePhone(String rawPhone) {
        return rawPhone == null ? null : rawPhone.replaceAll("[^0-9]", "");
    }

    public static boolean isValidEmail(String email) {
        return email != null && EMAIL_PATTERN.matcher(email.trim()).matches();
    }

    /** Expects an already-normalized (digits-only) phone number. */
    public static boolean isValidPhoneDigits(String digitsOnlyPhone) {
        return digitsOnlyPhone != null && PHONE_DIGITS_PATTERN.matcher(digitsOnlyPhone).matches();
    }

    /** Heuristic used to decide whether a login/forgot-password "identifier" is an email or a phone number. */
    public static boolean looksLikeEmail(String identifier) {
        return identifier != null && identifier.contains("@");
    }

    /** Masks an email for user-facing messages, e.g. {@code "jo***@gmail.com"}. */
    public static String maskEmail(String email) {
        if (email == null || !email.contains("@")) return email;
        String[] parts = email.split("@", 2);
        String local = parts[0];
        String masked = local.length() <= 2
                ? local.charAt(0) + "*"
                : local.substring(0, 2) + "***";
        return masked + "@" + parts[1];
    }
}
