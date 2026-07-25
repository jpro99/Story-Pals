import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/parent_voice_service.dart';
import '../../core/utils/sound_service.dart';
import '../../core/utils/tts_service.dart';
import '../../core/visuals/effects.dart';
import '../../core/visuals/living_background.dart';
import '../../core/visuals/pal_character.dart';
import '../../data/content/puzzle_generator.dart';
import '../../providers/child_profile_provider.dart';
import '../../providers/skill_level_provider.dart';
import 'puzzle_widgets_extra.dart';

/// Endless practice mode. Puzzles are generated on the fly, get harder as
/// the child masters each skill, and follow the parent's Learning Focus
/// weights from the dashboard. It never runs out.
class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key, this.pal});

  /// Optional character theme: 'dino' (Rex) or 'doll' (Luna).
  /// When set, the endless mode runs inside that character's world.
  final String? pal;

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen> {
  late PuzzleGenerator _generator;
  final _rnd = math.Random();

  String get _palCharacter => widget.pal ?? 'dino';
  String get _heroName => widget.pal == 'doll' ? 'Luna' : 'Rex';
  bool get _themed => widget.pal != null;

  final Map<String, int> _levels = {};
  final Map<String, int> _streaks = {};
  // Consecutive puzzles WITH mistakes per skill — used to gently step
  // difficulty back down when a child is stuck.
  final Map<String, int> _struggles = {};

  String _skill = 'coding';
  Map<String, dynamic>? _puzzle;
  int _puzzleNumber = 0;
  bool _hadMistake = false;
  bool _celebrating = false;
  bool _leveledUp = false;

  static const _skillInfo = {
    'coding': (label: 'Coding', emoji: '💻', scene: 'puzzle_green'),
    'math': (label: 'Math', emoji: '🔢', scene: 'map'),
    'english': (label: 'Letters', emoji: '📖', scene: 'puzzle_pink'),
    'spanish': (label: 'Spanish', emoji: '🌎', scene: 'jungle_clearing'),
    'tagalog': (label: 'Tagalog', emoji: '🌺', scene: 'jungle_river'),
  };

  @override
  void initState() {
    super.initState();
    _loadAndStart();
  }

  Future<void> _loadAndStart() async {
    final child = ref.read(activeChildProvider);
    // Themed mode stars the story character; plain practice stars the child
    // themselves ("Program Kaleb! ...").
    final interests =
        child == null ? <String>[] : await InterestStore.getInterests(child.uuid);
    _generator = PuzzleGenerator(
      heroName: _themed ? _heroName : child?.name,
      heroEmoji: widget.pal == 'doll' ? '🪆' : '🦕',
      interests: interests,
    );
    if (child == null) return;
    for (final s in PuzzleGenerator.skills) {
      _levels[s] = await SkillLevelStore.getLevel(child.uuid, s);
      _streaks[s] = 0;
      _struggles[s] = 0;
    }
    if (!mounted) return;
    _nextPuzzle();
  }

  /// Weighted skill choice based on the parent's Learning Focus sliders.
  String _chooseSkill() {
    final child = ref.read(activeChildProvider);
    final weights = <String, double>{
      'coding': child?.codingWeight ?? 0.5,
      'math': child?.mathWeight ?? 0.5,
      'english': child?.englishWeight ?? 0.5,
      // Spanish and Tagalog share the parent's Language slider.
      'spanish': (child?.additionalLanguageWeight ?? 0.3) / 2,
      'tagalog': (child?.additionalLanguageWeight ?? 0.3) / 2,
    };
    final total = weights.values.fold(0.0, (a, b) => a + b);
    if (total <= 0) {
      return PuzzleGenerator
          .skills[_rnd.nextInt(PuzzleGenerator.skills.length)];
    }
    var roll = _rnd.nextDouble() * total;
    for (final e in weights.entries) {
      roll -= e.value;
      if (roll <= 0) return e.key;
    }
    return weights.keys.last;
  }

  void _nextPuzzle() {
    final skill = _chooseSkill();
    final level = _levels[skill] ?? 1;
    setState(() {
      _skill = skill;
      _puzzle = _generator.generate(skill, level);
      _puzzleNumber++;
      _hadMistake = false;
      _celebrating = false;
      _leveledUp = false;
    });
    final instruction =
        (_puzzle?['instruction'] as Map<String, dynamic>?)?['en'] as String?;
    if (instruction != null) {
      ref.read(ttsServiceProvider).speak(instruction);
    }
  }

  Future<void> _onComplete() async {
    if (_celebrating) return;
    SoundFx.play('celebrate');
    final child = ref.read(activeChildProvider);
    final praiseSpeech = ref
        .read(parentVoiceServiceProvider)
        .praise(child?.name)
        .timeout(const Duration(seconds: 12), onTimeout: () {});

    var leveled = false;
    if (child != null) {
      await SkillLevelStore.incrementSolved(child.uuid, _skill);
      if (!_hadMistake) {
        // Clean solve: build the level-up streak.
        _struggles[_skill] = 0;
        _streaks[_skill] = (_streaks[_skill] ?? 0) + 1;
        if ((_streaks[_skill] ?? 0) >= 3 && (_levels[_skill] ?? 1) < 10) {
          _levels[_skill] = (_levels[_skill] ?? 1) + 1;
          _streaks[_skill] = 0;
          leveled = true;
          await SkillLevelStore.setLevel(
              child.uuid, _skill, _levels[_skill]!);
        }
      } else {
        // Struggled through it: after 3 rough puzzles in a row, quietly
        // ease the difficulty down one level. No announcement — the child
        // just starts winning again.
        _streaks[_skill] = 0;
        _struggles[_skill] = (_struggles[_skill] ?? 0) + 1;
        if ((_struggles[_skill] ?? 0) >= 3 && (_levels[_skill] ?? 1) > 1) {
          _levels[_skill] = (_levels[_skill] ?? 1) - 1;
          _struggles[_skill] = 0;
          await SkillLevelStore.setLevel(
              child.uuid, _skill, _levels[_skill]!);
        }
      }
    }

    if (!mounted) return;
    if (leveled) SoundFx.play('levelup');
    setState(() {
      _celebrating = true;
      _leveledUp = leveled;
    });

    // Wait for the praise to finish speaking, plus the level-up
    // announcement if there is one, plus a minimum celebration time —
    // then move on. Speech is never cut off between puzzles.
    await Future.wait([
      praiseSpeech,
      Future.delayed(Duration(milliseconds: leveled ? 2200 : 1200)),
    ]);
    if (leveled && mounted) {
      await ref
          .read(parentVoiceServiceProvider)
          .levelUp('Level up! You reached level ${_levels[_skill]} in '
              '${_skillInfo[_skill]!.label}!')
          .timeout(const Duration(seconds: 10), onTimeout: () {});
    }
    if (!mounted) return;
    _nextPuzzle();
  }

  void _onWrong() {
    _hadMistake = true;
    ref.read(parentVoiceServiceProvider).encourage();
  }

  @override
  void dispose() {
    ref.read(ttsServiceProvider).stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = _skillInfo[_skill]!;
    final level = _levels[_skill] ?? 1;
    final puzzle = _puzzle;
    final instruction =
        (puzzle?['instruction'] as Map<String, dynamic>?)?['en'] as String? ??
            '';

    final scene = _themed
        ? (widget.pal == 'doll' ? 'tea_party' : 'jungle_clearing')
        : info.scene;
    SoundFx.ambientForScene(scene);

    return Scaffold(
      body: TapSparkles(
        child: Stack(
          children: [
            Positioned.fill(child: LivingBackground(scene: scene, dim: 0.06)),
            SafeArea(
              child: puzzle == null
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        _PracticeHeader(
                          title: _themed
                              ? "$_heroName's Endless Adventure"
                              : 'Practice Adventure',
                          skillLabel: info.label,
                          skillEmoji: info.emoji,
                          level: level,
                          puzzleNumber: _puzzleNumber,
                          onBack: () => context.go(AppRoutes.chapterMap),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 8),
                          child: Text(
                            instruction,
                            style: Theme.of(context).textTheme.headlineMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            child: KeyedSubtree(
                              key: ValueKey(_puzzleNumber),
                              child: buildPuzzleWidget(
                                puzzle,
                                onComplete: _onComplete,
                                onWrong: _onWrong,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            if (_celebrating)
              _MiniCelebration(
                leveledUp: _leveledUp,
                level: level,
                character: _palCharacter,
              ),
          ],
        ),
      ),
    );
  }
}

class _PracticeHeader extends StatelessWidget {
  const _PracticeHeader({
    required this.title,
    required this.skillLabel,
    required this.skillEmoji,
    required this.level,
    required this.puzzleNumber,
    required this.onBack,
  });
  final String title;
  final String skillLabel;
  final String skillEmoji;
  final int level;
  final int puzzleNumber;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 12, 20, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 28),
            onPressed: onBack,
            tooltip: 'Back to stories',
          ),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: Text(
              '$skillEmoji $skillLabel · ⭐ Level $level',
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCelebration extends StatelessWidget {
  const _MiniCelebration({
    required this.leveledUp,
    required this.level,
    required this.character,
  });
  final bool leveledUp;
  final int level;
  final String character;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: Colors.black.withValues(alpha: leveledUp ? 0.5 : 0.25),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (leveledUp) const ConfettiRain(pieces: 90),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PalCharacter(
                      character: character,
                      action: 'celebrate',
                      size: leveledUp ? 200 : 140,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      leveledUp ? '⭐ LEVEL $level! ⭐' : 'Great job!',
                      style: Theme.of(context)
                          .textTheme
                          .displayLarge
                          ?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
