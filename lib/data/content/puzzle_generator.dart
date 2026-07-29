import 'dart:math' as math;

/// Procedurally generates endless puzzles for the Practice Adventure.
///
/// Every skill has 10 difficulty levels tuned for ages 2–7:
///  * coding  — step sequences & patterns: 2 steps → 5 steps with decoys,
///              AB patterns → AABC patterns (real pre-programming logic).
///  * math    — counting 2→10, then visual addition ("2 + 3") at level 6+.
///  * english — letter matching → first-letter word matching (B → 🍌).
///
/// Output uses the exact same JSON map shape as chapter files, so the
/// shared puzzle widgets render generated puzzles identically.
class PuzzleGenerator {
  PuzzleGenerator({
    math.Random? rnd,
    this.heroName,
    this.heroEmoji,
    this.interests = const [],
  }) : _rnd = rnd ?? math.Random();
  final math.Random _rnd;

  /// When set (e.g. "Rex"), sequence puzzles star this character instead of
  /// a random one — used by the themed endless modes.
  final String? heroName;

  /// Emoji used for the hero in maze puzzles ('🦕', '🪆', …).
  final String? heroEmoji;

  /// Child interests (e.g. ['dinosaurs', 'soccer']) — puzzles re-theme
  /// their items around these so a dino kid counts T-Rexes and a soccer
  /// kid counts soccer balls.
  final List<String> interests;

  static const skills = ['coding', 'math', 'english', 'spanish', 'tagalog'];

  /// Generate one puzzle for [skill] at [level] (1–10).
  Map<String, dynamic> generate(String skill, int level) {
    final l = level.clamp(1, 10);
    switch (skill) {
      case 'math':
        return _math(l);
      case 'english':
        return _english(l);
      case 'spanish':
        return _spanish(l);
      case 'tagalog':
        return _tagalog(l);
      default:
        return _coding(l);
    }
  }

  // ── Interest theming ─────────────────────────────────────────────

  static const _themePools = <String, List<({String emoji, String name})>>{
    'dinosaurs': [
      (emoji: '🦕', name: 'long-neck dinosaurs'),
      (emoji: '🦖', name: 'T-Rexes'),
      (emoji: '🥚', name: 'dinosaur eggs'),
      (emoji: '🦴', name: 'dinosaur bones'),
      (emoji: '🌋', name: 'volcanoes'),
    ],
    'soccer': [
      (emoji: '⚽', name: 'soccer balls'),
      (emoji: '🥅', name: 'goals'),
      (emoji: '👟', name: 'soccer shoes'),
      (emoji: '🏆', name: 'trophies'),
    ],
    'gymnastics': [
      (emoji: '🤸', name: 'cartwheels'),
      (emoji: '🎀', name: 'ribbons'),
      (emoji: '🏅', name: 'medals'),
      (emoji: '⭐', name: 'gold stars'),
    ],
    'space': [
      (emoji: '🚀', name: 'rockets'),
      (emoji: '🪐', name: 'planets'),
      (emoji: '⭐', name: 'stars'),
      (emoji: '🌙', name: 'moons'),
      (emoji: '👽', name: 'friendly aliens'),
    ],
    'vehicles': [
      (emoji: '🚗', name: 'cars'),
      (emoji: '🚌', name: 'buses'),
      (emoji: '🚁', name: 'helicopters'),
      (emoji: '🚲', name: 'bikes'),
      (emoji: '🚜', name: 'tractors'),
    ],
    'animals': [
      (emoji: '🐶', name: 'puppies'),
      (emoji: '🐱', name: 'kittens'),
      (emoji: '🐰', name: 'bunnies'),
      (emoji: '🐢', name: 'turtles'),
      (emoji: '🦁', name: 'lions'),
    ],
  };

