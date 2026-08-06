enum GamePlayKind { local, lan }

enum GameDifficulty { easy, medium, hard }

final class GameDefinition {
  const GameDefinition({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.description,
    required this.instructions,
    required this.imageAsset,
    required this.minimumPlayers,
    required this.maximumPlayers,
    required this.playKind,
    required this.difficulty,
    required this.tags,
    required this.playRoute,
    this.isNew = false,
  });

  final String id;
  final String title;
  final String shortDescription;
  final String description;
  final List<String> instructions;
  final String imageAsset;
  final int minimumPlayers;
  final int maximumPlayers;
  final GamePlayKind playKind;
  final GameDifficulty difficulty;
  final List<String> tags;
  final String playRoute;
  final bool isNew;

  String get playerLabel => minimumPlayers == maximumPlayers
      ? '$minimumPlayers بازیکن'
      : '$minimumPlayers تا $maximumPlayers بازیکن';

  String get modeLabel => switch (playKind) {
        GamePlayKind.local => 'بازی محلی',
        GamePlayKind.lan => 'شبکهٔ محلی',
      };

  String get difficultyLabel => switch (difficulty) {
        GameDifficulty.easy => 'آسان',
        GameDifficulty.medium => 'متوسط',
        GameDifficulty.hard => 'سخت',
      };
}
