import 'dart:async';

import 'package:drift/drift.dart';

import '../../core/domain/player/player_profile.dart';
import '../../core/domain/player/player_repository.dart';
import '../database/app_database.dart';

final class DriftPlayerRepository implements PlayerRepository {
  DriftPlayerRepository(this._database);

  final AppDatabase _database;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  Future<void> dispose() => _changes.close();

  @override
  Future<void> delete(String id) async {
    await _database.customStatement('DELETE FROM players WHERE id = ?', [id]);
    _changes.add(null);
  }

  @override
  Future<List<PlayerProfile>> getAll() async {
    final rows = await _database.customSelect(
      'SELECT * FROM players ORDER BY updated_at DESC',
      readsFrom: const {},
    ).get();
    return rows.map(_map).toList(growable: false);
  }

  @override
  Future<void> save(PlayerProfile profile) async {
    await _database.customStatement(
      '''
        INSERT INTO players (
          id, name, color_value, avatar_id, championship_points,
          total_wins, total_losses, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          name = excluded.name,
          color_value = excluded.color_value,
          avatar_id = excluded.avatar_id,
          championship_points = excluded.championship_points,
          total_wins = excluded.total_wins,
          total_losses = excluded.total_losses,
          updated_at = excluded.updated_at
      ''',
      [
        profile.id,
        profile.name,
        profile.colorValue,
        profile.avatarId,
        profile.championshipPoints,
        profile.totalWins,
        profile.totalLosses,
        profile.createdAt.microsecondsSinceEpoch,
        profile.updatedAt.microsecondsSinceEpoch,
      ],
    );
    _changes.add(null);
  }

  @override
  Stream<List<PlayerProfile>> watchAll() async* {
    yield await getAll();
    await for (final _ in _changes.stream) {
      yield await getAll();
    }
  }

  PlayerProfile _map(QueryRow row) => PlayerProfile(
    id: row.read<String>('id'),
    name: row.read<String>('name'),
    colorValue: row.read<int>('color_value'),
    avatarId: row.read<String>('avatar_id'),
    championshipPoints: row.read<int>('championship_points'),
    totalWins: row.read<int>('total_wins'),
    totalLosses: row.read<int>('total_losses'),
    createdAt: DateTime.fromMicrosecondsSinceEpoch(row.read<int>('created_at')),
    updatedAt: DateTime.fromMicrosecondsSinceEpoch(row.read<int>('updated_at')),
  );
}
