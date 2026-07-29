import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'parent_voice_files.dart'
    if (dart.library.html) 'parent_voice_files_web.dart' as voice_files;
import 'tts_service.dart';

/// A line the parent can record in their own voice.
class VoiceLine {
  const VoiceLine({required this.id, required this.text, required this.category});
  final String id;
  final String text;
  final String category; // 'praise' | 'encourage' | 'moment'
}

/// The script parents read during setup. Short, natural, high-emotion lines —
/// the moments where a real parent voice matters most.
const parentVoiceLines = <VoiceLine>[
  VoiceLine(id: 'praise_1', text: 'Amazing! Well done!', category: 'praise'),
  VoiceLine(id: 'praise_2', text: 'Wow, you did it!', category: 'praise'),
  VoiceLine(
      id: 'praise_3',
      text: "Great job! I'm so proud of you!",
      category: 'praise'),
  VoiceLine(id: 'praise_4', text: 'You are so smart!', category: 'praise'),
  VoiceLine(
      id: 'praise_5', text: 'Fantastic! Keep going!', category: 'praise'),
  VoiceLine(
      id: 'praise_6', text: 'Woohoo! That was perfect!', category: 'praise'),
  VoiceLine(
      id: 'encourage_1',
      text: 'Almost! Try again, you can do it!',
      category: 'encourage'),
  VoiceLine(
      id: 'encourage_2',
      text: "Good try! Let's look one more time.",
      category: 'encourage'),
  VoiceLine(
      id: 'encourage_3',
      text: 'So close! Give it another go!',
      category: 'encourage'),
  VoiceLine(
      id: 'moment_levelup',
      text: "Level up! You're getting so good at this!",
      category: 'moment'),
  VoiceLine(
      id: 'moment_hello',
      text: "Let's play and learn together!",
      category: 'moment'),
  VoiceLine(
      id: 'moment_done',
      text: 'All done! I love you!',
      category: 'moment'),
];

final parentVoiceServiceProvider = Provider<ParentVoiceService>((ref) {
  final svc = ParentVoiceService(ref.read(ttsServiceProvider));
  ref.onDispose(svc.dispose);
  return svc;
});

/// Plays parent-recorded lines when available, falls back to TTS when not.
/// Recordings live in the app's private documents folder and never leave
/// the device. On web, recordings are skipped (TTS only).
class ParentVoiceService {
  ParentVoiceService(this._tts);
  final TtsService _tts;
  final AudioPlayer _player = AudioPlayer();
  final math.Random _rnd = math.Random();

  static Future<String> filePathFor(String lineId) =>
      voice_files.filePathFor(lineId);

  static Future<bool> isRecorded(String lineId) async {
    if (kIsWeb) return false;
    return voice_files.isRecorded(lineId);
  }

  static Future<void> deleteRecording(String lineId) async {
    if (kIsWeb) return;
    await voice_files.deleteRecording(lineId);
  }

  Future<List<VoiceLine>> _recordedIn(String category) async {
    if (kIsWeb) return const [];
    final out = <VoiceLine>[];
    for (final line in parentVoiceLines) {
      if (line.category == category && await isRecorded(line.id)) {
        out.add(line);
      }
    }
    return out;
  }

  /// Play a random parent-recorded line from [category]; returns false if
  /// none are recorded (caller should fall back to TTS).
  Future<bool> _playFrom(String category) async {
    final recorded = await _recordedIn(category);
    if (recorded.isEmpty) return false;
    final line = recorded[_rnd.nextInt(recorded.length)];
    return playLine(line.id);
  }

  /// Play one specific recorded line. Completes when playback finishes.
  Future<bool> playLine(String lineId) async {
    if (kIsWeb) return false;
    final path = await filePathFor(lineId);
    if (!await voice_files.existsPath(path)) return false;
    try {
      await _tts.stop();
      await _player.stop();
      await _player.play(DeviceFileSource(path));
      await _player.onPlayerComplete.first
          .timeout(const Duration(seconds: 8));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Praise in the parent's voice if recorded, otherwise friendly TTS.
  Future<void> praise([String? childName]) async {
    if (await _playFrom('praise')) return;
    await _tts.praise(childName);
  }

  /// Encourage after a miss — parent's voice first, TTS fallback.
  Future<void> encourage() async {
    if (await _playFrom('encourage')) return;
    await _tts.encourage();
  }

  /// Level-up moment — parent's voice first, TTS fallback.
  Future<void> levelUp(String spokenFallback) async {
    if (await playLine('moment_levelup')) return;
    await _tts.speak(spokenFallback);
  }

  Future<void> stop() async {
    await _player.stop();
    await _tts.stop();
  }

  void dispose() {
    _player.dispose();
  }
}
