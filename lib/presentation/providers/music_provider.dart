import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/services/audio_service.dart';
import '../../core/theme/liturgical_colors.dart' hide LiturgicalSeason;
import '../../data/repositories/music_repository.dart';
import 'liturgical_calendar_provider.dart';

part 'music_provider.g.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class MusicState {
  const MusicState({
    this.isPlaying = false,
    this.currentNarration,
    this.currentTrack,
    this.volume = 0.6,
    this.isMuted = false,
    this.isGenerating = false,
    this.generationError,
    this.generatedTracks = const [],
  });

  final bool isPlaying;

  /// URL of the currently active ElevenLabs narration, if any.
  final String? currentNarration;

  /// URL of the currently active MusicGen ambient/jingle track, if any.
  final String? currentTrack;

  final double volume;
  final bool isMuted;
  final bool isGenerating;
  final String? generationError;
  final List<GeneratedTrack> generatedTracks;

  MusicState copyWith({
    bool? isPlaying,
    String? currentNarration,
    String? currentTrack,
    double? volume,
    bool? isMuted,
    bool? isGenerating,
    String? generationError,
    List<GeneratedTrack>? generatedTracks,
    bool clearError = false,
    bool clearNarration = false,
  }) {
    return MusicState(
      isPlaying: isPlaying ?? this.isPlaying,
      currentNarration: clearNarration ? null : (currentNarration ?? this.currentNarration),
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

enum GeneratedTrackType { verseNarration, saintVoice, questVictory, ambient }

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

    // Auto-play MusicGen ambient for current liturgical season on first build
    final season = ref.read(currentSeasonProvider);
    _loadSeasonAmbient(season);

    return const MusicState(isPlaying: false, volume: 0.6);
  }

  // ── Season ambient (MusicGen via Modal.com) ───────────────────────────────────

  /// Loads and plays MusicGen ambient music matching the current liturgical season.
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

  // ── Verse narration (ElevenLabs TTS) ─────────────────────────────────────────

  /// Narrates [verseText] / [verseRef] via ElevenLabs TTS and plays it.
  ///
  /// When [saintVoiceId] is provided the narration uses that saint's unique
  /// ElevenLabs voice ID.
  Future<void> narrateAndPlayVerse({
    required String verseText,
    required String verseRef,
    String? saintVoiceId,
    String? saintName,
  }) async {
    state = state.copyWith(isGenerating: true, clearError: true);
    final result = await _repo.narrateVerse(
      verseText,
      verseRef,
      saintVoiceId: saintVoiceId,
    );
    result.fold(
      (failure) {
        state = state.copyWith(isGenerating: false, generationError: failure.message);
      },
      (url) async {
        final trackTitle = saintName != null
            ? '$verseRef — narrated by $saintName'
            : '$verseRef — Narration';
        final track = GeneratedTrack(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: trackTitle,
          audioUrl: url,
          type: GeneratedTrackType.verseNarration,
          createdAt: DateTime.now(),
        );
        await _audio.playNarration(url);
        state = state.copyWith(
          isGenerating: false,
          isPlaying: true,
          currentNarration: url,
          generatedTracks: [track, ...state.generatedTracks],
        );
      },
    );
  }

  // ── Saint voice narration (ElevenLabs TTS) ────────────────────────────────────

  /// Narrates [text] using [saintName]'s ElevenLabs voice and plays it.
  Future<void> narrateWithSaintVoice({
    required String saintName,
    required String text,
  }) async {
    state = state.copyWith(isGenerating: true, clearError: true);
    final result = await _repo.narrateWithSaintVoice(saintName, text);
    result.fold(
      (failure) {
        state = state.copyWith(isGenerating: false, generationError: failure.message);
      },
      (url) async {
        final track = GeneratedTrack(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Narrated by $saintName',
          audioUrl: url,
          type: GeneratedTrackType.saintVoice,
          createdAt: DateTime.now(),
        );
        await _audio.playNarration(url);
        state = state.copyWith(
          isGenerating: false,
          isPlaying: true,
          currentNarration: url,
          generatedTracks: [track, ...state.generatedTracks],
        );
      },
    );
  }

  // ── Victory jingle (MusicGen via Modal.com) ───────────────────────────────────

  /// Generates and plays a MusicGen victory jingle for the given [questCategory].
  Future<void> playQuestVictoryJingle(String questCategory) async {
    final result = await _repo.getVictoryJingle(questCategory);
    result.fold((_) {}, (url) async {
      await _audio.playNarration(url);
    });
  }

  // ── Playback controls ─────────────────────────────────────────────────────────

  /// Plays [url] as a narration track.
  Future<void> playTrack(String url) async {
    await _audio.playNarration(url);
    state = state.copyWith(isPlaying: true, currentNarration: url);
  }

  /// Toggles narration on/off (pauses/resumes; ambient remains as-is).
  Future<void> toggleMusic() async {
    if (state.isPlaying) {
      await _audio.pauseNarration();
      state = state.copyWith(isPlaying: false);
    } else {
      await _audio.resumeNarration();
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
