import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:live_activities/live_activities.dart';
import 'package:live_activities/models/url_scheme_data.dart';

import '../../l10n/app_localizations.dart';
import '../db/isar_service.dart';
import '../models/enums.dart';
import '../models/lactation_timer.dart';
import 'lactation_timer_controller.dart';

/// Live Activity (iOS: Dynamic Island / pantalla de bloqueo) y notificación
/// persistente en Android con [Chronometer] nativo (segundo a segundo sin Dart).
class LactationLiveActivityService {
  LactationLiveActivityService._();

  static const String activityId = 'lactation_timer';

  /// Registrar el mismo App Group en Xcode (Runner + extensión) y en el portal Apple.
  static const String appGroupId = 'group.com.controlbebe.controlBebe.liveactivity';

  static final LiveActivities _plugin = LiveActivities();
  static bool _inited = false;
  static bool _pendingOpenFeeding = false;
  static StreamSubscription<dynamic>? _urlSchemeSub;

  static const _androidNavChannel =
      MethodChannel('com.controlbebe/lactation_navigation');

  static const _nativeTimerChannel =
      MethodChannel('com.controlbebe/lactation_timer');

  static final _openFeedingController = StreamController<void>.broadcast();

  /// Al pulsar la Live Activity / notificación del cronómetro.
  static Stream<void> get onOpenFeedingRequested => _openFeedingController.stream;

  /// Consumir navegación pendiente (arranque en frío antes de montar [MainNavigation]).
  static bool consumePendingOpenFeeding() {
    if (!_pendingOpenFeeding) return false;
    _pendingOpenFeeding = false;
    return true;
  }

  static void requestOpenFeedingTab() {
    _pendingOpenFeeding = true;
    if (!_openFeedingController.isClosed) {
      _openFeedingController.add(null);
    }
  }

  static Future<void> init() async {
    if (!Platform.isIOS && !Platform.isAndroid) return;
    if (_inited) return;
    try {
      await _plugin.init(
        appGroupId: appGroupId,
        urlScheme: 'mibebe',
        requestAndroidNotificationPermission: false,
      );
      _inited = true;
      _bindOpenFeedingNavigation();
      _bindNativeTimerChannel();
    } catch (e, st) {
      debugPrint('LactationLiveActivityService.init: $e\n$st');
    }
  }

  static void _bindNativeTimerChannel() {
    _nativeTimerChannel.setMethodCallHandler((call) async {
      if (call.method != 'timerChanged') return;
      final args = call.arguments;
      final action = args is Map ? args['action'] as String? : null;
      if (action == null || action.isEmpty) return;
      await LactationTimerController.syncFromNative(action: action);
    });
  }

  static void _bindOpenFeedingNavigation() {
    _urlSchemeSub?.cancel();
    _urlSchemeSub = _plugin.urlSchemeStream().listen(_handleUrlScheme);

    if (!Platform.isAndroid) return;
    _androidNavChannel.setMethodCallHandler((call) async {
      if (call.method == 'openFeeding') requestOpenFeedingTab();
    });
    unawaited(_consumeAndroidPendingOpenFeeding());
  }

  static Future<void> _consumeAndroidPendingOpenFeeding() async {
    final openFeeding =
        await _androidNavChannel.invokeMethod<bool>('consumePendingOpenFeeding');
    if (openFeeding == true) requestOpenFeedingTab();
  }

  static void _handleUrlScheme(UrlSchemeData data) {
    if (data.scheme != 'mibebe') return;
    final host = data.host ?? '';
    final path = data.path ?? '';
    if (host == 'lactation') {
      if (path.contains('pause')) {
        unawaited(LactationTimerController.pause());
      } else if (path.contains('resume')) {
        unawaited(LactationTimerController.resume());
      } else if (path.contains('stop')) {
        unawaited(_stopFromUrlScheme());
      }
      return;
    }
    if (host == 'feeding' || host.isEmpty) {
      requestOpenFeedingTab();
    }
  }

