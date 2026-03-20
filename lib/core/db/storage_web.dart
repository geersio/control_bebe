// Este archivo se importa SOLO cuando dart.library.html existe (Web)
// Usa SharedPreferences para persistencia en el navegador

import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/baby_profile.dart';
import '../models/weight_record.dart';
import '../models/diaper_record.dart';
import '../models/feeding_record.dart';
import '../models/lactation_timer.dart';
import '../models/app_settings.dart';
import '../models/enums.dart';

import 'storage_interface.dart';

class StorageServiceWeb implements StorageService {
  static const _keyBaby = 'baby_profile';
  static const _keyWeights = 'weight_records';
  static const _keyDiapers = 'diaper_records';
  static const _keyFeedings = 'feeding_records';
  static const _keyLactation = 'lactation_timer';
  static const _keySettings = 'app_settings';
  static const _keyNextId = 'next_id';

  SharedPreferences? _prefs;
  final _weightController = StreamController<List<WeightRecord>>.broadcast();
  final _diaperController = StreamController<List<DiaperRecord>>.broadcast();
  final _feedingController = StreamController<List<FeedingRecord>>.broadcast();

  Future<SharedPreferences> get _instance async {
    if (_prefs != null) return _prefs!;
    throw StateError('Storage no inicializado. Llama a initialize() primero.');
  }

  @override
  Future<void> initialize() async {
    if (_prefs != null) return;
    _prefs = await SharedPreferences.getInstance();

    final settings = _loadSettings();
    if (settings == null) {
      await _saveSettings(AppSettings());
    }
  }

  @override
  Future<bool> needsOnboarding() async {
    final s = _loadSettings();
    return s == null || !s.onboardingCompleted;
  }

  @override
  Future<void> completeOnboarding() async {
    final s = _loadSettings() ?? AppSettings();
    await _saveSettings(s.copyWith(onboardingCompleted: true));
  }

  @override
  Future<BabyProfile?> getBabyProfile() async {
    return _loadBabyProfile();
  }

  @override
  Future<void> saveBabyProfile(BabyProfile profile) async {
    final prefs = await _instance;
    await prefs.setString(_keyBaby, jsonEncode({
      'id': profile.id,
      'name': profile.name,
      'isMale': profile.isMale,
      'birthDate': profile.birthDate.toIso8601String(),
      'createdAt': profile.createdAt?.toIso8601String(),
      'photoUrl': profile.photoUrl,
      'heightCm': profile.heightCm,
    }));
  }

  @override
  Stream<List<WeightRecord>> watchWeightRecords() {
    return Stream.multi((listener) {
      listener.add(_loadWeightRecords());
      final sub = _weightController.stream.listen(
        listener.add,
        onError: listener.addError,
      );
      listener.onCancel = () => sub.cancel();
    });
  }

  @override
  Future<void> addWeightRecord(WeightRecord record) async {
    final list = _loadWeightRecords();
    final withId = record.id != null ? record : record.copyWith(id: _nextId());
    list.insert(0, withId);
    await _saveWeightRecords(list);
    _weightController.add(list);
  }

  @override
  Future<void> updateWeightRecord(WeightRecord record) async {
    final list = _loadWeightRecords();
    final idx = list.indexWhere((r) => r.id == record.id);
    if (idx >= 0) {
      list[idx] = record;
      await _saveWeightRecords(list);
      _weightController.add(list);
    }
  }

  @override
  Future<void> deleteWeightRecord(int id) async {
    final list = _loadWeightRecords().where((r) => r.id != id).toList();
    await _saveWeightRecords(list);
    _weightController.add(list);
  }

  @override
  Future<List<WeightRecord>> getWeightRecords() async {
    return _loadWeightRecords();
  }

  @override
  Stream<List<DiaperRecord>> watchDiaperRecords() {
    return Stream.multi((listener) {
      listener.add(_loadDiaperRecords());
      final sub = _diaperController.stream.listen(
        listener.add,
        onError: listener.addError,
      );
      listener.onCancel = () => sub.cancel();
    });
  }

  @override
  Future<void> addDiaperRecord(DiaperRecord record) async {
    final list = _loadDiaperRecords();
    final withId = record.id != null ? record : record.copyWith(id: _nextId());
    list.insert(0, withId);
    await _saveDiaperRecords(list);
    _diaperController.add(list);
  }

