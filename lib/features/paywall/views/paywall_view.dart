import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/revenuecat_config.dart';
import '../../../core/providers/premium_provider.dart';
import '../../../core/services/purchases_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_display.dart';
import '../../../l10n/app_localizations.dart';

/// Abre el paywall propio como pantalla modal. Devuelve true si el usuario
/// terminó con premium activo.
///
/// [headline] sustituye el título genérico para enganchar con la función
/// concreta desde la que se abrió (p. ej. «Descubre la hora óptima de dormir
/// de Gonzalo»).
Future<bool> showAppPaywall(BuildContext context, {String? headline}) async {
  if (!PurchasesService.isReady) return false;
  final result = await Navigator.of(context, rootNavigator: true).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => PaywallView(headline: headline),
    ),
  );
  return result ?? false;
}

class PaywallView extends ConsumerStatefulWidget {
  /// Título contextual; si es null se usa el genérico.
  final String? headline;

  const PaywallView({super.key, this.headline});

  @override
  ConsumerState<PaywallView> createState() => _PaywallViewState();
}

class _PaywallViewState extends ConsumerState<PaywallView> {
  Offering? _offering;
  Package? _selected;
  bool _loading = true;
  bool _loadError = false;
  bool _purchasing = false;

  @override
  void initState() {
    super.initState();
    _loadOffering();
  }

  Future<void> _loadOffering() async {
    setState(() {
      _loading = true;
      _loadError = false;
    });
    final offering = await PurchasesService.getCurrentOffering();
    if (!mounted) return;
    final packages = offering?.availablePackages ?? [];
    if (offering == null || packages.isEmpty) {
      setState(() {
        _loading = false;
        _loadError = true;
      });
      return;
    }
    final sorted = _sortPackages(packages);
    setState(() {
      _offering = offering;
      _selected = sorted.first;
      _loading = false;
    });
  }

  /// Anual primero (suele llevar la prueba), luego mensual, luego el resto.
  List<Package> _sortPackages(List<Package> packages) {
    int rank(Package p) {
      switch (p.packageType) {
        case PackageType.annual:
          return 0;
        case PackageType.sixMonth:
          return 1;
        case PackageType.threeMonth:
          return 2;
        case PackageType.twoMonth:
          return 3;
        case PackageType.monthly:
          return 4;
        case PackageType.weekly:
          return 5;
        default:
          return 6;
      }
    }

    final list = [...packages]..sort((a, b) => rank(a).compareTo(rank(b)));
    return list;
  }

  bool _hasTrial(Package p) => p.storeProduct.introductoryPrice != null;

  String _periodLabel(BuildContext context, Package p) {
    final l10n = AppLocalizations.of(context)!;
    switch (p.packageType) {
      case PackageType.annual:
        return l10n.paywallPerYear;
      case PackageType.monthly:
        return l10n.paywallPerMonth;
      case PackageType.weekly:
        return l10n.paywallPerWeek;
      default:
        return '';
    }
  }

  String _planTitle(BuildContext context, Package p) {
    final l10n = AppLocalizations.of(context)!;
    switch (p.packageType) {
      case PackageType.annual:
        return l10n.paywallPlanAnnual;
      case PackageType.monthly:
        return l10n.paywallPlanMonthly;
      default:
        return l10n.paywallPlanGeneric;
    }
  }

  String? _monthlyEquivalentLabel(
    BuildContext context,
    Package p,
    AppLocalizations l10n,
  ) {
    if (p.packageType != PackageType.annual) return null;
    final product = p.storeProduct;
    if (product.price <= 0) return null;
    final monthly = product.price / 12;
    final formatted = formatCurrencyAmount(
      amount: monthly,
      currencyCode: product.currencyCode,
      localeName: l10n.localeName,
    );
    return l10n.paywallAnnualMonthlyEquivalent(formatted);
  }

  Future<void> _purchase() async {
    final package = _selected;
    if (package == null || _purchasing) return;
    setState(() => _purchasing = true);
    final outcome = await PurchasesService.purchasePackage(package);
    if (!mounted) return;
    setState(() => _purchasing = false);
    switch (outcome) {
      case PurchaseOutcome.success:
        ref.invalidate(customerInfoProvider);
        Navigator.of(context).pop(true);
        break;
      case PurchaseOutcome.cancelled:
        break;
      case PurchaseOutcome.error:
        _showSnack(AppLocalizations.of(context)!.paywallPurchaseError);
        break;
    }
  }

