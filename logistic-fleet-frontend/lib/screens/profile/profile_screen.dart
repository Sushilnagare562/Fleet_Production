import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/settings/language_selector.dart';
import '../../widgets/settings/theme_mode_selector.dart';
import '../auth/login_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    // Login/register responses keep the payload small (no phone/photo), so
    // pull the full profile once this tab is actually opened.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().refreshProfile();
    });
  }

  Future<void> _pickAndUploadPhoto() async {
    final l10n = context.l10n;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    try {
      final bytes = await picked.readAsBytes();
      final base64Data = base64Encode(bytes);
      final auth = context.read<AuthProvider>();
      final success = await auth.updateProfilePhoto(base64Data);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: success ? context.fleet.success : context.fleet.danger,
          content: Text(success
              ? l10n.profilePhotoUpdated
              : (auth.error ?? l10n.couldNotUpdatePhoto)),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.fleet.danger,
          content: Text(l10n.couldNotReadImage),
        ),
      );
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fleet = context.fleet;
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final hasPhoto = user?.profilePhoto != null && user!.profilePhoto!.isNotEmpty;

    // Constrain width so the screen also reads well on tablet/web/desktop.
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            // Extra bottom padding (base + the device's safe-area inset) so the
            // last controls clear the phone's gesture bar and the page can be
            // scrolled all the way to the bottom on mobile.
            padding: EdgeInsets.fromLTRB(
              AppSpacing.base,
              AppSpacing.base,
              AppSpacing.base,
              AppSpacing.base + AppSpacing.xl + MediaQuery.of(context).padding.bottom,
            ),
            children: [
              // ---- Profile header ----
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor:
                            Theme.of(context).colorScheme.primary.withOpacity(0.12),
                            backgroundImage:
                            hasPhoto ? MemoryImage(base64Decode(user.profilePhoto!)) : null,
                            child: !hasPhoto
                                ? Text(
                              (user?.name.isNotEmpty == true ? user!.name[0] : '?')
                                  .toUpperCase(),
                              style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.primary),
                            )
                                : null,
                          ),
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  gradient: AppGradients.brand,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: fleet.surface, width: 2.5),
                                ),
                                child: _uploadingPhoto
                                    ? const Padding(
                                  padding: EdgeInsets.all(7),
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                                    : const Icon(Icons.camera_alt_rounded,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(user?.name ?? '',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700, color: fleet.textPrimary)),
                      if ((user?.companyName ?? '').isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(user!.companyName!,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: fleet.textSecondary)),
                      ],
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(user?.role ?? '',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ---- Account details ----
              _SectionLabel(l10n.accountDetails),
              const SizedBox(height: AppSpacing.sm),
              Card(
                child: Column(
                  children: [
                    _ProfileInfoTile(
                        icon: Icons.badge_outlined, label: l10n.username, value: user?.name ?? '—'),
                    _dividerTile(fleet),
                    _ProfileInfoTile(
                        icon: Icons.mail_outline_rounded,
                        label: l10n.emailAddress,
                        value: user?.email ?? '—'),
                    _dividerTile(fleet),
                    _ProfileInfoTile(
                      icon: Icons.call_outlined,
                      label: l10n.mobileNumber,
                      value: (user != null && user.phone.isNotEmpty) ? user.phone : '—',
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ---- Appearance: theme ----
              _SectionLabel(l10n.appearance),
              const SizedBox(height: AppSpacing.sm),
              Card(child: const ThemeModeSelector()),
              const SizedBox(height: AppSpacing.lg),

              // ---- Language ----
              _SectionLabel(l10n.language),
              const SizedBox(height: AppSpacing.sm),
              Card(child: const LanguageDropdown()),
              const SizedBox(height: AppSpacing.lg),

              // ---- Security ----
              _SectionLabel(l10n.security),
              const SizedBox(height: AppSpacing.base),
              // Centered, content-width gradient CTAs (not stretched edge to
              // edge) — more prominent than the old faint outlined buttons.
              Center(
                child: Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  alignment: WrapAlignment.center,
                  children: [
                    GradientButton(
                      label: l10n.changePassword,
                      icon: Icons.lock_reset_rounded,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                      ),
                    ),
                    GradientButton(
                      label: l10n.logout,
                      icon: Icons.logout,
                      gradient: AppGradients.danger,
                      // Logout logic preserved exactly as in the original screen.
                      onPressed: () async {
                        await context.read<AuthProvider>().logout();
                        if (!context.mounted) return;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dividerTile(FleetColors fleet) =>
      Divider(height: 1, indent: 16, endIndent: 16, color: fleet.divider);
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700, color: context.fleet.textPrimary));
  }
}

class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final fleet = context.fleet;
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11.5, color: fleet.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w600, color: fleet.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}