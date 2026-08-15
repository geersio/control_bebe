/// Regalo de Premium para usuarios que ya usaban la app antes del lanzamiento
/// de suscripciones.
class ComplimentaryPremiumConfig {
  /// Duración del regalo desde la primera apertura de la nueva versión en la
  /// familia (el primer miembro que abre fija la fecha para todos).
  static const Duration duration = Duration(days: 30);

  /// Perfil creado antes de esta fecha y onboarding completado = familia
  /// existente elegible para el regalo.
  static final DateTime launchCutoff = DateTime.utc(2026, 7, 10);

  /// Clave en [users/{uid}/user_settings] para el aviso one-shot del lanzamiento.
  static const launchNoticePrefKey = 'premiumLaunchNoticeShownV1';

  /// Marca que el usuario ya vio el aviso de expiración para una fecha concreta
  /// (valor = [expiresAtMs] de la pérdida de acceso).
  static const expiryWarningPrefKey = 'premiumExpiryWarningShownFor';

  /// Días de antelación (incluye el día 0) para el aviso de expiración.
  static const expiryWarningWindowDays = 3;
}
