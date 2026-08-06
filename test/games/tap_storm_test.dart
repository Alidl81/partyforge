import 'package:flutter_test/flutter_test.dart';
import 'package:partyforge/games/tap_storm/domain/tap_storm.dart';

void main() {
  test('result uses monotonic duration and tap rate', () {
    final result = TapStormEngine.finish(
      tapCount: 25,
      durationUs: 5000000,
    );

    expect(result.tapsPerSecond, 5);
    expect(result.points, greaterThan(500));
  });

  test('zero duration is safely normalized', () {
    final result = TapStormEngine.finish(tapCount: 1, durationUs: 0);
    expect(result.durationUs, 1);
    expect(result.points, greaterThan(0));
  });
}
