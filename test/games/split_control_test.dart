import 'package:flutter_test/flutter_test.dart';
import 'package:partyforge/games/split_control/domain/split_control.dart';

void main() {
  test('accepts only increasing input sequence and clamps axis', () {
    final accepted = SplitControlReducer.apply(
      current: const {},
      input: const SplitInput(
        playerId: 'p1',
        sequence: 2,
        axis: 4,
        pressed: true,
        hostTimeUs: 100,
      ),
    );
    final rejected = SplitControlReducer.apply(
      current: accepted,
      input: const SplitInput(
        playerId: 'p1',
        sequence: 1,
        axis: -1,
        pressed: false,
        hostTimeUs: 200,
      ),
    );

    expect(accepted['p1']?.axis, 1);
    expect(identical(rejected, accepted), isTrue);
  });

  test('input timeout neutralizes control', () {
    final expired = SplitControlReducer.expire(
      current: const {
        'p1': SplitControlInputState(
          axis: 0.5,
          pressed: true,
          lastSequence: 3,
          lastHostTimeUs: 100,
        ),
      },
      nowHostUs: 700000,
    );
    expect(expired['p1']?.axis, 0);
    expect(expired['p1']?.pressed, isFalse);
  });
}
