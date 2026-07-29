import 'dart:math' as math;

import '../../models/child_profile.dart';
import '../content/content_loader.dart';
import '../content/puzzle_generator.dart';

/// Applies parent Learning Focus weights to kid play:
/// Practice Adventure *and* story-chapter puzzles.
class LearningSteerer {
  LearningSteerer._();

  /// Weighted skill pick — same rules for Practice and steered chapters.
  static String chooseSkill(ChildProfile? child, math.Random rnd) {
    final weights = <String, double>{
      'coding': child?.codingWeight ?? 0.5,
      'math': child?.mathWeight ?? 0.4,
      'english': child?.englishWeight ?? 0.4,
      'spanish': child?.spanishWeight ?? 0.25,
      'tagalog': child?.tagalogWeight ?? 0.25,
    };
    final total = weights.values.fold(0.0, (a, b) => a + b);
    if (total <= 0) {
      return PuzzleGenerator.skills[rnd.nextInt(PuzzleGenerator.skills.length)];
    }
    var roll = rnd.nextDouble() * total;
    for (final e in weights.entries) {
      roll -= e.value;
      if (roll <= 0) return e.key;
    }
    return weights.keys.last;
  }

  static const _skillStoryLine = {
    'coding': 'Now let\'s practice coding steps!',
    'math': 'Now let\'s practice counting and math!',
    'english': 'Now let\'s practice letters and words!',
    'spanish': 'Now let\'s practice Spanish!',
    'tagalog': 'Now let\'s practice Tagalog!',
  };

  /// Rebuild chapter puzzles (and nudge story dialogs) from parent weights.
  /// Story structure / scene flow stays the same; learning content follows
  /// Coding / Math / English / Spanish / Tagalog sliders.
  static ChapterContent adaptChapter(
    ChapterContent base,
    ChildProfile? child, {
    List<String> interests = const [],
    Map<String, int> skillLevels = const {},
  }) {
    if (child == null || base.puzzles.isEmpty) return base;

    final seed = Object.hash(
      child.uuid,
      base.chapterId,
      child.updatedAt.millisecondsSinceEpoch,
      (child.codingWeight * 100).round(),
      (child.mathWeight * 100).round(),
      (child.englishWeight * 100).round(),
      (child.spanishWeight * 100).round(),
      (child.tagalogWeight * 100).round(),
    );
    final rnd = math.Random(seed);

    final heroName = base.character == 'doll' ? 'Luna' : 'Rex';
    final heroEmoji = base.character == 'doll' ? '🪆' : '🦕';
    final gen = PuzzleGenerator(
      rnd: rnd,
      heroName: heroName,
      heroEmoji: heroEmoji,
      interests: interests,
    );

    final skillsUsed = <String>[];
    final newPuzzles = <dynamic>[];
    for (var i = 0; i < base.puzzles.length; i++) {
      final skill = chooseSkill(child, rnd);
      skillsUsed.add(skill);
      final level = (skillLevels[skill] ?? (1 + (i ~/ 2))).clamp(1, 10);
      final puzzle = Map<String, dynamic>.from(gen.generate(skill, level));
      puzzle['puzzle_index'] = i;
      puzzle['steered_skill'] = skill;
      newPuzzles.add(puzzle);
    }

    // Soften story beats that lead into a puzzle so parents hear the steer.
    final newScenes = base.scenes.map((raw) {
      if (raw is! Map) return raw;
      final scene = Map<String, dynamic>.from(raw);
      if (scene['type'] != 'story') return scene;
      final next = scene['next'] as String?;
      if (next == null || !next.startsWith('puzzle_')) return scene;
      final idx = int.tryParse(next.split('_').last);
      if (idx == null || idx < 1 || idx > skillsUsed.length) return scene;
      final skill = skillsUsed[idx - 1];
      final hint = _skillStoryLine[skill];
      if (hint == null) return scene;
      final dialog = Map<String, dynamic>.from(
        (scene['dialog'] as Map?) ?? const {},
      );
      final en = (dialog['en'] as String?) ?? '';
      if (!en.contains(hint)) {
        dialog['en'] = en.isEmpty ? hint : '$en $hint';
      }
      scene['dialog'] = dialog;
      return scene;
    }).toList();

    return ChapterContent(
      chapterId: base.chapterId,
      isPremium: base.isPremium,
      character: base.character,
      themeColor: base.themeColor,
      title: base.title,
      scenes: newScenes,
      puzzles: newPuzzles,
    );
  }
}
