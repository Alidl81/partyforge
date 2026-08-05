import 'package:flutter_test/flutter_test.dart';
import 'package:partyforge/core/random/seeded_random.dart';

void main() {
  test('same seed produces the same sequence', () {
    final a = SplitMix64Random(42);
    final b = SplitMix64Random(42);
    expect(List.generate(20, (_) => a.nextInt(100000)), List.generate(20, (_) => b.nextInt(100000)));
  });
}
