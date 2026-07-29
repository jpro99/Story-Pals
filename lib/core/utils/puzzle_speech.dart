/// Builds kid-friendly spoken instructions that name the letters, words,
/// counts, and steps — not just "match the picture".
String spokenInstructionFor(Map<String, dynamic> puzzle) {
  final base =
      (puzzle['instruction'] as Map<String, dynamic>?)?['en'] as String? ??
          'Let\'s play!';
  final type = puzzle['type'] as String? ?? '';

  switch (type) {
    case 'match_shape':
      return _matchShape(base, puzzle);
    case 'sequence':
      return _sequence(base, puzzle);
    case 'count_match':
      return _count(base, puzzle);
      case 'memory_pairs':
        return '$base Flip cards and find matching pairs.';
      case 'which_more':
        return '$base Tap the side that has more.';
      case 'odd_one_out':
      return '$base Tap the one that does not belong.';
    case 'memory':
      return '$base Tap two matching cards.';
    case 'pattern':
      return '$base Look at the pattern and pick what comes next.';
    case 'compare':
      return '$base Which side has more?';
    case 'maze':
      return '$base Help them reach the treat. Tap the path.';
    default:
      return base;
  }
}

String _matchShape(String base, Map<String, dynamic> puzzle) {
  final items =
      ((puzzle['items'] as List?) ?? const []).cast<Map<String, dynamic>>();
  final targets =
      ((puzzle['targets'] as List?) ?? const []).cast<Map<String, dynamic>>();
  if (items.isEmpty || targets.isEmpty) return base;

  final targetById = {
    for (final t in targets) t['id'] as String: t,
  };

  final parts = <String>[base];
  for (final item in items) {
    final targetId = item['target_id'] as String?;
    final target = targetId == null ? null : targetById[targetId];
    final letter = (target?['display'] as String?) ??
        (target?['label'] is Map
            ? (target!['label'] as Map)['en'] as String?
            : null);
    final word = _wordFromItem(item);
    if (letter != null && letter.isNotEmpty && word != null) {
      // Spell letter clearly for TTS: "the letter B"
      final spokenLetter = letter.length == 1
          ? 'the letter ${letter.toUpperCase()}'
          : letter;
      parts.add('$word starts with $spokenLetter. Match $word to $spokenLetter.');
    } else if (letter != null && letter.isNotEmpty) {
      parts.add('Match the picture to $letter.');
    } else if (word != null) {
      parts.add('Find the match for $word.');
    }
  }
  return parts.join(' ');
}

String? _wordFromItem(Map<String, dynamic> item) {
  final label = item['label'];
  if (label is Map && label['en'] is String) return label['en'] as String;
  final id = item['id'] as String?;
  if (id == null || id.isEmpty) return null;
  return id.replaceAll('_', ' ');
}

String _sequence(String base, Map<String, dynamic> puzzle) {
  final items =
      ((puzzle['items'] as List?) ?? const []).cast<Map<String, dynamic>>();
  if (items.isEmpty) {
    return '$base Tap a step, then tap a numbered box.';
  }
  final names = <String>[];
  for (final it in items) {
    final label = it['label'];
    if (label is Map && label['en'] is String) {
      names.add(label['en'] as String);
    } else {
      names.add((it['id'] as String? ?? 'step').replaceAll('_', ' '));
    }
  }
  final order = names.join(', then ');
  return '$base Put them in order: $order. '
      'First tap ${names.first}, then tap box 1. '
      'Then tap the next step, then the next box.';
}

String _count(String base, Map<String, dynamic> puzzle) {
  final target = puzzle['target_count'];
  if (target is int) {
    return '$base Put $target into the basket, then tap Check.';
  }
  return '$base Count into the basket, then tap Check.';
}
