import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'card_info_button.dart';

/// Cabecera de pastilla Home: título en versalitas + «i», con hueco uniforme
/// hacia el contenido ([gapAfter] por defecto 8).
class HomeCardTitleRow extends StatelessWidget {
  static const double gapAfter = 8;

  final String title;
  final String infoTooltip;
  final VoidCallback onInfoPressed;
  final Widget? trailingBeforeInfo;

  const HomeCardTitleRow({
    super.key,
    required this.title,
    required this.infoTooltip,
    required this.onInfoPressed,
    this.trailingBeforeInfo,
  });

  static TextStyle? titleStyle(BuildContext context) =>
      Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppTheme.textDark,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
        height: 1.2,
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: titleStyle(context),
          ),
        ),
        if (trailingBeforeInfo != null) ...[
          trailingBeforeInfo!,
          const SizedBox(width: 8),
        ],
        CardInfoButton(
          tooltip: infoTooltip,
          onPressed: onInfoPressed,
        ),
      ],
    );
  }
}
