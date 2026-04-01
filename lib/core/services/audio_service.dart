import 'dart:async';

import 'package:just_audio/just_audio.dart';

/// Liturgical seasons understood by [AudioService].
enum LiturgicalSeason {
  advent,
  christmas,
  ordinary,
  lent,
  easter,
  pentecost,
}

/// Singleton audio service that manages background ambient music, sound
/// effects, and Suno-generated tracks.
///
/// Responsibilities:
///   • Background ambient music that loops continuously (one [AudioPlayer]).
///   • One-shot SFX using pooled [AudioPlayer] instances.
///   • Suno-generated track playback with fade-in/fade-out transitions.
///   • Volume control and mute toggle.
///   • Automatic liturgical-season ambient selection.
class AudioService {
  AudioService._();

  static final AudioService _instance = AudioService._();

  /// Access the singleton instance.
  static AudioService get instance => _instance;

  // ── Players ─────────────────────────────────────────────────────────────────

  final AudioPlayer _ambientPlayer = AudioPlayer();
  final AudioPlayer _sunoPlayer = AudioPlayer();

  // SFX pool — reuse players to avoid creation overhead on each effect
  final List<AudioPlayer> _sfxPool = List.generate(4, (_) => AudioPlayer());
  int _sfxPoolIndex = 0;

  // ── State ────────────────────────────────────────────────────────────────────

  bool _isMuted = false;
  double _volume = 0.6; // 0.0 – 1.0
  bool _ambientActive = false;
  String? _currentAmbientUrl;
  String? _currentSunoUrl;

  // ── Getters ──────────────────────────────────────────────────────────────────

  bool get isMuted => _isMuted;
  double get volume => _volume;
  bool get isAmbientPlaying => _ambientActive;
  bool get isSunoPlaying =>
      _sunoPlayer.playing && _sunoPlayer.processingState != ProcessingState.idle;
  String? get currentAmbientUrl => _currentAmbientUrl;
  String? get currentSunoUrl => _currentSunoUrl;

  // ── Initialise ───────────────────────────────────────────────────────────────

  /// Call once at app startup (e.g., in main.dart after WidgetsFlutterBinding).
  Future<void> init() async {
    await _ambientPlayer.setVolume(_effectiveVolume(0.4));
    await _sunoPlayer.setVolume(_effectiveVolume(_volume));
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

  // ── Suno track ────────────────────────────────────────────────────────────────

  /// Plays a Suno-generated track from [url].
  ///
  /// Fades out any currently playing Suno track first, then fades in the new one.
  Future<void> playSunoTrack(String url) async {
    if (_currentSunoUrl == url && _sunoPlayer.playing) return;

    _currentSunoUrl = url;

    if (_sunoPlayer.playing) {
      await _fadeOut(_sunoPlayer, duration: const Duration(milliseconds: 800));
      await _sunoPlayer.stop();
    }

    await _sunoPlayer.setVolume(0);
    await _sunoPlayer.setUrl(url);
    await _sunoPlayer.setLoopMode(LoopMode.off);
    await _sunoPlayer.play();
    await _fadeIn(_sunoPlayer, _effectiveVolume(_volume));
  }

  /// Pauses the Suno track.
  Future<void> pauseSunoTrack() async {
    await _fadeOut(_sunoPlayer, duration: const Duration(milliseconds: 500));
    await _sunoPlayer.pause();
  }

  /// Resumes the paused Suno track.
  Future<void> resumeSunoTrack() async {
    await _sunoPlayer.play();
    await _fadeIn(_sunoPlayer, _effectiveVolume(_volume));
  }

  /// Stops the Suno track.
  Future<void> stopSunoTrack() async {
    _currentSunoUrl = null;
    await _fadeOut(_sunoPlayer);
    await _sunoPlayer.stop();
  }

  // ── Auto-ambient by liturgical season ─────────────────────────────────────────

  /// Fetches and plays the ambient music track for the current [season].
  ///
  /// [seasonAmbientUrlResolver] should call the Cloudflare Worker endpoint
  /// `/music/kingdom-ambient/:season` and return the audio URL.
  Future<void> playSeasonAmbient(
    LiturgicalSeason season,
    Future<String?> Function(LiturgicalSeason) seasonAmbientUrlResolver,
  ) async {
    final url = await seasonAmbientUrlResolver(season);
    if (url == null || url.isEmpty) return;
    await playAmbient(url);
  }

  // ── Volume ────────────────────────────────────────────────────────────────────

  /// Sets the master volume (0.0 – 1.0).
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _ambientPlayer.setVolume(_effectiveVolume(0.4));
    await _sunoPlayer.setVolume(_effectiveVolume(_volume));
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
    await _sunoPlayer.setVolume(trackVol);
  }

  /// Mutes audio.
  Future<void> mute() async {
    _isMuted = true;
    await _ambientPlayer.setVolume(0);
    await _sunoPlayer.setVolume(0);
  }

  /// Unmutes audio.
  Future<void> unmute() async {
    _isMuted = false;
    await _ambientPlayer.setVolume(_effectiveVolume(0.4));
    await _sunoPlayer.setVolume(_effectiveVolume(_volume));
  }

  // ── Dispose ───────────────────────────────────────────────────────────────────

  /// Releases all audio resources. Call on app exit.
  Future<void> dispose() async {
    await _ambientPlayer.dispose();
    await _sunoPlayer.dispose();
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
