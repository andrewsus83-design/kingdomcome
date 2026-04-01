import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/data/models/quest/real_world_quest_model.dart';
import 'package:kingdomcome/data/models/quest/real_world_completion_model.dart';
import 'package:kingdomcome/data/repositories/real_world_quest_repository.dart';
import 'package:kingdomcome/presentation/providers/real_world_quest_provider.dart';
import 'package:kingdomcome/presentation/providers/auth_provider.dart';
import 'package:kingdomcome/presentation/widgets/common/kingdom_button.dart';

// ---------------------------------------------------------------------------
// Internal providers for parent-side data
// ---------------------------------------------------------------------------

final _parentPendingValidationsProvider = FutureProvider.autoDispose<
    List<_CompletionWithQuest>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final repo = RealWorldQuestRepositoryImpl(
    supabaseClient: Supabase.instance.client,
  );

  final completionsResult = await repo.getPendingValidations(user.id);
  final questsResult = await repo.getAllQuests(3); // get all age groups

  return completionsResult.fold(
    (_) => [],
    (completions) {
      return questsResult.fold(
        (_) => completions
            .map((c) => _CompletionWithQuest(completion: c, quest: null))
            .toList(),
        (quests) {
          return completions.map((c) {
            final quest = quests.where((q) => q.id == c.questId).firstOrNull;
            return _CompletionWithQuest(completion: c, quest: quest);
          }).toList();
        },
      );
    },
  );
});

class _CompletionWithQuest {
  final RealWorldCompletionModel completion;
  final RealWorldQuestModel? quest;
  const _CompletionWithQuest({required this.completion, required this.quest});
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ParentValidationScreen extends ConsumerStatefulWidget {
  const ParentValidationScreen({super.key});

  @override
  ConsumerState<ParentValidationScreen> createState() =>
      _ParentValidationScreenState();
}

class _ParentValidationScreenState
    extends ConsumerState<ParentValidationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(_parentPendingValidationsProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.purpleDark, AppColors.darkSurface],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _ParentHeader(
                childName: user?.displayName ?? 'Your Child',
                onBack: () => context.pop(),
              ),

