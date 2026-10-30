import 'package:flutter/material.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme.dart';

/// Which kind of identifier the user is currently typing into a single
/// "email or mobile number" field. Login and forgot-password both need
/// this so the field's label/icon/keyboard and validator can match what's
/// actually expected.
enum IdentifierMode { email, mobile }

/// Small pill-shaped two-way toggle: "Email" / "Mobile number".
class IdentifierModeToggle extends StatelessWidget {
  final IdentifierMode mode;
  final ValueChanged<IdentifierMode> onChanged;

  const IdentifierModeToggle({super.key, required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.fleet.background,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: context.fleet.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Segment(
              label: context.l10n.email,
              icon: Icons.mail_outline_rounded,
              selected: mode == IdentifierMode.email,
              onTap: () => onChanged(IdentifierMode.email),
            ),
          ),
          Expanded(
            child: _Segment(
              label: context.l10n.mobileNumber,
              icon: Icons.phone_outlined,
              selected: mode == IdentifierMode.mobile,
              onTap: () => onChanged(IdentifierMode.mobile),
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _Segment({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: selected ? Colors.white : context.fleet.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : context.fleet.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
