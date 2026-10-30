import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ---------------------------------------------------------------------------
/// BRAND + LIGHT SEMANTIC PALETTE
///
/// These are kept as `const Color` fields (unchanged from the original app) so
/// that the ~23 existing screens that reference `AppColors.primary`,
/// `AppColors.textPrimary`, etc. in `const` contexts keep compiling untouched.
///
/// For NEW / migrated widgets, prefer the theme-aware semantic colors exposed
/// via `context.fleet` (see [FleetColors] below), which resolve correctly in
/// both light and dark mode. Migration is a mechanical swap:
///   AppColors.textPrimary   ->  context.fleet.textPrimary
///   AppColors.background     ->  context.fleet.background
///   AppColors.surface        ->  context.fleet.surface
///   AppColors.textSecondary  ->  context.fleet.textSecondary
///   AppColors.divider        ->  context.fleet.divider
/// (done in non-const contexts). Brand + status colors are the same in both
/// themes and can stay as AppColors.* if desired.
/// ---------------------------------------------------------------------------
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFF57C00); // vivid orange - brand color
  static const Color primaryDark = Color(0xFFE65100);
  static const Color primaryLight = Color(0xFFFF9D3C);
  static const Color accent = Color(0xFFFF7043); // warm coral-orange accent for CTAs/alerts
  static const Color accentDark = Color(0xFFF4511E);
  static const Color background = Color(0xFFFFF8F3); // warm, very light off-white
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF201A16);
  static const Color textSecondary = Color(0xFF7A6E66);
  static const Color success = Color(0xFF2E9E5B);
  static const Color warning = Color(0xFFF9A825); // amber - distinct from the orange brand
  static const Color danger = Color(0xFFD64545);
  static const Color divider = Color(0xFFEFE4DB);
}

/// Dark-mode semantic palette. Not a naive inversion — a proper dark enterprise
/// surface stack with muted, accessible orange accents.
class AppColorsDark {
  AppColorsDark._();

  static const Color primary = Color(0xFFFF9D3C); // slightly lifted so it reads on dark
  static const Color accent = Color(0xFFFF8A65);
  static const Color background = Color(0xFF151311); // warm near-black, not pure black
  static const Color surface = Color(0xFF201C19); // one step lighter than background
  static const Color surfaceAlt = Color(0xFF2A2521);
  static const Color textPrimary = Color(0xFFF3EDE7);
  static const Color textSecondary = Color(0xFFB4A79D);
  static const Color success = Color(0xFF56C08A);
  static const Color warning = Color(0xFFF6B93B);
  static const Color danger = Color(0xFFE57373);
  static const Color divider = Color(0xFF3A332E);
}

/// Theme-aware semantic colors, resolved from the active [ThemeData].
/// Access via `context.fleet`.
@immutable
class FleetColors extends ThemeExtension<FleetColors> {
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;
  final Color success;
  final Color warning;
  final Color danger;

  const FleetColors({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
    required this.success,
    required this.warning,
    required this.danger,
  });

  static const FleetColors light = FleetColors(
    background: AppColors.background,
    surface: AppColors.surface,
    surfaceAlt: Color(0xFFFDF3EB),
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    divider: AppColors.divider,
    success: AppColors.success,
    warning: AppColors.warning,
    danger: AppColors.danger,
  );

  static const FleetColors dark = FleetColors(
    background: AppColorsDark.background,
    surface: AppColorsDark.surface,
    surfaceAlt: AppColorsDark.surfaceAlt,
    textPrimary: AppColorsDark.textPrimary,
    textSecondary: AppColorsDark.textSecondary,
    divider: AppColorsDark.divider,
    success: AppColorsDark.success,
    warning: AppColorsDark.warning,
    danger: AppColorsDark.danger,
  );

