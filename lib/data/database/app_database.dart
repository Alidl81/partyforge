import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final appDatabaseProvider = Provider<AppDatabase>(
  (_) => throw StateError('AppDatabase not initialized'),
);

final class AppDatabase extends GeneratedDatabase {
  AppDatabase(super.executor);

  static Future<AppDatabase> open() async {
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    final file = File(p.join(directory.path, 'partyforge.sqlite'));
    return AppDatabase(NativeDatabase.createInBackground(file));
  }

  @override
  int get schemaVersion => 1;

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  Iterable<DatabaseSchemaEntity> get allSchemaEntities => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (_) => _createSchema(),
    onUpgrade: (_, from, __) async {
      if (from < 1) await _createSchema();
    },
    beforeOpen: (_) async => customStatement('PRAGMA foreign_keys = ON'),
  );

  Future<void> _createSchema() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS players (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        avatar_id TEXT NOT NULL,
        championship_points INTEGER NOT NULL DEFAULT 0,
        total_wins INTEGER NOT NULL DEFAULT 0,
        total_losses INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS player_game_stats (
        player_id TEXT NOT NULL,
        game_id TEXT NOT NULL,
        matches INTEGER NOT NULL DEFAULT 0,
        wins INTEGER NOT NULL DEFAULT 0,
        losses INTEGER NOT NULL DEFAULT 0,
        best_raw_score INTEGER NOT NULL DEFAULT 0,
        total_raw_score INTEGER NOT NULL DEFAULT 0,
        record_json TEXT NOT NULL DEFAULT '{}',
        PRIMARY KEY (player_id, game_id),
        FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS matches (
        id TEXT PRIMARY KEY,
        game_id TEXT NOT NULL,
        mode TEXT NOT NULL,
        host_player_id TEXT NOT NULL,
        seed INTEGER NOT NULL,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        started_at INTEGER,
        ended_at INTEGER,
        settings_json TEXT NOT NULL,
        protocol_version INTEGER NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS match_players (
        match_id TEXT NOT NULL,
        player_id TEXT NOT NULL,
        seat_index INTEGER NOT NULL,
        PRIMARY KEY (match_id, player_id)
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS rounds (
        id TEXT PRIMARY KEY,
        match_id TEXT NOT NULL,
        round_index INTEGER NOT NULL,
        state TEXT NOT NULL,
        started_at INTEGER NOT NULL,
        ended_at INTEGER
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS score_events (
        id TEXT PRIMARY KEY,
        match_id TEXT NOT NULL,
        round_id TEXT NOT NULL,
        player_id TEXT NOT NULL,
        reason TEXT NOT NULL,
        raw_points INTEGER NOT NULL,
        championship_points INTEGER NOT NULL,
        metadata TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS game_records (
        id TEXT PRIMARY KEY,
        player_id TEXT NOT NULL,
        game_id TEXT NOT NULL,
        record_json TEXT NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS tournaments (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        status TEXT NOT NULL,
        game_order TEXT NOT NULL,
        current_game_index INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        ended_at INTEGER
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS tournament_players (
        tournament_id TEXT NOT NULL,
        player_id TEXT NOT NULL,
        points INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (tournament_id, player_id)
      )
    ''');
    await customStatement(
      'CREATE TABLE IF NOT EXISTS app_settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
    );
    await customStatement('''
      CREATE TABLE IF NOT EXISTS unlocked_items (
        id TEXT PRIMARY KEY,
        player_id TEXT NOT NULL,
        item_id TEXT NOT NULL,
        unlocked_at INTEGER NOT NULL
      )
    ''');
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_score_match ON score_events(match_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_round_match ON rounds(match_id, round_index)',
    );
  }
}
