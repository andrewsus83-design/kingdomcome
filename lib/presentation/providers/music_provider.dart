import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/services/audio_service.dart';
import '../../core/theme/liturgical_colors.dart';
import '../../data/repositories/music_repository.dart';
import 'liturgical_calendar_provider.dart';

part 'music_provider.g.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class MusicState {
  const MusicState({
    this.isPlaying = false,
    this.currentTrack,
    this.volume = 0.6,
    this.isMuted = false,
    this.isGenerating = false,
    this.generationError,
    this.generatedTracks = const [],
  });

  final bool isPlaying;
  final String? currentTrack;
  final double volume;
  final bool isMuted;
  final bool isGenerating;
  final String? generationError;
  final List<GeneratedTrack> generatedTracks;

  MusicState copyWith({
    bool? isPlaying,
    String? currentTrack,
    double? volume,
    bool? isMuted,
    bool? isGenerating,
    String? generationError,
    List<GeneratedTrack>? generatedTracks,
    bool clearError = false,
  }) {
    return MusicState(
      isPlaying: isPlaying ?? this.isPlaying,
      currentTrack: currentTrack ?? this.currentTrack,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      isGenerating: isGenerating ?? this.isGenerating,
      generationError: clearError ? null : (generationError ?? this.generationError),
      generatedTracks: generatedTracks ?? this.generatedTracks,
    );
  }
}

class GeneratedTrack {
  const GeneratedTrack({
    required this.id,
    required this.title,
    required this.audioUrl,
    required this.type,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String audioUrl;
  final GeneratedTrackType type;
  final DateTime createdAt;
}

enum GeneratedTrackType { verseHymn, feastDay, questVictory, custom }

// ── Repository provider ───────────────────────────────────────────────────────

/// Provide the MusicRepository. Override in tests.
final musicRepositoryProvider = Provider<MusicRepository>((ref) {
  throw UnimplementedError(
    'musicRepositoryProvider must be overridden with a MusicRepositoryImpl.',
  );
});

// ── Notifier ──────────────────────────────────────────────────────────────────

@riverpod
class MusicNotifier extends _$MusicNotifier {
  late final MusicRepository _repo;
  final AudioService _audio = AudioService.instance;

  @override
  MusicState build() {
    _repo = ref.read(musicRepositoryProvider);

    // Auto-play ambient for current liturgical season on first build
    final season = ref.read(currentSeasonProvider);
    _loadSeasonAmbient(season);

    return const MusicState(isPlaying: false, volume: 0.6);
  }

  // ── Season ambient ────────────────────────────────────────────────────────────

  /// Loads and plays ambient music matching the current liturgical season.
  Future<void> _loadSeasonAmbient(LiturgicalSeason season) async {
    final seasonKey = _seasonToKey(season);
    final result = await _repo.getSeasonAmbient(seasonKey);
    result.fold(
      (failure) {
        // Non-fatal: ambient will simply be silent
      },
      (url) async {
        await _audio.playAmbient(url);
        state = state.copyWith(isPlaying: true, currentTrack: url);
      },
    );
  }

  // ── Verse hymn ────────────────────────────────────────────────────────────────

  /// Generates a hymn from [verseText] / [verseRef] in the given [style],
  /// then plays it immediately.
  Future<void> generateAndPlayVerseHymn({
    required String verseText,
    required String verseRef,
    String style = 'hymn',
  }) async {
    state = state.copyWith(isGenerating: true, clearError: true);
    final result = await _repo.generateVerseHymn(verseText, verseRef, style);
    result.fold(
      (failure) {
        state = state.copyWith(isGenerating: false, generationError: failure.message);
      },
      (url) async {
        final track = GeneratedTrack(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: '$verseRef Hymn',
          audioUrl: url,
          type: GeneratedTrackType.verseHymn,
          createdAt: DateTime.now(),
        );
        await _audio.playSunoTrack(url);
        state = state.copyWith(
          isGenerating: false,
          isPlaying: true,
          currentTrack: url,
          generatedTracks: [track, ...state.generatedTracks],
        );
      },
    );
  }

  // ── Feast day song ────────────────────────────────────────────────────────────

  /// Generates a feast day song for [saintName] and plays it.
  Future<void> generateFeastDaySong({
    required String saintName,
    String patronage = '',
    String era = 'medieval',
  }) async {
    state = state.copyWith(isGenerating: true, clearError: true);
    final result = await _repo.generateFeastDaySong(saintName, patronage, era);
    result.fold(
      (failure) {
        state = state.copyWith(isGenerating: false, generationError: failure.message);
      },
      (url) async {
        final track = GeneratedTrack(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Feast of $saintName',
          audioUrl: url,
          type: GeneratedTrackType.feastDay,
          createdAt: DateTime.now(),
        );
        await _audio.playSunoTrack(url);
        state = state.copyWith(
          isGenerating: false,
          isPlaying: true,
          currentTrack: url,
          generatedTracks: [track, ...state.generatedTracks],
        );
      },
    );
  }

  // ── Victory jingle ────────────────────────────────────────────────────────────

  /// Generates and plays a victory jingle for the given [questCategory].
  Future<void> playQuestVictoryJingle(String questCategory) async {
    final result = await _repo.generateQuestVictoryJingle(questCategory);
    result.fold((_) {}, (url) async {
      await _audio.playSunoTrack(url);
    });
  }

  // ── Playback controls ─────────────────────────────────────────────────────────

  /// Plays [url] as a Suno track.
  Future<void> playTrack(String url) async {
    await _audio.playSunoTrack(url);
    state = state.copyWith(isPlaying: true, currentTrack: url);
  }

  /// Toggles music on/off (pauses/resumes Suno track; ambient remains as-is).
  Future<void> toggleMusic() async {
    if (state.isPlaying) {
      await _audio.pauseSunoTrack();
      state = state.copyWith(isPlaying: false);
    } else {
      await _audio.resumeSunoTrack();
      state = state.copyWith(isPlaying: true);
    }
  }

  // ── Volume ────────────────────────────────────────────────────────────────────

  /// Sets the master volume to [volume] (0.0 – 1.0).
  Future<void> setVolume(double volume) async {
    await _audio.setVolume(volume);
    state = state.copyWith(volume: volume);
  }

  /// Toggles mute state.
  Future<void> toggleMute() async {
    await _audio.toggleMute();
    state = state.copyWith(isMuted: !state.isMuted);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  String _seasonToKey(LiturgicalSeason season) {
    return switch (season) {
      LiturgicalSeason.advent => 'advent',
      LiturgicalSeason.christmas => 'christmas',
      LiturgicalSeason.lent => 'lent',
      LiturgicalSeason.easter => 'easter',
      LiturgicalSeason.pentecost => 'pentecost',
      LiturgicalSeason.ordinaryTime => 'ordinary',
    };
  }
}
