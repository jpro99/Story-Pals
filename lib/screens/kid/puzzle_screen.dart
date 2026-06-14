import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/tts_service.dart';
import '../../providers/chapter_provider.dart';
import '../../providers/session_provider.dart';

// ── Emoji helpers ──────────────────────────────────────────────────

String _emojiFor(Map<String, dynamic> item) {
  final e = item['emoji'] as String?;
  if (e != null && e.isNotEmpty) return e;
  const byId = {
    'find': '🌿', 'pick': '✋', 'eat': '😋',
    'walk': '🦶', 'jump': '⬆️', 'grab': '🤏',
    'circle': '⭕', 'star': '⭐', 'triangle': '🔺',
    'leaf': '🍃', 'rock': '🪨',
    'dress': '👗', 'hat': '🎩', 'bow': '🎀',
    'cookie': '🍪', 'sandwich': '🥪', 'candy': '🍬',
    'cloth': '🎪', 'cup': '☕', 'cake': '🎂',
    'pink': '🩷', 'purple': '💜', 'yellow': '💛',
  };
  const byShape = {
    'leaf': '🍃', 'rock': '🪨', 'circle': '⭕', 'star': '⭐',
    'triangle': '🔺', 'diamond': '💎', 'rectangle': '🟦',
    'boot': '👟', 'arrow_up': '⬆️', 'hand': '✋',
  };
  return byId[item['id'] as String? ?? ''] ??
      byShape[item['shape'] as String? ?? ''] ??
      '❓';
}

String _slotEmoji(String targetId) {
  if (targetId.startsWith('nest_')) return '🪺';
  if (targetId.startsWith('hanger_')) return '🪝';
  if (targetId.startsWith('plate_')) return '🍽️';
  return '📦';
}

