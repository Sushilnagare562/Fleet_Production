/// Shared validation helpers so every form (login, register, forgot/reset
/// password, change password) enforces the exact same rules the backend
/// does — keeps client-side errors and server-side 400s from disagreeing.
class Validators {
  Validators._();

  static final RegExp _emailPattern =
      RegExp(r'^[A-Za-z0-9+_.-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}$');

  /// E.164 phone numbers are at most 15 digits; 7 is a generous lower bound
  /// that still rejects obviously-truncated input. Mirrors
  /// `com.logisticfleet.util.ContactNormalizer` on the backend.
  static final RegExp _phoneDigitsPattern = RegExp(r'^[0-9]{7,15}$');

  /// At least 8 characters, one letter, one digit, one special character.
  /// Mirrors `AuthDtos.STRONG_PASSWORD_REGEX` on the backend exactly (same
  /// ASCII punctuation set Java's `\p{Punct}` matches) so client and server
  /// never disagree about what counts as a strong password.
  static final RegExp _strongPasswordPattern = RegExp(
      r'''^(?=.*[A-Za-z])(?=.*[0-9])(?=.*[!"#$%&'()*+,\-./:;<=>?@\[\]^_`{|}~]).{8,}$''');

  static bool isStrongPassword(String value) => _strongPasswordPattern.hasMatch(value);

  static bool isValidEmail(String value) => _emailPattern.hasMatch(value.trim());

  /// Strips everything but digits before checking length, so "+91 98765-43210"
  /// and "919876543210" validate the same way.
  static bool isValidPhone(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return _phoneDigitsPattern.hasMatch(digits);
  }

  static bool looksLikeEmail(String value) => value.contains('@');

  /// For the login / forgot-password "identifier" field, which accepts
  /// either an email or a mobile number.
  static String? identifier(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter your email or mobile number';
    final v = value.trim();
    if (looksLikeEmail(v)) {
      return isValidEmail(v) ? null : 'Enter a valid email address';
    }
    return isValidPhone(v) ? null : 'Enter a valid email or mobile number';
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter your email';
    return isValidEmail(value.trim()) ? null : 'Enter a valid email address';
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter your mobile number';
    return isValidPhone(value.trim()) ? null : 'Enter a valid mobile number (7-15 digits)';
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Enter a password';
    if (!isStrongPassword(value)) {
      return 'At least 8 characters with a letter, a number, and a special character';
    }
    return null;
  }

  /// Used at login only: an existing account's password might predate this
  /// app's password policy, so this just checks the field isn't empty and
  /// lets the server verify the actual password.
  static String? loginPassword(String? value) {
    return (value == null || value.isEmpty) ? 'Enter your password' : null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? otp(String? value) {
    if (value == null || value.trim().length != 6) return 'Enter the 6-digit code';
    if (!RegExp(r'^[0-9]{6}$').hasMatch(value.trim())) return 'Code must be 6 digits';
    return null;
  }

  static String? required(String? value, {String message = 'Required'}) {
    return (value == null || value.trim().isEmpty) ? message : null;
  }
}
