import '../../../core/models/baby_sex.dart';

/// Borrador local del onboarding previo al login / guardado en Firestore.
class OnboardingDraft {
  /// 0 nascido/embarazo … 7 cuenta (o -1 = no iniciado en UI).
  final int step;

  /// true = ya ha nacido, false = embarazada, null = sin elegir.
  final bool? hasBorn;

  final String name;

  /// null = aún no elegido; [BabySex.unspecified] = prefiero no decirlo.
  final BabySex? sex;

  final DateTime birthDate;
  final double? weightKg;
  final double? heightCm;

  /// Preferencia de notificaciones elegida en el paso 7.
  final bool? wantNotifications;

  /// Tras login desde el paso de cuenta: AppInitializer debe persistir y mostrar paywall.
  final bool pendingCommit;

  OnboardingDraft({
    this.step = 0,
    this.hasBorn,
    this.name = '',
    this.sex,
    DateTime? birthDate,
    this.weightKg,
    this.heightCm,
    this.wantNotifications,
    this.pendingCommit = false,
  }) : birthDate = birthDate ?? defaultBirthDate;

  /// Fecha por defecto: hoy.
  static DateTime get defaultBirthDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  factory OnboardingDraft.initial() => OnboardingDraft();

  factory OnboardingDraft.fromJson(Map<String, dynamic> json) {
    final sexName = json['sex'] as String?;
    BabySex? sex;
    if (sexName != null) {
      for (final value in BabySex.values) {
        if (value.name == sexName) {
          sex = value;
          break;
        }
      }
    }
    final birthDateMs = (json['birthDateMs'] as num?)?.toInt();
    return OnboardingDraft(
      step: (json['step'] as num?)?.toInt() ?? 0,
      hasBorn: json['hasBorn'] as bool?,
      name: json['name'] as String? ?? '',
      sex: sex,
      birthDate: birthDateMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(birthDateMs),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      wantNotifications: json['wantNotifications'] as bool?,
      pendingCommit: json['pendingCommit'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'step': step,
    'hasBorn': hasBorn,
    'name': name,
    'sex': sex?.name,
    'birthDateMs': birthDate.millisecondsSinceEpoch,
    'weightKg': weightKg,
    'heightCm': heightCm,
    'wantNotifications': wantNotifications,
    'pendingCommit': pendingCommit,
  };

  String get displayName {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '' : trimmed;
  }

  bool get hasName => displayName.isNotEmpty;

  bool get canContinueStep0 => hasBorn != null;

  bool get canContinueStep1 => hasName;

  bool get canContinueStepGender => sex != null;

  /// Compat: niño/niña; `null` si unspecified o sin elegir.
  bool? get isMale => sex?.isMaleFlag;

  OnboardingDraft copyWith({
    int? step,
    bool? hasBorn,
    String? name,
    BabySex? sex,
    bool clearSex = false,
    DateTime? birthDate,
    double? weightKg,
    double? heightCm,
    bool? wantNotifications,
    bool? pendingCommit,
    bool clearWeight = false,
    bool clearHeight = false,
    bool clearWantNotifications = false,
  }) {
    return OnboardingDraft(
      step: step ?? this.step,
      hasBorn: hasBorn ?? this.hasBorn,
      name: name ?? this.name,
      sex: clearSex ? null : (sex ?? this.sex),
      birthDate: birthDate ?? this.birthDate,
      weightKg: clearWeight ? null : (weightKg ?? this.weightKg),
      heightCm: clearHeight ? null : (heightCm ?? this.heightCm),
      wantNotifications: clearWantNotifications
          ? null
          : (wantNotifications ?? this.wantNotifications),
      pendingCommit: pendingCommit ?? this.pendingCommit,
    );
  }
}
