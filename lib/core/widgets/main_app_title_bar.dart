import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../theme/app_theme.dart';

/// Cabecera común: icono de la app, título centrado y ajustes (misma altura que [kToolbarHeight]).
class MainAppTitleBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onTitleTap;
  final VoidCallback onSettingsTap;

  const MainAppTitleBar({
    super.key,
    this.onTitleTap,
    required this.onSettingsTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppTheme.textHeading,
        );
    final titleRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          AppTheme.titleIconAsset,
          width: 34,
          height: 34,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Icon(
            Icons.child_care_rounded,
            size: 34,
            color: AppTheme.palettePrimary,
          ),
        ),
        const SizedBox(width: 12),
        Text('MiBebé Diario', style: titleStyle),
      ],
    );

    return SizedBox(
      height: kToolbarHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.screenEdgePadding),
        child: Row(
          children: [
            const SizedBox(width: 48),
            Expanded(
              child: Center(
                child: onTitleTap != null
                    ? Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onTitleTap,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                            child: titleRow,
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: titleRow,
                      ),
              ),
            ),
            IconButton(
              onPressed: onSettingsTap,
              style: IconButton.styleFrom(
                foregroundColor: AppTheme.textHeading,
                minimumSize: const Size(48, 48),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: FaIcon(
                FontAwesomeIcons.gear,
                size: 22,
                color: AppTheme.textHeading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
