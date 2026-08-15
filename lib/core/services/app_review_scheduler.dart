import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

import 'app_review_service.dart';

/// Pide valoración en momentos de valor: tras guardar los registros 10, 50 y 200
/// (peso, pañal o alimentación) vía `IsarService`.
/// Como mucho se intenta una petición por registro guardado.
class AppReviewScheduler {
  AppReviewScheduler._();

  static const _kSavedRecordCount = 'app_review_saved_record_count';
  static const _kPrompt10Shown = 'app_review_prompt_10_shown';
  static const _kPrompt50Shown = 'app_review_prompt_50_shown';
  static const _kPrompt200Shown = 'app_review_prompt_200_shown';

  static Future<void> maybePrompt() async {
    if (kIsWeb || !AppReviewService.canRequestInAppReview) return;

    final sp = await SharedPreferences.getInstance();
    final count = (sp.getInt(_kSavedRecordCount) ?? 0) + 1;
    await sp.setInt(_kSavedRecordCount, count);

    await _requestAtMilestone(
      sp,
      count,
      milestone: 10,
      flagKey: _kPrompt10Shown,
    );
    await _requestAtMilestone(
      sp,
      count,
      milestone: 50,
      flagKey: _kPrompt50Shown,
    );
    await _requestAtMilestone(
      sp,
      count,
      milestone: 200,
      flagKey: _kPrompt200Shown,
    );
  }

  static Future<void> _requestAtMilestone(
    SharedPreferences sp,
    int count, {
    required int milestone,
    required String flagKey,
  }) async {
    if (count != milestone || (sp.getBool(flagKey) ?? false)) return;

    await AppReviewService.requestReview();
    await sp.setBool(flagKey, true);
  }
}