  /// Vector-drawn species with their real names — for the dino experts.
  /// The '@dino:' tokens render as hand-drawn art via ItemGraphic.
  static const _dinoArtPool = [
    (emoji: '@dino:trex', name: 'Tyrannosaurus Rexes'),
    (emoji: '@dino:stegosaurus', name: 'Stegosauruses'),
    (emoji: '@dino:triceratops', name: 'Triceratops'),
    (emoji: '@dino:brachiosaurus', name: 'Brachiosauruses'),
    (emoji: '@dino:pterodactyl', name: 'Pterodactyls'),
    (emoji: '@dino:ankylosaurus', name: 'Ankylosauruses'),
  ];

  /// Counting pool: ~70 % themed items when interests are set.
  /// [allowArt] is false for puzzles that repeat an emoji inside one string
  /// (art tokens can't be string-multiplied).
  ({String emoji, String name}) _pickCountItem({bool allowArt = true}) {
    final themed = [
      for (final i in interests)
        ..._themePools[i] ?? <({String emoji, String name})>[],
      // Dino kids get the drawn species heavily weighted in.
      if (interests.contains('dinosaurs') && allowArt) ..._dinoArtPool,
      if (interests.contains('dinosaurs') && allowArt) ..._dinoArtPool,
    ];
    if (themed.isNotEmpty && _rnd.nextInt(10) < 7) {
      return themed[_rnd.nextInt(themed.length)];
    }
    return _pick(_countPool);
  }

  T _pick<T>(List<T> list) => list[_rnd.nextInt(list.length)];

  List<T> _sample<T>(List<T> list, int n) {
    final copy = List<T>.from(list)..shuffle(_rnd);
    return copy.take(n).toList();
  }

  // ── Coding ───────────────────────────────────────────────────────

  static const _actionPool = [
    (id: 'walk', emoji: '🦶', label: 'Walk', color: '#4CAF50'),
    (id: 'jump', emoji: '⬆️', label: 'Jump', color: '#5B8FFF'),
    (id: 'grab', emoji: '🤏', label: 'Grab', color: '#FF8C42'),
    (id: 'look', emoji: '👀', label: 'Look', color: '#7C4DFF'),
    (id: 'run', emoji: '🏃', label: 'Run', color: '#E91E8C'),
    (id: 'spin', emoji: '🌀', label: 'Spin', color: '#0288D1'),
    (id: 'clap', emoji: '👏', label: 'Clap', color: '#FF8F00'),
  ];

  static const _patternPool = [
    (id: 'sun', emoji: '☀️', color: '#FF8F00'),
    (id: 'moon', emoji: '🌙', color: '#5B8FFF'),
    (id: 'star', emoji: '⭐', color: '#FFD54F'),
    (id: 'heart', emoji: '❤️', color: '#E91E8C'),
    (id: 'tree', emoji: '🌳', color: '#4CAF50'),
    (id: 'fish', emoji: '🐟', color: '#0288D1'),
  ];

  Map<String, dynamic> _coding(int level) {
    // Rotate mechanics; the maze (real programming!) joins at level 3.
    final options = [
      _codingSequence,
      _codingPattern,
      if (level >= 3) _roboMaze,
      if (level >= 3) _roboMaze, // twice as likely once unlocked — it's the star
    ];
    return _pick(options)(level);
  }

