import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/sound_service.dart';
import '../../core/visuals/dino_art.dart';
import '../../core/visuals/effects.dart';

/// Reusable puzzle widgets shared by story chapters (PuzzleScreen) and the
/// endless Practice Adventure (PracticeScreen).
///
/// All puzzles consume the same JSON map format used in chapter files, so
/// hand-authored and procedurally-generated puzzles work identically.

// ── Emoji helpers ──────────────────────────────────────────────────

String emojiFor(Map<String, dynamic> item) {
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

String slotEmoji(String targetId) {
  if (targetId.startsWith('nest_')) return '🪺';
  if (targetId.startsWith('hanger_')) return '🪝';
  if (targetId.startsWith('plate_')) return '🍽️';
  if (targetId.startsWith('letter_')) return '🔤';
  if (targetId.startsWith('basket_')) return '🧺';
  return '📦';
}

Color parseItemColor(dynamic hex, [Color fallback = AppColors.primary]) {
  try {
    return Color(int.parse((hex as String).replaceFirst('#', '0xFF')));
  } catch (_) {
    return fallback;
  }
}

// ── Sequence Puzzle ────────────────────────────────────────────────
// Tap an item to select it (glows), then tap a numbered slot to place it.
// Drag-and-drop also works. Supports optional `decoys` (extra wrong items).

class SequencePuzzle extends StatefulWidget {
  const SequencePuzzle({
    super.key,
    required this.puzzle,
    required this.onComplete,
    this.onWrong,
  });
  final Map<String, dynamic> puzzle;
  final VoidCallback onComplete;
  final VoidCallback? onWrong;

  @override
  State<SequencePuzzle> createState() => _SequencePuzzleState();
}

class _SequencePuzzleState extends State<SequencePuzzle> {
  late List<Map<String, dynamic>> _shuffled;
  late List<Map<String, dynamic>?> _slots;
  String? _selectedId;
  bool _checked = false;

  List<Map<String, dynamic>> get _items =>
      (widget.puzzle['items'] as List).cast<Map<String, dynamic>>();

  List<Map<String, dynamic>> get _decoys =>
      ((widget.puzzle['decoys'] as List?) ?? []).cast<Map<String, dynamic>>();

  @override
  void initState() {
    super.initState();
    _shuffled = [..._items, ..._decoys]..shuffle();
    _slots = List.filled(_items.length, null);
  }

  bool get _allFilled => _slots.every((s) => s != null);

  bool get _isCorrect {
    for (int i = 0; i < _slots.length; i++) {
      if (_slots[i]?['id'] != _items[i]['id']) return false;
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
    SoundFx.play('place');
    setState(() {
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
      SoundFx.play('correct');
      Future.delayed(const Duration(milliseconds: 400), widget.onComplete);
    } else {
      SoundFx.play('wrong');
      widget.onWrong?.call();
    }
  }

  void _reset() => setState(() {
        _shuffled = [..._items, ..._decoys]..shuffle();
        _slots = List.filled(_slots.length, null);
        _selectedId = null;
        _checked = false;
      });

  @override
  Widget build(BuildContext context) {
    const locale = 'en';
    final items = _items;

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
                      if (_slots[j]?['id'] == details.data['id']) {
                        _slots[j] = null;
                      }
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
                                    color: isActive
                                        ? AppColors.primary
                                        : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(emojiFor(item),
                                    style: const TextStyle(fontSize: 44)),
                              ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${i + 1}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600),
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
                feedback: ItemChip(item: item, locale: locale, isDragging: true),
                childWhenDragging: ItemChip(
                    item: item, locale: locale, isDragging: false, faded: true),
                child: ItemChip(
                    item: item,
                    locale: locale,
                    isDragging: false,
                    isSelected: isSelected),
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

class ItemChip extends StatelessWidget {
  const ItemChip({
    super.key,
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

  @override
  Widget build(BuildContext context) {
    final color = parseItemColor(item['color']);
    final label = (item['label'] as Map?)?[locale] as String? ?? '';
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
              ? [
                  BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 14,
                      spreadRadius: isSelected ? 2 : 0)
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emojiFor(item), style: const TextStyle(fontSize: 40)),
            if (label.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 12, color: color),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Match Shape Puzzle ─────────────────────────────────────────────
// Tap an item to select it, then tap a target slot to place it.
// Targets may carry a `display` string (e.g. a letter) shown in the slot;
// otherwise a ghost hint of the matching item is shown unless
// puzzle['show_hints'] == false.

class MatchShapePuzzle extends StatefulWidget {
  const MatchShapePuzzle({
    super.key,
    required this.puzzle,
    required this.onComplete,
    this.onWrong,
  });
  final Map<String, dynamic> puzzle;
  final VoidCallback onComplete;
  final VoidCallback? onWrong;

  @override
  State<MatchShapePuzzle> createState() => _MatchShapePuzzleState();
}

class _MatchShapePuzzleState extends State<MatchShapePuzzle> {
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
    final wasCorrect = items
            .firstWhere((i) => i['id'] == itemId)['target_id'] ==
        targetId;
    SoundFx.play(wasCorrect ? 'correct' : 'wrong');
    setState(() {
      _placements.updateAll((k, v) => v == targetId ? null : v);
      _placements[itemId] = targetId;
      _correctCount = _placements.entries.where((e) {
        if (e.value == null) return false;
        final itm = items.firstWhere((i) => i['id'] == e.key);
        return itm['target_id'] == e.value;
      }).length;
    });

    if (!wasCorrect) widget.onWrong?.call();

    if (_correctCount == items.length) {
      Future.delayed(const Duration(milliseconds: 400), widget.onComplete);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = (widget.puzzle['items'] as List).cast<Map<String, dynamic>>();
    final targets =
        (widget.puzzle['targets'] as List).cast<Map<String, dynamic>>();
    final showHints = widget.puzzle['show_hints'] != false;

    final hintEmojiMap = <String, String>{
      for (final item in items) item['target_id'] as String: emojiFor(item),
    };

    final unplacedItems =
        items.where((i) => _placements[i['id'] as String] == null).toList();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: targets.map((target) {
            final targetId = target['id'] as String;
            final display = target['display'] as String?;
            final placedItemId = _placements.entries
                .firstWhere((e) => e.value == targetId,
                    orElse: () => const MapEntry('', null))
                .key;
            final placedItem = placedItemId.isNotEmpty
                ? items.firstWhere((i) => i['id'] == placedItemId,
                    orElse: () => {})
                : null;
            final isCorrect = placedItem != null &&
                (placedItem as Map)['target_id'] == targetId;
            final canReceive = _selectedItemId != null;

            return GestureDetector(
              onTap: () {
                if (_selectedItemId == null) return;
                _onPlaced(_selectedItemId!, targetId);
                setState(() => _selectedItemId = null);
              },
              child: DragTarget<Map<String, dynamic>>(
                onAcceptWithDetails: (d) =>
                    _onPlaced(d.data['id'] as String, targetId),
                builder: (ctx, candidates, _) {
                  final hovering = candidates.isNotEmpty;
                  Widget slotChild;
                  if (placedItem != null) {
                    slotChild = Center(
                      child: Text(emojiFor(placedItem),
                          style: const TextStyle(fontSize: 52)),
                    );
                  } else if (display != null) {
                    slotChild = Center(
                      child: Text(
                        display,
                        style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textMedium,
                        ),
                      ),
                    );
                  } else if (showHints) {
                    slotChild = Center(
                      child: Opacity(
                        opacity: 0.2,
                        child: Text(hintEmojiMap[targetId] ?? '❓',
                            style: const TextStyle(fontSize: 52)),
                      ),
                    );
                  } else {
                    slotChild = const Center(
                      child: Text('?',
                          style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey)),
                    );
                  }
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
                                : hovering ||
                                        (canReceive && placedItem == null)
                                    ? AppColors.primary
                                    : Colors.grey.shade300,
                            width: hovering || canReceive ? 3 : 2.5,
                          ),
                        ),
                        child: slotChild,
                      ),
                      const SizedBox(height: 6),
                      Text(slotEmoji(targetId),
                          style: const TextStyle(fontSize: 22)),
                    ],
                  );
                },
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 40),
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
                feedback: ShapeChip(item: item, isDragging: true),
                childWhenDragging:
                    ShapeChip(item: item, isDragging: false, faded: true),
                child: ShapeChip(
                    item: item, isDragging: false, isSelected: isSelected),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class ShapeChip extends StatelessWidget {
  const ShapeChip({
    super.key,
    required this.item,
    required this.isDragging,
    this.faded = false,
    this.isSelected = false,
  });
  final Map<String, dynamic> item;
  final bool isDragging;
  final bool faded;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final color = parseItemColor(item['color']);
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
              ? [
                  BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 14,
                      spreadRadius: isSelected ? 3 : 0)
                ]
              : [],
        ),
        child: Center(
          child: Text(emojiFor(item), style: const TextStyle(fontSize: 44)),
        ),
      ),
    );
  }
}

