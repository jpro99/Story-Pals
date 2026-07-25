import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/sound_service.dart';
import '../../core/visuals/dino_art.dart';
import '../../core/visuals/effects.dart';
import 'puzzle_widgets.dart';

export 'puzzle_widgets.dart';

/// Four additional puzzle mechanics to keep sessions fresh:
///  * [RoboMazePuzzle]   — build a program of moves, run it, debug it.
///  * [OddOneOutPuzzle]  — which one doesn't belong? (classification)
///  * [WhichMorePuzzle]  — which group has more/fewer? (number sense)
///  * [MemoryPairsPuzzle]— flip cards, find the pairs. (working memory)

/// Builds the right puzzle widget for any puzzle map's `type`.
Widget buildPuzzleWidget(
  Map<String, dynamic> puzzle, {
  required VoidCallback onComplete,
  VoidCallback? onWrong,
}) {
  switch (puzzle['type'] as String) {
    case 'sequence':
      return SequencePuzzle(
          puzzle: puzzle, onComplete: onComplete, onWrong: onWrong);
    case 'match_shape':
      return MatchShapePuzzle(
          puzzle: puzzle, onComplete: onComplete, onWrong: onWrong);
    case 'pattern':
      return PatternPuzzle(
          puzzle: puzzle, onComplete: onComplete, onWrong: onWrong);
    case 'count_match':
      return CountMatchPuzzle(
          puzzle: puzzle, onComplete: onComplete, onWrong: onWrong);
    case 'robo_maze':
      return RoboMazePuzzle(
          puzzle: puzzle, onComplete: onComplete, onWrong: onWrong);
    case 'odd_one_out':
      return OddOneOutPuzzle(
          puzzle: puzzle, onComplete: onComplete, onWrong: onWrong);
    case 'which_more':
      return WhichMorePuzzle(
          puzzle: puzzle, onComplete: onComplete, onWrong: onWrong);
    case 'memory_pairs':
      return MemoryPairsPuzzle(puzzle: puzzle, onComplete: onComplete);
    default:
      return Center(child: Text('Unknown puzzle type: ${puzzle['type']}'));
  }
}

// ── Robo Maze ──────────────────────────────────────────────────────
// True pre-programming: the child taps arrow commands to build a program,
// presses GO, and watches the hero execute it step by step. Bumping a wall
// or rock stops the run — edit the program and try again (debugging!).

class RoboMazePuzzle extends StatefulWidget {
  const RoboMazePuzzle({
    super.key,
    required this.puzzle,
    required this.onComplete,
    this.onWrong,
  });
  final Map<String, dynamic> puzzle;
  final VoidCallback onComplete;
  final VoidCallback? onWrong;

  @override
  State<RoboMazePuzzle> createState() => _RoboMazePuzzleState();
}

class _RoboMazePuzzleState extends State<RoboMazePuzzle> {
  final List<String> _program = [];
  late List<int> _pos;
  bool _running = false;
  bool _crashed = false;
  bool _done = false;

  int get _w => widget.puzzle['grid_w'] as int;
  int get _h => widget.puzzle['grid_h'] as int;
  List<int> get _start => (widget.puzzle['start'] as List).cast<int>();
  List<int> get _goal => (widget.puzzle['goal'] as List).cast<int>();
  List<List<int>> get _obstacles => ((widget.puzzle['obstacles'] as List?) ?? [])
      .map((o) => (o as List).cast<int>())
      .toList();
  String get _heroEmoji =>
      (widget.puzzle['hero_emoji'] as String?) ?? '🦕';
  String get _goalEmoji =>
      (widget.puzzle['goal_emoji'] as String?) ?? '🍓';

  static const _moves = {
    'up': (dx: 0, dy: -1, emoji: '⬆️'),
    'down': (dx: 0, dy: 1, emoji: '⬇️'),
    'left': (dx: -1, dy: 0, emoji: '⬅️'),
    'right': (dx: 1, dy: 0, emoji: '➡️'),
  };

  @override
  void initState() {
    super.initState();
    _pos = List.of(_start);
  }

  bool _isObstacle(int x, int y) =>
      _obstacles.any((o) => o[0] == x && o[1] == y);

  void _addMove(String move) {
    if (_running || _done || _program.length >= 12) return;
    SoundFx.play('place', volume: 0.4);
    setState(() {
      _program.add(move);
      _crashed = false;
    });
  }

  void _removeLast() {
    if (_running || _done || _program.isEmpty) return;
    SoundFx.play('flip', volume: 0.4);
    setState(() {
      _program.removeLast();
      _crashed = false;
    });
  }

