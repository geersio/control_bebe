class ComplimentaryPremium {
  final int grantedAtMs;
  final int expiresAtMs;
  final String grantedByUid;

  const ComplimentaryPremium({
    required this.grantedAtMs,
    required this.expiresAtMs,
    required this.grantedByUid,
  });

  bool get isActive {
    return DateTime.now().millisecondsSinceEpoch < expiresAtMs;
  }

  DateTime get expiresAt =>
      DateTime.fromMillisecondsSinceEpoch(expiresAtMs, isUtc: true).toLocal();

  DateTime get grantedAt =>
      DateTime.fromMillisecondsSinceEpoch(grantedAtMs, isUtc: true).toLocal();

  Map<String, dynamic> toMap() => {
        'grantedAtMs': grantedAtMs,
        'expiresAtMs': expiresAtMs,
        'grantedByUid': grantedByUid,
      };

  static ComplimentaryPremium? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final grantedAtMs = (raw['grantedAtMs'] as num?)?.toInt();
    final expiresAtMs = (raw['expiresAtMs'] as num?)?.toInt();
    final grantedByUid = raw['grantedByUid'] as String?;
    if (grantedAtMs == null ||
        expiresAtMs == null ||
        grantedByUid == null ||
        grantedByUid.isEmpty) {
      return null;
    }
    return ComplimentaryPremium(
      grantedAtMs: grantedAtMs,
      expiresAtMs: expiresAtMs,
      grantedByUid: grantedByUid,
    );
  }
}
