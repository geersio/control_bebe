import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Configuración de RevenueCat (suscripciones premium).
///
/// **Pasos para obtener las claves (dashboard de RevenueCat):**
/// 1. https://app.revenuecat.com > crea el proyecto y añade las apps iOS y Android.
/// 2. Project settings > API keys > copia las **Public SDK Keys**:
///    - iOS empieza por `appl_...`
///    - Android empieza por `goog_...`
/// 3. Crea un **Entitlement** con identificador `premium`.
/// 4. Crea los **Products** (importados de App Store Connect / Google Play):
///    - Suscripción mensual (2,99 €/mes) SIN prueba gratis.
///    - Suscripción anual (19,99 €/año) con prueba gratis de 7 días.
/// 5. Crea una **Offering** `default` con dos packages (mensual y anual) y
///    asígnalos al entitlement `premium`.
/// 6. Diseña el **Paywall** en RevenueCat (Paywalls) sobre la offering `default`.
///
/// Rellena la clave de la plataforma que vayas a publicar. La comprobación es
/// **por plataforma**: basta con tener la clave de iOS para que RevenueCat se
/// active en iOS, aunque la de Android siga siendo un placeholder (y viceversa).
/// Si la plataforma actual no tiene su clave, la app funciona sin bloqueos.
class RevenueCatConfig {
  /// Public SDK Key de iOS (empieza por `appl_`).
  static const String appleApiKey = 'appl_MABtPCCkPTJCvVnzWNXWDQvJLYc';

  /// Public SDK Key de Android (empieza por `goog_`).
  static const String googleApiKey = 'goog_REEMPLAZAR';

  /// Identificador del entitlement que concede acceso premium.
  static const String entitlementId = 'premium';

  /// Identificador de la offering usada por el paywall.
  static const String offeringId = 'default';

  /// URLs legales que Apple exige mostrar en el paywall.
  static const String termsUrl =
      'https://sergiosdiaz.github.io/mibebe-privacy/terms.html';
  static const String privacyUrl =
      'https://sergiosdiaz.github.io/mibebe-privacy/privacy.html';

  static bool _isReal(String key) =>
      key.isNotEmpty && !key.contains('REEMPLAZAR');

  /// Public SDK Key de la plataforma actual, o null si no está configurada
  /// (o la plataforma no soporta compras: web/desktop).
  static String? get apiKeyForCurrentPlatform {
    if (kIsWeb) return null;
    if (Platform.isIOS || Platform.isMacOS) {
      return _isReal(appleApiKey) ? appleApiKey : null;
    }
    if (Platform.isAndroid) {
      return _isReal(googleApiKey) ? googleApiKey : null;
    }
    return null;
  }

  /// true si la plataforma actual tiene su Public SDK Key configurada.
  static bool get isConfigured => apiKeyForCurrentPlatform != null;
}
