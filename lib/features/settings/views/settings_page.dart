import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:control_bebe/l10n/app_date_locale.dart';
import 'package:control_bebe/l10n/app_localizations.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/auth/unauth_entry.dart';
import '../../../core/db/isar_service.dart';
import '../../../core/models/baby_profile.dart';
import '../../../core/models/measurement_units.dart';
import '../../../core/providers/baby_profile_provider.dart';
import '../../../core/providers/measurement_prefs_provider.dart';
import '../../../core/providers/notification_prefs_provider.dart';
import '../../../core/providers/premium_provider.dart';
import '../../../core/services/next_feeding_notification_service.dart';
import '../../../core/services/purchases_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/feeding_interval_labels.dart';
import '../../../core/utils/diaper_cost_localization.dart';
import '../../../core/utils/measurement_display.dart';
import '../../../core/widgets/edit_dialog_fields.dart';
import '../../export/models/pediatric_report_data.dart';
import '../../export/services/pediatric_report_service.dart';
import '../../paywall/views/paywall_view.dart';

class SettingsPage extends ConsumerStatefulWidget {
  final BabyProfile? initialBaby;
  final void Function(BabyProfile profile)? onProfileSaved;

  const SettingsPage({super.key, this.initialBaby, this.onProfileSaved});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  static const _supportEmail = 'sergiodz.r@gmail.com';

  BabyProfile? _baby;
  bool _deletingAccount = false;
  bool _generatingReport = false;

