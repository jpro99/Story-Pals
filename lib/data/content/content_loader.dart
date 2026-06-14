import 'dart:convert';
import 'package:flutter/services.dart';

class ChapterContent {
  final String chapterId;
  final bool isPremium;
  final String character;
  final String themeColor;
  final Map<String, String> title;
  final List<dynamic> scenes;
  final List<dynamic> puzzles;

  const ChapterContent({
    required this.chapterId,
    required this.isPremium,
    required this.character,
    required this.themeColor,
    required this.title,
    required this.scenes,
    required this.puzzles,
  });

  factory ChapterContent.fromJson(Map<String, dynamic> json) {
    return ChapterContent(
      chapterId: json['chapter_id'] as String,
      isPremium: json['is_premium'] as bool,
      character: json['character'] as String,
      themeColor: json['theme_color'] as String,
      title: Map<String, String>.from(json['title'] as Map),
      scenes: json['scenes'] as List<dynamic>,
      puzzles: json['puzzles'] as List<dynamic>,
    );
  }

  String titleFor(String locale) =>
      title[locale] ?? title['en'] ?? chapterId;
}

class ContentLoader {
  static const _chapterPaths = {
    'ch1_dino': 'assets/content/chapters/chapter_1_dino.json',
    'ch2_doll': 'assets/content/chapters/chapter_2_doll.json',
  };

  static final Map<String, ChapterContent> _cache = {};

  static Future<ChapterContent> loadChapter(String chapterId) async {
    if (_cache.containsKey(chapterId)) return _cache[chapterId]!;

    final path = _chapterPaths[chapterId];
    if (path == null) throw Exception('Unknown chapter: $chapterId');

    final raw = await rootBundle.loadString(path);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final content = ChapterContent.fromJson(json);
    _cache[chapterId] = content;
    return content;
  }

  static Future<List<ChapterContent>> loadAllChapters() async {
    final futures = _chapterPaths.keys.map(loadChapter);
    return Future.wait(futures);
  }

  static List<String> get allChapterIds => _chapterPaths.keys.toList();
}
