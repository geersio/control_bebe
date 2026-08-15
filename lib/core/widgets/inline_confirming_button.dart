import 'dart:async';
import 'dart:math' as math;

import 'package:control_bebe/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

enum InlineSavePhase { idle, loading, saved }

class InlineConfirmingButton extends StatefulWidget {
  final FutureOr<bool> Function() onPressed;
  final Widget child;
  final ButtonStyle? style;
  /// Se invoca al entrar en la fase «Guardado» (verde + check), antes de volver a idle.
  final VoidCallback? onSavedVisible;
  final VoidCallback? onSaved;
  final Duration minimumLoadingDuration;
  final Duration savedDuration;

  const InlineConfirmingButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.onSavedVisible,
    this.onSaved,
    this.minimumLoadingDuration = const Duration(milliseconds: 750),
    this.savedDuration = const Duration(milliseconds: 1200),
  });

  @override
  State<InlineConfirmingButton> createState() => _InlineConfirmingButtonState();
}

class _InlineConfirmingButtonState extends State<InlineConfirmingButton> {
  InlineSavePhase _phase = InlineSavePhase.idle;

  Future<void> _handlePressed() async {
    if (_phase != InlineSavePhase.idle) return;

    HapticFeedback.lightImpact();
    setState(() => _phase = InlineSavePhase.loading);

    final startedAt = DateTime.now();
    bool saved;
    try {
      saved = await widget.onPressed();
    } catch (_) {
      if (mounted) setState(() => _phase = InlineSavePhase.idle);
      rethrow;
    }

    final elapsed = DateTime.now().difference(startedAt);
    final remaining = widget.minimumLoadingDuration - elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
    if (!mounted) return;

    if (!saved) {
      setState(() => _phase = InlineSavePhase.idle);
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _phase = InlineSavePhase.saved);
    widget.onSavedVisible?.call();

    await Future<void>.delayed(widget.savedDuration);
    widget.onSaved?.call();
    if (mounted) setState(() => _phase = InlineSavePhase.idle);
  }

  ButtonStyle _styleForPhase(BuildContext context) {
    final base =
        widget.style ??
        Theme.of(context).elevatedButtonTheme.style ??
        ElevatedButton.styleFrom();
    if (_phase != InlineSavePhase.saved) return base;
    return base.copyWith(
      backgroundColor: WidgetStateProperty.all(AppTheme.primaryGreen),
      foregroundColor: WidgetStateProperty.all(Colors.white),
      overlayColor: WidgetStateProperty.all(
        Colors.white.withValues(alpha: 0.12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ElevatedButton(
      onPressed: _handlePressed,
      style: _styleForPhase(context).copyWith(
        animationDuration: const Duration(milliseconds: 280),
      ),
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
        child: switch (_phase) {
          InlineSavePhase.idle => KeyedSubtree(
            key: const ValueKey(InlineSavePhase.idle),
            child: widget.child,
          ),
          InlineSavePhase.loading => const _InlineButtonContent(
            key: ValueKey(InlineSavePhase.loading),
            child: SoftSpinner(),
          ),
          InlineSavePhase.saved => _InlineButtonContent(
            key: const ValueKey(InlineSavePhase.saved),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, size: 22),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.commonSaved,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        },
      ),
    );
  }
}

class _InlineButtonContent extends StatelessWidget {
  final Widget child;

  const _InlineButtonContent({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 24, child: Center(child: child));
  }
}

class SoftSpinner extends StatefulWidget {
  final Color? color;

  const SoftSpinner({super.key, this.color});

  @override
  State<SoftSpinner> createState() => _SoftSpinnerState();
}

class _SoftSpinnerState extends State<SoftSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.color ??
        IconTheme.of(context).color ??
        DefaultTextStyle.of(context).style.color ??
        Colors.white;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final scale = 0.92 + (0.16 * (0.5 + 0.5 * math.sin(t * math.pi * 2)));
        return Transform.rotate(
          angle: t * math.pi * 2,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          strokeCap: StrokeCap.round,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}
