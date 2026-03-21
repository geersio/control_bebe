import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../db/isar_service.dart';

/// Notificación local cuando llega la hora sugerida de la siguiente toma.
class NextFeedingNotificationService {
  NextFeedingNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _notificationId = 9010;
  static const String _channelId = 'next_feeding_reminder';

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

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
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        'Próximas tomas',
        description: 'Aviso cuando llega la hora sugerida de toma',
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
    if (baby == null || last == null || !baby.notifyNextFeeding) return;

    final interval = baby.expectedFeedingIntervalMinutes.clamp(30, 720);
    final next = last.dateTime.add(Duration(minutes: interval));
    if (!next.isAfter(DateTime.now())) return;

    final when = tz.TZDateTime.from(next, tz.local);
    try {
      await _plugin.zonedSchedule(
        _notificationId,
        'Próxima toma',
        'Podría tocar otra toma para ${baby.name}.',
        when,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'Próximas tomas',
            channelDescription: 'Aviso cuando llega la hora sugerida de toma',
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
