import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/isar_service.dart';
import '../models/diaper_record.dart';
import '../models/feeding_record.dart';
import '../models/weight_record.dart';

/// Una sola suscripción por tipo de registro (evita varios listeners a Firestore / varios parseos en Web).
final weightRecordsStreamProvider =
    StreamProvider<List<WeightRecord>>((ref) => IsarService.watchWeightRecords());

final diaperRecordsStreamProvider =
    StreamProvider<List<DiaperRecord>>((ref) => IsarService.watchDiaperRecords());

final feedingRecordsStreamProvider =
    StreamProvider<List<FeedingRecord>>((ref) => IsarService.watchFeedingRecords());
