import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import '../models/baby_profile.dart';
import '../models/diaper_record.dart';
import '../models/enums.dart';
import '../models/feeding_record.dart';
import '../models/height_record.dart';
import '../models/lactation_timer.dart';
import '../models/sleep_record.dart';
import '../models/weight_record.dart';
import 'record_sync_codec.dart';
import 'storage_interface.dart';

/// Claves de operaciones persistidas en la cola de salida.
abstract final class SyncKinds {
  static const feedingAdd = 'feeding_add';
  static const feedingUpdate = 'feeding_update';
  static const feedingDelete = 'feeding_delete';
  static const weightAdd = 'weight_add';
  static const weightUpdate = 'weight_update';
  static const weightDelete = 'weight_delete';
  static const heightAdd = 'height_add';
  static const heightUpdate = 'height_update';
  static const heightDelete = 'height_delete';
  static const diaperAdd = 'diaper_add';
  static const diaperUpdate = 'diaper_update';
  static const diaperDelete = 'diaper_delete';
  static const sleepAdd = 'sleep_add';
  static const sleepUpdate = 'sleep_update';
  static const sleepDelete = 'sleep_delete';
}

class _SyncOutboxEntry {
  _SyncOutboxEntry({
    required this.kind,
    required this.payload,
    this.attempts = 0,
    DateTime? nextAttemptAfter,
  }) : nextAttemptAfter =
           nextAttemptAfter ?? DateTime.fromMillisecondsSinceEpoch(0);

  final String kind;
  final Map<String, dynamic> payload;
  int attempts;
  DateTime nextAttemptAfter;

  Map<String, dynamic> toJson() => {
    'kind': kind,
    'payload': payload,
    'attempts': attempts,
    'nextAfterMs': nextAttemptAfter.millisecondsSinceEpoch,
  };

  factory _SyncOutboxEntry.fromJson(Map<String, dynamic> j) => _SyncOutboxEntry(
    kind: j['kind'] as String,
    payload: Map<String, dynamic>.from(j['payload'] as Map),
    attempts: (j['attempts'] as num?)?.toInt() ?? 0,
    nextAttemptAfter: DateTime.fromMillisecondsSinceEpoch(
      (j['nextAfterMs'] as num?)?.toInt() ?? 0,
    ),
  );
}

/// Envuelve un [StorageService] remoto: las escrituras se persisten en cola y se
/// reintentan con retroceso exponencial; las lecturas en vivo fusionan la cola
/// para no dar la sensación de pérdida de datos sin red.
class QueuedStorageService implements StorageService {
  QueuedStorageService(this._remote);

  final StorageService _remote;

  static const _kOutboxKey = 'control_bebe.sync_outbox.v1';
  static const _kLactationTimerKey = 'control_bebe.lactation_timer.v1';
  static const _kBabyProfileKey = 'control_bebe.baby_profile.v1';
  static const _kPendingNativeFeedingKey =
      'control_bebe.lactation_pending_feeding.v1';

  SharedPreferences? _prefs;
  final List<_SyncOutboxEntry> _entries = [];
  final StreamController<void> _outboxTick = StreamController<void>.broadcast();
  Timer? _periodicDrain;
  bool _drainLoopRunning = false;

  int _newLocalId() => DateTime.now().microsecondsSinceEpoch;

  void _notifyOutbox() {
    if (!_outboxTick.isClosed) _outboxTick.add(null);
  }

  Future<void> _persistOutbox() async {
    final p = _prefs;
    if (p == null) return;
    final encoded = jsonEncode(_entries.map((e) => e.toJson()).toList());
    await p.setString(_kOutboxKey, encoded);
  }

