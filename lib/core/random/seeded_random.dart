abstract interface class SeededRandom {
  int nextInt(int maxExclusive);
  double nextDouble();
}

final class SplitMix64Random implements SeededRandom {
  SplitMix64Random(int seed) : _state = seed & _mask;

  static const int _mask = 0xFFFFFFFFFFFFFFFF;
  int _state;

  int _nextUint64() {
    _state = (_state + 0x9E3779B97F4A7C15) & _mask;
    var z = _state;
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & _mask;
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & _mask;
    return (z ^ (z >> 31)) & _mask;
  }

  @override
  int nextInt(int maxExclusive) {
    if (maxExclusive <= 0) throw ArgumentError.value(maxExclusive);
    return _nextUint64() % maxExclusive;
  }

  @override
  double nextDouble() => (_nextUint64() >>> 11) / 9007199254740992.0;
}
