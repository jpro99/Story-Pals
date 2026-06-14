import 'package:flutter_test/flutter_test.dart';
import 'package:story_pals/data/content/content_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ContentLoader', () {
    test('chapter 1 is not premium', () async {
      final chapter = await ContentLoader.loadChapter('ch1_dino');
      expect(chapter.isPremium, isFalse);
    });

    test('chapter 2 is not premium', () async {
      final chapter = await ContentLoader.loadChapter('ch2_doll');
      expect(chapter.isPremium, isFalse);
    });

    test('chapter has correct number of puzzles', () async {
      final chapter = await ContentLoader.loadChapter('ch1_dino');
      expect(chapter.puzzles.length, equals(5));
    });

    test('chapter title exists in all supported locales', () async {
      final chapter = await ContentLoader.loadChapter('ch1_dino');
      for (final locale in ['en', 'es', 'tl']) {
        expect(chapter.title[locale], isNotEmpty,
            reason: 'Missing title for locale $locale');
      }
    });

    test('all chapter scenes have dialog in all locales', () async {
      final chapter = await ContentLoader.loadChapter('ch1_dino');
      for (final scene in chapter.scenes) {
        final sceneMap = scene as Map<String, dynamic>;
        if (sceneMap['type'] == 'story') {
          final dialog = sceneMap['dialog'] as Map<String, dynamic>?;
          expect(dialog, isNotNull, reason: 'Scene ${sceneMap['scene_id']} missing dialog');
          expect(dialog!['en'], isNotEmpty);
          expect(dialog['es'], isNotEmpty);
          expect(dialog['tl'], isNotEmpty);
        }
      }
    });
  });
}
