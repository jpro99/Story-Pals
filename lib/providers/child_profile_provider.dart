import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/child_profile.dart';
import '../core/constants/app_constants.dart';
import '../data/local/isar_service.dart';

final childProfilesProvider =
    AsyncNotifierProvider<ChildProfilesNotifier, List<ChildProfile>>(
  ChildProfilesNotifier.new,
);

final activeChildProvider = StateProvider<ChildProfile?>((ref) => null);

class ChildProfilesNotifier extends AsyncNotifier<List<ChildProfile>> {
  @override
  Future<List<ChildProfile>> build() => IsarService.getProfiles();

  Future<void> addProfile({
    required String name,
    required int ageYears,
    required int avatarIndex,
  }) async {
    final now = DateTime.now();
    final profile = ChildProfile(
      uuid: const Uuid().v4(),
      name: name,
      ageYears: ageYears,
      avatarIndex: avatarIndex,
      codingWeight: AppConstants.defaultCodingWeight,
      mathWeight: AppConstants.defaultMathWeight,
      englishWeight: AppConstants.defaultEnglishWeight,
      spanishWeight: AppConstants.defaultSpanishWeight,
      tagalogWeight: AppConstants.defaultTagalogWeight,
      geographyWeight: AppConstants.defaultGeographyWeight,
      sessionLimitMinutes: AppConstants.defaultSessionMinutes,
      progressJson: '{}',
      createdAt: now,
      updatedAt: now,
      isSynced: false,
    );
    await IsarService.saveProfile(profile);
    ref.invalidateSelf();
  }

  Future<void> updateWeights(
    String uuid, {
    double? coding,
    double? math,
    double? english,
    double? spanish,
    double? tagalog,
    double? language,
    double? geography,
    int? sessionMinutes,
  }) async {
    final profile = await IsarService.getProfile(uuid);
    if (profile == null) return;
    final updated = profile.copyWith(
      codingWeight: coding,
      mathWeight: math,
      englishWeight: english,
      spanishWeight: spanish ?? language,
      tagalogWeight: tagalog ?? language,
      geographyWeight: geography,
      sessionLimitMinutes: sessionMinutes,
      updatedAt: DateTime.now(),
      isSynced: false,
    );
    await IsarService.saveProfile(updated);
    // Keep the active kid in sync so Practice Adventure picks up new weights.
    final active = ref.read(activeChildProvider);
    if (active?.uuid == uuid) {
      ref.read(activeChildProvider.notifier).state = updated;
    }
    ref.invalidateSelf();
  }

  Future<void> markPuzzleComplete(
    String uuid,
    String chapterId,
    int puzzleIndex,
  ) async {
    final profile = await IsarService.getProfile(uuid);
    if (profile == null) return;
    final progress = Map<String, dynamic>.from(
      jsonDecode(profile.progressJson) as Map,
    );
    final current = progress[chapterId] as int? ?? -1;
    if (puzzleIndex > current) {
      progress[chapterId] = puzzleIndex;
      final updated = profile.copyWith(
        progressJson: jsonEncode(progress),
        updatedAt: DateTime.now(),
        isSynced: false,
      );
      await IsarService.saveProfile(updated);
      ref.invalidateSelf();
    }
  }
}

final chapterProgressProvider =
    Provider.family<int, ({String childUuid, String chapterId})>(
  (ref, args) {
    final profiles = ref.watch(childProfilesProvider).valueOrNull ?? [];
    final profile =
        profiles.where((p) => p.uuid == args.childUuid).firstOrNull;
    if (profile == null) return -1;
    final progress = jsonDecode(profile.progressJson) as Map;
    return progress[args.chapterId] as int? ?? -1;
  },
);

final sharedPrefsProvider = FutureProvider<SharedPreferences>(
  (_) => SharedPreferences.getInstance(),
);

final selectedChildIdProvider = StateProvider<String?>((ref) => null);
