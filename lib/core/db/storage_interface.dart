import '../models/baby_profile.dart';
import '../models/weight_record.dart';
import '../models/height_record.dart';
import '../models/diaper_record.dart';
import '../models/feeding_record.dart';
import '../models/sleep_record.dart';
import '../models/lactation_timer.dart';
import '../models/enums.dart';

/// Interfaz de almacenamiento: remoto Firestore + cola local en [QueuedStorageService].
abstract class StorageService {
  Future<void> initialize();

  Future<bool> needsOnboarding();
  Future<void> completeOnboarding();

  Future<BabyProfile?> getBabyProfile();
  Future<void> saveBabyProfile(BabyProfile profile);

  /// Crea el perfil solo si la familia aún no tiene uno utilizable.
  /// Devuelve false sin modificar datos cuando ya existe.
  Future<bool> createBabyProfileIfAbsent(BabyProfile profile);

  /// Preferencia por usuario: aviso local de próxima toma (no compartida en familia).
  Future<bool> getNotifyNextFeeding();
  Future<void> setNotifyNextFeeding(bool value);

  /// Solo registros con `dateTime >= fromInclusive` (menos lecturas en Firestore).
  Stream<List<WeightRecord>> watchWeightRecordsSince(DateTime fromInclusive);

  /// Toda la serie temporal de peso (gráficas, tendencia, último peso global).
  Stream<List<WeightRecord>> watchAllWeightRecords();
  Future<List<WeightRecord>> getWeightRecords();

  /// ¿Existe algún registro con `dateTime` estrictamente anterior a [exclusiveUpper]?
  Future<bool> hasWeightRecordStrictlyBefore(DateTime exclusiveUpper);
  Future<void> addWeightRecord(WeightRecord record);
  Future<void> updateWeightRecord(WeightRecord record);
  Future<void> deleteWeightRecord(int id);

  /// Toda la serie temporal de altura.
  Stream<List<HeightRecord>> watchAllHeightRecords();

  /// One-shot (espera servidor si hay red); no usar [watch].first del caché offline.
  Future<List<HeightRecord>> getHeightRecords();
  Future<void> addHeightRecord(HeightRecord record);
  Future<void> updateHeightRecord(HeightRecord record);
  Future<void> deleteHeightRecord(int id);

  Stream<List<DiaperRecord>> watchDiaperRecordsSince(DateTime fromInclusive);

  /// One-shot (espera servidor si hay red); no usar [watch].first del caché offline.
  Future<List<DiaperRecord>> getDiaperRecordsSince(DateTime fromInclusive);
  Future<bool> hasDiaperRecordStrictlyBefore(DateTime exclusiveUpper);
  Future<List<DiaperRecord>> getDiaperRecordsToday();
  Future<List<DiaperRecord>> getDiaperRecordsLast7Days();
  Future<DiaperRecord?> getLastDiaperRecord();
  Future<void> addDiaperRecord(DiaperRecord record);
  Future<void> updateDiaperRecord(DiaperRecord record);
  Future<void> deleteDiaperRecord(int id);

  Stream<List<FeedingRecord>> watchFeedingRecordsSince(DateTime fromInclusive);

  /// One-shot (espera servidor si hay red); no usar [watch].first del caché offline.
  Future<List<FeedingRecord>> getFeedingRecordsSince(DateTime fromInclusive);
  Future<bool> hasFeedingRecordStrictlyBefore(DateTime exclusiveUpper);
  Future<List<FeedingRecord>> getFeedingRecordsToday();
  Future<FeedingRecord?> getLastFeedingRecord();
  Future<void> addFeedingRecord(FeedingRecord record);
  Future<void> updateFeedingRecord(FeedingRecord record);
  Future<void> deleteFeedingRecord(int id);

  Stream<List<SleepRecord>> watchSleepRecordsSince(DateTime fromInclusive);

  /// One-shot (espera servidor si hay red); no usar [watch].first del caché offline.
  Future<List<SleepRecord>> getSleepRecordsSince(DateTime fromInclusive);
  Future<bool> hasSleepRecordStrictlyBefore(DateTime exclusiveUpper);

  /// Devuelve el id asignado al registro.
  Future<int> addSleepRecord(SleepRecord record);
  Future<void> updateSleepRecord(SleepRecord record);
  Future<void> deleteSleepRecord(int id);

  Future<LactationTimer?> getActiveLactationTimer();
  Future<void> startLactationTimer(LactationSide side);
  Future<void> saveLactationTimer(LactationTimer timer);
  Future<LactationTimer?> stopLactationTimer();

  /// Recarga prefs/outbox tras cambios desde Live Activity o notificación nativa.
  Future<void> syncLactationFromNative({bool afterStop = false});

  /// ID de familia para compartir acceso (Firebase). Null si no aplica.
  Future<String?> getFamilyId();

  /// Une al usuario actual a una familia existente (escaneo QR). Firebase solo.
  Future<void> joinFamily(String familyId);

  /// Vacía la cola de escritura local (p. ej. al cerrar sesión). Sin efecto si no hay cola.
  Future<void> resetLocalSyncState();

  /// Limpia caches en memoria del backend (p. ej. `familyId` cacheado en Firestore).
  void clearRemoteSessionCache();
}