  static Future<void> _stopFromUrlScheme() async {
    await LactationTimerController.stopAndSave();
  }

  /// Reconcilia con el estado guardado (arranque en frío o pestaña lactancia).
  static Future<void> syncForActiveTimer() async {
    if (!_inited) return;
    try {
      final t = await IsarService.getActiveLactationTimer();
      if (t == null) {
        await stop();
        return;
      }
      final loc = WidgetsBinding.instance.platformDispatcher.locale;
      final l10n = lookupAppLocalizations(
        loc.languageCode == 'en' ? const Locale('en') : const Locale('es'),
      );
      final sideLabel =
          t.side == LactationSide.left ? l10n.feedingSideLeft : l10n.feedingSideRight;
      await _createOrUpdate(t, sideLabel: sideLabel, title: l10n.feedingBreast);
    } catch (e, st) {
      debugPrint('LactationLiveActivityService.syncForActiveTimer: $e\n$st');
    }
  }

  static Future<void> stop() async {
    if (!_inited) return;
    try {
      await _plugin.endActivity(activityId);
    } catch (e, st) {
      debugPrint('LactationLiveActivityService.stop: $e\n$st');
    }
  }

  static Future<void> _createOrUpdate(
    LactationTimer timer, {
    required String sideLabel,
    required String title,
  }) async {
    final supported = await _plugin.areActivitiesSupported();
    if (!supported) return;
    final enabled = await _plugin.areActivitiesEnabled();
    if (!enabled) return;

    final elapsedMs = timer.elapsed.inMilliseconds;
    final data = <String, dynamic>{
      'startedAtMs': timer.startedAt.millisecondsSinceEpoch.toDouble(),
      'sideLabel': sideLabel,
      'title': title,
      'isPaused': timer.isPaused,
      'totalPausedMs': timer.totalPausedMs.toDouble(),
      'frozenElapsedMs': elapsedMs.toDouble(),
    };

    // Cambia cada actualización: algunos caminos del plugin solo refrescan si el payload difiere.
    if (Platform.isIOS) {
      data['confirmPhase'] = 'idle';
      data['iosPresentationTick'] = DateTime.now().millisecondsSinceEpoch;
      data['sideIsLeft'] = timer.side == LactationSide.left;
      final loc = WidgetsBinding.instance.platformDispatcher.locale;
      final l10n = lookupAppLocalizations(
        loc.languageCode == 'en' ? const Locale('en') : const Locale('es'),
      );
      data['pauseLabel'] = l10n.feedingPause;
      data['resumeLabel'] = l10n.feedingResume;
      data['stopLabel'] = l10n.feedingStop;
      data['savedLabel'] = l10n.commonSaved;
      data['timerJson'] = jsonEncode({
        'side': timer.side.index,
        'startedAt': timer.startedAt.toIso8601String(),
        'startedAtMs': timer.startedAt.millisecondsSinceEpoch,
        'totalPausedMs': timer.totalPausedMs,
        if (timer.pausedAt != null) ...{
          'pausedAt': timer.pausedAt!.toIso8601String(),
          'pausedAtMs': timer.pausedAt!.millisecondsSinceEpoch,
        },
      });
      if (timer.isPaused) {
        data['pausedAtMs'] =
            timer.pausedAt!.millisecondsSinceEpoch.toDouble();
      }
    }

    if (Platform.isAndroid) {
      final loc = WidgetsBinding.instance.platformDispatcher.locale;
      final l10n = lookupAppLocalizations(
        loc.languageCode == 'en' ? const Locale('en') : const Locale('es'),
      );
      data['confirmPhase'] = 'idle';
      data['liveActivityChannelName'] = title;
      data['liveActivityChannelDescription'] = sideLabel;
      data['savedLabel'] = l10n.commonSaved;
    }

    await _plugin.createOrUpdateActivity(
      activityId,
      data,
      removeWhenAppIsKilled: false,
      iOSEnableRemoteUpdates: false,
    );
  }
}
