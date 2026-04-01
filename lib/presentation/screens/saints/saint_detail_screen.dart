import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/data/models/saint/saint_model.dart';
import 'package:kingdomcome/presentation/providers/saint_provider.dart';
import 'package:kingdomcome/presentation/providers/resource_provider.dart';
import 'package:kingdomcome/presentation/widgets/common/kingdom_button.dart';

class SaintDetailScreen extends ConsumerStatefulWidget {
  final String saintId;
  const SaintDetailScreen({super.key, required this.saintId});

  @override
  ConsumerState<SaintDetailScreen> createState() => _SaintDetailScreenState();
}

class _SaintDetailScreenState extends ConsumerState<SaintDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showFullBio = false;
  bool _isUnlocking = false;
  bool _isActivating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saintsAsync = ref.watch(saintNotifierProvider);
    final unlockedIds = ref.watch(unlockedSaintIdsProvider);
    final activeSaint = ref.watch(activeSaintProvider);

    return saintsAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.darkSurface,
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text(e.toString())),
      ),
      data: (saints) {
        final saint =
            saints.where((s) => s.id == widget.saintId).firstOrNull;
        if (saint == null) {
          return const Scaffold(
            body: Center(
                child: Text('Saint not found.',
                    style: TextStyle(color: AppColors.ivory))),
          );
        }

        final isUnlocked = unlockedIds.contains(saint.id);
        final isActive = activeSaint?.saintId == saint.id;

        return _SaintDetailView(
          saint: saint,
          isUnlocked: isUnlocked,
          isActive: isActive,
          tabController: _tabController,
          showFullBio: _showFullBio,
          isUnlocking: _isUnlocking,
          isActivating: _isActivating,
          onToggleBio: () => setState(() => _showFullBio = !_showFullBio),
          onUnlock: () => _unlock(saint),
          onSetGuardian: () => _setGuardian(saint),
          onActivateAbility: () => _activateAbility(saint),
        );
      },
    );
  }

  Future<void> _unlock(SaintModel saint) async {
    setState(() => _isUnlocking = true);
    try {
      await ref.read(saintNotifierProvider.notifier).unlockSaint(saint.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${saint.name} unlocked!'),
            backgroundColor: AppColors.forestGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not unlock saint: $e'),
            backgroundColor: AppColors.crimson,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUnlocking = false);
    }
  }

  Future<void> _setGuardian(SaintModel saint) async {
    await ref.read(saintNotifierProvider.notifier).setActiveSaint(saint.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${saint.name} set as your Guardian Saint!'),
          backgroundColor: AppColors.deepPurple,
        ),
      );
    }
  }

  Future<void> _activateAbility(SaintModel saint) async {
    setState(() => _isActivating = true);
    try {
      await ref.read(saintNotifierProvider.notifier).activateAbility(saint.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${saint.name}\'s ability activated!'),
            backgroundColor: AppColors.grace,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not activate ability: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isActivating = false);
    }
  }
}

// ── View ──────────────────────────────────────────────────────────────────────

class _SaintDetailView extends StatelessWidget {
  final SaintModel saint;
  final bool isUnlocked;
  final bool isActive;
  final TabController tabController;
  final bool showFullBio;
  final bool isUnlocking;
  final bool isActivating;
  final VoidCallback onToggleBio;
  final VoidCallback onUnlock;
  final VoidCallback onSetGuardian;
  final VoidCallback onActivateAbility;

  const _SaintDetailView({
    required this.saint,
    required this.isUnlocked,
    required this.isActive,
    required this.tabController,
    required this.showFullBio,
    required this.isUnlocking,
    required this.isActivating,
    required this.onToggleBio,
    required this.onUnlock,
    required this.onSetGuardian,
    required this.onActivateAbility,
  });

