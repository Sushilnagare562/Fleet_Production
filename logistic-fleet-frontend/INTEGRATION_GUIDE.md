# Fleet App — Theme + Localization Foundation (Phase 1)

This drop-in adds a centralized **Light/Dark/System theme** system and a
**5-language localization** system (English, Hindi, Marathi, Gujarati, Tamil),
both **runtime-switchable and persisted**, plus a redesigned **Profile →
Appearance + Language** screen. It does **not** touch your API client,
services, models, or business providers.

> Built and statically verified without a Flutter SDK in the authoring
> environment. It has **not** been run through `flutter analyze` / `flutter
> build` — do that as step 0 below.

## 1. Install

1. Copy the contents of this `lib/` over your project's `lib/`, replacing:
   - `lib/main.dart`
   - `lib/core/theme.dart`
   - `lib/screens/profile/profile_screen.dart`
   - `lib/screens/home/home_screen.dart`
   - `lib/screens/admin/admin_home_screen.dart`
   And adding (new):
   - `lib/core/localization/*` (delegate + 5 string maps)
   - `lib/core/settings/settings_service.dart`
   - `lib/providers/settings_provider.dart`
   - `lib/widgets/settings/theme_mode_selector.dart`
   - `lib/widgets/settings/language_selector.dart`
2. Apply the two `pubspec.yaml` additions (already in the included
   `pubspec.yaml`):
   ```yaml
   flutter_localizations:
     sdk: flutter
   shared_preferences: ^2.3.2
   ```
3. `flutter pub get`
4. **`flutter analyze`** then `flutter run` (mobile) / `flutter run -d chrome`.

## 2. What works immediately

- Theme toggle Light / Dark / System in **Profile → Appearance**, no restart,
  persisted across app/device/browser restarts.
- Language switch in **Profile → Language** (native names + English subtitle),
  no restart, persisted. Default = device language if supported, else English;
  a manual choice always wins.
- Devanagari / Gujarati / Tamil render with the correct Noto fonts (Inter has no
  Indic glyphs) — handled automatically by locale in `AppTheme`.
- All standard Material components (app bars, cards, inputs, nav bars, dialogs)
  adapt to dark mode everywhere via `ThemeData`.
- Navigation labels (driver + admin bottom bars) are localized.

## 3. Extending to the remaining screens (the mechanical pattern)

The other ~35 screens still contain hardcoded English strings and
`AppColors.*` semantic colors. Migrating each is two find-replace passes, **no
logic changes**:

**Strings** — add `import '../../core/localization/app_localizations.dart';`
then:
```dart
Text('Start trip')          ->  Text(context.l10n.startTrip)
AppBar(title: Text('Trips'))->  AppBar(title: Text(context.l10n.trips))
```
If a string isn't in the key set yet, add the key to `strings_en.dart` (+ a
getter in `app_localizations.dart`) and translate it in the other four files.
Missing keys already fall back to English, so the app never shows a blank/raw
key.

**Dark-mode colors** — swap the *semantic* colors (brand + status colors can
stay as `AppColors.*`, they're the same in both themes). In **non-const**
contexts:
```dart
AppColors.textPrimary    ->  context.fleet.textPrimary
AppColors.textSecondary  ->  context.fleet.textSecondary
AppColors.background     ->  context.fleet.background
AppColors.surface        ->  context.fleet.surface
AppColors.divider        ->  context.fleet.divider
```
Prefer `Theme.of(context).colorScheme.primary` for the brand accent so it
lifts correctly in dark mode.

For trip status labels use `context.l10n.tripStatus(trip.status)` — it maps the
untouched backend enum value to a localized label. `StatusColors.forTripStatus`
still gives the color.

## 4. Fleet-term glossary (keep terminology consistent)

| Key | English | Hindi | Marathi | Gujarati | Tamil |
|---|---|---|---|---|---|
| startTrip | Start trip | यात्रा शुरू करें | प्रवास सुरू करा | મુસાફરી શરૂ કરો | பயணத்தைத் தொடங்கு |
| completeTrip | Complete trip | यात्रा पूरी करें | प्रवास पूर्ण करा | મુસાફરી પૂર્ણ કરો | பயணத்தை முடி |
| trips | Trips | यात्राएँ | प्रवास | મુસાફરીઓ | பயணங்கள் |
| expenses | Expenses | खर्चे | खर्च | ખર્ચ | செலவுகள் |
| earnings | Earnings | कमाई | कमाई | કમાણી | வருமானம் |
| vehicle | Vehicle | वाहन | वाहन | વાહન | வாகனம் |
| driver | Driver | ड्राइवर | चालक | ડ્રાઇવર | ஓட்டுநர் |
| statusInProgress | In progress | चल रही है | सुरू आहे | ચાલુ છે | நடந்து கொண்டிருக்கிறது |

The full set of 117 keys lives in `lib/core/localization/strings_*.dart`.

## 5. Backend / DB

**No backend or DB change is required or included.** Language and theme are
client-side presentation preferences persisted locally. Trip/vehicle statuses
are backend enums (`ASSIGNED`, `IN_PROGRESS`, …) and are **not** translated at
the data layer — the client maps enum → localized label, so API request/response
parsing is untouched. (If you ever want language to sync across a user's devices,
add an optional `preferredLanguage` column + a profile endpoint later; it is not
needed for the requirements here.)

## 6. Honest status

- ✅ Compiles-by-inspection: braces/imports/symbols checked; key parity across
  all 5 languages verified (117/117).
- ❌ Not run through `flutter analyze` / `flutter build` (no SDK in the
  authoring env). Run it before shipping.
- ⚠️ Un-migrated screens stay light-styled in dark mode until section 3 is
  applied to them. Material chrome is already dark-aware everywhere.
- Translations are human-checked for common fleet terms; have a native speaker
  review before production, especially longer admin strings.
