class SessionRecord {
  final int? id;
  final String childUuid;
  final String chapterId;
  final int puzzlesCompleted;
  final int totalPuzzles;
  final int durationSeconds;
  final List<String> subjectTags;
  final DateTime startedAt;
  final DateTime endedAt;
  final bool isSynced;

  const SessionRecord({
    this.id,
    required this.childUuid,
    required this.chapterId,
    required this.puzzlesCompleted,
    required this.totalPuzzles,
    required this.durationSeconds,
    required this.subjectTags,
    required this.startedAt,
    required this.endedAt,
    required this.isSynced,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'child_uuid': childUuid,
        'chapter_id': chapterId,
        'puzzles_completed': puzzlesCompleted,
        'total_puzzles': totalPuzzles,
        'duration_seconds': durationSeconds,
        'subject_tags': subjectTags.join(','),
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt.toIso8601String(),
        'is_synced': isSynced ? 1 : 0,
      };

  factory SessionRecord.fromMap(Map<String, dynamic> m) => SessionRecord(
        id: m['id'] as int?,
        childUuid: m['child_uuid'] as String,
        chapterId: m['chapter_id'] as String,
        puzzlesCompleted: m['puzzles_completed'] as int,
        totalPuzzles: m['total_puzzles'] as int,
        durationSeconds: m['duration_seconds'] as int,
        subjectTags: (m['subject_tags'] as String)
            .split(',')
            .where((s) => s.isNotEmpty)
            .toList(),
        startedAt: DateTime.parse(m['started_at'] as String),
        endedAt: DateTime.parse(m['ended_at'] as String),
        isSynced: (m['is_synced'] as int) == 1,
      );
}
