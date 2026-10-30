import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/app_logger.dart';
import 'core/localization/app_localizations.dart';
import 'core/theme.dart';
import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/earning_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/live_tracking_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/trip_provider.dart';
import 'screens/splash_gate.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Push notifications only work once a Firebase project is wired up
  // (google-services.json for Android / GoogleService-Info.plist for iOS -
  // see the setup guide). Until then this just fails quietly and the rest
  // of the app runs exactly as before.
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    AppLogger.w('Startup', 'Firebase not configured yet - push notifications disabled', error: e);
  }

  runApp(const LogisticFleetApp());
}

class LogisticFleetApp extends StatelessWidget {
  const LogisticFleetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Presentation prefs (theme + language). Loaded once; kept separate
        // from all business/API providers below.
        ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TripProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => EarningProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => LiveTrackingProvider()),
      ],
      // Only rebuild MaterialApp when theme/locale change — business providers
      // never trigger a full app rebuild here.
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          final locale = settings.effectiveLocale;
          return MaterialApp(
            title: 'Logistic Fleet Driver',
            debugShowCheckedModeBanner: false,

            // On web, Flutter's default scroll behaviour only reacts to touch
            // + mouse-wheel, so on a laptop/PC a mouse *drag* can't reach the
            // bottom of long pages. Enabling mouse/trackpad/stylus as drag
            // devices fixes the "can't scroll to the bottom" issue everywhere.
            scrollBehavior: const _AppScrollBehavior(),

            // ---- Theme: light + dark + system, runtime-switchable ----
            theme: AppTheme.buildLight(locale),
            darkTheme: AppTheme.buildDark(locale),
            themeMode: settings.themeMode,

            // ---- Localization: 5 languages, runtime-switchable ----
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            home: const SplashGate(),
          );
        },
      ),
    );
  }
}

/// Lets long pages be dragged with a mouse / trackpad on web & desktop (not
/// just touch + wheel), so users can always scroll to the very bottom.
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}
