import 'package:flutter_test/flutter_test.dart';
import 'package:partyforge/core/domain/game_contracts/game_contract.dart';
import 'package:partyforge/core/domain/game_contracts/replay.dart';
import 'package:partyforge/games/chrono_lock/domain/chrono_lock.dart';

void main() {
  test('seed plus ordered command log reconstructs the same round', () {
    const game = ChronoLockGame();
    const context = GameContext(
      matchId: 'match-1',
      roundIndex: 0,
      playerIds: ['p1'],
    );
    const seed = 44;
    const replay = ReplayDescriptor<ChronoLockCommand>(
      matchId: 'match-1',
      seed: seed,
      commands: [
        ReplayCommand(
          sequence: 1,
          authoritativeTimeUs: 1000000,
          command: StartChronoLock(),
        ),
        ReplayCommand(
          sequence: 2,
          authoritativeTimeUs: 5500000,
          command: StopChronoLock(),
        ),
      ],
    );

    final reconstructed = ReplayRunner.replay(
      descriptor: replay,
      createInitialState: game.createInitialState,
      context: context,
      handleCommand: game.handleCommand,
    );

    expect(reconstructed.phase, ChronoLockPhase.stopped);
    expect(reconstructed.elapsedUs, 4500000);
  });

  test('rejects non-monotonic command sequences', () {
    const replay = ReplayDescriptor<int>(
      matchId: 'm',
      seed: 1,
      commands: [
        ReplayCommand(sequence: 2, authoritativeTimeUs: 1, command: 1),
        ReplayCommand(sequence: 2, authoritativeTimeUs: 2, command: 2),
      ],
    );
    expect(replay.validate, throwsStateError);
  });
}
