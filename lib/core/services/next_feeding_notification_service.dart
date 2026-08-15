import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, debugPrint;
import 'package:flutter/material.dart' show Locale;
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../l10n/app_localizations.dart';
import '../db/isar_service.dart';

/// Notificación local cuando llega la hora sugerida de la siguiente toma.
class NextFeedingNotificationService {
  NextFeedingNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _notificationId = 9010;
  static const String _channelId = 'next_feeding_reminder';

  static bool get _supported =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  static Future<void> init() async {
    if (!_supported) return;
    tzdata.initializeTimeZones();
    try {
      final zoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zoneName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    // No pedir permiso aquí: iOS lo mostraría en el primer launch.
    // Se solicita en onboarding (Activar) y en Ajustes.
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final loc = WidgetsBinding.instance.platformDispatcher.locale;
    final l10n = lookupAppLocalizations(
      loc.languageCode == 'en' ? const Locale('en') : const Locale('es'),
    );
    await androidPlugin?.createNotificationChannel(
      AndroidNotificationChannel(
        _channelId,
        l10n.notificationChannelName,
        description: l10n.notificationChannelDescription,
        importance: Importance.high,
      ),
    );
  }

  /// Solicita permiso de notificaciones (iOS y Android 13+).
  static Future<bool> requestPermissions() async {
    if (!_supported) return false;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final r = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return r ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final r = await android?.requestNotificationsPermission();
      return r ?? true;
    }
    return false;
  }

  static Future<void> cancelScheduled() async {
    if (!_supported) return;
    await _plugin.cancel(_notificationId);
  }

  /// Reprograma según perfil y última toma; cancela si no aplica.
  static Future<void> syncFromStorage() async {
    if (!_supported) return;
    await cancelScheduled();
    final baby = await IsarService.getBabyProfile();
    final last = await IsarService.getLastFeedingRecord();
    final notify = await IsarService.getNotifyNextFeeding();
    if (baby == null || last == null || !notify) return;

    // No avisar de "próxima toma" mientras el cronómetro de pecho está en marcha.
    if (await IsarService.getActiveLactationTimer() != null) return;

    final interval = baby.expectedFeedingIntervalMinutes.clamp(30, 720);
    final next = last.dateTime.add(Duration(minutes: interval));
    if (!next.isAfter(DateTime.now())) return;

    final when = tz.TZDateTime.from(next, tz.local);
    final loc = WidgetsBinding.instance.platformDispatcher.locale;
    final l10n = lookupAppLocalizations(
      loc.languageCode == 'en' ? const Locale('en') : const Locale('es'),
    );
    try {
      await _plugin.zonedSchedule(
        _notificationId,
        l10n.notificationNextFeedTitle,
        l10n.notificationNextFeedBody(baby.name),
        when,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            l10n.notificationChannelName,
            channelDescription: l10n.notificationChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e, st) {
      debugPrint('NextFeedingNotificationService: $e\n$st');
    }
  }
}
