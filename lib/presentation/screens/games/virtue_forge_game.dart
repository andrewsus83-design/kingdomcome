import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ── Domain ────────────────────────────────────────────────────────────────────

enum VirtueCard {
  kindness,
  courage,
  patience,
  humility,
  justice,
  temperance,
  prudence,
  faith,
  hope,
  charity,
  poverty,
  obedience,
  purity,
  zeal,
  fortitude,
  piety,
  wisdom,
  mercy,
  perseverance,
  gratitude,
}

extension VirtueCardExt on VirtueCard {
  String get displayName => switch (this) {
        VirtueCard.kindness => 'Kindness',
        VirtueCard.courage => 'Courage',
        VirtueCard.patience => 'Patience',
        VirtueCard.humility => 'Humility',
        VirtueCard.justice => 'Justice',
        VirtueCard.temperance => 'Temperance',
        VirtueCard.prudence => 'Prudence',
        VirtueCard.faith => 'Faith',
        VirtueCard.hope => 'Hope',
        VirtueCard.charity => 'Charity',
        VirtueCard.poverty => 'Poverty',
        VirtueCard.obedience => 'Obedience',
        VirtueCard.purity => 'Purity',
        VirtueCard.zeal => 'Zeal',
        VirtueCard.fortitude => 'Fortitude',
        VirtueCard.piety => 'Piety',
        VirtueCard.wisdom => 'Wisdom',
        VirtueCard.mercy => 'Mercy',
        VirtueCard.perseverance => 'Perseverance',
        VirtueCard.gratitude => 'Gratitude',
      };

  String get emoji => switch (this) {
        VirtueCard.kindness => '💛',
        VirtueCard.courage => '⚔️',
        VirtueCard.patience => '⏳',
        VirtueCard.humility => '🌱',
        VirtueCard.justice => '⚖️',
        VirtueCard.temperance => '🌊',
        VirtueCard.prudence => '🦉',
        VirtueCard.faith => '✝️',
        VirtueCard.hope => '⭐',
        VirtueCard.charity => '❤️',
        VirtueCard.poverty => '🕊️',
        VirtueCard.obedience => '🙏',
        VirtueCard.purity => '💎',
        VirtueCard.zeal => '🔥',
        VirtueCard.fortitude => '🏔️',
        VirtueCard.piety => '📿',
        VirtueCard.wisdom => '📖',
        VirtueCard.mercy => '🌸',
        VirtueCard.perseverance => '🗻',
        VirtueCard.gratitude => '🌻',
      };

  Color get color => switch (this) {
        VirtueCard.kindness => const Color(0xFFF39C12),
        VirtueCard.courage => const Color(0xFFE74C3C),
        VirtueCard.patience => const Color(0xFF3498DB),
        VirtueCard.humility => const Color(0xFF27AE60),
        VirtueCard.justice => const Color(0xFF9B59B6),
        VirtueCard.temperance => const Color(0xFF1ABC9C),
        VirtueCard.prudence => const Color(0xFF8E44AD),
        VirtueCard.faith => const Color(0xFF2980B9),
        VirtueCard.hope => const Color(0xFFFFD700),
        VirtueCard.charity => const Color(0xFFE91E63),
        VirtueCard.poverty => const Color(0xFF795548),
        VirtueCard.obedience => const Color(0xFF607D8B),
        VirtueCard.purity => const Color(0xFF00BCD4),
        VirtueCard.zeal => const Color(0xFFFF5722),
        VirtueCard.fortitude => const Color(0xFF455A64),
        VirtueCard.piety => const Color(0xFF7B1FA2),
        VirtueCard.wisdom => const Color(0xFF1565C0),
        VirtueCard.mercy => const Color(0xFFAD1457),
        VirtueCard.perseverance => const Color(0xFF33691E),
        VirtueCard.gratitude => const Color(0xFFFF8F00),
      };
}

class SaintRelic {
  const SaintRelic({
    required this.id,
    required this.name,
    required this.description,
    required this.bonus,
    required this.recipe,
    required this.emoji,
  });

  final String id;
  final String name;
  final String description;
  final String bonus;
  final Set<VirtueCard> recipe;
  final String emoji;
}

