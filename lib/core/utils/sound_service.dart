import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide sound effects and ambient music.
///
/// All sounds are original synthesized WAVs in assets/audio/ — no licensing,
/// fully offline. Static API so any widget can play a sound without
/// plumbing providers: `SoundFx.play('correct')`.
class SoundFx {
  SoundFx._();

  static const _prefMusic = 'soundfx_music_volume';
  static const _prefSfx = 'soundfx_sfx_volume';

  /// Master switch (a parent setting can toggle this later).
  static bool muted = false;

  /// Background lullaby level (0–1). Kids can change this on-screen.
  static double musicVolume = 0.45;

  /// Tap / correct / celebrate SFX level (0–1).
  static double sfxVolume = 0.75;

  static bool _prefsLoaded = false;

  // Small round-robin pool so rapid sounds don't cut each other off.
  static final List<AudioPlayer> _pool =
      List.generate(4, (_) => AudioPlayer());
  static int _next = 0;

  /// Load saved volumes (call once at app start).
  static Future<void> init() async {
    if (_prefsLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      musicVolume = (prefs.getDouble(_prefMusic) ?? 0.45).clamp(0.0, 1.0);
      sfxVolume = (prefs.getDouble(_prefSfx) ?? 0.75).clamp(0.0, 1.0);
      _prefsLoaded = true;
      if (_currentAmbient != null && !muted) {
        await _ambientPlayer.setVolume(musicVolume);
      }
    } catch (_) {}
  }

  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefMusic, musicVolume);
      await prefs.setDouble(_prefSfx, sfxVolume);
    } catch (_) {}
  }

  /// Fire-and-forget SFX: tap, place, correct, wrong, flip, step, crash,
  /// celebrate, levelup.
  static Future<void> play(String name, {double volume = 1.0}) async {
    if (muted || sfxVolume <= 0.01) return;
    final p = _pool[_next];
    _next = (_next + 1) % _pool.length;
    try {
      await p.stop();
      await p.setVolume((volume * sfxVolume).clamp(0.0, 1.0));
      await p.play(AssetSource('audio/$name.wav'));
    } catch (_) {
      // Sound must never break gameplay.
    }
  }

  // ── Ambient music / atmosphere ────────────────────────────────────

  static final AudioPlayer _ambientPlayer = AudioPlayer();
  static String? _currentAmbient;

  /// Great-grandma's lullaby loop (original family song tone).
  static const String themeTrack = 'family_song_loop';

  /// Start (or switch) the looping background track. Pass null to stop.
  static Future<void> ambient(String? name, {double? volume}) async {
    await init();
    final vol = (volume ?? musicVolume).clamp(0.0, 1.0);
    if (name == _currentAmbient && name != null) {
      try {
        await _ambientPlayer.setVolume(muted ? 0.0 : vol);
      } catch (_) {}
      return;
    }
    _currentAmbient = name;
    try {
      await _ambientPlayer.stop();
      if (name == null || muted || vol <= 0.01) return;
      await _ambientPlayer.setReleaseMode(ReleaseMode.loop);
      await _ambientPlayer.setVolume(vol);
      await _ambientPlayer.play(AssetSource('audio/$name.wav'));
    } catch (_) {}
  }

  /// Scene ambience — grandmother lullaby throughout kid screens.
  static Future<void> ambientForScene(String scene) {
    return ambient(themeTrack);
  }

  static Future<void> setMusicVolume(double value) async {
    musicVolume = value.clamp(0.0, 1.0);
    await _persist();
    if (_currentAmbient != null) {
      await ambient(_currentAmbient);
    } else {
      await ambient(themeTrack);
    }
  }

  static Future<void> setSfxVolume(double value) async {
    sfxVolume = value.clamp(0.0, 1.0);
    await _persist();
  }

  static Future<void> nudgeMusic(double delta) =>
      setMusicVolume(musicVolume + delta);

  static Future<void> nudgeSfx(double delta) =>
      setSfxVolume(sfxVolume + delta);
}