  Map<String, dynamic> _roboMaze(int level) {
    // Grid grows with level: 3x3 → 4x4 → 5x5. Rocks appear at level 5+.
    final size = level <= 4 ? 3 : level <= 7 ? 4 : 5;
    final start = [0, size - 1]; // bottom-left
    // Goal somewhere in the top row or right column, away from start.
    final goal = _rnd.nextBool()
        ? [1 + _rnd.nextInt(size - 1), 0]
        : [size - 1, _rnd.nextInt(size - 1)];

    // A guaranteed-solvable path: straight up, then straight right (or the
    // reverse). Obstacles are only placed OFF that path.
    final safe = <String>{};
    for (var y = start[1]; y >= goal[1]; y--) {
      safe.add('${start[0]},$y');
    }
    for (var x = start[0]; x <= goal[0]; x++) {
      safe.add('$x,${goal[1]}');
    }

    final obstacleCount = level <= 4 ? 0 : level <= 7 ? 1 : 2;
    final obstacles = <List<int>>[];
    var attempts = 0;
    while (obstacles.length < obstacleCount && attempts < 30) {
      attempts++;
      final ox = _rnd.nextInt(size);
      final oy = _rnd.nextInt(size);
      final key = '$ox,$oy';
      if (safe.contains(key)) continue;
      if (obstacles.any((o) => o[0] == ox && o[1] == oy)) continue;
      obstacles.add([ox, oy]);
    }

    final treats = ['🍓', '🍪', '🎁', '⭐', '🧁'];
    final name = heroName ?? 'Robo';

    return {
      'type': 'robo_maze',
      'subject_tags': ['coding_sequence', 'coding_logic'],
      'instruction': {
        'en': 'Program $name to reach the treat! '
            'Tap arrows, then press GO!',
      },
      'grid_w': size,
      'grid_h': size,
      'start': start,
      'goal': goal,
      'obstacles': obstacles,
      'hero_emoji': heroEmoji ?? '🦕',
      'goal_emoji': _pick(treats),
    };
  }

  Map<String, dynamic> _codingSequence(int level) {
    // Level 1–2: 2 steps. 3–4: 3 steps. 5–6: 4 steps. 7+: 4–5 steps + decoys.
    final steps = level <= 2 ? 2 : level <= 4 ? 3 : level <= 6 ? 4 : 4 + _rnd.nextInt(2);
    final decoyCount = level >= 7 ? (level >= 9 ? 2 : 1) : 0;

    final chosen = _sample(_actionPool, steps + decoyCount);
    final ordered = chosen.take(steps).toList();
    final decoys = chosen.skip(steps).toList();

    const storyNames = ['Robo', 'Rex', 'Luna', 'Zippy'];
    final name = heroName ?? _pick(storyNames);

    final stepNames = ordered.map((a) => a.label).join(', then ');
    return {
      'type': 'sequence',
      'subject_tags': ['coding_sequence'],
      'instruction': {
        'en': 'Help $name! Put the steps in order: $stepNames. '
            'Tap a step, then tap box 1, then the next step, then box 2.',
      },
      'items': [
        for (final a in ordered)
          {
            'id': a.id,
            'emoji': a.emoji,
            'color': a.color,
            'label': {'en': a.label},
          }
      ],
      if (decoys.isNotEmpty)
        'decoys': [
          for (final a in decoys)
            {
              'id': a.id,
              'emoji': a.emoji,
              'color': a.color,
              'label': {'en': a.label},
            }
        ],
    };
  }

  Map<String, dynamic> _codingPattern(int level) {
    // Level 1–3: AB. 4–5: ABB. 6–7: ABC. 8+: AABB / AABC.
    final List<int> unit;
    if (level <= 3) {
      unit = [0, 1];
    } else if (level <= 5) {
      unit = [0, 1, 1];
    } else if (level <= 7) {
      unit = [0, 1, 2];
    } else {
      unit = _rnd.nextBool() ? [0, 0, 1, 1] : [0, 0, 1, 2];
    }
    final symbolCount = unit.reduce(math.max) + 1;
    final symbols = _sample(_patternPool, math.max(symbolCount, 3));

    // Show the unit twice so the pattern is visible, then hide the next entry.
    const repeats = 2;
    final visible = <String>[];
    for (var r = 0; r < repeats; r++) {
      for (final u in unit) {
        visible.add(symbols[u].id);
      }
    }
    final answerIndex = unit[0];
    visible.add('?');

    // Choices: the correct next symbol + the other symbols as distractors.
    final choices = symbols
        .map((s) => {
              'id': s.id,
              'emoji': s.emoji,
              'color': s.color,
              'is_correct': s.id == symbols[answerIndex].id,
            })
        .toList()
      ..shuffle(_rnd);

    return {
      'type': 'pattern',
      'subject_tags': ['coding_pattern'],
      'instruction': {'en': 'Look at the pattern! What comes next?'},
      'pattern_sequence': visible,
      'choices': choices,
    };
  }

