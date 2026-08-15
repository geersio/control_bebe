import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../config/revenuecat_config.dart';
import '../db/isar_service.dart';
import '../firebase/firebase_service.dart';
import '../models/complimentary_premium.dart';
import '../models/family_paid_premium.dart';
import '../services/purchases_service.dart';

/// familyId de la sesión actual (para leer/escribir el premium de familia).
final familyIdProvider = FutureProvider<String?>((ref) async {
  if (!FirebaseService.isAvailable) return null;
  return IsarService.getFamilyId();
});

/// [CustomerInfo] en vivo desde RevenueCat: valor inicial + cada actualización.
final customerInfoProvider = StreamProvider<CustomerInfo?>((ref) async* {
  if (!PurchasesService.isReady) {
    yield null;
    return;
  }
  yield await PurchasesService.getCustomerInfo();
  yield* PurchasesService.customerInfoStream;
});

/// Premium propio: compra activa en esta cuenta.
final ownPremiumProvider = Provider<bool>((ref) {
  final info = ref.watch(customerInfoProvider).valueOrNull;
  return PurchasesService.isPremiumActive(info);
});

/// Estado de pago de la familia en Firestore (espejo de RevenueCat del pagador).
final familyPaidPremiumProvider = StreamProvider<FamilyPaidPremium?>((ref) async* {
  if (!FirebaseService.isAvailable) {
    yield null;
    return;
  }
  final familyId = await ref.watch(familyIdProvider.future);
  if (familyId == null || familyId.isEmpty) {
    yield null;
    return;
  }
  yield* FirebaseFirestore.instance
      .collection('families')
      .doc(familyId)
      .snapshots()
      .map((snap) => FamilyPaidPremium.fromMap(snap.data()?['premium']));
});

/// Premium de pago heredado de la familia: otro miembro tiene suscripción activa.
final familyPremiumProvider = Provider<bool>((ref) {
  final paid = ref.watch(familyPaidPremiumProvider).valueOrNull;
  return _familyPaidPremiumNotExpired(paid);
});

bool _familyPaidPremiumNotExpired(FamilyPaidPremium? paid) {
  if (paid == null || !paid.active) return false;
  final expiryMs = paid.expiresAtMs;
  if (expiryMs == null) return true;
  return DateTime.now().millisecondsSinceEpoch <
      expiryMs + const Duration(days: 1).inMilliseconds;
}

/// Premium de regalo de la familia (30 días desde el primer miembro que abrió
/// la nueva versión). Todos los miembros comparten la misma fecha de expiración.
final familyComplimentaryPremiumProvider =
    StreamProvider<ComplimentaryPremium?>((ref) async* {
  if (!FirebaseService.isAvailable) {
    yield null;
    return;
  }
  final familyId = await ref.watch(familyIdProvider.future);
  if (familyId == null || familyId.isEmpty) {
    yield null;
    return;
  }
  yield* FirebaseFirestore.instance
      .collection('families')
      .doc(familyId)
      .snapshots()
      .map(
        (snap) => ComplimentaryPremium.fromMap(
          snap.data()?['complimentary_premium'],
        ),
      );
});

/// true si la familia tiene regalo activo (no expirado).
final familyComplimentaryPremiumActiveProvider = Provider<bool>((ref) {
  final grant = ref.watch(familyComplimentaryPremiumProvider).valueOrNull;
  return grant?.isActive ?? false;
});


/// Estado premium efectivo: propio, familia de pago o regalo familiar.
///
/// Sin claves de RevenueCat (desarrollo) no se bloquea nada. Si las hay, un
/// perfil nuevo se trata como no premium hasta que llegue el estado real: si no,
/// parpadean las cards desbloqueadas.
final isPremiumProvider = Provider<bool>((ref) {
  if (!RevenueCatConfig.isConfigured) return true;
  if (!PurchasesService.isReady) return false;
  final own = ref.watch(ownPremiumProvider);
  final familyPaid = ref.watch(familyPremiumProvider);
  final familyGift =
      ref.watch(familyComplimentaryPremiumActiveProvider);
  return own || familyPaid || familyGift;
});

/// Precio del plan anual de la offering actual, para el pie «Después X/año».
final annualPriceProvider = FutureProvider<MonthlyPriceQuote?>((ref) {
  if (!PurchasesService.isReady) return Future.value(null);
  return PurchasesService.getAnnualPrice();
});

/// Precio mensual equivalente más bajo de la offering actual, para los avisos
/// «desde X/mes» fuera del paywall. Null mientras carga o si no hay planes.
final lowestMonthlyPriceProvider = FutureProvider<MonthlyPriceQuote?>((ref) {
  if (!PurchasesService.isReady) return Future.value(null);
  return PurchasesService.getLowestMonthlyPrice();
});

/// Escribe el estado premium del usuario en el documento de familia para que el
/// resto de miembros hereden el acceso.
///
/// Cuidado: un miembro que NO paga no debe pisar el `active:true` de quien sí
/// paga. Por eso solo se limpia el estado cuando el usuario actual era el dueño.
Future<void> syncFamilyPremium(CustomerInfo? info) async {
  if (!FirebaseService.isAvailable) return;
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;
  final familyId = await IsarService.getFamilyId();
  if (familyId == null || familyId.isEmpty) return;

  final active = PurchasesService.isPremiumActive(info);
  final docRef =
      FirebaseFirestore.instance.collection('families').doc(familyId);
  try {
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      final current = snap.data()?['premium'];
      final currentOwner =
          current is Map ? current['ownerUid'] as String? : null;
      final currentActive = current is Map && current['active'] == true;

      if (active) {
        final ent = PurchasesService.premiumEntitlement(info);
        tx.set(docRef, {
          'premium': {
            'active': true,
            'ownerUid': uid,
            'expiresAtMs': PurchasesService.premiumExpiryMs(info),
            'willRenew': ent?.willRenew ?? true,
            'productId': PurchasesService.premiumProductId(info),
            'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
          },
        }, SetOptions(merge: true));
      } else if (currentOwner == uid && currentActive) {
        // Yo era el dueño y he perdido premium: reflejarlo para la familia.
        tx.set(docRef, {
          'premium': {
            'active': false,
            'ownerUid': uid,
            'expiresAtMs': null,
            'willRenew': false,
            'productId': null,
            'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
          },
        }, SetOptions(merge: true));
      }
    });
  } catch (e) {
    debugPrint('syncFamilyPremium error: $e');
  }
}
