import 'package:flutter_test/flutter_test.dart';
import 'package:partyforge/games/ghost_trace/domain/ghost_trace.dart';

void main() {
  const line = [NormalizedPoint(0, 0), NormalizedPoint(1, 1)];

  test('resampling returns requested count and endpoints', () {
    final result = GhostTraceEngine.resample(line, count: 64);
    expect(result, hasLength(64));
    expect(result.first.x, 0);
    expect(result.last.y, 1);
  });

  test('identical normalized path scores perfectly', () {
    expect(GhostTraceEngine.score(line, line).points, 1000);
  });

  test('resolution scaling does not affect normalized score', () {
    const detailed = [NormalizedPoint(0, 0), NormalizedPoint(0.5, 0.5), NormalizedPoint(1, 1)];
    expect(GhostTraceEngine.score(line, detailed).points, 1000);
  });
}
