import 'package:flutter_test/flutter_test.dart';
import 'package:partyforge/games/catalog/game_definition.dart';
import 'package:partyforge/multiplayer/host/room_game_start_rules.dart';

void main() {
  const singlePlayerGame = GameDefinition(
    id: 'test-single',
    title: 'Test',
    shortDescription: 'Test',
    description: 'Test',
    instructions: ['Test'],
    imageAsset: 'assets/game_art/chrono_lock.png',
    minimumPlayers: 1,
    maximumPlayers: 8,
    playKind: GamePlayKind.local,
    difficulty: GameDifficulty.easy,
    tags: ['test'],
    playRoute: '/games/test',
  );

  const threePlayerGame = GameDefinition(
    id: 'test-three',
    title: 'Test 3',
    shortDescription: 'Test',
    description: 'Test',
    instructions: ['Test'],
    imageAsset: 'assets/game_art/chrono_lock.png',
    minimumPlayers: 3,
    maximumPlayers: 4,
    playKind: GamePlayKind.lan,
    difficulty: GameDifficulty.easy,
    tags: ['test'],
    playRoute: '/games/test-three',
  );

  test('hosted rooms require at least two participants', () {
    final check = RoomGameStartRules.check(
      game: singlePlayerGame,
      connectedClients: 0,
    );

    expect(check.allowed, isFalse);
    expect(check.status, RoomGameStartStatus.tooFewPlayers);
    expect(check.requiredMinimum, 2);
    expect(check.participantCount, 1);
  });

  test('host is counted as one participant', () {
    final check = RoomGameStartRules.check(
      game: singlePlayerGame,
      connectedClients: 1,
    );

    expect(check.allowed, isTrue);
    expect(check.participantCount, 2);
  });

  test('game-specific minimum is enforced', () {
    final check = RoomGameStartRules.check(
      game: threePlayerGame,
      connectedClients: 1,
    );

    expect(check.allowed, isFalse);
    expect(check.requiredMinimum, 3);
    expect(check.shortMessage, '1 نفر کم است');
  });

  test('maximum player count is enforced', () {
    final check = RoomGameStartRules.check(
      game: threePlayerGame,
      connectedClients: 4,
    );

    expect(check.allowed, isFalse);
    expect(check.status, RoomGameStartStatus.tooManyPlayers);
    expect(check.participantCount, 5);
  });
}