  @override
  void initState() {
    super.initState();
    _baby = widget.initialBaby;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_refreshBabyFromStorage());
    });
  }

  Future<void> _refreshBabyFromStorage() async {
    ref.invalidate(babyProfileProvider);
    final b = await ref.read(babyProfileProvider.future);
    if (!mounted || b == null) return;
    setState(() => _baby = b);
  }

  Future<void> _saveFeedingSchedule({required int intervalMinutes}) async {
    final b = _baby;
    if (b == null) return;
    final clamped = intervalMinutes.clamp(30, 720);
    final updated = b.copyWith(expectedFeedingIntervalMinutes: clamped);
    await IsarService.saveBabyProfile(updated);
    ref.invalidate(babyProfileProvider);
    await NextFeedingNotificationService.syncFromStorage();
    if (mounted) {
      setState(() => _baby = updated);
      widget.onProfileSaved?.call(updated);
    }
  }

  Future<void> _editProfile() async {
    var baby = _baby;
    if (baby == null) {
      baby = await ref.read(babyProfileProvider.future);
      if (mounted && baby != null) setState(() => _baby = baby);
    }
    if (!mounted) return;
    if (baby == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.homeConfigureProfileFirst),
        ),
      );
      return;
    }
    final profile = baby;

    final result = await showModalBottomSheet<BabyProfile?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditProfileSheet(baby: profile),
    );
    if (result != null && mounted) {
      await IsarService.saveBabyProfile(result);
      ref.invalidate(babyProfileProvider);
      setState(() => _baby = result);
      widget.onProfileSaved?.call(result);
    }
  }

  Future<void> _openFeedingIntervalSheet() async {
    final b = _baby;
    if (b == null) return;
    final l10n = AppLocalizations.of(context)!;
    final initialMinutes = b.expectedFeedingIntervalMinutes.clamp(30, 720);
    final selected = await _showFeedingIntervalPicker(
      context,
      initialMinutes: initialMinutes,
      l10n: l10n,
    );
    if (selected == null) return;
    await _saveFeedingSchedule(intervalMinutes: selected);
  }

  Future<void> _openWeightUnitSheet() async {
    final l10n = AppLocalizations.of(context)!;
    final prefs = await ref.read(measurementPrefsProvider.future);
    if (!mounted) return;
    final selected = await showModalBottomSheet<WeightUnitMode>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _OptionPickerSheet<WeightUnitMode>(
        title: l10n.settingsSheetUnitWeightTitle,
        intro: l10n.settingsUnitsIntro,
        currentValue: prefs.weight,
        options: [
          for (final mode in WeightUnitMode.values)
            _SheetOption(value: mode, label: weightSegmentLabel(mode, l10n)),
        ],
      ),
    );
    if (selected == null) return;
    await ref.read(measurementPrefsProvider.notifier).setWeight(selected);
  }

  Future<void> _openLiquidUnitSheet() async {
    final l10n = AppLocalizations.of(context)!;
    final prefs = await ref.read(measurementPrefsProvider.future);
    if (!mounted) return;
    final selected = await showModalBottomSheet<LiquidUnitMode>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _OptionPickerSheet<LiquidUnitMode>(
        title: l10n.settingsSheetUnitLiquidTitle,
        intro: l10n.settingsUnitsIntro,
        currentValue: prefs.liquid,
        options: [
          for (final mode in LiquidUnitMode.values)
            _SheetOption(value: mode, label: liquidSegmentLabel(mode, l10n)),
        ],
      ),
    );
    if (selected == null) return;
    await ref.read(measurementPrefsProvider.notifier).setLiquid(selected);
  }

  Future<void> _openCurrencySheet() async {
    final prefs = await ref.read(measurementPrefsProvider.future);
    if (!mounted) return;
    final autoCode = automaticCurrencyCode(moneyLocaleForContext(context));
    // '' = automático (según dispositivo).
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CurrencyPickerSheet(
        currentValue: prefs.currencyCode ?? '',
        automaticCode: autoCode,
      ),
    );
    if (selected == null) return;
    await ref
        .read(measurementPrefsProvider.notifier)
        .setCurrency(selected.isEmpty ? null : selected);
  }

  Future<void> _sharePediatricReport() async {
    if (_generatingReport) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _generatingReport = true);
    try {
      final data = await PediatricReportData.load();
      if (data == null) return;
      final bytes = await PediatricReportService.buildPdf(
        data: data,
        l10n: l10n,
      );
      await Printing.sharePdf(
        bytes: bytes,
        filename: PediatricReportService.suggestedFileName(data, l10n),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.reportShareError)));
      }
    } finally {
      if (mounted) setState(() => _generatingReport = false);
    }
  }

  /// Exportar el informe para el pediatra es premium: si no lo tiene,
  /// abre el paywall en vez de generar el PDF.
  Future<void> _onExportReportTap() async {
    final isPremium = ref.read(isPremiumProvider);
    if (isPremium) {
      await _sharePediatricReport();
      return;
    }
    await showAppPaywall(context);
    ref.invalidate(customerInfoProvider);
  }

  Future<void> _openShareFamilySheet() async {
    final familyId = await IsarService.getFamilyId();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ShareFamilySheet(familyId: familyId),
    );
  }

  /// Compartir por QR es premium: si no lo tiene, abre el paywall.
  Future<void> _onShareFamilyTap() async {
    final isPremium = ref.read(isPremiumProvider);
    if (isPremium) {
      await _openShareFamilySheet();
      return;
    }
    await showAppPaywall(context);
    ref.invalidate(customerInfoProvider);
  }

  Future<void> _openPaywall() async {
    await showAppPaywall(context);
    ref.invalidate(customerInfoProvider);
  }

  Future<void> _manageSubscription() async {
    await PurchasesService.manageSubscriptions();
  }

  Future<void> _restorePurchases() async {
    final l10n = AppLocalizations.of(context)!;
    final ownPremium = ref.read(ownPremiumProvider);
    final familyPaid = ref.read(familyPremiumProvider);
    final familyGift = ref.read(familyComplimentaryPremiumProvider).valueOrNull;
    final giftOnly =
        (familyGift?.isActive ?? false) && !ownPremium && !familyPaid;

    if (giftOnly) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.dialogRadius),
          ),
          title: Text(l10n.restorePurchasesGiftDialogTitle),
          content: Text(l10n.restorePurchasesGiftDialogBody),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.commonDone),
            ),
          ],
        ),
      );
      return;
    }

    final info = await PurchasesService.restorePurchases();
    if (!mounted) return;
    final restored = PurchasesService.isPremiumActive(info);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          restored ? l10n.restorePurchasesSuccess : l10n.restorePurchasesEmpty,
        ),
      ),
    );
    ref.invalidate(customerInfoProvider);
  }

  Future<void> _toggleNotify(bool on) async {
    final previous = ref.read(notifyNextFeedingProvider).valueOrNull ?? false;

    var notify = on;
    if (notify) {
      final ok = await NextFeedingNotificationService.requestPermissions();
      if (!ok && mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.settingsNotifyPermission)));
        return;
      }
    }

    await ref.read(notifyNextFeedingProvider.notifier).set(notify);
    if (notify != previous) {
      unawaited(NextFeedingNotificationService.syncFromStorage());
    }
  }

  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.dialogRadius),
        ),
        title: Text(l10n.deleteAccountTitle),
        content: Text(l10n.deleteAccountBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.deleteAccountConfirm),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _deletingAccount = true);
    try {
      await AuthService.deleteAccount();
      await ref.read(unauthEntryProvider.notifier).markLoginPreferred();
    } on Exception catch (e) {
      if (mounted) {
        setState(() => _deletingAccount = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.deleteAccountError(e))));
      }
      return;
    }
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _signOut() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.dialogRadius),
        ),
        title: Text(l10n.signOutTitle),
        content: Text(l10n.signOutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.signOutConfirm),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await AuthService.signOut();
        await ref.read(unauthEntryProvider.notifier).markLoginPreferred();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.signOutError(e))));
        }
        return;
      }
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  Future<void> _openSupportEmail() async {
    final l10n = AppLocalizations.of(context)!;
    final subject = Uri.encodeComponent(l10n.settingsContactEmailSubject);
    final uri = Uri.parse('mailto:$_supportEmail?subject=$subject');
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched || !mounted) return;
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.settingsContactOpenFail(_supportEmail))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final baby = _baby;
    final prefs = ref.watch(measurementPrefsProvider).valueOrNull;
    final notifyNextFeeding =
        ref.watch(notifyNextFeedingProvider).valueOrNull ?? false;
    final isPremium = ref.watch(isPremiumProvider);
    final ownPremium = ref.watch(ownPremiumProvider);
    final familyPaid = ref.watch(familyPremiumProvider);
    final familyGift = ref
        .watch(familyComplimentaryPremiumProvider)
        .valueOrNull;
    final giftActive = familyGift?.isActive ?? false;
    final showSubscription = PurchasesService.isReady;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppTheme.screenEdgePadding,
          12,
          AppTheme.screenEdgePadding,
          24 + AppTheme.safeBottomPadding(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ========== BEBÉ ==========
            _SettingsGroup(
              title: l10n.settingsGroupBaby,
              rows: [
                _SettingsRow(
                  icon: Icons.person_outline,
                  iconColor: AppTheme.palettePrimary,
                  title: l10n.settingsRowProfileTitle,
                  subtitle: l10n.settingsRowProfileSubtitle,
                  trailing: const _RowChevron(),
                  onTap: _editProfile,
                ),
                _SettingsRow(
                  icon: Icons.picture_as_pdf_outlined,
                  iconColor: AppTheme.palettePrimary,
                  title: l10n.settingsRowPediatricReport,
                  subtitle: l10n.settingsRowPediatricReportSubtitle,
                  trailing: _generatingReport
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : isPremium
                      ? const _RowChevron()
                      : const _PremiumCrownTrailing(),
                  onTap: (baby == null || _generatingReport)
                      ? null
                      : _onExportReportTap,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ========== PREFERENCIAS ==========
            _SettingsGroup(
              title: l10n.settingsGroupPreferences,
              rows: [
                _SettingsRow(
                  icon: Icons.notifications_outlined,
                  iconColor: AppTheme.palettePrimary,
                  title: l10n.settingsRowFeedingNotify,
                  subtitle: l10n.settingsNotifySubtitle,
                  trailing: Switch.adaptive(
                    value: notifyNextFeeding,
                    activeThumbColor: AppTheme.palettePrimary,
                    activeTrackColor: AppTheme.palettePrimary.withValues(
                      alpha: 0.32,
                    ),
                    onChanged: _toggleNotify,
                  ),
                  onTap: () => _toggleNotify(!notifyNextFeeding),
                ),
                _SettingsRow(
                  icon: Icons.schedule_outlined,
                  iconColor: AppTheme.palettePrimary,
                  title: l10n.settingsRowFeedingInterval,
                  trailing: _RowValue(
                    text: baby == null
                        ? l10n.settingsValueNotSet
                        : feedingIntervalOptionLabel(
                            l10n,
                            baby.expectedFeedingIntervalMinutes.clamp(30, 720),
                          ),
                    chevron: baby != null,
                  ),
                  onTap: baby == null ? null : _openFeedingIntervalSheet,
                ),
                _SettingsRow(
                  icon: Icons.monitor_weight_outlined,
                  iconColor: AppTheme.palettePrimary,
                  title: l10n.settingsRowUnitWeight,
                  trailing: _RowValue(
                    text: prefs == null
                        ? l10n.settingsValueNotSet
                        : weightSegmentLabel(prefs.weight, l10n),
                    chevron: true,
                  ),
                  onTap: prefs == null ? null : _openWeightUnitSheet,
                ),
                _SettingsRow(
                  icon: Icons.local_drink_outlined,
                  iconColor: AppTheme.palettePrimary,
                  title: l10n.settingsRowUnitLiquid,
                  trailing: _RowValue(
                    text: prefs == null
                        ? l10n.settingsValueNotSet
                        : liquidSegmentLabel(prefs.liquid, l10n),
                    chevron: true,
                  ),
                  onTap: prefs == null ? null : _openLiquidUnitSheet,
                ),
                _SettingsRow(
                  icon: Icons.payments_outlined,
                  iconColor: AppTheme.palettePrimary,
                  title: l10n.settingsRowCurrency,
                  trailing: _RowValue(
                    text: prefs == null
                        ? l10n.settingsValueNotSet
                        : (prefs.currencyCode == null
                              ? l10n.settingsCurrencyAuto
                              : currencyOptionLabel(prefs.currencyCode!)),
                    chevron: true,
                  ),
                  onTap: prefs == null ? null : _openCurrencySheet,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ========== FAMILIA ==========
            _SettingsGroup(
              title: l10n.settingsGroupFamily,
              rows: [
                _SettingsRow(
                  icon: Icons.qr_code_2_outlined,
                  iconColor: AppTheme.palettePrimary,
                  title: l10n.settingsRowFamilyShare,
                  subtitle: l10n.settingsRowFamilyShareSubtitle,
                  trailing: isPremium
                      ? const _RowChevron()
                      : const _PremiumCrownTrailing(),
                  onTap: _onShareFamilyTap,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ========== SUSCRIPCIÓN ==========
            if (showSubscription) ...[
              _SettingsGroup(
                title: l10n.settingsGroupSubscription,
                rows: [
                  if (isPremium && ownPremium)
                    _SettingsRow(
                      icon: Icons.workspace_premium_rounded,
                      iconColor: AppTheme.palettePrimary,
                      title: l10n.settingsRowSubscriptionActive,
                      subtitle: l10n.settingsRowManageSubscription,
                      trailing: const _RowChevron(),
                      onTap: _manageSubscription,
                    )
                  else if (isPremium && familyPaid)
                    _SettingsRow(
                      icon: Icons.workspace_premium_rounded,
                      iconColor: AppTheme.palettePrimary,
                      title: l10n.settingsRowSubscriptionFamily,
                      trailing: null,
                      onTap: null,
                    )
                  else if (isPremium && giftActive && familyGift != null)
                    _SettingsRow(
                      icon: Icons.card_giftcard_rounded,
                      iconColor: AppTheme.palettePrimary,
                      title: l10n.settingsRowComplimentaryPremium,
                      subtitle: l10n.settingsRowComplimentaryPremiumUntil(
                        DateFormat(
                          'd MMM yyyy',
                          dateFormatLanguageCode(context),
                        ).format(familyGift.expiresAt),
                      ),
                      trailing: const _RowChevron(),
                      onTap: _openPaywall,
                    )
                  else
                    _SettingsRow(
                      icon: Icons.workspace_premium_rounded,
                      iconColor: AppTheme.palettePrimary,
                      title: l10n.settingsRowSubscribe,
                      subtitle: l10n.settingsRowSubscribeSubtitle,
                      trailing: const _RowChevron(),
                      onTap: _openPaywall,
                    ),
                  _SettingsRow(
                    icon: Icons.restore_rounded,
                    iconColor: AppTheme.palettePrimary,
                    title: l10n.settingsRowRestorePurchases,
                    trailing: const _RowChevron(),
                    onTap: _restorePurchases,
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // ========== AYUDA ==========
            _SettingsGroup(
              title: l10n.settingsGroupHelp,
              rows: [
                _SettingsRow(
                  icon: Icons.mail_outline,
                  iconColor: AppTheme.palettePrimary,
                  title: l10n.settingsRowContactTitle,
                  subtitle: l10n.settingsRowContactSubtitle(_supportEmail),
                  trailing: const _RowChevron(),
                  onTap: _openSupportEmail,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ========== CUENTA ==========
            _SettingsGroup(
              title: l10n.settingsGroupAccount,
              rows: [
                _SettingsRow(
                  icon: Icons.logout,
                  iconColor: AppTheme.palettePrimary,
                  title: l10n.settingsSignOutButton,
                  subtitle: l10n.settingsSignOutRowSubtitle,
                  trailing: const _RowChevron(),
                  onTap: _signOut,
                ),
                _SettingsRow(
                  icon: Icons.delete_forever_outlined,
                  iconColor: Theme.of(context).colorScheme.error,
                  title: l10n.settingsDeleteAccount,
                  subtitle: l10n.settingsDeleteAccountRowSubtitle,
                  titleColor: Theme.of(context).colorScheme.error,
                  trailing: _deletingAccount
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const _RowChevron(),
                  onTap: _deletingAccount ? null : _deleteAccount,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Componentes reutilizables (estilo "iOS Settings")
// ============================================================

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> rows;

  const _SettingsGroup({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTheme.textLight,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              fontSize: 12,
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                rows[i],
                if (i < rows.length - 1) const _RowDivider(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 64),
      child: Divider(height: 1, thickness: 0.6, color: AppTheme.fieldBorder),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color? titleColor;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.titleColor,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    final effectiveTitleColor =
        titleColor ?? (isEnabled ? AppTheme.textDark : AppTheme.textLight);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.homeCardRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: Icon(
                icon,
                color: iconColor.withValues(alpha: isEnabled ? 0.72 : 0.45),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: effectiveTitleColor,
                      fontSize: 15,
                      height: 1.2,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textLight,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          ],
        ),
      ),
    );
  }
}

class _RowValue extends StatelessWidget {
  final String text;
  final bool chevron;

  const _RowValue({required this.text, this.chevron = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textLight,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (chevron) ...const [SizedBox(width: 4), _RowChevron()],
      ],
    );
  }
}

class _PremiumCrownTrailing extends StatelessWidget {
  const _PremiumCrownTrailing();

  static const _crownGold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return const FaIcon(FontAwesomeIcons.crown, size: 16, color: _crownGold);
  }
}

class _RowChevron extends StatelessWidget {
  const _RowChevron();

  @override
  Widget build(BuildContext context) {
    return Icon(
      CupertinoIcons.chevron_right,
      color: AppTheme.textLight.withValues(alpha: 0.7),
      size: 14,
    );
  }
}

// ============================================================
// Bottom sheets reutilizables
// ============================================================

class _SheetContainer extends StatelessWidget {
  final String title;
  final String? intro;
  final Widget child;

  /// Si es true, cabecera + [child] van en un [ListView] con [shrinkWrap] y
  /// altura máxima acotada (no rellena toda la pantalla en vacío).
  final bool scrollBody;

  /// Solo aplica cuando [scrollBody] es true (p. ej. teclado en hoja de edición).
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  const _SheetContainer({
    required this.title,
    this.intro,
    required this.child,
    this.scrollBody = false,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
  });

  List<Widget> _header(BuildContext context) {
    return [
      Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AppTheme.fieldBorder,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppTheme.textHeading,
        ),
      ),
      if (intro != null) ...[
        const SizedBox(height: 6),
        Text(
          intro!,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textLight,
            height: 1.35,
          ),
        ),
      ],
      const SizedBox(height: 16),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.dialogRadius),
        ),
      ),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: scrollBody
              ? Builder(
                  builder: (context) {
                    final mq = MediaQuery.of(context);
                    final maxH =
                        (mq.size.height -
                                mq.viewInsets.bottom -
                                mq.padding.top -
                                32)
                            .clamp(240.0, 9000.0);
                    return ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxH),
                      child: ListView(
                        shrinkWrap: true,
                        primary: false,
                        physics: const ClampingScrollPhysics(),
                        keyboardDismissBehavior: keyboardDismissBehavior,
                        padding: EdgeInsets.zero,
                        children: [..._header(context), child],
                      ),
                    );
                  },
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [..._header(context), child],
                ),
        ),
      ),
    );
  }
}

class _SheetOption<T> {
  final T value;
  final String label;
  const _SheetOption({required this.value, required this.label});
}

class _OptionPickerSheet<T> extends StatelessWidget {
  final String title;
  final String? intro;
  final T currentValue;
  final List<_SheetOption<T>> options;

  const _OptionPickerSheet({
    required this.title,
    this.intro,
    required this.currentValue,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return _SheetContainer(
      title: title,
      intro: intro,
      scrollBody: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 0.6,
                indent: 12,
                endIndent: 12,
                color: AppTheme.fieldBorder,
              ),
            InkWell(
              onTap: () => Navigator.pop(context, options[i].value),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        options[i].label,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: options[i].value == currentValue
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: options[i].value == currentValue
                              ? AppTheme.palettePrimary
                              : AppTheme.textDark,
                        ),
                      ),
                    ),
                    if (options[i].value == currentValue)
                      Icon(
                        CupertinoIcons.checkmark,
                        color: AppTheme.palettePrimary,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Selector de moneda: buscador + lista scrollable con bandera, nombre,
/// código y símbolo. El valor `''` representa el modo automático.
class _CurrencyPickerSheet extends StatefulWidget {
  final String currentValue;
  final String automaticCode;

  const _CurrencyPickerSheet({
    required this.currentValue,
    required this.automaticCode,
  });

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _filteredCodes(String languageCode) {
    final codes = [...kSelectableCurrencyCodes]
      ..sort(
        (a, b) => normalizeForSearch(
          currencyDisplayName(a, languageCode),
        ).compareTo(normalizeForSearch(currencyDisplayName(b, languageCode))),
      );
    final query = normalizeForSearch(_query.trim());
    if (query.isEmpty) return codes;
    return codes
        .where(
          (code) =>
              normalizeForSearch(code).contains(query) ||
              normalizeForSearch(
                currencyDisplayName(code, languageCode),
              ).contains(query) ||
              currencySymbolFor(code).contains(_query.trim()),
        )
        .toList();
  }

  Widget _searchField(AppLocalizations l10n) {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _query = value),
      textInputAction: TextInputAction.search,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        isDense: true,
        hintText: l10n.settingsCurrencySearchHint,
        hintStyle: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppTheme.textLight),
        prefixIcon: const Icon(
          CupertinoIcons.search,
          size: 18,
          color: AppTheme.textLight,
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 40),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                icon: const Icon(
                  CupertinoIcons.clear_circled_solid,
                  size: 18,
                  color: AppTheme.textLight,
                ),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              ),
        filled: true,
        fillColor: AppTheme.fieldBackground,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
          borderSide: const BorderSide(color: AppTheme.palettePrimary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final mq = MediaQuery.of(context);
    final query = _query.trim();
    final codes = _filteredCodes(languageCode);
    final showAuto =
        query.isEmpty ||
        normalizeForSearch(
          l10n.settingsCurrencyAuto,
        ).contains(normalizeForSearch(query));

    final available =
        mq.size.height - mq.padding.top - mq.viewInsets.bottom - 24;
    final preferred = mq.size.height * 0.86;
    final sheetHeight = (preferred < available ? preferred : available).clamp(
      260.0,
      double.infinity,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        height: sheetHeight,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.dialogRadius),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.fieldBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.settingsSheetCurrencyTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textHeading,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.settingsCurrencyIntro,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textLight,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _searchField(l10n),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: (!showAuto && codes.isEmpty)
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            l10n.settingsCurrencyNoResults(query),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textLight,
                            ),
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        children: [
                          if (showAuto)
                            _CurrencyTile(
                              leading: const Icon(
                                CupertinoIcons.globe,
                                size: 20,
                                color: AppTheme.palettePrimary,
                              ),
                              title: l10n.settingsCurrencyAuto,
                              subtitle: l10n.settingsCurrencyAutoSubtitle(
                                currencyOptionLabel(widget.automaticCode),
                              ),
                              selected: widget.currentValue.isEmpty,
                              onTap: () => Navigator.pop(context, ''),
                            ),
                          if (showAuto && codes.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
                              child: Text(
                                l10n.settingsCurrencyAllSection.toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppTheme.textLight,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          for (final code in codes)
                            _CurrencyTile(
                              leading: Text(
                                currencyFlagEmoji(code),
                                style: const TextStyle(fontSize: 20),
                              ),
                              title: currencyDisplayName(code, languageCode),
                              subtitle: '$code · ${currencySymbolFor(code)}',
                              selected: widget.currentValue == code,
                              onTap: () => Navigator.pop(context, code),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrencyTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _CurrencyTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: selected ? AppTheme.softPrimaryFill : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : AppTheme.fieldBackground,
                    shape: BoxShape.circle,
                  ),
                  child: leading,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected
                              ? AppTheme.palettePrimary
                              : AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(
                    CupertinoIcons.checkmark_alt_circle_fill,
                    color: AppTheme.palettePrimary,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Picker estilo iOS (rueda) para el intervalo entre tomas.
/// Dos columnas: horas (0..12) y minutos (0 o 30). Sin loop. El valor
/// guardado se hace clamp(30, 720) en `_saveFeedingSchedule`.
Future<int?> _showFeedingIntervalPicker(
  BuildContext context, {
  required int initialMinutes,
  required AppLocalizations l10n,
}) {
  const maxHours = 12;
  const minuteOptions = [0, 30];

  var selectedHours = (initialMinutes ~/ 60).clamp(0, maxHours);
  var selectedMinIndex = (initialMinutes % 60) >= 30 ? 1 : 0;

  int currentTotal() => selectedHours * 60 + minuteOptions[selectedMinIndex];

  return showCupertinoModalPopup<int>(
    context: context,
    builder: (ctx) {
      final labelStyle = TextStyle(
        fontSize: 18,
        color: CupertinoColors.label.resolveFrom(ctx),
      );
      return Container(
        color: CupertinoColors.systemBackground.resolveFrom(ctx),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 44,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(ctx),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l10n.commonCancel),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      onPressed: () => Navigator.pop(ctx, currentTotal()),
                      child: Text(l10n.commonDone),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 216,
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 32,
                        looping: false,
                        scrollController: FixedExtentScrollController(
                          initialItem: selectedHours,
                        ),
                        onSelectedItemChanged: (i) => selectedHours = i,
                        children: [
                          for (var h = 0; h <= maxHours; h++)
                            Center(
                              child: Text(
                                '$h ${l10n.timeSuffixHour}',
                                style: labelStyle,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 32,
                        looping: false,
                        scrollController: FixedExtentScrollController(
                          initialItem: selectedMinIndex,
                        ),
                        onSelectedItemChanged: (i) => selectedMinIndex = i,
                        children: [
                          for (final m in minuteOptions)
                            Center(
                              child: Text(
                                '$m ${l10n.timeSuffixMinute}',
                                style: labelStyle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ShareFamilySheet extends StatelessWidget {
  final String? familyId;

  const _ShareFamilySheet({required this.familyId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasFamily = familyId != null && familyId!.isNotEmpty;
    return _SheetContainer(
      title: l10n.settingsSheetShareTitle,
      intro: hasFamily
          ? l10n.settingsShareQrIntro
          : l10n.settingsFamilyFirebaseOnly,
      child: hasFamily
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      AppTheme.homeCardRadius,
                    ),
                    border: Border.all(color: AppTheme.fieldBorder),
                  ),
                  child: QrImageView(
                    data: familyId!,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppTheme.textDark,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.settingsQrCaption,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.textLight),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}

// ============================================================
// Sheet de edición de perfil
// ============================================================

class _EditProfileSheet extends StatefulWidget {
  final BabyProfile baby;

  const _EditProfileSheet({required this.baby});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameController;
  late bool? _isMale;
  late DateTime _birthDate;

  @override
  void initState() {
    super.initState();
    final baby = widget.baby;
    _nameController = TextEditingController(text: baby.name);
    _isMale = baby.isMale;
    _birthDate = baby.birthDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = BabyProfile.sanitizeName(_nameController.text);
    if (name.isEmpty) return;

    final profile = widget.baby.copyWith(
      name: name,
      isMale: _isMale,
      clearIsMale: _isMale == null,
      birthDate: _birthDate,
    );
    Navigator.pop(context, profile);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final labelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      color: AppTheme.textDark,
    );
    final fieldDecoration = BoxDecoration(
      color: AppTheme.fieldBackground,
      borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
      border: Border.all(color: AppTheme.fieldBorder),
    );

    final form = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.labelName, style: labelStyle),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: fieldDecoration,
          child: Row(
            children: [
              Icon(Icons.badge_outlined, color: AppTheme.primaryBlue, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _nameController,
                  maxLength: BabyProfile.maxNameLength,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                    counterText: '',
                  ),
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppTheme.textDark),
                  textCapitalization: TextCapitalization.words,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(l10n.labelGender, style: labelStyle),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _GenderChip(
                label: l10n.commonGenderBoy,
                icon: Icons.male_outlined,
                selected: _isMale == true,
                onTap: () => setState(() => _isMale = true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GenderChip(
                label: l10n.commonGenderGirl,
                icon: Icons.female_outlined,
                selected: _isMale == false,
                onTap: () => setState(() => _isMale = false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _GenderUnspecifiedOption(
          label: l10n.commonGenderUnspecified,
          selected: _isMale == null,
          onTap: () => setState(() => _isMale = null),
        ),
        const SizedBox(height: 16),
        Text(l10n.settingsBirthDate, style: labelStyle),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final firstDate = DateTime.now().subtract(
              const Duration(days: 365 * 2),
            );
            final lastDate = DateTime.now();
            final initial = _birthDate.isBefore(firstDate)
                ? firstDate
                : (_birthDate.isAfter(lastDate) ? lastDate : _birthDate);
            final Future<DateTime?> futureDate;
            if (defaultTargetPlatform == TargetPlatform.iOS) {
              futureDate = showCupertinoDatePickerSheet(
                context,
                initial,
                firstDate,
                lastDate,
                l10n,
              );
            } else {
              futureDate = showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: firstDate,
                lastDate: lastDate,
                locale: locale,
              );
            }
            final date = await futureDate;
            if (date != null && mounted) {
              setState(() => _birthDate = date);
            }
          },
          borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: fieldDecoration,
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: AppTheme.primaryBlue,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    DateFormat(
                      'd MMM yyyy',
                      dateFormatLanguageCode(context),
                    ).format(_birthDate),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: AppTheme.textDark),
                  ),
                ),
                const _RowChevron(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: Text(l10n.commonCancel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _save,
                child: Text(l10n.commonSave),
              ),
            ),
          ],
        ),
      ],
    );

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: _SheetContainer(
          scrollBody: true,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          title: l10n.editBabyProfileTitle,
          child: form,
        ),
      ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _GenderChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryBlue.withValues(alpha: 0.15)
              : AppTheme.fieldBackground,
          borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
          border: Border.all(
            color: selected ? AppTheme.primaryBlue : AppTheme.fieldBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: selected ? AppTheme.primaryBlue : AppTheme.textLight,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? AppTheme.primaryBlue : AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenderUnspecifiedOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenderUnspecifiedOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.primaryBlue : AppTheme.textLight;

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: selected ? 10 : 0,
                    height: selected ? 10 : 0,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: selected ? AppTheme.primaryBlue : AppTheme.textLight,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
