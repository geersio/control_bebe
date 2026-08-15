import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/auth/unauth_entry.dart';
import '../../../core/config/revenuecat_config.dart';
import '../../../core/db/isar_service.dart';
import '../../../core/firebase/firebase_service.dart';
import '../../../core/percentiles_data.dart';
import '../../../core/models/baby_profile.dart';
import '../../../core/models/baby_sex.dart';
import '../../../core/models/measurement_units.dart';
import '../../../core/providers/baby_profile_provider.dart';
import '../../../core/providers/measurement_prefs_provider.dart';
import '../../../core/services/next_feeding_notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/baby_age_calendar.dart';
import '../../../core/utils/feeding_interval_labels.dart';
import '../../../core/utils/measurement_display.dart';
import '../../../core/utils/next_sleep_prediction.dart';
import '../../../l10n/app_date_locale.dart';
import '../../../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../auth/views/family_qr_join_screen.dart';
import '../../auth/views/register_view.dart';
import '../../paywall/views/paywall_view.dart';
import '../models/onboarding_draft.dart';
import '../providers/onboarding_draft_provider.dart';
import '../utils/age_care_guidance.dart';
import '../utils/feeding_interval_for_age.dart';
import 'widgets/onboarding_step_scaffold.dart';

/// Nuevo onboarding de 8 pasos. Sin sesión: login al final.
/// Con sesión: omite cuenta y guarda al terminar.
class OnboardingFlowView extends ConsumerStatefulWidget {
  final Future<void> Function()? onFinished;
  final bool alreadyAuthenticated;

  const OnboardingFlowView({
    super.key,
    this.onFinished,
    this.alreadyAuthenticated = false,
  });

  @override
  ConsumerState<OnboardingFlowView> createState() => _OnboardingFlowViewState();
}

class _OnboardingFlowViewState extends ConsumerState<OnboardingFlowView> {
  bool _showQr = false;
  bool _committing = false;
  bool _autoCommitStarted = false;
  bool _existingProfileDialogShown = false;

