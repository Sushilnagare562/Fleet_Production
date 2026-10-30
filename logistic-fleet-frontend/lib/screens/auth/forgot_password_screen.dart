import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/identifier_mode_toggle.dart';
import 'reset_password_screen.dart';

/// Step 1 of "forgot password": the user enters either the email or the
/// mobile number tied to their account and we ask the backend to email a
/// one-time verification code (delivery is email-only regardless of which
/// identifier they used to look the account up).
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  IdentifierMode _mode = IdentifierMode.email;
  bool _submitting = false;

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  void _onModeChanged(IdentifierMode mode) {
    setState(() {
      _mode = mode;
      _identifierController.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final identifier = _identifierController.text.trim();

    setState(() => _submitting = true);
    try {
      final message = await auth.forgotPassword(identifier);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          content: Text(message),
        ),
      );
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ResetPasswordScreen(identifier: identifier)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.danger,
          content: Text(auth.error ?? context.l10n.couldNotSendCode),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEmail = _mode == IdentifierMode.email;

    return Scaffold(
      backgroundColor: context.fleet.background,
      appBar: AppBar(title: Text(l10n.forgotPasswordTitle)),
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
                    const SizedBox(height: 12),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: AppGradients.tint(AppColors.primary),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 30),
                    ),
                    const SizedBox(height: 20),
                    Text(l10n.resetYourPassword,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(
                      l10n.forgotSubtitle,
                      style: TextStyle(color: context.fleet.textSecondary, fontSize: 13.5),
                    ),
                    const SizedBox(height: 22),
                    IdentifierModeToggle(mode: _mode, onChanged: _onModeChanged),
                    const SizedBox(height: 18),
                    TextFormField(
                      key: ValueKey(_mode),
                      controller: _identifierController,
                      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: isEmail ? l10n.email : l10n.mobileNumber,
                        prefixIcon: Icon(isEmail ? Icons.mail_outline_rounded : Icons.phone_outlined),
                      ),
                      validator: isEmail ? Validators.email : Validators.phone,
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
                            : Text(l10n.sendVerifyCode, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 24),
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
