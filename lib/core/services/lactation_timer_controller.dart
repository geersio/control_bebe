import 'dart:async';

import 'package:flutter/services.dart';

import '../db/isar_service.dart';
import '../models/enums.dart';
import '../models/feeding_record.dart';
import 'lactation_live_activity_service.dart';
import 'next_feeding_notification_service.dart';

/// Pausa y reanudación del cronómetro (app y notificación).
class LactationTimerController {
  LactationTimerController._();

  static final _timerChangedController = StreamController<void>.broadcast();

  static Stream<void> get onTimerChanged => _timerChangedController.stream;

  static void _notifyChanged() {
    if (!_timerChangedController.isClosed) {
      _timerChangedController.add(null);
    }
  }

  static Future<void> pause() async {
    final t = await IsarService.getActiveLactationTimer();
    if (t == null || t.isPaused) return;
    await IsarService.saveLactationTimer(
      t.copyWith(pausedAt: DateTime.now()),
    );
    _notifyChanged();
    await LactationLiveActivityService.syncForActiveTimer();
  }

  static Future<void> resume() async {
    final t = await IsarService.getActiveLactationTimer();
    if (t == null || !t.isPaused || t.pausedAt == null) return;
    final extra = DateTime.now().difference(t.pausedAt!).inMilliseconds;
    await IsarService.saveLactationTimer(
      t.copyWith(
        totalPausedMs: t.totalPausedMs + extra,
        clearPausedAt: true,
      ),
    );
    _notifyChanged();
    await LactationLiveActivityService.syncForActiveTimer();
  }

  static Future<void> togglePause() async {
    final t = await IsarService.getActiveLactationTimer();
    if (t == null) return;
    if (t.isPaused) {
      await resume();
    } else {
      await pause();
    }
  }

  /// Tras pausa/reanudación/parada desde Live Activity o notificación Android.
  static Future<void> syncFromNative({required String action}) async {
    await IsarService.syncLactationFromNative(afterStop: action == 'stop');
    _notifyChanged();
    if (action == 'stop') {
      // Háptica en iOS: AppDelegate (Runner). En Android: LactationTimerBridge.
      await NextFeedingNotificationService.syncFromStorage();
    } else {
      await LactationLiveActivityService.syncForActiveTimer();
    }
  }

  /// Parada completa desde deep link (iOS <17 sin App Intents).
  static Future<void> stopAndSave() async {
    final active = await IsarService.getActiveLactationTimer();
    if (active == null) return;
    final durationSeconds = active.elapsed.inSeconds.clamp(1, 86400);
    final stopped = await IsarService.stopLactationTimer();
    if (stopped == null) return;
    HapticFeedback.mediumImpact();
    await IsarService.addFeedingRecord(
      FeedingRecord(
        type: stopped.side == LactationSide.left
            ? FeedingType.leftBreast
            : FeedingType.rightBreast,
        dateTime: stopped.startedAt,
        durationSeconds: durationSeconds,
      ),
    );
    await NextFeedingNotificationService.syncFromStorage();
    await LactationLiveActivityService.stop();
    _notifyChanged();
  }

  /// Recarga prefs tras volver al primer plano (cambios nativos en disco).
  static Future<void> reloadFromDisk() async {
    await IsarService.syncLactationFromNative();
    _notifyChanged();
  }
}