// ── Pattern Puzzle ─────────────────────────────────────────────────

class PatternPuzzle extends StatefulWidget {
  const PatternPuzzle({
    super.key,
    required this.puzzle,
    required this.onComplete,
    this.onWrong,
  });
  final Map<String, dynamic> puzzle;
  final VoidCallback onComplete;
  final VoidCallback? onWrong;

  @override
  State<PatternPuzzle> createState() => _PatternPuzzleState();
}

class _PatternPuzzleState extends State<PatternPuzzle> {
  String? _selected;
  bool _wrong = false;

  void _pick(Map<String, dynamic> choice, [Offset? tapPosition]) {
    if (choice['is_correct'] == true) {
      SoundFx.play('correct');
      if (tapPosition != null) StarBurst.show(context, tapPosition);
      setState(() => _selected = choice['id'] as String);
      Future.delayed(const Duration(milliseconds: 400), widget.onComplete);
    } else {
      SoundFx.play('wrong');
      widget.onWrong?.call();
      setState(() {
        _selected = choice['id'] as String;
        _wrong = true;
      });
      Future.delayed(
        const Duration(milliseconds: 800),
        () {
          if (!mounted) return;
          setState(() {
            _selected = null;
            _wrong = false;
          });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sequence = (widget.puzzle['pattern_sequence'] as List).cast<String>();
    final choices =
        (widget.puzzle['choices'] as List).cast<Map<String, dynamic>>();
    final emojiMap = <String, String>{
      for (final c in choices) c['id'] as String: emojiFor(c),
    };

    return Column(
      children: [
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
                    child: Text('?',
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold)),
                  ),
                );
              }
              final choice = choices.firstWhere((c) => c['id'] == step,
                  orElse: () => choices.first);
              final stepColor = parseItemColor(choice['color']);
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
                  child: Text(emojiMap[step] ?? '❓',
                      style: const TextStyle(fontSize: 36)),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 32),
        const Text('What comes next?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: choices.map((choice) {
            final id = choice['id'] as String;
            final color = parseItemColor(choice['color']);
            final isSelected = _selected == id;
            final isWrong = isSelected && _wrong;

            return GestureDetector(
              onTapUp: (d) => _pick(choice, d.globalPosition),
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
                    color: isWrong
                        ? AppColors.error
                        : isSelected
                            ? AppColors.success
                            : color,
                    width: 3,
                  ),
                ),
                child: Center(
                  child:
                      Text(emojiFor(choice), style: const TextStyle(fontSize: 44)),
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
// A real counting test: the child can put in too many or too few, take
// items back OUT of the basket by tapping them, and presses Check when
// they think the count is right. Wrong counts get gentle encouragement.

class CountMatchPuzzle extends StatefulWidget {
  const CountMatchPuzzle({
    super.key,
    required this.puzzle,
    required this.onComplete,
    this.onWrong,
  });
  final Map<String, dynamic> puzzle;
  final VoidCallback onComplete;
  final VoidCallback? onWrong;

  @override
  State<CountMatchPuzzle> createState() => _CountMatchPuzzleState();
}

class _CountMatchPuzzleState extends State<CountMatchPuzzle> {
  int _placed = 0;
  bool _wrongFlash = false;
  bool _done = false;

  int get _target => widget.puzzle['target_count'] as int;
  int get _total => widget.puzzle['total_available'] as int;

  void _addOne() {
    if (_done || _placed >= _total) return;
    SoundFx.play('place');
    setState(() {
      _placed++;
      _wrongFlash = false;
    });
  }

  void _removeOne() {
    if (_done || _placed <= 0) return;
    SoundFx.play('flip', volume: 0.4);
    setState(() {
      _placed--;
      _wrongFlash = false;
    });
  }

  void _check() {
    if (_done) return;
    if (_placed == _target) {
      SoundFx.play('correct');
      setState(() => _done = true);
      Future.delayed(const Duration(milliseconds: 300), widget.onComplete);
    } else {
      SoundFx.play('wrong');
      widget.onWrong?.call();
      setState(() => _wrongFlash = true);
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => _wrongFlash = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemEmoji = (widget.puzzle['item_emoji'] as String?) ?? '🔵';
    // Optional math expression shown big (e.g. "2 + 3") for addition levels.
    final expression = widget.puzzle['expression'] as String?;

    return Column(
      children: [
        if (expression != null) ...[
          Text(
            expression,
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
        ],
        DragTarget<int>(
          onAcceptWithDetails: (_) => _addOne(),
          builder: (ctx, candidates, _) => AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: _wrongFlash
                  ? AppColors.error.withValues(alpha: 0.15)
                  : _done
                      ? AppColors.dropTargetSuccess
                      : candidates.isNotEmpty
                          ? AppColors.dropTargetActive
                          : AppColors.dropTargetEmpty,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: _wrongFlash
                    ? AppColors.error
                    : _done
                        ? AppColors.success
                        : candidates.isNotEmpty
                            ? AppColors.primary
                            : Colors.grey.shade300,
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
                      // Tap an item in the basket to take it back out.
                      (_) => GestureDetector(
                        onTap: _removeOne,
                        child: ItemGraphic(token: itemEmoji, size: 30),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 14,
                  child: Text(
                    '$_placed',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: _done
                          ? AppColors.success
                          : _wrongFlash
                              ? AppColors.error
                              : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: List.generate(_total - _placed, (i) {
            return GestureDetector(
              onTap: _addOne,
              child: Draggable<int>(
                data: i,
                feedback: Material(
                  color: Colors.transparent,
                  child: ItemGraphic(token: itemEmoji, size: 56),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.25,
                  child: ItemGraphic(token: itemEmoji, size: 48),
                ),
                child: ItemGraphic(token: itemEmoji, size: 48),
              ),
            );
          }),
        ),
        const Spacer(),
        if (_placed > 0 && !_done)
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

// The buildPuzzleWidget dispatcher lives in puzzle_widgets_extra.dart,
// which covers both these core puzzles and the extended set.
