import 'player_game_stats.dart';

abstract interface class StatsRepository {
  Future<PlayerGameStats?> getForPlayer(String playerId, String gameId);
  Future<void> save(PlayerGameStats stats);
}
