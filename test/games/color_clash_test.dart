import 'package:flutter_test/flutter_test.dart';
import 'package:partyforge/core/random/seeded_random.dart';
import 'package:partyforge/games/color_clash/domain/color_clash.dart';

void main() {
  test('round generation is deterministic and ink differs from word', () {
    final first = ColorClashEngine.createRound(SplitMix64Random(42));
    final second = ColorClashEngine.createRound(SplitMix64Random(42));

    expect(first.word, second.word);
    expect(first.ink, second.ink);
    expect(first.word, isNot(first.ink));
  });

  test('correct fast answer scores more than slow answer', () {
    final round = const ColorClashRound(
      word: ClashColor.red,
      ink: ClashColor.blue,
    );
    final fast = ColorClashEngine.scoreAnswer(
      round: round,
      answer: ClashColor.blue,
      elapsedUs: 100000,
    );
    final slow = ColorClashEngine.scoreAnswer(
      round: round,
      answer: ClashColor.blue,
      elapsedUs: 1800000,
    );

    expect(fast, greaterThan(slow));
    expect(
      ColorClashEngine.scoreAnswer(
        round: round,
        answer: ClashColor.red,
        elapsedUs: 100000,
      ),
      0,
    );
  });
}