final List<SaintRelic> _allRelics = [
  const SaintRelic(
    id: 'st_francis',
    name: 'St. Francis Relic',
    description: 'Patron of animals and ecology.',
    bonus: '+15% XP multiplier',
    recipe: {VirtueCard.kindness, VirtueCard.humility, VirtueCard.poverty},
    emoji: '🕊️',
  ),
  const SaintRelic(
    id: 'st_thomas_aquinas',
    name: 'St. Thomas Aquinas Relic',
    description: 'Doctor of the Church, patron of scholars.',
    bonus: '+20% quiz bonus',
    recipe: {VirtueCard.wisdom, VirtueCard.prudence, VirtueCard.faith},
    emoji: '📖',
  ),
  const SaintRelic(
    id: 'st_joan',
    name: 'St. Joan of Arc Relic',
    description: 'Warrior saint and patron of France.',
    bonus: '+25% Grace generation',
    recipe: {VirtueCard.courage, VirtueCard.zeal, VirtueCard.faith},
    emoji: '⚔️',
  ),
  const SaintRelic(
    id: 'st_therese',
    name: 'St. Thérèse Relic',
    description: 'The Little Flower, patron of missions.',
    bonus: '+10% FaithCoin rate',
    recipe: {VirtueCard.patience, VirtueCard.mercy, VirtueCard.humility},
    emoji: '🌸',
  ),
  const SaintRelic(
    id: 'st_augustine',
    name: 'St. Augustine Relic',
    description: 'Doctor of Grace, bishop of Hippo.',
    bonus: '+20% Holy Points',
    recipe: {VirtueCard.wisdom, VirtueCard.piety, VirtueCard.perseverance},
    emoji: '✍️',
  ),
  const SaintRelic(
    id: 'st_dominic',
    name: 'St. Dominic Relic',
    description: 'Founder of the Order of Preachers.',
    bonus: 'Rosary bonus x2',
    recipe: {VirtueCard.zeal, VirtueCard.piety, VirtueCard.obedience},
    emoji: '📿',
  ),
  const SaintRelic(
    id: 'bl_mother_teresa',
    name: 'Bl. Teresa of Calcutta Relic',
    description: 'Apostle of mercy to the poor.',
    bonus: '+30% quest reward',
    recipe: {VirtueCard.charity, VirtueCard.mercy, VirtueCard.poverty},
    emoji: '🏥',
  ),
  const SaintRelic(
    id: 'st_benedict',
    name: 'St. Benedict Relic',
    description: 'Father of Western monasticism.',
    bonus: '+15% building speed',
    recipe: {VirtueCard.obedience, VirtueCard.temperance, VirtueCard.patience},
    emoji: '🏛️',
  ),
  const SaintRelic(
    id: 'st_cecilia',
    name: 'St. Cecilia Relic',
    description: 'Patron of musicians and sacred music.',
    bonus: 'Music generation free',
    recipe: {VirtueCard.purity, VirtueCard.faith, VirtueCard.courage},
    emoji: '🎵',
  ),
  const SaintRelic(
    id: 'st_michael',
    name: 'St. Michael Relic',
    description: 'Archangel, defender against evil.',
    bonus: 'Saint Defender shield',
    recipe: {VirtueCard.justice, VirtueCard.fortitude, VirtueCard.courage},
    emoji: '🛡️',
  ),
  const SiantRelic(
    id: 'st_joseph',
    name: 'St. Joseph Relic',
    description: 'Patron of workers and the universal Church.',
    bonus: '+20% resource production',
    recipe: {VirtueCard.prudence, VirtueCard.charity, VirtueCard.temperance},
    emoji: '🔨',
  ),
  const SaintRelic(
    id: 'st_peter',
    name: 'St. Peter Relic',
    description: 'First Pope, keeper of the keys.',
    bonus: '+25% parish influence',
    recipe: {VirtueCard.faith, VirtueCard.fortitude, VirtueCard.humility},
    emoji: '🗝️',
  ),
  const SaintRelic(
    id: 'st_paul',
    name: 'St. Paul Relic',
    description: 'Apostle to the Gentiles.',
    bonus: '+15% evangelisation XP',
    recipe: {VirtueCard.zeal, VirtueCard.perseverance, VirtueCard.gratitude},
    emoji: '📜',
  ),
  const SaintRelic(
    id: 'st_kateri',
    name: 'St. Kateri Tekakwitha Relic',
    description: 'Lily of the Mohawks.',
    bonus: '+20% prayer streak bonus',
    recipe: {VirtueCard.purity, VirtueCard.piety, VirtueCard.patience},
    emoji: '🌿',
  ),
  const SaintRelic(
    id: 'st_nicholas',
    name: 'St. Nicholas Relic',
    description: 'Patron of children and sailors.',
    bonus: '+30% FaithCoins on feast day',
    recipe: {VirtueCard.charity, VirtueCard.kindness, VirtueCard.hope},
    emoji: '🎁',
  ),
];

