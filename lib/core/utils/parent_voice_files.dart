import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<Directory> _dir() async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory('${docs.path}/parent_voice');
  if (!await dir.exists()) await dir.create(recursive: true);
  return dir;
}

Future<String> filePathFor(String lineId) async {
  final dir = await _dir();
  return '${dir.path}/$lineId.m4a';
}

Future<bool> isRecorded(String lineId) async {
  return File(await filePathFor(lineId)).exists();
}

Future<void> deleteRecording(String lineId) async {
  final f = File(await filePathFor(lineId));
  if (await f.exists()) await f.delete();
}

Future<bool> existsPath(String path) => File(path).exists();