  Color get _rarityColor {
    switch (saint.rarity.toLowerCase()) {
      case 'legendary':
        return AppColors.gold;
      case 'epic':
        return AppColors.grace;
      case 'rare':
        return AppColors.holyPoints;
      case 'uncommon':
        return AppColors.sage;
      default:
        return AppColors.midGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Portrait app bar
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                backgroundColor: AppColors.purpleDark,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: AppColors.gold),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: _PortraitSection(
                    saint: saint,
                    isUnlocked: isUnlocked,
                    isActive: isActive,
                    rarityColor: _rarityColor,
                  ),
                ),
              ),

              // Content
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.md, AppSpacing.md, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Name & meta
                    _MetaSection(saint: saint, rarityColor: _rarityColor)
                        .animate()
                        .fadeIn(delay: 100.ms),

                    const SizedBox(height: AppSpacing.md),

                    // Tab bar
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: AppSpacing.borderRadiusMd,
                      ),
                      child: TabBar(
                        controller: tabController,
                        tabs: const [
                          Tab(text: 'Biography'),
                          Tab(text: 'Abilities'),
                          Tab(text: 'Prayer'),
                        ],
                        labelColor: AppColors.gold,
                        unselectedLabelColor: AppColors.midGrey,
                        indicatorColor: AppColors.gold,
                        dividerColor: Colors.transparent,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    SizedBox(
                      height: 300,
                      child: TabBarView(
                        controller: tabController,
                        children: [
                          _BioTab(
                            saint: saint,
                            showFull: showFullBio,
                            onToggle: onToggleBio,
                          ),
                          _AbilitiesTab(
                            saint: saint,
                            isUnlocked: isUnlocked,
                          ),
                          _PrayerTab(saint: saint),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),

          // CTA bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _CtaBar(
              saint: saint,
              isUnlocked: isUnlocked,
              isActive: isActive,
              isUnlocking: isUnlocking,
              isActivating: isActivating,
              onUnlock: onUnlock,
              onSetGuardian: onSetGuardian,
              onActivateAbility: onActivateAbility,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Portrait section ──────────────────────────────────────────────────────────

class _PortraitSection extends StatelessWidget {
  final SaintModel saint;
  final bool isUnlocked;
  final bool isActive;
  final Color rarityColor;

  const _PortraitSection({
    required this.saint,
    required this.isUnlocked,
    required this.isActive,
    required this.rarityColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            rarityColor.withOpacity(0.2),
            AppColors.darkSurface,
          ],
        ),
        border: Border(
          bottom: BorderSide(color: rarityColor.withOpacity(0.5), width: 2),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            // Saint portrait
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: rarityColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: rarityColor.withOpacity(isActive ? 0.6 : 0.3),
                    blurRadius: isActive ? 24 : 12,
                    spreadRadius: isActive ? 4 : 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: isUnlocked
                    ? Image.asset(
                        saint.portraitAssetPath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.deepPurple,
                          child: const Icon(Icons.person,
                              color: AppColors.gold, size: 60),
                        ),
                      )
                    : Container(
                        color: AppColors.darkCard,
                        child: Icon(Icons.lock,
                            color: rarityColor.withOpacity(0.5), size: 48),
                      ),
              ),
            ),
            if (isActive) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.2),
                  borderRadius: AppSpacing.borderRadiusSm,
                  border: Border.all(color: AppColors.gold.withOpacity(0.5)),
                ),
                child: Text(
                  '★ Active Guardian',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.gold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Meta section ──────────────────────────────────────────────────────────────

class _MetaSection extends StatelessWidget {
  final SaintModel saint;
  final Color rarityColor;

  const _MetaSection({required this.saint, required this.rarityColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    saint.name,
                    style: AppTextStyles.displaySmall.copyWith(
                      color: AppColors.goldLight,
                    ),
                  ),
                  Text(
                    saint.latinName,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.midGrey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: rarityColor.withOpacity(0.15),
                borderRadius: AppSpacing.borderRadiusSm,
                border: Border.all(color: rarityColor.withOpacity(0.5)),
              ),
              child: Text(
                saint.rarity.toUpperCase(),
                style: AppTextStyles.badge.copyWith(color: rarityColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            _MetaChip(
                icon: Icons.calendar_today,
                label: 'Feast: ${saint.feastDay}'),
            _MetaChip(icon: Icons.place, label: saint.origin),
            _MetaChip(icon: Icons.history, label: saint.era),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Patron of: ${saint.patronage}',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.midGrey,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: AppSpacing.borderRadiusSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.midGrey),
          const SizedBox(width: 4),
          Text(
            label,
            style:
                AppTextStyles.labelSmall.copyWith(color: AppColors.midGrey),
          ),
        ],
      ),
    );
  }
}