// This is a typo-fix alias — avoids 'const' error for St. Joseph above
// ignore: camel_case_types
class SiantRelic extends SaintRelic {
  const SiantRelic({
    required super.id,
    required super.name,
    required super.description,
    required super.bonus,
    required super.recipe,
    required super.emoji,
  });
}

// ── Forge state ───────────────────────────────────────────────────────────────

class _ForgeState {
  const _ForgeState({
    this.selectedCards = const [],
    this.discoveredRelics = const [],
    this.hand = const [],
    this.lastForgedRelic,
    this.isForging = false,
  });

  final List<VirtueCard> selectedCards;
  final List<String> discoveredRelics; // relic ids
  final List<VirtueCard> hand;
  final SaintRelic? lastForgedRelic;
  final bool isForging;

  _ForgeState copyWith({
    List<VirtueCard>? selectedCards,
    List<String>? discoveredRelics,
    List<VirtueCard>? hand,
    SaintRelic? lastForgedRelic,
    bool? isForging,
    bool clearLastRelic = false,
  }) {
    return _ForgeState(
      selectedCards: selectedCards ?? this.selectedCards,
      discoveredRelics: discoveredRelics ?? this.discoveredRelics,
      hand: hand ?? this.hand,
      lastForgedRelic: clearLastRelic ? null : (lastForgedRelic ?? this.lastForgedRelic),
      isForging: isForging ?? this.isForging,
    );
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class VirtueForgeGameScreen extends ConsumerStatefulWidget {
  const VirtueForgeGameScreen({super.key});

  @override
  ConsumerState<VirtueForgeGameScreen> createState() => _VirtueForgeGameScreenState();
}

class _VirtueForgeGameScreenState extends ConsumerState<VirtueForgeGameScreen>
    with SingleTickerProviderStateMixin {
  late _ForgeState _state;
  late AnimationController _sparkleController;
  bool _showCollection = false;

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Deal starting hand
    final startingHand = VirtueCard.values.toList()..shuffle();
    _state = _ForgeState(
      hand: startingHand.take(8).toList(),
    );
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    super.dispose();
  }

  void _toggleCard(VirtueCard card) {
    final selected = List<VirtueCard>.from(_state.selectedCards);
    if (selected.contains(card)) {
      selected.remove(card);
    } else if (selected.length < 3) {
      selected.add(card);
    }
    setState(() => _state = _state.copyWith(selectedCards: selected));
  }

  Future<void> _forge() async {
    if (_state.selectedCards.length < 2) return;

    setState(() => _state = _state.copyWith(isForging: true));
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    _sparkleController.forward(from: 0);

    final selectedSet = _state.selectedCards.toSet();
    SaintRelic? matched;

    for (final relic in _allRelics) {
      if (relic.recipe.every((v) => selectedSet.contains(v)) &&
          selectedSet.every((v) => relic.recipe.contains(v))) {
        matched = relic;
        break;
      }
    }

    final newHand = List<VirtueCard>.from(_state.hand)
      ..removeWhere((c) => _state.selectedCards.contains(c));

    // Replenish hand
    final pool = VirtueCard.values
        .where((c) => !newHand.contains(c))
        .toList()
      ..shuffle();
    newHand.addAll(pool.take(3));

    final newDiscovered = List<String>.from(_state.discoveredRelics);
    if (matched != null && !newDiscovered.contains(matched.id)) {
      newDiscovered.add(matched.id);
    }

    setState(() {
      _state = _state.copyWith(
        selectedCards: [],
        hand: newHand,
        discoveredRelics: newDiscovered,
        lastForgedRelic: matched,
        isForging: false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Virtue Forge',
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontFamily: 'Cinzel',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_stories, color: Color(0xFFFFD700)),
            tooltip: 'Collection',
            onPressed: () => setState(() => _showCollection = !_showCollection),
          ),
        ],
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
      ),
      body: _showCollection ? _buildCollection() : _buildForge(),
    );
  }

  Widget _buildForge() {
    return Column(
      children: [
        // ── Forge area ──────────────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFFD700).withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'Select 2–3 Virtue Cards to Forge',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              // Selected slots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final card = i < _state.selectedCards.length
                      ? _state.selectedCards[i]
                      : null;
                  return _SelectedSlot(card: card);
                }),
              ),
              const SizedBox(height: 20),
              // Forge button
              AnimatedBuilder(
                animation: _sparkleController,
                builder: (context, child) {
                  final glow = _sparkleController.value;
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700)
                              .withOpacity(0.2 + glow * 0.6),
                          blurRadius: 10 + glow * 20,
                          spreadRadius: glow * 4,
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: ElevatedButton.icon(
                  onPressed: _state.selectedCards.length >= 2 && !_state.isForging
                      ? _forge
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: const Color(0xFF1A0A2E),
                    disabledBackgroundColor: Colors.white24,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _state.isForging
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF1A0A2E),
                          ),
                        )
                      : const Text('⚒️', style: TextStyle(fontSize: 18)),
                  label: Text(
                    _state.isForging ? 'Forging…' : 'Forge Relic',
                    style: const TextStyle(
                      fontFamily: 'Cinzel',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Last result
              if (_state.lastForgedRelic != null) ...[
                const SizedBox(height: 16),
                _RelicResult(relic: _state.lastForgedRelic!)
                    .animate()
                    .fadeIn()
                    .scale(begin: const Offset(0.5, 0.5)),
              ] else if (_state.selectedCards.length >= 2) ...[
                const SizedBox(height: 12),
                const Text(
                  '✨ Tap Forge to discover a relic!',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        // Discovered count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Relics Discovered: ${_state.discoveredRelics.length} / ${_allRelics.length}',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              Text(
                'Hand (${_state.hand.length} cards)',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // ── Card hand ────────────────────────────────────────────────────────
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            itemCount: _state.hand.length,
            itemBuilder: (context, i) {
              final card = _state.hand[i];
              final isSelected = _state.selectedCards.contains(card);
              return _VirtueCardWidget(
                card: card,
                isSelected: isSelected,
                onTap: () => _toggleCard(card),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCollection() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Relic Collection Book',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontFamily: 'Cinzel',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.2,
            ),
            itemCount: _allRelics.length,
            itemBuilder: (context, i) {
              final relic = _allRelics[i];
              final discovered = _state.discoveredRelics.contains(relic.id);
              return _RelicBookEntry(relic: relic, discovered: discovered);
            },
          ),
        ),
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SelectedSlot extends StatelessWidget {
  const _SelectedSlot({this.card});
  final VirtueCard? card;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 80,
      height: 90,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: card != null
            ? card!.color.withOpacity(0.2)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: card != null ? card!.color : Colors.white24,
          width: card != null ? 2 : 1,
        ),
      ),
      child: card != null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(card!.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 4),
                Text(
                  card!.displayName,
                  style: const TextStyle(color: Colors.white70, fontSize: 9),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ],
            )
          : const Icon(Icons.add, color: Colors.white24, size: 28),
    );
  }
}

