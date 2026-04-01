import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:just_audio/just_audio.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/data/models/ark/ark_node_model.dart';
import 'package:kingdomcome/presentation/providers/ark_provider.dart';

// ── Reading word model ────────────────────────────────────────────────────────

/// A single word with its audio timestamp offset for highlight sync.
class _ReadingWord {
  final String text;
  final double startSeconds; // when this word begins in the audio
  final double endSeconds;

  const _ReadingWord({
    required this.text,
    required this.startSeconds,
    required this.endSeconds,
  });
}

/// A parsed reading passage, split into highlighted word chunks.
class _ReadingPassage {
  final String chapterRef;
  final List<_ReadingWord> words;

  const _ReadingPassage({
    required this.chapterRef,
    required this.words,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Interactive Reading Screen
// ─────────────────────────────────────────────────────────────────────────────

/// Karaoke-style Bible chapter reading screen.
///
/// Features:
/// - Large readable NABRE Bible text
/// - Words highlight yellow as audio progresses (timestamp-based sync)
/// - Tap any word to hear pronunciation (TTS)
/// - Reading speed control (0.5x / 1x / 1.5x / 2x)
/// - Font size control
/// - Chapter completion with reward animation
/// - Progress auto-saved
class InteractiveReadingScreen extends ConsumerStatefulWidget {
  final String nodeId;

  const InteractiveReadingScreen({super.key, required this.nodeId});

  @override
  ConsumerState<InteractiveReadingScreen> createState() =>
      _InteractiveReadingScreenState();
}

class _InteractiveReadingScreenState
    extends ConsumerState<InteractiveReadingScreen>
    with TickerProviderStateMixin {
  late final AudioPlayer _audioPlayer;
  late final AnimationController _completionAnimController;

  StreamSubscription<Duration>? _positionSub;

  // Playback state
  bool _isPlaying = false;
  bool _isCompleted = false;
  double _playbackSpeed = 1.0;
  double _fontSize = 16.0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  int _currentHighlightIndex = -1;

  // Passage data
  late _ReadingPassage _passage;
  ArkNodeModel? _node;

  static const _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _completionAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadPassage();
    _setupAudioListeners();
  }

  void _loadPassage() {
    // Seed passage — in production this would be fetched from Supabase
    // by joining the node's chapterRef to a cached NABRE text table.
    _passage = _buildSeedPassage();
  }

  void _setupAudioListeners() {
    _audioPlayer.positionStream.listen((pos) {
      if (!mounted) return;
      setState(() {
        _position = pos;
        _updateHighlight(pos.inMilliseconds / 1000.0);
      });
    });

    _audioPlayer.durationStream.listen((dur) {
      if (dur != null && mounted) {
        setState(() => _duration = dur);
      }
    });

    _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      final isPlaying = state.playing;
      final processingState = state.processingState;

      if (processingState == ProcessingState.completed) {
        _handleChapterCompleted();
      }

      setState(() => _isPlaying = isPlaying);
    });
  }

  void _updateHighlight(double positionSeconds) {
    int newIndex = -1;
    for (int i = 0; i < _passage.words.length; i++) {
      if (positionSeconds >= _passage.words[i].startSeconds &&
          positionSeconds < _passage.words[i].endSeconds) {
        newIndex = i;
        break;
      }
    }
    if (newIndex != _currentHighlightIndex) {
      setState(() => _currentHighlightIndex = newIndex);
    }
  }

