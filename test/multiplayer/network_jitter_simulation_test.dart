import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:partyforge/games/signal_snap/domain/signal_snap.dart';
import 'package:partyforge/multiplayer/clock_sync/clock_sync_service.dart';

void main() {
  test('latency and jitter simulation preserves fair tap ordering', () {
    final random = Random(20260805);

    ClockEstimate estimateFor(int offsetUs) {
      final samples = <ClockSample>[];
      for (var i = 0; i < 9; i++) {
        final clientSend = i * 100000;
        final uplink = 8000 + random.nextInt(4000);
        final downlink = 8000 + random.nextInt(4000);
        final hostReceive = clientSend + offsetUs + uplink;
        final hostSend = hostReceive + 1000;
        final clientReceive = hostSend - offsetUs + downlink;
        samples.add(
          ClockSample(
            clientSendUs: clientSend,
            hostReceiveUs: hostReceive,
            hostSendUs: hostSend,
            clientReceiveUs: clientReceive,
          ),
        );
      }
      return ClockSyncEstimator.estimate(samples);
    }

    final aClock = estimateFor(50_000);
    final bClock = estimateFor(-35_000);
    const cueAtHostUs = 2_000_000;
    final outcome = SignalSnapResolver.resolve(
      cueAtHostUs: cueAtHostUs,
      taps: [
        SignalTap(
          playerId: 'a',
          hostTimeUs: aClock.toHostTime(cueAtHostUs - 50_000 + 120_000),
          uncertaintyUs: aClock.uncertaintyUs,
        ),
        SignalTap(
          playerId: 'b',
          hostTimeUs: bClock.toHostTime(cueAtHostUs + 35_000 + 180_000),
          uncertaintyUs: bClock.uncertaintyUs,
        ),
      ],
    );

    expect(outcome.type, SignalSnapOutcomeType.winner);
    expect(outcome.playerIds, ['a']);
  });
}
