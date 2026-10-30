import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';

/// Step 2 of "forgot password": the user enters the code sent to them
/// (see ForgotPasswordScreen) along with a new password. [identifier] is
/// whichever email or mobile number they submitted in step 1 — it's sent
/// back unchanged so the backend can re-resolve the same account.
class ResetPasswordScreen extends StatefulWidget {
  final String identifier;
  const ResetPasswordScreen({super.key, required this.identifier});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _submitting = false;
  bool _resending = false;

  bool get _isEmail => Validators.looksLikeEmail(widget.identifier);

  @override
  void dispose() {
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();

    setState(() => _submitting = true);
    try {
      final message = await auth.resetPassword(
        identifier: widget.identifier,
        otp: _otpController.text.trim(),
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          content: Text(message),
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.danger,
          content: Text(auth.error ?? context.l10n.couldNotResetPassword),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _resend() async {
    final auth = context.read<AuthProvider>();
    setState(() => _resending = true);
    try {
      final message = await auth.forgotPassword(widget.identifier);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, backgroundColor: AppColors.success, content: Text(message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.danger,
          content: Text(auth.error ?? context.l10n.couldNotResendCode),
        ),
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: context.fleet.background,
      appBar: AppBar(title: Text(l10n.enterVerifyCode)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        style: TextStyle(color: context.fleet.textSecondary, fontSize: 13.5),
                        children: [
                          TextSpan(text: _isEmail ? l10n.codeSentEmail : l10n.codeSentMobile),
                          TextSpan(
                            text: widget.identifier,
                            style: TextStyle(fontWeight: FontWeight.w700, color: context.fleet.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        labelText: l10n.verificationCode,
                        counterText: '',
                        prefixIcon: const Icon(Icons.pin_outlined),
                      ),
                      validator: Validators.otp,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: _obscureNew,
                      decoration: InputDecoration(
                        labelText: l10n.newPassword,
                        helperText: l10n.passwordRule,
                        helperMaxLines: 2,
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureNew ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                          onPressed: () => setState(() => _obscureNew = !_obscureNew),
                        ),
                      ),
                      validator: Validators.password,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: l10n.confirmNewPassword,
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (v) => Validators.confirmPassword(v, _newPasswordController.text),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(l10n.resetPassword, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: _resending ? null : _resend,
                        child: Text(_resending ? l10n.sending : l10n.resendCode),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
