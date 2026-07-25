import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

final ttsServiceProvider = Provider<TtsService>((ref) {
  final svc = TtsService();
  ref.onDispose(svc.dispose);
  return svc;
});

class TtsService {
  final FlutterTts _tts = FlutterTts();
  final math.Random _rnd = math.Random();
  bool _ready = false;

  TtsService() {
    _init();
  }

  Future<void> _init() async {
    // Prefer Google's TTS engine on Android — noticeably less robotic than
    // device-default engines.
    try {
      await _tts.setEngine('com.google.android.tts');
    } catch (_) {}
    await _tts.setVolume(1.0);
    // Slightly raised pitch + gentle rate reads as friendly. Overdoing the
    // pitch makes synthetic voices sound MORE robotic, so keep it subtle.
    await _tts.setPitch(1.12);
    await _tts.setSpeechRate(0.46);
    // Make speak() complete only when the speech actually finishes, so
    // screens can wait for a sentence to end before moving on.
    await _tts.awaitSpeakCompletion(true);
    await _pickBestVoice();
    _ready = true;
  }

  /// Try to find the highest-quality, friendliest voice installed on the
  /// device. Falls back silently to the system default.
  Future<void> _pickBestVoice() async {
    try {
      final raw = await _tts.getVoices;
      if (raw is! List) return;
      final voices = raw
          .whereType<Map>()
          .map((v) => (
                name: (v['name'] ?? '').toString(),
                locale: (v['locale'] ?? '').toString(),
              ))
          .where((v) => v.locale.toLowerCase().startsWith('en'))
          .toList();
      if (voices.isEmpty) return;

      int score(({String name, String locale}) v) {
        final n = v.name.toLowerCase();
        var s = 0;
        // Google "x-..." voices are neural and far less robotic.
        if (n.contains('-x-')) s += 4;
        if (n.contains('local')) s += 2; // works offline
        if (n.contains('female')) s += 2;
        if (n.contains('network')) s += 1; // best quality, needs internet
        if (v.locale.toLowerCase() == 'en-us') s += 1;
        return s;
      }

      voices.sort((a, b) => score(b).compareTo(score(a)));
      final best = voices.first;
      await _tts.setVoice({'name': best.name, 'locale': best.locale});
    } catch (_) {
      // Any failure: keep the default voice.
    }
  }

  Future<void> setLocale(String locale) async {
    // Map our locale codes to TTS language codes
    final lang = switch (locale) {
      'es' => 'es-ES',
      'tl' => 'fil-PH',
      _ => 'en-US',
    };
    await _tts.setLanguage(lang);
  }

  Future<void> speak(String text) async {
    if (!_ready || text.isEmpty) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  static const _praise = [
    'Amazing! Well done!',
    'Wow, you did it!',
    'Great job! High five!',
    'You are so smart!',
    'Fantastic! Keep going!',
    'Woohoo! That was perfect!',
    'Super duper! You got it!',
    'Incredible! You are a star!',
  ];

  static const _encourage = [
    'Almost! Try again, you can do it!',
    'Good try! Let\'s look one more time.',
    'So close! Give it another go!',
    'Keep trying, I believe in you!',
  ];

  static const _namePraise = [
    'Amazing, NAME!',
    'Great job, NAME!',
    'NAME, you are a star!',
    'Wow, NAME, you did it!',
    'NAME, that was perfect!',
  ];

  /// Speak a random praise line — varied so it never feels canned.
  /// Pass the child's [name] to personalize about half the time.
  Future<void> praise([String? name]) {
    if (name != null && name.isNotEmpty && _rnd.nextBool()) {
      final line = _namePraise[_rnd.nextInt(_namePraise.length)];
      return speak(line.replaceAll('NAME', name));
    }
    return speak(_praise[_rnd.nextInt(_praise.length)]);
  }

  /// Speak a random gentle encouragement after a miss.
  Future<void> encourage() =>
      speak(_encourage[_rnd.nextInt(_encourage.length)]);

  Future<void> stop() async => _tts.stop();

  void dispose() => _tts.stop();
}
