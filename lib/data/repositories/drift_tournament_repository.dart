import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/domain/tournament/tournament.dart';
import '../../core/domain/tournament/tournament_repository.dart';
import '../database/app_database.dart';

final class DriftTournamentRepository implements TournamentRepository {
  DriftTournamentRepository(this._database);

  final AppDatabase _database;

  @override
  Future<Tournament?> getById(String id) async {
    final row = await _database.customSelect(
      'SELECT * FROM tournaments WHERE id = ?',
      variables: [Variable.withString(id)],
      readsFrom: const {},
    ).getSingleOrNull();
    return row == null ? null : _map(row);
  }

  @override
  Future<void> save(Tournament tournament) => _database.customStatement(
    '''
      INSERT INTO tournaments (
        id, name, status, game_order, current_game_index, created_at, ended_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        name = excluded.name,
        status = excluded.status,
        game_order = excluded.game_order,
        current_game_index = excluded.current_game_index,
        ended_at = excluded.ended_at
    ''',
    [
      tournament.id,
      tournament.name,
      tournament.status.name,
      jsonEncode(tournament.gameOrder),
      tournament.currentGameIndex,
      tournament.createdAt.microsecondsSinceEpoch,
      tournament.endedAt?.microsecondsSinceEpoch,
    ],
  );

  Tournament _map(QueryRow row) {
    final decoded = jsonDecode(row.read<String>('game_order'));
    final endedAtUs = row.readNullable<int>('ended_at');
    return Tournament(
      id: row.read<String>('id'),
      name: row.read<String>('name'),
      status: TournamentStatus.values.byName(row.read<String>('status')),
      gameOrder: decoded is List
          ? decoded.map((value) => value.toString()).toList(growable: false)
          : const [],
      currentGameIndex: row.read<int>('current_game_index'),
      createdAt: DateTime.fromMicrosecondsSinceEpoch(
        row.read<int>('created_at'),
        isUtc: true,
      ),
      endedAt: endedAtUs == null
          ? null
          : DateTime.fromMicrosecondsSinceEpoch(endedAtUs, isUtc: true),
    );
  }
}
