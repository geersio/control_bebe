import 'package:flutter/material.dart';

/// Entrada de una ficha del historial: despliegue, deslizamiento y tinte.
class HistoryEntryReveal extends StatefulWidget {
  final bool highlighted;
  final Color accentColor;
  final Widget child;

  const HistoryEntryReveal({
    super.key,
    required this.highlighted,
    required this.accentColor,
    required this.child,
  });

  @override
  State<HistoryEntryReveal> createState() => _HistoryEntryRevealState();
}

class _HistoryEntryRevealState extends State<HistoryEntryReveal>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 1400);

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    if (widget.highlighted) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant HistoryEntryReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.highlighted && widget.highlighted) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _interval(double t, double end) {
    if (t >= end) return 1;
    return Curves.easeOutCubic.transform((t / end).clamp(0.0, 1.0));
  }

  double _highlightStrength(double t) {
    if (t < 0.25) {
      return Curves.easeOut.transform((t / 0.25).clamp(0.0, 1.0));
    }
    return Curves.easeIn.transform(((1 - t) / 0.75).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isCompleted) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final tile = child ?? widget.child;
        final t = _controller.value;
        final sizeT = _interval(t, 0.42);
        final fadeT = Curves.easeOut.transform((t / 0.35).clamp(0.0, 1.0));
        final slidePx = (1 - _interval(t, 0.4)) * 14;
        final highlightT = _highlightStrength(t);

        final tintedChild = highlightT > 0.01
            ? ColorFiltered(
                colorFilter: ColorFilter.mode(
                  widget.accentColor.withValues(alpha: 0.14 * highlightT),
                  BlendMode.srcATop,
                ),
                child: tile,
              )
            : tile;

        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: sizeT.clamp(0.001, 1.0),
            child: Transform.translate(
              offset: Offset(0, slidePx),
              child: Opacity(
                opacity: fadeT.clamp(0.0, 1.0),
                child: tintedChild,
              ),
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
