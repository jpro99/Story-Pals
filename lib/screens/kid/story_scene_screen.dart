import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/sound_service.dart';
import '../../core/utils/tts_service.dart';
import '../../core/visuals/effects.dart';
import '../../core/visuals/living_background.dart';
import '../../core/visuals/pal_character.dart';
import '../../providers/chapter_provider.dart';

class StorySceneScreen extends ConsumerStatefulWidget {
  const StorySceneScreen({
    super.key,
    required this.chapterId,
    required this.sceneId,
  });
  final String chapterId;
  final String sceneId;

  @override
  ConsumerState<StorySceneScreen> createState() => _StorySceneScreenState();
}

class _StorySceneScreenState extends ConsumerState<StorySceneScreen>
    with TickerProviderStateMixin {
  late AnimationController _charController;
  late AnimationController _dialogController;
  late Animation<Offset> _charSlide;
  late Animation<double> _dialogFade;
  bool _dialogVisible = false;
  bool _showEndChoice = false;

  @override
  void initState() {
    super.initState();
    _charController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _dialogController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _charSlide = Tween<Offset>(
      begin: const Offset(-1.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _charController, curve: Curves.easeOut));
    _dialogFade = CurvedAnimation(parent: _dialogController, curve: Curves.easeIn)
        .drive(Tween(begin: 0.0, end: 1.0));

    _charController.forward().then((_) {
      setState(() => _dialogVisible = true);
      _dialogController.forward();
      _speakCurrentDialog();
    });
  }

  void _speakCurrentDialog() {
    final chapterAsync = ref.read(chapterContentProvider(widget.chapterId));
    chapterAsync.whenData((chapter) {
      final scene = chapter.scenes.firstWhere(
        (s) => s['scene_id'] == widget.sceneId,
        orElse: () => chapter.scenes.first,
      ) as Map<String, dynamic>;
      final dialog =
          (scene['dialog'] as Map<String, dynamic>?)?['en'] as String? ?? '';
      if (dialog.isNotEmpty) {
        ref.read(ttsServiceProvider).speak(dialog);
      }
    });
  }

  @override
  void dispose() {
    ref.read(ttsServiceProvider).stop();
    _charController.dispose();
    _dialogController.dispose();
    super.dispose();
  }

  void _advance(Map<String, dynamic> scene) {
    if (_showEndChoice) return;
    final next = scene['next'] as String?;
    if (next == null) {
      // Chapter complete — offer endless mode or finish.
      setState(() => _showEndChoice = true);
      ref.read(ttsServiceProvider).speak('Do you want more puzzles?');
      return;
    }
    if (next.startsWith('puzzle_')) {
      final idx = int.parse(next.split('_').last) - 1;
      context.go('/puzzle/${widget.chapterId}/$idx');
    } else {
      context.go('/story/${widget.chapterId}/$next');
    }
  }

  @override
  Widget build(BuildContext context) {
    final chapterAsync = ref.watch(chapterContentProvider(widget.chapterId));

    return chapterAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (chapter) {
        final scene = chapter.scenes.firstWhere(
          (s) => s['scene_id'] == widget.sceneId,
          orElse: () => chapter.scenes.first,
        ) as Map<String, dynamic>;

        const locale = 'en'; // TODO: wire to locale provider
        final dialog =
            (scene['dialog'] as Map<String, dynamic>?)?[locale] as String? ??
                '';
        final background = scene['background'] as String? ?? 'jungle';
        final action = scene['character_action'] as String? ?? 'idle';
        SoundFx.ambientForScene(background);

        return Scaffold(
          body: GestureDetector(
            onTap: () => _advance(scene),
            child: TapSparkles(
              child: Stack(
              children: [
                // Living, animated background
                Positioned.fill(
                  child: LivingBackground(scene: background),
                ),
                // Celebration confetti on celebrate scenes
                if (action == 'celebrate')
                  Positioned.fill(
                    child: ConfettiRain(
                      pieces: 60,
                      hearts: chapter.character == 'doll',
                    ),
                  ),
                // Animated vector character
                Positioned(
                  left: 20,
                  bottom: 170,
                  child: SlideTransition(
                    position: _charSlide,
                    child: PalCharacter(
                      character: chapter.character,
                      action: action,
                      size: 190,
                    ),
                  ),
                ),
                // Dialog bubble
                if (_dialogVisible)
                  Positioned(
                    bottom: 40,
                    left: 24,
                    right: 24,
                    child: FadeTransition(
                      opacity: _dialogFade,
                      child: _DialogBubble(text: dialog),
                    ),
                  ),
                // Tap hint
                Positioned(
                  bottom: 12,
                  right: 24,
                  child: FadeTransition(
                    opacity: _dialogFade,
                    child: const _TapHint(),
                  ),
                ),
                // Back to chapter map
                Positioned(
                  top: 12,
                  left: 8,
                  child: SafeArea(
                    child: Material(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => context.go('/chapter-map'),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 26),
                        ),
                      ),
                    ),
                  ),
                ),
                // End-of-chapter choice: endless mode or all done
                if (_showEndChoice)
                  _EndChoiceOverlay(
                    character: chapter.character,
                    onMorePuzzles: () =>
                        context.go('/practice?pal=${chapter.character}'),
                    onAllDone: () => context.go('/emotion-checkin?post=true'),
                  ),
              ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EndChoiceOverlay extends StatelessWidget {
  const _EndChoiceOverlay({
    required this.character,
    required this.onMorePuzzles,
    required this.onAllDone,
  });
  final String character;
  final VoidCallback onMorePuzzles;
  final VoidCallback onAllDone;

  @override
  Widget build(BuildContext context) {
    final heroName = character == 'doll' ? 'Luna' : 'Rex';
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PalCharacter(
                character: character, action: 'celebrate', size: 160),
            const SizedBox(height: 8),
            Text(
              'More puzzles?',
              style: Theme.of(context)
                  .textTheme
                  .displayMedium
                  ?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 300,
              height: 76,
              child: ElevatedButton(
                onPressed: onMorePuzzles,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C4DFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                ),
                child: Text('🚀 Play More with $heroName!',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: 300,
              height: 64,
              child: ElevatedButton(
                onPressed: onAllDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF4A4A6A),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                ),
                child: const Text('⭐ All Done!',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogBubble extends StatelessWidget {
  const _DialogBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _TapHint extends StatefulWidget {
  const _TapHint();

  @override
  State<_TapHint> createState() => _TapHintState();
}

class _TapHintState extends State<_TapHint>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)),
      child: const Text('👆 Tap anywhere!',
          style: TextStyle(color: Colors.white70, fontSize: 14)),
    );
  }
}
