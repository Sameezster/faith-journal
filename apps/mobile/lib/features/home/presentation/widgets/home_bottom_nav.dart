import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_text_styles.dart';

/// One bottom-nav destination.
class NavDestination {
  const NavDestination({required this.label, this.icon, this.imageIcon});

  final String label;
  final IconData? icon;
  final String? imageIcon; // for the praying-hands png

  static const items = <NavDestination>[
    NavDestination(label: 'Home', icon: AppIcons.home),
    NavDestination(label: 'Bible', icon: AppIcons.bible),
    NavDestination(label: 'Journal', icon: AppIcons.journal),
    NavDestination(label: 'Prayer', imageIcon: AppAssets.navPray),
    NavDestination(label: 'Profile', icon: AppIcons.profile),
  ];
}

/// Bottom navigation bar.
///
/// Per design: the icon colour stays constant for every tab. Only the active
/// tab's *label* turns gold and gains a short underline — the icon never
/// changes colour.
class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const Color _iconColor = AppColors.navy;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: List.generate(NavDestination.items.length, (i) {
              return Expanded(
                child: _NavItem(
                  data: NavDestination.items[i],
                  active: i == currentIndex,
                  onTap: () => onTap(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.data,
    required this.active,
    required this.onTap,
  });

  final NavDestination data;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconWidget = data.imageIcon != null
        ? ImageIcon(
            AssetImage(data.imageIcon!),
            size: 24,
            color: HomeBottomNav._iconColor,
          )
        : Icon(data.icon, size: 24, color: HomeBottomNav._iconColor);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconWidget,
          const SizedBox(height: 4),
          Text(
            data.label,
            style: active
                ? AppTextStyles.navLabel.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w600,
                  )
                : AppTextStyles.navLabel,
          ),
          const SizedBox(height: 3),
          // Underline only under the active label.
          Container(
            height: 2,
            width: 18,
            decoration: BoxDecoration(
              color: active ? AppColors.gold : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