  @override
  FleetColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? textPrimary,
    Color? textSecondary,
    Color? divider,
    Color? success,
    Color? warning,
    Color? danger,
  }) {
    return FleetColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      divider: divider ?? this.divider,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
    );
  }

  @override
  FleetColors lerp(ThemeExtension<FleetColors>? other, double t) {
    if (other is! FleetColors) return this;
    return FleetColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

extension FleetColorsX on BuildContext {
  /// Theme-aware semantic colors (background/surface/text/divider/status).
  FleetColors get fleet =>
      Theme.of(this).extension<FleetColors>() ?? FleetColors.light;
}

class AppGradients {
  AppGradients._();

  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primaryLight, AppColors.primary, AppColors.primaryDark],
  );

  static const LinearGradient brandVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.primary, AppColors.primaryDark],
  );

  static const LinearGradient accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.accent, AppColors.accentDark],
  );

  /// Warm red gradient for destructive CTAs (e.g. the profile "Log out"
  /// button). Fixed reds so it reads the same in light and dark themes.
  static const LinearGradient danger = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF16565), Color(0xFFD64545)],
  );

  static LinearGradient tint(Color color) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color.withOpacity(0.16), color.withOpacity(0.06)],
      );
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> soft = [
    BoxShadow(
      color: AppColors.primaryDark.withOpacity(0.06),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> brand = [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.28),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];
}

/// Design-system spacing scale (4,8,12,16,20,24,32,40,48).
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 48;
}

/// Responsive breakpoints.
class AppBreakpoints {
  AppBreakpoints._();
  static const double mobile = 600;
  static const double tablet = 1024;
  static const double desktop = 1440;

  static bool isMobile(BuildContext c) => MediaQuery.sizeOf(c).width < mobile;
  static bool isTablet(BuildContext c) {
    final w = MediaQuery.sizeOf(c).width;
    return w >= mobile && w < tablet;
  }

  static bool isDesktop(BuildContext c) => MediaQuery.sizeOf(c).width >= tablet;
}

class AppTheme {
  AppTheme._();

  /// Picks a Google Fonts text theme that can actually render the given
  /// locale's script. Inter has no Devanagari/Gujarati/Tamil glyphs, so Indic
  /// locales fall back to the matching Noto Sans family.
  static TextTheme _localizedTextTheme(TextTheme base, Locale? locale) {
    switch (locale?.languageCode) {
      case 'hi':
      case 'mr':
        return GoogleFonts.notoSansDevanagariTextTheme(base);
      case 'gu':
        return GoogleFonts.notoSansGujaratiTextTheme(base);
      case 'ta':
        return GoogleFonts.notoSansTamilTextTheme(base);
      case 'en':
      default:
        return GoogleFonts.interTextTheme(base);
    }
  }

  /// Backwards-compatible getter. Existing code calling `AppTheme.light`
  /// (with no locale) keeps working and gets the English/Inter theme.
  static ThemeData get light => buildLight(null);

