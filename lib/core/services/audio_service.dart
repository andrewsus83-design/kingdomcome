import 'dart:async';

import 'package:just_audio/just_audio.dart';

import 'package:kingdomcome/core/theme/liturgical_colors.dart';

/// Singleton audio service that manages background ambient music, sound
/// effects, and ElevenLabs/MusicGen narration tracks.
///
/// Responsibilities:
///   • Background ambient music that loops continuously (one [AudioPlayer]).
///   • One-shot SFX using pooled [AudioPlayer] instances.
///   • ElevenLabs narration and MusicGen track playback with fade transitions.
///   • Volume control and mute toggle.
///   • Automatic liturgical-season ambient selection.
///   • Fetching verse narration from the Cloudflare Worker audio endpoints.
class AudioService {
  AudioService._();

  static final AudioService _instance = AudioService._();

  /// Access the singleton instance.
  static AudioService get instance => _instance;

  // ── Players ─────────────────────────────────────────────────────────────────

  final AudioPlayer _ambientPlayer = AudioPlayer();

  /// Player used for ElevenLabs narrations and MusicGen victory jingles.
  final AudioPlayer _narrationPlayer = AudioPlayer();

  // SFX pool — reuse players to avoid creation overhead on each effect
  final List<AudioPlayer> _sfxPool = List.generate(4, (_) => AudioPlayer());
  int _sfxPoolIndex = 0;

  // ── State ────────────────────────────────────────────────────────────────────

  bool _isMuted = false;
  double _volume = 0.6; // 0.0 – 1.0
  bool _ambientActive = false;
  String? _currentAmbientUrl;

  /// URL of the currently playing narration (ElevenLabs TTS or MusicGen).
  String? _currentNarrationUrl;

  // ── Getters ──────────────────────────────────────────────────────────────────

  bool get isMuted => _isMuted;
  double get volume => _volume;
  bool get isAmbientPlaying => _ambientActive;
  bool get isNarrationPlaying =>
      _narrationPlayer.playing &&
      _narrationPlayer.processingState != ProcessingState.idle;
  String? get currentAmbientUrl => _currentAmbientUrl;
  String? get currentNarrationUrl => _currentNarrationUrl;

  // ── Initialise ───────────────────────────────────────────────────────────────

  /// Call once at app startup (e.g., in main.dart after WidgetsFlutterBinding).
  Future<void> init() async {
    await _ambientPlayer.setVolume(_effectiveVolume(0.4));
    await _narrationPlayer.setVolume(_effectiveVolume(_volume));
    _ambientPlayer.setLoopMode(LoopMode.one);
  }

  // ── Ambient music ─────────────────────────────────────────────────────────────

  /// Plays ambient music from [url], looping indefinitely.
  ///
  /// If the same URL is already playing, this is a no-op.
  /// Fades in over 1.5 seconds.
  Future<void> playAmbient(String url) async {
    if (_currentAmbientUrl == url && _ambientActive) return;

    _currentAmbientUrl = url;
    _ambientActive = true;

    await _ambientPlayer.stop();
    await _ambientPlayer.setVolume(0);
    await _ambientPlayer.setUrl(url);
    await _ambientPlayer.setLoopMode(LoopMode.one);
    await _ambientPlayer.play();
    await _fadeIn(_ambientPlayer, _effectiveVolume(0.4));
  }

  /// Stops ambient music with a fade-out.
  Future<void> stopAmbient() async {
    _ambientActive = false;
    _currentAmbientUrl = null;
    await _fadeOut(_ambientPlayer);
    await _ambientPlayer.stop();
  }

  /// Pauses ambient music.
  Future<void> pauseAmbient() async {
    _ambientActive = false;
    await _fadeOut(_ambientPlayer, duration: const Duration(milliseconds: 600));
    await _ambientPlayer.pause();
  }

  /// Resumes ambient music.
  Future<void> resumeAmbient() async {
    _ambientActive = true;
    await _ambientPlayer.play();
    await _fadeIn(_ambientPlayer, _effectiveVolume(0.4));
  }

  // ── SFX ───────────────────────────────────────────────────────────────────────

  /// Plays a short sound effect from an asset path (e.g., `assets/audio/chime.mp3`).
  ///
  /// Uses a round-robin pool of [AudioPlayer] instances to support overlapping
  /// effects.
  Future<void> playSfx(String assetPath) async {
    if (_isMuted) return;
    final player = _sfxPool[_sfxPoolIndex % _sfxPool.length];
    _sfxPoolIndex++;
    try {
      await player.setVolume(_effectiveVolume(_volume));
      await player.setAsset(assetPath);
      await player.seek(Duration.zero);
      await player.play();
    } catch (_) {
      // SFX errors are non-fatal
    }
  }

  // ── ElevenLabs narration / MusicGen track ─────────────────────────────────────

  /// Plays an ElevenLabs narration or MusicGen track from [url].
  ///
  /// Fades out any currently playing narration first, then fades in the new one.
  /// Accepts both regular https:// URLs and data: URIs returned by ElevenLabs.
  Future<void> playNarration(String url) async {
    if (_currentNarrationUrl == url && _narrationPlayer.playing) return;

    _currentNarrationUrl = url;

    if (_narrationPlayer.playing) {
      await _fadeOut(_narrationPlayer, duration: const Duration(milliseconds: 800));
      await _narrationPlayer.stop();
    }

    await _narrationPlayer.setVolume(0);
    await _narrationPlayer.setUrl(url);
    await _narrationPlayer.setLoopMode(LoopMode.off);
    await _narrationPlayer.play();
    await _fadeIn(_narrationPlayer, _effectiveVolume(_volume));
  }

