import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/fleet_logo.dart';
import '../../widgets/identifier_mode_toggle.dart';
import '../../widgets/settings/language_selector.dart';
import '../admin/admin_home_screen.dart';
import '../home/home_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  IdentifierMode _mode = IdentifierMode.email;
  bool _obscurePassword = true;

  // Simple, standard entrance animation for the sign-in card: a plain state
  // flag flipped shortly after the first frame, driving AnimatedOpacity /
  // AnimatedSlide. This is intentionally boring — no custom
  // TweenAnimationBuilder / Stack+Positioned combination — so it renders
  // reliably on every platform, including Flutter web.
  bool _cardVisible = false;

  /// Prefs key for the last email/mobile that signed in — restored into the
  /// field so it shows up as a suggestion next time.
  static const _kLastIdentifier = 'last_login_identifier';

  @override
  void initState() {
    super.initState();
    _restoreSavedIdentifier();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 80), () {
        if (mounted) setState(() => _cardVisible = true);
      });
    });
  }

  Future<void> _restoreSavedIdentifier() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLastIdentifier);
    if (!mounted || saved == null || saved.isEmpty) return;
    // Only prefill when the field is still empty (don't clobber typing).
    if (_identifierController.text.isEmpty) {
      _identifierController.text = saved;
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
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
    final success = await auth.login(identifier, _passwordController.text);

    if (!mounted) return;
    if (success) {
      // Remember the email/mobile so it's pre-filled next time, and let the
      // browser/OS save the credentials for its own autofill suggestions.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLastIdentifier, identifier);
      TextInput.finishAutofillContext();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => auth.isAdmin ? const AdminHomeScreen() : const HomeScreen()),
            (route) => false,
      );
      return;
    }

    final error = auth.error ?? context.l10n.loginFailed;
    // The backend returns a specific "no account found" message when the
    // typed email/mobile number isn't registered at all (as opposed to a
    // wrong password on an existing account) — surface a direct path to
    // registration in that case rather than just a plain error.
    final notRegistered = error.toLowerCase().contains('register');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.danger,
        content: Text(error),
        action: notRegistered
            ? SnackBarAction(
                label: context.l10n.register.toUpperCase(),
                textColor: Colors.white,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l10n = context.l10n;
    final size = MediaQuery.of(context).size;
    final heroHeight = size.height * 0.32 < 240 ? 240.0 : size.height * 0.32;

    return Scaffold(
      backgroundColor: context.fleet.background,
      // A single scrollable column — hero on top, card directly below it in
      // normal document flow, pulled up over the curve with a negative
      // margin. No Stack/Positioned.fill needed for this effect, so there's
      // nothing that can silently collapse to zero height.
      body: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipPath(
                clipper: _HeroClipper(),
                child: Container(
                  height: heroHeight,
                  width: double.infinity,
                  decoration: const BoxDecoration(gradient: AppGradients.brand),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -40,
                        right: -30,
                        child: _GhostCircle(size: 140, opacity: 0.10),
                      ),
                      Positioned(
                        bottom: 10,
                        left: -50,
                        child: _GhostCircle(size: 160, opacity: 0.08),
                      ),
                      // Pre-login language switcher — drivers can pick their
                      // language before signing in.
                      Positioned(
                        top: 0,
                        right: 8,
                        child: SafeArea(
                          bottom: false,
                          child: LanguageShortcut(color: Colors.white),
                        ),
                      ),
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 18),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const AnimatedLogisticFleetLogo(size: 78),
                              const SizedBox(height: 14),
                              const LogisticFleetWordmark(fontSize: 26),
                              const SizedBox(height: 4),
                              Text(
                                l10n.appTagline,
                                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12.5, letterSpacing: 0.3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedOpacity(
                opacity: _cardVisible ? 1 : 0,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                child: AnimatedSlide(
                  offset: _cardVisible ? Offset.zero : const Offset(0, 0.04),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Container(
                        margin: const EdgeInsets.only(top: 30, left: 20, right: 20),
                        padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
                        decoration: BoxDecoration(
                          color: context.fleet.surface,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: AppShadows.soft,
                        ),
                        child: Form(
                          key: _formKey,
                          child: AutofillGroup(
                            child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(l10n.welcomeBack,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 6),
                              Text(
                                l10n.signInSubtitleLong,
                                style: TextStyle(color: context.fleet.textSecondary, fontSize: 13.5),
                              ),
                              const SizedBox(height: 24),
                              IdentifierModeToggle(mode: _mode, onChanged: _onModeChanged),
                              const SizedBox(height: 18),
                              TextFormField(
                                key: ValueKey(_mode),
                                controller: _identifierController,
                                textInputAction: TextInputAction.next,
                                autofillHints: _mode == IdentifierMode.email
                                    ? const [AutofillHints.username, AutofillHints.email]
                                    : const [AutofillHints.telephoneNumber],
                                keyboardType: _mode == IdentifierMode.email
                                    ? TextInputType.emailAddress
                                    : TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: _mode == IdentifierMode.email ? l10n.email : l10n.mobileNumber,
                                  prefixIcon: Icon(
                                    _mode == IdentifierMode.email ? Icons.mail_outline_rounded : Icons.phone_outlined,
                                  ),
                                ),
                                validator: _mode == IdentifierMode.email ? Validators.email : Validators.phone,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                // Pressing Enter after typing the password logs
                                // straight in, no need to reach for the button.
                                onFieldSubmitted: (_) {
                                  if (!auth.loading) _submit();
                                },
                                decoration: InputDecoration(
                                  labelText: l10n.password,
                                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: Validators.loginPassword,
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                                  ),
                                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
                                  child: Text(l10n.forgotPassword, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: auth.loading ? null : AppGradients.brand,
                                    color: auth.loading ? AppColors.primary.withOpacity(0.6) : null,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: auth.loading ? null : AppShadows.brand,
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    onPressed: auth.loading ? null : _submit,
                                    child: auth.loading
                                        ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                        : Text(l10n.signIn, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Center(
                                child: TextButton(
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                  ),
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(color: context.fleet.textSecondary, fontSize: 13.5),
                                      children: [
                                        TextSpan(text: '${l10n.dontHaveAccount} '),
                                        TextSpan(
                                          text: l10n.register,
                                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _GhostCircle extends StatelessWidget {
  final double size;
  final double opacity;

  const _GhostCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: Colors.white.withOpacity(opacity), shape: BoxShape.circle),
    );
  }
}

class _HeroClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(size.width * 0.5, size.height, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