// ── Bio tab ───────────────────────────────────────────────────────────────────

class _BioTab extends StatelessWidget {
  final SaintModel saint;
  final bool showFull;
  final VoidCallback onToggle;

  const _BioTab(
      {required this.saint, required this.showFull, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            showFull ? saint.longBio : saint.shortBio,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.parchment,
              height: 1.7,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: onToggle,
            child: Text(
              showFull ? 'Show less' : 'Read full biography',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.gold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Abilities tab ─────────────────────────────────────────────────────────────

class _AbilitiesTab extends StatelessWidget {
  final SaintModel saint;
  final bool isUnlocked;

  const _AbilitiesTab({required this.saint, required this.isUnlocked});

  @override
  Widget build(BuildContext context) {
    if (saint.abilities.isEmpty) {
      return Center(
        child: Text(
          'No abilities available',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.midGrey),
        ),
      );
    }

    return ListView.separated(
      itemCount: saint.abilities.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (ctx, i) {
        final ability = saint.abilities[i];
        return Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: AppSpacing.borderRadiusSm,
            border: Border.all(color: AppColors.grace.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome,
                      color: AppColors.grace, size: 16),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    ability.name,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.goldLight,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${ability.graceCost} Grace',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.grace,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                ability.description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.midGrey,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${(ability.multiplier * 100 - 100).round()}% bonus · ${ability.durationHours}h duration',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Prayer tab ────────────────────────────────────────────────────────────────

class _PrayerTab extends StatelessWidget {
  final SaintModel saint;
  const _PrayerTab({required this.saint});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.deepPurple.withOpacity(0.2),
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(color: AppColors.deepPurple.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.church, color: AppColors.gold, size: 16),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Prayer to ${saint.name}',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.goldLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              saint.prayerText,
              style: AppTextStyles.scriptureQuote.copyWith(
                color: AppColors.parchment,
                fontFamily: 'Cinzel',
                fontSize: 15,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── CTA bar ───────────────────────────────────────────────────────────────────

class _CtaBar extends StatelessWidget {
  final SaintModel saint;
  final bool isUnlocked;
  final bool isActive;
  final bool isUnlocking;
  final bool isActivating;
  final VoidCallback onUnlock;
  final VoidCallback onSetGuardian;
  final VoidCallback onActivateAbility;

  const _CtaBar({
    required this.saint,
    required this.isUnlocked,
    required this.isActive,
    required this.isUnlocking,
    required this.isActivating,
    required this.onUnlock,
    required this.onSetGuardian,
    required this.onActivateAbility,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.darkCard,
        border: Border(top: BorderSide(color: AppColors.goldDark)),
      ),
      child: SafeArea(
        top: false,
        child: isUnlocked
            ? Row(
                children: [
                  Expanded(
                    child: KingdomButton(
                      label: isActive ? 'Guardian ✓' : 'Set as Guardian',
                      onPressed: isActive ? null : onSetGuardian,
                      icon: Icons.shield,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: KingdomButton(
                      label: 'Activate',
                      onPressed: isActivating ? null : onActivateAbility,
                      isLoading: isActivating,
                      icon: Icons.auto_awesome,
                      isPrimary: false,
                    ),
                  ),
                ],
              )
            : KingdomButton(
                label: 'Unlock — ${saint.holyPointsCost} HP',
                onPressed: isUnlocking ? null : onUnlock,
                isLoading: isUnlocking,
                icon: Icons.lock_open,
              ),
      ),
    );
  }
}
