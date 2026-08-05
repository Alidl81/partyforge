import 'package:flutter_test/flutter_test.dart';
import 'package:partyforge/multiplayer/clock_sync/clock_sync_service.dart';

void main() {
  test('estimates host offset while rejecting slow outlier influence', () {
    final samples = <ClockSample>[];
    for (var i = 0; i < 7; i++) {
      final send = i * 100000;
      samples.add(ClockSample(
        clientSendUs: send,
        hostReceiveUs: send + 55_000,
        hostSendUs: send + 56_000,
        clientReceiveUs: send + 11_000,
      ));
    }
    samples.add(const ClockSample(clientSendUs: 0, hostReceiveUs: 500000, hostSendUs: 501000, clientReceiveUs: 800000));
    final estimate = ClockSyncEstimator.estimate(samples);
    expect(estimate.offsetUs, closeTo(50_000, 2_000));
    expect(estimate.sampleCount, greaterThanOrEqualTo(5));
  });
}
