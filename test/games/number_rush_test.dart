import 'package:flutter_test/flutter_test.dart';
import 'package:partyforge/core/random/seeded_random.dart';
import 'package:partyforge/games/number_rush/domain/number_rush.dart';

void main() {
  test('generated round always contains a valid pair', () {
    for (var seed = 0; seed < 30; seed++) {
      final round = NumberRushEngine.createRound(SplitMix64Random(seed));
      var found = false;
      for (var i = 0; i < round.numbers.length; i++) {
        for (var j = i + 1; j < round.numbers.length; j++) {
          found = found || NumberRushEngine.isCorrect(round, i, j);
        }
      }
      expect(found, isTrue, reason: 'seed $seed');
    }
  });

  test('same index cannot be used twice', () {
    const round = NumberRushRound(target: 10, numbers: [5, 2, 8, 1]);
    expect(NumberRushEngine.isCorrect(round, 0, 0), isFalse);
    expect(NumberRushEngine.isCorrect(round, 1, 2), isTrue);
  });
}
