enum TournamentStatus { created, running, completed, cancelled }

final class Tournament {
  const Tournament({
    required this.id,
    required this.name,
    required this.status,
    required this.gameOrder,
    required this.currentGameIndex,
    required this.createdAt,
    this.endedAt,
  });

  final String id;
  final String name;
  final TournamentStatus status;
  final List<String> gameOrder;
  final int currentGameIndex;
  final DateTime createdAt;
  final DateTime? endedAt;
}
