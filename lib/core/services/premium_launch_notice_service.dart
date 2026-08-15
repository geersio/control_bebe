import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_date_locale.dart';
import '../../l10n/app_localizations.dart';
import '../models/complimentary_premium.dart';
import '../services/complimentary_premium_service.dart';
import '../services/purchases_service.dart';
import '../theme/app_theme.dart';

/// Aviso one-shot del regalo Premium familiar al lanzar la nueva versión.
class PremiumLaunchNoticeService {
  PremiumLaunchNoticeService._();

  static Future<void> tryShow(
    BuildContext context, {
    required ComplimentaryPremium? familyGrant,
  }) async {
    if (!context.mounted || !PurchasesService.isReady) return;
    if (await ComplimentaryPremiumService.hasSeenLaunchNotice()) return;

    final complimentary = familyGrant;
    final giftActive = complimentary?.isActive ?? false;
    if (!giftActive || complimentary == null) return;

    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final dateLang = dateFormatLanguageCode(context);
    final dateLabel = DateFormat(
      'd MMM yyyy',
      dateLang,
    ).format(complimentary.expiresAt);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final bodyStyle = Theme.of(ctx).textTheme.bodyMedium?.copyWith(
          color: AppTheme.textDark,
          height: 1.35,
        );
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.dialogRadius),
          ),
          title: Text(l10n.premiumLaunchNoticeTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.premiumLaunchNoticeBodyGift(dateLabel),
                  style: bodyStyle,
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.premiumLaunchNoticeBodyEssential,
                  style: bodyStyle?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 18),
                Text(l10n.premiumLaunchNoticeSignOff, style: bodyStyle),
                const SizedBox(height: 4),
                Text(
                  l10n.premiumLaunchNoticeSignatureName,
                  style: GoogleFonts.alexBrush(
                    fontSize: 28,
                    height: 1.1,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.premiumLaunchNoticeDismiss),
            ),
          ],
        );
      },
    );

    await ComplimentaryPremiumService.markLaunchNoticeShown();
  }
}
