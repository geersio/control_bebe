import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/isar_service.dart';

/// Preferencia de notificación de próxima toma (por usuario, no por familia).
final notifyNextFeedingProvider =
    AsyncNotifierProvider<NotifyNextFeedingNotifier, bool>(
      NotifyNextFeedingNotifier.new,
    );

class NotifyNextFeedingNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => IsarService.getNotifyNextFeeding();

  Future<void> set(bool value) async {
    await IsarService.setNotifyNextFeeding(value);
    state = AsyncData(value);
  }
}
