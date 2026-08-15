import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/revenuecat_config.dart';

/// Resultado de un intento de compra desde el paywall propio.
enum PurchaseOutcome { success, cancelled, error }

/// Precio de un plan, para mostrar fuera del paywall.
///
/// [storeFormatted] es el `priceString` de StoreKit / Play Billing (divisa y
/// formato del mercado del usuario). Si está presente, la UI debe preferirlo
/// frente a reformatear [amount] a mano.
class MonthlyPriceQuote {
  final double amount;
  final String currencyCode;
  final String? storeFormatted;

  const MonthlyPriceQuote({
    required this.amount,
    required this.currencyCode,
    this.storeFormatted,
  });
}

/// Envuelve el SDK de RevenueCat: inicialización, login/logout con el uid de
/// Firebase, escucha de cambios de suscripción y presentación del paywall.
///
/// El estado premium se expone como stream de [CustomerInfo] para que Riverpod
/// reaccione en vivo. La combinación con el premium a nivel familia se hace en
/// los providers ([isPremiumProvider]).
class PurchasesService {
  PurchasesService._();

  static bool _initialized = false;

  /// true cuando el SDK se configuró correctamente (claves reales presentes).
  static bool get isReady => _initialized && RevenueCatConfig.isConfigured;

  static final StreamController<CustomerInfo> _customerInfoController =
      StreamController<CustomerInfo>.broadcast();

  /// Emite cada vez que RevenueCat actualiza la información del cliente.
  static Stream<CustomerInfo> get customerInfoStream =>
      _customerInfoController.stream;