  OnboardingDraft get _draft => ref.read(onboardingDraftProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowExistingProfileDialog();
    });
  }

  void _maybeShowExistingProfileDialog() {
    if (!mounted || _existingProfileDialogShown) return;
    if (!ref.read(onboardingExistingProfileAlertProvider)) return;
    _existingProfileDialogShown = true;
    ref.read(onboardingExistingProfileAlertProvider.notifier).state = false;
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.dialogRadius),
          ),
          title: Text(l10n.onboardingFlowProfileAlreadyExistsTitle),
          content: Text(l10n.onboardingFlowProfileAlreadyExists),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(l10n.onboardingFlowProfileAlreadyExistsButton),
            ),
          ],
        );
      },
    ).whenComplete(() {
      _existingProfileDialogShown = false;
    });
  }

  Future<void> _rejectExistingProfileAndStayOnSignIn() async {
    final draft = ref.read(onboardingDraftProvider);
    ref.read(onboardingDraftProvider.notifier).clearPendingCommit();
    if (draft.step != 8) {
      ref.read(onboardingDraftProvider.notifier).setStep(8);
    }
    ref.read(onboardingExistingProfileAlertProvider.notifier).state = true;
    _autoCommitStarted = false;
    if (widget.alreadyAuthenticated) {
      await ref.read(unauthEntryProvider.notifier).preferOnboardingKeepDraft();
      try {
        await AuthService.signOut();
      } catch (_) {}
      return;
    }
    if (mounted) {
      setState(() => _committing = false);
      _maybeShowExistingProfileDialog();
    }
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  void _goTo(int step) {
    _dismissKeyboard();
    ref.read(onboardingDraftProvider.notifier).setStep(step);
  }

  void _back() {
    final step = _draft.step;
    if (step <= 0) return;
    // Desde resultados (6) saltar la pantalla de cálculo (5).
    if (step == 6) {
      _goTo(4);
      return;
    }
    _goTo(step - 1);
  }

  Future<void> _openQrInvite() async {
    final l10n = AppLocalizations.of(context)!;
    if (!FirebaseService.isAvailable) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.onboardingFlowQrNeedsConnection)),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      try {
        await AuthService.signInAnonymously();
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.onboardingFlowQrOpenFail)));
      }
      return;
    }

    setState(() => _showQr = true);
  }

  Future<void> _onQrScanned(String familyId) async {
    await IsarService.joinFamily(familyId);
    await IsarService.completeOnboarding();
    ref.read(onboardingDraftProvider.notifier).reset();
    ref.invalidate(babyProfileProvider);
    if (!mounted) return;
    await widget.onFinished?.call();
  }

  Future<void> _finishAuthenticatedPath() async {
    if (_committing) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _committing = true);
    try {
      await ref
          .read(onboardingDraftProvider.notifier)
          .commit(defaultName: l10n.onboardingFlowBabyDefaultName);
      if (!mounted) return;
      await showAppPaywall(context);
      if (!mounted) return;
      await widget.onFinished?.call();
    } on ExistingBabyProfileException {
      await _rejectExistingProfileAndStayOnSignIn();
    } catch (e) {
      if (!mounted) return;
      _autoCommitStarted = false;
      _goTo(7);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.onboardingFlowSaveFail('$e'))),
      );
    } finally {
      if (mounted) setState(() => _committing = false);
    }
  }

  Future<void> _authWith(Future<UserCredential?> Function() signIn) async {
    final l10n = AppLocalizations.of(context)!;
    // Marcar ANTES del login: AuthWrapper puede reconstruir en cuanto hay sesión.
    ref.read(onboardingDraftProvider.notifier).markPendingCommit();
    await ref.read(onboardingDraftProvider.notifier).flushPersistence();
    if (!mounted) return;
    setState(() => _committing = true);
    try {
      final cred = await signIn();
      if (cred == null) {
        ref.read(onboardingDraftProvider.notifier).clearPendingCommit();
      }
    } on FirebaseAuthException catch (e) {
      ref.read(onboardingDraftProvider.notifier).clearPendingCommit();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? l10n.onboardingFlowAuthError)),
      );
    } catch (_) {
      ref.read(onboardingDraftProvider.notifier).clearPendingCommit();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.onboardingFlowSignInFail)));
    } finally {
      if (mounted) setState(() => _committing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingDraftProvider);
    ref.listen<bool>(onboardingExistingProfileAlertProvider, (prev, next) {
      if (next) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _maybeShowExistingProfileDialog();
        });
      }
    });

    if (_showQr) {
      return FamilyQrJoinScreen(
        onScanned: _onQrScanned,
        onBack: () => setState(() => _showQr = false),
      );
    }

    // Usuario ya autenticado: al llegar al paso de cuenta, guardar + paywall.
    if (widget.alreadyAuthenticated && draft.step >= 8) {
      if (!_autoCommitStarted) {
        _autoCommitStarted = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _finishAuthenticatedPath();
        });
      }
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    switch (draft.step) {
      case 0:
        return _BornOrPregnantStep(
          draft: draft,
          onSelectAndContinue: (v) {
            ref
                .read(onboardingDraftProvider.notifier)
                .selectHasBornAndContinue(v);
          },
          onQrInvite: _openQrInvite,
          onHaveAccount: () async {
            // Tras un alta parcialmente fallida puede existir una sesión Firebase
            // sin perfil. AuthWrapper ignora el destino no autenticado mientras
            // esa sesión siga activa, por lo que primero fijamos login y salimos.
            await ref.read(unauthEntryProvider.notifier).markLoginPreferred();
            if (FirebaseAuth.instance.currentUser != null) {
              await AuthService.signOut();
            }
          },
        );
      case 1:
        return _NameStep(
          draft: draft,
          onName: (n) => ref.read(onboardingDraftProvider.notifier).setName(n),
          onContinue: () {
            if (ref.read(onboardingDraftProvider).canContinueStep1) {
              _goTo(2);
            }
          },
          onBack: _back,
        );
      case 2:
        return _HideKeyboardOnAppear(
          child: _GenderStep(
            draft: draft,
            onSelectAndContinue: (sex) {
              ref
                  .read(onboardingDraftProvider.notifier)
                  .selectSexAndContinue(sex);
            },
            onBack: _back,
          ),
        );
      case 3:
        return _BirthDateStep(
          draft: draft,
          onDate: (d) =>
              ref.read(onboardingDraftProvider.notifier).setBirthDate(d),
          onContinue: () => _goTo(4),
          onBack: _back,
        );
      case 4:
        return _MeasurementsStep(
          draft: draft,
          onWeight: (w) =>
              ref.read(onboardingDraftProvider.notifier).setWeightKg(w),
          onHeight: (h) =>
              ref.read(onboardingDraftProvider.notifier).setHeightCm(h),
          onContinue: () => _goTo(5),
          onSkip: () {
            ref.read(onboardingDraftProvider.notifier).setWeightKg(null);
            ref.read(onboardingDraftProvider.notifier).setHeightCm(null);
            _goTo(5);
          },
          onBack: _back,
        );
      case 5:
        return _HideKeyboardOnAppear(
          child: _CalculatingStep(draft: draft, onDone: () => _goTo(6)),
        );
      case 6:
        return _HideKeyboardOnAppear(
          child: _ResultsStep(
            draft: draft,
            onContinue: () => _goTo(7),
            onBack: _back,
          ),
        );
      case 7:
        return _HideKeyboardOnAppear(
          child: _NotificationsStep(
            draft: draft,
            onEnable: () async {
              final ok =
                  await NextFeedingNotificationService.requestPermissions();
              ref
                  .read(onboardingDraftProvider.notifier)
                  .setWantNotifications(ok);
              _goTo(8);
            },
            onSkip: () {
              ref
                  .read(onboardingDraftProvider.notifier)
                  .setWantNotifications(false);
              _goTo(8);
            },
            onBack: _back,
          ),
        );
      case 8:
      default:
        return _SaveAccountStep(
          draft: draft,
          loading: _committing,
          onApple: () => _authWith(AuthService.signInWithApple),
          onGoogle: () => _authWith(AuthService.signInWithGoogle),
          onEmail: () async {
            final notifier = ref.read(onboardingDraftProvider.notifier);
            notifier.markPendingCommit();
            // Flush antes del signup: AuthWrapper monta AppInitializer en cuanto
            // hay sesión y debe ver pendingCommit + nombre/fecha del borrador.
            await notifier.flushPersistence();
            if (!context.mounted) return;
            final registered = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const RegisterView()),
            );
            // Si este State ya no está montado, AppInitializer hace el commit.
            if (!mounted) return;
            if (registered != true &&
                FirebaseAuth.instance.currentUser == null) {
              notifier.clearPendingCommit();
            }
          },
          onBack: _back,
        );
    }
  }
}

/// Cierra el teclado al montar una pantalla sin campos de texto.
class _HideKeyboardOnAppear extends StatefulWidget {
  final Widget child;

  const _HideKeyboardOnAppear({required this.child});

  @override
  State<_HideKeyboardOnAppear> createState() => _HideKeyboardOnAppearState();
}

class _HideKeyboardOnAppearState extends State<_HideKeyboardOnAppear> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.primaryFocus?.unfocus();
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ─────────────────────────────────────────────────────────────────────────────
// Paso 0 — Nacido / embarazada
// ─────────────────────────────────────────────────────────────────────────────

class _BornOrPregnantStep extends StatefulWidget {
  final OnboardingDraft draft;
  final ValueChanged<bool> onSelectAndContinue;
  final VoidCallback onQrInvite;
  final VoidCallback onHaveAccount;

  const _BornOrPregnantStep({
    required this.draft,
    required this.onSelectAndContinue,
    required this.onQrInvite,
    required this.onHaveAccount,
  });

  @override
  State<_BornOrPregnantStep> createState() => _BornOrPregnantStepState();
}

class _BornOrPregnantStepState extends State<_BornOrPregnantStep> {
  bool? _selected;
  bool _advancing = false;
  Timer? _advanceTimer;

  @override
  void dispose() {
    _advanceTimer?.cancel();
    super.dispose();
  }

