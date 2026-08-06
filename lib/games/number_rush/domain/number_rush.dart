import '../../../core/random/seeded_random.dart';

final class NumberRushRound {
  const NumberRushRound({required this.target, required this.numbers});

  final int target;
  final List<int> numbers;
}

abstract final class NumberRushEngine {
  static NumberRushRound createRound(SeededRandom random) {
    final a = 2 + random.nextInt(18);
    final b = 2 + random.nextInt(18);
    final target = a + b;
    final numbers = <int>[a, b];
    while (numbers.length < 6) {
      final candidate = 1 + random.nextInt(24);
      if (!numbers.contains(candidate)) numbers.add(candidate);
    }
    for (var i = numbers.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final value = numbers[i];
      numbers[i] = numbers[j];
      numbers[j] = value;
    }
    return NumberRushRound(target: target, numbers: List.unmodifiable(numbers));
  }

  static bool isCorrect(NumberRushRound round, int first, int second) =>
      first != second &&
      first >= 0 &&
      second >= 0 &&
      first < round.numbers.length &&
      second < round.numbers.length &&
      round.numbers[first] + round.numbers[second] == round.target;

  static int score({required bool correct, required int streak}) =>
      correct ? 150 + streak.clamp(0, 20).toInt() * 35 : 0;
}
