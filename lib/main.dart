import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/constants/app_constants.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/app_settings_provider.dart';
import 'core/providers/locale_provider.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FLUTTER ERROR: ${details.exception}');
    debugPrint('${details.stack}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PLATFORM ERROR: $error');
    debugPrint('$stack');
    return true;
  };

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  tz.initializeTimeZones();

  runApp(const ProviderScope(child: MonkApp()));
}

class MonkApp extends ConsumerWidget {
  const MonkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final compactMode =
        ref.watch(compactModeProvider).asData?.value ?? false;
    final visualDensity =
        compactMode ? VisualDensity.compact : VisualDensity.standard;
    final locale = ref.watch(localeProvider).asData?.value ?? const Locale('en');

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light.copyWith(visualDensity: visualDensity),
      darkTheme: AppTheme.dark.copyWith(visualDensity: visualDensity),
      routerConfig: router,
      // ── Localizations ──────────────────────────────────────────
      locale: locale,
      supportedLocales: kSupportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.85, 1.2),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
