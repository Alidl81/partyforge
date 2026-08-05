final class PlayerProfile {
  const PlayerProfile({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.avatarId,
    required this.championshipPoints,
    required this.totalWins,
    required this.totalLosses,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final int colorValue;
  final String avatarId;
  final int championshipPoints;
  final int totalWins;
  final int totalLosses;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlayerProfile copyWith({
    String? name,
    int? colorValue,
    String? avatarId,
    int? championshipPoints,
    int? totalWins,
    int? totalLosses,
    DateTime? updatedAt,
  }) => PlayerProfile(
    id: id,
    name: name ?? this.name,
    colorValue: colorValue ?? this.colorValue,
    avatarId: avatarId ?? this.avatarId,
    championshipPoints: championshipPoints ?? this.championshipPoints,
    totalWins: totalWins ?? this.totalWins,
    totalLosses: totalLosses ?? this.totalLosses,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
