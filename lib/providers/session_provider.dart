import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/session_record.dart';
import '../data/local/isar_service.dart';
import 'child_profile_provider.dart';

class ActiveSession {
  final String chapterId;
  final String childUuid;
  final DateTime startedAt;
  int puzzlesCompleted;
  final List<String> subjectTags;

  ActiveSession({
    required this.chapterId,
    required this.childUuid,
    required this.startedAt,
    this.puzzlesCompleted = 0,
    List<String>? subjectTags,
  }) : subjectTags = subjectTags ?? [];
}

final activeSessionProvider =
    StateNotifierProvider<ActiveSessionNotifier, ActiveSession?>(
  ActiveSessionNotifier.new,
);

class ActiveSessionNotifier extends StateNotifier<ActiveSession?> {
  ActiveSessionNotifier(this._ref) : super(null);

  final Ref _ref;

  void start(String chapterId, String childUuid) {
    state = ActiveSession(
      chapterId: chapterId,
      childUuid: childUuid,
      startedAt: DateTime.now(),
    );
  }

  void recordPuzzleComplete(int puzzleIndex, List<String> tags) {
    final s = state;
    if (s == null) return;
    s.puzzlesCompleted++;
    s.subjectTags.addAll(tags);
    // Trigger state update by reassigning
    state = s;

    _ref.read(childProfilesProvider.notifier).markPuzzleComplete(
          s.childUuid,
          s.chapterId,
          puzzleIndex,
        );
  }

  Future<void> end(int totalPuzzles) async {
    final s = state;
    if (s == null) return;

    final record = SessionRecord(
      childUuid: s.childUuid,
      chapterId: s.chapterId,
      puzzlesCompleted: s.puzzlesCompleted,
      totalPuzzles: totalPuzzles,
      durationSeconds: DateTime.now().difference(s.startedAt).inSeconds,
      subjectTags: s.subjectTags.toSet().toList(),
      startedAt: s.startedAt,
      endedAt: DateTime.now(),
      isSynced: false,
    );

    await IsarService.saveSession(record);
    state = null;
  }
}