  static ThemeData buildLight(Locale? locale) {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    final textTheme = _localizedTextTheme(base.textTheme, locale);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      extensions: const [FleetColors.light],
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.danger,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.divider),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: _elevatedButtonTheme(textTheme, AppColors.primary),
      outlinedButtonTheme: _outlinedButtonTheme(AppColors.primary),
      textButtonTheme: _textButtonTheme(textTheme, AppColors.primary),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 3,
      ),
      inputDecorationTheme: _inputTheme(
        fill: AppColors.surface,
        border: AppColors.divider,
        focus: AppColors.primary,
        error: AppColors.danger,
        label: AppColors.textSecondary,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        selectedIconTheme: IconThemeData(color: AppColors.primary),
        unselectedIconTheme: IconThemeData(color: AppColors.textSecondary),
        indicatorColor: Color(0x1FF57C00),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: TextStyle(fontWeight: FontWeight.w700),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.background,
        selectedColor: AppColors.primary.withOpacity(0.12),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: const BorderSide(color: AppColors.divider),
      ),
    );
  }

  static ThemeData buildDark(Locale? locale) {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);
    final textTheme = _localizedTextTheme(base.textTheme, locale);

    return base.copyWith(
      scaffoldBackgroundColor: AppColorsDark.background,
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      extensions: const [FleetColors.dark],
      colorScheme: base.colorScheme.copyWith(
        primary: AppColorsDark.primary,
        secondary: AppColorsDark.accent,
        surface: AppColorsDark.surface,
        error: AppColorsDark.danger,
        onPrimary: const Color(0xFF201A16),
        onSurface: AppColorsDark.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColorsDark.background,
        foregroundColor: AppColorsDark.textPrimary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColorsDark.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColorsDark.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColorsDark.divider),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: _elevatedButtonTheme(textTheme, AppColorsDark.primary,
          foreground: const Color(0xFF201A16)),
      outlinedButtonTheme: _outlinedButtonTheme(AppColorsDark.primary),
      textButtonTheme: _textButtonTheme(textTheme, AppColorsDark.primary),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColorsDark.accent,
        foregroundColor: Color(0xFF201A16),
        elevation: 3,
      ),
      inputDecorationTheme: _inputTheme(
        fill: AppColorsDark.surfaceAlt,
        border: AppColorsDark.divider,
        focus: AppColorsDark.primary,
        error: AppColorsDark.danger,
        label: AppColorsDark.textSecondary,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColorsDark.surface,
        selectedItemColor: AppColorsDark.primary,
        unselectedItemColor: AppColorsDark.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColorsDark.surface,
        selectedIconTheme: IconThemeData(color: AppColorsDark.primary),
        unselectedIconTheme: IconThemeData(color: AppColorsDark.textSecondary),
        indicatorColor: Color(0x33FF9D3C),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColorsDark.primary,
        unselectedLabelColor: AppColorsDark.textSecondary,
        indicatorColor: AppColorsDark.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: TextStyle(fontWeight: FontWeight.w700),
      ),
      dividerTheme: const DividerThemeData(color: AppColorsDark.divider, thickness: 1),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColorsDark.surfaceAlt,
        selectedColor: AppColorsDark.primary.withOpacity(0.18),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColorsDark.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: const BorderSide(color: AppColorsDark.divider),
      ),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme(TextTheme t, Color bg,
          {Color foreground = Colors.white}) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: foreground,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      );

  static OutlinedButtonThemeData _outlinedButtonTheme(Color c) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c,
          side: BorderSide(color: c),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );

  static TextButtonThemeData _textButtonTheme(TextTheme t, Color c) =>
      TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c,
          textStyle: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      );

  static InputDecorationTheme _inputTheme({
    required Color fill,
    required Color border,
    required Color focus,
    required Color error,
    required Color label,
  }) =>
      InputDecorationTheme(
        filled: true,
        fillColor: fill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: focus, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: error, width: 1.2),
        ),
        labelStyle: TextStyle(color: label),
      );
}

class StatusColors {
  StatusColors._();

  static Color forTripStatus(String status) {
    switch (status) {
      case 'ASSIGNED':
        return AppColors.warning;
      case 'IN_PROGRESS':
        return AppColors.primary;
      case 'COMPLETED':
        return AppColors.success;
      case 'CANCELLED':
        return AppColors.danger;
      default:
        return AppColors.textSecondary;
    }
  }

  static IconData iconForTripStatus(String status) {
    switch (status) {
      case 'ASSIGNED':
        return Icons.pending_actions_rounded;
      case 'IN_PROGRESS':
        return Icons.local_shipping_rounded;
      case 'COMPLETED':
        return Icons.check_circle_rounded;
      case 'CANCELLED':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  /// Raw fallback label (English, spaces). Prefer the localized version:
  /// `context.l10n.tripStatus(status)` — see AppLocalizations.
  static String labelForTripStatus(String status) => status.replaceAll('_', ' ');
}
