import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/liturgical_colors.dart';
import '../../providers/music_provider.dart';
import '../../providers/bible_provider.dart';

class MusicPlayerScreen extends ConsumerStatefulWidget {
  const MusicPlayerScreen({super.key});

  @override
  ConsumerState<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends ConsumerState<MusicPlayerScreen>
    with TickerProviderStateMixin {
  late final AnimationController _vinylController;
  late final AnimationController _pulseController;

  String _selectedStyle = 'hymn';

  static const _styles = [
    ('gregorian', 'Gregorian Chant'),
    ('hymn', 'Traditional Hymn'),
    ('contemporary', 'Contemporary'),
    ('kids', 'Kids Song'),
  ];

  @override
  void initState() {
    super.initState();
    _vinylController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _vinylController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final musicState = ref.watch(musicNotifierProvider);

    if (!musicState.isPlaying) {
      _vinylController.stop();
    } else {
      if (!_vinylController.isAnimating) _vinylController.repeat();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A0A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Sacred Music',
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontFamily: 'Cinzel',
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Vinyl / Cross Disc ──────────────────────────────────────────
            _buildVinylDisc(musicState),
            const SizedBox(height: 24),

            // ── Now Playing ─────────────────────────────────────────────────
            _buildNowPlaying(musicState),
            const SizedBox(height: 24),

            // ── Playback controls ────────────────────────────────────────────
            _buildControls(musicState),
            const SizedBox(height: 16),

            // ── Volume ───────────────────────────────────────────────────────
            _buildVolumeControl(musicState),
            const SizedBox(height: 32),

            // ── Generate new hymn ────────────────────────────────────────────
            _buildGenerateSection(musicState),
            const SizedBox(height: 32),

            // ── Generated hymns library ──────────────────────────────────────
            _buildHymnLibrary(musicState),
          ],
        ),
      ),
    );
  }

  // ── Vinyl disc ────────────────────────────────────────────────────────────────

  Widget _buildVinylDisc(MusicState state) {
    return Center(
      child: AnimatedBuilder(
        animation: _vinylController,
        builder: (context, child) {
          return Transform.rotate(
            angle: state.isPlaying ? _vinylController.value * 2 * math.pi : 0,
            child: child,
          );
        },
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const SweepGradient(
              colors: [
                Color(0xFF1A1A2E),
                Color(0xFF2D1248),
                Color(0xFF1A1A2E),
                Color(0xFF16213E),
                Color(0xFF1A1A2E),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.3),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Grooves
              ...List.generate(5, (i) {
                final radius = 30.0 + i * 22;
                return Container(
                  width: radius * 2,
                  height: radius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.05),
                      width: 1,
                    ),
                  ),
                );
              }),
              // Centre cross
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                  ),
                ),
                child: const Icon(
                  Icons.add, // Cross shape approximation
                  color: Color(0xFF1A0A2E),
                  size: 32,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8));
  }

  // ── Now Playing ───────────────────────────────────────────────────────────────

  Widget _buildNowPlaying(MusicState state) {
    final trackName = state.currentTrack != null
        ? (state.generatedTracks.isNotEmpty
            ? state.generatedTracks.first.title
            : 'Kingdom Ambient Music')
        : 'No track playing';

    return Column(
      children: [
        Text(
          'Now Playing',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          trackName,
          style: const TextStyle(
            color: Color(0xFFFFD700),
            fontFamily: 'Cinzel',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ── Controls ──────────────────────────────────────────────────────────────────

  Widget _buildControls(MusicState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Mute
        IconButton(
          onPressed: () => ref.read(musicNotifierProvider.notifier).toggleMute(),
          icon: Icon(
            state.isMuted ? Icons.volume_off : Icons.volume_up,
            color: state.isMuted ? Colors.redAccent : const Color(0xFFFFD700),
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        // Play/Pause
        GestureDetector(
          onTap: () => ref.read(musicNotifierProvider.notifier).toggleMusic(),
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = state.isPlaying
                  ? 1.0 + _pulseController.value * 0.05
                  : 1.0;
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: const Color(0xFF1A0A2E),
                size: 36,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Stop
        IconButton(
          onPressed: () async {
            await AudioServiceRef.stop(ref);
          },
          icon: const Icon(Icons.stop_rounded, color: Color(0xFFFFD700), size: 28),
        ),
      ],
    );
  }

  // ── Volume ────────────────────────────────────────────────────────────────────

  Widget _buildVolumeControl(MusicState state) {
    return Row(
      children: [
        const Icon(Icons.volume_down, color: Colors.white54, size: 20),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFFFFD700),
              inactiveTrackColor: Colors.white24,
              thumbColor: const Color(0xFFFFD700),
              overlayColor: const Color(0xFFFFD700).withOpacity(0.2),
              trackHeight: 3,
            ),
            child: Slider(
              value: state.volume,
              min: 0,
              max: 1,
              onChanged: (v) {
                ref.read(musicNotifierProvider.notifier).setVolume(v);
              },
            ),
          ),
        ),
        const Icon(Icons.volume_up, color: Colors.white54, size: 20),
      ],
    );
  }

  // ── Generate section ──────────────────────────────────────────────────────────

  Widget _buildGenerateSection(MusicState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Generate New Hymn',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontFamily: 'Cinzel',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a sacred hymn from the Verse of the Day',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          // Style selector
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _styles.map((styleEntry) {
              final (key, label) = styleEntry;
              final isSelected = _selectedStyle == key;
              return GestureDetector(
                onTap: () => setState(() => _selectedStyle = key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFFD700)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFFFD700)
                          : Colors.white30,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF1A0A2E) : Colors.white70,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: state.isGenerating
                  ? null
                  : () => _generateFromVerseOfDay(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: const Color(0xFF1A0A2E),
                disabledBackgroundColor: Colors.white24,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: state.isGenerating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF1A0A2E),
                      ),
                    )
                  : const Icon(Icons.music_note),
              label: Text(
                state.isGenerating ? 'Generating…' : 'Generate Hymn from Verse',
                style: const TextStyle(
                  fontFamily: 'Cinzel',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (state.generationError != null) ...[
            const SizedBox(height: 8),
            Text(
              state.generationError!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  // ── Hymn library ──────────────────────────────────────────────────────────────

  Widget _buildHymnLibrary(MusicState state) {
    if (state.generatedTracks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Hymn Library',
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontFamily: 'Cinzel',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...state.generatedTracks.map((track) => _buildTrackTile(track, state)),
      ],
    );
  }

  Widget _buildTrackTile(GeneratedTrack track, MusicState state) {
    final isCurrentTrack = state.currentTrack == track.audioUrl;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCurrentTrack
            ? const Color(0xFFFFD700).withOpacity(0.15)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentTrack
              ? const Color(0xFFFFD700).withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _trackTypeColor(track.type).withOpacity(0.2),
          ),
          child: Icon(
            _trackTypeIcon(track.type),
            color: _trackTypeColor(track.type),
            size: 20,
          ),
        ),
        title: Text(
          track.title,
          style: TextStyle(
            color: isCurrentTrack ? const Color(0xFFFFD700) : Colors.white,
            fontWeight: isCurrentTrack ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          _trackTypeLabel(track.type),
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCurrentTrack)
              const Icon(Icons.equalizer, color: Color(0xFFFFD700), size: 20),
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white54, size: 20),
              onPressed: () => _shareTrack(track),
            ),
            IconButton(
              icon: Icon(
                isCurrentTrack && state.isPlaying
                    ? Icons.pause_circle
                    : Icons.play_circle,
                color: const Color(0xFFFFD700),
                size: 28,
              ),
              onPressed: () {
                ref.read(musicNotifierProvider.notifier).playTrack(track.audioUrl);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────────

  Future<void> _generateFromVerseOfDay() async {
    // In production this reads from the bible provider
    const verseText =
        'I can do all things through Christ who strengthens me.';
    const verseRef = 'Philippians 4:13';

    await ref.read(musicNotifierProvider.notifier).generateAndPlayVerseHymn(
          verseText: verseText,
          verseRef: verseRef,
          style: _selectedStyle,
        );
  }

  void _shareTrack(GeneratedTrack track) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing "${track.title}"…'),
        backgroundColor: const Color(0xFFFFD700),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  Color _trackTypeColor(GeneratedTrackType type) {
    return switch (type) {
      GeneratedTrackType.verseHymn => const Color(0xFF9B59B6),
      GeneratedTrackType.feastDay => const Color(0xFFE67E22),
      GeneratedTrackType.questVictory => const Color(0xFF27AE60),
      GeneratedTrackType.custom => const Color(0xFF3498DB),
    };
  }

  IconData _trackTypeIcon(GeneratedTrackType type) {
    return switch (type) {
      GeneratedTrackType.verseHymn => Icons.book,
      GeneratedTrackType.feastDay => Icons.star,
      GeneratedTrackType.questVictory => Icons.emoji_events,
      GeneratedTrackType.custom => Icons.music_note,
    };
  }

  String _trackTypeLabel(GeneratedTrackType type) {
    return switch (type) {
      GeneratedTrackType.verseHymn => 'Scripture Hymn',
      GeneratedTrackType.feastDay => 'Feast Day Song',
      GeneratedTrackType.questVictory => 'Victory Jingle',
      GeneratedTrackType.custom => 'Custom Track',
    };
  }
}

// ── Helper class to call AudioService without circular dependency ─────────────

abstract final class AudioServiceRef {
  static Future<void> stop(WidgetRef ref) async {
    await ref.read(musicNotifierProvider.notifier).toggleMusic();
  }
}
