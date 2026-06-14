enum EmotionLevel {
  verySad,
  sad,
  neutral,
  happy,
  veryHappy;

  int get value => index;

  static EmotionLevel fromValue(int v) => EmotionLevel.values[v.clamp(0, 4)];
}

class EmotionEntry {
  final int? id;
  final String childUuid;
  final EmotionLevel emotion;
  final String checkInType; // 'pre' or 'post'
  final DateTime recordedAt;
  final bool isSynced;

  const EmotionEntry({
    this.id,
    required this.childUuid,
    required this.emotion,
    required this.checkInType,
    required this.recordedAt,
    required this.isSynced,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'child_uuid': childUuid,
        'emotion': emotion.value,
        'check_in_type': checkInType,
        'recorded_at': recordedAt.toIso8601String(),
        'is_synced': isSynced ? 1 : 0,
      };

  factory EmotionEntry.fromMap(Map<String, dynamic> m) => EmotionEntry(
        id: m['id'] as int?,
        childUuid: m['child_uuid'] as String,
        emotion: EmotionLevel.fromValue(m['emotion'] as int),
        checkInType: m['check_in_type'] as String,
        recordedAt: DateTime.parse(m['recorded_at'] as String),
        isSynced: (m['is_synced'] as int) == 1,
      );
}
