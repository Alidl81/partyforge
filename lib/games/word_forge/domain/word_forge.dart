abstract interface class DictionaryProvider {
  Future<bool> contains(String normalizedWord);
}

abstract final class PersianWordNormalizer {
  static final RegExp _diacritics = RegExp('[\u064B-\u065F\u0670\u06D6-\u06ED]');
  static final RegExp _spaces = RegExp(r'[\s\u200C]+');

  static String normalize(String value) => value
      .replaceAll('ي', 'ی')
      .replaceAll('ك', 'ک')
      .replaceAll(_diacritics, '')
      .replaceAll('ـ', '')
      .replaceAll(_spaces, ' ')
      .trim()
      .toLowerCase();
}

final class LetterInventory {
  LetterInventory(Map<String, int> counts) : counts = Map.unmodifiable(counts);
  final Map<String, int> counts;

  bool canBuild(String word) {
    final needed = <String, int>{};
    for (final rune in word.runes) {
      final char = String.fromCharCode(rune);
      if (char == ' ') continue;
      needed[char] = (needed[char] ?? 0) + 1;
    }
    return needed.entries.every((entry) => (counts[entry.key] ?? 0) >= entry.value);
  }
}

abstract final class WordForgeScoring {
  static const _rare = {'ژ', 'ظ', 'ض', 'ث', 'ذ', 'غ', 'ق', 'چ', 'پ', 'گ'};

  static int score(String normalizedWord) {
    final letters = normalizedWord.runes.map(String.fromCharCode).where((c) => c != ' ').toList();
    if (letters.length < 2) return 0;
    final lengthScore = letters.length * letters.length * 5;
    final rareScore = letters.where(_rare.contains).length * 20;
    return lengthScore + rareScore;
  }
}

final class WordForgeSession {
  WordForgeSession({required this.inventory, required this.dictionary});
  final LetterInventory inventory;
  final DictionaryProvider dictionary;
  final Set<String> _accepted = {};

  Future<int> submit(String rawWord) async {
    final word = PersianWordNormalizer.normalize(rawWord);
    if (word.isEmpty || _accepted.contains(word) || !inventory.canBuild(word)) return 0;
    if (!await dictionary.contains(word)) return 0;
    _accepted.add(word);
    return WordForgeScoring.score(word);
  }
}