              // Tab bar
              Container(
                color: AppColors.purpleDark.withOpacity(0.5),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.gold,
                  labelColor: AppColors.goldLight,
                  unselectedLabelColor: AppColors.midGrey,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('⏳',
                              style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          const Text('Pending'),
                          if (pendingAsync.valueOrNull?.isNotEmpty ?? false) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.red,
                                borderRadius:
                                    AppSpacing.borderRadiusSm,
                              ),
                              child: Text(
                                '${pendingAsync.valueOrNull!.length}',
                                style: AppTextStyles.badge,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Tab(text: 'Create Quest'),
                  ],
                ),
              ),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Pending validations list
                    pendingAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.gold),
                      ),
                      error: (e, _) => Center(
                        child: Text(
                          'Could not load validations.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.midGrey,
                          ),
                        ),
                      ),
                      data: (items) => items.isEmpty
                          ? _EmptyPending()
                          : _PendingList(
                              items: items,
                              onRefresh: () => ref.invalidate(
                                  _parentPendingValidationsProvider),
                            ),
                    ),

                    // Custom quest creator
                    _CustomQuestCreator(
                      parentId: user?.id ?? '',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _ParentHeader extends StatelessWidget {
  final String childName;
  final VoidCallback onBack;

  const _ParentHeader({required this.childName, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.purpleDark.withOpacity(0.8),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.ivory),
            onPressed: onBack,
          ),
          const Text('👨‍👩‍👧', style: TextStyle(fontSize: 28)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Parent Gate',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.goldLight,
                  ),
                ),
                Text(
                  'Real World Quest Validation',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.midGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty pending
// ---------------------------------------------------------------------------

class _EmptyPending extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('✅', style: TextStyle(fontSize: 64))
                .animate(onPlay: (c) => c.repeat(count: 2))
                .scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.05, 1.05),
                  duration: 600.ms,
                )
                .then()
                .scale(
                  begin: const Offset(1.05, 1.05),
                  end: const Offset(1, 1),
                ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'All caught up!',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.goldLight,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No quests waiting for your approval right now.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.midGrey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pending list
// ---------------------------------------------------------------------------

class _PendingList extends StatelessWidget {
  final List<_CompletionWithQuest> items;
  final VoidCallback onRefresh;

  const _PendingList({required this.items, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.gold,
      onRefresh: () async => onRefresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: items.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppSpacing.sm),
        itemBuilder: (ctx, i) => _ValidationCard(
          item: items[i],
          onValidated: onRefresh,
        ).animate(delay: (i * 60).ms).fadeIn(duration: 300.ms).slideX(begin: -0.05),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Validation card
// ---------------------------------------------------------------------------

class _ValidationCard extends ConsumerStatefulWidget {
  final _CompletionWithQuest item;
  final VoidCallback onValidated;

  const _ValidationCard({
    required this.item,
    required this.onValidated,
  });

  @override
  ConsumerState<_ValidationCard> createState() =>
      _ValidationCardState();
}

class _ValidationCardState extends ConsumerState<_ValidationCard> {
  final _noteController = TextEditingController();
  bool _isExpanded = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _validate() async {
    setState(() => _isLoading = true);
    final repo = RealWorldQuestRepositoryImpl(
      supabaseClient: Supabase.instance.client,
    );
    final result = await repo.validateCompletion(
      widget.item.completion.id,
      _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );
    result.fold(
      (f) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(f.message),
              backgroundColor: AppColors.crimson,
            ),
          );
        }
      },
      (_) {
        if (mounted) {
          setState(() => _isLoading = false);
          widget.onValidated();
        }
      },
    );
  }

  Future<void> _reject() async {
    setState(() => _isLoading = true);
    final repo = RealWorldQuestRepositoryImpl(
      supabaseClient: Supabase.instance.client,
    );
    final result = await repo.rejectCompletion(
      widget.item.completion.id,
      'Not yet — try again!',
    );
    result.fold(
      (f) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(f.message),
              backgroundColor: AppColors.crimson,
            ),
          );
        }
      },
      (_) {
        if (mounted) {
          setState(() => _isLoading = false);
          widget.onValidated();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final completion = widget.item.completion;
    final quest = widget.item.quest;
    final timeAgo = _timeAgo(completion.completedAt);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.darkElevated),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      quest?.iconEmoji ?? '⭐',
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quest?.title ?? 'Unknown Quest',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.ivory,
                            ),
                          ),
                          Text(
                            timeAgo,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.midGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Expand toggle
                    IconButton(
                      icon: Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppColors.midGrey,
                      ),
                      onPressed: () =>
                          setState(() => _isExpanded = !_isExpanded),
                    ),
                  ],
                ),

                // Child's note (always visible if present)
                if (completion.childNote != null &&
                    completion.childNote!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.darkElevated,
                      borderRadius: AppSpacing.borderRadiusSm,
                      border: Border.all(
                        color: AppColors.purpleLight.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💬',
                            style: TextStyle(fontSize: 14)),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            completion.childNote!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.ivory.withOpacity(0.85),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Proof photo placeholder
                if (completion.proofPhotoUrl != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '📸 Photo proof attached',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.holyPoints,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Expanded: encouragement note field
          if (_isExpanded) ...[
            const Divider(color: AppColors.darkElevated, height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add an encouragement note (optional):',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.ivory,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.ivory,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'e.g. "I\'m so proud of you for doing this! Keep it up!"',
                      hintStyle: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.midGrey,
                      ),
                      filled: true,
                      fillColor: AppColors.darkElevated,
                      border: OutlineInputBorder(
                        borderRadius: AppSpacing.borderRadiusMd,
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action buttons
          const Divider(color: AppColors.darkElevated, height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                // Reject button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _reject,
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Not yet'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.midGrey,
                      side: BorderSide(
                          color: AppColors.midGrey.withOpacity(0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Validate button
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _validate,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.ivory,
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 16),
                    label: Text(_isLoading ? 'Approving...' : '✅ Validate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forestGreen,
                      foregroundColor: AppColors.ivory,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.borderRadiusMd,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d, h:mm a').format(dt);
  }
}

// ---------------------------------------------------------------------------
// Custom quest creator
// ---------------------------------------------------------------------------

class _CustomQuestCreator extends ConsumerStatefulWidget {
  final String parentId;
  const _CustomQuestCreator({required this.parentId});

  @override
  ConsumerState<_CustomQuestCreator> createState() =>
      _CustomQuestCreatorState();
}

class _CustomQuestCreatorState
    extends ConsumerState<_CustomQuestCreator> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  RealWorldCategory _category = RealWorldCategory.homeLife;
  RealWorldVerification _verification = RealWorldVerification.parentValidate;
  RepeatFrequency _frequency = RepeatFrequency.once;
  int _holyPoints = 50;
  int _faithCoins = 0;
  bool _isCreating = false;
  bool _created = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _createQuest() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _isCreating = true);

    final repo = RealWorldQuestRepositoryImpl(
      supabaseClient: Supabase.instance.client,
    );

    final result = await repo.createCustomQuest(
      widget.parentId,
      _titleController.text.trim(),
      _descController.text.trim().isEmpty
          ? 'A special quest from your parent!'
          : _descController.text.trim(),
      _category,
      _holyPoints,
      _faithCoins,
      _frequency,
      _verification,
    );

    result.fold(
      (f) {
        if (mounted) {
          setState(() => _isCreating = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(f.message),
              backgroundColor: AppColors.crimson,
            ),
          );
        }
      },
      (_) {
        if (mounted) {
          setState(() {
            _isCreating = false;
            _created = true;
          });
          // Refresh quest board
          ref
              .read(realWorldQuestNotifierProvider.notifier)
              .refresh();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_created) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 64))
                  .animate()
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1, 1),
                    curve: Curves.elasticOut,
                    duration: 600.ms,
                  ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Quest Created!',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.goldLight,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your child will see this quest on their Quest Board.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.midGrey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              KingdomButton(
                label: 'Create Another',
                onPressed: () => setState(() {
                  _created = false;
                  _titleController.clear();
                  _descController.clear();
                  _holyPoints = 50;
                  _faithCoins = 0;
                }),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create a Special Quest',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.goldLight,
            ),
          ).animate().fadeIn(),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Design a custom quest just for your child.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.midGrey,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Title
          _FormLabel(label: 'Quest Title *'),
          TextField(
            controller: _titleController,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ivory),
            decoration: _inputDecoration('e.g. Help make dinner tonight'),
          ),
          const SizedBox(height: AppSpacing.md),

          // Description
          _FormLabel(label: 'Description'),
          TextField(
            controller: _descController,
            maxLines: 3,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ivory),
            decoration: _inputDecoration(
                'What should your child do? (optional)'),
          ),
          const SizedBox(height: AppSpacing.md),

          // Category
          _FormLabel(label: 'Category'),
          DropdownButtonFormField<RealWorldCategory>(
            value: _category,
            dropdownColor: AppColors.darkElevated,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ivory),
            decoration: _inputDecoration(''),
            items: RealWorldCategory.values
                .map(
                  (cat) => DropdownMenuItem(
                    value: cat,
                    child: Text('${cat.emoji} ${cat.displayName}'),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _category = v);
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Verification
          _FormLabel(label: 'How is it verified?'),
          DropdownButtonFormField<RealWorldVerification>(
            value: _verification,
            dropdownColor: AppColors.darkElevated,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ivory),
            decoration: _inputDecoration(''),
            items: RealWorldVerification.values
                .map(
                  (v) => DropdownMenuItem(
                    value: v,
                    child: Text('${v.emoji} ${v.displayName}'),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _verification = v);
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Frequency
          _FormLabel(label: 'Frequency'),
          DropdownButtonFormField<RepeatFrequency>(
            value: _frequency,
            dropdownColor: AppColors.darkElevated,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ivory),
            decoration: _inputDecoration(''),
            items: RepeatFrequency.values
                .map(
                  (f) => DropdownMenuItem(
                    value: f,
                    child: Text(f.displayName),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _frequency = v);
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // Holy Points reward slider
          _FormLabel(
              label: 'Holy Points Reward: $_holyPoints HP'),
          Slider(
            value: _holyPoints.toDouble(),
            min: 10,
            max: 200,
            divisions: 19,
            activeColor: AppColors.holyPoints,
            inactiveColor: AppColors.darkElevated,
            label: '$_holyPoints HP',
            onChanged: (v) => setState(() => _holyPoints = v.round()),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Faith Coins reward slider
          _FormLabel(
              label: 'Faith Coins Reward: $_faithCoins FC'),
          Slider(
            value: _faithCoins.toDouble(),
            min: 0,
            max: 100,
            divisions: 20,
            activeColor: AppColors.faithCoins,
            inactiveColor: AppColors.darkElevated,
            label: '$_faithCoins FC',
            onChanged: (v) => setState(() => _faithCoins = v.round()),
          ),

          const SizedBox(height: AppSpacing.xl),

          KingdomButton(
            label: 'Create Quest',
            icon: Icons.add_circle_rounded,
            isLoading: _isCreating,
            onPressed:
                _isCreating || _titleController.text.trim().isEmpty
                    ? null
                    : _createQuest,
          ),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          AppTextStyles.bodyMedium.copyWith(color: AppColors.midGrey),
      filled: true,
      fillColor: AppColors.darkElevated,
      border: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        borderSide: BorderSide(color: AppColors.darkCard),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        borderSide: BorderSide(color: AppColors.darkCard),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String label;
  const _FormLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.ivory,
        ),
      ),
    );
  }
}
