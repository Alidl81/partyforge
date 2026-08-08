import '../../games/catalog/game_definition.dart';

enum RoomGameStartStatus {
  allowed,
  tooFewPlayers,
  tooManyPlayers,
}

final class RoomGameStartCheck {
  const RoomGameStartCheck({
    required this.status,
    required this.participantCount,
    required this.requiredMinimum,
    required this.maximumPlayers,
  });

  final RoomGameStartStatus status;
  final int participantCount;
  final int requiredMinimum;
  final int maximumPlayers;

  bool get allowed => status == RoomGameStartStatus.allowed;

  String get shortMessage => switch (status) {
        RoomGameStartStatus.allowed => 'آمادهٔ شروع',
        RoomGameStartStatus.tooFewPlayers =>
          '${requiredMinimum - participantCount} نفر کم است',
        RoomGameStartStatus.tooManyPlayers =>
          '${participantCount - maximumPlayers} نفر بیشتر است',
      };

  String message(String gameTitle) => switch (status) {
        RoomGameStartStatus.allowed => 'بازی آمادهٔ شروع است.',
        RoomGameStartStatus.tooFewPlayers =>
          'برای «$gameTitle» حداقل $requiredMinimum نفر لازم است. '
              'الان $participantCount نفر هستید؛ '
              '${requiredMinimum - participantCount} نفر دیگر باید وارد اتاق شود.',
        RoomGameStartStatus.tooManyPlayers =>
          '«$gameTitle» حداکثر $maximumPlayers نفر را پشتیبانی می‌کند. '
              'الان $participantCount نفر در اتاق هستند.',
      };
}

abstract final class RoomGameStartRules {
  static RoomGameStartCheck check({
    required GameDefinition game,
    required int connectedClients,
  }) {
    final participantCount = connectedClients + 1;
    final requiredMinimum = game.minimumPlayers < 2 ? 2 : game.minimumPlayers;

    final status = participantCount < requiredMinimum
        ? RoomGameStartStatus.tooFewPlayers
        : participantCount > game.maximumPlayers
            ? RoomGameStartStatus.tooManyPlayers
            : RoomGameStartStatus.allowed;

    return RoomGameStartCheck(
      status: status,
      participantCount: participantCount,
      requiredMinimum: requiredMinimum,
      maximumPlayers: game.maximumPlayers,
    );
  }
}
