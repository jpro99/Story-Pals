import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
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
    await _tts.setPitch(1.08);
    // Web Speech API treats ~1.0 as natural; 0.46 was painfully slow in browser.
    // Mobile uses 0–1 scale where ~0.55–0.6 still sounds kid-friendly.
    await _tts.setSpeechRate(kIsWeb ? 1.0 : 0.58);
    // On web, speak-completion callbacks often never fire, which freezes
    // puzzle flow waiting for praise to "finish". Don't await completion there.
    await _tts.awaitSpeakCompletion(!kIsWeb);
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

  /// Rough listen time so UI can pause without relying on flaky web callbacks.
  Duration _estimateDuration(String text) {
    final words = text.trim().isEmpty
        ? 1
        : text.trim().split(RegExp(r'\s+')).length;
    // ~160 wpm on web at rate 1.0, plus a short buffer.
    final ms = (words * (kIsWeb ? 320 : 380) + 400).clamp(700, 6000);
    return Duration(milliseconds: ms);
  }

  Future<void> speak(String text) async {
    if (!_ready || text.isEmpty) return;
    try {
      await _tts.stop();
    } catch (_) {}
    if (kIsWeb) {
      // Fire speech, then wait an estimate so callers can advance reliably.
      // ignore: unawaited_futures
      _tts.speak(text);
      await Future.delayed(_estimateDuration(text));
      return;
    }
    try {
      await _tts.speak(text).timeout(
            _estimateDuration(text) + const Duration(seconds: 2),
          );
    } catch (_) {
      // Timeout / platform glitch — don't block gameplay.
    }
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

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  void dispose() {
    _tts.stop();
  }
}
