class ChildProfile {
  final int? id;
  final String uuid;
  final String name;
  final int ageYears;
  final int avatarIndex;
  final String? parentUid;

  // Learning weights (0.0–1.0), parent-configured
  final double codingWeight;
  final double mathWeight;
  final double englishWeight;
  final double additionalLanguageWeight;
  final double geographyWeight;

  final int sessionLimitMinutes;

  // JSON string: { chapterId: highestCompletedPuzzleIndex }
  final String progressJson;

  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  const ChildProfile({
    this.id,
    required this.uuid,
    required this.name,
    required this.ageYears,
    required this.avatarIndex,
    this.parentUid,
    required this.codingWeight,
    required this.mathWeight,
    required this.englishWeight,
    required this.additionalLanguageWeight,
    required this.geographyWeight,
    required this.sessionLimitMinutes,
    required this.progressJson,
    required this.createdAt,
    required this.updatedAt,
    required this.isSynced,
  });

  ChildProfile copyWith({
    int? id,
    String? uuid,
    String? name,
    int? ageYears,
    int? avatarIndex,
    String? parentUid,
    double? codingWeight,
    double? mathWeight,
    double? englishWeight,
    double? additionalLanguageWeight,
    double? geographyWeight,
    int? sessionLimitMinutes,
    String? progressJson,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return ChildProfile(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      ageYears: ageYears ?? this.ageYears,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      parentUid: parentUid ?? this.parentUid,
      codingWeight: codingWeight ?? this.codingWeight,
      mathWeight: mathWeight ?? this.mathWeight,
      englishWeight: englishWeight ?? this.englishWeight,
      additionalLanguageWeight:
          additionalLanguageWeight ?? this.additionalLanguageWeight,
      geographyWeight: geographyWeight ?? this.geographyWeight,
      sessionLimitMinutes: sessionLimitMinutes ?? this.sessionLimitMinutes,
      progressJson: progressJson ?? this.progressJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'uuid': uuid,
        'name': name,
        'age_years': ageYears,
        'avatar_index': avatarIndex,
        'parent_uid': parentUid,
        'coding_weight': codingWeight,
        'math_weight': mathWeight,
        'english_weight': englishWeight,
        'language_weight': additionalLanguageWeight,
        'geography_weight': geographyWeight,
        'session_limit_minutes': sessionLimitMinutes,
        'progress_json': progressJson,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'is_synced': isSynced ? 1 : 0,
      };

  factory ChildProfile.fromMap(Map<String, dynamic> m) => ChildProfile(
        id: m['id'] as int?,
        uuid: m['uuid'] as String,
        name: m['name'] as String,
        ageYears: m['age_years'] as int,
        avatarIndex: m['avatar_index'] as int,
        parentUid: m['parent_uid'] as String?,
        codingWeight: (m['coding_weight'] as num).toDouble(),
        mathWeight: (m['math_weight'] as num).toDouble(),
        englishWeight: (m['english_weight'] as num).toDouble(),
        additionalLanguageWeight: (m['language_weight'] as num).toDouble(),
        geographyWeight: (m['geography_weight'] as num).toDouble(),
        sessionLimitMinutes: m['session_limit_minutes'] as int,
        progressJson: m['progress_json'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
        isSynced: (m['is_synced'] as int) == 1,
      );
}