  void _pick(bool hasBorn) {
    if (_advancing) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _selected = hasBorn;
      _advancing = true;
    });
    // Deja ver el check animado (mismo timing que InlineConfirmingButton) y avanza.
    _advanceTimer?.cancel();
    _advanceTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      widget.onSelectAndContinue(hasBorn);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selected = _selected ?? widget.draft.hasBorn;
    return OnboardingStepScaffold(
      progressStep: 0,
      title: l10n.onboardingFlowBornTitle,
      subtitle: l10n.onboardingFlowBornSubtitle,
      showPrimary: false,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 14),
          _OnboardingSecondaryLink(
            icon: Icons.qr_code_2_rounded,
            label: l10n.onboardingFlowQrInvite,
            emphasized: true,
            onTap: _advancing ? null : widget.onQrInvite,
          ),
          const SizedBox(height: 4),
          _OnboardingSecondaryLink(
            label: l10n.onboardingFlowHaveAccount,
            emphasized: false,
            onTap: _advancing ? null : widget.onHaveAccount,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnboardingBigOption(
            label: l10n.onboardingFlowBornOption,
            icon: Icons.crib_rounded,
            selected: selected == true,
            showChevron: selected == null,
            onTap: () => _pick(true),
          ),
          const SizedBox(height: 14),
          OnboardingBigOption(
            label: l10n.onboardingFlowPregnantOption,
            icon: Icons.pregnant_woman_rounded,
            selected: selected == false,
            showChevron: selected == null,
            onTap: () => _pick(false),
          ),
        ],
      ),
    );
  }
}

