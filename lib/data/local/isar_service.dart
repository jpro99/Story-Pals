import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';

import '../../models/child_profile.dart';
import '../../models/session_record.dart';
import '../../models/emotion_entry.dart';

class IsarService {
  static Database? _db;

  static Future<Database> get _instance async {
    _db ??= await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    // Web ffi stores by simple name in IndexedDB; native uses the platform path.
    final path = kIsWeb
        ? 'story_pals.db'
        : '${await getDatabasesPath()}/story_pals.db';
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE child_profiles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            uuid TEXT UNIQUE NOT NULL,
            name TEXT NOT NULL,
            age_years INTEGER NOT NULL,
            avatar_index INTEGER NOT NULL,
            parent_uid TEXT,
            coding_weight REAL NOT NULL,
            math_weight REAL NOT NULL,
            english_weight REAL NOT NULL,
            language_weight REAL NOT NULL,
            geography_weight REAL NOT NULL,
            session_limit_minutes INTEGER NOT NULL,
            progress_json TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            is_synced INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE session_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            child_uuid TEXT NOT NULL,
            chapter_id TEXT NOT NULL,
            puzzles_completed INTEGER NOT NULL,
            total_puzzles INTEGER NOT NULL,
            duration_seconds INTEGER NOT NULL,
            subject_tags TEXT NOT NULL,
            started_at TEXT NOT NULL,
            ended_at TEXT NOT NULL,
            is_synced INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE emotion_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            child_uuid TEXT NOT NULL,
            emotion INTEGER NOT NULL,
            check_in_type TEXT NOT NULL,
            recorded_at TEXT NOT NULL,
            is_synced INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  // ── Child profiles ──────────────────────────────────────────────

  static Future<List<ChildProfile>> getProfiles() async {
    final db = await _instance;
    final rows = await db.query('child_profiles', orderBy: 'created_at ASC');
    return rows.map(ChildProfile.fromMap).toList();
  }

  static Future<ChildProfile?> getProfile(String uuid) async {
    final db = await _instance;
    final rows = await db.query(
      'child_profiles',
      where: 'uuid = ?',
      whereArgs: [uuid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ChildProfile.fromMap(rows.first);
  }

  static Future<void> saveProfile(ChildProfile profile) async {
    final db = await _instance;
    await db.insert(
      'child_profiles',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> deleteProfile(String uuid) async {
    final db = await _instance;
    await db.delete('child_profiles', where: 'uuid = ?', whereArgs: [uuid]);
  }

  // ── Sessions ────────────────────────────────────────────────────

  static Future<void> saveSession(SessionRecord session) async {
    final db = await _instance;
    await db.insert('session_records', session.toMap());
  }

  static Future<List<SessionRecord>> getSessionsForChild(
    String childUuid, {
    DateTime? since,
  }) async {
    final db = await _instance;
    final where = since != null
        ? 'child_uuid = ? AND started_at >= ?'
        : 'child_uuid = ?';
    final args = since != null
        ? [childUuid, since.toIso8601String()]
        : [childUuid];
    final rows = await db.query(
      'session_records',
      where: where,
      whereArgs: args,
      orderBy: 'started_at DESC',
    );
    return rows.map(SessionRecord.fromMap).toList();
  }

  // ── Emotions ────────────────────────────────────────────────────

  static Future<void> saveEmotion(EmotionEntry entry) async {
    final db = await _instance;
    await db.insert('emotion_entries', entry.toMap());
  }

  static Future<List<EmotionEntry>> getEmotionsForChild(
    String childUuid, {
    DateTime? since,
  }) async {
    final db = await _instance;
    final where = since != null
        ? 'child_uuid = ? AND recorded_at >= ?'
        : 'child_uuid = ?';
    final args = since != null
        ? [childUuid, since.toIso8601String()]
        : [childUuid];
    final rows = await db.query(
      'emotion_entries',
      where: where,
      whereArgs: args,
      orderBy: 'recorded_at DESC',
    );
    return rows.map(EmotionEntry.fromMap).toList();
  }
}
