import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/storage_service.dart';
import 'notification_prefs_provider.dart';
import 'premium_provider.dart';
import 'record_stream_providers.dart';

/// Limpia caches de la sesión anterior (familia, perfil, premium, historial).
///
/// Sin esto, al crear un perfil nuevo en el mismo arranque se ve el bebé/premium
/// del usuario anterior hasta que Firestore termina de cargar.
void invalidateAuthSessionProviders(WidgetRef ref) {
  storage.clearRemoteSessionCache();
  ref.invalidate(familyIdProvider);
  ref.invalidate(familyPaidPremiumProvider);
  ref.invalidate(familyComplimentaryPremiumProvider);
  ref.invalidate(customerInfoProvider);
  ref.invalidate(annualPriceProvider);
  ref.invalidate(lowestMonthlyPriceProvider);
  ref.invalidate(notifyNextFeedingProvider);
  resetRecordHistoryFirestoreDays(ref);
}
