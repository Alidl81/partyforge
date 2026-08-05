import 'package:flutter_test/flutter_test.dart';
import 'package:partyforge/core/random/seeded_random.dart';
import 'package:partyforge/games/hidden_fuse/domain/hidden_fuse.dart';

void main() {
  test('release before explosion banks score', () {
    final initial = HiddenFuseEngine.initial(SplitMix64Random(1));
    final holding = HiddenFuseEngine.start(initial, 1000).state;
    final result = HiddenFuseEngine.release(holding, holding.explosionAtUs! - 1);
    expect(result.state.phase, HiddenFusePhase.banked);
    expect(result.score, greaterThan(0));
  });

  test('release at or after boundary explodes', () {
    final initial = HiddenFuseEngine.initial(SplitMix64Random(2));
    final holding = HiddenFuseEngine.start(initial, 10).state;
    final atBoundary = HiddenFuseEngine.release(holding, holding.explosionAtUs!);
    expect(atBoundary.state.phase, HiddenFusePhase.exploded);
    expect(atBoundary.score, 0);
  });

  test('score progression accelerates', () {
    expect(HiddenFuseEngine.scoreForHold(5_000_000), greaterThan(HiddenFuseEngine.scoreForHold(3_000_000) * 2));
  });

  test('same seed reproduces fuse', () {
    expect(HiddenFuseEngine.initial(SplitMix64Random(99)).fuseDurationUs, HiddenFuseEngine.initial(SplitMix64Random(99)).fuseDurationUs);
  });
}
