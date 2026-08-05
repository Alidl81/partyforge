import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/domain/match/game_match.dart';
import '../../core/domain/match/match_repository.dart';
import '../../core/domain/scoring/score_event.dart';
import '../database/app_database.dart';

final class DriftMatchRepository implements MatchRepository {
  DriftMatchRepository(this._database);

  final AppDatabase _database;

  @override
  Future<void> saveMatch(GameMatch match) => _database.customStatement(
    '''
      INSERT INTO matches (
        id, game_id, mode, host_player_id, seed, status, created_at,
        started_at, ended_at, settings_json, protocol_version
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        status = excluded.status,
        started_at = excluded.started_at,
        ended_at = excluded.ended_at,
        settings_json = excluded.settings_json
    ''',
    [
      match.id,
      match.gameId,
      match.mode,
      match.hostPlayerId,
      match.seed,
      match.status.name,
      match.createdAt.microsecondsSinceEpoch,
      match.startedAt?.microsecondsSinceEpoch,
      match.endedAt?.microsecondsSinceEpoch,
      match.settingsJson,
      match.protocolVersion,
    ],
  );

  @override
  Future<void> saveRound(GameRound round) => _database.customStatement(
    '''
      INSERT INTO rounds (
        id, match_id, round_index, state, started_at, ended_at
      ) VALUES (?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        state = excluded.state,
        ended_at = excluded.ended_at
    ''',
    [
      round.id,
      round.matchId,
      round.roundIndex,
      round.state,
      round.startedAt.microsecondsSinceEpoch,
      round.endedAt?.microsecondsSinceEpoch,
    ],
  );

  @override
  Future<void> appendScoreEvent(ScoreEvent event) => _database.customStatement(
    '''
      INSERT INTO score_events (
        id, match_id, round_id, player_id, reason, raw_points,
        championship_points, metadata, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
    [
      event.id,
      event.matchId,
      event.roundId,
      event.playerId,
      event.reason,
      event.rawPoints,
      event.championshipPoints,
      jsonEncode(event.metadata),
      event.createdAt.microsecondsSinceEpoch,
    ],
  );

  @override
  Future<List<ScoreEvent>> scoresForMatch(String matchId) async {
    final rows = await _database.customSelect(
      'SELECT * FROM score_events WHERE match_id = ? ORDER BY created_at, id',
      variables: [Variable.withString(matchId)],
      readsFrom: const {},
    ).get();
    return rows.map(_mapScore).toList(growable: false);
  }

  ScoreEvent _mapScore(QueryRow row) {
    final decoded = jsonDecode(row.read<String>('metadata'));
    final metadata = decoded is Map
        ? decoded.map((key, value) => MapEntry(key.toString(), value))
        : <String, Object?>{};
    return ScoreEvent(
      id: row.read<String>('id'),
      matchId: row.read<String>('match_id'),
      roundId: row.read<String>('round_id'),
      playerId: row.read<String>('player_id'),
      reason: row.read<String>('reason'),
      rawPoints: row.read<int>('raw_points'),
      championshipPoints: row.read<int>('championship_points'),
      metadata: metadata,
      createdAt: DateTime.fromMicrosecondsSinceEpoch(
        row.read<int>('created_at'),
        isUtc: true,
      ),
    );
  }
}
