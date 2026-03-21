import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../core/db/isar_service.dart';
import '../../../core/providers/record_stream_providers.dart';
import '../../../core/services/next_feeding_notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../settings/views/settings_page.dart';
import 'home_view.dart';
import '../../diapers/views/diapers_view.dart';
import '../../feeding/views/feeding_view.dart';
import '../../weight/views/weight_view.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _currentIndex = 0;
  final _homeScrollController = ScrollController();
  final _diapersScrollController = ScrollController();
  final _feedingScrollController = ScrollController();
  final _weightScrollController = ScrollController();

  static const _scrollTopDuration = Duration(milliseconds: 300);
  static const _scrollTopCurve = Curves.easeOut;

  @override
  void dispose() {
    _homeScrollController.dispose();
    _diapersScrollController.dispose();
    _feedingScrollController.dispose();
    _weightScrollController.dispose();
    super.dispose();
  }

  void _scrollHomeToTop({required bool animated}) {
    if (!_homeScrollController.hasClients) return;
    if (animated) {
      _homeScrollController.animateTo(
        0,
        duration: _scrollTopDuration,
        curve: _scrollTopCurve,
      );
    } else {
      _homeScrollController.jumpTo(0);
    }
  }

  void _goHome() {
    if (_currentIndex == 0) {
      _scrollHomeToTop(animated: true);
    } else {
      setState(() => _currentIndex = 0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollHomeToTop(animated: false);
      });
    }
  }

  void _onTabTap(int index) {
    if (index == _currentIndex) {
      switch (index) {
        case 0:
          _scrollHomeToTop(animated: true);
          break;
        case 1:
          _diapersScrollController.animateTo(
            0,
            duration: _scrollTopDuration,
            curve: _scrollTopCurve,
          );
          break;
        case 2:
          _feedingScrollController.animateTo(
            0,
            duration: _scrollTopDuration,
            curve: _scrollTopCurve,
          );
          break;
        case 3:
          _weightScrollController.animateTo(
            0,
            duration: _scrollTopDuration,
            curve: _scrollTopCurve,
          );
          break;
      }
      return;
    }
    if (index == 0) {
      setState(() => _currentIndex = 0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollHomeToTop(animated: false);
      });
      return;
    }
    setState(() => _currentIndex = index);
  }

  Future<void> _openSettings() async {
    final baby = await IsarService.getBabyProfile();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SettingsPage(initialBaby: baby)),
    );
    if (!mounted) return;
    ref.invalidate(weightRecordsStreamProvider);
    ref.invalidate(diaperRecordsStreamProvider);
    ref.invalidate(feedingRecordsStreamProvider);
    await NextFeedingNotificationService.syncFromStorage();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeView(
        scrollController: _homeScrollController,
        onNavigateToTab: (i) => setState(() => _currentIndex = i),
        onTitleTap: _goHome,
        isActiveTab: _currentIndex == 0,
      ),
      DiapersView(
        onTitleTap: _goHome,
        onSettingsTap: _openSettings,
        scrollController: _diapersScrollController,
      ),
      FeedingView(
        onTitleTap: _goHome,
        onSettingsTap: _openSettings,
        scrollController: _feedingScrollController,
      ),
      WeightView(
        onTitleTap: _goHome,
        onSettingsTap: _openSettings,
        scrollController: _weightScrollController,
      ),
    ];
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Material(
        elevation: 12,
        shadowColor: Colors.black26,
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Container(
            decoration: const BoxDecoration(color: AppTheme.cardBackground),
            // top: false — el inset superior es para el notch/status; no aplica a la barra inferior.
            child: SafeArea(
              top: false,
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 4,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _NavItem(
                        icon: Icons.home_rounded,
                        activeIcon: Icons.home_rounded,
                        label: 'INICIO',
                        isSelected: _currentIndex == 0,
                        selectedBackground: AppTheme.navHomeSelectedFill,
                        selectedForeground: AppTheme.navHomeSelectedFg,
                        onTap: () => _onTabTap(0),
                      ),
                    ),
                    Expanded(
                      child: _NavItem(
                        icon: MdiIcons.humanBabyChangingTable,
                        activeIcon: MdiIcons.humanBabyChangingTable,
                        label: 'PAÑALES',
                        isSelected: _currentIndex == 1,
                        selectedBackground: AppTheme.navDiapersSelectedFill,
                        selectedForeground: AppTheme.navDiapersSelectedFg,
                        onTap: () => _onTabTap(1),
                      ),
                    ),
                    Expanded(
                      child: _NavItem(
                        fontAwesomeIcon: FontAwesomeIcons.utensils,
                        label: 'ALIMENTACIÓN',
                        isSelected: _currentIndex == 2,
                        selectedBackground: AppTheme.navFeedingSelectedFill,
                        selectedForeground: AppTheme.navFeedingSelectedFg,
                        onTap: () => _onTabTap(2),
                      ),
                    ),
                    Expanded(
                      child: _NavItem(
                        icon: Icons.monitor_weight_rounded,
                        activeIcon: Icons.monitor_weight_rounded,
                        label: 'PESO',
                        isSelected: _currentIndex == 3,
                        selectedBackground: AppTheme.navWeightSelectedFill,
                        selectedForeground: AppTheme.navWeightSelectedFg,
                        onTap: () => _onTabTap(3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Alimentación (Font Awesome): tamaño de referencia, algo menor que Material/MDI.
const double _kBottomNavIconSizeFa = 24;

/// Inicio, pañales y peso ([Icon] / MDI).
const double _kBottomNavIconSizeMaterial = 30;

/// Misma altura de cápsula en las cuatro pestañas (hueco repartido por [Expanded]).
const double _kNavPillHeight = 64;

class _NavItem extends StatelessWidget {
  final IconData? icon;
  final IconData? activeIcon;
  final IconData? fontAwesomeIcon;
  final String label;
  final bool isSelected;
  final Color selectedBackground;
  final Color selectedForeground;
  final VoidCallback onTap;

  const _NavItem({
    this.icon,
    this.activeIcon,
    this.fontAwesomeIcon,
    required this.label,
    required this.isSelected,
    required this.selectedBackground,
    required this.selectedForeground,
    required this.onTap,
  }) : assert(
         (fontAwesomeIcon != null && icon == null && activeIcon == null) ||
             (fontAwesomeIcon == null && icon != null && activeIcon != null),
       );

  @override
  Widget build(BuildContext context) {
    final inactiveColor = AppTheme.textLight;
    final iconColor = isSelected ? selectedForeground : inactiveColor;
    final pillRadius = BorderRadius.circular(999);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: pillRadius,
        splashColor: isSelected
            ? selectedForeground.withValues(alpha: 0.14)
            : AppTheme.textLight.withValues(alpha: 0.2),
        highlightColor: isSelected
            ? selectedForeground.withValues(alpha: 0.08)
            : AppTheme.textLight.withValues(alpha: 0.12),
        child: Container(
          width: double.infinity,
          height: _kNavPillHeight,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? selectedBackground : Colors.transparent,
            borderRadius: pillRadius,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              fontAwesomeIcon != null
                  ? FaIcon(
                      fontAwesomeIcon,
                      size: _kBottomNavIconSizeFa,
                      color: iconColor,
                    )
                  : Icon(
                      isSelected ? activeIcon! : icon!,
                      size: _kBottomNavIconSizeMaterial,
                      color: iconColor,
                    ),
              const SizedBox(height: 1),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  letterSpacing: 0.35,
                  height: 1.05,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? selectedForeground : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
