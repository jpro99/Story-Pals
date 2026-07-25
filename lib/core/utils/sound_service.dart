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

  /// Start (or switch) the looping background track. Pass null to stop.
  /// Tracks: music_box_loop, jungle_loop.
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

  /// Pick the ambience matching a scene name.
  /// family_song_loop is great-grandma's lullaby melody, re-voiced as a
  /// music box — it plays on the chapter map and in bedtime scenes.
  static Future<void> ambientForScene(String scene) {
    if (scene.startsWith('jungle')) return ambient('jungle_loop');
    if (scene == 'bedroom') return ambient('family_song_loop');
    return ambient('music_box_loop');
  }
}