  /// Configura el SDK. Debe llamarse una vez al arrancar, tras Firebase.
  /// Si las claves no están configuradas, no hace nada (la app funciona sin
  /// bloqueos en desarrollo).
  static Future<void> init() async {
    if (_initialized) return;
    final apiKey = RevenueCatConfig.apiKeyForCurrentPlatform;
    if (apiKey == null) return;

    try {
      await Purchases.setLogLevel(
        kDebugMode ? LogLevel.debug : LogLevel.warn,
      );
      await Purchases.configure(PurchasesConfiguration(apiKey));
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);
      _initialized = true;
    } catch (e) {
      debugPrint('PurchasesService.init error: $e');
    }
  }

  static void _onCustomerInfoUpdated(CustomerInfo info) {
    if (!_customerInfoController.isClosed) {
      _customerInfoController.add(info);
    }
  }

  /// Asocia las compras al usuario de Firebase. Llamar tras iniciar sesión.
  static Future<void> logIn(String uid) async {
    if (!isReady) return;
    try {
      final result = await Purchases.logIn(uid);
      _onCustomerInfoUpdated(result.customerInfo);
    } catch (e) {
      debugPrint('PurchasesService.logIn error: $e');
    }
  }

  /// Desvincula el usuario. Llamar al cerrar sesión.
  static Future<void> logOut() async {
    if (!isReady) return;
    try {
      final info = await Purchases.logOut();
      _onCustomerInfoUpdated(info);
    } catch (e) {
      // logOut lanza si el usuario ya es anónimo; se ignora.
      debugPrint('PurchasesService.logOut error: $e');
    }
  }

  /// Lee la información actual del cliente (sin esperar a un evento).
  static Future<CustomerInfo?> getCustomerInfo() async {
    if (!isReady) return null;
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      debugPrint('PurchasesService.getCustomerInfo error: $e');
      return null;
    }
  }

  /// true si el [CustomerInfo] tiene el entitlement premium activo.
  static bool isPremiumActive(CustomerInfo? info) {
    if (info == null) return false;
    return info.entitlements.active.containsKey(RevenueCatConfig.entitlementId);
  }

  /// Fecha de expiración (ms epoch) del entitlement premium, o null si es
  /// vitalicio / no aplica.
  static int? premiumExpiryMs(CustomerInfo? info) {
    if (info == null) return null;
    final ent = info.entitlements.active[RevenueCatConfig.entitlementId];
    final iso = ent?.expirationDate;
    if (iso == null) return null;
    return DateTime.tryParse(iso)?.millisecondsSinceEpoch;
  }

  /// Product id del entitlement premium activo, si lo hay.
  static String? premiumProductId(CustomerInfo? info) {
    if (info == null) return null;
    return info.entitlements.active[RevenueCatConfig.entitlementId]
        ?.productIdentifier;
  }

  /// Entitlement premium activo, si lo hay.
  static EntitlementInfo? premiumEntitlement(CustomerInfo? info) {
    if (info == null) return null;
    return info.entitlements.active[RevenueCatConfig.entitlementId];
  }

  /// true si la suscripción propia se renovará al final del periodo.
  static bool premiumWillRenew(CustomerInfo? info) {
    return premiumEntitlement(info)?.willRenew ?? false;
  }

  /// Obtiene la offering actual (o la `default`) con sus packages para el
  /// paywall propio. Null si no hay o falla.
  static Future<Offering?> getCurrentOffering() async {
    if (!isReady) return null;
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current ??
          offerings.all[RevenueCatConfig.offeringId];
    } catch (e) {
      debugPrint('PurchasesService.getCurrentOffering error: $e');
      return null;
    }
  }

  /// Precio del plan anual de la offering actual. Null si no hay o el SDK
  /// no está listo. Incluye [MonthlyPriceQuote.storeFormatted] de la tienda.
  static Future<MonthlyPriceQuote?> getAnnualPrice() async {
    final offering = await getCurrentOffering();
    final packages = offering?.availablePackages ?? const <Package>[];
    for (final package in packages) {
      if (package.packageType != PackageType.annual) continue;
      final product = package.storeProduct;
      if (product.price <= 0) continue;
      return MonthlyPriceQuote(
        amount: product.price,
        currencyCode: product.currencyCode,
        storeFormatted: product.priceString,
      );
    }
    return null;
  }

  /// Coste mensual equivalente más bajo de la offering actual (el anual se
  /// divide entre 12, el semanal se multiplica por 4,35...). Null si no hay
  /// planes o el SDK no está listo.
  static Future<MonthlyPriceQuote?> getLowestMonthlyPrice() async {
    final offering = await getCurrentOffering();
    final packages = offering?.availablePackages ?? const <Package>[];
    MonthlyPriceQuote? lowest;
    for (final package in packages) {
      final product = package.storeProduct;
      if (product.price <= 0) continue;
      final months = _monthsPerPeriod(package.packageType);
      if (months == null) continue;
      final monthly = product.price / months;
      if (lowest == null || monthly < lowest.amount) {
        lowest = MonthlyPriceQuote(
          amount: monthly,
          currencyCode: product.currencyCode,
        );
      }
    }
    return lowest;
  }

  /// Meses que cubre un periodo de suscripción; null para tipos sin duración
  /// conocida (consumibles, lifetime, custom...).
  static double? _monthsPerPeriod(PackageType type) {
    switch (type) {
      case PackageType.annual:
        return 12;
      case PackageType.sixMonth:
        return 6;
      case PackageType.threeMonth:
        return 3;
      case PackageType.twoMonth:
        return 2;
      case PackageType.monthly:
        return 1;
      case PackageType.weekly:
        return 1 / 4.345;
      default:
        return null;
    }
  }

  /// Compra un package concreto. Distingue compra correcta, cancelación del
  /// usuario y error real.
  static Future<PurchaseOutcome> purchasePackage(Package package) async {
    if (!isReady) return PurchaseOutcome.error;
    try {
      final result = await Purchases.purchase(
        PurchaseParams.package(package),
      );
      _onCustomerInfoUpdated(result.customerInfo);
      return isPremiumActive(result.customerInfo)
          ? PurchaseOutcome.success
          : PurchaseOutcome.error;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseOutcome.cancelled;
      }
      debugPrint('PurchasesService.purchasePackage error: $e');
      return PurchaseOutcome.error;
    } catch (e) {
      debugPrint('PurchasesService.purchasePackage error: $e');
      return PurchaseOutcome.error;
    }
  }

  /// Abre la pantalla NATIVA de gestión de suscripciones de la tienda
  /// (App Store en iOS, Play Store en Android).
  ///
  /// La versión instalada de `purchases_flutter` (10.4.0) no expone
  /// `Purchases.showManageSubscriptions()`; el SDK provee la ruta oficial a
  /// través de [CustomerInfo.managementURL], que apunta a la pantalla nativa
  /// de la tienda correspondiente. Si no hay suscripción activa, es null.
  static Future<void> manageSubscriptions() async {
    if (!isReady) return;
    try {
      final info = await Purchases.getCustomerInfo();
      final url = info.managementURL;
      if (url == null) return;
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('PurchasesService.manageSubscriptions error: $e');
    }
  }

  /// Restaura compras anteriores (botón "Restaurar compras").
  static Future<CustomerInfo?> restorePurchases() async {
    if (!isReady) return null;
    try {
      final info = await Purchases.restorePurchases();
      _onCustomerInfoUpdated(info);
      return info;
    } catch (e) {
      debugPrint('PurchasesService.restorePurchases error: $e');
      return null;
    }
  }
}
