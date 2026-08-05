enum MatchStatus { created, lobby, running, paused, completed, cancelled }

final class GameMatch {
  const GameMatch({
    required this.id,
    required this.gameId,
    required this.mode,
    required this.hostPlayerId,
    required this.seed,
    required this.status,
    required this.createdAt,
    required this.settingsJson,
    required this.protocolVersion,
    this.startedAt,
    this.endedAt,
  });

  final String id;
  final String gameId;
  final String mode;
  final String hostPlayerId;
  final int seed;
  final MatchStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String settingsJson;
  final int protocolVersion;
}

final class GameRound {
  const GameRound({
    required this.id,
    required this.matchId,
    required this.roundIndex,
    required this.state,
    required this.startedAt,
    this.endedAt,
  });

  final String id;
  final String matchId;
  final int roundIndex;
  final String state;
  final DateTime startedAt;
  final DateTime? endedAt;
}
