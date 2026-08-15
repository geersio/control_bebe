import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../features/paywall/views/paywall_view.dart';
import '../../l10n/app_localizations.dart';
import '../providers/premium_provider.dart';
import '../services/purchases_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_display.dart';

/// Una función bloqueada del listado premium: qué se ofrece y con qué titular
/// se abre el paywall al pulsarla.
class PremiumFeatureItem {
  final IconData icon;
  final String title;
  final String subtitle;

  /// Título contextual del paywall (p. ej. «Descubre la hora óptima de dormir
  /// de Gonzalo»).
  final String paywallHeadline;

  const PremiumFeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.paywallHeadline,
  });
}

/// Tarjeta única que sustituye a las pastillas bloqueadas cuando el usuario no
/// tiene premium: lista lo que se está perdiendo y abre el paywall con el
/// titular de la función pulsada.
class PremiumFeaturesCard extends ConsumerWidget {
  final List<PremiumFeatureItem> items;

  /// Nombre del bebé para personalizar el subtítulo de la tarjeta.
  final String babyName;

  /// Análisis premium que no caben en las 3 filas («Y X análisis más»).
  final int moreCount;

  const PremiumFeaturesCard({
    super.key,
    required this.items,
    required this.babyName,
    this.moreCount = 0,
  });

  static const _crownGold = Color(0xFFFFB300);

  Future<void> _openPaywall(
    BuildContext context,
    WidgetRef ref, {
    String? headline,
  }) async {
    await showAppPaywall(context, headline: headline);
    ref.invalidate(customerInfoProvider);
  }

  /// Precio formateado según el idioma de la app (no el de la cuenta de la
  /// tienda). Usamos importe + divisa del producto de StoreKit/Play; el
  /// `priceString` de la tienda se ignora aquí porque puede venir en otro
  /// idioma (p. ej. «19,99 €» con la app en inglés → «€19.99»).
  String? _priceLabel(BuildContext context, MonthlyPriceQuote? quote) {
    if (quote == null) return null;
    final l10n = AppLocalizations.of(context)!;
    return formatCurrencyAmount(
      amount: quote.amount,
      currencyCode: quote.currencyCode,
      localeName: l10n.localeName,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final annualPrice = _priceLabel(
      context,
      ref.watch(annualPriceProvider).valueOrNull,
    );
    final footer = annualPrice == null
        ? l10n.premiumTeaserCancelAnytime
        : l10n.premiumTeaserAfterPrice(annualPrice);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.homeCardRadius),
        border: Border.all(color: AppTheme.cardOutline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: _Header(
              title: l10n.premiumTeaserTitle,
              subtitle: l10n.premiumTeaserSubtitle(babyName),
            ),
          ),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const _RowDivider(),
            _FeatureRow(
              item: items[i],
              onTap: () => _openPaywall(
                context,
                ref,
                headline: items[i].paywallHeadline,
              ),
            ),
          ],
          if (moreCount > 0) ...[
            const _RowDivider(),
            InkWell(
              onTap: () => _openPaywall(context, ref),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  l10n.premiumTeaserMoreAnalyses(moreCount),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.w500,
                        fontSize: 13.5,
                      ),
                ),
              ),
            ),
          ],
          const _RowDivider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _openPaywall(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.palettePrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      l10n.premiumTeaserCta,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  footer,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.textLight,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;

  const _Header({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
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
            border: Border.all(
              color: PremiumFeaturesCard._crownGold.withValues(alpha: 0.5),
            ),
          ),
          child: const Center(
            child: FaIcon(
              FontAwesomeIcons.crown,
              color: PremiumFeaturesCard._crownGold,
              size: 15,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.textDark,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textLight,
                      fontSize: 12,
                      height: 1.25,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final PremiumFeatureItem item;
  final VoidCallback onTap;

  const _FeatureRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(item.icon, size: 21, color: AppTheme.palettePrimary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5,
                          height: 1.2,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textLight,
                          fontSize: 11.5,
                          height: 1.25,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: AppTheme.textLight.withValues(alpha: 0.55),
            ),
          ],
        ),
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: AppTheme.fieldBorder);
  }
}
