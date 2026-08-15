import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../config/complimentary_premium_config.dart';
import '../db/isar_service.dart';
import '../firebase/firebase_service.dart';
import '../models/complimentary_premium.dart';

/// Concede y lee el Premium de regalo a nivel familia en Firestore.
class ComplimentaryPremiumService {
  ComplimentaryPremiumService._();

  static ComplimentaryPremium? _parseFamilyComplimentary(
    Map<String, dynamic>? data,
  ) {
    return ComplimentaryPremium.fromMap(data?['complimentary_premium']);
  }

  static bool _isEligibleForGrant(Map<String, dynamic> familyData) {
    final settings = familyData['app_settings'] as Map<String, dynamic>?;
    if (settings?['onboardingCompleted'] != true) return false;
    final profile = familyData['baby_profile'] as Map<String, dynamic>?;
    final profileCreatedAt = DateTime.tryParse(
      profile?['createdAt'] as String? ?? '',
    );
    if (profileCreatedAt == null) return false;
    return profileCreatedAt.toUtc().isBefore(
      ComplimentaryPremiumConfig.launchCutoff,
    );
  }

  /// Si la familia aún no tiene regalo y es elegible, lo crea (30 días desde
  /// ahora). Si ya existe, lo devuelve tal cual (activo o expirado).
  static Future<ComplimentaryPremium?> ensureFamilyGrant() async {
    if (!FirebaseService.isAvailable) return null;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final familyId = await IsarService.getFamilyId();
    if (familyId == null || familyId.isEmpty) return null;

    final docRef = FirebaseFirestore.instance
        .collection('families')
        .doc(familyId);
    try {
      return await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(docRef);
        final data = snap.data();
        if (data == null) return null;

        final eligible = _isEligibleForGrant(data);
        final existing = _parseFamilyComplimentary(data);
        // Una concesión ya creada nunca se revoca desde el cliente. La
        // elegibilidad solo decide si se puede crear una concesión nueva.
        if (existing != null) return existing;

        if (!eligible) return null;

        final now = DateTime.now();
        final grant = ComplimentaryPremium(
          grantedAtMs: now.millisecondsSinceEpoch,
          expiresAtMs: now
              .add(ComplimentaryPremiumConfig.duration)
              .millisecondsSinceEpoch,
          grantedByUid: uid,
        );
        tx.set(docRef, {
          'complimentary_premium': grant.toMap(),
        }, SetOptions(merge: true));
        return grant;
      });
    } catch (e) {
      debugPrint('ComplimentaryPremiumService.ensureFamilyGrant error: $e');
      return null;
    }
  }

  static Future<bool> hasSeenLaunchNotice() async {
    if (!FirebaseService.isAvailable) return true;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return true;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final settings = doc.data()?['user_settings'] as Map<String, dynamic>?;
    return settings?[ComplimentaryPremiumConfig.launchNoticePrefKey] == true;
  }

  static Future<void> markLaunchNoticeShown() async {
    if (!FirebaseService.isAvailable) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'user_settings': {ComplimentaryPremiumConfig.launchNoticePrefKey: true},
    }, SetOptions(merge: true));
  }
}
