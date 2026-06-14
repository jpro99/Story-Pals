import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/tts_service.dart';
import '../../models/emotion_entry.dart';
import '../../providers/child_profile_provider.dart';
import '../../data/local/isar_service.dart';

const _emotions = [
  (emoji: '😢', label: 'Very Sad', level: EmotionLevel.verySad, color: AppColors.emotionVerySad),
  (emoji: '😕', label: 'Sad', level: EmotionLevel.sad, color: AppColors.emotionSad),
  (emoji: '😐', label: 'Okay', level: EmotionLevel.neutral, color: AppColors.emotionNeutral),
  (emoji: '🙂', label: 'Happy', level: EmotionLevel.happy, color: AppColors.emotionHappy),
  (emoji: '😄', label: 'Very Happy', level: EmotionLevel.veryHappy, color: AppColors.emotionVeryHappy),
];

class EmotionCheckinScreen extends ConsumerStatefulWidget {
  const EmotionCheckinScreen({super.key, required this.isPostSession});
  final bool isPostSession;

  @override
  ConsumerState<EmotionCheckinScreen> createState() =>
      _EmotionCheckinScreenState();
}

class _EmotionCheckinScreenState extends ConsumerState<EmotionCheckinScreen>
    with SingleTickerProviderStateMixin {
  EmotionLevel? _selected;
  late AnimationController _bounceController;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      lowerBound: 0.9,
      upperBound: 1.0,
    )..value = 1.0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final heading = widget.isPostSession
          ? 'Great job! How do you feel?'
          : 'How are you feeling today?';
      ref.read(ttsServiceProvider).speak(heading);
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    if (_selected == null) return;
    final child = ref.read(activeChildProvider);
    if (child == null) return;

    final entry = EmotionEntry(
      childUuid: child.uuid,
      emotion: _selected!,
      checkInType: widget.isPostSession ? 'post' : 'pre',
      recordedAt: DateTime.now(),
      isSynced: false,
    );

    await IsarService.saveEmotion(entry);

    if (!mounted) return;
    if (widget.isPostSession) {
      context.go(AppRoutes.profileSelect);
    } else {
      context.go(AppRoutes.chapterMap);
    }
  }

  @override
  Widget build(BuildContext context) {
    final heading = widget.isPostSession
        ? 'Great job! How do you feel?'
        : 'How are you feeling today?';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, size: 28),
                  onPressed: () => context.go(AppRoutes.chapterMap),
                  tooltip: 'Back',
                ),
              ),
              const Spacer(),
              Text(
                heading,
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _emotions
                    .map((e) => _EmotionButton(
                          emoji: e.emoji,
                          label: e.label,
                          color: e.color,
                          isSelected: _selected == e.level,
                          onTap: () => setState(() => _selected = e.level),
                        ))
                    .toList(),
              ),
              const Spacer(),
              AnimatedOpacity(
                opacity: _selected != null ? 1.0 : 0.3,
                duration: const Duration(milliseconds: 250),
                child: SizedBox(
                  width: double.infinity,
                  height: 72,
                  child: ElevatedButton(
                    onPressed: _selected != null ? _saveAndContinue : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      widget.isPostSession ? 'Done! 🌟' : "Let's Play! 🎉",
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmotionButton extends StatefulWidget {
  const _EmotionButton({
    required this.emoji,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });
  final String emoji;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_EmotionButton> createState() => _EmotionButtonState();
}

class _EmotionButtonState extends State<_EmotionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(_EmotionButton old) {
    super.didUpdateWidget(old);
    if (widget.isSelected && !old.isSelected) {
      _ctrl.forward().then((_) => _ctrl.reverse());
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isSelected
                    ? widget.color
                    : widget.color.withOpacity(0.2),
                border: Border.all(
                  color: widget.isSelected ? widget.color : Colors.transparent,
                  width: 3,
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: widget.color.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Text(widget.emoji,
                    style: const TextStyle(fontSize: 34)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: widget.isSelected
                    ? FontWeight.w700
                    : FontWeight.w400,
                color: widget.isSelected
                    ? widget.color
                    : AppColors.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
