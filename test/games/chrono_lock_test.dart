import 'package:flutter_test/flutter_test.dart';
import 'package:partyforge/core/domain/game_contracts/game_contract.dart';
import 'package:partyforge/core/random/seeded_random.dart';
import 'package:partyforge/games/chrono_lock/domain/chrono_lock.dart';

void main() {
  const game = ChronoLockGame();
  const context = GameContext(matchId: 'm', roundIndex: 0, playerIds: ['p']);

  test('exact target scores 1000', () {
    final result = ChronoLockGame.scoreFor(targetUs: 5_000_000, elapsedUs: 5_000_000);
    expect(result.errorUs, 0);
    expect(result.points, 1000);
  });

  test('early and late stop are symmetric', () {
    final early = ChronoLockGame.scoreFor(targetUs: 5_000_000, elapsedUs: 4_500_000);
    final late = ChronoLockGame.scoreFor(targetUs: 5_000_000, elapsedUs: 5_500_000);
    expect(early.points, late.points);
    expect(early.errorUs, 500_000);
  });

  test('score clamps to zero', () {
    expect(ChronoLockGame.scoreFor(targetUs: 2_000_000, elapsedUs: 8_000_000).points, 0);
  });

  test('target generation is deterministic and bounded', () {
    final a = game.createInitialState(context, SplitMix64Random(7));
    final b = game.createInitialState(context, SplitMix64Random(7));
    expect(a.targetUs, b.targetUs);
    expect(a.targetUs, inInclusiveRange(2_000_000, 10_000_000));
  });

  test('state transition uses authoritative time', () {
    final initial = game.createInitialState(context, SplitMix64Random(1));
    final running = game.handleCommand(initial, const StartChronoLock(), context, SplitMix64Random(1), 100).newState;
    final stopped = game.handleCommand(running, const StopChronoLock(), context, SplitMix64Random(1), 500).newState;
    expect(stopped.elapsedUs, 400);
  });
}
