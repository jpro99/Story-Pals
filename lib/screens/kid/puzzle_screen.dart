import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/parent_voice_service.dart';
import '../../core/utils/puzzle_speech.dart';
import '../../core/utils/sound_service.dart';
import '../../core/utils/sound_volume_panel.dart';
import '../../core/utils/tts_service.dart';
import '../../core/visuals/effects.dart';
import '../../core/visuals/living_background.dart';
import '../../core/visuals/pal_character.dart';
import '../../providers/chapter_provider.dart';
import '../../providers/child_profile_provider.dart';
import '../../providers/session_provider.dart';
import 'puzzle_widgets_extra.dart';

class PuzzleScreen extends ConsumerStatefulWidget {
  const PuzzleScreen({
    super.key,
    required this.chapterId,
    required this.puzzleIndex,
  });
  final String chapterId;
  final int puzzleIndex;

  @override
  ConsumerState<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends ConsumerState<PuzzleScreen>
    with SingleTickerProviderStateMixin {
  bool _completed = false;
  late AnimationController _celebrationCtrl;

  @override
  void initState() {
    super.initState();
    _celebrationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    SoundFx.ambient(SoundFx.themeTrack);
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakInstruction());
  }

  void _speakInstruction() {
    final chapterAsync = ref.read(chapterContentProvider(widget.chapterId));
    chapterAsync.whenData((chapter) {
      if (widget.puzzleIndex >= chapter.puzzles.length) return;
      final puzzle =
          chapter.puzzles[widget.puzzleIndex] as Map<String, dynamic>;
      final spoken = spokenInstructionFor(puzzle);
      if (spoken.isNotEmpty) {
        ref.read(ttsServiceProvider).speak(spoken);
      }
    });
  }

  @override
  void dispose() {
    ref.read(ttsServiceProvider).stop();
    _celebrationCtrl.dispose();
    super.dispose();
  }

  Future<void> _onPuzzleComplete(Map<String, dynamic> puzzle) async {
    if (_completed) return;
    setState(() => _completed = true);

    final tags =
        (puzzle['subject_tags'] as List<dynamic>?)?.cast<String>() ?? [];
    ref
        .read(activeSessionProvider.notifier)
        .recordPuzzleComplete(widget.puzzleIndex, tags);

    SoundFx.play('celebrate');
    // Speak the praise and hold a short celebration, then advance.
    // Speech wait is capped so a stuck TTS completion can't freeze the game.
    final speech = ref
        .read(parentVoiceServiceProvider)
        .praise(ref.read(activeChildProvider)?.name)
        .timeout(const Duration(seconds: 5), onTimeout: () {});
    _celebrationCtrl.forward();
    await Future.wait([
      speech,
      Future.delayed(const Duration(milliseconds: 900)),
    ]);
    if (!mounted) return;
    _goNext(puzzle);
  }

  void _goNext(Map<String, dynamic> puzzle) {
    final chapter =
        ref.read(chapterContentProvider(widget.chapterId)).asData?.value;
    if (chapter == null) {
      context.go('${AppRoutes.emotionCheckin}?post=true');
      return;
    }
    final currentScene = chapter.scenes.cast<Map<String, dynamic>?>().firstWhere(
          (s) =>
              s != null &&
              s['type'] == 'puzzle' &&
              s['puzzle_index'] == widget.puzzleIndex,
          orElse: () => null,
        );
    if (currentScene == null) {
      context.go('/story/${widget.chapterId}/outro_1');
      return;
    }
    final next = currentScene['next_on_complete'] as String?;
    if (next == null) {
      context.go('${AppRoutes.emotionCheckin}?post=true');
    } else {
      context.go('/story/${widget.chapterId}/$next');
    }
  }

  @override
  Widget build(BuildContext context) {
    final chapterAsync = ref.watch(chapterContentProvider(widget.chapterId));

    return chapterAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (chapter) {
        if (widget.puzzleIndex >= chapter.puzzles.length) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () =>
                    context.go('${AppRoutes.emotionCheckin}?post=true'),
                child: const Text('Chapter Complete!'),
              ),
            ),
          );
        }

        final puzzle = chapter.puzzles[widget.puzzleIndex] as Map<String, dynamic>;
        const locale = 'en';
        final instruction = spokenInstructionFor(puzzle);

        return Scaffold(
          body: TapSparkles(
            child: Stack(
              children: [
                Positioned.fill(
                  child: LivingBackground(
                    scene: chapter.character == 'doll'
                        ? 'puzzle_pink'
                        : 'puzzle_green',
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      _PuzzleHeader(
                        chapterTitle: chapter.titleFor(locale),
                        puzzleIndex: widget.puzzleIndex,
                        totalPuzzles: chapter.puzzles.length,
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
                          child: buildPuzzleWidget(
                            puzzle,
                            onComplete: () => _onPuzzleComplete(puzzle),
                            onWrong: () =>
                                ref.read(parentVoiceServiceProvider).encourage(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_completed)
                  _CelebrationOverlay(
                    controller: _celebrationCtrl,
                    character: chapter.character,
                  ),
                const SoundVolumeOverlay(),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Puzzle Header ──────────────────────────────────────────────────

class _PuzzleHeader extends StatelessWidget {
  const _PuzzleHeader({
    required this.chapterTitle,
    required this.puzzleIndex,
    required this.totalPuzzles,
    required this.onBack,
  });
  final String chapterTitle;
  final int puzzleIndex;
  final int totalPuzzles;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 12, 24, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 28),
            onPressed: onBack,
            tooltip: 'Back to stories',
          ),
          Expanded(
            child:
                Text(chapterTitle, style: Theme.of(context).textTheme.titleLarge),
          ),
          Row(
            children: List.generate(
              totalPuzzles,
              (i) => Container(
                margin: const EdgeInsets.only(left: 4),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i <= puzzleIndex
                      ? AppColors.primary
                      : AppColors.dropTargetEmpty,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Celebration Overlay ────────────────────────────────────────────

class _CelebrationOverlay extends StatelessWidget {
  const _CelebrationOverlay(
      {required this.controller, required this.character});
  final AnimationController controller;
  final String character;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: controller.drive(Tween(begin: 0.0, end: 1.0)),
      child: Container(
        color: Colors.black.withValues(alpha: 0.45),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ConfettiRain(pieces: 80, hearts: character == 'doll'),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: controller.drive(
                      Tween(begin: 0.5, end: 1.0)
                          .chain(CurveTween(curve: Curves.elasticOut)),
                    ),
                    child: PalCharacter(
                      character: character,
                      action: 'celebrate',
                      size: 180,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Amazing!',
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
    );
  }
}
