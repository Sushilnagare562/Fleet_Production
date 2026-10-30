import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme.dart';
import '../../providers/settings_provider.dart';

/// Light / Dark selector. Switches instantly (no restart) and the
/// [SettingsProvider] persists the choice.
class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = context.watch<SettingsProvider>();
    final fleet = context.fleet;

    // Older installs may still have ThemeMode.system persisted from before
    // this option was removed from the UI; resolve it to the platform's
    // current brightness so one of the two tiles always reads as selected.
    final effective = settings.themeMode == ThemeMode.system
        ? (MediaQuery.platformBrightnessOf(context) == Brightness.dark ? ThemeMode.dark : ThemeMode.light)
        : settings.themeMode;

    final options = <_ThemeOption>[
      _ThemeOption(ThemeMode.light, Icons.light_mode_rounded, l10n.themeLight, l10n.themeLightSubtitle),
      _ThemeOption(ThemeMode.dark, Icons.dark_mode_rounded, l10n.themeDark, l10n.themeDarkSubtitle),
    ];

    return Column(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) Divider(height: 1, indent: 16, endIndent: 16, color: fleet.divider),
          _SelectableTile(
            icon: options[i].icon,
            title: options[i].title,
            subtitle: options[i].subtitle,
            selected: effective == options[i].mode,
            onTap: () => context.read<SettingsProvider>().setThemeMode(options[i].mode),
          ),
        ],
      ],
    );
  }
}

class _ThemeOption {
  final ThemeMode mode;
  final IconData icon;
  final String title;
  final String subtitle;
  const _ThemeOption(this.mode, this.icon, this.title, this.subtitle);
}

class _SelectableTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _SelectableTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fleet = context.fleet;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: scheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 19, color: scheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w600, color: fleet.textPrimary)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: TextStyle(fontSize: 12, color: fleet.textSecondary)),
                  ],
                ],
              ),
            ),
            AnimatedScale(
              scale: selected ? 1 : 0,
              duration: const Duration(milliseconds: 150),
              child: Icon(Icons.check_circle_rounded, color: scheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}