  /// Pauses the current narration.
  Future<void> pauseNarration() async {
    await _fadeOut(_narrationPlayer, duration: const Duration(milliseconds: 500));
    await _narrationPlayer.pause();
  }

  /// Resumes the paused narration.
  Future<void> resumeNarration() async {
    await _narrationPlayer.play();
    await _fadeIn(_narrationPlayer, _effectiveVolume(_volume));
  }

  /// Stops the narration.
  Future<void> stopNarration() async {
    _currentNarrationUrl = null;
    await _fadeOut(_narrationPlayer);
    await _narrationPlayer.stop();
  }

  // ── Auto-ambient by liturgical season ─────────────────────────────────────────

  /// Fetches and plays the MusicGen ambient track for the current [season].
  ///
  /// [seasonAmbientUrlResolver] should call the Cloudflare Worker endpoint
  /// `POST /music/ambient` with the season name and return the audio URL.
  Future<void> playSeasonAmbient(
    LiturgicalSeason season,
    Future<String?> Function(LiturgicalSeason) seasonAmbientUrlResolver,
  ) async {
    final url = await seasonAmbientUrlResolver(season);
    if (url == null || url.isEmpty) return;
    await playAmbient(url);
  }

  /// Fetches a verse narration URL from the Cloudflare Worker
  /// `POST /audio/narrate-verse` endpoint and plays it.
  ///
  /// Returns the audio URL on success, or null on failure.
  Future<String?> narrateVerse(
    String text,
    String verseRef, {
    String? saintNarratorId,
    required Future<String?> Function(String text, String verseRef, String? saintNarratorId)
        narrateVerseResolver,
  }) async {
    final url = await narrateVerseResolver(text, verseRef, saintNarratorId);
    if (url == null || url.isEmpty) return null;
    await playNarration(url);
    return url;
  }

  /// Fetches ambient music for the given liturgical [season] via the
  /// Cloudflare Worker `POST /music/ambient` endpoint.
  ///
  /// Returns the audio URL on success, or null on failure.
  Future<String?> getAmbientMusic(
    String liturgicalSeason, {
    required Future<String?> Function(String season) ambientMusicResolver,
  }) async {
    final url = await ambientMusicResolver(liturgicalSeason);
    if (url == null || url.isEmpty) return null;
    await playAmbient(url);
    return url;
  }

  // ── Volume ────────────────────────────────────────────────────────────────────

  /// Sets the master volume (0.0 – 1.0).
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _ambientPlayer.setVolume(_effectiveVolume(0.4));
    await _narrationPlayer.setVolume(_effectiveVolume(_volume));
    for (final p in _sfxPool) {
      await p.setVolume(_effectiveVolume(_volume));
    }
  }

  /// Toggles mute state.
  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    final ambientVol = _isMuted ? 0.0 : _effectiveVolume(0.4);
    final trackVol = _isMuted ? 0.0 : _effectiveVolume(_volume);
    await _ambientPlayer.setVolume(ambientVol);
    await _narrationPlayer.setVolume(trackVol);
  }

  /// Mutes audio.
  Future<void> mute() async {
    _isMuted = true;
    await _ambientPlayer.setVolume(0);
    await _narrationPlayer.setVolume(0);
  }

  /// Unmutes audio.
  Future<void> unmute() async {
    _isMuted = false;
    await _ambientPlayer.setVolume(_effectiveVolume(0.4));
    await _narrationPlayer.setVolume(_effectiveVolume(_volume));
  }

  // ── Dispose ───────────────────────────────────────────────────────────────────

  /// Releases all audio resources. Call on app exit.
  Future<void> dispose() async {
    await _ambientPlayer.dispose();
    await _narrationPlayer.dispose();
    for (final p in _sfxPool) {
      await p.dispose();
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────────

  double _effectiveVolume(double target) => _isMuted ? 0.0 : target.clamp(0.0, 1.0);

  Future<void> _fadeIn(
    AudioPlayer player,
    double targetVolume, {
    Duration duration = const Duration(milliseconds: 1500),
  }) async {
    const steps = 30;
    final stepDuration = duration ~/ steps;
    final volumeStep = targetVolume / steps;

    for (int i = 1; i <= steps; i++) {
      await Future<void>.delayed(stepDuration);
      final newVol = (volumeStep * i).clamp(0.0, 1.0);
      await player.setVolume(newVol);
    }
  }

  Future<void> _fadeOut(
    AudioPlayer player, {
    Duration duration = const Duration(milliseconds: 1200),
  }) async {
    final currentVolume = player.volume;
    if (currentVolume <= 0.0) return;

    const steps = 24;
    final stepDuration = duration ~/ steps;
    final volumeStep = currentVolume / steps;

    for (int i = steps - 1; i >= 0; i--) {
      await Future<void>.delayed(stepDuration);
      final newVol = (volumeStep * i).clamp(0.0, 1.0);
      await player.setVolume(newVol);
    }
  }
}
