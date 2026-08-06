import '../../../core/random/seeded_random.dart';

final class MemoryGridRound {
  const MemoryGridRound({
    required this.size,
    required this.activeCells,
    required this.level,
  });

  final int size;
  final Set<int> activeCells;
  final int level;
}

final class MemoryGridResult {
  const MemoryGridResult({
    required this.correct,
    required this.missed,
    required this.extra,
    required this.points,
  });

  final bool correct;
  final int missed;
  final int extra;
  final int points;
}

abstract final class MemoryGridEngine {
  static MemoryGridRound createRound(SeededRandom random, int level) {
    final safeLevel = level.clamp(1, 12).toInt();
    final size = safeLevel >= 7 ? 5 : 4;
    final count = (safeLevel + 2).clamp(3, size * size - 2).toInt();
    final cells = <int>{};
    while (cells.length < count) {
      cells.add(random.nextInt(size * size));
    }
    return MemoryGridRound(
      size: size,
      activeCells: Set.unmodifiable(cells),
      level: safeLevel,
    );
  }

  static MemoryGridResult evaluate(
    MemoryGridRound round,
    Set<int> selected,
  ) {
    final missed = round.activeCells.difference(selected).length;
    final extra = selected.difference(round.activeCells).length;
    final correct = missed == 0 && extra == 0;
    final base = round.activeCells.length * 120 + round.level * 40;
    final penalty = (missed * 120) + (extra * 80);
    return MemoryGridResult(
      correct: correct,
      missed: missed,
      extra: extra,
      points: (base - penalty).clamp(0, 2000).toInt(),
    );
  }
}
