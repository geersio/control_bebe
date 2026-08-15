import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AppToastVariant { info, warning }

/// Aviso flotante breve (funciona sobre diálogos y pantallas normales).
class AppToast {
  AppToast._();

  static OverlayEntry? _entry;
  static Timer? _hideTimer;

  static void show(
    BuildContext context, {
    required String message,
    AppToastVariant variant = AppToastVariant.info,
  }) {
    _dismiss();
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _entry = OverlayEntry(
      builder: (ctx) => _ToastOverlay(
        message: message,
        variant: variant,
        onDismiss: _dismiss,
      ),
    );
    overlay.insert(_entry!);
    _hideTimer = Timer(const Duration(milliseconds: 2600), _dismiss);
  }

  static void _dismiss() {
    _hideTimer?.cancel();
    _hideTimer = null;
    _entry?.remove();
    _entry = null;
  }
}

class _ToastOverlay extends StatefulWidget {
  const _ToastOverlay({
    required this.message,
    required this.variant,
    required this.onDismiss,
  });

  final String message;
  final AppToastVariant variant;
  final VoidCallback onDismiss;

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    reverseDuration: const Duration(milliseconds: 200),
  );

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.12),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final keyboardVisible = mq.viewInsets.bottom > 48;
    final accent = widget.variant == AppToastVariant.warning
        ? AppTheme.primaryOrange
        : AppTheme.palettePrimary;
    final icon = widget.variant == AppToastVariant.warning
        ? Icons.tune_rounded
        : Icons.info_outline_rounded;

    final toast = SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Material(
            color: Colors.transparent,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.cardOutline),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A2D6583),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(icon, size: 20, color: accent),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onDismiss,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppTheme.textLight.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    );

    final horizontal = AppTheme.screenEdgePadding;
    if (keyboardVisible) {
      return Positioned(
        top: mq.padding.top + 12,
        left: horizontal,
        right: horizontal,
        child: toast,
      );
    }
    return Positioned(
      left: horizontal,
      right: horizontal,
      bottom: mq.padding.bottom + 20,
      child: toast,
    );
  }
}
