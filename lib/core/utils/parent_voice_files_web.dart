/// Web stub — parent mic recordings are device-only; browser uses TTS.
Future<String> filePathFor(String lineId) async => '';

Future<bool> isRecorded(String lineId) async => false;

Future<void> deleteRecording(String lineId) async {}

Future<bool> existsPath(String path) async => false;
