class FamilyPaidPremium {
  final bool active;
  final int? expiresAtMs;
  final bool willRenew;
  final String? ownerUid;

  const FamilyPaidPremium({
    required this.active,
    this.expiresAtMs,
    required this.willRenew,
    this.ownerUid,
  });

  static FamilyPaidPremium? fromMap(Object? raw) {
    if (raw is! Map) return null;
    if (raw['active'] != true) return null;
    return FamilyPaidPremium(
      active: true,
      expiresAtMs: (raw['expiresAtMs'] as num?)?.toInt(),
      // Sin dato = asumir renovación activa (evita falsas alarmas en familias antiguas).
      willRenew: raw['willRenew'] as bool? ?? true,
      ownerUid: raw['ownerUid'] as String?,
    );
  }
}
