import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/db/isar_service.dart';
import 'core/services/next_feeding_notification_service.dart';
import 'core/services/lactation_live_activity_service.dart';
import 'core/services/analytics_service.dart';
import 'core/services/purchases_service.dart';
import 'core/firebase/firebase_service.dart';
import 'core/auth/auth_service.dart';
import 'core/auth/auth_shell.dart';
import 'features/onboarding/providers/onboarding_draft_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);
  await initializeDateFormatting('en', null);
  await initializeOnboardingDraftPersistence();
  await FirebaseService.initialize();
  await IsarService.initialize();
  await NextFeedingNotificationService.init();
  await PurchasesService.init();
  await LactationLiveActivityService.init();
  await LactationLiveActivityService.syncForActiveTimer();
  // Vincula/desvincula las compras de RevenueCat con la sesión de Firebase.
  if (FirebaseService.isAvailable) {
    AuthService.authStateChanges.listen((user) {
      if (user != null) {
        unawaited(PurchasesService.logIn(user.uid));
      } else {
        unawaited(PurchasesService.logOut());
      }
    });
  }
  unawaited(AnalyticsService.logAppOpen());
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ProviderScope(child: ControlBebeApp()));
}

class ControlBebeApp extends ConsumerWidget {
  const ControlBebeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx)!.appTitle,
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppTheme.systemUiForLightBackground,
          child: child ?? const SizedBox.shrink(),
        );
      },
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      localeListResolutionCallback: (locales, supported) {
        if (locales == null || locales.isEmpty) {
          return const Locale('es');
        }
        for (final preferred in locales) {
          for (final s in supported) {
            if (s.languageCode == preferred.languageCode) {
              return s;
            }
          }
        }
        return const Locale('es');
      },
      home: const AuthWrapper(),
    );
  }
}
