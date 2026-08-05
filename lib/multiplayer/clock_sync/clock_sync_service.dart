final class ClockSample {
  const ClockSample({
    required this.clientSendUs,
    required this.hostReceiveUs,
    required this.hostSendUs,
    required this.clientReceiveUs,
  });

  final int clientSendUs;
  final int hostReceiveUs;
  final int hostSendUs;
  final int clientReceiveUs;

  int get roundTripUs =>
      (clientReceiveUs - clientSendUs) - (hostSendUs - hostReceiveUs);

  double get offsetUs =>
      ((hostReceiveUs - clientSendUs) +
          (hostSendUs - clientReceiveUs)) /
      2.0;
}

final class ClockEstimate {
  const ClockEstimate({
    required this.offsetUs,
    required this.uncertaintyUs,
    required this.sampleCount,
  });

  final double offsetUs;
  final double uncertaintyUs;
  final int sampleCount;

  int toHostTime(int clientTimeUs) => (clientTimeUs + offsetUs).round();
}

abstract final class ClockSyncEstimator {
  static ClockEstimate estimate(List<ClockSample> samples) {
    if (samples.length < 7) {
      throw ArgumentError('At least seven samples are required.');
    }
    final valid = samples
        .where((sample) => sample.roundTripUs >= 0)
        .toList()
      ..sort((a, b) => a.roundTripUs.compareTo(b.roundTripUs));
    if (valid.length < 5) {
      throw StateError('Insufficient valid clock samples.');
    }
    final calculatedKeepCount = (valid.length * 0.6).ceil();
    final keepCount = calculatedKeepCount < 5 ? 5 : calculatedKeepCount;
    final best = valid.take(keepCount).toList(growable: false);
    final weightedOffset = best.fold<double>(0, (sum, sample) {
      final denominator = sample.roundTripUs < 1 ? 1 : sample.roundTripUs;
      final weight = 1 / denominator;
      return sum + sample.offsetUs * weight;
    });
    final totalWeight = best.fold<double>(0, (sum, sample) {
      final denominator = sample.roundTripUs < 1 ? 1 : sample.roundTripUs;
      return sum + 1 / denominator;
    });
    final offset = weightedOffset / totalWeight;
    final uncertainty = best
        .map(
          (sample) =>
              sample.roundTripUs / 2.0 + (sample.offsetUs - offset).abs(),
        )
        .reduce((a, b) => a > b ? a : b);
    return ClockEstimate(
      offsetUs: offset,
      uncertaintyUs: uncertainty,
      sampleCount: best.length,
    );
  }
}

final class ClockSyncService {
  ClockSyncService({this.maximumSamples = 21});

  final int maximumSamples;
  final List<ClockSample> _samples = [];

  List<ClockSample> get samples => List.unmodifiable(_samples);

  ClockEstimate? addSample(ClockSample sample) {
    if (sample.roundTripUs < 0) return null;
    _samples.add(sample);
    if (_samples.length > maximumSamples) _samples.removeAt(0);
    if (_samples.length < 7) return null;
    return ClockSyncEstimator.estimate(_samples);
  }

  void reset() => _samples.clear();
}