  Future<void> _restore() async {
    if (_purchasing) return;
    setState(() => _purchasing = true);
    final info = await PurchasesService.restorePurchases();
    if (!mounted) return;
    setState(() => _purchasing = false);
    final l10n = AppLocalizations.of(context)!;
    if (PurchasesService.isPremiumActive(info)) {
      ref.invalidate(customerInfoProvider);
      Navigator.of(context).pop(true);
    } else {
      _showSnack(l10n.restorePurchasesEmpty);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.background,
      // bottom: false → el footer pinta hasta el borde y usa el hueco del home indicator.
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_loadError)
              _buildErrorState(l10n)
            else
              _buildContent(l10n),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                tooltip: l10n.paywallClose,
                icon: const Icon(Icons.close_rounded, color: AppTheme.textLight),
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          32,
          32,
          32,
          32 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 48, color: AppTheme.textLight),
            const SizedBox(height: 16),
            Text(
              l10n.paywallLoadError,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textDark,
                  ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: _loadOffering,
              child: Text(l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }

  /// Densidad según el alto disponible del contenido (no el alto del device),
  /// para que header + features + planes quepan en vertical sin quedar cortados.
  _PaywallDensity _densityFor(double availableHeight, int planCount) {
    // Estimación del contenido a densidad 1.0 (incluye 2 planes típicos).
    final ideal = 520.0 + (planCount.clamp(1, 3) - 1) * 72.0;
    // >1.0 si sobra altura: crece un poco corona/gaps; el resto lo reparte
    // spaceBetween entre bloques.
    final d = (availableHeight / ideal).clamp(0.72, 1.18);
    return _PaywallDensity(d);
  }

  Widget _buildContent(AppLocalizations l10n) {
    final packages = _sortPackages(_offering!.availablePackages);
    final selected = _selected;
    final ctaLabel = (selected != null && _hasTrial(selected))
        ? l10n.paywallCtaTrial
        : l10n.paywallCtaSubscribe;

    return LayoutBuilder(
      builder: (context, outerConstraints) {
        // Reserva aprox. del footer para calcular densidad del bloque scroll.
        final bottomInset = MediaQuery.paddingOf(context).bottom;
        final footerReserve = 148.0 + (bottomInset > 0 ? bottomInset - 10 : 4);
        final contentAvail =
            (outerConstraints.maxHeight - footerReserve).clamp(280.0, 2000.0);
        final density = _densityFor(contentAvail, packages.length);

        return Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final topPad = density.topPad;
                  const bottomPad = 8.0;
                  final minBodyHeight =
                      (constraints.maxHeight - topPad - bottomPad)
                          .clamp(0.0, double.infinity);
                  final planCards = <Widget>[
                    for (var i = 0; i < packages.length; i++)
                      Padding(
                        padding: EdgeInsets.only(
                          top: packages[i].packageType == PackageType.annual
                              ? density.planTopExtra
                              : 0,
                          bottom: i == packages.length - 1
                              ? 0
                              : density.planGap,
                        ),
                        child: _PlanCard(
                          title: _planTitle(context, packages[i]),
                          // Importe + divisa de la tienda, formato del idioma
                          // de la app (el priceString de StoreKit puede venir
                          // en el locale de la cuenta, no el de la UI).
                          priceString: formatCurrencyAmount(
                            amount: packages[i].storeProduct.price,
                            currencyCode:
                                packages[i].storeProduct.currencyCode,
                            localeName: l10n.localeName,
                          ),
                          period: _periodLabel(context, packages[i]),
                          trialLabel: _hasTrial(packages[i])
                              ? l10n.paywallTrialBadge
                              : null,
                          monthlyEquivalentLabel: _monthlyEquivalentLabel(
                            context,
                            packages[i],
                            l10n,
                          ),
                          recommendedLabel:
                              packages[i].packageType == PackageType.annual
                              ? l10n.paywallBadgeRecommended
                              : null,
                          selected: identical(packages[i], selected) ||
                              packages[i].identifier == selected?.identifier,
                          density: density,
                          onTap: () => setState(() => _selected = packages[i]),
                        ),
                      ),
                  ];
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(24, topPad, 24, bottomPad),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: minBodyHeight),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(l10n, density: density),
                          _buildFeatures(l10n, density: density),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: planCards,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            _buildFooter(l10n, ctaLabel, density: density),
          ],
        );
      },
    );
  }

  Widget _buildHeader(
    AppLocalizations l10n, {
    required _PaywallDensity density,
  }) {
    const crownGold = Color(0xFFFFB300);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: density.crownSize,
          height: density.crownSize,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFFDE7),
                Color(0xFFFFF9C4),
                Color(0xFFFFECB3),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: crownGold.withValues(alpha: 0.35),
                blurRadius: density.lerp(12, 18),
                offset: Offset(0, density.lerp(4, 6)),
              ),
            ],
          ),
          child: Center(
            child: FaIcon(
              FontAwesomeIcons.crown,
              color: crownGold,
              size: density.crownIconSize,
            ),
          ),
        ),
        SizedBox(height: density.lerp(6, 12)),
        Text(
          widget.headline ?? l10n.paywallTitle,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.textHeading,
                fontSize: widget.headline == null
                    ? density.lerp(21, 24)
                    : density.lerp(19, 22),
              ),
        ),
        SizedBox(height: density.lerp(3, 8)),
        Text(
          l10n.paywallSubtitle,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textDark,
                fontSize: density.lerp(12.5, 14),
                height: 1.25,
              ),
        ),
      ],
    );
  }

  Widget _buildFeatures(
    AppLocalizations l10n, {
    required _PaywallDensity density,
  }) {
    final features = [
      l10n.paywallFeatureInsights,
      l10n.paywallFeatureFeedingTrack,
      l10n.paywallFeatureSleepTrack,
      l10n.paywallFeatureFamily,
      l10n.paywallFeaturePdf,
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: features
          .map((f) => Padding(
                padding: EdgeInsets.symmetric(vertical: density.featureVPad),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.palettePrimary,
                      size: density.lerp(17, 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        f,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.w500,
                              fontSize: density.lerp(13.5, 16),
                              height: 1.2,
                            ),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildFooter(
    AppLocalizations l10n,
    String ctaLabel, {
    required _PaywallDensity density,
  }) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    // Solo un pequeño margen sobre el home indicator (sin sumar padding extra).
    final bottomPad = bottomInset > 0
        ? (bottomInset - 10).clamp(4.0, bottomInset)
        : 4.0;
    final linkStyle = TextButton.styleFrom(
      visualDensity: VisualDensity.compact,
      minimumSize: Size.zero,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    return Container(
      padding: EdgeInsets.fromLTRB(24, density.lerp(5, 10), 24, bottomPad),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _purchasing ? null : _purchase,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.palettePrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: density.lerp(12, 16)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _purchasing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      ctaLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 2),
          TextButton(
            onPressed: _purchasing ? null : _restore,
            style: linkStyle.copyWith(
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              ),
            ),
            child: Text(
              l10n.paywallRestore,
              style: const TextStyle(color: AppTheme.textLight, fontSize: 13),
            ),
          ),
          Text(
            l10n.paywallLegal,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.textLight,
                  height: 1.2,
                  fontSize: 10,
                ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => _openUrl(RevenueCatConfig.termsUrl),
                style: linkStyle,
                child: Text(
                  l10n.paywallTerms,
                  style: const TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const Text('·', style: TextStyle(color: AppTheme.textLight)),
              TextButton(
                onPressed: () => _openUrl(RevenueCatConfig.privacyUrl),
                style: linkStyle,
                child: Text(
                  l10n.paywallPrivacy,
                  style: const TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Escala de espaciado/tipografía del paywall (1.0 = cómodo, ~0.72 = denso).
class _PaywallDensity {
  final double value;

  const _PaywallDensity(this.value);

  double lerp(double min, double max) => min + (max - min) * value;

  double get topPad => lerp(8, 20);
  double get sectionGap => lerp(8, 18);
  double get planGap => lerp(6, 10);
  double get planTopExtra => lerp(4, 10);
  double get featureVPad => lerp(1.5, 4.5);
  double get crownSize => lerp(48, 68);
  double get crownIconSize => lerp(22, 32);
  double get planVPad => lerp(8, 14);
  double get planRecommendedTopPad => lerp(12, 18);
  double get planTitleSize => lerp(14.5, 16);
  double get planMetaSize => lerp(10.5, 12);
  double get radioSize => lerp(20, 24);
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String priceString;
  final String period;
  final String? trialLabel;
  final String? monthlyEquivalentLabel;
  final String? recommendedLabel;
  final bool selected;
  final _PaywallDensity density;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.priceString,
    required this.period,
    required this.trialLabel,
    required this.monthlyEquivalentLabel,
    required this.recommendedLabel,
    required this.selected,
    required this.density,
    required this.onTap,
  });

  bool get _isRecommended => recommendedLabel != null;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppTheme.palettePrimary
        : _isRecommended
            ? AppTheme.palettePrimary.withValues(alpha: 0.45)
            : AppTheme.fieldBackground;
    final borderWidth = selected || _isRecommended ? 2.0 : 1.5;
    final vPad = density.planVPad;
    final recommendedTopPad = density.planRecommendedTopPad;
    final metaGap = density.lerp(2, 4);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.fromLTRB(
              16,
              _isRecommended ? recommendedTopPad : vPad,
              16,
              vPad,
            ),
            decoration: BoxDecoration(
              color: _isRecommended
                  ? AppTheme.softPrimaryFill.withValues(alpha: 0.35)
                  : AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color:
                        selected ? AppTheme.palettePrimary : AppTheme.textLight,
                    size: density.radioSize,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textDark,
                                  fontSize: density.planTitleSize,
                                ),
                      ),
                      if (monthlyEquivalentLabel != null) ...[
                        SizedBox(height: metaGap),
                        Text(
                          monthlyEquivalentLabel!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.palettePrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: density.planMetaSize,
                                  ),
                        ),
                      ],
                      if (trialLabel != null) ...[
                        SizedBox(height: metaGap),
                        Text(
                          trialLabel!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.primaryGreen,
                                    fontWeight: FontWeight.w700,
                                    fontSize: density.planMetaSize,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      priceString,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textHeading,
                            fontSize: density.planTitleSize,
                          ),
                    ),
                    if (period.isNotEmpty)
                      Text(
                        period,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textLight,
                              fontSize: density.planMetaSize,
                            ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (recommendedLabel != null)
            Positioned(
              top: -11,
              left: 16,
              child: _Badge(
                text: recommendedLabel!,
                background: AppTheme.palettePrimary,
                foreground: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;

  const _Badge({
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