  Future<void> _loadOutbox() async {
    _entries.clear();
    final p = _prefs;
    if (p == null) return;
    final raw = p.getString(_kOutboxKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          _entries.add(_SyncOutboxEntry.fromJson(item));
        } else if (item is Map) {
          _entries.add(
            _SyncOutboxEntry.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    } catch (_) {
      _entries.clear();
      await p.remove(_kOutboxKey);
    }
  }

  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Epoch ms (nativo) o ISO (Flutter). Siempre hora local en Dart.
  DateTime _parseLactationDateTime(
    Map<String, dynamic> m,
    String isoKey,
    String msKey,
  ) {
    final ms = m[msKey];
    if (ms is num) {
      return DateTime.fromMillisecondsSinceEpoch(ms.toInt());
    }
    final iso = m[isoKey];
    if (iso is String && iso.isNotEmpty) {
      return DateTime.parse(iso).toLocal();
    }
    throw FormatException('Missing $isoKey / $msKey');
  }

  DateTime? _parseOptionalLactationDateTime(
    Map<String, dynamic> m,
    String isoKey,
    String msKey,
  ) {
    final ms = m[msKey];
    if (ms is num) {
      return DateTime.fromMillisecondsSinceEpoch(ms.toInt());
    }
    final iso = m[isoKey];
    if (iso is String && iso.isNotEmpty) {
      return DateTime.parse(iso).toLocal();
    }
    return null;
  }

  Future<LactationTimer?> _loadLactationLocal() async {
    await _ensurePrefs();
    final raw = _prefs!.getString(_kLactationTimerKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final sideIdx = (m['side'] as num?)?.toInt() ?? 0;
      final side = sideIdx >= 0 && sideIdx < LactationSide.values.length
          ? LactationSide.values[sideIdx]
          : LactationSide.left;
      return LactationTimer(
        id: (m['id'] as num?)?.toInt(),
        side: side,
        startedAt: _parseLactationDateTime(m, 'startedAt', 'startedAtMs'),
        totalPausedMs: (m['totalPausedMs'] as num?)?.toInt() ?? 0,
        pausedAt: _parseOptionalLactationDateTime(m, 'pausedAt', 'pausedAtMs'),
      );
    } catch (_) {
      await _prefs!.remove(_kLactationTimerKey);
      return null;
    }
  }

  Future<void> _saveLactationLocal(LactationTimer t) async {
    await _ensurePrefs();
    await _prefs!.setString(
      _kLactationTimerKey,
      jsonEncode({
        'side': t.side.index,
        'startedAt': t.startedAt.toIso8601String(),
        'startedAtMs': t.startedAt.millisecondsSinceEpoch,
        'id': t.id,
        'totalPausedMs': t.totalPausedMs,
        if (t.pausedAt != null) ...{
          'pausedAt': t.pausedAt!.toIso8601String(),
          'pausedAtMs': t.pausedAt!.millisecondsSinceEpoch,
        },
      }),
    );
  }

  Future<void> _clearLactationLocal() async {
    await _ensurePrefs();
    await _prefs!.remove(_kLactationTimerKey);
  }

  Map<String, dynamic> _babyToJson(BabyProfile p) => {
    'id': p.id,
    'name': p.name,
    'isMale': p.isMale,
    'birthDate': p.birthDate.toIso8601String(),
    'createdAt': p.createdAt?.toIso8601String(),
    'photoUrl': p.photoUrl,
    'heightCm': p.heightCm,
    'expectedFeedingIntervalMinutes': p.expectedFeedingIntervalMinutes,
  };

  BabyProfile? _babyFromJson(Map<String, dynamic> m) {
    final name = m['name'];
    final birthRaw = m['birthDate'];
    if (name is! String || name.trim().isEmpty) return null;
    if (birthRaw is! String || birthRaw.isEmpty) return null;
    return BabyProfile(
      id: (m['id'] as num?)?.toInt(),
      name: name,
      isMale: m['isMale'] as bool?,
      birthDate: DateTime.parse(birthRaw),
      createdAt: m['createdAt'] is String
          ? DateTime.parse(m['createdAt'] as String)
          : null,
      photoUrl: m['photoUrl'] as String?,
      heightCm: (m['heightCm'] as num?)?.toDouble(),
      expectedFeedingIntervalMinutes:
          (m['expectedFeedingIntervalMinutes'] as num?)?.toInt() ?? 180,
    );
  }

  Future<BabyProfile?> _loadBabyLocal() async {
    await _ensurePrefs();
    final raw = _prefs!.getString(_kBabyProfileKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return _babyFromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      await _prefs!.remove(_kBabyProfileKey);
      return null;
    }
  }

  Future<void> _saveBabyLocal(BabyProfile profile) async {
    await _ensurePrefs();
    await _prefs!.setString(_kBabyProfileKey, jsonEncode(_babyToJson(profile)));
  }

  Future<void> _clearBabyLocal() async {
    await _ensurePrefs();
    await _prefs!.remove(_kBabyProfileKey);
  }

  Future<void> _refreshBabyFromRemote() async {
    try {
      final remote = await _remote.getBabyProfile();
      if (remote != null) await _saveBabyLocal(remote);
    } catch (_) {}
  }

  Duration _backoffForAttempt(int n) {
    final ms = math.min(30000, 500 * math.pow(2, n).toInt());
    return Duration(milliseconds: ms);
  }

  Future<void> _enqueue(_SyncOutboxEntry entry) async {
    _entries.add(entry);
    await _persistOutbox();
    _notifyOutbox();
    unawaited(drainOutbox());
  }

  /// Procesa la cola hasta un fallo de red o vaciarse.
  Future<void> drainOutbox() async {
    if (_drainLoopRunning) return;
    _drainLoopRunning = true;
    var scheduledDelayedRetry = false;
    try {
      while (_entries.isNotEmpty) {
        final head = _entries.first;
        final now = DateTime.now();
        if (head.nextAttemptAfter.isAfter(now)) {
          final wait = head.nextAttemptAfter.difference(now);
          scheduledDelayedRetry = true;
          Future<void>.delayed(wait, drainOutbox);
          break;
        }
        try {
          await _executeHead(head);
          _entries.removeAt(0);
          await _persistOutbox();
          _notifyOutbox();
        } catch (_) {
          head.attempts++;
          head.nextAttemptAfter = DateTime.now().add(
            _backoffForAttempt(head.attempts),
          );
          await _persistOutbox();
          _notifyOutbox();
          scheduledDelayedRetry = true;
          Future<void>.delayed(_backoffForAttempt(head.attempts), drainOutbox);
          break;
        }
      }
    } finally {
      _drainLoopRunning = false;
    }
    if (_entries.isNotEmpty && !scheduledDelayedRetry) {
      scheduleMicrotask(() {
        unawaited(drainOutbox());
      });
    }
  }

  Future<void> _executeHead(_SyncOutboxEntry e) async {
    final k = e.kind;
    if (k == SyncKinds.feedingAdd) {
      await _remote.addFeedingRecord(
        RecordSyncCodec.feedingFromJson(
          e.payload,
        ).copyWith(pendingRemoteSync: false),
      );
    } else if (k == SyncKinds.feedingUpdate) {
      await _remote.updateFeedingRecord(
        RecordSyncCodec.feedingFromJson(
          e.payload,
        ).copyWith(pendingRemoteSync: false),
      );
    } else if (k == SyncKinds.feedingDelete) {
      await _remote.deleteFeedingRecord((e.payload['id'] as num).toInt());
    } else if (k == SyncKinds.weightAdd) {
      await _remote.addWeightRecord(
        RecordSyncCodec.weightFromJson(
          e.payload,
        ).copyWith(pendingRemoteSync: false),
      );
    } else if (k == SyncKinds.weightUpdate) {
      await _remote.updateWeightRecord(
        RecordSyncCodec.weightFromJson(
          e.payload,
        ).copyWith(pendingRemoteSync: false),
      );
    } else if (k == SyncKinds.weightDelete) {
      await _remote.deleteWeightRecord((e.payload['id'] as num).toInt());
    } else if (k == SyncKinds.heightAdd) {
      await _remote.addHeightRecord(
        RecordSyncCodec.heightFromJson(
          e.payload,
        ).copyWith(pendingRemoteSync: false),
      );
    } else if (k == SyncKinds.heightUpdate) {
      await _remote.updateHeightRecord(
        RecordSyncCodec.heightFromJson(
          e.payload,
        ).copyWith(pendingRemoteSync: false),
      );
    } else if (k == SyncKinds.heightDelete) {
      await _remote.deleteHeightRecord((e.payload['id'] as num).toInt());
    } else if (k == SyncKinds.diaperAdd) {
      await _remote.addDiaperRecord(
        RecordSyncCodec.diaperFromJson(
          e.payload,
        ).copyWith(pendingRemoteSync: false),
      );
    } else if (k == SyncKinds.diaperUpdate) {
      await _remote.updateDiaperRecord(
        RecordSyncCodec.diaperFromJson(
          e.payload,
        ).copyWith(pendingRemoteSync: false),
      );
    } else if (k == SyncKinds.diaperDelete) {
      await _remote.deleteDiaperRecord((e.payload['id'] as num).toInt());
    } else if (k == SyncKinds.sleepAdd) {
      await _remote.addSleepRecord(
        RecordSyncCodec.sleepFromJson(
          e.payload,
        ).copyWith(pendingRemoteSync: false),
      );
    } else if (k == SyncKinds.sleepUpdate) {
      await _remote.updateSleepRecord(
        RecordSyncCodec.sleepFromJson(
          e.payload,
        ).copyWith(pendingRemoteSync: false),
      );
    } else if (k == SyncKinds.sleepDelete) {
      await _remote.deleteSleepRecord((e.payload['id'] as num).toInt());
    }
  }

  // --- Scrub / enqueue helpers ---

  void _removeAllOpsForFeedingId(int id) {
    _entries.removeWhere((e) {
      if (!e.kind.startsWith('feeding_')) return false;
      if (e.kind == SyncKinds.feedingDelete) {
        return (e.payload['id'] as num?)?.toInt() == id;
      }
      return (e.payload['id'] as num?)?.toInt() == id;
    });
  }

  bool _scrubFeedingAddUpdate(int id) {
    var hadAdd = false;
    _entries.removeWhere((e) {
      if (e.kind == SyncKinds.feedingAdd &&
          (e.payload['id'] as num?)?.toInt() == id) {
        hadAdd = true;
        return true;
      }
      if (e.kind == SyncKinds.feedingUpdate &&
          (e.payload['id'] as num?)?.toInt() == id) {
        return true;
      }
      return false;
    });
    return hadAdd;
  }

  void _removeAllOpsForWeightId(int id) {
    _entries.removeWhere((e) {
      if (!e.kind.startsWith('weight_')) return false;
      if (e.kind == SyncKinds.weightDelete) {
        return (e.payload['id'] as num?)?.toInt() == id;
      }
      return (e.payload['id'] as num?)?.toInt() == id;
    });
  }

  bool _scrubWeightAddUpdate(int id) {
    var hadAdd = false;
    _entries.removeWhere((e) {
      if (e.kind == SyncKinds.weightAdd &&
          (e.payload['id'] as num?)?.toInt() == id) {
        hadAdd = true;
        return true;
      }
      if (e.kind == SyncKinds.weightUpdate &&
          (e.payload['id'] as num?)?.toInt() == id) {
        return true;
      }
      return false;
    });
    return hadAdd;
  }

  void _removeAllOpsForHeightId(int id) {
    _entries.removeWhere((e) {
      if (!e.kind.startsWith('height_')) return false;
      if (e.kind == SyncKinds.heightDelete) {
        return (e.payload['id'] as num?)?.toInt() == id;
      }
      return (e.payload['id'] as num?)?.toInt() == id;
    });
  }

  bool _scrubHeightAddUpdate(int id) {
    var hadAdd = false;
    _entries.removeWhere((e) {
      if (e.kind == SyncKinds.heightAdd &&
          (e.payload['id'] as num?)?.toInt() == id) {
        hadAdd = true;
        return true;
      }
      if (e.kind == SyncKinds.heightUpdate &&
          (e.payload['id'] as num?)?.toInt() == id) {
        return true;
      }
      return false;
    });
    return hadAdd;
  }

  void _removeAllOpsForDiaperId(int id) {
    _entries.removeWhere((e) {
      if (!e.kind.startsWith('diaper_')) return false;
      if (e.kind == SyncKinds.diaperDelete) {
        return (e.payload['id'] as num?)?.toInt() == id;
      }
      return (e.payload['id'] as num?)?.toInt() == id;
    });
  }

  bool _scrubDiaperAddUpdate(int id) {
    var hadAdd = false;
    _entries.removeWhere((e) {
      if (e.kind == SyncKinds.diaperAdd &&
          (e.payload['id'] as num?)?.toInt() == id) {
        hadAdd = true;
        return true;
      }
      if (e.kind == SyncKinds.diaperUpdate &&
          (e.payload['id'] as num?)?.toInt() == id) {
        return true;
      }
      return false;
    });
    return hadAdd;
  }

  void _removeAllOpsForSleepId(int id) {
    _entries.removeWhere((e) {
      if (!e.kind.startsWith('sleep_')) return false;
      if (e.kind == SyncKinds.sleepDelete) {
        return (e.payload['id'] as num?)?.toInt() == id;
      }
      return (e.payload['id'] as num?)?.toInt() == id;
    });
  }

  bool _scrubSleepAddUpdate(int id) {
    var hadAdd = false;
    _entries.removeWhere((e) {
      if (e.kind == SyncKinds.sleepAdd &&
          (e.payload['id'] as num?)?.toInt() == id) {
        hadAdd = true;
        return true;
      }
      if (e.kind == SyncKinds.sleepUpdate &&
          (e.payload['id'] as num?)?.toInt() == id) {
        return true;
      }
      return false;
    });
    return hadAdd;
  }

  // --- Merge (overlay cola sobre remoto) ---

  static Set<int> _pendingIdsForPrefix(
    List<_SyncOutboxEntry> entries,
    String prefix,
  ) {
    final ids = <int>{};
    for (final e in entries) {
      if (!e.kind.startsWith(prefix)) continue;
      if (e.kind.endsWith('_delete')) continue;
      final id = (e.payload['id'] as num?)?.toInt();
      if (id != null) ids.add(id);
    }
    return ids;
  }

  List<FeedingRecord> _mergeFeedings(
    List<FeedingRecord> remote,
    DateTime fromInclusive,
  ) {
    final pendingIds = _pendingIdsForPrefix(_entries, 'feeding_');
    final map = <int, FeedingRecord>{};
    for (final r in remote) {
      final id = r.id;
      if (id == null) continue;
      map[id] = r.copyWith(pendingRemoteSync: pendingIds.contains(id));
    }
    for (final e in _entries) {
      final k = e.kind;
      if (k == SyncKinds.feedingAdd || k == SyncKinds.feedingUpdate) {
        final rec = RecordSyncCodec.feedingFromJson(
          e.payload,
        ).copyWith(pendingRemoteSync: true);
        if (rec.id != null) map[rec.id!] = rec;
      } else if (k == SyncKinds.feedingDelete) {
        map.remove((e.payload['id'] as num).toInt());
      }
    }
    final list =
        map.values.where((r) => !r.dateTime.isBefore(fromInclusive)).toList()
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return list;
  }

  List<WeightRecord> _mergeWeights(
    List<WeightRecord> remote,
    DateTime fromInclusive,
  ) {
    final pendingIds = _pendingIdsForPrefix(_entries, 'weight_');
    final map = <int, WeightRecord>{};
    for (final r in remote) {
      final id = r.id;
      if (id == null) continue;
      map[id] = r.copyWith(pendingRemoteSync: pendingIds.contains(id));
    }
    for (final e in _entries) {
      final k = e.kind;
      if (k == SyncKinds.weightAdd || k == SyncKinds.weightUpdate) {
        final rec = RecordSyncCodec.weightFromJson(
          e.payload,
        ).copyWith(pendingRemoteSync: true);
        if (rec.id != null) map[rec.id!] = rec;
      } else if (k == SyncKinds.weightDelete) {
        map.remove((e.payload['id'] as num).toInt());
      }
    }
    final list =
        map.values.where((r) => !r.dateTime.isBefore(fromInclusive)).toList()
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return list;
  }

  List<HeightRecord> _mergeHeights(List<HeightRecord> remote) {
    final pendingIds = _pendingIdsForPrefix(_entries, 'height_');
    final map = <int, HeightRecord>{};
    for (final r in remote) {
      final id = r.id;
      if (id == null) continue;
      map[id] = r.copyWith(pendingRemoteSync: pendingIds.contains(id));
    }
    for (final e in _entries) {
      final k = e.kind;
      if (k == SyncKinds.heightAdd || k == SyncKinds.heightUpdate) {
        final rec = RecordSyncCodec.heightFromJson(
          e.payload,
        ).copyWith(pendingRemoteSync: true);
        if (rec.id != null) map[rec.id!] = rec;
      } else if (k == SyncKinds.heightDelete) {
        map.remove((e.payload['id'] as num).toInt());
      }
    }
    return map.values.toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  List<DiaperRecord> _mergeDiapers(
    List<DiaperRecord> remote,
    DateTime fromInclusive,
  ) {
    final pendingIds = _pendingIdsForPrefix(_entries, 'diaper_');
    final map = <int, DiaperRecord>{};
    for (final r in remote) {
      final id = r.id;
      if (id == null) continue;
      map[id] = r.copyWith(pendingRemoteSync: pendingIds.contains(id));
    }
    for (final e in _entries) {
      final k = e.kind;
      if (k == SyncKinds.diaperAdd || k == SyncKinds.diaperUpdate) {
        final rec = RecordSyncCodec.diaperFromJson(
          e.payload,
        ).copyWith(pendingRemoteSync: true);
        if (rec.id != null) map[rec.id!] = rec;
      } else if (k == SyncKinds.diaperDelete) {
        map.remove((e.payload['id'] as num).toInt());
      }
    }
    final list =
        map.values.where((r) => !r.dateTime.isBefore(fromInclusive)).toList()
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return list;
  }

  List<FeedingRecord> _allMergedFeedingsDesc(List<FeedingRecord> remoteSeed) {
    final map = <int, FeedingRecord>{};
    for (final r in remoteSeed) {
      if (r.id != null) map[r.id!] = r;
    }
    for (final e in _entries) {
      final k = e.kind;
      if (k == SyncKinds.feedingAdd || k == SyncKinds.feedingUpdate) {
        final rec = RecordSyncCodec.feedingFromJson(e.payload);
        if (rec.id != null) map[rec.id!] = rec;
      } else if (k == SyncKinds.feedingDelete) {
        map.remove((e.payload['id'] as num).toInt());
      }
    }
    final pendingIds = _pendingIdsForPrefix(_entries, 'feeding_');
    final withFlags =
        map.values
            .map(
              (r) => r.copyWith(pendingRemoteSync: pendingIds.contains(r.id)),
            )
            .toList()
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return withFlags;
  }

  List<DiaperRecord> _allMergedDiapersDesc(List<DiaperRecord> remoteSeed) {
    final map = <int, DiaperRecord>{};
    for (final r in remoteSeed) {
      if (r.id != null) map[r.id!] = r;
    }
    for (final e in _entries) {
      final k = e.kind;
      if (k == SyncKinds.diaperAdd || k == SyncKinds.diaperUpdate) {
        final rec = RecordSyncCodec.diaperFromJson(e.payload);
        if (rec.id != null) map[rec.id!] = rec;
      } else if (k == SyncKinds.diaperDelete) {
        map.remove((e.payload['id'] as num).toInt());
      }
    }
    final pendingIds = _pendingIdsForPrefix(_entries, 'diaper_');
    return map.values
        .map((r) => r.copyWith(pendingRemoteSync: pendingIds.contains(r.id)))
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  List<WeightRecord> _allMergedWeightsDesc(List<WeightRecord> remoteSeed) {
    final map = <int, WeightRecord>{};
    for (final r in remoteSeed) {
      if (r.id != null) map[r.id!] = r;
    }
    for (final e in _entries) {
      final k = e.kind;
      if (k == SyncKinds.weightAdd || k == SyncKinds.weightUpdate) {
        final rec = RecordSyncCodec.weightFromJson(e.payload);
        if (rec.id != null) map[rec.id!] = rec;
      } else if (k == SyncKinds.weightDelete) {
        map.remove((e.payload['id'] as num).toInt());
      }
    }
    final pendingIds = _pendingIdsForPrefix(_entries, 'weight_');
    return map.values
        .map((r) => r.copyWith(pendingRemoteSync: pendingIds.contains(r.id)))
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  bool _outboxHasFeedingStrictlyBefore(DateTime exclusiveUpper) {
    for (final e in _entries) {
      if (!e.kind.startsWith('feeding_')) continue;
      if (e.kind == SyncKinds.feedingDelete) continue;
      final rec = RecordSyncCodec.feedingFromJson(e.payload);
      if (rec.dateTime.isBefore(exclusiveUpper)) return true;
    }
    return false;
  }

  bool _outboxHasDiaperStrictlyBefore(DateTime exclusiveUpper) {
    for (final e in _entries) {
      if (!e.kind.startsWith('diaper_')) continue;
      if (e.kind == SyncKinds.diaperDelete) continue;
      final rec = RecordSyncCodec.diaperFromJson(e.payload);
      if (rec.dateTime.isBefore(exclusiveUpper)) return true;
    }
    return false;
  }

  List<SleepRecord> _mergeSleeps(
    List<SleepRecord> remote,
    DateTime fromInclusive,
  ) {
    final pendingIds = _pendingIdsForPrefix(_entries, 'sleep_');
    final map = <int, SleepRecord>{};
    for (final r in remote) {
      final id = r.id;
      if (id == null) continue;
      map[id] = r.copyWith(pendingRemoteSync: pendingIds.contains(id));
    }
    for (final e in _entries) {
      final k = e.kind;
      if (k == SyncKinds.sleepAdd || k == SyncKinds.sleepUpdate) {
        final rec = RecordSyncCodec.sleepFromJson(
          e.payload,
        ).copyWith(pendingRemoteSync: true);
        if (rec.id != null) map[rec.id!] = rec;
      } else if (k == SyncKinds.sleepDelete) {
        map.remove((e.payload['id'] as num).toInt());
      }
    }
    final list = map.values.where((r) {
      if (r.isOpen) return true;
      return !r.sortAt.isBefore(fromInclusive);
    }).toList()..sort((a, b) => b.sortAt.compareTo(a.sortAt));
    return list;
  }

  bool _outboxHasSleepStrictlyBefore(DateTime exclusiveUpper) {
    for (final e in _entries) {
      if (!e.kind.startsWith('sleep_')) continue;
      if (e.kind == SyncKinds.sleepDelete) continue;
      final rec = RecordSyncCodec.sleepFromJson(e.payload);
      if (rec.isOpen) {
        if (rec.startDateTime.isBefore(exclusiveUpper)) return true;
        continue;
      }
      if (rec.sortAt.isBefore(exclusiveUpper)) return true;
    }
    return false;
  }

  bool _outboxHasWeightStrictlyBefore(DateTime exclusiveUpper) {
    for (final e in _entries) {
      if (!e.kind.startsWith('weight_')) continue;
      if (e.kind == SyncKinds.weightDelete) continue;
      final rec = RecordSyncCodec.weightFromJson(e.payload);
      if (rec.dateTime.isBefore(exclusiveUpper)) return true;
    }
    return false;
  }

  Stream<List<T>> _combinedWatch<T>(
    Stream<List<T>> remoteStream,
    List<T> Function(List<T> remote) merge,
  ) {
    List<T>? latestRemote;

    void emit(StreamController<List<T>> c) {
      if (c.isClosed) return;
      final r = latestRemote;
      if (r != null) {
        c.add(merge(r));
        return;
      }
      final local = merge(<T>[]);
      if (local.isNotEmpty) c.add(local);
    }

    late final StreamSubscription<List<T>> subRemote;
    late final StreamSubscription<void> subTick;

    final controller = StreamController<List<T>>(
      onCancel: () {
        subRemote.cancel();
        subTick.cancel();
      },
    );

    subRemote = remoteStream.listen(
      (r) {
        latestRemote = r;
        emit(controller);
      },
      onError: controller.addError,
      onDone: () {
        subTick.cancel();
        if (!controller.isClosed) controller.close();
      },
    );

    subTick = _outboxTick.stream.listen((_) => emit(controller));
    emit(controller);

    return controller.stream;
  }

  @override
  Future<void> resetLocalSyncState() async {
    _entries.clear();
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(_kOutboxKey);
    await _prefs!.remove(_kLactationTimerKey);
    await _prefs!.remove(_kBabyProfileKey);
    _notifyOutbox();
    _remote.clearRemoteSessionCache();
  }

  @override
  void clearRemoteSessionCache() {
    _remote.clearRemoteSessionCache();
  }

  @override
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadOutbox();
    await _remote.initialize();
    _periodicDrain?.cancel();
    _periodicDrain = Timer.periodic(const Duration(seconds: 45), (_) {
      unawaited(drainOutbox());
    });
    unawaited(drainOutbox());
  }

  @override
  Future<bool> needsOnboarding() async {
    final local = await _loadBabyLocal();
    if (local != null && local.name.trim().isNotEmpty) return false;
    return _remote.needsOnboarding();
  }

  @override
  Future<void> completeOnboarding() => _remote.completeOnboarding();

  @override
  Future<BabyProfile?> getBabyProfile() async {
    final local = await _loadBabyLocal();
    if (local != null) {
      unawaited(_refreshBabyFromRemote());
      return local;
    }
    try {
      final remote = await _remote.getBabyProfile();
      if (remote != null) await _saveBabyLocal(remote);
      return remote;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveBabyProfile(BabyProfile profile) async {
    await _saveBabyLocal(profile);
    unawaited(_remote.saveBabyProfile(profile));
  }

  @override
  Future<bool> createBabyProfileIfAbsent(BabyProfile profile) async {
    await _saveBabyLocal(profile);
    try {
      final created = await _remote.createBabyProfileIfAbsent(profile);
      if (!created) {
        await _clearBabyLocal();
        return false;
      }
      return true;
    } catch (_) {
      unawaited(_remote.saveBabyProfile(profile));
      return true;
    }
  }

  @override
  Future<bool> getNotifyNextFeeding() => _remote.getNotifyNextFeeding();

  @override
  Future<void> setNotifyNextFeeding(bool value) =>
      _remote.setNotifyNextFeeding(value);

  @override
  Stream<List<WeightRecord>> watchWeightRecordsSince(DateTime fromInclusive) {
    return _combinedWatch(
      _remote.watchWeightRecordsSince(fromInclusive),
      (remote) => _mergeWeights(remote, fromInclusive),
    );
  }

  @override
  Stream<List<WeightRecord>> watchAllWeightRecords() {
    return _combinedWatch(
      _remote.watchAllWeightRecords(),
      _allMergedWeightsDesc,
    );
  }

  @override
  Future<List<WeightRecord>> getWeightRecords() async {
    final remote = await _remote.getWeightRecords();
    return _allMergedWeightsDesc(remote);
  }

  @override
  Future<bool> hasWeightRecordStrictlyBefore(DateTime exclusiveUpper) async {
    final r = await _remote.hasWeightRecordStrictlyBefore(exclusiveUpper);
    if (r) return true;
    return _outboxHasWeightStrictlyBefore(exclusiveUpper);
  }

  @override
  Future<void> addWeightRecord(WeightRecord record) async {
    final id = record.id ?? _newLocalId();
    final withId = record.copyWith(id: id, pendingRemoteSync: false);
    await _enqueue(
      _SyncOutboxEntry(
        kind: SyncKinds.weightAdd,
        payload: RecordSyncCodec.weightToJson(withId),
      ),
    );
  }

  @override
  Future<void> updateWeightRecord(WeightRecord record) async {
    if (record.id == null) return;
    final id = record.id!;
    final hadAdd = _scrubWeightAddUpdate(id);
    final kind = hadAdd ? SyncKinds.weightAdd : SyncKinds.weightUpdate;
    await _enqueue(
      _SyncOutboxEntry(
        kind: kind,
        payload: RecordSyncCodec.weightToJson(record.copyWith(id: id)),
      ),
    );
  }

  @override
  Future<void> deleteWeightRecord(int id) async {
    _removeAllOpsForWeightId(id);
    await _persistOutbox();
    _notifyOutbox();
    await _enqueue(
      _SyncOutboxEntry(kind: SyncKinds.weightDelete, payload: {'id': id}),
    );
  }

  @override
  Stream<List<HeightRecord>> watchAllHeightRecords() {
    return _combinedWatch(_remote.watchAllHeightRecords(), _mergeHeights);
  }

  @override
  Future<List<HeightRecord>> getHeightRecords() async {
    final remote = await _remote.getHeightRecords();
    return _mergeHeights(remote);
  }

  @override
  Future<void> addHeightRecord(HeightRecord record) async {
    final id = record.id ?? _newLocalId();
    final withId = record.copyWith(id: id, pendingRemoteSync: false);
    await _enqueue(
      _SyncOutboxEntry(
        kind: SyncKinds.heightAdd,
        payload: RecordSyncCodec.heightToJson(withId),
      ),
    );
  }

  @override
  Future<void> updateHeightRecord(HeightRecord record) async {
    if (record.id == null) return;
    final id = record.id!;
    final hadAdd = _scrubHeightAddUpdate(id);
    final kind = hadAdd ? SyncKinds.heightAdd : SyncKinds.heightUpdate;
    await _enqueue(
      _SyncOutboxEntry(
        kind: kind,
        payload: RecordSyncCodec.heightToJson(record.copyWith(id: id)),
      ),
    );
  }

  @override
  Future<void> deleteHeightRecord(int id) async {
    _removeAllOpsForHeightId(id);
    await _persistOutbox();
    _notifyOutbox();
    await _enqueue(
      _SyncOutboxEntry(kind: SyncKinds.heightDelete, payload: {'id': id}),
    );
  }

  @override
  Stream<List<DiaperRecord>> watchDiaperRecordsSince(DateTime fromInclusive) {
    return _combinedWatch(
      _remote.watchDiaperRecordsSince(fromInclusive),
      (remote) => _mergeDiapers(remote, fromInclusive),
    );
  }

  @override
  Future<List<DiaperRecord>> getDiaperRecordsSince(
    DateTime fromInclusive,
  ) async {
    final remote = await _remote.getDiaperRecordsSince(fromInclusive);
    return _mergeDiapers(remote, fromInclusive);
  }

  @override
  Future<bool> hasDiaperRecordStrictlyBefore(DateTime exclusiveUpper) async {
    final r = await _remote.hasDiaperRecordStrictlyBefore(exclusiveUpper);
    if (r) return true;
    return _outboxHasDiaperStrictlyBefore(exclusiveUpper);
  }

  @override
  Future<List<DiaperRecord>> getDiaperRecordsToday() async {
    final remote = await _remote.getDiaperRecordsToday();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final merged = _allMergedDiapersDesc(remote);
    return merged
        .where((r) => !r.dateTime.isBefore(start) && r.dateTime.isBefore(end))
        .toList();
  }

  @override
  Future<List<DiaperRecord>> getDiaperRecordsLast7Days() async {
    final remote = await _remote.getDiaperRecordsLast7Days();
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final merged = _allMergedDiapersDesc(remote);
    return merged.where((r) => !r.dateTime.isBefore(cutoff)).toList();
  }

  @override
  Future<DiaperRecord?> getLastDiaperRecord() async {
    final remote = await _remote.getLastDiaperRecord();
    final merged = _allMergedDiapersDesc(remote != null ? [remote] : []);
    return merged.isEmpty ? null : merged.first;
  }

  @override
  Future<void> addDiaperRecord(DiaperRecord record) async {
    final id = record.id ?? _newLocalId();
    final withId = record.copyWith(id: id, pendingRemoteSync: false);
    await _enqueue(
      _SyncOutboxEntry(
        kind: SyncKinds.diaperAdd,
        payload: RecordSyncCodec.diaperToJson(withId),
      ),
    );
  }

  @override
  Future<void> updateDiaperRecord(DiaperRecord record) async {
    if (record.id == null) return;
    final id = record.id!;
    final hadAdd = _scrubDiaperAddUpdate(id);
    final kind = hadAdd ? SyncKinds.diaperAdd : SyncKinds.diaperUpdate;
    await _enqueue(
      _SyncOutboxEntry(
        kind: kind,
        payload: RecordSyncCodec.diaperToJson(record.copyWith(id: id)),
      ),
    );
  }

  @override
  Future<void> deleteDiaperRecord(int id) async {
    _removeAllOpsForDiaperId(id);
    await _persistOutbox();
    _notifyOutbox();
    await _enqueue(
      _SyncOutboxEntry(kind: SyncKinds.diaperDelete, payload: {'id': id}),
    );
  }

  @override
  Stream<List<SleepRecord>> watchSleepRecordsSince(DateTime fromInclusive) {
    return _combinedWatch(
      _remote.watchSleepRecordsSince(fromInclusive),
      (remote) => _mergeSleeps(remote, fromInclusive),
    );
  }

  @override
  Future<List<SleepRecord>> getSleepRecordsSince(DateTime fromInclusive) async {
    final remote = await _remote.getSleepRecordsSince(fromInclusive);
    return _mergeSleeps(remote, fromInclusive);
  }

  @override
  Future<bool> hasSleepRecordStrictlyBefore(DateTime exclusiveUpper) async {
    final r = await _remote.hasSleepRecordStrictlyBefore(exclusiveUpper);
    if (r) return true;
    return _outboxHasSleepStrictlyBefore(exclusiveUpper);
  }

  @override
  Future<int> addSleepRecord(SleepRecord record) async {
    final id = record.id ?? _newLocalId();
    final withId = record.copyWith(id: id, pendingRemoteSync: false);
    await _enqueue(
      _SyncOutboxEntry(
        kind: SyncKinds.sleepAdd,
        payload: RecordSyncCodec.sleepToJson(withId),
      ),
    );
    return id;
  }

  @override
  Future<void> updateSleepRecord(SleepRecord record) async {
    if (record.id == null) return;
    final id = record.id!;
    final hadAdd = _scrubSleepAddUpdate(id);
    final kind = hadAdd ? SyncKinds.sleepAdd : SyncKinds.sleepUpdate;
    await _enqueue(
      _SyncOutboxEntry(
        kind: kind,
        payload: RecordSyncCodec.sleepToJson(record.copyWith(id: id)),
      ),
    );
  }

  @override
  Future<void> deleteSleepRecord(int id) async {
    _removeAllOpsForSleepId(id);
    await _persistOutbox();
    _notifyOutbox();
    await _enqueue(
      _SyncOutboxEntry(kind: SyncKinds.sleepDelete, payload: {'id': id}),
    );
  }

  @override
  Stream<List<FeedingRecord>> watchFeedingRecordsSince(DateTime fromInclusive) {
    return _combinedWatch(
      _remote.watchFeedingRecordsSince(fromInclusive),
      (remote) => _mergeFeedings(remote, fromInclusive),
    );
  }

  @override
  Future<List<FeedingRecord>> getFeedingRecordsSince(
    DateTime fromInclusive,
  ) async {
    final remote = await _remote.getFeedingRecordsSince(fromInclusive);
    return _mergeFeedings(remote, fromInclusive);
  }

  @override
  Future<bool> hasFeedingRecordStrictlyBefore(DateTime exclusiveUpper) async {
    final r = await _remote.hasFeedingRecordStrictlyBefore(exclusiveUpper);
    if (r) return true;
    return _outboxHasFeedingStrictlyBefore(exclusiveUpper);
  }

  @override
  Future<List<FeedingRecord>> getFeedingRecordsToday() async {
    final remote = await _remote.getFeedingRecordsToday();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final merged = _allMergedFeedingsDesc(remote);
    return merged
        .where((r) => !r.dateTime.isBefore(start) && r.dateTime.isBefore(end))
        .toList();
  }

  @override
  Future<FeedingRecord?> getLastFeedingRecord() async {
    final remote = await _remote.getLastFeedingRecord();
    final merged = _allMergedFeedingsDesc(remote != null ? [remote] : []);
    return merged.isEmpty ? null : merged.first;
  }

  @override
  Future<void> addFeedingRecord(FeedingRecord record) async {
    final id = record.id ?? _newLocalId();
    final withId = record.copyWith(id: id, pendingRemoteSync: false);
    await _enqueue(
      _SyncOutboxEntry(
        kind: SyncKinds.feedingAdd,
        payload: RecordSyncCodec.feedingToJson(withId),
      ),
    );
  }

  @override
  Future<void> updateFeedingRecord(FeedingRecord record) async {
    if (record.id == null) return;
    final id = record.id!;
    final hadAdd = _scrubFeedingAddUpdate(id);
    final kind = hadAdd ? SyncKinds.feedingAdd : SyncKinds.feedingUpdate;
    await _enqueue(
      _SyncOutboxEntry(
        kind: kind,
        payload: RecordSyncCodec.feedingToJson(record.copyWith(id: id)),
      ),
    );
  }

  @override
  Future<void> deleteFeedingRecord(int id) async {
    _removeAllOpsForFeedingId(id);
    await _persistOutbox();
    _notifyOutbox();
    await _enqueue(
      _SyncOutboxEntry(kind: SyncKinds.feedingDelete, payload: {'id': id}),
    );
  }

  @override
  Future<LactationTimer?> getActiveLactationTimer() => _loadLactationLocal();

  @override
  Future<void> startLactationTimer(LactationSide side) async {
    final now = DateTime.now();
    await _saveLactationLocal(LactationTimer(side: side, startedAt: now));
  }

  @override
  Future<void> saveLactationTimer(LactationTimer timer) async {
    await _saveLactationLocal(timer);
  }

  @override
  Future<LactationTimer?> stopLactationTimer() async {
    final t = await _loadLactationLocal();
    await _clearLactationLocal();
    return t;
  }

  @override
  Future<void> syncLactationFromNative({bool afterStop = false}) async {
    await _ensurePrefs();
    await _prefs!.reload();
    await _loadOutbox();
    if (afterStop) {
      await _enqueuePendingNativeFeeding();
      unawaited(drainOutbox());
    }
  }

  /// Toma encolada por Live Activity sin tocar el outbox completo (evita revivir borrados).
  Future<void> _enqueuePendingNativeFeeding() async {
    final raw = _prefs!.getString(_kPendingNativeFeedingKey);
    if (raw == null || raw.isEmpty) return;
    await _prefs!.remove(_kPendingNativeFeedingKey);
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      _entries.add(_SyncOutboxEntry.fromJson(m));
      await _persistOutbox();
      _notifyOutbox();
    } catch (_) {
      // Ignorar JSON corrupto.
    }
  }

  @override
  Future<String?> getFamilyId() => _remote.getFamilyId();

  @override
  Future<void> joinFamily(String familyId) async {
    await _remote.joinFamily(familyId);
    try {
      final remote = await _remote.getBabyProfile();
      if (remote != null) {
        await _saveBabyLocal(remote);
      } else {
        await _clearBabyLocal();
      }
    } catch (_) {}
  }
}
