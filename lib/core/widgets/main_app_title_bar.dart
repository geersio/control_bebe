import 'package:control_bebe/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../theme/app_theme.dart';

/// Gradiente sobre el contenido justo debajo de la cabecera ([MainAppTitleBar.totalHeight]).
/// Va en un [Stack] con [clipBehavior: Clip.hardEdge], detrás del header posicionado.
class TitleBarScrollFade extends StatelessWidget {
  const TitleBarScrollFade({super.key});

  static const double _fadeHeight = 28;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MainAppTitleBar.totalHeight,
      left: 0,
      right: 0,
      height: _fadeHeight,
      child: const IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.background,
                Color(0x00F7F9F9),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Cabecera común: título centrado y ajustes.
/// Altura [totalHeight] (= [kToolbarHeight]) para alinear padding del scroll y el fade.
class MainAppTitleBar extends StatelessWidget implements PreferredSizeWidget {
  /// Misma altura que la barra; útil con [Stack] + scroll a pantalla completa.
  static const double totalHeight = kToolbarHeight;

  final VoidCallback? onTitleTap;
  final VoidCallback onSettingsTap;

  const MainAppTitleBar({
    super.key,
    this.onTitleTap,
    required this.onSettingsTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(totalHeight);

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppTheme.textHeading,
        );
    final title = Text(
      AppLocalizations.of(context)!.appTitle,
      style: titleStyle,
    );

    return ClipRect(
      child: ColoredBox(
        color: AppTheme.background,
        child: SizedBox(
          height: kToolbarHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.screenEdgePadding,
            ),
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 8,
                                ),
                                child: title,
                              ),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: title,
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
        ),
      ),
    );
  }
}
