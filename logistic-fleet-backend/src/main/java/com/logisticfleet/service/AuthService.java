package com.logisticfleet.service;

import com.logisticfleet.dto.AuthDtos.ChangePasswordRequest;
import com.logisticfleet.dto.AuthDtos.ForgotPasswordRequest;
import com.logisticfleet.dto.AuthDtos.LoginRequest;
import com.logisticfleet.dto.AuthDtos.LoginResponse;
import com.logisticfleet.dto.AuthDtos.MessageResponse;
import com.logisticfleet.dto.AuthDtos.ProfileResponse;
import com.logisticfleet.dto.AuthDtos.RegisterRequest;
import com.logisticfleet.dto.AuthDtos.ResetPasswordRequest;
import com.logisticfleet.entity.Tenant;
import com.logisticfleet.entity.TenantStatus;
import com.logisticfleet.entity.User;
import com.logisticfleet.exception.ResourceNotFoundException;
import com.logisticfleet.repository.TenantRepository;
import com.logisticfleet.repository.UserRepository;
import com.logisticfleet.security.JwtUtil;
import com.logisticfleet.util.ContactNormalizer;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.LocalDateTime;
@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final TenantRepository tenantRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtUtil jwtUtil;
    private final MailService mailService;

    private static final SecureRandom RANDOM = new SecureRandom();

    @Value("${logisticfleet.otp.expiry-minutes:10}")
    private int otpExpiryMinutes;

    @Transactional
    public LoginResponse register(RegisterRequest req) {
        String email = ContactNormalizer.normalizeEmail(req.getEmail());
        String phone = ContactNormalizer.normalizePhone(req.getPhone());

        if (!ContactNormalizer.isValidPhoneDigits(phone)) {
            // The @Pattern on RegisterRequest.phone already rejects obviously
            // malformed input, but it allows spaces/dashes/a leading "+", so
            // it's still possible to end up with too few/many digits once
            // those are stripped (e.g. "+" alone, or "12-34").
            throw new IllegalArgumentException("Enter a valid mobile number");
        }
        if (userRepository.existsByEmail(email)) {
            throw new IllegalArgumentException("Email already registered");
        }
        userRepository.findByPhone(phone).ifPresent(existing -> {
            throw new IllegalArgumentException("Mobile number already registered");
        });

        boolean isNewCompany = !tenantRepository.existsByCompanyNameIgnoreCase(req.getCompanyName().trim());
        if (!isNewCompany && req.getRole() == com.logisticfleet.entity.Role.ADMIN) {
            // Anyone could otherwise type an existing company's name and grant
            // themselves admin rights over it. Only the very first person to
            // register a company name becomes its admin; everyone else joins
            // as DRIVER or COMPANY_EMPLOYEE and an existing admin can promote
            // them later if needed.
            throw new IllegalArgumentException(
                    "\"" + req.getCompanyName().trim() + "\" is already registered. " +
                            "Join as Driver or Company Employee, or ask your company admin for access.");
        }

        Tenant tenant = resolveTenant(req.getCompanyName());

        User user = User.builder()
                .tenant(tenant)
                .name(req.getName().trim())
                .email(email)
                .phone(phone)
                .passwordHash(passwordEncoder.encode(req.getPassword()))
                .role(req.getRole())
                .vehicleNumber(req.getVehicleNumber())
                .licenseNumber(req.getLicenseNumber())
                .build();

        userRepository.save(user);
        String token = jwtUtil.generateToken(user.getEmail(), user.getId(), user.getRole().name(), tenant.getId());
        log.info("New user saved for tenant {}", tenant.getId());
        return new LoginResponse(token, user.getId(), user.getName(), user.getEmail(), user.getPhone(),
                user.getRole().name(), tenant.getId(), tenant.getCompanyName());
    }

    /**
     * Logs in with either the account's email or its mobile number.
     * Whichever one the user typed, the identifier is resolved to the
     * account first, then the *actual* stored email is what's handed to
     * Spring Security for the password check — {@link com.logisticfleet.security.UserDetailsServiceImpl}
     * only ever looks users up by email, so this keeps that contract intact
     * while letting the login screen accept either identifier.
     */
    @Transactional(readOnly = true)
    public LoginResponse login(LoginRequest req) {
        User user = findUserByIdentifierOrThrow(req.getIdentifier());

        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(user.getEmail(), req.getPassword()));

        Tenant tenant = user.getTenant();
        String token = jwtUtil.generateToken(user.getEmail(), user.getId(), user.getRole().name(), tenant.getId());
        return new LoginResponse(token, user.getId(), user.getName(), user.getEmail(), user.getPhone(),
                user.getRole().name(), tenant.getId(), tenant.getCompanyName());
    }

    /**
     * Step 1 of "forgot password": generates a 6-digit OTP, stores its hash
     * (never the plaintext) with a short expiry, and emails it to the
     * account's registered email — regardless of whether the user identified
     * themselves by email or mobile number, since email is the only delivery
     * channel currently configured.
     */
    @Transactional
    public MessageResponse forgotPassword(ForgotPasswordRequest req) {
        User user = findUserByIdentifierOrThrow(req.getIdentifier());

        String otp = String.format("%06d", RANDOM.nextInt(1_000_000));
        user.setResetOtpHash(passwordEncoder.encode(otp));
        user.setResetOtpExpiry(LocalDateTime.now().plusMinutes(otpExpiryMinutes));
        userRepository.save(user);

        mailService.sendPasswordResetOtp(user.getEmail(), otp, otpExpiryMinutes);
        log.info("Password reset OTP generated for {}", user.getEmail());

        return new MessageResponse(
                "A verification code has been sent to " + ContactNormalizer.maskEmail(user.getEmail()));
    }

    /**
     * Step 2 of "forgot password": verifies the OTP (and that it hasn't
     * expired) then sets the new password. Uses the same identifier
     * submitted in step 1 to re-resolve the account.
     */
    @Transactional
    public MessageResponse resetPassword(ResetPasswordRequest req) {
        User user = findUserByIdentifierOrThrow(req.getIdentifier());

        if (user.getResetOtpHash() == null || user.getResetOtpExpiry() == null) {
            throw new IllegalArgumentException("No reset code was requested for this account");
        }
        if (user.getResetOtpExpiry().isBefore(LocalDateTime.now())) {
            throw new IllegalArgumentException("This code has expired. Please request a new one.");
        }
        if (!passwordEncoder.matches(req.getOtp(), user.getResetOtpHash())) {
            throw new IllegalArgumentException("Incorrect verification code");
        }

        user.setPasswordHash(passwordEncoder.encode(req.getNewPassword()));
        user.setResetOtpHash(null);
        user.setResetOtpExpiry(null);
        userRepository.save(user);
        log.info("Password reset completed for {}", user.getEmail());

        return new MessageResponse("Password reset successfully. You can now sign in.");
    }

    /** Used from the Profile screen: the user already knows their current password. */
    @Transactional
    public MessageResponse changePassword(Long userId, ChangePasswordRequest req) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        if (!passwordEncoder.matches(req.getCurrentPassword(), user.getPasswordHash())) {
            throw new IllegalArgumentException("Current password is incorrect");
        }

        user.setPasswordHash(passwordEncoder.encode(req.getNewPassword()));
        userRepository.save(user);
        log.info("Password changed for user {}", userId);

        return new MessageResponse("Password changed successfully.");
    }

    @Transactional(readOnly = true)
    public ProfileResponse getProfile(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        Tenant tenant = user.getTenant();
        return new ProfileResponse(user.getId(), user.getName(), user.getEmail(), user.getPhone(),
                user.getRole().name(), tenant.getId(), tenant.getCompanyName(), user.getProfilePhoto());
    }

    @Transactional
    public ProfileResponse updateProfilePhoto(Long userId, String photoBase64) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        user.setProfilePhoto(photoBase64);
        userRepository.save(user);
        Tenant tenant = user.getTenant();
        return new ProfileResponse(user.getId(), user.getName(), user.getEmail(), user.getPhone(),
                user.getRole().name(), tenant.getId(), tenant.getCompanyName(), user.getProfilePhoto());
    }

    /**
     * Resolves a login/forgot-password "identifier" (typed as either an
     * email or a mobile number) to the account it belongs to.
     * <p>
     * Throws a clear, actionable message in every failure case: an
     * unrecognizable format gets a format error, while a well-formed
     * email/phone that simply isn't registered gets a "please register"
     * prompt rather than a generic "not found".
     */
    private User findUserByIdentifierOrThrow(String rawIdentifier) {
        String identifier = rawIdentifier == null ? "" : rawIdentifier.trim();
        if (identifier.isEmpty()) {
            throw new IllegalArgumentException("Enter your email or mobile number");
        }

        if (ContactNormalizer.looksLikeEmail(identifier)) {
            String email = ContactNormalizer.normalizeEmail(identifier);
            if (!ContactNormalizer.isValidEmail(email)) {
                throw new IllegalArgumentException("Enter a valid email address");
            }
            return userRepository.findByEmail(email)
                    .orElseThrow(() -> new ResourceNotFoundException(
                            "No account found for this email. Please register first."));
        }

        String phone = ContactNormalizer.normalizePhone(identifier);
        if (!ContactNormalizer.isValidPhoneDigits(phone)) {
            throw new IllegalArgumentException("Enter a valid email or mobile number");
        }
        return userRepository.findByPhone(phone)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "No account found for this mobile number. Please register first."));
    }

    /**
     * Finds an existing tenant by company name (case-insensitive) so
     * teammates joining the same company land in the same tenant, or
     * creates a brand-new tenant the first time a company name is used.
     */
    private Tenant resolveTenant(String companyName) {
        return tenantRepository.findByCompanyNameIgnoreCase(companyName.trim())
                .orElseGet(() -> tenantRepository.save(
                        Tenant.builder()
                                .companyName(companyName.trim())
                                .status(TenantStatus.ACTIVE)
                                .build()));
    }
}