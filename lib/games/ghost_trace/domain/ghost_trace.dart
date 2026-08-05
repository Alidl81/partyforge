import 'dart:math' as math;

final class NormalizedPoint {
  const NormalizedPoint(this.x, this.y);
  final double x;
  final double y;

  double distanceTo(NormalizedPoint other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return math.sqrt(dx * dx + dy * dy);
  }
}

final class GhostTraceScore {
  const GhostTraceScore({
    required this.averageDistance,
    required this.maxDistance,
    required this.endpointError,
    required this.pathLengthRatio,
    required this.directionPenalty,
    required this.points,
  });

  final double averageDistance;
  final double maxDistance;
  final double endpointError;
  final double pathLengthRatio;
  final double directionPenalty;
  final int points;
}

abstract final class GhostTraceEngine {
  static List<NormalizedPoint> resample(List<NormalizedPoint> points, {int count = 64}) {
    if (count < 2) throw ArgumentError.value(count);
    if (points.length < 2) throw ArgumentError('At least two points are required.');
    final cumulative = <double>[0];
    for (var i = 1; i < points.length; i++) {
      cumulative.add(cumulative.last + points[i - 1].distanceTo(points[i]));
    }
    final total = cumulative.last;
    if (total == 0) return List.filled(count, points.first, growable: false);
    final result = <NormalizedPoint>[];
    var segment = 1;
    for (var i = 0; i < count; i++) {
      final target = total * i / (count - 1);
      while (segment < cumulative.length - 1 && cumulative[segment] < target) {
        segment++;
      }
      final startDistance = cumulative[segment - 1];
      final endDistance = cumulative[segment];
      final ratio = endDistance == startDistance ? 0.0 : (target - startDistance) / (endDistance - startDistance);
      final a = points[segment - 1];
      final b = points[segment];
      result.add(NormalizedPoint(a.x + (b.x - a.x) * ratio, a.y + (b.y - a.y) * ratio));
    }
    return result;
  }

  static double pathLength(List<NormalizedPoint> points) {
    var result = 0.0;
    for (var i = 1; i < points.length; i++) {
      result += points[i - 1].distanceTo(points[i]);
    }
    return result;
  }

  static GhostTraceScore score(List<NormalizedPoint> reference, List<NormalizedPoint> attempt) {
    final a = resample(reference);
    final b = resample(attempt);
    final distances = List<double>.generate(a.length, (i) => a[i].distanceTo(b[i]), growable: false);
    final average = distances.reduce((x, y) => x + y) / distances.length;
    final maximum = distances.reduce((a, b) => a > b ? a : b);
    final endpoint = (a.first.distanceTo(b.first) + a.last.distanceTo(b.last)) / 2;
    final lengthA = pathLength(a);
    final lengthB = pathLength(b);
    final ratio = lengthA == 0 ? 0.0 : lengthB / lengthA;
    final forwardError = endpoint;
    final reverseError = (a.first.distanceTo(b.last) + a.last.distanceTo(b.first)) / 2;
    final directionPenalty = reverseError < forwardError ? 0.25 : 0.0;
    final ratioPenalty = (1 - ratio.clamp(0.0, 2.0)).abs();
    final weightedError = average * 0.45 + maximum * 0.2 + endpoint * 0.15 + ratioPenalty * 0.1 + directionPenalty * 0.1;
    final points = ((1 - weightedError / 0.5).clamp(0.0, 1.0) * 1000).round();
    return GhostTraceScore(
      averageDistance: average,
      maxDistance: maximum,
      endpointError: endpoint,
      pathLengthRatio: ratio,
      directionPenalty: directionPenalty,
      points: points,
    );
  }
}
