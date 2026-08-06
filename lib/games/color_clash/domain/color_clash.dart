import '../../../core/random/seeded_random.dart';

enum ClashColor { red, blue, green, yellow }

extension ClashColorLabel on ClashColor {
  String get label => switch (this) {
        ClashColor.red => 'قرمز',
        ClashColor.blue => 'آبی',
        ClashColor.green => 'سبز',
        ClashColor.yellow => 'زرد',
      };
}

final class ColorClashRound {
  const ColorClashRound({required this.word, required this.ink});

  final ClashColor word;
  final ClashColor ink;
}

abstract final class ColorClashEngine {
  static ColorClashRound createRound(SeededRandom random) {
    final values = ClashColor.values;
    final word = values[random.nextInt(values.length)];
    var ink = values[random.nextInt(values.length)];
    if (ink == word) {
      ink = values[(ink.index + 1 + random.nextInt(values.length - 1)) %
          values.length];
    }
    return ColorClashRound(word: word, ink: ink);
  }

  static int scoreAnswer({
    required ColorClashRound round,
    required ClashColor answer,
    required int elapsedUs,
  }) {
    if (answer != round.ink) return 0;
    final timeBonus = (800 - elapsedUs ~/ 2500).clamp(0, 800).toInt();
    return 200 + timeBonus;
  }
}
