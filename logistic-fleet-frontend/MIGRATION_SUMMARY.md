# Fleet App — Theming + Localization Migration Summary

## What was delivered
- **Light / Dark / System theme** with runtime switching + persistence
  (`SharedPreferences`). Semantic colors resolve via a `FleetColors`
  `ThemeExtension` (`context.fleet.*`); brand/status colors stay in `AppColors`.
- **5-language i18n**: English, हिंदी, मराठी, ગુજરાતી, தமிழ் — runtime switch,
  persistence, system-default detection, English fallback for any missing key.
  **358 keys per language**, 1:1 with typed getters (`context.l10n.*`), so a
  missing/mistyped key is a compile error, not a blank UI string.
- Enum values are **never translated** — they map to localized labels at the UI
  layer (`tripStatus`, `expenseCategory`, `earningStatus`, `vehicleType`,
  `vehicleStatus`, `reportTypeLabel/Desc`, `reportPeriodLabel`, plus in-screen
  helpers for stop type / device status). Backend/API/enums are untouched.
- **All ~40 screens migrated** for i18n + dark mode: auth (heavily restyled +
  responsive + pre-login language switcher), driver flow (trips, expenses,
  earnings, profile, password), and admin (dashboard, drivers, vehicles,
  assign-trip, live-tracking, reports, approvals, etc.).
- Responsive `maxWidth` containers on auth + form screens; dashboard uses a
  responsive grid.

## How to run
1. `flutter pub get`  (adds `flutter_localizations`, `shared_preferences`)
2. `flutter analyze`  ← please run this; see caveat below
3. `flutter run`

## Honest status / caveats
- This migration was done and **statically verified** (5-way key parity, all
  `l10n` references resolve, no leftover hardcoded UI strings or semantic
  `AppColors`, brace/import balance) but **was NOT compiled** — no Flutter SDK
  was available in the build environment. Expect `flutter analyze` to surface a
  small number of residual issues (most likely a stray `const` in front of a
  now-runtime color/string) that are quick to fix.
- Fonts load at runtime via `google_fonts`. For offline/production, bundle the
  Noto Devanagari / Gujarati / Tamil families as assets.
- The Indic translations are solid but should get a **native-speaker review**
  before shipping, especially longer sentences.
- `intl` is pinned at `^0.19.0` to match the existing project; if
  `flutter_localizations` complains, align it to the version your Flutter ships.
