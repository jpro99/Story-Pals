import 'package:shared_preferences/shared_preferences.dart';

/// Persists each child's mastery level (1–10) per skill, on-device only.
///
/// Levels only ever go up — young kids should never feel demoted. A child
/// levels up after 3 first-try successes in a row on that skill.
class SkillLevelStore {
  static String _levelKey(String childUuid, String skill) =>
      'skill_level_${childUuid}_$skill';
  static String _solvedKey(String childUuid, String skill) =>
      'skill_solved_${childUuid}_$skill';

  static Future<int> getLevel(String childUuid, String skill) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_levelKey(childUuid, skill)) ?? 1;
  }

  static Future<void> setLevel(
      String childUuid, String skill, int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_levelKey(childUuid, skill), level.clamp(1, 10));
  }

  /// Lifetime solved-puzzle count per skill (for the parent dashboard).
  static Future<int> getSolvedCount(String childUuid, String skill) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_solvedKey(childUuid, skill)) ?? 0;
  }

  static Future<void> incrementSolved(String childUuid, String skill) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_solvedKey(childUuid, skill)) ?? 0;
    await prefs.setInt(_solvedKey(childUuid, skill), current + 1);
  }
}

/// Per-child interests (dinosaurs, soccer, …) chosen by the parent.
/// Puzzles re-theme themselves around these.
class InterestStore {
  static String _key(String childUuid) => 'interests_$childUuid';

  static const available = [
    (id: 'dinosaurs', label: '🦕 Dinosaurs'),
    (id: 'soccer', label: '⚽ Soccer'),
    (id: 'gymnastics', label: '🤸 Gymnastics'),
    (id: 'space', label: '🚀 Space'),
    (id: 'vehicles', label: '🚗 Vehicles'),
    (id: 'animals', label: '🐶 Animals'),
  ];

  static Future<List<String>> getInterests(String childUuid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key(childUuid)) ?? [];
  }

  static Future<void> setInterests(
      String childUuid, List<String> interests) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key(childUuid), interests);
  }
}
