import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Botón «i» unificado para cabeceras de tarjetas del home / insights.
///
/// Icono fijo (tamaño/color) sin [IconButton], para que no herede temas
/// distintos según el árbol de widgets.
class CardInfoButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback onPressed;

  static const double iconSize = 16;
  static const double tapWidth = 24;
  static const double tapHeight = 18;
  static const IconData icon = Icons.info_outline_rounded;
  static const Color color = AppTheme.textLight;

  const CardInfoButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onPressed,
          behavior: HitTestBehavior.opaque,
          child: const SizedBox(
            width: tapWidth,
            height: tapHeight,
            child: Center(
              child: ExcludeSemantics(
                child: Icon(icon, size: iconSize, color: color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
