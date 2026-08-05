final class PlayerGameStats {
  const PlayerGameStats({
    required this.playerId,
    required this.gameId,
    required this.matches,
    required this.wins,
    required this.losses,
    required this.bestRawScore,
    required this.totalRawScore,
    required this.recordJson,
  });

  final String playerId;
  final String gameId;
  final int matches;
  final int wins;
  final int losses;
  final int bestRawScore;
  final int totalRawScore;
  final String recordJson;
}
