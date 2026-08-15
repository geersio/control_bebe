import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/paywall/views/paywall_view.dart';
import '../../l10n/app_localizations.dart';
import '../config/complimentary_premium_config.dart';
import '../firebase/firebase_service.dart';
import '../models/family_paid_premium.dart';
import '../providers/premium_provider.dart';
import '../services/purchases_service.dart';
import '../theme/app_theme.dart';

class PremiumExpiryWarning {
  final int finalLossExpiresAtMs;
  final int daysRemaining;
  final bool giftOnly;

  const PremiumExpiryWarning({
    required this.finalLossExpiresAtMs,
    required this.daysRemaining,
    required this.giftOnly,
  });

  DateTime get expiresAt => DateTime.fromMillisecondsSinceEpoch(
        finalLossExpiresAtMs,
        isUtc: true,
      ).toLocal();
}

class _PremiumSource {
  final int expiresAtMs;
  final bool willRenew;
  final bool isGift;

  const _PremiumSource({
    required this.expiresAtMs,
    required this.willRenew,
    required this.isGift,
  });
}

/// Aviso one-shot cuando el premium va a expirar sin renovación (≤ 3 días, día 0
/// incluido). Cubre pago propio, familia de pago y regalo.
class PremiumExpiryWarningService {
  PremiumExpiryWarningService._();

  static PremiumExpiryWarning? resolve(WidgetRef ref) {
    if (!PurchasesService.isReady || !ref.read(isPremiumProvider)) {
      return null;
    }

    final info = ref.read(customerInfoProvider).valueOrNull;
    final ownPremium = PurchasesService.isPremiumActive(info);
    final ent = PurchasesService.premiumEntitlement(info);
    final familyPaid = ref.read(familyPaidPremiumProvider).valueOrNull;
    final gift = ref.read(familyComplimentaryPremiumProvider).valueOrNull;

    final sources = <_PremiumSource>[];

    if (ownPremium) {
      final expiryMs = PurchasesService.premiumExpiryMs(info);
      if (expiryMs != null) {
        sources.add(
          _PremiumSource(
            expiresAtMs: expiryMs,
            willRenew: ent?.willRenew ?? false,
            isGift: false,
          ),
        );
      }
    }

    if (familyPaid != null &&
        familyPaid.active &&
        _familyPaidStillActive(familyPaid)) {
      final expiryMs = familyPaid.expiresAtMs;
      if (expiryMs != null) {
        sources.add(
          _PremiumSource(
            expiresAtMs: expiryMs,
            willRenew: familyPaid.willRenew,
            isGift: false,
          ),
        );
      }
    }

    if (gift != null && gift.isActive) {
      sources.add(
        _PremiumSource(
          expiresAtMs: gift.expiresAtMs,
          willRenew: false,
          isGift: true,
        ),
      );
    }

    if (sources.isEmpty || sources.any((s) => s.willRenew)) return null;

    final finalLossMs = sources.map((s) => s.expiresAtMs).reduce(max);
    final daysRemaining = _calendarDaysUntil(finalLossMs);
    if (daysRemaining > ComplimentaryPremiumConfig.expiryWarningWindowDays) {
      return null;
    }

    final hasPaidSource = sources.any((s) => !s.isGift);
    return PremiumExpiryWarning(
      finalLossExpiresAtMs: finalLossMs,
      daysRemaining: daysRemaining,
      giftOnly: !hasPaidSource,
    );
  }

  static bool _familyPaidStillActive(FamilyPaidPremium paid) {
    final expiryMs = paid.expiresAtMs;
    if (expiryMs == null) return true;
    return DateTime.now().millisecondsSinceEpoch < expiryMs;
  }

  static int _calendarDaysUntil(int expiresAtMs) {
    final expiry = DateTime.fromMillisecondsSinceEpoch(
      expiresAtMs,
      isUtc: true,
    ).toLocal();
    final now = DateTime.now();
    final expiryDay = DateTime(expiry.year, expiry.month, expiry.day);
    final today = DateTime(now.year, now.month, now.day);
    return expiryDay.difference(today).inDays;
  }

  static Future<bool> _hasSeenWarningFor(int expiresAtMs) async {
    if (!FirebaseService.isAvailable) return true;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return true;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final settings = doc.data()?['user_settings'] as Map<String, dynamic>?;
    final seen = settings?[ComplimentaryPremiumConfig.expiryWarningPrefKey];
    return seen is num && seen.toInt() == expiresAtMs;
  }

  static Future<void> _markWarningShownFor(int expiresAtMs) async {
    if (!FirebaseService.isAvailable) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'user_settings': {
        ComplimentaryPremiumConfig.expiryWarningPrefKey: expiresAtMs,
      },
    }, SetOptions(merge: true));
  }

  static Future<void> tryShow(BuildContext context, WidgetRef ref) async {
    if (!context.mounted || !PurchasesService.isReady) return;

    final warning = resolve(ref);
    if (warning == null) return;
    if (await _hasSeenWarningFor(warning.finalLossExpiresAtMs)) return;
    if (!context.mounted) return;

    final l10n = AppLocalizations.of(context)!;

    final String body;
    if (warning.giftOnly) {
      body = warning.daysRemaining == 0
          ? l10n.premiumExpiryWarningBodyGiftToday
          : l10n.premiumExpiryWarningBodyGiftDays(warning.daysRemaining);
    } else {
      body = warning.daysRemaining == 0
          ? l10n.premiumExpiryWarningBodyToday
          : l10n.premiumExpiryWarningBodyDays(warning.daysRemaining);
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.dialogRadius),
        ),
        title: Text(l10n.premiumExpiryWarningTitle),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.premiumExpiryWarningDismiss),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (context.mounted) {
                await showAppPaywall(context);
                ref.invalidate(customerInfoProvider);
              }
            },
            child: Text(l10n.premiumExpiryWarningRenew),
          ),
        ],
      ),
    );

    await _markWarningShownFor(warning.finalLossExpiresAtMs);
  }
}