  // ── Math ─────────────────────────────────────────────────────────

  static const _countPool = [
    (emoji: '🍓', name: 'strawberries'),
    (emoji: '🍌', name: 'bananas'),
    (emoji: '⭐', name: 'stars'),
    (emoji: '🐠', name: 'fish'),
    (emoji: '🌸', name: 'flowers'),
    (emoji: '🍪', name: 'cookies'),
    (emoji: '🎈', name: 'balloons'),
    (emoji: '🦋', name: 'butterflies'),
  ];

  Map<String, dynamic> _math(int level) {
    // Rotate: counting / which-has-more / number memory.
    final roll = _rnd.nextInt(level >= 4 ? 3 : 2);
    if (roll == 1) return _whichMore(level);
    if (roll == 2) return _numberMemory(level);

    final item = _pickCountItem();

    if (level >= 6) {
      // Visual addition: a + b, sums scale 4 → 10.
      final maxSum = math.min(4 + level - 5 + 2, 10);
      final sum = 4 + _rnd.nextInt(math.max(maxSum - 3, 1));
      final a = 1 + _rnd.nextInt(sum - 1);
      final b = sum - a;
      return {
        'type': 'count_match',
        'subject_tags': ['math_counting', 'math_addition'],
        'instruction': {
          'en': '$a plus $b! Put that many ${item.name} in the basket!',
        },
        'expression': '$a + $b = ?',
        'target_count': sum,
        'total_available': math.min(sum + 2 + _rnd.nextInt(2), 12),
        'item_emoji': item.emoji,
      };
    }

    // Pure counting: 2 → 8.
    final target = math.min(1 + level + _rnd.nextInt(2), 8);
    return {
      'type': 'count_match',
      'subject_tags': ['math_counting'],
      'instruction': {
        'en': 'Count ${_numWord(target)} ${item.name} into the basket!',
      },
      'target_count': target,
      'total_available': math.min(target + 2 + _rnd.nextInt(3), 12),
      'item_emoji': item.emoji,
    };
  }

  Map<String, dynamic> _whichMore(int level) {
    final item = _pickCountItem();
    // Difference shrinks as level rises: easy 1 vs 4, hard 6 vs 7.
    final base = 1 + _rnd.nextInt(math.min(2 + level, 7));
    final diff = level <= 3 ? 2 + _rnd.nextInt(3) : 1 + _rnd.nextInt(2);
    final a = base;
    final b = math.min(base + diff, 9);
    final leftBigger = _rnd.nextBool();
    final wantMore = level < 7 || _rnd.nextBool();

    return {
      'type': 'which_more',
      'subject_tags': ['math_counting', 'math_compare'],
      'instruction': {
        'en': wantMore
            ? 'Tap the side with MORE ${item.name}!'
            : 'Tap the side with FEWER ${item.name}!',
      },
      'left_count': leftBigger ? b : a,
      'right_count': leftBigger ? a : b,
      'item_emoji': item.emoji,
      'mode': wantMore ? 'more' : 'less',
    };
  }

  Map<String, dynamic> _numberMemory(int level) {
    // Match the numeral to that many objects: '3' ↔ '🍓🍓🍓'.
    final pairCount = level <= 5 ? 2 : 3;
    final item = _pickCountItem(allowArt: false);
    final numbers = _sample([1, 2, 3, 4, 5], pairCount);
    return {
      'type': 'memory_pairs',
      'subject_tags': ['math_counting'],
      'instruction': {
        'en': 'Flip the cards! Match each number to that many things!',
      },
      'pairs': [
        for (final n in numbers) {'a': '$n', 'b': item.emoji * n},
      ],
    };
  }

  // ── English ──────────────────────────────────────────────────────

