import '../utils/baby_age_calendar.dart';
import 'baby_sex.dart';

/// Modelo de datos puro - sin dependencias de Isar
class BabyProfile {
  /// Límite pensado para home (fila sin Flexible), títulos de onboarding
  /// («¿{name} es un chico…?»), notificaciones y líneas de percentil.
  /// Cubre nombres compuestos típicos (p. ej. «María de los Ángeles»).
  static const int maxNameLength = 20;

  final int? id;
  final String name;

  /// `true` niño, `false` niña, `null` prefiero no decirlo (OMS mixtas + UI azul).
  final bool? isMale;

  final DateTime birthDate;
  final DateTime? createdAt;
  /// Foto en base64 (data:image/jpeg;base64,...) o URL de Firebase Storage
  final String? photoUrl;
  /// Altura actual en centímetros (opcional).
  final double? heightCm;
  /// Minutos entre tomas sugeridas (inicio y notificación). Por defecto 180 (3 h).
  final int expectedFeedingIntervalMinutes;

  BabyProfile({
    this.id,
    required this.name,
    required this.isMale,
    required this.birthDate,
    this.createdAt,
    this.photoUrl,
    this.heightCm,
    this.expectedFeedingIntervalMinutes = 180,
  });

  BabySex get sex => BabySex.fromIsMaleFlag(isMale);

  /// Recorta espacios, pone la primera letra en mayúscula y aplica [maxNameLength].
  static String sanitizeName(String raw) {
    var trimmed = raw.trim();
    if (trimmed.isNotEmpty) {
      final first = trimmed[0].toUpperCase();
      if (first != trimmed[0]) {
        trimmed = '$first${trimmed.substring(1)}';
      }
    }
    if (trimmed.length <= maxNameLength) return trimmed;
    return trimmed.substring(0, maxNameLength).trimRight();
  }

  BabyProfile copyWith({
    int? id,
    String? name,
    bool? isMale,
    bool clearIsMale = false,
    DateTime? birthDate,
    DateTime? createdAt,
    String? photoUrl,
    double? heightCm,
    int? expectedFeedingIntervalMinutes,
    /// Si es true, se asigna [photoUrl] tal cual (puede ser null para borrar la foto).
    bool setPhotoUrl = false,
    /// Si es true, se asigna [heightCm] tal cual (puede ser null para borrar).
    bool setHeightCm = false,
  }) =>
      BabyProfile(
        id: id ?? this.id,
        name: name != null ? sanitizeName(name) : this.name,
        isMale: clearIsMale ? null : (isMale ?? this.isMale),
        birthDate: birthDate ?? this.birthDate,
        createdAt: createdAt ?? this.createdAt,
        photoUrl: setPhotoUrl ? photoUrl : (photoUrl ?? this.photoUrl),
        heightCm: setHeightCm ? heightCm : (heightCm ?? this.heightCm),
        expectedFeedingIntervalMinutes:
            expectedFeedingIntervalMinutes ?? this.expectedFeedingIntervalMinutes,
      );

  /// Edad en meses decimales (calendario) desde el nacimiento hasta hoy.
  double get ageInMonths =>
      BabyAgeCalendar.fractionalMonthsAt(birthDate, DateTime.now());
}
