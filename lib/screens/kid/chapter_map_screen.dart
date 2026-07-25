import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/sound_service.dart';
import '../../core/visuals/effects.dart';
import '../../core/visuals/living_background.dart';
import '../../core/visuals/pal_character.dart';
import '../../data/content/content_loader.dart';
import '../../providers/child_profile_provider.dart';
import '../../providers/chapter_provider.dart';
import '../../providers/session_provider.dart';

class ChapterMapScreen extends ConsumerWidget {
  const ChapterMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(activeChildProvider);
    final chaptersAsync = ref.watch(allChaptersProvider);
    // Great-grandma's lullaby, re-voiced as a music box.
    SoundFx.ambient('family_song_loop');

    return Scaffold(
      body: TapSparkles(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const LivingBackground(scene: 'map'),
            SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 24, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, size: 28),
                    onPressed: () => context.go('/profile-select'),
                    tooltip: 'Switch player',
                  ),
                  Expanded(
                    child: Text(
                      'Choose a Story!',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ),
                  if (child != null)
                    _ChildBadge(name: child.name, avatarIndex: child.avatarIndex),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: chaptersAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (chapters) => ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: chapters.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _PracticeCard(
                          enabled: child != null,
                          onTap: child != null
                              ? () => context.go('/practice')
                              : null,
                        ),
                      );
                    }
                    final i = index - 1;
                    final chapter = chapters[i];
                    final isUnlocked =
                        ref.watch(chapterUnlockedProvider(chapter.chapterId));
                    final progress = child == null
                        ? -1
                        : ref.watch(chapterProgressProvider((
                            childUuid: child.uuid,
                            chapterId: chapter.chapterId,
                          )));

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _ChapterCard(
                        chapter: chapter,
                        isUnlocked: isUnlocked,
                        completedPuzzles: progress + 1,
                        onTap: isUnlocked && child != null
                            ? () {
                                ref.read(activeSessionProvider.notifier).start(
                                      chapter.chapterId,
                                      child.uuid,
                                    );
                                context.go(
                                  '/story/${chapter.chapterId}/intro_1',
                                );
                              }
                            : null,
                      ),
                    );
                  },
                ),
              ),
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

class _PracticeCard extends StatelessWidget {
  const _PracticeCard({required this.enabled, this.onTap});
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Wiggle(
        enabled: enabled,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C4DFF), Color(0xFF5B8FFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C4DFF).withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              const Text('🚀', style: TextStyle(fontSize: 48)),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Practice Adventure',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Endless puzzles that grow with you! '
                      'Coding · Math · Letters',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildBadge extends StatelessWidget {
  const _ChildBadge({required this.name, required this.avatarIndex});
  final String name;
  final int avatarIndex;

  static const _avatars = ['🦕', '🪆', '🐬', '🐒', '🚀'];

  @override
  Widget build(BuildContext context) {
    final emoji = _avatars[avatarIndex.clamp(0, _avatars.length - 1)];
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 6),
        Text(name, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    required this.chapter,
    required this.isUnlocked,
    required this.completedPuzzles,
    this.onTap,
  });
  final ChapterContent chapter;
  final bool isUnlocked;
  final int completedPuzzles;
  final VoidCallback? onTap;

  Color _parseColor() {
    try {
      return Color(
        int.parse(chapter.themeColor.replaceFirst('#', '0xFF')),
      );
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor();
    final title = chapter.titleFor('en');
    final isComplete = completedPuzzles >= AppConstants.puzzlesPerChapter;

    return GestureDetector(
      onTap: onTap,
      child: Wiggle(
        enabled: isUnlocked && !isComplete,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isUnlocked
              ? Colors.white.withValues(alpha: 0.92)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isUnlocked ? color : Colors.grey.shade300,
            width: 2.5,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Opacity(
              opacity: isUnlocked ? 1.0 : 0.35,
              child: PalCharacter(
                character: chapter.character,
                action: 'idle',
                size: 68,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: isUnlocked ? null : Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (isUnlocked) ...[
                    _ProgressBar(
                      completed: completedPuzzles,
                      total: AppConstants.puzzlesPerChapter,
                      color: color,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isComplete
                          ? '⭐ Complete!'
                          : '$completedPuzzles / ${AppConstants.puzzlesPerChapter} puzzles',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        const Text('🔒', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          'Premium — unlock to play!',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (isUnlocked)
              Icon(Icons.arrow_forward_ios_rounded, color: color, size: 28),
          ],
        ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.completed,
    required this.total,
    required this.color,
  });
  final int completed;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: fraction,
        minHeight: 10,
        backgroundColor: color.withValues(alpha: 0.15),
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}
