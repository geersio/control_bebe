import '../models/diaper_record.dart';
import '../models/enums.dart';
import '../models/feeding_record.dart';
import '../models/height_record.dart';
import '../models/sleep_record.dart';
import '../models/weight_record.dart';

/// Serialización JSON para la cola de sincronización (SharedPreferences).
class RecordSyncCodec {
  RecordSyncCodec._();

  static Map<String, dynamic> weightToJson(WeightRecord r) => {
    'id': r.id,
    'weightKg': r.weightKg,
    'dateTime': r.dateTime.toIso8601String(),
  };

  static WeightRecord weightFromJson(Map<String, dynamic> m) => WeightRecord(
    id: (m['id'] as num?)?.toInt(),
    weightKg: (m['weightKg'] as num).toDouble(),
    dateTime: DateTime.parse(m['dateTime'] as String),
    pendingRemoteSync: false,
  );

  static Map<String, dynamic> heightToJson(HeightRecord r) => {
    'id': r.id,
    'heightCm': r.heightCm,
    'dateTime': r.dateTime.toIso8601String(),
  };

  static HeightRecord heightFromJson(Map<String, dynamic> m) => HeightRecord(
    id: (m['id'] as num?)?.toInt(),
    heightCm: (m['heightCm'] as num).toDouble(),
    dateTime: DateTime.parse(m['dateTime'] as String),
    pendingRemoteSync: false,
  );

  static Map<String, dynamic> diaperToJson(DiaperRecord r) => {
    'id': r.id,
    'type': r.type.index,
    'dateTime': r.dateTime.toIso8601String(),
  };

  static DiaperRecord diaperFromJson(Map<String, dynamic> m) => DiaperRecord(
    id: (m['id'] as num?)?.toInt(),
    type: DiaperType.values[(m['type'] as num).toInt()],
    dateTime: DateTime.parse(m['dateTime'] as String),
    pendingRemoteSync: false,
  );

  static Map<String, dynamic> feedingToJson(FeedingRecord r) => {
    'id': r.id,
    'type': r.type.index,
    'dateTime': r.dateTime.toIso8601String(),
    'durationSeconds': r.durationSeconds,
    'amountMl': r.amountMl,
    'solidName': r.solidName,
    'solidQuantity': r.solidQuantity,
    'solidUnit': r.solidUnit?.index,
  };

  static FeedingRecord feedingFromJson(Map<String, dynamic> m) {
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
    final dateTime = m['dateTimeMs'] != null
        ? DateTime.fromMillisecondsSinceEpoch((m['dateTimeMs'] as num).toInt())
        : DateTime.parse(m['dateTime'] as String).toLocal();
    return FeedingRecord(
      id: (m['id'] as num?)?.toInt(),
      type: type,
      dateTime: dateTime,
      durationSeconds: (m['durationSeconds'] as num?)?.toInt(),
      amountMl: (m['amountMl'] as num?)?.toInt(),
      solidName: m['solidName'] as String?,
      solidQuantity: (m['solidQuantity'] as num?)?.toDouble(),
      solidUnit: solidUnit,
      pendingRemoteSync: false,
    );
  }

  static Map<String, dynamic> sleepToJson(SleepRecord r) => {
    'id': r.id,
    'startDateTime': r.startDateTime.toIso8601String(),
    'endDateTime': r.endDateTime?.toIso8601String() ?? kSleepOpenEndSentinelIso,
    'type': r.type.index,
    if (r.parentSleepId != null) 'parentSleepId': r.parentSleepId,
  };

  static SleepRecord sleepFromJson(Map<String, dynamic> m) {
    final typeIdx = (m['type'] as num?)?.toInt() ?? 0;
    final type = typeIdx >= 0 && typeIdx < SleepType.values.length
        ? SleepType.values[typeIdx]
        : SleepType.night;
    final endRaw = m['endDateTime'] as String?;
    DateTime? end;
    if (endRaw != null && endRaw.isNotEmpty) {
      final parsed = DateTime.parse(endRaw).toLocal();
      if (parsed.year < 9000) end = parsed;
    }
    return SleepRecord(
      id: (m['id'] as num?)?.toInt(),
      startDateTime: DateTime.parse(m['startDateTime'] as String).toLocal(),
      endDateTime: end,
      type: type,
      parentSleepId: (m['parentSleepId'] as num?)?.toInt(),
      pendingRemoteSync: false,
    );
  }
}
