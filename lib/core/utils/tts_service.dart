import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

final ttsServiceProvider = Provider<TtsService>((ref) {
  final svc = TtsService();
  ref.onDispose(svc.dispose);
  return svc;
});

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  TtsService() {
    _init();
  }

  Future<void> _init() async {
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.15);   // slightly higher pitch = friendlier kid voice
    await _tts.setSpeechRate(0.45); // slow enough for young children
    _ready = true;
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

  Future<void> stop() async => _tts.stop();

  void dispose() => _tts.stop();
}
