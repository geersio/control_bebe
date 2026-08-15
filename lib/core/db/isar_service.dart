// Facade que delega al StorageService (Firestore vía cola + prefs en disco).
// Mantiene la API original para compatibilidad con el resto de la app.
import 'dart:async';

import 'storage_interface.dart';
import 'storage_service.dart';

import '../services/app_review_scheduler.dart';
import '../services/analytics_service.dart';

import '../models/baby_profile.dart';
import '../models/weight_record.dart';
import '../models/height_record.dart';
import '../models/diaper_record.dart';
import '../models/feeding_record.dart';
import '../models/sleep_record.dart';
import '../models/lactation_timer.dart';
import '../models/enums.dart';

class IsarService {
  static StorageService get _s => storage;

  static Future<void> initialize() async {
    await _s.initialize();
  }

  static Future<bool> needsOnboarding() => _s.needsOnboarding();
  static Future<void> completeOnboarding() => _s.completeOnboarding();

  static Future<BabyProfile?> getBabyProfile() => _s.getBabyProfile();
  static Future<void> saveBabyProfile(BabyProfile profile) =>
      _s.saveBabyProfile(profile);
  static Future<bool> createBabyProfileIfAbsent(BabyProfile profile) =>
      _s.createBabyProfileIfAbsent(profile);

  static Future<bool> getNotifyNextFeeding() => _s.getNotifyNextFeeding();
  static Future<void> setNotifyNextFeeding(bool value) =>
      _s.setNotifyNextFeeding(value);

  static Stream<List<WeightRecord>> watchWeightRecordsSince(DateTime from) =>
      _s.watchWeightRecordsSince(from);

  static Stream<List<WeightRecord>> watchAllWeightRecords() =>
      _s.watchAllWeightRecords();

  static Future<bool> hasWeightRecordStrictlyBefore(DateTime exclusiveUpper) =>
      _s.hasWeightRecordStrictlyBefore(exclusiveUpper);
  static Future<void> addWeightRecord(WeightRecord record) async {
    await _s.addWeightRecord(record);
    unawaited(AnalyticsService.logRecordCreated('weight'));
    unawaited(AppReviewScheduler.maybePrompt());
  }

  static Future<void> updateWeightRecord(WeightRecord record) =>
      _s.updateWeightRecord(record);
  static Future<void> deleteWeightRecord(int id) => _s.deleteWeightRecord(id);

  static Stream<List<HeightRecord>> watchAllHeightRecords() =>
      _s.watchAllHeightRecords();

  static Future<List<HeightRecord>> getHeightRecords() => _s.getHeightRecords();

  static Future<void> addHeightRecord(HeightRecord record) async {
    await _s.addHeightRecord(record);
    unawaited(AnalyticsService.logRecordCreated('height'));
    unawaited(AppReviewScheduler.maybePrompt());
  }

  static Future<void> updateHeightRecord(HeightRecord record) =>
      _s.updateHeightRecord(record);
  static Future<void> deleteHeightRecord(int id) => _s.deleteHeightRecord(id);

  static Stream<List<DiaperRecord>> watchDiaperRecordsSince(DateTime from) =>
      _s.watchDiaperRecordsSince(from);

  static Future<List<DiaperRecord>> getDiaperRecordsSince(DateTime from) =>
      _s.getDiaperRecordsSince(from);

  static Future<bool> hasDiaperRecordStrictlyBefore(DateTime exclusiveUpper) =>
      _s.hasDiaperRecordStrictlyBefore(exclusiveUpper);
  static Future<void> addDiaperRecord(DiaperRecord record) async {
    await _s.addDiaperRecord(record);
    unawaited(AnalyticsService.logRecordCreated('diaper'));
    unawaited(AppReviewScheduler.maybePrompt());
  }

  static Future<void> updateDiaperRecord(DiaperRecord record) =>
      _s.updateDiaperRecord(record);
  static Future<void> deleteDiaperRecord(int id) => _s.deleteDiaperRecord(id);

  static Stream<List<FeedingRecord>> watchFeedingRecordsSince(DateTime from) =>
      _s.watchFeedingRecordsSince(from);

  static Future<List<FeedingRecord>> getFeedingRecordsSince(DateTime from) =>
      _s.getFeedingRecordsSince(from);

  static Future<bool> hasFeedingRecordStrictlyBefore(DateTime exclusiveUpper) =>
      _s.hasFeedingRecordStrictlyBefore(exclusiveUpper);
  static Future<void> addFeedingRecord(FeedingRecord record) async {
    await _s.addFeedingRecord(record);
    unawaited(AnalyticsService.logRecordCreated('feeding'));
    unawaited(AppReviewScheduler.maybePrompt());
  }

  static Future<void> updateFeedingRecord(FeedingRecord record) =>
      _s.updateFeedingRecord(record);
  static Future<void> deleteFeedingRecord(int id) => _s.deleteFeedingRecord(id);

  static Stream<List<SleepRecord>> watchSleepRecordsSince(DateTime from) =>
      _s.watchSleepRecordsSince(from);

  static Future<List<SleepRecord>> getSleepRecordsSince(DateTime from) =>
      _s.getSleepRecordsSince(from);

  static Future<bool> hasSleepRecordStrictlyBefore(DateTime exclusiveUpper) =>
      _s.hasSleepRecordStrictlyBefore(exclusiveUpper);
  static Future<int> addSleepRecord(SleepRecord record) async {
    final id = await _s.addSleepRecord(record);
    unawaited(AnalyticsService.logRecordCreated('sleep'));
    unawaited(AppReviewScheduler.maybePrompt());
    return id;
  }

  static Future<void> updateSleepRecord(SleepRecord record) =>
      _s.updateSleepRecord(record);
  static Future<void> deleteSleepRecord(int id) => _s.deleteSleepRecord(id);

  static Future<LactationTimer?> getActiveLactationTimer() =>
      _s.getActiveLactationTimer();
  static Future<void> startLactationTimer(LactationSide side) =>
      _s.startLactationTimer(side);
  static Future<void> saveLactationTimer(LactationTimer timer) =>
      _s.saveLactationTimer(timer);
  static Future<LactationTimer?> stopLactationTimer() =>
      _s.stopLactationTimer();
  static Future<void> syncLactationFromNative({bool afterStop = false}) =>
      _s.syncLactationFromNative(afterStop: afterStop);

  static Future<String?> getFamilyId() => _s.getFamilyId();
  static Future<void> joinFamily(String familyId) => _s.joinFamily(familyId);

  static Future<List<WeightRecord>> getWeightRecords() => _s.getWeightRecords();
  static Future<List<FeedingRecord>> getFeedingRecordsToday() =>
      _s.getFeedingRecordsToday();
  static Future<FeedingRecord?> getLastFeedingRecord() =>
      _s.getLastFeedingRecord();
  static Future<List<DiaperRecord>> getDiaperRecordsToday() =>
      _s.getDiaperRecordsToday();
  static Future<List<DiaperRecord>> getDiaperRecordsLast7Days() =>
      _s.getDiaperRecordsLast7Days();
  static Future<DiaperRecord?> getLastDiaperRecord() =>
      _s.getLastDiaperRecord();
}
