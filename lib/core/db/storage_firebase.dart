import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/baby_profile.dart';
import '../models/weight_record.dart';
import '../models/height_record.dart';
import '../models/diaper_record.dart';
import '../models/feeding_record.dart';
import '../models/sleep_record.dart';
import '../models/lactation_timer.dart';
import '../models/enums.dart';

import 'storage_interface.dart';

/// Implementación de StorageService usando Firestore.
/// Los datos se almacenan en families/{familyId}/...
/// users/{userId} contiene familyId que apunta a la familia.
class StorageServiceFirebase implements StorageService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  /// Evita repetir `users/{uid}.get()` en cada operación de la sesión.
  String? _memoryFamilyId;
  String? _memoryFamilyOwnerUid;

  String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Usuario no autenticado');
    return uid;
  }

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _firestore.collection('users').doc(_uid);

  /// Obtiene el familyId del usuario sin crear. Null si no tiene.
  Future<String?> _getFamilyIdOnly() async {
    final uid = _uid;
    final cached = _memoryFamilyId;
    if (_memoryFamilyOwnerUid == uid && cached != null && cached.isNotEmpty) {
      return cached;
    }
    // La instancia de almacenamiento vive durante toda la app. Nunca reutilizar
    // la familia en caché si Firebase Auth ha cambiado de usuario.
    _memoryFamilyId = null;
    _memoryFamilyOwnerUid = null;

    final userDoc = await _userDoc.get();
    final familyId = userDoc.data()?['familyId'] as String?;
    final out = (familyId != null && familyId.isNotEmpty) ? familyId : null;
    if (out != null) {
      _memoryFamilyId = out;
      _memoryFamilyOwnerUid = uid;
    }
    return out;
  }

  /// Obtiene el familyId del usuario. Crea familia y user doc si no existen.
  /// Sin revalidar/borrar el id en cada arranque (evita onboarding y familias duplicadas).
  Future<String> _getOrCreateFamilyId() async {
    final familyId = await _getFamilyIdOnly();
    if (familyId != null) return familyId;
    return _createFamilyForUser();
  }

  /// Crea una familia nueva y asocia al usuario.
  Future<String> _createFamilyForUser() async {
    final familyRef = _firestore.collection('families').doc();
    final familyId = familyRef.id;

    // En create, usar lista literal [_uid]: con arrayUnion las reglas suelen no ver
    // request.resource.data.members y falla permission-denied para cuentas nuevas.
    await _firestore.runTransaction((tx) async {
      tx.set(familyRef, {
        'members': <String>[_uid],
        'app_settings': {'onboardingCompleted': false},
      });
      tx.set(_userDoc, {'familyId': familyId}, SetOptions(merge: true));
    });

    _memoryFamilyId = familyId;
    _memoryFamilyOwnerUid = _uid;
    return familyId;
  }

  DocumentReference<Map<String, dynamic>> _familyDoc(String familyId) =>
      _firestore.collection('families').doc(familyId);

  CollectionReference<Map<String, dynamic>> _weights(String familyId) =>
      _familyDoc(familyId).collection('weight_records');

  CollectionReference<Map<String, dynamic>> _heights(String familyId) =>
      _familyDoc(familyId).collection('height_records');

  CollectionReference<Map<String, dynamic>> _diapers(String familyId) =>
      _familyDoc(familyId).collection('diaper_records');

  CollectionReference<Map<String, dynamic>> _feedings(String familyId) =>
      _familyDoc(familyId).collection('feeding_records');

  CollectionReference<Map<String, dynamic>> _sleeps(String familyId) =>
      _familyDoc(familyId).collection('sleep_records');

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
      final data = doc.data();
      final settings = data?['app_settings'] as Map<String, dynamic>?;
      if (settings?['onboardingCompleted'] == true) return false;
      // Datos creados antes de este flag o editados a mano: si ya hay perfil de bebé, no bloquear.
      if (_hasUsableBabyProfileMap(data?['baby_profile'])) return false;
      return true;
    } catch (_) {
      return true;
    }
  }

  static bool _hasUsableBabyProfileMap(Object? raw) {
    if (raw is! Map<String, dynamic>) return false;
    final name = raw['name'];
    return name is String && name.trim().isNotEmpty;
  }

  @override
  Future<void> completeOnboarding() async {
    final familyId = await _getOrCreateFamilyId();
    final doc = await _familyDoc(familyId).get();
    final data = doc.data() ?? {};
    final settings = Map<String, dynamic>.from(
      data['app_settings'] as Map? ?? {},
    );
    settings['onboardingCompleted'] = true;
    if (!settings.containsKey('onboardingCompletedAtMs')) {
      settings['onboardingCompletedAtMs'] =
          DateTime.now().millisecondsSinceEpoch;
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
      isMale: data['isMale'] as bool?,
      birthDate: DateTime.parse(data['birthDate'] as String),
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'] as String)
          : null,
      photoUrl: data['photoUrl'] as String?,
      heightCm: (data['heightCm'] as num?)?.toDouble(),
      expectedFeedingIntervalMinutes:
          (data['expectedFeedingIntervalMinutes'] as num?)?.toInt() ?? 180,
    );
  }

  @override
  Future<bool> getNotifyNextFeeding() async {
    final userDoc = await _userDoc.get();
    final userData = userDoc.data();
    final settings = userData?['user_settings'] as Map<String, dynamic>?;
    if (settings != null && settings.containsKey('notifyNextFeeding')) {
      return settings['notifyNextFeeding'] as bool? ?? false;
    }

    // Migración: valor legacy en baby_profile de la familia.
    final familyId = await _getFamilyIdOnly();
    if (familyId != null) {
      final doc = await _familyDoc(familyId).get();
      final baby = doc.data()?['baby_profile'] as Map<String, dynamic>?;
      if (baby != null && baby.containsKey('notifyNextFeeding')) {
        final legacy = baby['notifyNextFeeding'] as bool? ?? false;
        await setNotifyNextFeeding(legacy);
        return legacy;
      }
    }
    return false;
  }

  @override
  Future<void> setNotifyNextFeeding(bool value) async {
    await _userDoc.set({
      'user_settings': {'notifyNextFeeding': value},
    }, SetOptions(merge: true));
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
        'expectedFeedingIntervalMinutes':
            profile.expectedFeedingIntervalMinutes,
      },
    }, SetOptions(merge: true));
  }

  @override
  Future<bool> createBabyProfileIfAbsent(BabyProfile profile) async {
    final familyId = await _getOrCreateFamilyId();
    return _firestore.runTransaction((tx) async {
      final familyRef = _familyDoc(familyId);
      final snapshot = await tx.get(familyRef);
      final data = snapshot.data();
      if (_hasUsableBabyProfileMap(data?['baby_profile'])) {
        return false;
      }
      tx.set(familyRef, {
        'baby_profile': {
          'id': profile.id,
          'name': profile.name,
          'isMale': profile.isMale,
          'birthDate': profile.birthDate.toIso8601String(),
          'createdAt': profile.createdAt?.toIso8601String(),
          'photoUrl': profile.photoUrl,
          'heightCm': profile.heightCm,
          'expectedFeedingIntervalMinutes':
              profile.expectedFeedingIntervalMinutes,
        },
      }, SetOptions(merge: true));
      return true;
    });
  }

  static int _localId() => DateTime.now().microsecondsSinceEpoch;

  /// Reintenta la suscripción si Firestore devuelve permission-denied (p. ej. familia
  /// aún no propagada), para no dejar el [StreamProvider] en error permanente.
  Stream<List<T>> _resilientFamilyListStream<T>(
    Stream<List<T>> Function() subscribe,
  ) async* {
    while (true) {
      try {
        await for (final list in subscribe()) {
          yield list;
        }
        return;
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          yield <T>[];
          await Future<void>.delayed(const Duration(milliseconds: 600));
          continue;
        }
        rethrow;
      } on StateError {
        // Usuario no autenticado aún: reintentar en lugar de terminar el stream.
        yield <T>[];
        await Future<void>.delayed(const Duration(milliseconds: 800));
        continue;
      }
    }
  }

  @override
  Stream<List<WeightRecord>> watchWeightRecordsSince(DateTime fromInclusive) {
    final fromIso = fromInclusive.toIso8601String();
    return _resilientFamilyListStream(
      () => Stream.fromFuture(_getOrCreateFamilyId()).asyncExpand(
        (familyId) => _weights(familyId)
            .where('dateTime', isGreaterThanOrEqualTo: fromIso)
            .orderBy('dateTime', descending: true)
            .snapshots()
            .map((s) => s.docs.map(_weightFromDoc).toList()),
      ),
    );
  }

  @override
  Stream<List<WeightRecord>> watchAllWeightRecords() {
    return _resilientFamilyListStream(
      () => Stream.fromFuture(_getOrCreateFamilyId()).asyncExpand(
        (familyId) => _weights(familyId)
            .orderBy('dateTime', descending: true)
            .snapshots()
            .map((s) => s.docs.map(_weightFromDoc).toList()),
      ),
    );
  }

  @override
  Future<bool> hasWeightRecordStrictlyBefore(DateTime exclusiveUpper) async {
    try {
      final familyId = await _getOrCreateFamilyId();
      final snap = await _weights(familyId)
          .where('dateTime', isLessThan: exclusiveUpper.toIso8601String())
          .orderBy('dateTime', descending: true)
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<WeightRecord>> getWeightRecords() async {
    final familyId = await _getOrCreateFamilyId();
    final s = await _weights(
      familyId,
    ).orderBy('dateTime', descending: true).get();
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
      pendingRemoteSync: false,
    );
  }

  @override
  Stream<List<HeightRecord>> watchAllHeightRecords() {
    return _resilientFamilyListStream(
      () => Stream.fromFuture(_getOrCreateFamilyId()).asyncExpand(
        (familyId) => _heights(familyId)
            .orderBy('dateTime', descending: true)
            .snapshots()
            .map((s) => s.docs.map(_heightFromDoc).toList()),
      ),
    );
  }

  @override
  Future<List<HeightRecord>> getHeightRecords() async {
    final familyId = await _getOrCreateFamilyId();
    final s = await _heights(
      familyId,
    ).orderBy('dateTime', descending: true).get();
    return s.docs.map(_heightFromDoc).toList();
  }

  @override
  Future<void> addHeightRecord(HeightRecord record) async {
    final familyId = await _getOrCreateFamilyId();
    final id = record.id ?? _localId();
    await _heights(familyId).doc(id.toString()).set({
      'id': id,
      'heightCm': record.heightCm,
      'dateTime': record.dateTime.toIso8601String(),
    });
  }

  @override
  Future<void> updateHeightRecord(HeightRecord record) async {
    if (record.id == null) return;
    final familyId = await _getOrCreateFamilyId();
    await _heights(familyId).doc(record.id.toString()).update({
      'heightCm': record.heightCm,
      'dateTime': record.dateTime.toIso8601String(),
    });
  }

  @override
  Future<void> deleteHeightRecord(int id) async {
    final familyId = await _getOrCreateFamilyId();
    await _heights(familyId).doc(id.toString()).delete();
  }

  HeightRecord _heightFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    return HeightRecord(
      id: (m['id'] as num?)?.toInt(),
      heightCm: (m['heightCm'] as num).toDouble(),
      dateTime: DateTime.parse(m['dateTime'] as String),
      pendingRemoteSync: false,
    );
  }

  @override
  Stream<List<DiaperRecord>> watchDiaperRecordsSince(DateTime fromInclusive) {
    final fromIso = fromInclusive.toIso8601String();
    return _resilientFamilyListStream(
      () => Stream.fromFuture(_getOrCreateFamilyId()).asyncExpand(
        (familyId) => _diapers(familyId)
            .where('dateTime', isGreaterThanOrEqualTo: fromIso)
            .orderBy('dateTime', descending: true)
            .snapshots()
            .map((s) => s.docs.map(_diaperFromDoc).toList()),
      ),
    );
  }

  @override
  Future<List<DiaperRecord>> getDiaperRecordsSince(
    DateTime fromInclusive,
  ) async {
    final familyId = await _getOrCreateFamilyId();
    final s = await _diapers(familyId)
        .where(
          'dateTime',
          isGreaterThanOrEqualTo: fromInclusive.toIso8601String(),
        )
        .orderBy('dateTime', descending: true)
        .get();
    return s.docs.map(_diaperFromDoc).toList();
  }

  @override
  Future<bool> hasDiaperRecordStrictlyBefore(DateTime exclusiveUpper) async {
    try {
      final familyId = await _getOrCreateFamilyId();
      final snap = await _diapers(familyId)
          .where('dateTime', isLessThan: exclusiveUpper.toIso8601String())
          .orderBy('dateTime', descending: true)
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
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
    final s = await _diapers(
      familyId,
    ).orderBy('dateTime', descending: true).limit(1).get();
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
      pendingRemoteSync: false,
    );
  }

  @override
  Stream<List<FeedingRecord>> watchFeedingRecordsSince(DateTime fromInclusive) {
    final fromIso = fromInclusive.toIso8601String();
    return _resilientFamilyListStream(
      () => Stream.fromFuture(_getOrCreateFamilyId()).asyncExpand(
        (familyId) => _feedings(familyId)
            .where('dateTime', isGreaterThanOrEqualTo: fromIso)
            .orderBy('dateTime', descending: true)
            .snapshots()
            .map((s) => s.docs.map(_feedingFromDoc).toList()),
      ),
    );
  }

  @override
  Future<List<FeedingRecord>> getFeedingRecordsSince(
    DateTime fromInclusive,
  ) async {
    final familyId = await _getOrCreateFamilyId();
    final s = await _feedings(familyId)
        .where(
          'dateTime',
          isGreaterThanOrEqualTo: fromInclusive.toIso8601String(),
        )
        .orderBy('dateTime', descending: true)
        .get();
    return s.docs.map(_feedingFromDoc).toList();
  }

  @override
  Future<bool> hasFeedingRecordStrictlyBefore(DateTime exclusiveUpper) async {
    try {
      final familyId = await _getOrCreateFamilyId();
      final snap = await _feedings(familyId)
          .where('dateTime', isLessThan: exclusiveUpper.toIso8601String())
          .orderBy('dateTime', descending: true)
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
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
    final s = await _feedings(
      familyId,
    ).orderBy('dateTime', descending: true).limit(1).get();
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
      'solidName': record.solidName,
      'solidQuantity': record.solidQuantity,
      'solidUnit': record.solidUnit?.index,
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
      'solidName': record.solidName,
      'solidQuantity': record.solidQuantity,
      'solidUnit': record.solidUnit?.index,
    });
  }

  @override
  Future<void> deleteFeedingRecord(int id) async {
    final familyId = await _getOrCreateFamilyId();
    await _feedings(familyId).doc(id.toString()).delete();
  }

  FeedingRecord _feedingFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    final typeIdx = (m['type'] as num?)?.toInt() ?? 0;
    final type = typeIdx >= 0 && typeIdx < FeedingType.values.length
        ? FeedingType.values[typeIdx]
        : FeedingType.bottle;
    final suRaw = (m['solidUnit'] as num?)?.toInt();
    SolidQuantityUnit? solidUnit;
    if (suRaw != null &&
        suRaw >= 0 &&
        suRaw < SolidQuantityUnit.values.length) {
      solidUnit = SolidQuantityUnit.values[suRaw];
    }
    return FeedingRecord(
      id: (m['id'] as num?)?.toInt(),
      type: type,
      dateTime: DateTime.parse(m['dateTime'] as String),
      durationSeconds: (m['durationSeconds'] as num?)?.toInt(),
      amountMl: (m['amountMl'] as num?)?.toInt(),
      solidName: m['solidName'] as String?,
      solidQuantity: (m['solidQuantity'] as num?)?.toDouble(),
      solidUnit: solidUnit,
      pendingRemoteSync: false,
    );
  }

  @override
  Stream<List<SleepRecord>> watchSleepRecordsSince(DateTime fromInclusive) {
    final fromIso = fromInclusive.toIso8601String();
    return _resilientFamilyListStream(
      () => Stream.fromFuture(_getOrCreateFamilyId()).asyncExpand(
        (familyId) => _sleeps(familyId)
            .where('endDateTime', isGreaterThanOrEqualTo: fromIso)
            .orderBy('endDateTime', descending: true)
            .snapshots()
            .map((s) => s.docs.map(_sleepFromDoc).toList()),
      ),
    );
  }

  @override
  Future<List<SleepRecord>> getSleepRecordsSince(DateTime fromInclusive) async {
    final familyId = await _getOrCreateFamilyId();
    final s = await _sleeps(familyId)
        .where(
          'endDateTime',
          isGreaterThanOrEqualTo: fromInclusive.toIso8601String(),
        )
        .orderBy('endDateTime', descending: true)
        .get();
    return s.docs.map(_sleepFromDoc).toList();
  }

  @override
  Future<bool> hasSleepRecordStrictlyBefore(DateTime exclusiveUpper) async {
    try {
      final familyId = await _getOrCreateFamilyId();
      final snap = await _sleeps(familyId)
          .where('endDateTime', isLessThan: exclusiveUpper.toIso8601String())
          .orderBy('endDateTime', descending: true)
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<int> addSleepRecord(SleepRecord record) async {
    final familyId = await _getOrCreateFamilyId();
    final id = record.id ?? _localId();
    await _sleeps(familyId).doc(id.toString()).set({
      'id': id,
      'startDateTime': record.startDateTime.toIso8601String(),
      'endDateTime':
          record.endDateTime?.toIso8601String() ?? kSleepOpenEndSentinelIso,
      'type': record.type.index,
      if (record.parentSleepId != null) 'parentSleepId': record.parentSleepId,
    });
    return id;
  }

  @override
  Future<void> updateSleepRecord(SleepRecord record) async {
    if (record.id == null) return;
    final familyId = await _getOrCreateFamilyId();
    await _sleeps(familyId).doc(record.id.toString()).update({
      'startDateTime': record.startDateTime.toIso8601String(),
      'endDateTime':
          record.endDateTime?.toIso8601String() ?? kSleepOpenEndSentinelIso,
      'type': record.type.index,
      'parentSleepId': record.parentSleepId,
    });
  }

  @override
  Future<void> deleteSleepRecord(int id) async {
    final familyId = await _getOrCreateFamilyId();
    await _sleeps(familyId).doc(id.toString()).delete();
  }

  SleepRecord _sleepFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    final typeIdx = (m['type'] as num?)?.toInt() ?? 0;
    final type = typeIdx >= 0 && typeIdx < SleepType.values.length
        ? SleepType.values[typeIdx]
        : SleepType.night;
    final endRaw = m['endDateTime'] as String?;
    DateTime? end;
    if (endRaw != null && endRaw.isNotEmpty) {
      final parsed = DateTime.parse(endRaw);
      if (parsed.year < 9000) end = parsed;
    }
    return SleepRecord(
      id: (m['id'] as num?)?.toInt(),
      startDateTime: DateTime.parse(m['startDateTime'] as String),
      endDateTime: end,
      type: type,
      parentSleepId: (m['parentSleepId'] as num?)?.toInt(),
      pendingRemoteSync: false,
    );
  }

  /// El cronómetro activo vive solo en local ([QueuedStorageService]); aquí no hay I/O.
  @override
  Future<LactationTimer?> getActiveLactationTimer() async => null;

  @override
  Future<void> startLactationTimer(LactationSide side) async {}

  @override
  Future<void> saveLactationTimer(LactationTimer timer) async {}

  @override
  Future<LactationTimer?> stopLactationTimer() async => null;

  @override
  Future<void> syncLactationFromNative({bool afterStop = false}) async {}

  @override
  Future<String?> getFamilyId() async {
    try {
      return await _getOrCreateFamilyId();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> resetLocalSyncState() async {}

  @override
  void clearRemoteSessionCache() {
    _memoryFamilyId = null;
    _memoryFamilyOwnerUid = null;
  }

  @override
  Future<void> joinFamily(String familyId) async {
    // Lista literal en el update (no arrayUnion): las reglas comparan before/after
    // con size/hasAll; el sentinel de arrayUnion a veces provoca permission-denied.
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(_familyDoc(familyId));
      if (!snap.exists) {
        throw StateError('Familia no encontrada');
      }
      final data = snap.data() ?? {};
      final raw = data['members'];
      final members = <String>[];
      if (raw is List) {
        for (final e in raw) {
          if (e == null) continue;
          final s = e.toString();
          if (!members.contains(s)) members.add(s);
        }
      }
      if (!members.contains(_uid)) {
        members.add(_uid);
        tx.update(_familyDoc(familyId), {'members': members});
      }
      tx.set(_userDoc, {'familyId': familyId}, SetOptions(merge: true));
    });
    _memoryFamilyId = familyId;
    _memoryFamilyOwnerUid = _uid;
  }
}
