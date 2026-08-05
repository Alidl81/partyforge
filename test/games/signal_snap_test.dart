import 'package:flutter_test/flutter_test.dart';
import 'package:partyforge/games/signal_snap/domain/signal_snap.dart';

void main() {
  test('false start is rejected and first valid tap wins', () {
    final result = SignalSnapResolver.resolve(cueAtHostUs: 1000, taps: const [
      SignalTap(playerId: 'a', hostTimeUs: 900, uncertaintyUs: 10),
      SignalTap(playerId: 'b', hostTimeUs: 1100, uncertaintyUs: 10),
      SignalTap(playerId: 'c', hostTimeUs: 1200, uncertaintyUs: 10),
    ]);
    expect(result.type, SignalSnapOutcomeType.winner);
    expect(result.playerIds, ['b']);
    expect(result.falseStartIds, ['a']);
  });

  test('combined uncertainty produces tie', () {
    final result = SignalSnapResolver.resolve(cueAtHostUs: 1000, taps: const [
      SignalTap(playerId: 'a', hostTimeUs: 1100, uncertaintyUs: 80),
      SignalTap(playerId: 'b', hostTimeUs: 1150, uncertaintyUs: 70),
    ]);
    expect(result.type, SignalSnapOutcomeType.tie);
    expect(result.playerIds, ['a', 'b']);
  });
}
