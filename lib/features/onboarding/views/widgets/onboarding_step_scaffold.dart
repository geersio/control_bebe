import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Número total de pasos del onboarding (0…8).
const int kOnboardingTotalSteps = 9;

/// Barra fina de progreso del onboarding.
class OnboardingProgressBar extends StatelessWidget {
  final int step;
  final int totalSteps;

  const OnboardingProgressBar({
    super.key,
    required this.step,
    this.totalSteps = kOnboardingTotalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final value = ((step + 1) / totalSteps).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.screenEdgePadding,
        4,
        AppTheme.screenEdgePadding,
        0,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: value,
          minHeight: 3,
          backgroundColor: AppTheme.softPrimaryFill,
          color: AppTheme.primaryBlue,
        ),
      ),
    );
  }
}

/// Layout común de cada paso del onboarding: título, subtítulo, cuerpo y CTA.
class OnboardingStepScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onBack;
  final Widget? footer;
  final bool primaryLoading;
  final bool showPrimary;
  final int progressStep;

  const OnboardingStepScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.primaryLabel,
    required this.progressStep,
    this.onPrimary,
    this.onBack,
    this.footer,
    this.primaryLoading = false,
    this.showPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = AppTheme.safeBottomPadding(context);
    final hasPrimary = showPrimary && primaryLabel != null;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OnboardingProgressBar(step: progressStep),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.screenEdgePadding,
                4,
                AppTheme.screenEdgePadding,
                0,
              ),
              child: Row(
                children: [
                  if (onBack != null)
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: AppTheme.textDark,
                    )
                  else
                    const SizedBox(width: 48, height: 48),
                  const Spacer(),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.screenEdgePadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textHeading,
                            height: 1.2,
                          ),
                    ),
                    if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textLight,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    Expanded(child: child),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppTheme.screenEdgePadding,
                8,
                AppTheme.screenEdgePadding,
                bottom + AppTheme.screenEdgePadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (hasPrimary)
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: primaryLoading ? null : onPrimary,
                        child: primaryLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                primaryLabel!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  if (footer != null) ...[
                    if (hasPrimary) const SizedBox(height: 14),
                    footer!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingBigOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  /// Chevron a la derecha cuando no está seleccionado. Se oculta al elegir otra opción.
  final bool showChevron;

  const OnboardingBigOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasIcon = icon != null;
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: hasIcon ? 20 : 18,
            vertical: hasIcon ? 26 : 18,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.softPrimaryFill
                : AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(
              color: selected
                  ? AppTheme.primaryBlue.withValues(alpha: 0.35)
                  : AppTheme.cardOutline,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              if (hasIcon) ...[
                Icon(
                  icon,
                  size: 28,
                  color: selected ? AppTheme.primaryBlue : AppTheme.textLight,
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.start,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                    color: selected
                        ? AppTheme.primaryBlue
                        : AppTheme.textDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 24,
                height: 24,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    );
                  },
                  child: selected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          key: ValueKey('check'),
                          color: AppTheme.primaryBlue,
                          size: 22,
                        )
                      : showChevron
                      ? Icon(
                          Icons.chevron_right_rounded,
                          key: const ValueKey('chevron'),
                          color: AppTheme.textLight,
                          size: 24,
                        )
                      : const SizedBox.shrink(key: ValueKey('empty')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingLinkText extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const OnboardingLinkText({
    super.key,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.primaryBlue,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: AppTheme.primaryBlue,
        ),
      ),
    );
  }
}
