import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/content/content_loader.dart';
import '../core/constants/app_constants.dart';

// Load a single chapter's content
final chapterContentProvider =
    FutureProvider.family<ChapterContent, String>((ref, chapterId) {
  return ContentLoader.loadChapter(chapterId);
});

// Load all chapters (for the chapter map)
final allChaptersProvider = FutureProvider<List<ChapterContent>>((ref) {
  return ContentLoader.loadAllChapters();
});

// Whether a chapter is unlocked for a given profile
final chapterUnlockedProvider = Provider.family<bool, String>((ref, chapterId) {
  // In v1: chapters 1 & 2 are always free; 3-5 require premium
  // Premium check will be wired to in_app_purchase entitlements
  final chapterIndex = ContentLoader.allChapterIds.indexOf(chapterId);
  return chapterIndex < AppConstants.freeChapterCount || _isPremium(ref);
});

bool _isPremium(Ref ref) {
  // Stub: always false until in_app_purchase is wired
  return false;
}
