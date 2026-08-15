import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase/firebase_service.dart';

/// Analítica mínima de embudo: apertura -> primer registro -> retención Firebase.
class AnalyticsService {
  AnalyticsService._();

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static const _kFirstRecordCreatedLogged =
      'analytics_first_record_created_logged';

  static Future<void> logAppOpen() async {
    if (!FirebaseService.isAvailable) return;

    try {
      await _analytics.logAppOpen();
    } catch (_) {
      // La analítica nunca debe afectar al arranque de la app.
    }
  }

  static Future<void> logRecordCreated(String recordType) async {
    if (!FirebaseService.isAvailable) return;

    await _logEvent('record_created', {'record_type': recordType});
    await _logFirstRecordCreatedIfNeeded(recordType);
  }

  static Future<void> _logFirstRecordCreatedIfNeeded(String recordType) async {
    final sp = await SharedPreferences.getInstance();
    if (sp.getBool(_kFirstRecordCreatedLogged) ?? false) return;

    await _logEvent('first_record_created', {'record_type': recordType});
    await sp.setBool(_kFirstRecordCreatedLogged, true);
  }

  static Future<void> _logEvent(
    String name,
    Map<String, Object> parameters,
  ) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (_) {
      // Mantener la UX intacta si Firebase Analytics no está disponible.
    }
  }
}
