import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../data/content/content_loader.dart';
import '../data/content/learning_steerer.dart';
import '../data/content/puzzle_generator.dart';
import '../providers/child_profile_provider.dart';
import '../providers/skill_level_provider.dart';

/// Chapter with puzzles rewritten from the active child's Learning Focus.
final chapterContentProvider =
    FutureProvider.family<ChapterContent, String>((ref, chapterId) async {
  final base = await ContentLoader.loadChapter(chapterId);
  final child = ref.watch(activeChildProvider);
  if (child == null) return base;

  final interests = await InterestStore.getInterests(child.uuid);
  final levels = <String, int>{};
  for (final skill in PuzzleGenerator.skills) {
    levels[skill] = await SkillLevelStore.getLevel(child.uuid, skill);
  }

  return LearningSteerer.adaptChapter(
    base,
    child,
    interests: interests,
    skillLevels: levels,
  );
});

// Load all chapters (for the chapter map) — titles/meta only, no steer needed
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