  static const _letterWords = [
    (letter: 'A', emoji: '🍎', word: 'Apple'),
    (letter: 'B', emoji: '🍌', word: 'Banana'),
    (letter: 'C', emoji: '🐱', word: 'Cat'),
    (letter: 'D', emoji: '🐶', word: 'Dog'),
    (letter: 'E', emoji: '🥚', word: 'Egg'),
    (letter: 'F', emoji: '🐟', word: 'Fish'),
    (letter: 'G', emoji: '🍇', word: 'Grapes'),
    (letter: 'H', emoji: '🎩', word: 'Hat'),
    (letter: 'I', emoji: '🍦', word: 'Ice cream'),
    (letter: 'J', emoji: '🧃', word: 'Juice'),
    (letter: 'K', emoji: '🪁', word: 'Kite'),
    (letter: 'L', emoji: '🦁', word: 'Lion'),
    (letter: 'M', emoji: '🌙', word: 'Moon'),
    (letter: 'O', emoji: '🍊', word: 'Orange'),
    (letter: 'P', emoji: '🐷', word: 'Pig'),
    (letter: 'R', emoji: '🌈', word: 'Rainbow'),
    (letter: 'S', emoji: '☀️', word: 'Sun'),
    (letter: 'T', emoji: '🌳', word: 'Tree'),
    (letter: 'U', emoji: '☂️', word: 'Umbrella'),
    (letter: 'W', emoji: '🐳', word: 'Whale'),
    (letter: 'Z', emoji: '🦓', word: 'Zebra'),
  ];

  static const _itemColors = ['#E91E8C', '#4CAF50', '#5B8FFF', '#FF8C42'];

  static const _oddCategories = [
    (name: 'animals', items: ['🐶', '🐱', '🐰', '🦁', '🐷', '🐻']),
    (name: 'foods', items: ['🍎', '🍌', '🍪', '🍇', '🥕', '🧁']),
    (name: 'things that go', items: ['🚗', '🚌', '🚀', '🚲', '🚁']),
    (name: 'clothes', items: ['👗', '🎩', '🧦', '👟', '🧢']),
  ];

  Map<String, dynamic> _english(int level) {
    // Rotate: letter matching / odd-one-out / letter memory (level 3+).
    final roll = _rnd.nextInt(level >= 3 ? 3 : 2);
    if (roll == 1) return _oddOneOut(level);
    if (roll == 2) return _letterMemory(level);

    // Level 1–3: 2 letters, ghost hints ON (letter shown, picture obvious).
    // Level 4–6: 3 letters. Level 7+: 3–4 letters, hints OFF (child must
    // know the first letter sound of the word).
    final count = level <= 3 ? 2 : level <= 6 ? 3 : 3 + _rnd.nextInt(2);
    final showHints = level <= 6;
    final chosen = _sample(_letterWords, count);

    return {
      'type': 'match_shape',
      'subject_tags': ['language_english'],
      'show_hints': showHints,
      'instruction': {
        'en': level <= 6
            ? 'Match each picture to its letter!'
            : 'Which letter does each word start with? Match them!',
      },
      'items': [
        for (var i = 0; i < chosen.length; i++)
          {
            'id': chosen[i].word.toLowerCase().replaceAll(' ', '_'),
            'emoji': chosen[i].emoji,
            'color': _itemColors[i % _itemColors.length],
            'target_id': 'letter_${chosen[i].letter}',
          }
      ],
      'targets': [
        for (final c in chosen)
          {
            'id': 'letter_${c.letter}',
            'display': c.letter,
            'label': {'en': c.letter},
          }
      ],
    };
  }

