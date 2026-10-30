import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme.dart';
import '../../providers/settings_provider.dart';

/// One-click language list. Each row shows the native name (e.g. हिंदी) with the
/// English name beneath, so both drivers and admins can find their language.
/// Selecting switches the whole app immediately (no restart) and persists.
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final fleet = context.fleet;
    final current = settings.effectiveLocale.languageCode;
    final codes = AppLocalizations.supportedLocales.map((l) => l.languageCode).toList();

    return Column(
      children: [
        for (var i = 0; i < codes.length; i++) ...[
          if (i > 0) Divider(height: 1, indent: 16, endIndent: 16, color: fleet.divider),
          _LanguageTile(
            code: codes[i],
            selected: current == codes[i],
            onTap: () => context.read<SettingsProvider>().setLocale(Locale(codes[i])),
          ),
        ],
      ],
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String code;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile({required this.code, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fleet = context.fleet;
    final native = AppLocalizations.languageNames[code] ?? code;
    final english = AppLocalizations.languageEnglishNames[code] ?? code;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(native.isNotEmpty ? native.substring(0, 1) : '?',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: scheme.primary)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(native,
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600, color: fleet.textPrimary)),
                  const SizedBox(height: 2),
                  Text(english, style: TextStyle(fontSize: 12, color: fleet.textSecondary)),
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

/// Dropdown variant of the language picker — a single tappable field showing
/// the current language, expanding into the full list. Used on the Profile
/// screen so switching languages doesn't take up a full stack of rows.
class LanguageDropdown extends StatelessWidget {
  const LanguageDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final fleet = context.fleet;
    final current = settings.effectiveLocale.languageCode;
    final codes = AppLocalizations.supportedLocales.map((l) => l.languageCode).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: codes.contains(current) ? current : codes.first,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: fleet.textSecondary),
          dropdownColor: fleet.surface,
          borderRadius: BorderRadius.circular(14),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 10),
          ),
          selectedItemBuilder: (context) => codes
              .map((code) => Align(
            alignment: Alignment.centerLeft,
            child: _LanguageDropdownRow(code: code, dense: true),
          ))
              .toList(),
          items: codes
              .map((code) => DropdownMenuItem<String>(
            value: code,
            child: _LanguageDropdownRow(code: code, dense: false),
          ))
              .toList(),
          onChanged: (code) {
            if (code != null) context.read<SettingsProvider>().setLocale(Locale(code));
          },
        ),
      ),
    );
  }
}

class _LanguageDropdownRow extends StatelessWidget {
  final String code;
  final bool dense;

  const _LanguageDropdownRow({required this.code, required this.dense});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fleet = context.fleet;
    final native = AppLocalizations.languageNames[code] ?? code;
    final english = AppLocalizations.languageEnglishNames[code] ?? code;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: dense ? 30 : 34,
          height: dense ? 30 : 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(native.isNotEmpty ? native.substring(0, 1) : '?',
              style: TextStyle(fontSize: dense ? 13 : 15, fontWeight: FontWeight.w700, color: scheme.primary)),
        ),
        const SizedBox(width: 12),
        Text(native, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: fleet.textPrimary)),
        const SizedBox(width: 6),
        Text('($english)', style: TextStyle(fontSize: 12, color: fleet.textSecondary)),
      ],
    );
  }
}

/// Compact header shortcut (e.g. for the driver app bar): shows a globe + the
/// current language's native name and opens a bottom sheet to switch.
class LanguageShortcut extends StatelessWidget {
  /// Optional override for foreground/accent color — pass e.g. [Colors.white]
  /// when placing the shortcut on a colored (brand-gradient) surface.
  final Color? color;

  const LanguageShortcut({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final scheme = Theme.of(context).colorScheme;
    final fg = color ?? scheme.primary;
    final code = settings.effectiveLocale.languageCode;
    final native = AppLocalizations.languageNames[code] ?? code;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => showLanguageSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: fg.withOpacity(color != null ? 0.20 : 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language_rounded, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(native,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
          ],
        ),
      ),
    );
  }
}

Future<void> showLanguageSheet(BuildContext context) {
  final fleet = context.fleet;
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    backgroundColor: fleet.surface,
    // Scroll-controlled so the sheet can grow, and the list below is itself
    // scrollable — together these stop the "BOTTOM OVERFLOWED BY … PIXELS"
    // error that showed up when the browser/device was zoomed in and the
    // fixed-height column no longer fit the default half-screen sheet.
    isScrollControlled: true,
    builder: (ctx) {
      final maxHeight = MediaQuery.of(ctx).size.height * 0.85;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(ctx.l10n.selectLanguage,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ctx.fleet.textPrimary)),
              ),
              // Flexible + scroll view: the list takes only the room it needs,
              // but can scroll instead of overflowing when space is tight.
              Flexible(
                child: SingleChildScrollView(
                  child: const LanguageSelector(),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}