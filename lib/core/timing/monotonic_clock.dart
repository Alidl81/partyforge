abstract interface class MonotonicClock {
  int nowMicroseconds();
}

final class StopwatchMonotonicClock implements MonotonicClock {
  StopwatchMonotonicClock() : _stopwatch = Stopwatch()..start();

  final Stopwatch _stopwatch;

  @override
  int nowMicroseconds() => _stopwatch.elapsedMicroseconds;
}

final class FakeMonotonicClock implements MonotonicClock {
  int _now = 0;

  @override
  int nowMicroseconds() => _now;

  void advance(Duration duration) => _now += duration.inMicroseconds;
  void setMicroseconds(int value) => _now = value;
}