  Map<String, dynamic> _oddOneOut(int level) {
    // Interests join the category pool (a dino kid gets "which is not a
    // dinosaur?" rounds).
    final allCats = [
      ..._oddCategories,
      for (final i in interests)
        if ((_themePools[i] ?? []).length >= 4)
          (
            name: i,
            items: [for (final e in _themePools[i]!) e.emoji],
          ),
    ];
    final cats = _sample(allCats, 2);
    final mainCat = cats[0];
    final oddCat = cats[1];
    final sameCount = level <= 4 ? 3 : 4;
    final same = _sample(mainCat.items, sameCount);
    final odd = _pick(oddCat.items);

    final items = [
      for (var i = 0; i < same.length; i++)
        {'id': 'same_$i', 'emoji': same[i]},
      {'id': 'odd', 'emoji': odd},
    ]..shuffle(_rnd);

    return {
      'type': 'odd_one_out',
      'subject_tags': ['language_english', 'logic_classification'],
      'instruction': {
        'en': level <= 5
            ? 'One of these is different! Tap the odd one out!'
            : 'These are almost all ${mainCat.name}. Tap the one that is NOT!',
      },
      'items': items,
      'odd_id': 'odd',
    };
  }

  Map<String, dynamic> _letterMemory(int level) {
    // Match the letter to a picture that starts with it: 'A' ↔ '🍎'.
    final pairCount = level <= 5 ? 2 : 3;
    final chosen = _sample(_letterWords, pairCount);
    return {
      'type': 'memory_pairs',
      'subject_tags': ['language_english'],
      'instruction': {
        'en': 'Flip the cards! Match each letter to its picture!',
      },
      'pairs': [
        for (final c in chosen) {'a': c.letter, 'b': c.emoji},
      ],
    };
  }

  // ── Spanish ──────────────────────────────────────────────────────
  // Bilingual early exposure: Spanish words woven into familiar puzzle
  // mechanics, always paired with pictures and English so nothing blocks.

  static const _spanishWords = [
    (es: 'perro', en: 'dog', emoji: '🐶'),
    (es: 'gato', en: 'cat', emoji: '🐱'),
    (es: 'manzana', en: 'apple', emoji: '🍎'),
    (es: 'sol', en: 'sun', emoji: '☀️'),
    (es: 'luna', en: 'moon', emoji: '🌙'),
    (es: 'flor', en: 'flower', emoji: '🌸'),
    (es: 'pez', en: 'fish', emoji: '🐟'),
    (es: 'casa', en: 'house', emoji: '🏠'),
    (es: 'árbol', en: 'tree', emoji: '🌳'),
    (es: 'estrella', en: 'star', emoji: '⭐'),
    (es: 'pelota', en: 'ball', emoji: '⚽'),
    (es: 'fresa', en: 'strawberry', emoji: '🍓'),
  ];

  static const _spanishNumbers = [
    '',
    'uno',
    'dos',
    'tres',
    'cuatro',
    'cinco',
    'seis',
    'siete',
    'ocho',
  ];

  Map<String, dynamic> _spanish(int level) {
    final roll = _rnd.nextInt(level >= 3 ? 3 : 2);

    if (roll == 0) {
      // Spanish counting: number word taught in context.
      final item = _pickCountItem();
      final target = math.min(1 + level ~/ 2 + _rnd.nextInt(2), 8);
      return {
        'type': 'count_match',
        'subject_tags': ['language_spanish', 'math_counting'],
        'instruction': {
          'en': '${_spanishNumbers[target].toUpperCase()}! That is Spanish '
              'for ${_numWord(target)}! Count ${_spanishNumbers[target]} '
              '${item.name} into the basket!',
        },
        'target_count': target,
        'total_available': math.min(target + 2 + _rnd.nextInt(3), 12),
        'item_emoji': item.emoji,
      };
    }

    if (roll == 1) {
      // Word ↔ picture memory: perro ↔ 🐶.
      final pairCount = level <= 5 ? 2 : 3;
      final chosen = _sample(_spanishWords, pairCount);
      final spoken =
          chosen.map((w) => '${w.es} means ${w.en}').join('. ');
      return {
        'type': 'memory_pairs',
        'subject_tags': ['language_spanish'],
        'instruction': {
          'en': 'Flip the cards! Match the Spanish word to its picture! '
              '$spoken.',
        },
        'pairs': [
          for (final w in chosen) {'a': w.es, 'b': w.emoji},
        ],
      };
    }

    // Spanish which-more: más = more!
    final item = _pickCountItem();
    final a = 1 + _rnd.nextInt(4);
    final b = math.min(a + 1 + _rnd.nextInt(3), 9);
    final leftBigger = _rnd.nextBool();
    return {
      'type': 'which_more',
      'subject_tags': ['language_spanish', 'math_compare'],
      'instruction': {
        'en': 'MÁS means MORE! Tap the side with más ${item.name}!',
      },
      'left_count': leftBigger ? b : a,
      'right_count': leftBigger ? a : b,
      'item_emoji': item.emoji,
      'mode': 'more',
    };
  }

