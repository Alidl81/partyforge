final class TapStormResult {
  const TapStormResult({
    required this.tapCount,
    required this.durationUs,
    required this.points,
  });

  final int tapCount;
  final int durationUs;
  final int points;

  double get tapsPerSecond =>
      durationUs <= 0 ? 0 : tapCount / (durationUs / 1000000);
}

abstract final class TapStormEngine {
  static TapStormResult finish({
    required int tapCount,
    required int durationUs,
  }) {
    final safeDuration = durationUs <= 0 ? 1 : durationUs;
    final speedBonus = (tapCount / (safeDuration / 1000000) * 40).round();
    return TapStormResult(
      tapCount: tapCount,
      durationUs: safeDuration,
      points: tapCount * 20 + speedBonus,
    );
  }
}
