import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/presentation/providers/resource_provider.dart';
import 'package:kingdomcome/presentation/widgets/common/resource_badge.dart';

/// Main scaffold shell that wraps all 5-tab navigation branches.
///
/// Renders:
/// - A resource HUD at the top (FaithCoins + HolyPoints)
/// - A medieval-styled bottom nav bar with gold active state and glow
/// - The [StatefulNavigationShell] page content
class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  static const _tabs = [
    _NavTab(
      label: 'The Ark',
      icon: Icons.sailing_outlined,
      activeIcon: Icons.sailing,
      path: '/ark',
    ),
    _NavTab(
      label: 'Kingdom',
      icon: Icons.castle_outlined,
      activeIcon: Icons.castle,
      path: '/kingdom',
    ),
    _NavTab(
      label: 'Academy',
      icon: Icons.sports_esports_outlined,
      activeIcon: Icons.sports_esports,
      path: '/academy',
    ),
    _NavTab(
      label: 'Workshop',
      icon: Icons.palette_outlined,
      activeIcon: Icons.palette,
      path: '/workshop',
    ),
    _NavTab(
      label: 'My Soul',
      icon: Icons.self_improvement_outlined,
      activeIcon: Icons.self_improvement,
      path: '/soul',
    ),
  ];

  void _onTabTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = navigationShell.currentIndex;

    return Scaffold(
      body: Column(
        children: [
          // Resource HUD at top
          const _ResourceHud(),
          // Page content
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: _MedievalNavBar(
        tabs: _tabs,
        selectedIndex: selectedIndex,
        onTabTap: (i) => _onTabTap(context, i),
      ),
    );
  }
}

// ── Resource HUD ──────────────────────────────────────────────────────────────

class _ResourceHud extends ConsumerWidget {
  const _ResourceHud();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resources = ref.watch(resourceNotifierProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.purpleDark, AppColors.deepPurple],
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.goldDark, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs + 2,
          ),
          child: resources.when(
            loading: () => const SizedBox(height: 34),
            error: (_, __) => const SizedBox(height: 34),
            data: (res) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ResourceBadge(
                  type: ResourceBadgeType.faithCoins,
                  value: res.faithCoins,
                ),
                _HudDivider(),
                ResourceBadge(
                  type: ResourceBadgeType.holyPoints,
                  value: res.holyPoints,
                ),
                _HudDivider(),
                ResourceBadge(
                  type: ResourceBadgeType.grace,
                  value: res.grace,
                ),
                _HudDivider(),
                ResourceBadge(
                  type: ResourceBadgeType.blessings,
                  value: res.blessings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HudDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 20,
      color: AppColors.goldDark.withOpacity(0.4),
    );
  }
}

// ── Bottom Nav Bar ────────────────────────────────────────────────────────────

class _MedievalNavBar extends StatelessWidget {
  final List<_NavTab> tabs;
  final int selectedIndex;
  final void Function(int) onTabTap;

  const _MedievalNavBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onTabTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.purpleDark,
        border: const Border(
          top: BorderSide(color: AppColors.goldDark, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
            spreadRadius: 2,
          ),
          const BoxShadow(
            color: Color(0x50000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(tabs.length, (i) {
              final isSelected = i == selectedIndex;
              // Center tab (The Kingdom, index 1) is slightly larger + elevated
              final isHeroTab = i == 1;

              return Expanded(
                child: _NavItem(
                  tab: tabs[i],
                  isSelected: isSelected,
                  isHeroTab: isHeroTab,
                  onTap: () => onTabTap(i),
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
  final _NavTab tab;
  final bool isSelected;
  final bool isHeroTab;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.isSelected,
    required this.isHeroTab,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double iconSize = isHeroTab ? 28 : 22;
    final double containerSize = isHeroTab ? 52 : 40;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          vertical: isHeroTab ? 4 : 6,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container with glow/elevation for active state
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: containerSize,
              height: containerSize,
              decoration: isSelected
                  ? BoxDecoration(
                      color: AppColors.gold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(
                          isHeroTab ? AppSpacing.radiusMd : AppSpacing.radiusSm),
                      border: Border.all(
                        color: AppColors.gold.withOpacity(0.5),
                        width: isHeroTab ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withOpacity(0.35),
                          blurRadius: isHeroTab ? 16 : 10,
                          spreadRadius: isHeroTab ? 2 : 1,
                        ),
                      ],
                    )
                  : null,
              child: Center(
                child: Icon(
                  isSelected ? tab.activeIcon : tab.icon,
                  color: isSelected
                      ? AppColors.gold
                      : AppColors.parchmentDark.withOpacity(0.6),
                  size: iconSize,
                ),
              ),
            ),
            const SizedBox(height: 3),
            // Label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected
                    ? AppColors.goldLight
                    : AppColors.midGrey,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w400,
                fontSize: isHeroTab ? 11 : 9,
                letterSpacing: isHeroTab ? 0.5 : 0.3,
                shadows: isSelected
                    ? [
                        Shadow(
                          blurRadius: 6,
                          color: AppColors.gold.withOpacity(0.5),
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      )
          .animate(target: isSelected ? 1 : 0)
          .scaleXY(begin: 1.0, end: isHeroTab ? 1.04 : 1.02, duration: 200.ms),
    );
  }
}

class _NavTab {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String path;

  const _NavTab({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.path,
  });
}