  // ── Tagalog ──────────────────────────────────────────────────────

  static const _tagalogWords = [
    (tl: 'aso', en: 'dog', emoji: '🐶'),
    (tl: 'pusa', en: 'cat', emoji: '🐱'),
    (tl: 'araw', en: 'sun', emoji: '☀️'),
    (tl: 'buwan', en: 'moon', emoji: '🌙'),
    (tl: 'bulaklak', en: 'flower', emoji: '🌸'),
    (tl: 'isda', en: 'fish', emoji: '🐟'),
    (tl: 'bahay', en: 'house', emoji: '🏠'),
    (tl: 'puno', en: 'tree', emoji: '🌳'),
    (tl: 'bituin', en: 'star', emoji: '⭐'),
    (tl: 'mansanas', en: 'apple', emoji: '🍎'),
    (tl: 'bola', en: 'ball', emoji: '⚽'),
    (tl: 'saging', en: 'banana', emoji: '🍌'),
  ];

  static const _tagalogNumbers = [
    '',
    'isa',
    'dalawa',
    'tatlo',
    'apat',
    'lima',
    'anim',
    'pito',
    'walo',
  ];

  Map<String, dynamic> _tagalog(int level) {
    final roll = _rnd.nextInt(level >= 3 ? 3 : 2);

    if (roll == 0) {
      final item = _pickCountItem();
      final target = math.min(1 + level ~/ 2 + _rnd.nextInt(2), 8);
      return {
        'type': 'count_match',
        'subject_tags': ['language_tagalog', 'math_counting'],
        'instruction': {
          'en': '${_tagalogNumbers[target].toUpperCase()}! That is Tagalog '
              'for ${_numWord(target)}! Count ${_tagalogNumbers[target]} '
              '${item.name} into the basket!',
        },
        'target_count': target,
        'total_available': math.min(target + 2 + _rnd.nextInt(3), 12),
        'item_emoji': item.emoji,
      };
    }

    if (roll == 1) {
      final pairCount = level <= 5 ? 2 : 3;
      final chosen = _sample(_tagalogWords, pairCount);
      final spoken = chosen.map((w) => '${w.tl} means ${w.en}').join('. ');
      return {
        'type': 'memory_pairs',
        'subject_tags': ['language_tagalog'],
        'instruction': {
          'en': 'Flip the cards! Match the Tagalog word to its picture! '
              '$spoken.',
        },
        'pairs': [
          for (final w in chosen) {'a': w.tl, 'b': w.emoji},
        ],
      };
    }

    final item = _pickCountItem();
    final a = 1 + _rnd.nextInt(4);
    final b = math.min(a + 1 + _rnd.nextInt(3), 9);
    final leftBigger = _rnd.nextBool();
    return {
      'type': 'which_more',
      'subject_tags': ['language_tagalog', 'math_compare'],
      'instruction': {
        'en': 'MAS MARAMI means MORE! Tap the side with mas marami '
            '${item.name}!',
      },
      'left_count': leftBigger ? b : a,
      'right_count': leftBigger ? a : b,
      'item_emoji': item.emoji,
      'mode': 'more',
    };
  }

  // ── Helpers ──────────────────────────────────────────────────────

  static String _numWord(int n) => switch (n) {
        1 => 'one',
        2 => 'two',
        3 => 'three',
        4 => 'four',
        5 => 'five',
        6 => 'six',
        7 => 'seven',
        8 => 'eight',
        9 => 'nine',
        10 => 'ten',
        _ => '$n',
      };
}
