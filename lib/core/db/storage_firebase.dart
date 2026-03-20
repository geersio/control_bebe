import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/baby_profile.dart';
import '../models/weight_record.dart';
import '../models/diaper_record.dart';
import '../models/feeding_record.dart';
import '../models/lactation_timer.dart';
import '../models/enums.dart';

import 'storage_interface.dart';

/// Implementación de StorageService usando Firestore.
/// Los datos se almacenan en families/{familyId}/...
/// users/{userId} contiene familyId que apunta a la familia.
class StorageServiceFirebase implements StorageService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Usuario no autenticado');
    return uid;
  }

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _firestore.collection('users').doc(_uid);

  /// Obtiene el familyId del usuario sin crear. Null si no tiene.
  Future<String?> _getFamilyIdOnly() async {
    final userDoc = await _userDoc.get();
    final familyId = userDoc.data()?['familyId'] as String?;
    return (familyId != null && familyId.isNotEmpty) ? familyId : null;
  }

  /// Obtiene el familyId del usuario. Crea familia y user doc si no existen.
  Future<String> _getOrCreateFamilyId() async {
    final familyId = await _getFamilyIdOnly();
    if (familyId != null) return familyId;
    return _createFamilyForUser();
  }

  /// Crea una familia nueva y asocia al usuario.
  Future<String> _createFamilyForUser() async {
    final familyRef = _firestore.collection('families').doc();
    final familyId = familyRef.id;

    await _firestore.runTransaction((tx) async {
      tx.set(familyRef, {
        'members': FieldValue.arrayUnion([_uid]),
        'app_settings': {
          'onboardingCompleted': false,
          'homeCardOrder': ['weight', 'feeding', 'diapers'],
        },
      });
      tx.set(_userDoc, {'familyId': familyId}, SetOptions(merge: true));
    });

    return familyId;
  }

  DocumentReference<Map<String, dynamic>> _familyDoc(String familyId) =>
      _firestore.collection('families').doc(familyId);

  CollectionReference<Map<String, dynamic>> _weights(String familyId) =>
      _familyDoc(familyId).collection('weight_records');

  CollectionReference<Map<String, dynamic>> _diapers(String familyId) =>
      _familyDoc(familyId).collection('diaper_records');

  CollectionReference<Map<String, dynamic>> _feedings(String familyId) =>
      _familyDoc(familyId).collection('feeding_records');

  @override
  Future<void> initialize() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    await _getOrCreateFamilyId();
  }

  @override
  Future<bool> needsOnboarding() async {
    try {
      final familyId = await _getFamilyIdOnly();
      if (familyId == null) return true;
      final doc = await _familyDoc(familyId).get();
      if (!doc.exists) return true;
      final settings = doc.data()?['app_settings'] as Map<String, dynamic>?;
      return settings?['onboardingCompleted'] != true;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<void> completeOnboarding() async {
    final familyId = await _getOrCreateFamilyId();
    final doc = await _familyDoc(familyId).get();
    final data = doc.data() ?? {};
    final settings = Map<String, dynamic>.from(data['app_settings'] as Map? ?? {});
    settings['onboardingCompleted'] = true;
    if (settings['homeCardOrder'] == null) {
      settings['homeCardOrder'] = ['weight', 'feeding', 'diapers'];
    }
    await _familyDoc(familyId).update({'app_settings': settings});
  }

  @override
  Future<BabyProfile?> getBabyProfile() async {
    final familyId = await _getOrCreateFamilyId();
    final doc = await _familyDoc(familyId).get();
    final data = doc.data()?['baby_profile'] as Map<String, dynamic>?;
    if (data == null) return null;
    return BabyProfile(
      id: (data['id'] as num?)?.toInt(),
      name: data['name'] as String,
      isMale: data['isMale'] as bool,
      birthDate: DateTime.parse(data['birthDate'] as String),
      createdAt: data['createdAt'] != null ? DateTime.parse(data['createdAt'] as String) : null,
      photoUrl: data['photoUrl'] as String?,
      heightCm: (data['heightCm'] as num?)?.toDouble(),
    );
  }

  @override
  Future<void> saveBabyProfile(BabyProfile profile) async {
    final familyId = await _getOrCreateFamilyId();
    await _familyDoc(familyId).set({
      'baby_profile': {
        'id': profile.id,
        'name': profile.name,
        'isMale': profile.isMale,
        'birthDate': profile.birthDate.toIso8601String(),
        'createdAt': profile.createdAt?.toIso8601String(),
        'photoUrl': profile.photoUrl,
        'heightCm': profile.heightCm,
      },
    }, SetOptions(merge: true));
  }

  static int _localId() => DateTime.now().microsecondsSinceEpoch;

  @override
  Stream<List<WeightRecord>> watchWeightRecords() {
    return Stream.fromFuture(_getOrCreateFamilyId()).asyncExpand((familyId) =>
        _weights(familyId).orderBy('dateTime', descending: true).snapshots().map(
            (s) => s.docs.map((d) => _weightFromDoc(d)).toList()));
  }

  @override
  Future<List<WeightRecord>> getWeightRecords() async {
    final familyId = await _getOrCreateFamilyId();
    final s = await _weights(familyId).orderBy('dateTime', descending: true).get();
    return s.docs.map(_weightFromDoc).toList();
  }

  @override
  Future<void> addWeightRecord(WeightRecord record) async {
    final familyId = await _getOrCreateFamilyId();
    final id = record.id ?? _localId();
    await _weights(familyId).doc(id.toString()).set({
      'id': id,
      'weightKg': record.weightKg,
      'dateTime': record.dateTime.toIso8601String(),
    });
  }

  @override
  Future<void> updateWeightRecord(WeightRecord record) async {
    if (record.id == null) return;
    final familyId = await _getOrCreateFamilyId();
    await _weights(familyId).doc(record.id.toString()).update({
      'weightKg': record.weightKg,
      'dateTime': record.dateTime.toIso8601String(),
    });
  }

  @override
  Future<void> deleteWeightRecord(int id) async {
    final familyId = await _getOrCreateFamilyId();
    await _weights(familyId).doc(id.toString()).delete();
  }

  WeightRecord _weightFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    return WeightRecord(
      id: (m['id'] as num?)?.toInt(),
      weightKg: (m['weightKg'] as num).toDouble(),
      dateTime: DateTime.parse(m['dateTime'] as String),
    );
  }

  @override
  Stream<List<DiaperRecord>> watchDiaperRecords() {
    return Stream.fromFuture(_getOrCreateFamilyId()).asyncExpand((familyId) =>
        _diapers(familyId).orderBy('dateTime', descending: true).snapshots().map(
            (s) => s.docs.map((d) => _diaperFromDoc(d)).toList()));
  }

  @override
  Future<List<DiaperRecord>> getDiaperRecordsToday() async {
    final familyId = await _getOrCreateFamilyId();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final s = await _diapers(familyId)
        .where('dateTime', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('dateTime', isLessThan: end.toIso8601String())
        .get();
    return s.docs.map(_diaperFromDoc).toList();
  }

  @override
  Future<List<DiaperRecord>> getDiaperRecordsLast7Days() async {
    final familyId = await _getOrCreateFamilyId();
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final s = await _diapers(familyId)
        .where('dateTime', isGreaterThanOrEqualTo: cutoff.toIso8601String())
        .orderBy('dateTime', descending: true)
        .get();
    return s.docs.map(_diaperFromDoc).toList();
  }

  @override
  Future<DiaperRecord?> getLastDiaperRecord() async {
    final familyId = await _getOrCreateFamilyId();
    final s = await _diapers(familyId).orderBy('dateTime', descending: true).limit(1).get();
    return s.docs.isNotEmpty ? _diaperFromDoc(s.docs.first) : null;
  }

  @override
  Future<void> addDiaperRecord(DiaperRecord record) async {
    final familyId = await _getOrCreateFamilyId();
    final id = record.id ?? _localId();
    await _diapers(familyId).doc(id.toString()).set({
      'id': id,
      'type': record.type.index,
      'dateTime': record.dateTime.toIso8601String(),
    });
  }

  @override
  Future<void> updateDiaperRecord(DiaperRecord record) async {
    if (record.id == null) return;
    final familyId = await _getOrCreateFamilyId();
    await _diapers(familyId).doc(record.id.toString()).update({
      'type': record.type.index,
      'dateTime': record.dateTime.toIso8601String(),
    });
  }

  @override
  Future<void> deleteDiaperRecord(int id) async {
    final familyId = await _getOrCreateFamilyId();
    await _diapers(familyId).doc(id.toString()).delete();
  }

  DiaperRecord _diaperFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    return DiaperRecord(
      id: (m['id'] as num?)?.toInt(),
      type: DiaperType.values[(m['type'] as num).toInt()],
      dateTime: DateTime.parse(m['dateTime'] as String),
    );
  }

  @override
  Stream<List<FeedingRecord>> watchFeedingRecords() {
    return Stream.fromFuture(_getOrCreateFamilyId()).asyncExpand((familyId) =>
        _feedings(familyId).orderBy('dateTime', descending: true).snapshots().map(
            (s) => s.docs.map((d) => _feedingFromDoc(d)).toList()));
  }

  @override
  Future<List<FeedingRecord>> getFeedingRecordsToday() async {
    final familyId = await _getOrCreateFamilyId();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final s = await _feedings(familyId)
        .where('dateTime', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('dateTime', isLessThan: end.toIso8601String())
        .get();
    return s.docs.map(_feedingFromDoc).toList();
  }

  @override
  Future<FeedingRecord?> getLastFeedingRecord() async {
    final familyId = await _getOrCreateFamilyId();
    final s = await _feedings(familyId).orderBy('dateTime', descending: true).limit(1).get();
    return s.docs.isNotEmpty ? _feedingFromDoc(s.docs.first) : null;
  }

  @override
  Future<void> addFeedingRecord(FeedingRecord record) async {
    final familyId = await _getOrCreateFamilyId();
    final id = record.id ?? _localId();
    await _feedings(familyId).doc(id.toString()).set({
      'id': id,
      'type': record.type.index,
      'dateTime': record.dateTime.toIso8601String(),
      'durationSeconds': record.durationSeconds,
      'amountMl': record.amountMl,
    });
  }

  @override
  Future<void> updateFeedingRecord(FeedingRecord record) async {
    if (record.id == null) return;
    final familyId = await _getOrCreateFamilyId();
    await _feedings(familyId).doc(record.id.toString()).update({
      'type': record.type.index,
      'dateTime': record.dateTime.toIso8601String(),
      'durationSeconds': record.durationSeconds,
      'amountMl': record.amountMl,
    });
  }

  @override
  Future<void> deleteFeedingRecord(int id) async {
    final familyId = await _getOrCreateFamilyId();
    await _feedings(familyId).doc(id.toString()).delete();
  }

  FeedingRecord _feedingFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    return FeedingRecord(
      id: (m['id'] as num?)?.toInt(),
      type: FeedingType.values[(m['type'] as num).toInt()],
      dateTime: DateTime.parse(m['dateTime'] as String),
      durationSeconds: (m['durationSeconds'] as num?)?.toInt(),
      amountMl: (m['amountMl'] as num?)?.toInt(),
    );
  }

  /// Cronómetro guardado en users/{uid} (solo lo ve quien lo inició).
  /// El registro se guarda en la familia al parar.
  @override
  Future<LactationTimer?> getActiveLactationTimer() async {
    final doc = await _userDoc.get();
    final data = doc.data()?['lactation_timer'] as Map<String, dynamic>?;
    if (data == null) return null;
    return LactationTimer(
      id: (data['id'] as num?)?.toInt(),
      side: LactationSide.values[(data['side'] as num).toInt()],
      startedAt: DateTime.parse(data['startedAt'] as String),
    );
  }

  @override
  Future<void> startLactationTimer(LactationSide side) async {
    await _userDoc.set({
      'lactation_timer': {
        'side': side.index,
        'startedAt': DateTime.now().toIso8601String(),
      },
    }, SetOptions(merge: true));
  }

  @override
  Future<LactationTimer?> stopLactationTimer() async {
    final timer = await getActiveLactationTimer();
    await _userDoc.update({'lactation_timer': FieldValue.delete()});
    return timer;
  }

  @override
  Future<List<String>> getHomeCardOrder() async {
    final familyId = await _getOrCreateFamilyId();
    final doc = await _familyDoc(familyId).get();
    final settings = doc.data()?['app_settings'] as Map<String, dynamic>?;
    final order = settings?['homeCardOrder'] as List?;
    return order != null ? List<String>.from(order) : ['weight', 'feeding', 'diapers'];
  }

  @override
  Future<void> setHomeCardOrder(List<String> order) async {
    final familyId = await _getOrCreateFamilyId();
    final doc = await _familyDoc(familyId).get();
    final data = doc.data() ?? {};
    final settings = Map<String, dynamic>.from(data['app_settings'] as Map? ?? {});
    settings['homeCardOrder'] = order;
    await _familyDoc(familyId).update({'app_settings': settings});
  }

  @override
  Future<String?> getFamilyId() async {
    try {
      return await _getOrCreateFamilyId();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> joinFamily(String familyId) async {
    final doc = await _familyDoc(familyId).get();
    if (!doc.exists) {
      throw StateError('Familia no encontrada');
    }
    await _firestore.runTransaction((tx) async {
      tx.update(_familyDoc(familyId), {
        'members': FieldValue.arrayUnion([_uid]),
      });
      tx.set(_userDoc, {'familyId': familyId}, SetOptions(merge: true));
    });
  }
}