// ── PuzzleScreen ────────────────────────────────────────────────────

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakInstruction());
  }

  void _speakInstruction() {
    final chapterAsync = ref.read(chapterContentProvider(widget.chapterId));
    chapterAsync.whenData((chapter) {
      if (widget.puzzleIndex >= chapter.puzzles.length) return;
      final puzzle = chapter.puzzles[widget.puzzleIndex] as Map<String, dynamic>;
      final instruction =
          (puzzle['instruction'] as Map<String, dynamic>?)?['en'] as String?;
      if (instruction != null && instruction.isNotEmpty) {
        ref.read(ttsServiceProvider).speak(instruction);
      }
    });
  }

  @override
  void dispose() {
    ref.read(ttsServiceProvider).stop();
    _celebrationCtrl.dispose();
    super.dispose();
  }

  void _onPuzzleComplete(Map<String, dynamic> puzzle) {
    if (_completed) return;
    setState(() => _completed = true);

    final tags = (puzzle['subject_tags'] as List<dynamic>?)?.cast<String>() ?? [];
    ref.read(activeSessionProvider.notifier).recordPuzzleComplete(widget.puzzleIndex, tags);

    ref.read(ttsServiceProvider).speak('Amazing! Well done!');
    _celebrationCtrl.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        _goNext(puzzle);
      });
    });
  }

  void _goNext(Map<String, dynamic> puzzle) {
    final chapterAsync = ref.read(chapterContentProvider(widget.chapterId));
    chapterAsync.whenData((chapter) {
      final currentScene = chapter.scenes.firstWhere(
        (s) => s['type'] == 'puzzle' && s['puzzle_index'] == widget.puzzleIndex,
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final chapterAsync = ref.watch(chapterContentProvider(widget.chapterId));

    return chapterAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (chapter) {
        if (widget.puzzleIndex >= chapter.puzzles.length) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => context.go(AppRoutes.emotionCheckin + '?post=true'),
                child: const Text('Chapter Complete!'),
              ),
            ),
          );
        }

        final puzzle = chapter.puzzles[widget.puzzleIndex] as Map<String, dynamic>;
        final type = puzzle['type'] as String;
        const locale = 'en';
        final instruction =
            (puzzle['instruction'] as Map<String, dynamic>?)?[locale] as String? ??
                'Complete the puzzle!';

        return Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _PuzzleHeader(
                      chapterTitle: chapter.titleFor(locale),
                      puzzleIndex: widget.puzzleIndex,
                      totalPuzzles: chapter.puzzles.length,
                      onBack: () => context.go(AppRoutes.chapterMap),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Text(
                        instruction,
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: _buildPuzzleWidget(type, puzzle, chapter.character),
                      ),
                    ),
                  ],
                ),
                if (_completed) _CelebrationOverlay(controller: _celebrationCtrl),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPuzzleWidget(String type, Map<String, dynamic> puzzle, String character) {
    switch (type) {
      case 'sequence':
        return _SequencePuzzle(puzzle: puzzle, onComplete: () => _onPuzzleComplete(puzzle));
      case 'match_shape':
        return _MatchShapePuzzle(puzzle: puzzle, onComplete: () => _onPuzzleComplete(puzzle));
      case 'pattern':
        return _PatternPuzzle(puzzle: puzzle, onComplete: () => _onPuzzleComplete(puzzle));
      case 'count_match':
        return _CountMatchPuzzle(puzzle: puzzle, onComplete: () => _onPuzzleComplete(puzzle));
      default:
        return Center(child: Text('Unknown puzzle type: $type'));
    }
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
            child: Text(chapterTitle, style: Theme.of(context).textTheme.titleLarge),
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
                  color: i <= puzzleIndex ? AppColors.primary : AppColors.dropTargetEmpty,
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
  const _CelebrationOverlay({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: controller.drive(Tween(begin: 0.0, end: 1.0)),
      child: Container(
        color: Colors.black.withValues(alpha: 0.4),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: controller.drive(
                  Tween(begin: 0.5, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)),
                ),
                child: const Text('🌟', style: TextStyle(fontSize: 100)),
              ),
              const SizedBox(height: 16),
              Text(
                'Amazing!',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sequence Puzzle ────────────────────────────────────────────────
// Tap an item to select it (glows), then tap a numbered slot to place it.
// Drag-and-drop also works as a bonus.

class _SequencePuzzle extends StatefulWidget {
  const _SequencePuzzle({required this.puzzle, required this.onComplete});
  final Map<String, dynamic> puzzle;
  final VoidCallback onComplete;

  @override
  State<_SequencePuzzle> createState() => _SequencePuzzleState();
}

class _SequencePuzzleState extends State<_SequencePuzzle> {
  late List<Map<String, dynamic>> _shuffled;
  late List<Map<String, dynamic>?> _slots;
  String? _selectedId;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    final items = (widget.puzzle['items'] as List).cast<Map<String, dynamic>>();
    _shuffled = List.from(items)..shuffle();
    _slots = List.filled(items.length, null);
  }

  bool get _allFilled => _slots.every((s) => s != null);

  bool get _isCorrect {
    final items = (widget.puzzle['items'] as List).cast<Map<String, dynamic>>();
    for (int i = 0; i < _slots.length; i++) {
      if (_slots[i]?['id'] != items[i]['id']) return false;
    }
    return true;
  }

  void _selectItem(String id) => setState(() {
        _selectedId = _selectedId == id ? null : id;
      });

  void _placeInSlot(int slotIndex) {
    if (_selectedId == null) return;
    final item = _shuffled.firstWhere(
      (it) => it['id'] == _selectedId,
      orElse: () => <String, dynamic>{},
    );
    if (item.isEmpty) return;
    setState(() {
      // Remove from any other slot
      for (int j = 0; j < _slots.length; j++) {
        if (_slots[j]?['id'] == _selectedId) _slots[j] = null;
      }
      _slots[slotIndex] = item;
      _selectedId = null;
      _checked = false;
    });
  }

  void _check() {
    if (!_allFilled) return;
    setState(() => _checked = true);
    if (_isCorrect) {
      Future.delayed(const Duration(milliseconds: 400), widget.onComplete);
    }
  }

  void _reset() => setState(() {
        _shuffled = List.from(
          (widget.puzzle['items'] as List).cast<Map<String, dynamic>>(),
        )..shuffle();
        _slots = List.filled(_slots.length, null);
        _selectedId = null;
        _checked = false;
      });

  @override
  Widget build(BuildContext context) {
    const locale = 'en';
    final items = (widget.puzzle['items'] as List).cast<Map<String, dynamic>>();

    return Column(
      children: [
        // Numbered drop slots — tap to place selected item
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_slots.length, (i) {
            final item = _slots[i];
            Color? slotColor;
            if (_checked && item != null) {
              slotColor = item['id'] == items[i]['id']
                  ? AppColors.dropTargetSuccess
                  : AppColors.emotionVerySad;
            }
            final isActive = _selectedId != null && item == null;

            return GestureDetector(
              onTap: () => _placeInSlot(i),
              child: DragTarget<Map<String, dynamic>>(
                onAcceptWithDetails: (details) {
                  setState(() {
                    for (int j = 0; j < _slots.length; j++) {
                      if (_slots[j]?['id'] == details.data['id']) _slots[j] = null;
                    }
                    _slots[i] = details.data;
                    _selectedId = null;
                    _checked = false;
                  });
                },
                builder: (ctx, candidates, _) {
                  final hovering = candidates.isNotEmpty;
                  return Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: slotColor ??
                              (hovering || isActive
                                  ? AppColors.dropTargetActive
                                  : AppColors.dropTargetEmpty),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: hovering || isActive
                                ? AppColors.primary
                                : Colors.grey.shade300,
                            width: hovering || isActive ? 3 : 2,
                          ),
                        ),
                        child: item == null
                            ? Center(
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    fontSize: 28,
                                    color: isActive ? AppColors.primary : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(_emojiFor(item), style: const TextStyle(fontSize: 44)),
                              ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${i + 1}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                    ],
                  );
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 28),
        // Draggable / tappable items
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: _shuffled.where((item) {
            return !_slots.any((s) => s?['id'] == item['id']);
          }).map((item) {
            final id = item['id'] as String;
            final isSelected = _selectedId == id;
            return GestureDetector(
              onTap: () => _selectItem(id),
              child: Draggable<Map<String, dynamic>>(
                data: item,
                feedback: _ItemChip(item: item, locale: locale, isDragging: true),
                childWhenDragging: _ItemChip(item: item, locale: locale, isDragging: false, faded: true),
                child: _ItemChip(item: item, locale: locale, isDragging: false, isSelected: isSelected),
              ),
            );
          }).toList(),
        ),
        const Spacer(),
        if (_checked && !_isCorrect)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ElevatedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again!'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        if (_allFilled && !_checked)
          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              onPressed: _check,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
              child: const Text('Check! ✓', style: TextStyle(fontSize: 20)),
            ),
          ),
      ],
    );
  }
}

