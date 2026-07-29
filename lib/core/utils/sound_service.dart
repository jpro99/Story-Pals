import 'package:audioplayers/audioplayers.dart';

/// App-wide sound effects and ambient music.
///
/// All sounds are original synthesized WAVs in assets/audio/ — no licensing,
/// fully offline. Static API so any widget can play a sound without
/// plumbing providers: `SoundFx.play('correct')`.
class SoundFx {
  SoundFx._();

  /// Master switch (a parent setting can toggle this later).
  static bool muted = false;

  // Small round-robin pool so rapid sounds don't cut each other off.
  static final List<AudioPlayer> _pool =
      List.generate(4, (_) => AudioPlayer());
  static int _next = 0;

  /// Fire-and-forget SFX: tap, place, correct, wrong, flip, step, crash,
  /// celebrate, levelup.
  static Future<void> play(String name, {double volume = 0.6}) async {
    if (muted) return;
    final p = _pool[_next];
    _next = (_next + 1) % _pool.length;
    try {
      await p.stop();
      await p.setVolume(volume);
      await p.play(AssetSource('audio/$name.wav'));
    } catch (_) {
      // Sound must never break gameplay.
    }
  }

  // ── Ambient music / atmosphere ────────────────────────────────────

  static final AudioPlayer _ambientPlayer = AudioPlayer();
  static String? _currentAmbient;

  /// Great-grandma's lullaby, synthesized as a soft music-box loop.
  /// Used as the single ambient theme across the kid experience.
  static const String themeTrack = 'grandma_theme_loop';

  /// Start (or switch) the looping background track. Pass null to stop.
  /// Default theme is [themeTrack] (grandma lullaby music box).
  static Future<void> ambient(String? name, {double volume = 0.22}) async {
    if (_currentAmbient == name) return;
    _currentAmbient = name;
    try {
      await _ambientPlayer.stop();
      if (name == null || muted) return;
      await _ambientPlayer.setReleaseMode(ReleaseMode.loop);
      await _ambientPlayer.setVolume(volume);
      await _ambientPlayer.play(AssetSource('audio/$name.wav'));
    } catch (_) {}
  }

  /// Scene ambience — one lullaby theme throughout (jungle/bedroom/map/etc.).
  static Future<void> ambientForScene(String scene) {
    return ambient(themeTrack, volume: 0.20);
  }
}
