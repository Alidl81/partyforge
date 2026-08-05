import 'package:drift/drift.dart';

import '../../core/domain/player/player_game_stats.dart';
import '../../core/domain/player/stats_repository.dart';
import '../database/app_database.dart';

final class DriftStatsRepository implements StatsRepository {
  DriftStatsRepository(this._database);

  final AppDatabase _database;

  @override
  Future<PlayerGameStats?> getForPlayer(String playerId, String gameId) async {
    final row = await _database.customSelect(
      'SELECT * FROM player_game_stats WHERE player_id = ? AND game_id = ?',
      variables: [Variable.withString(playerId), Variable.withString(gameId)],
      readsFrom: const {},
    ).getSingleOrNull();
    return row == null ? null : _map(row);
  }

  @override
  Future<void> save(PlayerGameStats stats) => _database.customStatement(
    '''
      INSERT INTO player_game_stats (
        player_id, game_id, matches, wins, losses, best_raw_score,
        total_raw_score, record_json
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(player_id, game_id) DO UPDATE SET
        matches = excluded.matches,
        wins = excluded.wins,
        losses = excluded.losses,
        best_raw_score = excluded.best_raw_score,
        total_raw_score = excluded.total_raw_score,
        record_json = excluded.record_json
    ''',
    [
      stats.playerId,
      stats.gameId,
      stats.matches,
      stats.wins,
      stats.losses,
      stats.bestRawScore,
      stats.totalRawScore,
      stats.recordJson,
    ],
  );

  PlayerGameStats _map(QueryRow row) => PlayerGameStats(
    playerId: row.read<String>('player_id'),
    gameId: row.read<String>('game_id'),
    matches: row.read<int>('matches'),
    wins: row.read<int>('wins'),
    losses: row.read<int>('losses'),
    bestRawScore: row.read<int>('best_raw_score'),
    totalRawScore: row.read<int>('total_raw_score'),
    recordJson: row.read<String>('record_json'),
  );
}