class _OnboardingSecondaryLink extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool emphasized;

  const _OnboardingSecondaryLink({
    required this.label,
    required this.onTap,
    this.icon,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = emphasized ? AppTheme.primaryBlue : AppTheme.textLight;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontWeight: emphasized ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Paso 1 — Nombre
// ─────────────────────────────────────────────────────────────────────────────

class _NameStep extends StatefulWidget {
  final OnboardingDraft draft;
  final ValueChanged<String> onName;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const _NameStep({
    required this.draft,
    required this.onName,
    required this.onContinue,
    required this.onBack,
  });

  @override
  State<_NameStep> createState() => _NameStepState();
}

class _NameStepState extends State<_NameStep> {
  late final TextEditingController _controller;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    final initial = _capitalizeFirstLetter(widget.draft.name);
    _controller = TextEditingController(text: initial);
    if (initial != widget.draft.name) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onName(initial);
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _useUndecidedName(AppLocalizations l10n) {
    final name = l10n.onboardingFlowBabyDefaultName;
    _controller.text = name;
    widget.onName(name);
    widget.onContinue();
  }

  /// Primera letra en mayúscula; el resto se deja como lo escribió el usuario.
  static String _capitalizeFirstLetter(String value) {
    if (value.isEmpty) return value;
    final first = value[0];
    final upper = first.toUpperCase();
    if (first == upper) return value;
    return '$upper${value.substring(1)}';
  }

  void _onNameChanged(String value) {
    final capitalized = _capitalizeFirstLetter(value);
    if (capitalized != value) {
      final sel = _controller.selection;
      _controller.value = TextEditingValue(
        text: capitalized,
        selection: sel.copyWith(
          baseOffset: sel.baseOffset.clamp(0, capitalized.length),
          extentOffset: sel.extentOffset.clamp(0, capitalized.length),
        ),
      );
    }
    widget.onName(capitalized);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final draft = widget.draft;
    return OnboardingStepScaffold(
      progressStep: 1,
      title: l10n.onboardingFlowNameTitle,
      subtitle: l10n.onboardingFlowNameSubtitle,
      primaryLabel: l10n.onboardingFlowContinue,
      onPrimary: draft.canContinueStep1 ? widget.onContinue : null,
      onBack: widget.onBack,
      child: Column(
        children: [
          TextField(
            controller: _controller,
            focusNode: _focus,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.words,
            showCursor: false,
            cursorOpacityAnimates: false,
            autocorrect: false,
            enableSuggestions: false,
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.done,
            maxLength: BabyProfile.maxNameLength,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
            decoration: InputDecoration(
              hintText: l10n.onboardingFlowNameHint,
              hintStyle: TextStyle(
                color: AppTheme.textLight.withValues(alpha: 0.7),
              ),
              counterText: '',
              filled: true,
              fillColor: AppTheme.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                borderSide: BorderSide(color: AppTheme.cardOutline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                borderSide: BorderSide(color: AppTheme.cardOutline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                borderSide: const BorderSide(
                  color: AppTheme.primaryBlue,
                  width: 2,
                ),
              ),
            ),
            onChanged: _onNameChanged,
            onSubmitted: (value) {
              final name = _capitalizeFirstLetter(value);
              widget.onName(name);
              if (name.trim().isNotEmpty) widget.onContinue();
            },
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _useUndecidedName(l10n),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryBlue,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
            child: Text(
              l10n.onboardingFlowNameUndecided,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Paso 2 — Sexo
// ─────────────────────────────────────────────────────────────────────────────

class _GenderStep extends StatefulWidget {
  final OnboardingDraft draft;
  final ValueChanged<BabySex> onSelectAndContinue;
  final VoidCallback onBack;

  const _GenderStep({
    required this.draft,
    required this.onSelectAndContinue,
    required this.onBack,
  });

  @override
  State<_GenderStep> createState() => _GenderStepState();
}

class _GenderStepState extends State<_GenderStep> {
  BabySex? _selected;
  bool _advancing = false;
  Timer? _advanceTimer;

  @override
  void dispose() {
    _advanceTimer?.cancel();
    super.dispose();
  }

  void _pick(BabySex sex) {
    if (_advancing) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _selected = sex;
      _advancing = true;
    });
    _advanceTimer?.cancel();
    _advanceTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      widget.onSelectAndContinue(sex);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final draft = widget.draft;
    final selected = _selected ?? draft.sex;
    return OnboardingStepScaffold(
      progressStep: 2,
      title: draft.hasName
          ? l10n.onboardingFlowGenderTitleNamed(draft.displayName)
          : l10n.onboardingFlowGenderTitle,
      subtitle: l10n.onboardingFlowGenderSubtitle,
      showPrimary: false,
      onBack: widget.onBack,
      child: Column(
        children: [
          OnboardingBigOption(
            label: l10n.commonGenderBoy,
            icon: Icons.male_rounded,
            selected: selected == BabySex.male,
            showChevron: selected == null,
            onTap: () => _pick(BabySex.male),
          ),
          const SizedBox(height: 14),
          OnboardingBigOption(
            label: l10n.commonGenderGirl,
            icon: Icons.female_rounded,
            selected: selected == BabySex.female,
            showChevron: selected == null,
            onTap: () => _pick(BabySex.female),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _advancing ? null : () => _pick(BabySex.unspecified),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryBlue,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
            child: Text(
              l10n.commonGenderUnspecified,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Paso 3 — Fecha de nacimiento / prevista
// ─────────────────────────────────────────────────────────────────────────────

class _BirthDateStep extends StatefulWidget {
  final OnboardingDraft draft;
  final ValueChanged<DateTime> onDate;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const _BirthDateStep({
    required this.draft,
    required this.onDate,
    required this.onContinue,
    required this.onBack,
  });

  @override
  State<_BirthDateStep> createState() => _BirthDateStepState();
}

class _BirthDateStepState extends State<_BirthDateStep> {
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _selected = _clamped(widget.draft.birthDate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onDate(_selected);
    });
  }

  @override
  void didUpdateWidget(covariant _BirthDateStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draft.hasBorn != widget.draft.hasBorn ||
        oldWidget.draft.birthDate != widget.draft.birthDate) {
      _selected = _clamped(widget.draft.birthDate);
    }
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool get _isBorn => widget.draft.hasBorn != false;

  DateTime get _min {
    final today = _today;
    return _isBorn ? DateTime(today.year - 5, today.month, today.day) : today;
  }

  DateTime get _max {
    final today = _today;
    return _isBorn ? today : DateTime(today.year + 1, today.month, today.day);
  }

  DateTime _clamped(DateTime raw) {
    var d = DateTime(raw.year, raw.month, raw.day);
    if (d.isBefore(_min)) d = _min;
    if (d.isAfter(_max)) d = _max;
    return d;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final draft = widget.draft;
    final name = draft.hasName
        ? draft.displayName
        : l10n.onboardingFlowBabyGeneric;
    final title = _isBorn
        ? l10n.onboardingFlowBirthTitle(name)
        : l10n.onboardingFlowDueTitle(name);
    final now = DateTime.now();
    final min = _min;
    final max = _max;

    return OnboardingStepScaffold(
      progressStep: 3,
      title: title,
      subtitle: l10n.onboardingFlowBirthSubtitle,
      primaryLabel: l10n.onboardingFlowContinue,
      onPrimary: () {
        widget.onDate(_selected);
        widget.onContinue();
      },
      onBack: widget.onBack,
      child: Column(
        children: [
          const Spacer(),
          SizedBox(
            height: 220,
            child: CupertinoTheme(
              data: const CupertinoThemeData(
                textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              child: CupertinoDatePicker(
                key: ValueKey<String>(
                  'onboarding_date_${_isBorn}_${min.toIso8601String()}_${max.toIso8601String()}',
                ),
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selected,
                minimumDate: min,
                maximumDate: max,
                minimumYear: min.year,
                maximumYear: max.year,
                onDateTimeChanged: (d) {
                  final next = _clamped(d);
                  setState(() => _selected = next);
                  widget.onDate(next);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final babyName = draft.hasName
                  ? draft.displayName
                  : l10n.onboardingFlowBabyGeneric;
              final String label;
              if (_isBorn) {
                final age = BabyAgeCalendar.monthsAndDaysAt(_selected, now);
                label = age.months == 0
                    ? l10n.onboardingFlowAgeHasDays(babyName, age.days)
                    : (age.days == 0
                          ? l10n.onboardingFlowAgeHasMonths(
                              babyName,
                              age.months,
                            )
                          : l10n.onboardingFlowAgeHasMonthsDays(
                              babyName,
                              age.months,
                              age.days,
                            ));
              } else {
                final due = DateTime(
                  _selected.year,
                  _selected.month,
                  _selected.day,
                );
                final daysLeft = due.difference(_today).inDays;
                label = daysLeft <= 0
                    ? l10n.onboardingFlowDueToday(babyName)
                    : (daysLeft == 1
                          ? l10n.onboardingFlowDueInOneDay(babyName)
                          : l10n.onboardingFlowDueInDays(babyName, daysLeft));
              }
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.softPrimaryFill,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textHeading,
                  ),
                ),
              );
            },
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Paso 3 — Medidas
// ─────────────────────────────────────────────────────────────────────────────

class _MeasurementsStep extends ConsumerStatefulWidget {
  final OnboardingDraft draft;
  final ValueChanged<double?> onWeight;
  final ValueChanged<double?> onHeight;
  final VoidCallback onContinue;
  final VoidCallback onSkip;
  final VoidCallback onBack;

  const _MeasurementsStep({
    required this.draft,
    required this.onWeight,
    required this.onHeight,
    required this.onContinue,
    required this.onSkip,
    required this.onBack,
  });

  @override
  ConsumerState<_MeasurementsStep> createState() => _MeasurementsStepState();
}

class _MeasurementsStepState extends ConsumerState<_MeasurementsStep> {
  static const double _minWeightKg = 0.5;
  static const double _maxWeightKg = 30;
  static const double _minHeightCm = 30;
  static const double _maxHeightCm = 120;

  late final TextEditingController _weightCtrl;
  late final TextEditingController _heightCtrl;
  final _weightFocus = FocusNode();
  final _heightFocus = FocusNode();

  /// Talla en pulgadas en UI (almacenamiento siempre cm).
  /// Por defecto según región del dispositivo (US/LR/MM → in).
  bool _heightUsesInches = MeasurementPrefs.regionUsesImperial();

  String get _decimalSep =>
      Localizations.localeOf(context).languageCode == 'es' ? ',' : '.';

  String get _placeholder =>
      '0$_decimalSep'
      '0';

  String _formatForField(String raw) =>
      raw.replaceAll('.', _decimalSep).replaceAll(',', _decimalSep);

  bool _weightOutOfRange = false;
  bool _heightOutOfRange = false;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController();
    _heightCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncControllersFromDraft();
      _weightFocus.requestFocus();
    });
  }

  void _syncControllersFromDraft() {
    final prefs =
        ref.read(measurementPrefsProvider).valueOrNull ??
        MeasurementPrefs.defaultsForDispatcher();
    final wKg = widget.draft.weightKg;
    if (wKg != null && wKg > 0) {
      _weightCtrl.text = _formatForField(weightInputDisplayFromKg(wKg, prefs));
    }
    final hCm = widget.draft.heightCm;
    if (hCm != null && hCm > 0) {
      final value = _heightUsesInches ? hCm / 2.54 : hCm;
      _heightCtrl.text = _formatForField(value.toStringAsFixed(1));
    }
    _refreshRangeFlags(prefs);
  }

  void _refreshRangeFlags(MeasurementPrefs prefs) {
    final kg = parseWeightInputToKg(_weightCtrl.text, prefs);
    final cm = _parseHeightToCm(_heightCtrl.text);
    setState(() {
      _weightOutOfRange =
          kg != null && (kg < _minWeightKg || kg > _maxWeightKg);
      _heightOutOfRange =
          cm != null && (cm < _minHeightCm || cm > _maxHeightCm);
    });
  }

  /// Guarda solo valores dentro de rango; vacío u outside → null (aviso suave).
  double? _sanitizedWeightKg(MeasurementPrefs prefs) {
    final kg = parseWeightInputToKg(_weightCtrl.text, prefs);
    if (kg == null) return null;
    if (kg < _minWeightKg || kg > _maxWeightKg) return null;
    return kg;
  }

  double? _sanitizedHeightCm() {
    final cm = _parseHeightToCm(_heightCtrl.text);
    if (cm == null) return null;
    if (cm < _minHeightCm || cm > _maxHeightCm) return null;
    return cm;
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _weightFocus.dispose();
    _heightFocus.dispose();
    super.dispose();
  }

  double? _parseHeightToCm(String raw) {
    final n = parseLooseDecimal(raw);
    if (n == null || n <= 0) return null;
    return _heightUsesInches ? n * 2.54 : n;
  }

  Future<void> _pickWeightUnit(MeasurementPrefs prefs) async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await showModalBottomSheet<WeightUnitMode>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _OnboardingUnitPickerSheet<WeightUnitMode>(
        title: l10n.onboardingFlowWeightUnitTitle,
        currentValue: prefs.weight,
        options: [
          (
            value: WeightUnitMode.metric,
            label: l10n.onboardingFlowWeightUnitKg,
          ),
          (
            value: WeightUnitMode.imperial,
            label: l10n.onboardingFlowWeightUnitLb,
          ),
        ],
      ),
    );
    if (selected == null || selected == prefs.weight || !mounted) return;
    final kg = parseWeightInputToKg(_weightCtrl.text, prefs);
    await ref.read(measurementPrefsProvider.notifier).setWeight(selected);
    if (!mounted) return;
    final updated =
        ref.read(measurementPrefsProvider).valueOrNull ??
        prefs.copyWith(weight: selected);
    if (kg != null) {
      _weightCtrl.text = _formatForField(weightInputDisplayFromKg(kg, updated));
      widget.onWeight(_sanitizedWeightKg(updated));
    }
    _refreshRangeFlags(updated);
  }

  Future<void> _pickHeightUnit() async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _OnboardingUnitPickerSheet<bool>(
        title: l10n.onboardingFlowHeightUnitTitle,
        currentValue: _heightUsesInches,
        options: [
          (value: false, label: l10n.onboardingFlowHeightUnitCm),
          (value: true, label: l10n.onboardingFlowHeightUnitIn),
        ],
      ),
    );
    if (selected == null || selected == _heightUsesInches || !mounted) return;
    final cm = _parseHeightToCm(_heightCtrl.text);
    setState(() => _heightUsesInches = selected);
    if (cm != null) {
      final value = _heightUsesInches ? cm / 2.54 : cm;
      _heightCtrl.text = _formatForField(value.toStringAsFixed(1));
      widget.onHeight(_sanitizedHeightCm());
    }
    final prefs =
        ref.read(measurementPrefsProvider).valueOrNull ??
        MeasurementPrefs.defaultsForDispatcher();
    _refreshRangeFlags(prefs);
  }

  bool get _hasAnyTyped =>
      _weightCtrl.text.trim().isNotEmpty || _heightCtrl.text.trim().isNotEmpty;

  void _submit() {
    if (!_hasAnyTyped) {
      widget.onSkip();
      return;
    }
    final prefsNow =
        ref.read(measurementPrefsProvider).valueOrNull ??
        MeasurementPrefs.defaultsForDispatcher();
    widget.onWeight(_sanitizedWeightKg(prefsNow));
    widget.onHeight(_sanitizedHeightCm());
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final prefs =
        ref.watch(measurementPrefsProvider).valueOrNull ??
        MeasurementPrefs.defaultsForDispatcher();
    final weightUnit = prefs.weight == WeightUnitMode.metric ? 'kg' : 'lb';
    final heightUnit = _heightUsesInches ? 'in' : 'cm';
    final hasTyped = _hasAnyTyped;

    return OnboardingStepScaffold(
      progressStep: 4,
      title: l10n.onboardingFlowMeasuresTitle,
      subtitle: l10n.onboardingFlowMeasuresSubtitle,
      primaryLabel: hasTyped
          ? l10n.onboardingFlowContinue
          : l10n.onboardingFlowMeasuresLater,
      onPrimary: _submit,
      onBack: widget.onBack,
      child: Column(
        children: [
          _MeasureField(
            controller: _weightCtrl,
            focusNode: _weightFocus,
            label: l10n.onboardingFlowWeightLabel,
            unit: weightUnit,
            placeholder: _placeholder,
            icon: Icons.monitor_weight_outlined,
            warning: _weightOutOfRange
                ? l10n.onboardingFlowWeightRangeHint
                : null,
            onUnitTap: () => _pickWeightUnit(prefs),
            onChanged: (v) {
              final prefsNow =
                  ref.read(measurementPrefsProvider).valueOrNull ?? prefs;
              final kg = parseWeightInputToKg(v, prefsNow);
              final ok =
                  kg == null || (kg >= _minWeightKg && kg <= _maxWeightKg);
              setState(() => _weightOutOfRange = kg != null && !ok);
              widget.onWeight(ok ? kg : null);
            },
          ),
          const SizedBox(height: 16),
          _MeasureField(
            controller: _heightCtrl,
            focusNode: _heightFocus,
            label: l10n.onboardingFlowHeightLabel,
            unit: heightUnit,
            placeholder: _placeholder,
            icon: Icons.straighten_outlined,
            warning: _heightOutOfRange
                ? l10n.onboardingFlowHeightRangeHint
                : null,
            onUnitTap: _pickHeightUnit,
            onChanged: (v) {
              final cm = _parseHeightToCm(v);
              final ok =
                  cm == null || (cm >= _minHeightCm && cm <= _maxHeightCm);
              setState(() => _heightOutOfRange = cm != null && !ok);
              widget.onHeight(ok ? cm : null);
            },
          ),
        ],
      ),
    );
  }
}

class _MeasureField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String unit;
  final String placeholder;
  final IconData icon;
  final String? warning;
  final VoidCallback onUnitTap;
  final ValueChanged<String> onChanged;

  const _MeasureField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.unit,
    required this.placeholder,
    required this.icon,
    required this.onUnitTap,
    required this.onChanged,
    this.warning,
  });

  @override
  Widget build(BuildContext context) {
    final hasWarning = warning != null && warning!.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: hasWarning
              ? AppTheme.primaryOrange.withValues(alpha: 0.55)
              : AppTheme.cardOutline,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.textLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: hasWarning
                      ? AppTheme.primaryOrange.withValues(alpha: 0.45)
                      : AppTheme.cardOutline,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: const [LooseDecimalInputFormatter()],
                    textInputAction: TextInputAction.next,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                      height: 1.2,
                    ),
                    cursorColor: AppTheme.primaryBlue,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: placeholder,
                      hintStyle: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textLight.withValues(alpha: 0.45),
                            height: 1.2,
                          ),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.only(bottom: 8),
                    ),
                    onChanged: onChanged,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onUnitTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 4, 2, 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          unit,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.expand_more_rounded,
                          size: 20,
                          color: AppTheme.primaryBlue.withValues(alpha: 0.85),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (hasWarning) ...[
            const SizedBox(height: 10),
            Text(
              warning!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.primaryOrange,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OnboardingUnitPickerSheet<T> extends StatelessWidget {
  final String title;
  final T currentValue;
  final List<({T value, String label})> options;

  const _OnboardingUnitPickerSheet({
    required this.title,
    required this.currentValue,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = AppTheme.safeBottomPadding(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppTheme.screenEdgePadding,
        0,
        AppTheme.screenEdgePadding,
        bottom + AppTheme.screenEdgePadding,
      ),
      child: Material(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.homeCardRadius),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textHeading,
                    ),
                  ),
                ),
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
                        horizontal: 12,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              options[i].label,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    fontWeight: options[i].value == currentValue
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: options[i].value == currentValue
                                        ? AppTheme.primaryBlue
                                        : AppTheme.textDark,
                                  ),
                            ),
                          ),
                          if (options[i].value == currentValue)
                            const Icon(
                              Icons.check_rounded,
                              color: AppTheme.primaryBlue,
                              size: 22,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Paso 4 — Cálculo animado
// ─────────────────────────────────────────────────────────────────────────────

class _CalculatingStep extends StatefulWidget {
  final OnboardingDraft draft;
  final VoidCallback onDone;

  const _CalculatingStep({required this.draft, required this.onDone});

  @override
  State<_CalculatingStep> createState() => _CalculatingStepState();
}

class _CalculatingStepState extends State<_CalculatingStep>
    with SingleTickerProviderStateMixin {
  static const int _itemCount = 3;
  static const int _minItemMs = 450;
  static const int _maxItemMs = 2000;

  late final List<int> _itemDurationsMs;
  late final int _totalMs;
  late final AnimationController _progress;
  int _doneCount = 0;

  @override
  void initState() {
    super.initState();
    final rng = math.Random();
    _itemDurationsMs = List<int>.generate(
      _itemCount,
      (_) => _minItemMs + rng.nextInt(_maxItemMs - _minItemMs + 1),
    );
    _totalMs = _itemDurationsMs.fold<int>(0, (sum, ms) => sum + ms);
    _progress = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _totalMs),
    )..addListener(_onProgressTick);
    _progress.forward().whenComplete(() async {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (mounted) widget.onDone();
    });
  }

  void _onProgressTick() {
    final elapsedMs = (_progress.value * _totalMs);
    var accumulated = 0.0;
    var done = 0;
    for (final ms in _itemDurationsMs) {
      accumulated += ms;
      if (elapsedMs >= accumulated) {
        done++;
      } else {
        break;
      }
    }
    if (done != _doneCount && mounted) {
      setState(() => _doneCount = done);
    }
  }

  @override
  void dispose() {
    _progress
      ..removeListener(_onProgressTick)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = widget.draft.hasName
        ? widget.draft.displayName
        : l10n.onboardingFlowBabyGeneric;
    final isPregnant = widget.draft.hasBorn == false;

    // Alineado con lo que muestra _ResultsStep: crecimiento, tomas y sueño.
    final items = isPregnant
        ? [
            l10n.onboardingFlowCalcDueDate,
            l10n.onboardingFlowCalcNewbornFeeding,
            l10n.onboardingFlowCalcNewbornRoutines,
          ]
        : [
            l10n.onboardingFlowCalcPercentiles(name),
            l10n.onboardingFlowCalcFeeding,
            l10n.onboardingFlowCalcSleep,
          ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            const OnboardingProgressBar(step: 5),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.screenEdgePadding),
                child: Column(
                  children: [
                    const Spacer(),
                    Text(
                      l10n.onboardingFlowPreparingTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textHeading,
                          ),
                    ),
                    const SizedBox(height: 20),
                    AnimatedBuilder(
                      animation: _progress,
                      builder: (context, _) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: _progress.value.clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: AppTheme.softPrimaryFill,
                            color: AppTheme.primaryBlue,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    for (var i = 0; i < items.length; i++) ...[
                      _CalcRow(label: items[i], done: i < _doneCount),
                      if (i < items.length - 1) const SizedBox(height: 18),
                    ],
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalcRow extends StatelessWidget {
  final String label;
  final bool done;

  const _CalcRow({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: done
                ? const _AnimatedSuccessCheck(key: ValueKey('ok'))
                : const SizedBox(
                    key: ValueKey('load'),
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
        ),
      ],
    );
  }
}

/// Check verde con pop + halo suave al completar cada ítem del cálculo.
class _AnimatedSuccessCheck extends StatefulWidget {
  const _AnimatedSuccessCheck({super.key});

  @override
  State<_AnimatedSuccessCheck> createState() => _AnimatedSuccessCheckState();
}

class _AnimatedSuccessCheckState extends State<_AnimatedSuccessCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _checkOpacity;
  late final Animation<double> _halo;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.35,
          end: 1.18,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.18,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 45,
      ),
    ]).animate(_controller);
    _checkOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.55, curve: Curves.easeOut),
    );
    _halo = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.85, curve: Curves.easeOutCubic),
    );
    HapticFeedback.lightImpact();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final haloT = _halo.value;
        final haloScale = 0.7 + (haloT * 0.9);
        final haloOpacity = (1.0 - haloT) * 0.45;
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (haloOpacity > 0.01)
              Transform.scale(
                scale: haloScale,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryGreen.withValues(alpha: haloOpacity),
                  ),
                ),
              ),
            Transform.scale(
              scale: _scale.value,
              child: Opacity(
                opacity: _checkOpacity.value.clamp(0.0, 1.0),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.primaryGreen,
                  size: 28,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Paso 5 — Resultados
// ─────────────────────────────────────────────────────────────────────────────

class _ResultsStep extends StatelessWidget {
  final OnboardingDraft draft;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const _ResultsStep({
    required this.draft,
    required this.onContinue,
    required this.onBack,
  });

  static String _formatWakeMinutes(int minutes) {
    if (minutes % 60 == 0) return '${minutes ~/ 60} h';
    final h = minutes / 60;
    final s = h.toStringAsFixed(1);
    return '${s.replaceAll('.', ',')} h';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = draft.hasName
        ? draft.displayName
        : l10n.onboardingFlowBabyGeneric;
    final isPregnant = draft.hasBorn == false;
    final isMale = draft.isMale;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final birthDay = DateTime(
      draft.birthDate.year,
      draft.birthDate.month,
      draft.birthDate.day,
    );
    final age = BabyAgeCalendar.monthsAndDaysAt(draft.birthDate, now);
    final ageMonths = BabyAgeCalendar.fractionalMonthsAt(draft.birthDate, now);
    final monthsForSleep = isPregnant ? 0 : (age.months < 0 ? 0 : age.months);
    final ageForCare = isPregnant ? 0.0 : ageMonths;
    final interval = feedingIntervalPresetForAgeMonths(ageForCare);
    final intervalLabel = feedingIntervalOptionLabel(l10n, interval);
    final sleepRule = sleepAgeWakeRuleForMonths(monthsForSleep);
    final wakeMin = sleepRule.wakeWindowsMinutes.reduce(
      (a, b) => a < b ? a : b,
    );
    final wakeMax = sleepRule.wakeWindowsMinutes.reduce(
      (a, b) => a > b ? a : b,
    );
    final wakeRange = wakeMin == wakeMax
        ? _formatWakeMinutes(wakeMin)
        : '${_formatWakeMinutes(wakeMin)}–${_formatWakeMinutes(wakeMax)}';
    final dailySleepRange =
        '${sleepRule.dailySleepHoursMin}–${sleepRule.dailySleepHoursMax} h';
    final care = onboardingAgeCareCopy(
      l10n: l10n,
      ageMonths: ageForCare,
      isPregnant: isPregnant,
      wakeRange: wakeRange,
      dailySleepRange: dailySleepRange,
      intervalLabel: intervalLabel,
    );

    final weightPct = !isPregnant && draft.weightKg != null && ageMonths >= 0
        ? PercentilesData.estimateWeightPercentile(
            isMale: isMale,
            ageInMonths: ageMonths,
            weightKg: draft.weightKg!,
          )
        : null;
    final heightPct = !isPregnant && draft.heightCm != null && ageMonths >= 0
        ? PercentilesData.estimateHeightPercentile(
            isMale: isMale,
            ageInMonths: ageMonths,
            heightCm: draft.heightCm!,
          )
        : null;
    final monthsShown = age.months < 0 ? 0 : age.months;
    final daysLeft = birthDay.difference(today).inDays;
    final dueDateLabel = DateFormat.yMMMMd(
      dateFormatLanguageCode(context),
    ).format(birthDay);

    final ageText = onboardingResultAgeLabel(
      l10n,
      months: monthsShown,
      days: age.days,
    );

    return OnboardingStepScaffold(
      progressStep: 6,
      title: l10n.onboardingFlowResultsTitle(name),
      subtitle: isPregnant
          ? l10n.onboardingFlowResultsSubtitlePregnant
          : l10n.onboardingFlowResultsSubtitle,
      primaryLabel: l10n.onboardingFlowContinue,
      onPrimary: onContinue,
      onBack: onBack,
      child: ListView(
        children: [
          if (isPregnant)
            _ResultHero(
              eyebrow: l10n.onboardingFlowResultDueHeroLabel,
              headline: daysLeft <= 0
                  ? l10n.onboardingFlowResultDueHeroToday
                  : (daysLeft == 1
                        ? l10n.onboardingFlowResultDueHeroOne
                        : l10n.onboardingFlowResultDueHeroDays(daysLeft)),
              caption: l10n.onboardingFlowResultDueDateCaption(dueDateLabel),
              icon: Icons.favorite_rounded,
            )
          else
            _ResultHero(
              eyebrow: l10n.onboardingFlowResultAgeLabel(name),
              headline: ageText,
              caption: null,
              icon: Icons.cake_rounded,
            ),
          const SizedBox(height: 16),
          if (!isPregnant) ...[
            _ResultSectionLabel(l10n.onboardingFlowResultGrowthTitle),
            const SizedBox(height: 10),
            if (draft.weightKg == null && draft.heightCm == null)
              _ResultSoftCard(
                child: Text(
                  l10n.onboardingFlowResultNoWeightHeight,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textLight,
                    height: 1.35,
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _ResultMetric(
                      label: l10n.onboardingFlowResultWeightPct,
                      value:
                          weightPct?.shortLabel() ??
                          l10n.onboardingFlowResultNoWeight,
                      emphasize: weightPct != null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ResultMetric(
                      label: l10n.onboardingFlowResultHeightPct,
                      value:
                          heightPct?.shortLabel() ??
                          l10n.onboardingFlowResultNoHeight,
                      emphasize: heightPct != null,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 10),
            Text(
              l10n.onboardingFlowResultMedicalDisclaimer,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textLight.withValues(alpha: 0.9),
                height: 1.35,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 18),
          ] else ...[
            _ResultSoftCard(
              child: Row(
                children: [
                  Icon(Icons.show_chart_rounded, color: AppTheme.primaryBlue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.onboardingFlowResultWhoPregnant,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.onboardingFlowResultMedicalDisclaimer,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textLight.withValues(alpha: 0.9),
                height: 1.35,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 18),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ResultInsightCard(
                  icon: Icons.schedule_rounded,
                  title: care.feedingTitle,
                  value: care.feedingValue,
                  hint: care.feedingHint,
                  accent: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ResultInsightCard(
                  icon: Icons.bedtime_rounded,
                  title: l10n.onboardingFlowResultSleepTitle,
                  value: care.sleepValue,
                  hint: care.sleepHint,
                  accent: const Color(0xFF5B8FA8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ResultHero extends StatelessWidget {
  final String eyebrow;
  final String headline;
  final String? caption;
  final IconData icon;

  const _ResultHero({
    required this.eyebrow,
    required this.headline,
    required this.caption,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8F1F5), Color(0xFFD7E8F0)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.homeCardRadius),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryBlue, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            eyebrow,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.textHeading,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            headline,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.textHeading,
              height: 1.15,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 8),
            Text(
              caption!,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textLight),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultSectionLabel extends StatelessWidget {
  final String label;
  const _ResultSectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppTheme.textDark,
      ),
    );
  }
}

class _ResultMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const _ResultMetric({
    required this.label,
    required this.value,
    required this.emphasize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: emphasize ? AppTheme.softPrimaryFill : AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: emphasize
              ? AppTheme.primaryBlue.withValues(alpha: 0.25)
              : AppTheme.cardOutline,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTheme.textLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: emphasize ? AppTheme.textHeading : AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultInsightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String hint;
  final Color accent;

  const _ResultInsightCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.hint,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.cardOutline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.textLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textLight,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultSoftCard extends StatelessWidget {
  final Widget child;
  const _ResultSoftCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.softPrimaryFill,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Paso 6 — Notificaciones
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationsStep extends StatelessWidget {
  final OnboardingDraft draft;
  final Future<void> Function() onEnable;
  final VoidCallback onSkip;
  final VoidCallback onBack;

  const _NotificationsStep({
    required this.draft,
    required this.onEnable,
    required this.onSkip,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = draft.hasName
        ? draft.displayName
        : l10n.onboardingFlowBabyGenericYour;
    final ageMonths = BabyAgeCalendar.fractionalMonthsAt(
      draft.birthDate,
      DateTime.now(),
    );
    final timedMilkFeeds = usesTimedMilkFeedReminders(ageMonths);
    final interval = feedingIntervalPresetForAgeMonths(ageMonths);
    final hoursLabel = feedingIntervalOptionLabel(l10n, interval);

    return OnboardingStepScaffold(
      progressStep: 7,
      title: timedMilkFeeds
          ? l10n.onboardingFlowNotifyTitle(name)
          : l10n.onboardingFlowNotifyTitleToddler(name),
      subtitle: timedMilkFeeds
          ? l10n.onboardingFlowNotifySubtitle(hoursLabel)
          : l10n.onboardingFlowNotifySubtitleToddler,
      primaryLabel: l10n.onboardingFlowNotifyEnable,
      onPrimary: () => onEnable(),
      onBack: onBack,
      footer: OnboardingLinkText(
        label: l10n.onboardingFlowNotifyLater,
        onTap: onSkip,
      ),
      child: Center(
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.softPrimaryFill,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.notifications_active_rounded,
            size: 56,
            color: AppTheme.primaryBlue,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Paso 7 — Guardar cuenta
// ─────────────────────────────────────────────────────────────────────────────

class _SaveAccountStep extends StatelessWidget {
  final OnboardingDraft draft;
  final bool loading;
  final Future<void> Function() onApple;
  final Future<void> Function() onGoogle;
  final Future<void> Function() onEmail;
  final VoidCallback onBack;

  const _SaveAccountStep({
    required this.draft,
    required this.loading,
    required this.onApple,
    required this.onGoogle,
    required this.onEmail,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = draft.hasName
        ? draft.displayName
        : l10n.onboardingFlowBabyGenericYour;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const OnboardingProgressBar(step: 8),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppTheme.screenEdgePadding,
                  4,
                  AppTheme.screenEdgePadding,
                  AppTheme.safeBottomPadding(context) +
                      AppTheme.screenEdgePadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: loading ? null : onBack,
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.onboardingFlowSaveTitle(name),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textHeading,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.onboardingFlowSaveSubtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textLight,
                      ),
                    ),
                    const Spacer(),
                    _AuthButton(
                      onPressed: loading ? null : onApple,
                      background: Colors.black,
                      foreground: Colors.white,
                      icon: const Icon(
                        Icons.apple,
                        size: 24,
                        color: Colors.white,
                      ),
                      label: l10n.onboardingFlowContinueApple,
                    ),
                    const SizedBox(height: 12),
                    _AuthButton(
                      onPressed: loading ? null : onGoogle,
                      background: Colors.white,
                      foreground: Colors.black87,
                      border: true,
                      icon: SvgPicture.asset(
                        'assets/images/google_logo.svg',
                        width: 20,
                        height: 20,
                      ),
                      label: l10n.onboardingFlowContinueGoogle,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: loading ? null : () => onEmail(),
                      child: Text(
                        l10n.onboardingFlowContinueEmail,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationColor: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                    if (loading) ...[
                      const SizedBox(height: 12),
                      const Center(child: CircularProgressIndicator()),
                    ],
                    const Spacer(),
                    Text(
                      l10n.onboardingFlowDataSafe,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textLight,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () =>
                              _openLegalUrl(RevenueCatConfig.termsUrl),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            l10n.paywallTerms,
                            style: const TextStyle(
                              color: AppTheme.textLight,
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const Text(
                          '·',
                          style: TextStyle(color: AppTheme.textLight),
                        ),
                        TextButton(
                          onPressed: () =>
                              _openLegalUrl(RevenueCatConfig.privacyUrl),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openLegalUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _AuthButton extends StatelessWidget {
  final Future<void> Function()? onPressed;
  final Color background;
  final Color foreground;
  final Widget icon;
  final String label;
  final bool border;

  const _AuthButton({
    required this.onPressed,
    required this.background,
    required this.foreground,
    required this.icon,
    required this.label,
    this.border = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onPressed == null ? null : () => onPressed!(),
        icon: icon,
        label: Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w700, color: foreground),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          elevation: 0,
          side: border
              ? const BorderSide(color: Color(0xFFE0E0E0))
              : BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          ),
        ),
      ),
    );
  }
}