class _VirtueCardWidget extends StatelessWidget {
  const _VirtueCardWidget({
    required this.card,
    required this.isSelected,
    required this.onTap,
  });
  final VirtueCard card;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? card.color.withOpacity(0.3)
              : const Color(0xFF1A2A3A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? card.color : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: card.color.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(card.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                card.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RelicResult extends StatelessWidget {
  const _RelicResult({required this.relic});
  final SaintRelic relic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(relic.emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  relic.name,
                  style: const TextStyle(
                    color: Color(0xFF1A0A2E),
                    fontFamily: 'Cinzel',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  relic.bonus,
                  style: const TextStyle(
                    color: Color(0xFF4A2800),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

class _RelicBookEntry extends StatelessWidget {
  const _RelicBookEntry({required this.relic, required this.discovered});
  final SaintRelic relic;
  final bool discovered;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: discovered
            ? const Color(0xFF1A2A3A)
            : const Color(0xFF0D1520),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: discovered
              ? const Color(0xFFFFD700).withOpacity(0.4)
              : Colors.white12,
        ),
      ),
      child: discovered
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(relic.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        relic.name,
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cinzel',
                        ),
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  relic.bonus,
                  style: const TextStyle(
                    color: Color(0xFF27AE60),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Recipe: ${relic.recipe.map((v) => v.displayName).join(' + ')}',
                  style: const TextStyle(color: Colors.white54, fontSize: 9),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('❓', style: TextStyle(fontSize: 28)),
                const SizedBox(height: 6),
                const Text(
                  'Undiscovered\nRelic',
                  style: TextStyle(color: Colors.white24, fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }
}