  Future<void> _run() async {
    if (_running || _done || _program.isEmpty) return;
    setState(() {
      _running = true;
      _crashed = false;
      _pos = List.of(_start);
    });

    for (final move in _program) {
      await Future.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      final m = _moves[move]!;
      final nx = _pos[0] + m.dx;
      final ny = _pos[1] + m.dy;
      if (nx < 0 || nx >= _w || ny < 0 || ny >= _h || _isObstacle(nx, ny)) {
        // Crash! Back to start, program kept for debugging.
        SoundFx.play('crash');
        setState(() {
          _crashed = true;
          _running = false;
          _pos = List.of(_start);
        });
        widget.onWrong?.call();
        return;
      }
      SoundFx.play('step', volume: 0.45);
      setState(() => _pos = [nx, ny]);
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    if (_pos[0] == _goal[0] && _pos[1] == _goal[1]) {
      SoundFx.play('correct');
      setState(() {
        _done = true;
        _running = false;
      });
      widget.onComplete();
    } else {
      SoundFx.play('crash');
      setState(() {
        _crashed = true;
        _running = false;
        _pos = List.of(_start);
      });
      widget.onWrong?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // The maze grid
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: _w / _h,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _crashed ? AppColors.error : AppColors.primary,
                    width: 2.5,
                  ),
                ),
                padding: const EdgeInsets.all(6),
                child: Column(
                  children: List.generate(_h, (y) {
                    return Expanded(
                      child: Row(
                        children: List.generate(_w, (x) {
                          final isHero = _pos[0] == x && _pos[1] == y;
                          final isGoal = _goal[0] == x && _goal[1] == y;
                          final isRock = _isObstacle(x, y);
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: AppColors.dropTargetEmpty
                                    .withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: FittedBox(
                                  child: Text(
                                    isHero
                                        ? _heroEmoji
                                        : isGoal
                                            ? _goalEmoji
                                            : isRock
                                                ? '🪨'
                                                : '',
                                    style: const TextStyle(fontSize: 34),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // The program strip
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: _crashed ? AppColors.error : Colors.grey.shade300,
                width: 2),
          ),
          child: Row(
            children: [
              const Text('📜', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: _program.isEmpty
                    ? Text(
                        'Tap arrows to build your program!',
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w600),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _program
                              .map((m) => Padding(
                                    padding:
                                        const EdgeInsets.only(right: 4),
                                    child: Text(_moves[m]!.emoji,
                                        style:
                                            const TextStyle(fontSize: 26)),
                                  ))
                              .toList(),
                        ),
                      ),
              ),
              if (_program.isNotEmpty && !_running)
                IconButton(
                  icon: const Icon(Icons.backspace_outlined),
                  onPressed: _removeLast,
                  tooltip: 'Remove last step',
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Command buttons + GO
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final entry in _moves.entries)
              _ArrowButton(
                emoji: entry.value.emoji,
                enabled: !_running && !_done,
                onTap: () => _addMove(entry.key),
              ),
            SizedBox(
              height: 62,
              child: ElevatedButton(
                onPressed:
                    (!_running && !_done && _program.isNotEmpty) ? _run : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                ),
                child: Text(_running ? '...' : '▶ GO!',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.emoji,
    required this.enabled,
    required this.onTap,
  });
  final String emoji;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: enabled
              ? Colors.white.withValues(alpha: 0.9)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 28))),
      ),
    );
  }
}

// ── Odd One Out ────────────────────────────────────────────────────

class OddOneOutPuzzle extends StatefulWidget {
  const OddOneOutPuzzle({
    super.key,
    required this.puzzle,
    required this.onComplete,
    this.onWrong,
  });
  final Map<String, dynamic> puzzle;
  final VoidCallback onComplete;
  final VoidCallback? onWrong;

  @override
  State<OddOneOutPuzzle> createState() => _OddOneOutPuzzleState();
}

class _OddOneOutPuzzleState extends State<OddOneOutPuzzle> {
  String? _wrongId;
  bool _done = false;

  void _pick(Map<String, dynamic> item, Offset tapPosition) {
    if (_done) return;
    if (item['id'] == widget.puzzle['odd_id']) {
      SoundFx.play('correct');
      setState(() => _done = true);
      StarBurst.show(context, tapPosition);
      Future.delayed(const Duration(milliseconds: 400), widget.onComplete);
    } else {
      SoundFx.play('wrong');
      widget.onWrong?.call();
      setState(() => _wrongId = item['id'] as String);
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _wrongId = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final items =
        (widget.puzzle['items'] as List).cast<Map<String, dynamic>>();
    return Center(
      child: Wrap(
        spacing: 18,
        runSpacing: 18,
        alignment: WrapAlignment.center,
        children: items.map((item) {
          final isWrong = _wrongId == item['id'];
          final isOddDone = _done && item['id'] == widget.puzzle['odd_id'];
          return GestureDetector(
            onTapUp: (d) => _pick(item, d.globalPosition),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: isWrong
                    ? AppColors.error.withValues(alpha: 0.15)
                    : isOddDone
                        ? AppColors.dropTargetSuccess
                        : Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isWrong
                      ? AppColors.error
                      : isOddDone
                          ? AppColors.success
                          : AppColors.primary.withValues(alpha: 0.4),
                  width: 3,
                ),
              ),
              child: Center(
                child: ItemGraphic(
                    token: item['emoji'] as String? ?? '❓', size: 56),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Which Has More? ────────────────────────────────────────────────

class WhichMorePuzzle extends StatefulWidget {
  const WhichMorePuzzle({
    super.key,
    required this.puzzle,
    required this.onComplete,
    this.onWrong,
  });
  final Map<String, dynamic> puzzle;
  final VoidCallback onComplete;
  final VoidCallback? onWrong;

  @override
  State<WhichMorePuzzle> createState() => _WhichMorePuzzleState();
}

class _WhichMorePuzzleState extends State<WhichMorePuzzle> {
  String? _picked; // 'left' | 'right'
  bool _done = false;

  int get _left => widget.puzzle['left_count'] as int;
  int get _right => widget.puzzle['right_count'] as int;
  bool get _wantMore => (widget.puzzle['mode'] as String? ?? 'more') == 'more';

  void _pick(String side) {
    if (_done) return;
    final leftWins = _wantMore ? _left > _right : _left < _right;
    final correct = (side == 'left') == leftWins;
    SoundFx.play(correct ? 'correct' : 'wrong');
    setState(() => _picked = side);
    if (correct) {
      _done = true;
      Future.delayed(const Duration(milliseconds: 400), widget.onComplete);
    } else {
      widget.onWrong?.call();
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _picked = null);
      });
    }
  }

  Widget _group(String side, int count) {
    final emoji = widget.puzzle['item_emoji'] as String? ?? '🍓';
    final isPicked = _picked == side;
    final leftWins = _wantMore ? _left > _right : _left < _right;
    final isCorrectSide = (side == 'left') == leftWins;
    final showResult = isPicked;

    return Expanded(
      child: GestureDetector(
        onTap: () => _pick(side),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.all(14),
          constraints: const BoxConstraints(minHeight: 190),
          decoration: BoxDecoration(
            color: showResult
                ? (isCorrectSide
                    ? AppColors.dropTargetSuccess
                    : AppColors.error.withValues(alpha: 0.15))
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: showResult
                  ? (isCorrectSide ? AppColors.success : AppColors.error)
                  : AppColors.primary.withValues(alpha: 0.4),
              width: 3,
            ),
          ),
          child: Center(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: List.generate(
                count,
                (_) => ItemGraphic(token: emoji, size: 34),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            children: [
              _group('left', _left),
              _group('right', _right),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

// ── Memory Pairs ───────────────────────────────────────────────────

class MemoryPairsPuzzle extends StatefulWidget {
  const MemoryPairsPuzzle({
    super.key,
    required this.puzzle,
    required this.onComplete,
  });
  final Map<String, dynamic> puzzle;
  final VoidCallback onComplete;

  @override
  State<MemoryPairsPuzzle> createState() => _MemoryPairsPuzzleState();
}

class _MemoryCard {
  _MemoryCard({required this.content, required this.pairId});
  final String content;
  final int pairId;
  bool revealed = false;
  bool matched = false;
}

class _MemoryPairsPuzzleState extends State<MemoryPairsPuzzle> {
  late List<_MemoryCard> _cards;
  int? _firstFlipped;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final pairs = (widget.puzzle['pairs'] as List).cast<Map<String, dynamic>>();
    _cards = [];
    for (var i = 0; i < pairs.length; i++) {
      _cards.add(_MemoryCard(content: pairs[i]['a'] as String, pairId: i));
      _cards.add(_MemoryCard(content: pairs[i]['b'] as String, pairId: i));
    }
    _cards.shuffle(math.Random());
  }

  Future<void> _flip(int index) async {
    if (_busy) return;
    final card = _cards[index];
    if (card.revealed || card.matched) return;

    SoundFx.play('flip', volume: 0.45);
    setState(() => card.revealed = true);

    if (_firstFlipped == null) {
      _firstFlipped = index;
      return;
    }

    final first = _cards[_firstFlipped!];
    _firstFlipped = null;
    _busy = true;

    if (first.pairId == card.pairId) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      SoundFx.play('correct');
      setState(() {
        first.matched = true;
        card.matched = true;
      });
      _busy = false;
      if (_cards.every((c) => c.matched)) {
        Future.delayed(const Duration(milliseconds: 400), widget.onComplete);
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      setState(() {
        first.revealed = false;
        card.revealed = false;
      });
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final columns = _cards.length <= 6 ? 3 : 4;
    return Center(
      child: GridView.count(
        crossAxisCount: columns,
        shrinkWrap: true,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: List.generate(_cards.length, (i) {
          final card = _cards[i];
          final faceUp = card.revealed || card.matched;
          return GestureDetector(
            onTap: () => _flip(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: card.matched
                    ? AppColors.dropTargetSuccess
                    : faceUp
                        ? Colors.white
                        : AppColors.primary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: card.matched
                      ? AppColors.success
                      : AppColors.primaryDark.withValues(alpha: 0.5),
                  width: 2.5,
                ),
              ),
              child: Center(
                child: faceUp
                    ? ItemGraphic(token: card.content, size: 34)
                    : const Text(
                        '⭐',
                        style: TextStyle(fontSize: 34, color: Colors.white),
                      ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
