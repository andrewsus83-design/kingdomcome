import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/presentation/providers/resource_provider.dart';
import 'package:kingdomcome/presentation/widgets/common/resource_badge.dart';

/// Persistent shell scaffold with bottom nav and resource HUD.
class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        children: [
          // Resource HUD at top
          const _ResourceHud(),
          // Page content
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: const _MedievalNavBar(),
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
          colors: [AppColors.purpleDark, AppColors.deepPurple],
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.goldDark, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: resources.when(
            loading: () => const SizedBox(height: 32),
            error: (_, __) => const SizedBox(height: 32),
            data: (res) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ResourceBadge(
                  type: ResourceBadgeType.holyPoints,
                  value: res.holyPoints,
                ),
                ResourceBadge(
                  type: ResourceBadgeType.faithCoins,
                  value: res.faithCoins,
                ),
                ResourceBadge(
                  type: ResourceBadgeType.grace,
                  value: res.grace,
                ),
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

// ── Bottom Navigation Bar ─────────────────────────────────────────────────────

class _MedievalNavBar extends ConsumerWidget {
  const _MedievalNavBar();

  static const _tabs = [
    _NavTab(label: 'Kingdom', icon: Icons.castle_outlined, activeIcon: Icons.castle, path: '/kingdom'),
    _NavTab(label: 'Quests', icon: Icons.assignment_outlined, activeIcon: Icons.assignment, path: '/quests'),
    _NavTab(label: 'Learn', icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book, path: '/learn'),
    _NavTab(label: 'Saints', icon: Icons.star_outline, activeIcon: Icons.star, path: '/saints'),
    _NavTab(label: 'Profile', icon: Icons.person_outline, activeIcon: Icons.person, path: '/profile'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _tabs.indexWhere(
      (t) => location.startsWith(t.path),
    ).clamp(0, _tabs.length - 1);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.purpleDark,
        border: Border(top: BorderSide(color: AppColors.goldDark, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_tabs.length, (i) {
              final tab = _tabs[i];
              final isSelected = i == selectedIndex;
              return _NavItem(
                tab: tab,
                isSelected: isSelected,
                onTap: () => context.go(tab.path),
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
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: isSelected
                  ? BoxDecoration(
                      color: AppColors.gold.withOpacity(0.15),
                      borderRadius: AppSpacing.borderRadiusSm,
                    )
                  : null,
              child: Icon(
                isSelected ? tab.activeIcon : tab.icon,
                color: isSelected ? AppColors.gold : AppColors.midGrey,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              tab.label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? AppColors.gold : AppColors.midGrey,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
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
