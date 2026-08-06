import 'package:flutter_test/flutter_test.dart';
import 'package:partyforge/core/random/seeded_random.dart';
import 'package:partyforge/games/memory_grid/domain/memory_grid.dart';

void main() {
  test('same seed and level generate the same pattern', () {
    final first = MemoryGridEngine.createRound(SplitMix64Random(77), 4);
    final second = MemoryGridEngine.createRound(SplitMix64Random(77), 4);

    expect(first.size, second.size);
    expect(first.activeCells, second.activeCells);
  });

  test('perfect selection is correct and scores points', () {
    final round = MemoryGridEngine.createRound(SplitMix64Random(11), 2);
    final result = MemoryGridEngine.evaluate(round, round.activeCells);

    expect(result.correct, isTrue);
    expect(result.missed, 0);
    expect(result.extra, 0);
    expect(result.points, greaterThan(0));
  });

  test('extra and missed cells reduce score', () {
    final round = MemoryGridEngine.createRound(SplitMix64Random(13), 2);
    final selected = <int>{...round.activeCells}..remove(round.activeCells.first);
    selected.add((round.activeCells.first + 1) % (round.size * round.size));

    final result = MemoryGridEngine.evaluate(round, selected);
    expect(result.correct, isFalse);
    expect(result.points, lessThan(
      MemoryGridEngine.evaluate(round, round.activeCells).points,
    ));
  });
}