  @override
  Future<void> updateDiaperRecord(DiaperRecord record) async {
    final list = _loadDiaperRecords();
    final idx = list.indexWhere((r) => r.id == record.id);
    if (idx >= 0) {
      list[idx] = record;
      await _saveDiaperRecords(list);
      _diaperController.add(list);
    }
  }

  @override
  Future<void> deleteDiaperRecord(int id) async {
    final list = _loadDiaperRecords().where((r) => r.id != id).toList();
    await _saveDiaperRecords(list);
    _diaperController.add(list);
  }

  @override
  Future<List<DiaperRecord>> getDiaperRecordsToday() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return _loadDiaperRecords()
        .where((r) => !r.dateTime.isBefore(startOfDay) && r.dateTime.isBefore(endOfDay))
        .toList();
  }

  @override
  Future<List<DiaperRecord>> getDiaperRecordsLast7Days() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return _loadDiaperRecords().where((r) => !r.dateTime.isBefore(cutoff)).toList();
  }

  @override
  Future<DiaperRecord?> getLastDiaperRecord() async {
    final list = _loadDiaperRecords();
    return list.isNotEmpty ? list.first : null;
  }

  @override
  Stream<List<FeedingRecord>> watchFeedingRecords() {
    return Stream.multi((listener) {
      listener.add(_loadFeedingRecords());
      final sub = _feedingController.stream.listen(
        listener.add,
        onError: listener.addError,
      );
      listener.onCancel = () => sub.cancel();
    });
  }

  @override
  Future<void> addFeedingRecord(FeedingRecord record) async {
    final list = _loadFeedingRecords();
    final withId = record.id != null ? record : record.copyWith(id: _nextId());
    list.insert(0, withId);
    await _saveFeedingRecords(list);
    _feedingController.add(list);
  }

  @override
  Future<void> updateFeedingRecord(FeedingRecord record) async {
    final list = _loadFeedingRecords();
    final idx = list.indexWhere((r) => r.id == record.id);
    if (idx >= 0) {
      list[idx] = record;
      await _saveFeedingRecords(list);
      _feedingController.add(list);
    }
  }

  @override
  Future<void> deleteFeedingRecord(int id) async {
    final list = _loadFeedingRecords().where((r) => r.id != id).toList();
    await _saveFeedingRecords(list);
    _feedingController.add(list);
  }

  @override
  Future<List<FeedingRecord>> getFeedingRecordsToday() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return _loadFeedingRecords()
        .where((r) => !r.dateTime.isBefore(startOfDay) && r.dateTime.isBefore(endOfDay))
        .toList();
  }

  @override
  Future<FeedingRecord?> getLastFeedingRecord() async {
    final list = _loadFeedingRecords();
    return list.isNotEmpty ? list.first : null;
  }

  @override
  Future<LactationTimer?> getActiveLactationTimer() async {
    return _loadLactationTimer();
  }

  @override
  Future<void> startLactationTimer(LactationSide side) async {
    await _saveLactationTimer(LactationTimer(side: side, startedAt: DateTime.now()));
  }

  @override
  Future<LactationTimer?> stopLactationTimer() async {
    final t = _loadLactationTimer();
    await _saveLactationTimer(null);
    return t;
  }

  @override
  Future<List<String>> getHomeCardOrder() async {
    final s = _loadSettings();
    return s?.homeCardOrder ?? ['weight', 'feeding', 'diapers'];
  }

  @override
  Future<void> setHomeCardOrder(List<String> order) async {
    final s = _loadSettings() ?? AppSettings();
    await _saveSettings(s.copyWith(homeCardOrder: order));
  }

  @override
  Future<String?> getFamilyId() async => null;

  @override
  Future<void> joinFamily(String familyId) async {
    throw UnsupportedError('Unir familia solo disponible con Firebase');
  }

  // Helpers
  BabyProfile? _loadBabyProfile() {
    final json = _prefs?.getString(_keyBaby);
    if (json == null) return null;
    final m = jsonDecode(json) as Map<String, dynamic>;
    return BabyProfile(
      id: m['id'] as int?,
      name: m['name'] as String,
      isMale: m['isMale'] as bool,
      birthDate: DateTime.parse(m['birthDate'] as String),
      createdAt: m['createdAt'] != null ? DateTime.parse(m['createdAt'] as String) : null,
      photoUrl: m['photoUrl'] as String?,
      heightCm: (m['heightCm'] as num?)?.toDouble(),
    );
  }

  List<WeightRecord> _loadWeightRecords() {
    final json = _prefs?.getString(_keyWeights);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => _weightFromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _saveWeightRecords(List<WeightRecord> list) async {
    await _prefs!.setString(_keyWeights, jsonEncode(list.map(_weightToJson).toList()));
  }

  WeightRecord _weightFromJson(Map<String, dynamic> m) => WeightRecord(
        id: m['id'] as int?,
        weightKg: (m['weightKg'] as num).toDouble(),
        dateTime: DateTime.parse(m['dateTime'] as String),
      );

  Map<String, dynamic> _weightToJson(WeightRecord r) => {
        'id': r.id,
        'weightKg': r.weightKg,
        'dateTime': r.dateTime.toIso8601String(),
      };

  List<DiaperRecord> _loadDiaperRecords() {
    final json = _prefs?.getString(_keyDiapers);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => _diaperFromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _saveDiaperRecords(List<DiaperRecord> list) async {
    await _prefs!.setString(_keyDiapers, jsonEncode(list.map(_diaperToJson).toList()));
  }

  DiaperRecord _diaperFromJson(Map<String, dynamic> m) => DiaperRecord(
        id: m['id'] as int?,
        type: DiaperType.values[m['type'] as int],
        dateTime: DateTime.parse(m['dateTime'] as String),
      );

  Map<String, dynamic> _diaperToJson(DiaperRecord r) => {
        'id': r.id,
        'type': r.type.index,
        'dateTime': r.dateTime.toIso8601String(),
      };

  List<FeedingRecord> _loadFeedingRecords() {
    final json = _prefs?.getString(_keyFeedings);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => _feedingFromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _saveFeedingRecords(List<FeedingRecord> list) async {
    await _prefs!.setString(_keyFeedings, jsonEncode(list.map(_feedingToJson).toList()));
  }

  FeedingRecord _feedingFromJson(Map<String, dynamic> m) => FeedingRecord(
        id: m['id'] as int?,
        type: FeedingType.values[m['type'] as int],
        dateTime: DateTime.parse(m['dateTime'] as String),
        durationSeconds: m['durationSeconds'] as int?,
        amountMl: m['amountMl'] as int?,
      );

  Map<String, dynamic> _feedingToJson(FeedingRecord r) => {
        'id': r.id,
        'type': r.type.index,
        'dateTime': r.dateTime.toIso8601String(),
        'durationSeconds': r.durationSeconds,
        'amountMl': r.amountMl,
      };

  LactationTimer? _loadLactationTimer() {
    final json = _prefs?.getString(_keyLactation);
    if (json == null) return null;
    final m = jsonDecode(json) as Map<String, dynamic>;
    return LactationTimer(
      id: m['id'] as int?,
      side: LactationSide.values[m['side'] as int],
      startedAt: DateTime.parse(m['startedAt'] as String),
    );
  }

  Future<void> _saveLactationTimer(LactationTimer? t) async {
    if (t == null) {
      await _prefs!.remove(_keyLactation);
    } else {
      await _prefs!.setString(_keyLactation, jsonEncode({
        'id': t.id,
        'side': t.side.index,
        'startedAt': t.startedAt.toIso8601String(),
      }));
    }
  }

  AppSettings? _loadSettings() {
    final json = _prefs?.getString(_keySettings);
    if (json == null) return null;
    final m = jsonDecode(json) as Map<String, dynamic>;
    return AppSettings(
      id: m['id'] as int? ?? 1,
      onboardingCompleted: m['onboardingCompleted'] as bool? ?? false,
      homeCardOrder: List<String>.from(m['homeCardOrder'] as List? ?? ['weight', 'feeding', 'diapers']),
    );
  }

  Future<void> _saveSettings(AppSettings s) async {
    await _prefs!.setString(_keySettings, jsonEncode({
      'id': s.id,
      'onboardingCompleted': s.onboardingCompleted,
      'homeCardOrder': s.homeCardOrder,
    }));
  }

  int _nextId() {
    final id = (_prefs?.getInt(_keyNextId) ?? 0) + 1;
    _prefs?.setInt(_keyNextId, id);
    return id;
  }
}

/// Factory para import condicional
StorageService createStorageService() => StorageServiceWeb();