class _ItemChip extends StatelessWidget {
  const _ItemChip({
    required this.item,
    required this.locale,
    required this.isDragging,
    this.faded = false,
    this.isSelected = false,
  });
  final Map<String, dynamic> item;
  final String locale;
  final bool isDragging;
  final bool faded;
  final bool isSelected;

  Color _color() {
    try {
      return Color(int.parse((item['color'] as String).replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Opacity(
      opacity: faded ? 0.3 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isSelected ? 0.3 : 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: isSelected ? 3.5 : 2),
          boxShadow: (isDragging || isSelected)
              ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 14, spreadRadius: isSelected ? 2 : 0)]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_emojiFor(item), style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 4),
            Text(
              (item['label'] as Map)[locale] as String? ?? '',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Match Shape Puzzle ─────────────────────────────────────────────
// Tap an item to select it, then tap a target slot to place it.
// Drag-and-drop also works.

class _MatchShapePuzzle extends StatefulWidget {
  const _MatchShapePuzzle({required this.puzzle, required this.onComplete});
  final Map<String, dynamic> puzzle;
  final VoidCallback onComplete;

  @override
  State<_MatchShapePuzzle> createState() => _MatchShapePuzzleState();
}

class _MatchShapePuzzleState extends State<_MatchShapePuzzle> {
  late Map<String, String?> _placements; // itemId -> targetId
  String? _selectedItemId;
  int _correctCount = 0;

  @override
  void initState() {
    super.initState();
    final items = (widget.puzzle['items'] as List).cast<Map<String, dynamic>>();
    _placements = {for (final i in items) i['id'] as String: null};
  }

  void _onPlaced(String itemId, String targetId) {
    final items = (widget.puzzle['items'] as List).cast<Map<String, dynamic>>();
    setState(() {
      _placements.updateAll((k, v) => v == targetId ? null : v);
      _placements[itemId] = targetId;
      _correctCount = _placements.entries.where((e) {
        if (e.value == null) return false;
        final itm = items.firstWhere((i) => i['id'] == e.key);
        return itm['target_id'] == e.value;
      }).length;
    });

    if (_correctCount == items.length) {
      Future.delayed(const Duration(milliseconds: 400), widget.onComplete);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = (widget.puzzle['items'] as List).cast<Map<String, dynamic>>();
    final targets = (widget.puzzle['targets'] as List).cast<Map<String, dynamic>>();

    // Map each target ID to the emoji that belongs there
    final hintEmojiMap = <String, String>{
      for (final item in items) item['target_id'] as String: _emojiFor(item),
    };

    final unplacedItems = items.where((i) => _placements[i['id'] as String] == null).toList();

    return Column(
      children: [
        // Target slots — tap to receive a selected item
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: targets.map((target) {
            final targetId = target['id'] as String;
            final placedItemId = _placements.entries
                .firstWhere((e) => e.value == targetId, orElse: () => const MapEntry('', null))
                .key;
            final placedItem = placedItemId.isNotEmpty
                ? items.firstWhere((i) => i['id'] == placedItemId, orElse: () => {})
                : null;
            final isCorrect = placedItem != null && (placedItem as Map)['target_id'] == targetId;
            final canReceive = _selectedItemId != null;

            return GestureDetector(
              onTap: () {
                if (_selectedItemId == null) return;
                _onPlaced(_selectedItemId!, targetId);
                setState(() => _selectedItemId = null);
              },
              child: DragTarget<Map<String, dynamic>>(
                onAcceptWithDetails: (d) => _onPlaced(d.data['id'] as String, targetId),
                builder: (ctx, candidates, _) {
                  final hovering = candidates.isNotEmpty;
                  return Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: hovering || (canReceive && placedItem == null)
                              ? AppColors.dropTargetActive
                              : isCorrect
                                  ? AppColors.dropTargetSuccess
                                  : AppColors.dropTargetEmpty,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isCorrect
                                ? AppColors.success
                                : hovering || (canReceive && placedItem == null)
                                    ? AppColors.primary
                                    : Colors.grey.shade300,
                            width: hovering || canReceive ? 3 : 2.5,
                          ),
                        ),
                        child: placedItem != null
                            ? Center(
                                child: Text(
                                  _emojiFor(placedItem),
                                  style: const TextStyle(fontSize: 52),
                                ),
                              )
                            : Center(
                                child: Opacity(
                                  opacity: 0.2,
                                  child: Text(
                                    hintEmojiMap[targetId] ?? '❓',
                                    style: const TextStyle(fontSize: 52),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 6),
                      Text(_slotEmoji(targetId), style: const TextStyle(fontSize: 22)),
                    ],
                  );
                },
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 40),
        // Tappable / draggable items
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: unplacedItems.map((item) {
            final id = item['id'] as String;
            final isSelected = _selectedItemId == id;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedItemId = isSelected ? null : id;
              }),
              child: Draggable<Map<String, dynamic>>(
                data: item,
                feedback: _ShapeChip(item: item, isDragging: true),
                childWhenDragging: _ShapeChip(item: item, isDragging: false, faded: true),
                child: _ShapeChip(item: item, isDragging: false, isSelected: isSelected),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ShapeChip extends StatelessWidget {
  const _ShapeChip({
    required this.item,
    required this.isDragging,
    this.faded = false,
    this.isSelected = false,
  });
  final Map<String, dynamic> item;
  final bool isDragging;
  final bool faded;
  final bool isSelected;

  Color _color() {
    try {
      return Color(int.parse((item['color'] as String).replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Opacity(
      opacity: faded ? 0.3 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: color.withValues(alpha: isSelected ? 0.3 : 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: isSelected ? 4 : 2.5),
          boxShadow: (isDragging || isSelected)
              ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 14, spreadRadius: isSelected ? 3 : 0)]
              : [],
        ),
        child: Center(
          child: Text(_emojiFor(item), style: const TextStyle(fontSize: 44)),
        ),
      ),
    );
  }
}

// ── Pattern Puzzle ─────────────────────────────────────────────────

class _PatternPuzzle extends StatefulWidget {
  const _PatternPuzzle({required this.puzzle, required this.onComplete});
  final Map<String, dynamic> puzzle;
  final VoidCallback onComplete;

  @override
  State<_PatternPuzzle> createState() => _PatternPuzzleState();
}

class _PatternPuzzleState extends State<_PatternPuzzle> {
  String? _selected;
  bool _wrong = false;

  void _pick(Map<String, dynamic> choice) {
    if (choice['is_correct'] == true) {
      setState(() => _selected = choice['id'] as String);
      Future.delayed(const Duration(milliseconds: 400), widget.onComplete);
    } else {
      setState(() {
        _selected = choice['id'] as String;
        _wrong = true;
      });
      Future.delayed(
        const Duration(milliseconds: 800),
        () => setState(() {
          _selected = null;
          _wrong = false;
        }),
      );
    }
  }

  Color _choiceColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sequence = (widget.puzzle['pattern_sequence'] as List).cast<String>();
    final choices = (widget.puzzle['choices'] as List).cast<Map<String, dynamic>>();
    final emojiMap = <String, String>{
      for (final c in choices) c['id'] as String: _emojiFor(c),
    };

    return Column(
      children: [
        // Pattern row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: sequence.map((step) {
              if (step == '?') {
                return Container(
                  margin: const EdgeInsets.all(6),
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.dropTargetEmpty,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: const Center(
                    child: Text('?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  ),
                );
              }
              final choice = choices.firstWhere((c) => c['id'] == step, orElse: () => choices.first);
              final stepColor = _choiceColor(choice['color'] as String);
              return Container(
                margin: const EdgeInsets.all(6),
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: stepColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: stepColor, width: 2),
                ),
                child: Center(
                  child: Text(emojiMap[step] ?? '❓', style: const TextStyle(fontSize: 36)),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 32),
        const Text('What comes next?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: choices.map((choice) {
            final id = choice['id'] as String;
            final color = _choiceColor(choice['color'] as String);
            final isSelected = _selected == id;
            final isWrong = isSelected && _wrong;

            return GestureDetector(
              onTap: () => _pick(choice),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: isWrong
                      ? AppColors.error.withValues(alpha: 0.2)
                      : isSelected
                          ? AppColors.success.withValues(alpha: 0.2)
                          : color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isWrong ? AppColors.error : isSelected ? AppColors.success : color,
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Text(_emojiFor(choice), style: const TextStyle(fontSize: 44)),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Count Match Puzzle ─────────────────────────────────────────────
// Tap items OR drag them into the bowl.

class _CountMatchPuzzle extends StatefulWidget {
  const _CountMatchPuzzle({required this.puzzle, required this.onComplete});
  final Map<String, dynamic> puzzle;
  final VoidCallback onComplete;

  @override
  State<_CountMatchPuzzle> createState() => _CountMatchPuzzleState();
}

class _CountMatchPuzzleState extends State<_CountMatchPuzzle> {
  int _placed = 0;

  void _addOne() {
    final target = widget.puzzle['target_count'] as int;
    if (_placed >= target) return;
    setState(() => _placed++);
    if (_placed == target) {
      Future.delayed(const Duration(milliseconds: 400), widget.onComplete);
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.puzzle['target_count'] as int;
    final total = widget.puzzle['total_available'] as int;
    final itemEmoji = (widget.puzzle['item_emoji'] as String?) ?? '🔵';

    return Column(
      children: [
        // Drop zone (bowl / table)
        DragTarget<int>(
          onAcceptWithDetails: (_) => _addOne(),
          builder: (ctx, candidates, _) => AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: candidates.isNotEmpty
                  ? AppColors.dropTargetActive
                  : AppColors.dropTargetEmpty,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: candidates.isNotEmpty ? AppColors.primary : Colors.grey.shade300,
                width: 2.5,
              ),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: List.generate(
                      _placed,
                      (_) => Text(itemEmoji, style: const TextStyle(fontSize: 30)),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 14,
                  child: Text(
                    '$_placed / $target',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _placed == target ? AppColors.success : Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        // Items — TAP to add to bowl, or drag
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: List.generate(total - _placed, (i) {
            return GestureDetector(
              onTap: _addOne,
              child: Draggable<int>(
                data: i,
                feedback: Material(
                  color: Colors.transparent,
                  child: Text(itemEmoji,
                      style: const TextStyle(fontSize: 56, decoration: TextDecoration.none)),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.25,
                  child: Text(itemEmoji, style: const TextStyle(fontSize: 48)),
                ),
                child: Text(itemEmoji, style: const TextStyle(fontSize: 48)),
              ),
            );
          }),
        ),
      ],
    );
  }
}