  Future<void> _handleChapterCompleted() async {
    if (_isCompleted) return;
    setState(() => _isCompleted = true);
    await _completionAnimController.forward();

    if (mounted) {
      await ref.read(arkNotifierProvider.notifier).completeNode(widget.nodeId);
      _showCompletionDialog();
    }
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      final node = _node;
      if (node?.sunoAudioUrl != null && _position == Duration.zero) {
        try {
          await _audioPlayer.setUrl(node!.sunoAudioUrl!);
          await _audioPlayer.setSpeed(_playbackSpeed);
          await _audioPlayer.play();
        } catch (_) {
          // If no real audio, simulate playback for demo
          _simulatePlayback();
        }
      } else {
        await _audioPlayer.play();
      }
    }
  }

  Timer? _simulationTimer;

  void _simulatePlayback() {
    if (_passage.words.isEmpty) return;
    final totalWords = _passage.words.length;
    final totalDuration = _passage.words.last.endSeconds;
    setState(() {
      _isPlaying = true;
      _duration = Duration(milliseconds: (totalDuration * 1000).toInt());
    });

    double elapsed = 0;
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (t) {
        if (!mounted || !_isPlaying) {
          t.cancel();
          return;
        }
        elapsed += 0.1 * _playbackSpeed;
        setState(() {
          _position =
              Duration(milliseconds: (elapsed * 1000).clamp(0, _duration.inMilliseconds).toInt());
          _updateHighlight(elapsed);
        });
        if (elapsed >= totalDuration) {
          t.cancel();
          _handleChapterCompleted();
        }
      },
    );
  }

  Future<void> _setSpeed(double speed) async {
    setState(() => _playbackSpeed = speed);
    await _audioPlayer.setSpeed(speed);
  }

  void _showCompletionDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg,
          side: const BorderSide(color: AppColors.gold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('✝️', style: TextStyle(fontSize: 56))
                .animate(
                    controller: _completionAnimController,
                    autoPlay: false)
                .scale(begin: const Offset(0.3, 0.3))
                .then()
                .shake(),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Chapter Complete!',
              style: AppTextStyles.headlineLarge.copyWith(color: AppColors.gold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Well done! Your rewards have been added.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.parchment),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(
              'Continue',
              style: TextStyle(color: AppColors.gold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _simulationTimer?.cancel();
    _audioPlayer.dispose();
    _completionAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nodesAsync = ref.watch(arkNotifierProvider);
    _node = nodesAsync.valueOrNull?.firstWhereOrNull((n) => n.id == widget.nodeId);

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Chapter reference header
          _ChapterRefHeader(chapterRef: _passage.chapterRef),

          // Reading text area (scrollable)
          Expanded(
            child: _ReadingTextArea(
              words: _passage.words,
              highlightIndex: _currentHighlightIndex,
              fontSize: _fontSize,
              onWordTap: _onWordTap,
            ),
          ),

          // Playback controls bar
          _PlaybackControls(
            isPlaying: _isPlaying,
            position: _position,
            duration: _duration,
            playbackSpeed: _playbackSpeed,
            onPlayPause: _togglePlayPause,
            onSeek: (val) => _audioPlayer.seek(
              Duration(milliseconds: (val * _duration.inMilliseconds).toInt()),
            ),
            onSpeedTap: _showSpeedPicker,
            onFontSizeIncrease: () =>
                setState(() => _fontSize = (_fontSize + 2).clamp(12, 28)),
            onFontSizeDecrease: () =>
                setState(() => _fontSize = (_fontSize - 2).clamp(12, 28)),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.purpleDark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.goldLight),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Interactive Reading',
        style: AppTextStyles.headlineSmall.copyWith(color: AppColors.goldLight),
      ),
      actions: [
        if (_isCompleted)
          const Padding(
            padding: EdgeInsets.only(right: AppSpacing.md),
            child: Icon(Icons.check_circle, color: AppColors.sage, size: 22),
          ),
      ],
    );
  }

  void _onWordTap(_ReadingWord word) {
    // In production: call TTS to read this word aloud
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pronunciation: "${word.text}"'),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.darkCard,
      ),
    );
  }

  void _showSpeedPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Reading Speed',
              style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.goldLight),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              children: _speeds.map((speed) {
                final isSelected = speed == _playbackSpeed;
                return GestureDetector(
                  onTap: () {
                    _setSpeed(speed);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.gold.withOpacity(0.2)
                          : AppColors.darkElevated,
                      borderRadius: AppSpacing.borderRadiusMd,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.gold
                            : AppColors.darkElevated,
                      ),
                    ),
                    child: Text(
                      '${speed}x',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: isSelected ? AppColors.gold : AppColors.ivory,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  /// Builds a seeded passage with timing data for the demo.
  _ReadingPassage _buildSeedPassage() {
    const chapterText =
        'In the beginning God created the heavens and the earth. '
        'The earth was without form or shape, with darkness over the abyss '
        'and a mighty wind sweeping over the waters. '
        'Then God said: Let there be light, and there was light. '
        'God saw that the light was good. '
        'God then separated the light from the darkness. '
        'God called the light "day," and the darkness he called "night." '
        'Evening came, and morning followed — the first day.';

    final rawWords = chapterText.split(' ');
    const secondsPerWord = 0.45;
    final words = rawWords.asMap().entries.map((e) {
      final i = e.key;
      return _ReadingWord(
        text: e.value,
        startSeconds: i * secondsPerWord,
        endSeconds: (i + 1) * secondsPerWord,
      );
    }).toList();

    return _ReadingPassage(
      chapterRef: 'Genesis 1:1-5 (NABRE)',
      words: words,
    );
  }
}

// ── Chapter Ref Header ────────────────────────────────────────────────────────

class _ChapterRefHeader extends StatelessWidget {
  final String chapterRef;
  const _ChapterRefHeader({required this.chapterRef});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.purpleDark,
        border: Border(bottom: BorderSide(color: AppColors.goldDark, width: 1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_stories, color: AppColors.gold, size: 16),
          const SizedBox(width: AppSpacing.xs),
          Text(
            chapterRef,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.goldLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reading Text Area ─────────────────────────────────────────────────────────

class _ReadingTextArea extends StatelessWidget {
  final List<_ReadingWord> words;
  final int highlightIndex;
  final double fontSize;
  final void Function(_ReadingWord) onWordTap;

  const _ReadingTextArea({
    required this.words,
    required this.highlightIndex,
    required this.fontSize,
    required this.onWordTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF120821),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Wrap(
          spacing: 4,
          runSpacing: 8,
          children: words.asMap().entries.map((entry) {
            final i = entry.key;
            final word = entry.value;
            final isHighlighted = i == highlightIndex;
            final isPast = i < highlightIndex;

            return GestureDetector(
              onTap: () => onWordTap(word),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 3, vertical: 2),
                decoration: isHighlighted
                    ? BoxDecoration(
                        color: AppColors.faithCoins.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.faithCoins.withOpacity(0.4),
                            blurRadius: 6,
                          ),
                        ],
                      )
                    : null,
                child: Text(
                  word.text,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontFamily: 'Cinzel',
                    color: isHighlighted
                        ? AppColors.faithCoins
                        : isPast
                            ? AppColors.parchmentDark
                            : AppColors.parchment,
                    fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w400,
                    height: 1.8,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Playback Controls ─────────────────────────────────────────────────────────

class _PlaybackControls extends StatelessWidget {
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final double playbackSpeed;
  final VoidCallback onPlayPause;
  final ValueChanged<double> onSeek;
  final VoidCallback onSpeedTap;
  final VoidCallback onFontSizeIncrease;
  final VoidCallback onFontSizeDecrease;

  const _PlaybackControls({
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.playbackSpeed,
    required this.onPlayPause,
    required this.onSeek,
    required this.onSpeedTap,
    required this.onFontSizeIncrease,
    required this.onFontSizeDecrease,
  });

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.sm,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.purpleDark,
        border: Border(top: BorderSide(color: AppColors.goldDark, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Seek bar
          Row(
            children: [
              Text(
                _formatDuration(position),
                style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.midGrey),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.gold,
                    inactiveTrackColor: AppColors.darkCard,
                    thumbColor: AppColors.gold,
                    overlayColor: AppColors.gold.withOpacity(0.2),
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                    trackHeight: 3,
                  ),
                  child: Slider(
                    value: progress.clamp(0.0, 1.0),
                    onChanged: onSeek,
                  ),
                ),
              ),
              Text(
                _formatDuration(duration),
                style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.midGrey),
              ),
            ],
          ),
          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Font decrease
              IconButton(
                onPressed: onFontSizeDecrease,
                icon: const Icon(Icons.text_decrease,
                    color: AppColors.parchment, size: 20),
              ),
              // Play / Pause button
              GestureDetector(
                onTap: onPlayPause,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.deepPurple,
                    border: Border.all(color: AppColors.gold, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: AppColors.gold,
                    size: 28,
                  ),
                ),
              ),
              // Font increase
              IconButton(
                onPressed: onFontSizeIncrease,
                icon: const Icon(Icons.text_increase,
                    color: AppColors.parchment, size: 20),
              ),
              // Speed control
              GestureDetector(
                onTap: onSpeedTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: AppSpacing.borderRadiusSm,
                    border:
                        Border.all(color: AppColors.goldDark.withOpacity(0.5)),
                  ),
                  child: Text(
                    '${playbackSpeed}x',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.goldLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Extension ─────────────────────────────────────────────────────────────────

extension _ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
