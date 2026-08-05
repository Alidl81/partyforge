final class ScoreEvent {
  const ScoreEvent({
    required this.id,
    required this.matchId,
    required this.roundId,
    required this.playerId,
    required this.reason,
    required this.rawPoints,
    required this.championshipPoints,
    required this.metadata,
    required this.createdAt,
  });

  final String id;
  final String matchId;
  final String roundId;
  final String playerId;
  final String reason;
  final int rawPoints;
  final int championshipPoints;
  final Map<String, Object?> metadata;
  final DateTime createdAt;
}

final class RankedScore {
  const RankedScore({required this.playerId, required this.rawScore});
  final String playerId;
  final int rawScore;
}
